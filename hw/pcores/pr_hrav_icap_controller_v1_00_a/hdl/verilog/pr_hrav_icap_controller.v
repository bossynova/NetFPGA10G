//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Nguyen Van Quang Anh
// Email: nvqanh@gmail.com
// 
// Create Date:    
// Design Name: 
// Module Name:    pr_hrav_icap_controller
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//    * This module has AXI-Stream slave IF to receive data from pr_hrav_dispatcher
//      then convert to ICAP primitive interface to partially configure scanner core
//    * This module also implement AXI-Stream master IF to send configuration done
//      message back to pr_hrav_collector
//    * This module also has several internal control/debug registers which can
//      accessed via AXI-Lite slave IF. ICAP can be access via register
//      read/write 
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

//----------------------------------------
// Module Section
//----------------------------------------
module pr_hrav_icap_controller 
#(
    // Master AXI Stream Data Width
  parameter                              C_M_AXIS_DATA_WIDTH = 256,
  parameter                              C_S_AXIS_DATA_WIDTH = 256,
  parameter USER_MAGIC_CODE = 24'hAEECAB,
  parameter C_BASEADDR=32'hffffffff,
  parameter C_HIGHADDR=32'h0
  )
	(

   // System
   input          ACLK,     // AXI Stream clock (or core clock domain)
   input          ICAP_clk, // ICAP clock
   input          RESETN,   // Peripheral reset (active low) from System reset controller
   input          RESET,    // Peripheral reset from System reset controller

   // S/W cores control interface
   output reg     core_0_enb,    // To dispatcher/collector disable core_0 during reconfiguration
   output reg     core_1_enb,    // To dispatcher/collector  to disable core_1 during reconfiguration
   output reg     core_0_reset,  // To core 0 for reset
   output reg     core_1_reset,  // To core 1 for reset
	 output         core_sync_reset,
	 output         core_sync_reset_n,
	 output         hrav_0_axis_lp,
	 output         hrav_1_axis_lp,
 
   // AXI stream interface
   output  [C_M_AXIS_DATA_WIDTH-1:0]  M_AXIS_TDATA,
   output  [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   M_AXIS_TSTRB,
   output          M_AXIS_TVALID,
   output  [127:0] M_AXIS_TUSER,
   input           M_AXIS_TREADY,
   output          M_AXIS_TLAST,
  
   input [C_S_AXIS_DATA_WIDTH-1:0]   S_AXIS_TDATA,
   input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]    S_AXIS_TSTRB,
   input          S_AXIS_TVALID,
   output         S_AXIS_TREADY,
   input [127:0]  S_AXIS_TUSER,
   input          S_AXIS_TLAST,

    //Interface to AXI_LITE_SLAVE
   // axi lite control/status interface
   input          S_AXI_ACLK,
   input          S_AXI_ARESETN, 
   input [31:0]   S_AXI_AWADDR,
   input          S_AXI_AWVALID,
   output         S_AXI_AWREADY,
   input [31:0]   S_AXI_WDATA,
   input [3:0]    S_AXI_WSTRB,
   input          S_AXI_WVALID,
   output         S_AXI_WREADY,
   output [1:0]   S_AXI_BRESP,
   output         S_AXI_BVALID,
   input          S_AXI_BREADY,
   input [31:0]   S_AXI_ARADDR,
   input          S_AXI_ARVALID,
   output         S_AXI_ARREADY,
   output [31:0]  S_AXI_RDATA,
   output [1:0]   S_AXI_RRESP,
   output         S_AXI_RVALID,
   input          S_AXI_RREADY  
	);
	
  localparam ICAP_IS_BUSY = 1'b0; // Change this 1'b1 if BUSY is active-hight
  
   // Reset synchronoizer AXI Stream clock domain
    // These two are to dis-patcher, collector, etc
   rst_sync rst_sync_0i (.clk(ACLK), .rst_in(RESET),  .rst_out(core_sync_reset));
   rst_sync rst_sync_1i (.clk(ACLK), .rst_in(RESETN), .rst_out(core_sync_reset_n));

    // For ICAP
   wire icap_reset_n;
   rst_sync rst_sync_4i (.clk(ICAP_clk), .rst_in(RESETN),  .rst_out(icap_reset_n));

  // Enable and S/W control (will be also handled by ICAP FSM)
  // so that this can be auto done by H/W (TBD)
  // Sync to core clock domain used inside this module
  wire a_reset;
  rst_sync rst_sync_2i (.clk(ACLK), .rst_in(RESET),   .rst_out(a_reset));
  wire [31:0] core_ctrl;

  wire [7:0]  sync_core_ctrl;
  multi_bit_sync #(.BW(8)) core_ctrl_sync	(
    .clk(ACLK), .rst(a_reset), .in_sig(core_ctrl[7:0]), 
    .sync_sig(sync_core_ctrl[7:0])
  );

  wire [1:0] icap_core_enb, icap_core_rst;

  // Reset sync and S/W reset for scanner cores 
  always @(posedge ACLK) begin
    if (a_reset) {core_1_reset, core_0_reset} <= 2'b11;
    else         {core_1_reset, core_0_reset} <= (sync_core_ctrl[1:0] | icap_core_rst);
  end

  always @(posedge ACLK) begin
    if (a_reset) {core_1_enb, core_0_enb} <= 2'b00;
    else         {core_1_enb, core_0_enb} <= (&icap_core_enb) ? sync_core_ctrl[3:2] : icap_core_enb;
  end
  
  // HRAV AXIS loop-back mode
  assign hrav_0_axis_lp = sync_core_ctrl[5];
  assign hrav_1_axis_lp = sync_core_ctrl[6];
  
  // Enable auto clear stat. counter after result packet is sent back
  wire clr_stat_cnt_enb = sync_core_ctrl[7];

  // Calculate number of packet for debug
  reg [31:0] icap_pkt_cnt;
  always @(posedge ACLK) begin
    if (a_reset) begin
      icap_pkt_cnt <= 32'h0;
    end
    else if (S_AXIS_TVALID & S_AXIS_TREADY & S_AXIS_TLAST) begin
      icap_pkt_cnt <= icap_pkt_cnt + 1'b1;
    end
  end
  
  // pr_hrav_icap_controller_regfile
  wire [23:0] magic_code;

  wire        reg2icap_rd_req;
  wire        icap2reg_rd_ready;
  wire [31:0] icap2reg_rd_data; 

  wire         reg2icap_wr_req;
  wire         icap2reg_wr_ready;
  wire [31:0] reg2icap_wr_data; 

  wire [31:0] no_config_blk_pkt;
  wire [31:0] no_config_byte;
  wire [1:0]  icap_config_state;  

  pr_hrav_icap_controller_regfile  regfile
     (
      // Internal IF
      .magic_code(magic_code),
      .icap_pkt_cnt(icap_pkt_cnt),
      .no_config_blk_pkt (no_config_blk_pkt),
      .no_config_byte(no_config_byte),
      .icap_config_status({30'h0, icap_config_state}),

      // External control IF
      .core_ctrl(core_ctrl),

      // ICAP debug interface
      .reg2icap_rd_req   (reg2icap_rd_req  ),
      .icap2reg_rd_ready (icap2reg_rd_ready),
      .icap2reg_rd_data  (icap2reg_rd_data ), 

      .reg2icap_wr_req   (reg2icap_wr_req  ),
      .reg2icap_wr_data  (reg2icap_wr_data ),
      .icap2reg_wr_ready (icap2reg_wr_ready), 

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

	  reg [23:0] magic_code_sync_q, magic_code_sync_q1;
	  reg [15:0] icap_src_dst_sync_q, icap_src_dst_sync_q1;
	  always @(posedge ACLK) begin
			magic_code_sync_q <= magic_code;
			magic_code_sync_q1 <= magic_code_sync_q;
      
      icap_src_dst_sync_q  <= core_ctrl[31:16]; 
      icap_src_dst_sync_q1 <= icap_src_dst_sync_q; 
	  end

  // Master AXIS Interface muxing (for debugging purpose)
  wire  [C_M_AXIS_DATA_WIDTH-1:0]  ICAP_M_AXIS_TDATA, LB_M_AXIS_TDATA;
  wire  [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   ICAP_M_AXIS_TSTRB, LB_M_AXIS_TSTRB;
  wire          ICAP_M_AXIS_TVALID, LB_M_AXIS_TVALID;
  wire  [127:0] ICAP_M_AXIS_TUSER,  LB_M_AXIS_TUSER;
  wire          ICAP_M_AXIS_TREADY, LB_M_AXIS_TREADY;
  wire          ICAP_M_AXIS_TLAST,  LB_M_AXIS_TLAST;
  wire          ICAP_S_AXIS_TREADY;

  assign  LB_M_AXIS_TSTRB  = S_AXIS_TSTRB;
  assign  LB_M_AXIS_TVALID = S_AXIS_TVALID;
  assign  LB_M_AXIS_TUSER  = {S_AXIS_TUSER[127:32], S_AXIS_TUSER[23:16], S_AXIS_TUSER[31:24], S_AXIS_TUSER[15:0]};
  assign  LB_M_AXIS_TLAST  = S_AXIS_TLAST;
  assign  LB_M_AXIS_TDATA  = S_AXIS_TDATA;
    
    //Control mux
  assign  S_AXIS_TREADY      = sync_core_ctrl[4] ? M_AXIS_TREADY : ICAP_S_AXIS_TREADY;
  assign  ICAP_M_AXIS_TREADY = sync_core_ctrl[4] ? 1'b0: M_AXIS_TREADY; 

    //Data mux
  assign  M_AXIS_TSTRB  = sync_core_ctrl[4] ? LB_M_AXIS_TSTRB : ICAP_M_AXIS_TSTRB;
  assign  M_AXIS_TVALID = sync_core_ctrl[4] ? LB_M_AXIS_TVALID: ICAP_M_AXIS_TVALID;
  assign  M_AXIS_TUSER  = sync_core_ctrl[4] ? LB_M_AXIS_TUSER : ICAP_M_AXIS_TUSER;
  assign  M_AXIS_TLAST  = sync_core_ctrl[4] ? LB_M_AXIS_TLAST : ICAP_M_AXIS_TLAST;
  assign  M_AXIS_TDATA  = sync_core_ctrl[4] ? LB_M_AXIS_TDATA : ICAP_M_AXIS_TDATA;

  wire dbg_icap_ce;     
  wire dbg_icap_write;   
  wire [31:0] dbg_icap_data_in;
  wire [31:0] dbg_icap_data_out;
  wire dbg_icap_busy;
  icap_controller #(.IS_BUSY(ICAP_IS_BUSY)) icap_controller (
    .ICAP_clock(ICAP_clk),
    .ICAP_reset_n(icap_reset_n),
    .ACLK(ACLK),
    .ARESETN(core_sync_reset_n),

    // AXIS-IF
		.S_AXIS_TUSER (S_AXIS_TUSER),
		.S_AXIS_TSTRB (S_AXIS_TSTRB),
		.S_AXIS_TDATA (S_AXIS_TDATA ),
		.S_AXIS_TLAST (S_AXIS_TLAST ),
		.S_AXIS_TVALID(S_AXIS_TVALID),
		.S_AXIS_TREADY(ICAP_S_AXIS_TREADY),
		.M_AXIS_TUSER (ICAP_M_AXIS_TUSER),
		.M_AXIS_TSTRB (ICAP_M_AXIS_TSTRB),
		.M_AXIS_TDATA (ICAP_M_AXIS_TDATA ),
		.M_AXIS_TLAST (ICAP_M_AXIS_TLAST ),
		.M_AXIS_TVALID(ICAP_M_AXIS_TVALID),
		.M_AXIS_TREADY(ICAP_M_AXIS_TREADY),

    // Control IF
    .config_icap_magic_code(magic_code_sync_q1),
    .config_icap_src(icap_src_dst_sync_q1[7:0]),
    .config_icap_dst(icap_src_dst_sync_q1[15:8]),
    .icap_core_enb(icap_core_enb),
    .icap_core_rst(icap_core_rst),


    // Debug interface
    .dbg_icap_ce       (dbg_icap_ce      ),
    .dbg_icap_write    (dbg_icap_write   ),
    .dbg_icap_data_in  (dbg_icap_data_in ),
    .dbg_icap_data_out (dbg_icap_data_out),
    .dbg_icap_busy     (dbg_icap_busy    ),

    .clr_stat_cnt_enb  (clr_stat_cnt_enb),
    .no_config_blk_pkt (no_config_blk_pkt),
    .no_config_byte(no_config_byte),
    .icap_config_state(icap_config_state)
  );

  icap_debug_controller #(.IS_BUSY(ICAP_IS_BUSY)) icap_debug_controller (
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .ICAP_clk(ICAP_clk),
    .ICAP_reset_n(icap_reset_n),

    // Register file read interface
    .reg2icap_rd_req   (reg2icap_rd_req  ),
    .icap2reg_rd_ready (icap2reg_rd_ready),
    .icap2reg_rd_data  (icap2reg_rd_data ), 

    .reg2icap_wr_req   (reg2icap_wr_req  ),
    .reg2icap_wr_data  (reg2icap_wr_data ),
    .icap2reg_wr_ready (icap2reg_wr_ready), 

    // icap read debug interface
    .dbg_icap_ce       (dbg_icap_ce      ), //Read data request
    .dbg_icap_write    (dbg_icap_write   ),
    .dbg_icap_data_in  (dbg_icap_data_in ),
    .dbg_icap_data_out (dbg_icap_data_out),
    .dbg_icap_busy     (dbg_icap_busy    )
  );
endmodule
