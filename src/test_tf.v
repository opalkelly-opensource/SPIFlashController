//------------------------------------------------------------------------
// test_tf.v
//
// This is a simple test fixture designed to demonstrate usage of the
// flash controller. This is not intended to be an exhaustive test for
// verification purposes.
//------------------------------------------------------------------------
// Copyright (c) 2017 Opal Kelly Incorporated
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
// 
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module tf;
	reg          clk;
	reg          rst;
	reg          cmd_erase;
	reg          cmd_read;
	reg          cmd_write;
	reg  [15:0]  cmd_addr;
	reg  [15:0]  cmd_length;
	
	reg   [7:0]  fifo_din;
	wire  [7:0]  fifo_dout;
	wire         fifo_read;
	wire         fifo_write;
	wire         done;
	wire [15:0]  status;

	wire         flash_q, flash_c, flash_s_n, flash_d;


//------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------
flash_b dut (
		.clk              (clk),
		.reset            (rst),

		.cmd_erasesectors (cmd_erase),
		.cmd_write        (cmd_write),
		.cmd_read         (cmd_read),
		.addr             (cmd_addr),
		.length           (cmd_length),
		
		// For this test/demonstration the din input is fixed to a single
		// value. It is relatively simple to generate a FIFO for a given
		// FPGA architecture and connect it to the signals below.
		.din              (fifo_din),
		.dout             (fifo_dout),
		.read             (fifo_read),
		.write            (fifo_write),

		.done             (done),
		.status           (status),

		.flash_q          (flash_q),
		.flash_c          (flash_c),
		.flash_s_n        (flash_s_n),
		.flash_d          (flash_d)
	);

M25P64 flash0 (
		.c        (flash_c),
		.data_in  (flash_d),
		.data_out (flash_q),
		.s        (flash_s_n),
		.w        (1'b1),
		.hold     (1'b1)
	);


// Clock Generation
parameter tCLK = 10;
initial   clk  = 0;
always #(tCLK/2.0) clk = ~clk;

initial cmd_erase = 1'b0;
initial cmd_read = 1'b0;
initial cmd_write = 1'b0;
initial cmd_addr = 16'h00;
initial cmd_length = 16'h00;


initial begin
	//$dumpfile("dump.vcd"); $dumpvars;
	rst = 1'b1;
	#100;
	rst = 1'b0;
	#100;

	// Erase 8 sectors starting at sector 0 (each sector is 256 KiB)
	@(posedge clk);
	cmd_erase = 1'b1;
	cmd_addr = 16'h00;
	cmd_length = 16'h8;

	@(posedge clk);
	cmd_erase = 1'b0;

	// Wait done
	while(done == 1'b0) begin
		#tCLK;
	end

	// Write 0xBE to page 0x10
	@(posedge clk);
	cmd_write  = 1'b1;
	cmd_addr   = 16'h10;
	cmd_length = 1;
	fifo_din   = 8'hBE; // This can be replaced with a FIFO for data transfer

	@(posedge clk);
	cmd_write = 1'b0;

	// Wait done
	while(done == 1'b0) begin
		#tCLK;
	end

	// Read 0x0F-0x11
	@(posedge clk);
	cmd_read   = 1'b1;
	cmd_addr   = 16'h0F;
	cmd_length = 8'h03;

	@(posedge clk);
	cmd_read = 1'b0;
	
	// Wait done
	while(done == 1'b0) begin
		#tCLK;
	end

	$finish;
end


endmodule
