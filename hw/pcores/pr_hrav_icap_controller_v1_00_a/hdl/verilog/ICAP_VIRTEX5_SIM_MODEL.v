// This is simulation model for ICAP primitives
module ICAP_VIRTEX5_SIM_MODEL #(
    parameter ICAP_WIDTH = 32,
    parameter MEM_ADDR_WIDTH  = 8,
    parameter IS_BUSY   = 1'b0) 
(
  	input CLK,                // 1-bit input: Clock Input
		input CE,                 // 1-bit input: Active-Low ICAP input Enable
		input WRITE,	            // 1-bit input: Read=1/Write=0 Select input
		input  [ICAP_WIDTH-1:0] I,// ICAP_WIDTH - bit input: Configuration data input bus
		output [ICAP_WIDTH-1:0] O,// ICAP_WIDTH -bit output: Configuration data output bus
		output BUSY           		// 1-bit output: Busy/Ready output
);

reg [ICAP_WIDTH-1:0] mem_array [2**MEM_ADDR_WIDTH-1:0];
reg icap_busy;
reg [ICAP_WIDTH-1:0] rd_data;
reg [MEM_ADDR_WIDTH-1:0] rd_ptr, wr_ptr;
wire [MEM_ADDR_WIDTH-1:0] nxt_rd_ptr, nxt_wr_ptr;
reg full, empty;

always @(posedge CLK) begin
  icap_busy <= full ? IS_BUSY : // Busy if full
            ((({$random()} % 5) == 4) ? IS_BUSY : ~IS_BUSY); // 20% busy model
end

assign nxt_rd_ptr = rd_ptr + 1'b1;
assign nxt_wr_ptr = wr_ptr + 1'b1;

always @(posedge CLK) begin
  //Read
  if (~CE & WRITE & (icap_busy != IS_BUSY) & ~empty) begin
    rd_data <= mem_array[rd_ptr];
    rd_ptr  <= nxt_rd_ptr;
    if (nxt_rd_ptr == wr_ptr) empty <= 1'b1;
    else if ((nxt_rd_ptr > wr_ptr) | (nxt_rd_ptr == 0)) full <= 1'b0;
  end
  
  // Write
  if (~CE & ~WRITE & (icap_busy != IS_BUSY)) begin
    mem_array[wr_ptr] <= I;
    wr_ptr <= nxt_wr_ptr;
    if (nxt_wr_ptr == rd_ptr) full <= 1'b1;
    else if ((nxt_wr_ptr > rd_ptr) | (nxt_wr_ptr == 0)) empty <= 1'b0;
  end  
end

// Output wires
assign O = rd_data;
assign BUSY = icap_busy;

initial begin
  rd_ptr = 0;
  wr_ptr = 0;
  full   = 0;
  empty  = 1;
end

endmodule
