`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:34:00 04/01/2015 
// Design Name: 
// Module Name:    icap_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:    This module is to control write/read bitstream to ICAP primitive
// Dependencies:
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module icap_controller #(
    parameter ICAP_WIDTH = 32,
    parameter IS_BUSY   = 1'b0) 
	(
		// ADD USER PORTS BELOW THIS LINE 
		input ICAP_clock,				//ICAP_CLK - or in the future can make a clock generator in this module
    input ICAP_reset_n,

		// ADD USER PORTS ABOVE THIS LINE 
    input   dbg_icap_ce,
    input   dbg_icap_write,
    input   [31:0] dbg_icap_data_in,
    output  [31:0] dbg_icap_data_out,
    output  dbg_icap_busy, 

    output [31:0] no_config_blk_pkt,
    output [31:0] no_config_byte,
    output [1:0]  icap_config_state,
    output [1:0]  icap_core_enb,
    output [1:0]  icap_core_rst,

    input  [23:0] config_icap_magic_code,
    input  [7:0]  config_icap_src,
    input  [7:0]  config_icap_dst,
    input         clr_stat_cnt_enb,
		
		// DO NOT EDIT BELOW THIS LINE ////////////////////
		// Bus protocol ports, do not add or delete. 
		input ACLK,
		input ARESETN,

		input  [255:0]  S_AXIS_TDATA,
		input           S_AXIS_TLAST,
		input           S_AXIS_TVALID,
    input  [127:0]  S_AXIS_TUSER,
    input  [31:0]   S_AXIS_TSTRB,
		output          S_AXIS_TREADY,

		output  [255:0] M_AXIS_TDATA,
		output          M_AXIS_TLAST,
		output          M_AXIS_TVALID,
    output  [127:0] M_AXIS_TUSER,
    output  [31:0]  M_AXIS_TSTRB,
		input           M_AXIS_TREADY
		// DO NOT EDIT ABOVE THIS LINE ////////////////////
	);

// ADD USER PARAMETERS BELOW THIS LINE 
	localparam	DATA_WIDTH = 256;
	localparam	ARRAY_SIZE = 4;
	localparam  ICAP_DATA_WIDTH = 32;
// ADD USER PARAMETERS ABOVE THIS LINE
	
//----------------------------------------
// Implementation Section
//----------------------------------------
// 

  wire [7:0] in_strb = {  S_AXIS_TSTRB[28], S_AXIS_TSTRB[24], S_AXIS_TSTRB[20], S_AXIS_TSTRB[16]
                        , S_AXIS_TSTRB[12], S_AXIS_TSTRB[8], S_AXIS_TSTRB[4], S_AXIS_TSTRB[0]};

  wire fifo_ready, fifo_valid;
  wire [ICAP_WIDTH-1:0] fifo_wdata, fifo_rdata;
  wire config_blk_start, config_blk_end, config_end;
  reg  clr_stat_cnt, next_clr_stat_cnt;

  icap_data_size_converter #(DATA_WIDTH, ICAP_DATA_WIDTH) icap_data_size_converter (
		.clock(ACLK),
		.rst_n(ARESETN),
    
    // 256bit FIFO interface
		.in_valid (S_AXIS_TVALID),
		.in_data  (S_AXIS_TDATA),
    .in_strb  (in_strb), // Assume data is multiple of 4 bytes
    .in_user  (S_AXIS_TUSER),
    .in_last  (S_AXIS_TLAST),
		.out_ready(S_AXIS_TREADY),
    
    // 32-bit ICAP interfce
    .in_ready  (fifo_ready),
		.out_data  (fifo_wdata),
		.out_valid (fifo_valid),

    // Internal interface
    .config_blk_start   (config_blk_start),
    .config_blk_end     (config_blk_end),
    .config_end         (config_end),
    .clr_stat_cnt   (clr_stat_cnt),
    .no_config_blk  (no_config_blk_pkt[31:16]),
    .no_config_pkt  (no_config_blk_pkt[15:0]),
    .no_config_byte (no_config_byte)
  );

  wire wfull, rempty;
  wire icap_ce, icap_write;
  wire [31:0] icap_i, icap_o;
  wire icap_busy;

  assign fifo_ready = ~wfull;
  wire winc = fifo_valid & fifo_ready;
  wire rinc = (icap_busy != IS_BUSY) & ~rempty;

	ASYN_fifo #(ICAP_DATA_WIDTH, ARRAY_SIZE) asyn_fifo_0
	(
		.wfull(wfull),		//1: full;  0: non full
    .wdata(fifo_wdata),
    .winc(winc),
    .wclk(ACLK), .wrst_n(ARESETN),

		.rempty(rempty),	//1: empty; 0: non empty + wait for 2 more clock to change the flag (for synchronous with wclk)
    .rdata(fifo_rdata),
		.rinc(rinc), 
    .rclk(ICAP_clock), .rrst_n( ICAP_reset_n)
	);
  
	assign icap_ce = rempty & dbg_icap_ce;
  assign icap_write = (dbg_icap_write & ~dbg_icap_ce);
  assign icap_i     = dbg_icap_ce ? fifo_rdata : dbg_icap_data_in;
  assign dbg_icap_data_out = icap_o;
  assign dbg_icap_busy     = icap_busy;

  //`define ICAP_SIM
  `define ICAP_TEST_BUF
  `ifdef ICAP_SIM
  ICAP_VIRTEX5_SIM_MODEL  #(.IS_BUSY(IS_BUSY)) ICAP_VIRTEX5_inst (
  	.CLK(ICAP_clock),			// 1-bit input: Clock Input
		.CE(icap_ce),				  // 1-bit input: Active-Low ICAP input Enable
		.WRITE(icap_write),	  // 1-bit input: (Read=1)/(Write=0) Select input
		.I(icap_i),						// ICAP_WIDTH - bit input: Configuration data input bus
		.O(icap_o),				    // ICAP_WIDTH -bit output: Configuration data output bus
		.BUSY(icap_busy)			// 1-bit output: Busy/Ready output
  );
  `else
    `ifdef ICAP_TEST_BUF
    ICAP_VIRTEX5_TEST_BUF  #(.IS_BUSY(IS_BUSY)) ICAP_VIRTEX5_inst (
      .CLK(ICAP_clock),			// 1-bit input: Clock Input
      .RST_N(ICAP_reset_n),
      .CE(icap_ce),				  // 1-bit input: Active-Low ICAP input Enable
      .WRITE(icap_write),	  // 1-bit input: (Read=1)/(Write=0) Select input
      .I(icap_i),						// ICAP_WIDTH - bit input: Configuration data input bus
      .O(icap_o),				    // ICAP_WIDTH -bit output: Configuration data output bus
      .BUSY(icap_busy)			// 1-bit output: Busy/Ready output
    );   
    `else
    ICAP_VIRTEX5 #(.ICAP_WIDTH("X32")) ICAP_VIRTEX5_inst (
      .CLK(ICAP_clock),			// 1-bit input: Clock Input
      .CE(icap_ce),				  // 1-bit input: Active-Low ICAP input Enable
      .WRITE(icap_write),	  // 1-bit input: Read/Write Select input
      .I(icap_i),						// ICAP_WIDTH - bit input: Configuration data input bus
      .O(icap_o),				    // ICAP_WIDTH -bit output: Configuration data output bus
      .BUSY(icap_busy)			// 1-bit output: Busy/Ready output
    ); 
    `endif
  `endif

  // Control FSM
  localparam IDLE               = 3'b000;
  localparam CONFIG_START       = 3'b001;
  localparam RECV_FIRST_BLK     = 3'b011;
  localparam RECV_END_BLK       = 3'b101;
  localparam RESET_CORE         = 3'b111;
  localparam SEND_CONFIG_RESULT = 3'b100;

  // Result packet FSM
  localparam RESULT_IDLE  = 2'b00;
  localparam RESULT_FIRST = 2'b10;
  localparam RESULT_LAST  = 2'b11;
  
  // Reset control FSM
  localparam RST_CTRL_IDLE = 2'b00;
  localparam RST_ACTIVE    = 2'b10;
  localparam RST_INACTIVE  = 2'b11;

  // Wait and reset counter
  localparam CNT_BW       = 4;
  localparam WAIT_CYCLE   = 4'hf;
  
  localparam RST_CNT_BW   = 5;
  localparam RST_CYCLE    = 5'h18;

  reg [2 : 0]         state, next_state; // Main state
  reg [1 : 0]         rst_ctrl_state, next_rst_ctrl_state; // Reset control sub-state
  reg [1 :0]          result_state, next_result_state; // AXI-S control sub-state to send result back to S/W
  reg [CNT_BW-1 : 0]      wait_cnt, next_wait_cnt; // Wait counter to be sure that PR is done
  reg [RST_CNT_BW-1 : 0]  rst_cnt, next_rst_cnt;   // Counter to specify reset active time

  reg [7:0]    save_header, next_save_header;
  reg [1:0]    save_core_sel, next_save_core_sel;

  reg [1:0]   core_enb, next_core_enb;        // To auto enable/disable scanner
  reg [1:0]   core_rst, next_core_rst;        // To auto reset scanner
  wire wait_cnt_expr = (wait_cnt == WAIT_CYCLE);
  wire rst_cnt_expr  = (rst_cnt  == RST_CYCLE);

  wire sync_rempty;
  single_bit_sync_n empty_sync (.clk(ACLK), .rst_n(ARESETN), .in_sig(rempty), .sync_sig(sync_rempty));

	always @(posedge ACLK)	begin
		if (~ARESETN) begin
      state         <= IDLE;
      wait_cnt      <= {CNT_BW{1'b0}};

      save_header   <= 8'b0;
      save_core_sel <= 2'b01; // Defaul is core 0

      core_enb      <= 2'b11;
    end
    else begin
      state         <= next_state;
      result_state  <= next_result_state;

      wait_cnt      <= next_wait_cnt;

      save_header   <= next_save_header;
      save_core_sel <= next_save_core_sel;

      core_enb      <= next_core_enb;
    end
	end

  always @* begin
    next_state = state;
    next_wait_cnt = wait_cnt;
    next_save_header = save_header;
    next_save_core_sel = save_core_sel;

    next_core_enb  = core_enb;

    case (state)
    IDLE: begin
      if (config_blk_start) begin
        next_state = CONFIG_START;
        next_save_header = S_AXIS_TDATA[31:24];
        next_save_core_sel = {S_AXIS_TDATA[26], ~S_AXIS_TDATA[26]};
      end
    end
    CONFIG_START: begin
      if (config_blk_end) begin
        next_state = config_end ? RECV_END_BLK : RECV_FIRST_BLK;
      end
    end
    RECV_FIRST_BLK: begin
      next_core_enb = {save_core_sel[0], save_core_sel[1]}; // Disable the selected core
      if (config_end) begin
        next_state = RECV_END_BLK;
      end
    end
    RECV_END_BLK: begin    
      next_core_enb = {save_core_sel[0], save_core_sel[1]}; // Disable the selected core
      if (wait_cnt_expr & sync_rempty) begin
        next_state = RESET_CORE;
        next_wait_cnt = 4'h0;
      end
      else begin
        next_wait_cnt = wait_cnt + 1'b1;
      end
    end

    RESET_CORE: begin
      next_core_enb  = {save_core_sel[0], save_core_sel[1]}; // Disable the selected core    
      if (~rst_ctrl_state[1]) begin // if reset seq. is done
        next_state = SEND_CONFIG_RESULT;
      end
    end

    SEND_CONFIG_RESULT: begin
      next_core_enb = 2'b11; // Enable all cores;    
      if (~result_state[1]) begin //  If result sending is done
        next_state = IDLE;
      end
    end

    endcase
  end
  
  assign icap_config_state = state;
  assign icap_core_enb = core_enb;

  // Send result via master AXI
	always @(posedge ACLK)	begin
		if (~ARESETN) begin
      rst_ctrl_state  <= RST_CTRL_IDLE;    
      result_state    <= RESULT_IDLE;
      
      rst_cnt         <= {RST_CNT_BW{1'b0}};
      clr_stat_cnt    <= 1'b0;
      
      core_rst        <= 2'b0;
    end
    else begin
      rst_ctrl_state  <= next_rst_ctrl_state;
      result_state    <= next_result_state;
      
      rst_cnt         <= next_rst_cnt;
      clr_stat_cnt    <= next_clr_stat_cnt & clr_stat_cnt_enb;
      
      core_rst        <= next_core_rst;      
    end
  end
  
  assign icap_core_rst = core_rst;  
  
  
    // Reset control
   always @* begin
    next_rst_ctrl_state = rst_ctrl_state;
    next_rst_cnt        = rst_cnt;
    next_core_rst       = core_rst;
    case(rst_ctrl_state)
    RST_CTRL_IDLE: begin
      next_rst_ctrl_state = (state == RECV_END_BLK) & (next_state == RESET_CORE) ? 
                           RST_ACTIVE : RST_CTRL_IDLE;
    end
    RST_ACTIVE: begin
      next_core_rst = {save_core_sel[1], save_core_sel[0]}; // Reset the config. core
      if (rst_cnt_expr) begin
        next_rst_ctrl_state = RST_INACTIVE;
        next_rst_cnt      = {RST_CNT_BW{1'b0}};
      end
      else begin
        next_rst_cnt = rst_cnt + 1'b1;
      end
    end
    RST_INACTIVE: begin
      next_core_rst = 2'b00;
      if (rst_cnt_expr) begin
        next_rst_ctrl_state = RST_CTRL_IDLE;
        next_rst_cnt      = {RST_CNT_BW{1'b0}};
      end
      else begin
        next_rst_cnt = rst_cnt + 1'b1;      
      end
    end
    endcase
  end
  
    // Sending configuration done status control
  always @* begin
    next_result_state = result_state;
    next_clr_stat_cnt = 1'b0;
    case(result_state)
    RESULT_IDLE: begin
      next_result_state = (next_state == SEND_CONFIG_RESULT) ? RESULT_FIRST : RESULT_IDLE;
    end
    RESULT_FIRST: begin
      next_result_state = (M_AXIS_TREADY) ? RESULT_LAST : RESULT_FIRST;
    end
    RESULT_LAST: begin
      next_result_state = (M_AXIS_TREADY) ? RESULT_IDLE : RESULT_LAST;
      next_clr_stat_cnt =  M_AXIS_TREADY;
    end
    endcase
  end
  
  // Configuration done packet
  assign M_AXIS_TDATA[31:0] = {save_header, config_icap_magic_code};
  //assign M_AXIS_TDATA[63:32] = {6'h20, 2'b11, 24'h0};
  assign M_AXIS_TDATA[63:32] = {6'h00, 2'b11, 24'h0};  
  assign M_AXIS_TDATA[95:64] =  no_config_blk_pkt[31:0];
  assign M_AXIS_TDATA[127:96] = no_config_byte;
  assign M_AXIS_TDATA[253:128] = 126'h0;
  assign M_AXIS_TDATA[255:254] = state;
  //assign M_AXIS_TLAST = 1'b1;
  assign M_AXIS_TLAST  = result_state[0];
  assign M_AXIS_TVALID = result_state[1];
  //assign M_AXIS_TUSER[15:0] = 16'h0020; // 32-byte
  assign M_AXIS_TUSER[15:0]   = 16'h0040; // 64-byte  
  assign M_AXIS_TUSER[23:16]  = config_icap_src[7:0];
  assign M_AXIS_TUSER[31:24]  = config_icap_dst[7:0];
  assign M_AXIS_TUSER[127:32] = 96'b0;
  assign M_AXIS_TSTRB = 32'hFFFF_FFFF; // All bytes are valid

endmodule
