//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Nguyen Van Quang Anh
// Email: nvqanh@gmail.com
// 
// Create Date:    
// Design Name: 
// Module Name:    pr_hrav_dispatcher
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//    * This module is to interface with SW in-order to dispatch data
//    to either scanner core 0, scanner 1 or ICAP controller
//    * Currently, dispatcher is based on HEADER[4] of the packet
//      to dispatch data received from S/W. Rule is as below
//      [1:0]: 00, 01, 10 To scanner core
//             11         To ICAP
//      [2]  : 0  To core 0
//             1  To core 1
//    * Note that packet is FWD. as it is, no modification is done          
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

//----------------------------------------
// Module Section
//----------------------------------------
module pr_hrav_dispatcher 
#(
    // Master AXI Stream Data Width
  parameter                              C_M_AXIS_DATA_WIDTH = 256,
  parameter                              C_S_AXIS_DATA_WIDTH = 256,
  )
	(
		// Clock/reset
		ACLK,
		ARESETN,

    // RX DMA interface to received data sent from S/W via PCIe EP
   input [C_S_AXIS_DATA_WIDTH-1:0]   S_AXIS_TDATA,
   input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]    S_AXIS_TSTRB,
   input          S_AXIS_TVALID,
   output         S_AXIS_TREADY,
   input [127:0]  S_AXIS_TUSER,
   input          S_AXIS_TLAST,

    // To scanner core 0
   output  [C_M_AXIS_DATA_WIDTH-1:0]  CORE0_M_AXIS_TDATA,
   output  [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   CORE0_M_AXIS_TSTRB,
   output          CORE0_M_AXIS_TVALID,
   output  [127:0] CORE0_M_AXIS_TUSER,
   input           CORE0_M_AXIS_TREADY,
   output          CORE0_M_AXIS_TLAST,

    // To scanner core 1
   output  [C_M_AXIS_DATA_WIDTH-1:0]  CORE1_M_AXIS_TDATA,
   output  [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   CORE1_M_AXIS_TSTRB,
   output          CORE1_M_AXIS_TVALID,
   output  [127:0] CORE1_M_AXIS_TUSER,
   input           CORE1_M_AXIS_TREADY,
   output          CORE1_M_AXIS_TLAST,

    // To ICAP controller
   output  [C_M_AXIS_DATA_WIDTH-1:0]  ICAP_M_AXIS_TDATA,
   output  [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   ICAP_M_AXIS_TSTRB,
   output          ICAP_M_AXIS_TVALID,
   output  [127:0] ICAP_M_AXIS_TUSER,
   input           ICAP_M_AXIS_TREADY,
   output          ICAP_M_AXIS_TLAST

    // Debug interface
    // TBD
	);

  //Handsake with RX DMA
  reg fifo_rdy;
  wire accept_data, accept_last_data;
  assign S_AXIS_TREADY = fifo_rdy;
  assign accept_data   = S_AXIS_TVALID & fifo_rdy;
  assign accept_last_data = accept_data & S_AXIS_TLAST;
  /////////////////////////////////////////////////////

  // Dispatcher FSM
    // FSM mapping
  parameter HEADER    = 3'b000; // State to receive and parse header
  parameter CORE0_PKT = 3'b001; // In this state, packet is fwd. to scanner core 0
  parameter CORE1_PKT = 3'b010; // In this state, packet is fwd. to scanner core 1
  parameter ICAP_PKT  = 3'b100; // In this state, packet is fwd. to ICAP controller

    // Dispatcher decoder
  wire [2:0] dis_patch_header = S_AXIS_TDATA[26:24]; // Bit [2:0] of HEADER[4]
  wire [2:0] dst_sel =   (dis_patch_header[1:0] == 2'b11) ? 3'b100  // ICAP
                        : dis_patch_header[2]             ? 3'b010  // Core 1
                        :                                   3'b001; // Core 0
    // FSM Seq. logic
  reg [2:0] state, nxt_state;
  always @(posedge ACLK) begin
    if(~ARESETN) state         <= HEADER;
    else         state         <= nxt_state;
  end
  
    // FSM Comb. logic
  reg  [2:0]  in_fifo_wr_en;
  wire [2:0]  in_fifo_nearly_full;
  always @ (*) begin
    fifo_rdy        = 1'b0;
    in_fifo_wr_en   = 3'b0;

    nxt_state = state;   
    case (state)
    HEADER: begin
      // Control
      fifo_rdy = (~in_fifo_nearly_full[0] & dst_sel[0]) |
                 (~in_fifo_nearly_full[1] & dst_sel[1])
                 (~in_fifo_nearly_full[2] & dst_sel[2]);
      in_fifo_wr_en = accept_data ? dst_sel : 3'b0;

     // State transition
      if (accept_data) begin
        nxt_state = ({3{dst_sel[0]}} & CORE0_PKT) |
                    ({3{dst_sel[1]}} & CORE1_PKT) |
                    ({3{dst_sel[2]}} & ICAP_PKT);
      end
    end
    CORE0_PKT: begin
      // Control
      fifo_rdy = ~in_fifo_nearly_full[0];
      in_fifo_wr_en[0] = accept_data;
      // State transition
      nxt_state = accept_last_data ? HEADER : CORE0_PKT;
    end
    CORE1_PKT: begin
      // Control
      fifo_rdy = ~in_fifo_nearly_full[1];
      in_fifo_wr_en[1] = accept_data;
     // State transition
      nxt_state = accept_last_data ? HEADER : CORE1_PKT;
    end
    ICAP_PKT: begin
      // Control
      fifo_rdy = ~in_fifo_nearly_full[2];
      in_fifo_wr_en[2] = accept_data;
     // State transition
      nxt_state = accept_last_data ? HEADER : ICAP_PKT;
    end
    endcase  
  end
  /////////////////////////////////////////////////////

  // Output hand-sake with downstream FIFO
  wire [2:0] in_fifo_empty;
  wire [2:0] in_fifo_rd_en = {ICAP_M_AXIS_TVALID  & ICAP_M_AXIS_TREADY,
                              CORE1_M_AXIS_TVALID & CORE1_M_AXIS_TREADY,
                              CORE0_M_AXIS_TVALID & CORE0_M_AXIS_TREADY};
  assign {ICAP_M_AXIS_TVALID, CORE1_M_AXIS_TVALID, CORE0_M_AXIS_TVALID} = ~in_fifo_empty;

  /////////////////////////////////////////////////////
  // Double-buffer for timing closure
  parameter DAT_DW = C_M_AXIS_DATA_WIDTH+128+C_M_AXIS_DATA_WIDTH/8 + 1;
  wire [DAT_DW: 0] dbuf_data_in;
  assign dbuf_data_in = {S_AXIS_TLAST, S_AXIS_TUSER, S_AXIS_TSTRB, S_AXIS_TDATA};
  pr_hrav_dispatcher_dbuf #( .DAT_BW(DAT_DW),.MAX_DEPTH_BITS(3)) core0_dbuf( // Core 0
    // Clock, reset
    .clk(ACLK), .rst_n(ARESETN),
    // Write interface
    .vld_in(valid[0]), data_in(dbuf_data_in), ready_out(ready[0]),
    // Read interface
    .ready_in(CORE0_M_AXIS_TREADY), vld_out(CORE0_M_AXIS_TVALID), 
    .data_out({CORE0_M_AXIS_TLAST, CORE0_M_AXIS_TUSER, CORE0_M_AXIS_TSTRB, CORE0_M_AXIS_TDATA});

  fallthrough_small_fifo #( .WIDTH(FIFO_DW),.MAX_DEPTH_BITS(3))  fifo_core_0
    (// Outputs
     .dout                           ({CORE0_M_AXIS_TLAST, CORE0_M_AXIS_TUSER, CORE0_M_AXIS_TSTRB, CORE0_M_AXIS_TDATA}),
     .full                           (),
     .nearly_full                    (in_fifo_nearly_full[0]),
     .prog_full                      (),
     .empty                          (in_fifo_empty[0]),
     // Inputs
     .din                            (in_fifo_din),
     .wr_en                          (in_fifo_wr_en[0]),
     .rd_en                          (in_fifo_rd_en[0]),
     .reset                          (~RESETN),
     .clk                            (ACLK)
     );

  fallthrough_small_fifo #( .WIDTH(FIFO_DW),.MAX_DEPTH_BITS(3))  fifo_core_1
    (// Outputs
     .dout                           ({CORE1_M_AXIS_TLAST, CORE1_M_AXIS_TUSER, CORE1_M_AXIS_TSTRB, CORE1_M_AXIS_TDATA}),
     .full                           (),
     .nearly_full                    (in_fifo_nearly_full[1]),
     .prog_full                      (),
     .empty                          (in_fifo_empty[1]),
     // Inputs
     .din                            (in_fifo_din),
     .wr_en                          (in_fifo_wr_en[1]),
     .rd_en                          (in_fifo_rd_en[1]),
     .reset                          (~ARESETN),
     .clk                            (ACLK)
     ); 

  fallthrough_small_fifo #( .WIDTH(FIFO_DW),.MAX_DEPTH_BITS(3))  fifo_icap
    (// Outputs
     .dout                           ({ICAP_M_AXIS_TLAST, ICAP_M_AXIS_TUSER, ICAP_M_AXIS_TSTRB, ICAP_M_AXIS_TDATA}),
     .full                           (),
     .nearly_full                    (in_fifo_nearly_full[2]),
     .prog_full                      (),
     .empty                          (in_fifo_empty[2]),
     // Inputs
     .din                            (in_fifo_din),
     .wr_en                          (in_fifo_wr_en[2]),
     .rd_en                          (in_fifo_rd_en[2]),
     .reset                          (~ARESETN),
     .clk                            (ACLK)
     ); 
endmodule
