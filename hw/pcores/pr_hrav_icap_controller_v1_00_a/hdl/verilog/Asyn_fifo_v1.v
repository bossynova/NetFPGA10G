`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:15:14 02/05/2015 
// Design Name: 
// Module Name:    Asyn_fifo_v1 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ASYN_fifo
	#(
		parameter DATA_SIZE = 256,
		parameter ARRAY_SIZE = 3
	)
	(
		output [DATA_SIZE-1:0] rdata,
		output wfull,
		output rempty,
		input [DATA_SIZE-1:0] wdata,
		input winc, wclk, wrst_n,
		input rinc, rclk, rrst_n
	);
	
	wire [ARRAY_SIZE-1:0] waddr, raddr;
	wire [ARRAY_SIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
	
	sync_r2w #(ARRAY_SIZE) sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr), .wclk(wclk), .wrst_n(wrst_n));

	sync_w2r #(ARRAY_SIZE) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr), .rclk(rclk), .rrst_n(rrst_n));

	fifomem #(DATA_SIZE, ARRAY_SIZE) fifomem (.rdata(rdata), .wdata(wdata), .waddr(waddr), .raddr(raddr), .wclken(winc), .wfull(wfull), .wclk(wclk));
	
	rptr_empty #(ARRAY_SIZE) rptr_empty (.rempty(rempty), .raddr(raddr), .rptr(rptr), .rq2_wptr(rq2_wptr), .rinc(rinc), .rclk(rclk), .rrst_n(rrst_n));
	
	wptr_full #(ARRAY_SIZE) wptr_full (.wfull(wfull), .waddr(waddr), .wptr(wptr), .wq2_rptr(wq2_rptr), .winc(winc), .wclk(wclk), .wrst_n(wrst_n));
	
endmodule

module fifomem 
	#(
		parameter DATA_SIZE = 256,
		parameter ARRAY_SIZE = 5
	) // Number of mem address bits
	(
		output [DATA_SIZE-1:0] rdata,
		input [DATA_SIZE-1:0] wdata,
		input [ARRAY_SIZE-1:0] waddr, raddr,
		input wclken, wfull, wclk
	);
	`ifdef VENDORRAM
	// instantiation of a vendor's dual-port RAM
	vendor_ram mem (.dout(rdata), .din(wdata), .waddr(waddr), .raddr(raddr), .wclken(wclken), .wclken_n(wfull), .clk(wclk));
	`else
	// RTL Verilog memory model
	localparam DEPTH = 1<<ARRAY_SIZE;
	reg [DATA_SIZE-1:0] mem [0:DEPTH-1];
	
	assign rdata = mem[raddr];
	
	always @(posedge wclk)
		if (wclken && !wfull) mem[waddr] <= wdata;
	`endif
	
endmodule

module rptr_empty 
	#(
		parameter ARRAY_SIZE = 5
	)
	(
		output reg rempty,
		output [ARRAY_SIZE-1:0] raddr,
		output reg [ARRAY_SIZE :0] rptr,
		input [ARRAY_SIZE :0] rq2_wptr,
		input rinc, rclk, rrst_n
	);

	reg [ARRAY_SIZE:0] rbin;
	wire [ARRAY_SIZE:0] rgraynext, rbinnext;
	//-------------------
	// GRAYSTYLE2 pointer
	//-------------------
	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) {rbin, rptr} <= 0;
		else {rbin, rptr} <= {rbinnext, rgraynext};
	
	// Memory read-address pointer (okay to use binary to address memory)
	assign raddr = rbin[ARRAY_SIZE-1:0];
	assign rbinnext = rbin + (rinc & ~rempty);
	assign rgraynext = (rbinnext>>1) ^ rbinnext;
	
	//---------------------------------------------------------------
	// FIFO empty when the next rptr == synchronized wptr or on reset
	//---------------------------------------------------------------
	
	assign rempty_val = (rgraynext == rq2_wptr);
	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) rempty <= 1'b1;
		else rempty <= rempty_val;

endmodule

module sync_r2w 
	#(
		parameter ARRAY_SIZE = 5
	)
	(
		output reg [ARRAY_SIZE:0] wq2_rptr,
		input [ARRAY_SIZE:0] rptr,
		input wclk, wrst_n
	);
	
	reg [ARRAY_SIZE:0] wq1_rptr;
	
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
		else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule

module sync_w2r 
	#(
		parameter ARRAY_SIZE = 5
	)
	(
		output reg [ARRAY_SIZE:0] rq2_wptr,
		input [ARRAY_SIZE:0] wptr,
		input rclk, rrst_n
	);

	reg [ARRAY_SIZE:0] rq1_wptr;

	always @(posedge rclk or negedge rrst_n)
		if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;
		else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
endmodule

module wptr_full 
	#(
		parameter ARRAY_SIZE = 5
	)
	(
		output reg wfull,
		output [ARRAY_SIZE-1:0] waddr,
		output reg [ARRAY_SIZE :0] wptr,
		input [ARRAY_SIZE :0] wq2_rptr,
		input winc, wclk, wrst_n
	);
	
	reg [ARRAY_SIZE:0] wbin;
	
	wire [ARRAY_SIZE:0] wgraynext, wbinnext;
	
	// GRAYSTYLE2 pointer
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) {wbin, wptr} <= 0;
		else {wbin, wptr} <= {wbinnext, wgraynext};
	
	// Memory write-address pointer (okay to use binary to address memory)
	assign waddr = wbin[ARRAY_SIZE-1:0];
	assign wbinnext = wbin + (winc & ~wfull);
	assign wgraynext = (wbinnext>>1) ^ wbinnext;
	//------------------------------------------------------------------
	// Simplified version of the three necessary full-tests:
	// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
	// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
	// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
	//------------------------------------------------------------------
	assign wfull_val = (wgraynext=={~wq2_rptr[ARRAY_SIZE:ARRAY_SIZE-1],wq2_rptr[ARRAY_SIZE-2:0]});
	always @(posedge wclk or negedge wrst_n)
		if (!wrst_n) wfull <= 1'b0;
		else wfull <= wfull_val;

endmodule
