// This modue is a double buffer for ease of timing
module	pr_hrav_dbuf  #(parameter DAT_BW=128)
  (
  // System IF
  input  wire                 clk,
  input  wire                 rst_n,

  // Input data IF
  input  wire                 vld_in,
  input  wire [DAT_BW-1:0]    data_in,
  output wire                 ready_out,
  
  // Output data IF
  input   wire                ready_in,
  output  wire			          vld_out,
  output  wire [DAT_BW-1:0]   data_out
  );

  // 1. Control FSM
    // FSM state map
  parameter EMPTY = 2'b00,  // Buffer is empty, can receive up to 2 data regarless of the output side readiness
            HALF  = 2'b01,  // 1 slot is input but not yet output, in this state at max recieve 1 more data
            FULL  = 2'b11;  // 2 slot are input but not yet output, in this state can not receive more data
  
  reg [1:0] buf_state, nxt_buf_state;
  
  // Current state
  always @(posedge clk) begin
    if (~rst_n) buf_state <= EMPTY;
    else        buf_state <= nxt_buf_state;
  end
  
  // State transition
  always @*  begin
    nxt_buf_state = buf_state; // By default, keep at current state
    
    case (buf_state)
    EMPTY: begin
      if (vld_in) nxt_buf_state = HALF; // Receive 1 data so move to HALF state b/c at least next cycle data can be output
    end
    
    HALF: begin
      if (vld_in && ~ready_in) nxt_buf_state = FULL; // Receive 1 more data but output side is not ready so buf get full
      else if (~vld_in && ready_in) nxt_buf_state = EMPTY; // Don't receive more data, and output side is ready to ready so fifo get empty
      // Note incase "vld_in = 1 and read_in = 1" are asserted at same time, then keep in this state b/c data is input and output at same time
    end
    
    FULL: begin
      if (ready_in) nxt_buf_state = HALF; // No more data can be pushed so simply wait if output side is ready to output data and back to HALF
    end    
    endcase
  end
  
  // State decoder
  reg buf_1_en, buf_2_en;
  reg buf_1_data_sel;
  always @* begin
    buf_1_en = 1'b0;        // At output side
    buf_2_en = 1'b0;        // Internal side to store data when it's impossible to foward data
    buf_1_data_sel = 1'b0;  // To select among data input or from buf_2 to save in buf_1
    
   case (buf_state)
    EMPTY: begin
      if (vld_in) buf_1_en = 1'b1;  // Write to buffer 1
    end
    
    HALF: begin
      buf_2_en = 1'b1;               // Enable write data to buffer 2 to save data, just in case can not send out data (next is FULL)
      if (ready_in) buf_1_en = 1'b1; // As output side is ready, so get next data to send out
    end
    
    FULL: begin
      buf_1_data_sel = 1'b1;  // At this state, need to toogle this signal to select saved data from buf 2, not directly from input data size
      if (ready_in) buf_1_en = 1'b1; // As output side is ready, so get next data to send out
    end    
    endcase    
    
  end
  
  // 2. Data-path
  reg [DAT_BW-1:0] buf_1, buf_2;
  always @(posedge clk) begin
    if (~rst_n)         buf_1 <= {DAT_BW{1'b0}};
    else if (buf_1_en)  buf_1 <= buf_1_data_sel ? buf_2 : data_in;
  end
  
  always @(posedge clk) begin
    if (~rst_n)         buf_2 <= {DAT_BW{1'b0}};
    else if (buf_2_en)  buf_2 <= data_in;
  end
 
  // 3. Output wire (all are from FF so timing should be fine at later development phase)
  assign ready_out  = ~buf_state[1]; // (Allow receiving data if not in FULl state)
  
  assign vld_out    = buf_state[0];  // (Half or Full state)
  assign data_out   = buf_1;
  
endmodule

