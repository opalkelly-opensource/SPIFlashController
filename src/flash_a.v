//------------------------------------------------------------------------
// flash_a.v
//    This is the flash "A" controller which handles the flash communication
//    at the bit level.  Byte-wide requests are made to this controller
//    by the "B" controller which handles more elaborate commands.
//------------------------------------------------------------------------
//    Slices: 
// Slice FFs: 
//    4-LUTs: 
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
module flash_a(
	input  wire        clk,
	input  wire        reset,

	input  wire        write,
	input  wire        read,
	input  wire        deselect,
	input  wire [7:0]  din,
	output reg  [7:0]  dout,
	output reg         done,
	
	// Flash interface
	input  wire        flash_q,
	output reg         flash_c,
	output reg         flash_s_n,
	output reg         flash_d
	);


reg        des;
reg [7:0]  shift;
reg [3:0]  count;
reg [3:0]  descount;

parameter s_idle       = 0,
          s_write1     = 1,
          s_write2     = 2,
          s_read1      = 3,
          s_read1a     = 4,
          s_read2      = 5,
          s_deselect   = 6;
reg [31:0] state;
always @(posedge clk) begin
	if (reset == 1'b1) begin
		state <= s_idle;
		done  <= 1'b0;
		des   <= 1'b0;
		shift <= 8'b0;
		flash_c   <= 1'b0;
		flash_d   <= 1'b0;
		flash_s_n <= 1'b1;
	end else begin
		done <= 1'b0;
		
		case (state)
			s_idle: begin
				flash_c <= 1'b0;
				shift <= din;
				count <= 7;
				descount <= 10;
				des <= deselect;
				if (deselect == 1'b1) begin
					descount <= 10;
				end else begin
					descount <= 0;
				end
				
				if (write == 1'b1) begin
					state <= s_write1;
					flash_s_n <= 1'b0;
				end else if (read == 1'b1) begin
					state <= s_read1;
					flash_s_n <= 1'b0;
				end
			end

			s_write1: begin
				state <= s_write2;
				flash_c <= 1'b0;
				flash_d <= shift[7];
				shift <= {shift[6:0], 1'b0};
			end

			s_write2: begin
				count <= count - 1;
				flash_c <= 1'b1;
				if (count == 0) begin
					state <= s_deselect;
				end else begin
					state <= s_write1;
				end
			end

			s_read1: begin
				state <= s_read1a;
			end

			s_read1a: begin
				state <= s_read2;
				flash_c <= 1'b1;
				shift <= {shift[6:0], flash_q};
			end

			s_read2: begin
				flash_c <= 1'b0;
				count <= count - 1;
				if (count == 0) begin
					dout <= shift;
					state <= s_deselect;
				end else begin
					state <= s_read1;
				end
			end

			s_deselect: begin
				flash_c <= 1'b0;
				descount <= descount - 1;
				flash_s_n <= des;
				if (descount == 0) begin
					done <= 1'b1;
					state <= s_idle;
				end
			end
			
		endcase
	end

end

endmodule
`default_nettype wire
