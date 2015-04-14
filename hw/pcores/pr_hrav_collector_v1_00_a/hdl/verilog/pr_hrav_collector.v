//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Nguyen Van Quang Anh
// Email: nvqanh@gmail.com
// 
// Create Date:    
// Design Name: 
// Module Name:    pr_hrav_collector
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//    * This module is collect data from scanner 0, scanner 1, and ICAP controller
//      and send to S/W
//    * For now this is simply a MUX (arbiter), no modification or processing is done 
//      Arbiter scheme is FIFO and in packet basic. That means if a request from once source
//      is accepted, other sources can NOT get the bus till that source finished sending
//      the last cell (TLAST = 1'b1)
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

//----------------------------------------
// Module Section
//----------------------------------------
module pr_hrav_collector 
#(
    // Master AXI Stream Data Width
  parameter                              C_M_AXIS_DATA_WIDTH = 256,
  parameter                              C_S_AXIS_DATA_WIDTH = 256
  )
	(
		// Clock/reset
	input	ACLK,
	input	ARESETN,

    // Enable to de-coupling with scanner cores during reconfiguration
  input core_0_enb,
  input core_1_enb,

    // RX DMA interface to received data sent from S/W via PCIe EP
   output [C_M_AXIS_DATA_WIDTH-1:0]   M_AXIS_TDATA,
   output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]    M_AXIS_TSTRB,
   output          M_AXIS_TVALID,
   output [127:0]  M_AXIS_TUSER,
   output          M_AXIS_TLAST,
   input           M_AXIS_TREADY,

    // From scanner core 0
   input   [C_S_AXIS_DATA_WIDTH-1:0]  CORE0_S_AXIS_TDATA,
   input   [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   CORE0_S_AXIS_TSTRB,
   input           CORE0_S_AXIS_TVALID,
   input   [127:0] CORE0_S_AXIS_TUSER,
   input           CORE0_S_AXIS_TLAST,
   output          CORE0_S_AXIS_TREADY,

    // From scanner core 1
   input   [C_S_AXIS_DATA_WIDTH-1:0]  CORE1_S_AXIS_TDATA,
   input   [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   CORE1_S_AXIS_TSTRB,
   input           CORE1_S_AXIS_TVALID,
   input   [127:0] CORE1_S_AXIS_TUSER,
   input           CORE1_S_AXIS_TLAST,
   output          CORE1_S_AXIS_TREADY,

    // From ICAP controller
   input   [C_S_AXIS_DATA_WIDTH-1:0]  ICAP_S_AXIS_TDATA,
   input   [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   ICAP_S_AXIS_TSTRB,
   input           ICAP_S_AXIS_TVALID,
   input   [127:0] ICAP_S_AXIS_TUSER,
   input           ICAP_S_AXIS_TLAST,
   output          ICAP_S_AXIS_TREADY,

    // Debug interface
   input dbg_ctrl_0,
   input dbg_ctrl_1,
   input dbg_ctrl_2,
   input dbg_ctrl_3

	);

  /////////////////////////////////////////////////////
  // Double-buffer for timing closure
  localparam DAT_BW = C_M_AXIS_DATA_WIDTH+128+(C_M_AXIS_DATA_WIDTH/8) + 1;
  wire [2:0] dbuf_ready;
  wire [2:0] dbuf_valid;
  wire [DAT_BW-1:0] core0_data;
  wire [DAT_BW-1:0] core1_data;
  wire [DAT_BW-1:0] icap_data;
  pr_hrav_dbuf #(.DAT_BW(DAT_BW)) core0_dbuf( // Core 0
    // Clock, reset
    .clk(ACLK), .rst_n(ARESETN),
    // Write interface
    .vld_in(CORE0_S_AXIS_TVALID & core_0_enb),
    .data_in({CORE0_S_AXIS_TLAST, CORE0_S_AXIS_TUSER, CORE0_S_AXIS_TSTRB, CORE0_S_AXIS_TDATA}), 
    .ready_out(CORE0_S_AXIS_TREADY),
    // Read interface
    .ready_in(dbuf_ready[0]), .vld_out(dbuf_valid[0]), .data_out(core0_data)
  );

  pr_hrav_dbuf #(.DAT_BW(DAT_BW)) core1_dbuf( // Core 1
    // Clock, reset
    .clk(ACLK), .rst_n(ARESETN),
    // Write interface
    .vld_in(CORE1_S_AXIS_TVALID & core_1_enb),
    .data_in({CORE1_S_AXIS_TLAST, CORE1_S_AXIS_TUSER, CORE1_S_AXIS_TSTRB, CORE1_S_AXIS_TDATA}), 
    .ready_out(CORE1_S_AXIS_TREADY),
    // Read interface
    .ready_in(dbuf_ready[1]), .vld_out(dbuf_valid[1]), .data_out(core1_data)
  );

  pr_hrav_dbuf #(.DAT_BW(DAT_BW)) icap_dbuf( // ICAP controller
    // Clock, reset
    .clk(ACLK), .rst_n(ARESETN),
    // Write interface
    .vld_in(ICAP_S_AXIS_TVALID),
    .data_in({ICAP_S_AXIS_TLAST, ICAP_S_AXIS_TUSER, ICAP_S_AXIS_TSTRB, ICAP_S_AXIS_TDATA}), 
    .ready_out(ICAP_S_AXIS_TREADY),
    // Read interface
    .ready_in(dbuf_ready[2]), .vld_out(dbuf_valid[2]), .data_out(icap_data)
  );

  // Arbiter FSM to make sure once a request is accepted, it's granted till last cell is sent
  localparam IDLE       = 3'b000; // In this state, arbitration is done based on arb_pri
  localparam CORE0_PKT  = 3'b001; // In this state, arbitraion is not done, only packet from core0 is granted
  localparam CORE1_PKT  = 3'b010; // In this state, arbitraion is not done, only packet from core1 is granted
  localparam ICAP_PKT   = 3'b100; // In this state, arbitraion is not done, only packet from icap is granted

  reg [2:0] state, nxt_state;
  always @(posedge ACLK) begin
    if(~ARESETN)       state <= IDLE;
    else               state <= nxt_state;
  end
  
  reg [2:0]  gnt_sel;
  wire send_data, last_data;
  always @* begin
    nxt_state = state;
    case(state)
      IDLE: begin
        if (send_data & ~last_data) begin // State in this state if packet length is just once cell
          nxt_state = ({3{gnt_sel[0]}} & CORE0_PKT) |
                      ({3{gnt_sel[1]}} & CORE1_PKT) |
                      ({3{gnt_sel[2]}} & ICAP_PKT);
        end
      end
      CORE0_PKT, CORE1_PKT, ICAP_PKT: nxt_state = (send_data & last_data) ? IDLE : state;
    endcase
  end

  // FIFO priority scheme between scanner core
  reg [2:0] arb_pri_0, arb_pri_1, arb_pri_2;
  reg [2:0] nxt_arb_pri_0, nxt_arb_pri_1, nxt_arb_pri_2;
  always @(posedge ACLK) begin
    if(~ARESETN)  begin
      arb_pri_0 <= CORE0_PKT; // Core 0 has first priority
      arb_pri_1 <= CORE1_PKT; // Core 1 has second priority
      arb_pri_2 <= ICAP_PKT;  // ICAP controller has the lowest priority
    end
    else if (send_data) begin
      {arb_pri_0, arb_pri_1, arb_pri_2} <= {nxt_arb_pri_0, nxt_arb_pri_1, nxt_arb_pri_2};
    end
  end

  // Arbiter
  always @* begin
    nxt_arb_pri_0 = arb_pri_0;
    nxt_arb_pri_1 = arb_pri_1;
    nxt_arb_pri_2 = arb_pri_2;
    gnt_sel       = 3'b000;
    case (state)
    IDLE: begin
      if (|(arb_pri_0 & dbuf_valid[2:0])) begin // Highest priority req. is requested
        // Assign the winner
        gnt_sel       = arb_pri_0;
        // Update all priority registers
        nxt_arb_pri_0 = arb_pri_1;
        nxt_arb_pri_1 = arb_pri_2;
        nxt_arb_pri_2 = arb_pri_0;
      end
      else if (|(arb_pri_1 & dbuf_valid[2:0])) begin // Second priority req. is requested
        // Assign the winner
        gnt_sel       = arb_pri_1;
        // Update 2nd to least priority registers
        nxt_arb_pri_1 = arb_pri_2;
        nxt_arb_pri_2 = arb_pri_1;
      end
      else if (|(arb_pri_2 & dbuf_valid[2:0])) begin // Least priority req. is requested
        // Assign the winner
        gnt_sel       = arb_pri_2;
        // No need to update priority
      end
    end
    CORE0_PKT: gnt_sel[0] = 1'b1; // Always core 0 is granted
    CORE1_PKT: gnt_sel[1] = 1'b1; // Always core 1 is granted
    ICAP_PKT:  gnt_sel[2] = 1'b1; // Always ICAP controller is granted
    endcase
  end

  // Output selector based on arbitration result
  assign dbuf_ready = gnt_sel & {3{M_AXIS_TREADY}};
  wire [DAT_BW-1:0] sel_core0_data = dbg_ctrl_0 ? {core0_data[DAT_BW-1:24], 24'hA1B1C1} : core0_data;
  wire [DAT_BW-1:0] sel_core1_data = dbg_ctrl_1 ? {core1_data[DAT_BW-1:24], 24'hD2E2F2} : core1_data;
  wire [DAT_BW-1:0] sel_icap_data  = dbg_ctrl_2 ? {icap_data[DAT_BW-1:24],  24'hC3A3B3} : icap_data;
  assign {last_data, M_AXIS_TUSER, M_AXIS_TSTRB, M_AXIS_TDATA} = ({DAT_BW{gnt_sel[0]}} & sel_core0_data) |
                                                                 ({DAT_BW{gnt_sel[1]}} & sel_core1_data) |
                                                                 ({DAT_BW{gnt_sel[2]}} & sel_icap_data);
  assign M_AXIS_TLAST = last_data;

  wire [3:0] gnt_valid = (dbuf_valid & gnt_sel);

  // Handsake with TX DMA
  assign M_AXIS_TVALID = |gnt_valid; 
  assign send_data = (|gnt_valid) & M_AXIS_TREADY;

endmodule

