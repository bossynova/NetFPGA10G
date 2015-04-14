module icap_debug_controller #(
    parameter ICAP_WIDTH = 32,
    parameter IS_BUSY   = 1'b0) 
(
   input S_AXI_ACLK,
   input S_AXI_ARESETN,
   input ICAP_clk,
   input ICAP_reset_n,

    // Register file read interface
   input                        reg2icap_rd_req,
   output reg                   icap2reg_rd_ready,
   output reg [ICAP_WIDTH-1:0]  icap2reg_rd_data,

    // Register file write
   input                  reg2icap_wr_req,
   input [ICAP_WIDTH-1:0] reg2icap_wr_data,
   output reg             icap2reg_wr_ready,

    // ICAP controller interface
   output reg                   dbg_icap_ce,
   output reg                   dbg_icap_write,
   output reg [ICAP_WIDTH-1:0]  dbg_icap_data_in,
   input  [ICAP_WIDTH-1:0]      dbg_icap_data_out,
   input                        dbg_icap_busy
);

 // ACLK domain
  reg req_hold;
  reg [ICAP_WIDTH-1:0] dbg_rd_data, dbg_wr_data;
  wire icap_ack;
  reg [3:0]  ack_wait_count;
  always @(posedge S_AXI_ACLK) begin
    if (~S_AXI_ARESETN) begin
      req_hold <= 1'b0;
      icap2reg_wr_ready <= 1'b0;
      icap2reg_rd_ready <= 1'b0;
    end
    else if (req_hold & icap_ack) begin
      req_hold <= 1'b0;
      icap2reg_wr_ready <= reg2icap_wr_req;
      icap2reg_rd_ready <= reg2icap_rd_req;
      // Capture read data to register 
      icap2reg_rd_data  <= dbg_rd_data;
    end
    else if (~req_hold & (reg2icap_rd_req | reg2icap_wr_req)) begin
      req_hold          <= 1'b1;
      icap2reg_wr_ready <= 1'b0;
      icap2reg_rd_ready <= 1'b0;

      // Capture write data to send to ICAP domain
      if (reg2icap_wr_req) dbg_wr_data <= reg2icap_wr_data;
    end
  end

  localparam ACK_WAIT_CYCLE = 8;
  always @(posedge S_AXI_ACLK) begin
    if (~S_AXI_ARESETN) ack_wait_count <= 4'b0;
    else if (~req_hold & (reg2icap_rd_req | reg2icap_wr_req)) ack_wait_count <= 4'b0;
    else if (req_hold & (ack_wait_count < ACK_WAIT_CYCLE)) begin
      ack_wait_count <= ack_wait_count + 1'b1;
    end
  end

  // Sync
  wire icap_busy_sync;
  reg icap_busy;
  single_bit_sync_n busy_sync (.clk(S_AXI_ACLK), .rst_n(S_AXI_ARESETN), .in_sig(icap_busy), .sync_sig(icap_busy_sync));

    // Wait fixed ACK_WAIT_CYCLE to cope with the delay of acknowledge
    // due to synchronization delay, then go check if ICAP is busy, if not
    // then confirmed that request is acknowledge
  assign icap_ack = req_hold & (ack_wait_count == ACK_WAIT_CYCLE) & (icap_busy_sync != IS_BUSY);

  // ICAP domain
 
  wire icap_rd_req, icap_wr_req; 
  single_bit_sync_n rd_req_sync (.clk(ICAP_clk), .rst_n(ICAP_reset_n), .in_sig(reg2icap_rd_req), .sync_sig(icap_rd_req));
  single_bit_sync_n wr_req_sync (.clk(ICAP_clk), .rst_n(ICAP_reset_n), .in_sig(reg2icap_wr_req), .sync_sig(icap_wr_req));

  // Receive request
  reg  icap_rd_req_q, icap_wr_req_q;
  wire rd_req_redge, wr_req_redge;
  always @(posedge ICAP_clk) begin
    if (~ICAP_reset_n) {icap_rd_req_q, icap_wr_req_q} <= 2'b0;
    else               {icap_rd_req_q, icap_wr_req_q} <= {icap_rd_req, icap_wr_req};
  end
  assign rd_req_redge = (icap_rd_req & ~icap_rd_req_q);
  assign wr_req_redge = (icap_wr_req & ~icap_wr_req_q);

  // FIXME need to consider if we should asynchronous reset
  always @(posedge ICAP_clk) begin
    if (~ICAP_reset_n) begin
      dbg_icap_ce    <= 1'b1;     // Inactive
      dbg_icap_write <= 1'b1; // Write
    end 
    else if (rd_req_redge | wr_req_redge) begin
      dbg_icap_ce    <= 1'b0;
      dbg_icap_write <= rd_req_redge;
      if (wr_req_redge) dbg_icap_data_in <= dbg_wr_data;
    end
    else if (dbg_icap_busy != IS_BUSY) begin
      dbg_icap_ce   <= 1'b1; 
    end
  end
 
  reg dbg_icap_rd_en;
  always @(posedge ICAP_clk) begin
    dbg_icap_rd_en <= ~dbg_icap_ce & dbg_icap_write & (dbg_icap_busy != IS_BUSY);
    if (dbg_icap_rd_en) dbg_rd_data <= dbg_icap_data_out;
  end 

  // ACK and read data return
  always @(posedge ICAP_clk) begin
    if (~ICAP_reset_n) icap_busy <= 1'b1;
    else               icap_busy <= dbg_icap_busy;
  end
   
endmodule