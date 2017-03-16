//------------------------------------------------------------------------
// flash_b.v
//    This is the flash "B" controller which handles the macro commands
//    to the flash device.  This includes full commands such as
//    sector erase, page program, and so on.
//
//    This controller uses the "A" controller for direct control of the
//    flash.
//
// Commands:
//  ERASE_SECTORS
//     + ADDR is the sector address to start erasing (0..127)
//     + LENGTH is the number of sectors to erase in sequence
//  WRITE
//     + ADDR is the page address to start writing (0..65535)
//     + LENGTH is the number of full (256-byte) pages to write.
//  READ
//     + ADDR is the page address to start reading (0..65535)
//     + LENGTH is the number of full (256-byte) pages to read.
//------------------------------------------------------------------------
// Copyright (c) 2005-2017 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps
module flash_b(
	input  wire        clk,
	input  wire        reset,

	input  wire        cmd_erasesectors,
	input  wire        cmd_write,
	input  wire        cmd_read,
	input  wire [15:0] addr,
	input  wire [15:0] length,
	input  wire [7:0]  din,
	output reg  [7:0]  dout,
	output reg         read,
	output reg         write,
	output reg         done,
	output wire [15:0] status,
	
	// Flash interface
	input  wire        flash_q,
	output wire        flash_c,
	output wire        flash_s_n,
	output wire        flash_d
	);

reg        a_write;
reg        a_read;
reg        a_deselect;
wire       a_done;
wire [7:0] a_dout;
reg  [7:0] a_din;

reg  [15:0] count_a;
reg  [15:0] count_b;
reg  [23:0] count_c;

assign status = count_b;

flash_a f0(
	.clk(clk),
	.reset(reset),
	.write(a_write),
	.read(a_read),
	.deselect(a_deselect),
	.din(a_din),
	.dout(a_dout),
	.done(a_done),
	.flash_c(flash_c),
	.flash_s_n(flash_s_n),
	.flash_d(flash_d),
	.flash_q(flash_q));

parameter s_idle       = 0,
          s_erase1     = 1,
          s_erase1w    = 2,
          s_erase2     = 3,
          s_erase2w    = 4,
          s_erase3     = 5,
          s_erase3w    = 6,
          s_erase4     = 7,
          s_erase4w    = 8,
          s_erase5     = 9,
          s_erase5w    = 10,
          s_erase6     = 11,
          s_erase6w    = 12,
          s_erase7     = 13,
          s_erase7w    = 14,
          s_erase8     = 15,
          
          s_write1     = 20,
          s_write1w    = 21,
          s_write2     = 22,
          s_write2w    = 23,
          s_write3     = 24,
          s_write3w    = 25,
          s_write4     = 26,
          s_write4w    = 27,
          s_write5     = 28,
          s_write5w    = 29,
          s_write6     = 30,
          s_write6w    = 31,
          s_write7     = 32,
          s_write7w    = 33,
          s_write8     = 34,
          s_write8w    = 35,
          s_write9     = 36,
          
          s_read1      = 40,
          s_read1w     = 41,
          s_read2      = 42,
          s_read2w     = 43,
          s_read3      = 44,
          s_read3w     = 45,
          s_read4      = 46,
          s_read4w     = 47,
          s_read5      = 48,
          s_read5w     = 49,
          s_read6      = 50,
          s_read6w     = 51,
          s_read7      = 52;
reg [31:0] state;
always @(posedge clk) begin
	if (reset == 1'b1) begin
		state <= s_idle;
		done <= 1'b0;
		read <= 1'b0;
		write <= 1'b0;
	end else begin
		done <= 1'b0;
		read <= 1'b0;
		write <= 1'b0;
		a_write <= 1'b0;
		a_read  <= 1'b0;
		a_deselect <= 1'b0;
		
		case (state)
			s_idle: begin
				if (cmd_erasesectors == 1'b1) begin
					state <= s_erase1;
					count_a <= addr;
					count_b <= length;
				end else if (cmd_write == 1'b1) begin
					state <= s_write1;
					count_a <= addr;
					count_b <= length;
				end else if (cmd_read == 1'b1) begin
					state <= s_read1;
					count_a <= addr;
					count_c <= {length, 8'hff};
				end
			end

			//===============================================================
			// ERASE SECTORS
			//===============================================================
			// WREN
			s_erase1: begin
				a_write    <= 1'b1;
				a_deselect <= 1'b1;
				a_din      <= 8'h06;
				state <= s_erase1w;
			end
			s_erase1w: begin
				if (a_done == 1'b1)
					state <= s_erase2;
			end
			
			// SE
			s_erase2: begin
				a_write <= 1'b1;
				a_din <= 8'hd8;
				state <= s_erase2w;
			end
			s_erase2w: begin
				if (a_done == 1'b1)
					state <= s_erase3;
			end

			// ADDR[23:16]			
			s_erase3: begin
				a_write <= 1'b1;
				a_din <= count_a[7:0];
				state <= s_erase3w;
			end
			s_erase3w: begin
				if (a_done == 1'b1)
					state <= s_erase4;
			end

			// ADDR[15:8]			
			s_erase4: begin
				a_write <= 1'b1;
				a_din <= 8'h00;
				state <= s_erase4w;
			end
			s_erase4w: begin
				if (a_done == 1'b1)
					state <= s_erase5;
			end

			// ADDR[7:0]
			s_erase5: begin
				a_write <= 1'b1;
				a_din <= 8'h00;
				a_deselect <= 1'b1;
				state <= s_erase5w;
			end
			s_erase5w: begin
				if (a_done == 1'b1)
					state <= s_erase6;
			end

			// RDSR
			s_erase6: begin
				a_write <= 1'b1;
				a_din <= 8'h05;
				state <= s_erase6w;
			end
			s_erase6w: begin
				if (a_done == 1'b1)
					state <= s_erase7;
			end

			s_erase7: begin
				a_read <= 1'b1;
				a_deselect <= 1'b1;
				state <= s_erase7w;
			end
			s_erase7w: begin
				if (a_done == 1'b1) begin
					if (a_dout[0] == 1'b1)
						state <= s_erase6;
					else
						state <= s_erase8;
				end
			end

			// Loop until all requested sectors are erased.
			s_erase8: begin
				count_b <= count_b - 1;
				count_a <= count_a + 1;
				if (count_b == 0) begin
					state <= s_idle;
					done <= 1'b1;
				end else begin
					state <= s_erase1;
				end
			end


			//===============================================================
			// WRITE DATA
			//===============================================================
			// WREN
			s_write1: begin
				a_write <= 1'b1;
				a_deselect <= 1'b1;
				a_din <= 8'h06;
				state <= s_write1w;
			end
			s_write1w: begin
				if (a_done == 1'b1)
					state <= s_write2;
			end
			
			// PP
			s_write2: begin
				a_write <= 1'b1;
				a_din <= 8'h02;
				state <= s_write2w;
			end
			s_write2w: begin
				if (a_done == 1'b1)
					state <= s_write3;
			end

			// ADDR[23:16]
			s_write3: begin
				a_write <= 1'b1;
				a_din <= count_a[15:8];
				state <= s_write3w;
			end
			s_write3w: begin
				if (a_done == 1'b1)
					state <= s_write4;
			end

			// ADDR[15:8]
			s_write4: begin
				a_write <= 1'b1;
				a_din <= count_a[7:0];
				state <= s_write4w;
			end
			s_write4w: begin
				if (a_done == 1'b1)
					state <= s_write5;
			end

			// ADDR[7:0]
			s_write5: begin
				a_write <= 1'b1;
				a_din <= 8'h00;
				read <= 1'b1;			// Gets the first data word ready.
				state <= s_write5w;
			end
			s_write5w: begin
				if (a_done == 1'b1) begin
					state <= s_write6;
					count_c <= 8'd255;
				end
			end

			// DATA[0..255]
			s_write6: begin
				state <= s_write6w;
				a_write <= 1'b1;
				a_din <= din;
				if (count_c == 0) begin
					a_deselect <= 1'b1;
				end else begin
					read <= 1'b1;		// Gets next word from memory.
				end
			end
			s_write6w: begin
				if (a_done == 1'b1) begin
					count_c <= count_c - 1;
					if (count_c == 0) begin
						state <= s_write7;
					end else begin
						state <= s_write6;
					end
				end
			end
			
			// RDSR
			s_write7: begin
				a_write <= 1'b1;
				a_din <= 8'h05;
				state <= s_write7w;
			end
			s_write7w: begin
				if (a_done == 1'b1)
					state <= s_write8;
			end

			s_write8: begin
				a_read <= 1'b1;
				a_deselect <= 1'b1;
				state <= s_write8w;
			end
			s_write8w: begin
				if (a_done == 1'b1) begin
					if (a_dout[0] == 1'b1)
						state <= s_write7;
					else
						state <= s_write9;
				end
			end

			// Loop until all pages have been written
			s_write9: begin
				count_a <= count_a + 1;
				count_b <= count_b - 1;
				if (count_b == 0) begin
					done <= 1'b1;
					state <= s_idle;
				end else begin
					state <= s_write1;
				end
			end


			//===============================================================
			// READ DATA
			//===============================================================
			// FAST_READ
			s_read1: begin
				a_write <= 1'b1;
				a_din <= 8'h0b;
				state <= s_read1w;
			end
			s_read1w: begin
				if (a_done == 1'b1)
					state <= s_read2;
			end

			// ADDR[23:16]
			s_read2: begin
				a_write <= 1'b1;
				a_din <= count_a[15:8];
				state <= s_read2w;
			end
			s_read2w: begin
				if (a_done == 1'b1)
					state <= s_read3;
			end

			// ADDR[15:8]
			s_read3: begin
				a_write <= 1'b1;
				a_din <= count_a[7:0];
				state <= s_read3w;
			end
			s_read3w: begin
				if (a_done == 1'b1)
					state <= s_read4;
			end

			// ADDR[7:0]
			s_read4: begin
				a_write <= 1'b1;
				a_din <= 8'h00;
				state <= s_read4w;
			end
			s_read4w: begin
				if (a_done == 1'b1) begin
					state <= s_read5;
				end
			end

			// DUMMY
			s_read5: begin
				a_read <= 1'b1;
				state <= s_read5w;
			end
			s_read5w: begin
				if (a_done == 1'b1) begin
					state <= s_read6;
				end
			end

			// DATA[n]
			s_read6: begin
				a_read <= 1'b1;
				state <= s_read6w;
				if (count_c == 0) begin
					a_deselect <= 1'b1;
				end
			end
			s_read6w: begin
				if (a_done == 1'b1) begin
					write <= 1'b1;
					dout <= a_dout;
					state <= s_read7;
				end
			end
			
			s_read7: begin
				count_c <= count_c - 1;
				if (count_c == 0) begin
					state <= s_idle;
					done <= 1'b1;
				end else begin
					state <= s_read6;
				end
			end

		endcase
	end

end

endmodule
`default_nettype wire
