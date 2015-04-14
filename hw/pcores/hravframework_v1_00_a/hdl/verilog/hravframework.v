//----------------------------------------------------------------------------
// hravframework - module
//----------------------------------------------------------------------------
// IMPORTANT:
// DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
//
// SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
//
// TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
// PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
// OF THE USER_LOGIC ENTITY.
//----------------------------------------------------------------------------
//
// ***************************************************************************
// ** Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.            **
// **                                                                       **
// ** Xilinx, Inc.                                                          **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
// ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
// ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
// ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
// ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
// ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
// ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
// ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
// ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
// ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
// ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
// ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
// ** FOR A PARTICULAR PURPOSE.                                             **
// **                                                                       **
// ***************************************************************************
//
//----------------------------------------------------------------------------
// Filename:          hravframework
// Version:           1.00.a
// Description:       Example Axi Streaming core (Verilog).
// Date:              Thu Oct  2 03:45:24 2014 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//   component instantiations:              "<ENTITY_>I_<#|FUNC>"
//----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
//
//
// Definition of Ports
// ACLK              : Synchronous clock
// ARESETN           : System reset, active low
// S_AXIS_TREADY  : Ready to accept data in
// S_AXIS_TDATA   :  Data in 
// S_AXIS_TLAST   : Optional data in qualifier
// S_AXIS_TVALID  : Data in is valid
// M_AXIS_TVALID  :  Data out is valid
// M_AXIS_TDATA   : Data Out
// M_AXIS_TLAST   : Optional data out qualifier
// M_AXIS_TREADY  : Connected slave device is ready to accept data out
//
////////////////////////////////////////////////////////////////////////////////

//----------------------------------------
// Module Section
//----------------------------------------

module hravframework 
#(
	//Master AXI Stream Data Width
	parameter C_M_AXIS_DATA_WIDTH=256,
	parameter C_S_AXIS_DATA_WIDTH=256,
	parameter C_M_AXIS_TUSER_WIDTH=128,
	parameter C_S_AXIS_TUSER_WIDTH=128,
	parameter TOTAL_LENGTH_POS=0,
	parameter SRC_PORT_POS=16,
	parameter DST_PORT_POS=24,
	parameter C_BASEADDR=32'hffffffff,
	parameter C_HIGHADDR=32'h0,
	
	parameter integer MASTERBANK_PIN_WIDTH = 3,
	parameter integer NUM_MEM_CHIPS      = 3,
	parameter integer NUM_MEM_INPUTS     = 6,
	parameter integer MEM_WIDTH          = 36,
	parameter integer MEM_ADDR_WIDTH     = 19,
	parameter integer MEM_CQ_WIDTH       = 1,
	parameter integer MEM_CLK_WIDTH      = 1,
	parameter integer MEM_BW_WIDTH       = 4
)
(
	// Global Ports
	input axi_aclk,
	input axi_resetn,

	// anhqvn, added to avoid reset inverstion
	input axi_reset,
	
	// anhqvn, added port for debug
	input hrav_axis_lp,

	// Master Stream Ports (interface to data path)
	output	[C_M_AXIS_DATA_WIDTH - 1:0]			m_axis_tdata,
	output	[((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]	m_axis_tstrb,
	output	[C_M_AXIS_TUSER_WIDTH-1:0]			m_axis_tuser,
	output 										m_axis_tvalid,
	input 										m_axis_tready,
	output  									m_axis_tlast,

	// Slave Stream Ports (interface to RX queues)
	input [C_S_AXIS_DATA_WIDTH - 1:0]			s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]	s_axis_tstrb,
	input [C_S_AXIS_TUSER_WIDTH-1:0]			s_axis_tuser,
	input										s_axis_tvalid,
	output										s_axis_tready,
	input										s_axis_tlast,

	// axi lite control/status interface
	input          S_AXI_ACLK,
	input          S_AXI_ARESETN,
	input [31:0]   S_AXI_AWADDR,
	input          S_AXI_AWVALID,
	output        S_AXI_AWREADY,
	input [31:0]   S_AXI_WDATA,
	input [3:0]    S_AXI_WSTRB,
	input          S_AXI_WVALID,
	output         S_AXI_WREADY,
	output [1:0]   S_AXI_BRESP,
	output      S_AXI_BVALID,
	input          S_AXI_BREADY,
	input [31:0]   S_AXI_ARADDR,
	input          S_AXI_ARVALID,
	output         S_AXI_ARREADY,
	output  [31:0]  S_AXI_RDATA,
	output [1:0]   S_AXI_RRESP,
	output         S_AXI_RVALID,
	input          S_AXI_RREADY,
	
	//MISC
	input 			core_clk,
	input 			core_clk_270,
	input 			sram_clk_200,
	
	input [(MEM_WIDTH)-1:0]  qdr_q_0,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_0,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_0,
	output             qdr_dll_off_n_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_0,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_0,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_0,
	output             qdr_w_n_0,
	output [(MEM_WIDTH)-1:0]  qdr_d_0,
	output             qdr_r_n_0,

	input [(MEM_WIDTH)-1:0]  qdr_q_1,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_1,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_1,
	output             qdr_dll_off_n_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_1,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_1,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_1,
	output             qdr_w_n_1,
	output [(MEM_WIDTH)-1:0]  qdr_d_1,
	output             qdr_r_n_1,

	input [(MEM_WIDTH)-1:0]  qdr_q_2,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_2,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_2,
	output             qdr_dll_off_n_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_2,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_2,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_2,
	output             qdr_w_n_2,
	output [(MEM_WIDTH)-1:0]  qdr_d_2,
	output             qdr_r_n_2,

	/*synthesis syn_keep = 1 */(* S = "TRUE" *)
	input  [MASTERBANK_PIN_WIDTH-1:0]  masterbank_sel_pin,

	input		locked
);

	wire scn_rdy_dpt;
	wire dpt_dvld_scn;
	wire [7:0] dpt_cmd_scn;
	wire [23:0] dpt_id_scn;
	wire [31:0] dpt_poff_scn;
	wire [255:0] dpt_data_scn;
	wire [31:0] dpt_bvld_scn;
	wire dpt_end_scn;
	
	wire clt_rdy_scn;
	wire scn_dvld_clt;
	wire [7:0] scn_cmd_clt;
	wire [23:0] scn_id_clt;
	wire [31:0] scn_poff_clt;
	wire [255:0] scn_data_clt;
	wire [31:0] scn_bvld_clt;
	wire scn_end_clt;
	
	dispatcher dpt (
		.clk(axi_aclk), 
		//.reset(~axi_resetn), 
		//anhqvn
		.reset(axi_reset),
		.s_axis_tdata(s_axis_tdata), 
		.s_axis_tstrb(s_axis_tstrb), 
		.s_axis_tuser(s_axis_tuser), 
		.s_axis_tvalid(s_axis_tvalid), 
		.s_axis_tready(s_axis_tready), 
		.s_axis_tlast(s_axis_tlast), 
		.dpt_dvld_scn(dpt_dvld_scn), 
		.dpt_cmd_scn(dpt_cmd_scn), 
		.dpt_id_scn(dpt_id_scn), 
		.dpt_poff_scn(dpt_poff_scn), 
		.dpt_data_scn(dpt_data_scn), 
		.dpt_bvld_scn(dpt_bvld_scn), 
		.dpt_end_scn(dpt_end_scn), 
		.scn_rdy_dpt(scn_rdy_dpt)
	);
/*	
	scanner scn (
		.clk(axi_aclk), 
		//.reset(~axi_resetn),
		// anhqvn change reset signal to avoid reset inversion
		.reset(axi_reset),
		
		.dpt_dvld_scn(dpt_dvld_scn), 
		.dpt_cmd_scn(dpt_cmd_scn), 
		.dpt_id_scn(dpt_id_scn), 
		.dpt_poff_scn(dpt_poff_scn), 
		.dpt_data_scn(dpt_data_scn), 
		.dpt_bvld_scn(dpt_bvld_scn), 
		.dpt_end_scn(dpt_end_scn), 
		.scn_rdy_dpt(scn_rdy_dpt),
		
		.scn_dvld_clt(scn_dvld_clt), 
		.scn_cmd_clt(scn_cmd_clt), 
		.scn_id_clt(scn_id_clt), 
//		.scn_poff_clt(scn_poff_clt), 
		.scn_data_clt(scn_data_clt), 
		.scn_bvld_clt(scn_bvld_clt), 
		.scn_end_clt(scn_end_clt), 
		.clt_rdy_scn(clt_rdy_scn)
	);
*/

	wire ctrl_en_scn;

	scanner_wrapper awrapper (
		.clk(axi_aclk), 
		//.reset(~axi_resetn),
		.reset(axi_reset),

		.ctrl_en_scn(ctrl_en_scn),
		
		.dpt_dvld_scn(dpt_dvld_scn), 
		.dpt_cmd_scn(dpt_cmd_scn), 
		.dpt_id_scn(dpt_id_scn), 
		.dpt_poff_scn(dpt_poff_scn), 
		.dpt_data_scn(dpt_data_scn), 
		.dpt_bvld_scn(dpt_bvld_scn), 
		.dpt_end_scn(dpt_end_scn), 
		.scn_rdy_dpt(scn_rdy_dpt),
		
		.scn_dvld_clt(scn_dvld_clt), 
		.scn_cmd_clt(scn_cmd_clt), 
		.scn_id_clt(scn_id_clt), 
//		.scn_poff_clt(scn_poff_clt), 
		.scn_data_clt(scn_data_clt), 
		.scn_bvld_clt(scn_bvld_clt), 
		.scn_end_clt(scn_end_clt), 
		.clt_rdy_scn(clt_rdy_scn)
	);


	collector clt (
		.clk(axi_aclk), 
		//.reset(~axi_resetn), 
		.reset(axi_reset), 
		.m_axis_tdata(m_axis_tdata), 
		.m_axis_tstrb(m_axis_tstrb), 
		.m_axis_tuser(m_axis_tuser), 
		.m_axis_tvalid(m_axis_tvalid), 
		.m_axis_tready(m_axis_tready), 
		.m_axis_tlast(m_axis_tlast), 
		.scn_dvld_clt(scn_dvld_clt), 
		.scn_cmd_clt(scn_cmd_clt), 
		.scn_id_clt(scn_id_clt), 
//		.scn_poff_clt(scn_poff_clt), 
		.scn_data_clt(scn_data_clt), 
		.scn_bvld_clt(scn_bvld_clt), 
		.scn_end_clt(scn_end_clt), 
		.clt_rdy_scn(clt_rdy_scn)
	);	


	hrav_framework_controller  controler
     (
      // hrav_framework control signal.
      .ctrl_en_scn(ctrl_en_scn),
      // Axi lite slave control signals
      .ACLK(S_AXI_ACLK),
      .ARESETN(S_AXI_ARESETN),
      .AWADDR(S_AXI_AWADDR),
      .AWVALID(S_AXI_AWVALID),
      .AWREADY(S_AXI_AWREADY),
      .WDATA(S_AXI_WDATA),
      .WSTRB(S_AXI_WSTRB),
      .WVALID(S_AXI_WVALID),
      .WREADY(S_AXI_WREADY),
      .BRESP(S_AXI_BRESP),
      .BVALID(S_AXI_BVALID),
      .BREADY(S_AXI_BREADY),
      .ARADDR(S_AXI_ARADDR),
      .ARVALID(S_AXI_ARVALID),
      .ARREADY(S_AXI_ARREADY),
      .RDATA(S_AXI_RDATA),
      .RRESP(S_AXI_RRESP),
      .RVALID(S_AXI_RVALID),
      .RREADY(S_AXI_RREADY)
     );

endmodule
