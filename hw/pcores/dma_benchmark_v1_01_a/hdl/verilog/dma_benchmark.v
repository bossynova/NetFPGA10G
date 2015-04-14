//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Tran Trung Hieu
// Email: hieutt@hcmut.edu.vn
// 
// Create Date:    
// Design Name: 
// Module Name:    dma_benchmark 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.00 - Add debug control out register to for dispatcher/collector
//                 debug control Mar 14, 2015 anhqvn
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

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
module dma_benchmark 
#(
    // Master AXI Stream Data Width
  parameter                              C_M_AXIS_DATA_WIDTH = 256,
  parameter                              C_S_AXIS_DATA_WIDTH = 256,
  parameter USER_MAGIC_CODE = 24'haecafe,
  parameter C_BASEADDR=32'hffffffff,
  parameter C_HIGHADDR=32'h0
  )
	(
   input          ACLK,
   input          RESETN,

   // Rev 1.00
   output         dbg_ctrl_0,
   output         dbg_ctrl_1,
   output         dbg_ctrl_2,
   output         dbg_ctrl_3,
   //

   output reg [C_M_AXIS_DATA_WIDTH-1:0]  M_AXIS_TDATA,
   output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]   M_AXIS_TSTRB,
   output reg         M_AXIS_TVALID,
   output reg [127:0] M_AXIS_TUSER,
   input              M_AXIS_TREADY,
   output reg         M_AXIS_TLAST,
  
   input [C_M_AXIS_DATA_WIDTH-1:0]   S_AXIS_TDATA,
   input [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]    S_AXIS_TSTRB,
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
  localparam C_M_AXIS_TUSER_WIDTH = 128;
  localparam C_S_AXIS_TUSER_WIDTH = 128;
  

  localparam STATE_IDLE = 0;
  localparam STATE_USER_PACKET = 1;
  localparam STATE_IP_PACKET = 2;
  localparam STATE_END_PACKET = 3;

  localparam SRC0 = 0;
  localparam SRC1 = 1;
  localparam SRC2 = 2;
  localparam SRC3 = 3;
  localparam SRCA = 4;
  //------------Wires--------------



     reg [5*32 -1: 0] no_packet, no_packet_next;
     reg [5*32 -1: 0] no_user_packet, no_user_packet_next;
     reg [5*32 -1: 0] total_length, total_length_next;
     reg [5*32 -1: 0] no_tdata, no_tdata_next;
     reg [5*32 -1: 0] speed_data; //byte per million clock
     reg [5*32 -1: 0] speed_packet; //packet per million clock

    wire [7:0] source_port_mask; // where is data come from.
    wire [7:0] source_port;
    reg [31:0] clock_counter; 
    reg [32*5-1:0] prev_packet;
    reg [32*5-1:0] prev_data; 


  wire in_fifo_nearly_full;
  wire in_fifo_empty;
   reg in_fifo_rd_en;

   wire [C_M_AXIS_DATA_WIDTH - 1:0] fifo_axis_tdata;
   wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] fifo_axis_tstrb;
   wire [C_M_AXIS_TUSER_WIDTH-1:0] fifo_axis_tuser;
   wire fifo_axis_tlast;

  reg [2:0] state;
   reg [2:0] state_next;


   // Rev 1.00
   wire [31:0] dbg_ctrl_out;


//------------Modules -----------------
  fallthrough_small_fifo
    #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
       .MAX_DEPTH_BITS(3))
  input_fifo
    (// Outputs
     .dout                           ({fifo_axis_tlast, fifo_axis_tuser, fifo_axis_tstrb, fifo_axis_tdata}),
     .full                           (),
     .nearly_full                    (in_fifo_nearly_full),
     .prog_full                      (),
     .empty                          (in_fifo_empty),
     // Inputs
     .din                            ({S_AXIS_TLAST, S_AXIS_TUSER, S_AXIS_TSTRB, S_AXIS_TDATA}),
     .wr_en                          (S_AXIS_TVALID & ~in_fifo_nearly_full),
     .rd_en                          (in_fifo_rd_en),
     .reset                          (~RESETN),
     .clk                            (ACLK)
     );


  dma_benchmark_controller  controler
     (
      // dma benchmark control signal.
      // Rev 1.00
      .dbg_ctrl_out(dbg_ctrl_out),
      //
      .benchmark_rst(benchmark_rst),
      .benchmark_en(benchmark_en),
      .benchmark_inf_recv(benchmark_inf_recv),
      .source_port_mask(source_port_mask),
      .reg_no_packet(no_packet),
      .reg_no_user_packet(no_user_packet),
      .reg_total_length(total_length),
      .reg_no_tdata(no_tdata),
      .reg_speed_packet(speed_packet),
      .reg_speed_data(speed_data),
      .clock_counter(clock_counter),
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

    assign source_port = source_port_mask & fifo_axis_tuser[23:16];
     
     // ------------- Logic ----------------

   assign S_AXIS_TREADY = !in_fifo_nearly_full;
   assign local_M_AXIS_TREADY = (benchmark_inf_recv)?1'b1:M_AXIS_TREADY;

    always@(*)begin
      state_next = state;

      in_fifo_rd_en = 0;

      M_AXIS_TVALID = 0;
      M_AXIS_TUSER = 0;
      M_AXIS_TDATA = 0;
      M_AXIS_TLAST = 0;
      M_AXIS_TSTRB = 0;

      no_user_packet_next = no_user_packet;
      no_packet_next = no_packet;
      no_tdata_next = no_tdata;
      total_length_next = total_length;

      case(state)
        STATE_IDLE: begin
          M_AXIS_TVALID = !in_fifo_empty;
          in_fifo_rd_en = M_AXIS_TVALID && local_M_AXIS_TREADY;
          M_AXIS_TUSER = fifo_axis_tuser;
          M_AXIS_TDATA = fifo_axis_tdata;
          M_AXIS_TLAST = fifo_axis_tlast;
          M_AXIS_TSTRB = fifo_axis_tstrb;

          if(M_AXIS_TVALID && local_M_AXIS_TREADY)begin
            //Increase counter
            if(source_port[1])begin // from CPU 0
              no_packet_next[32*SRC0+31:32*SRC0] = no_packet[32*SRC0+31:32*SRC0] + 1;
              no_tdata_next[32*SRC0+31:32*SRC0] = no_tdata[32*SRC0+31:32*SRC0] +1;
              total_length_next[32*SRC0+31:32*SRC0] = total_length[32*SRC0+31:32*SRC0] + fifo_axis_tuser[15:0];
            end
            if(source_port[3])begin // from CPU 1
              no_packet_next[32*SRC1+31:32*SRC1] = no_packet[32*SRC1+31:32*SRC1] + 1;
              no_tdata_next[32*SRC1+31:32*SRC1] = no_tdata[32*SRC1+31:32*SRC1] +1;
              total_length_next[32*SRC1+31:32*SRC1] = total_length[32*SRC1+31:32*SRC1] + fifo_axis_tuser[15:0];
            end
            if(source_port[5])begin // from CPU 2
              no_packet_next[32*SRC2+31:32*SRC2] = no_packet[32*SRC2+31:32*SRC2] + 1;
              no_tdata_next[32*SRC2+31:32*SRC2] = no_tdata[32*SRC2+31:32*SRC2] +1;
              total_length_next[32*SRC2+31:32*SRC2] = total_length[32*SRC2+31:32*SRC2] + fifo_axis_tuser[15:0];
            end
            if(source_port[7])begin // from CPU 3
              no_packet_next[32*SRC3+31:32*SRC3] = no_packet[32*SRC3+31:32*SRC3] + 1;
              no_tdata_next[32*SRC3+31:32*SRC3] = no_tdata[32*SRC3+31:32*SRC3] +1;
              total_length_next[32*SRC3+31:32*SRC3] = total_length[32*SRC3+31:32*SRC3] + fifo_axis_tuser[15:0];
            end
            no_packet_next[32*SRCA+31:32*SRCA] = no_packet[32*SRCA+31:32*SRCA] + 1;
            no_tdata_next[32*SRCA+31:32*SRCA] = no_tdata[32*SRCA+31:32*SRCA] +1;
            total_length_next[32*SRCA+31:32*SRCA] = total_length[32*SRCA+31:32*SRCA] + fifo_axis_tuser[15:0];


            //state transition
            if(fifo_axis_tdata[23:0] == USER_MAGIC_CODE) begin
              state_next = STATE_USER_PACKET;
              
              if(source_port[1])
                no_user_packet_next[32*SRC0+31:32*SRC0] = no_user_packet[32*SRC0+31:32*SRC0] + 1;
              if(source_port[3])
                no_user_packet_next[32*SRC1+31:32*SRC1] = no_user_packet[32*SRC1+31:32*SRC1] + 1;
              if(source_port[5])
                no_user_packet_next[32*SRC2+31:32*SRC2] = no_user_packet[32*SRC2+31:32*SRC2] + 1;
              if(source_port[7])
                no_user_packet_next[32*SRC2+31:32*SRC2] = no_user_packet[32*SRC3+31:32*SRC3] + 1;
              no_user_packet_next[32*SRCA+31:32*SRCA]   = no_user_packet[32*SRCA+31:32*SRCA] + 1;
            end
            else begin
              state_next = STATE_IP_PACKET;
            end
            
            //if packet have only one entry
            if(M_AXIS_TLAST)
              state_next = STATE_IDLE;
          end
        end
        STATE_USER_PACKET: begin
          //special logic if needed.
          M_AXIS_TVALID = !in_fifo_empty;
          M_AXIS_TUSER = fifo_axis_tuser;
          M_AXIS_TDATA = fifo_axis_tdata;
          M_AXIS_TLAST = fifo_axis_tlast;
          M_AXIS_TSTRB = fifo_axis_tstrb;
          in_fifo_rd_en = M_AXIS_TVALID && local_M_AXIS_TREADY;
          if(M_AXIS_TVALID && local_M_AXIS_TREADY && M_AXIS_TLAST)begin
            state_next = STATE_IDLE;
          end
          if(M_AXIS_TVALID && local_M_AXIS_TREADY) begin
            if(source_port[1])
                no_tdata_next[32*SRC0+31:32*SRC0] = no_tdata[32*SRC0+31:32*SRC0] + 1;
              if(source_port[3])
                no_tdata_next[32*SRC1+31:32*SRC1] = no_tdata[32*SRC1+31:32*SRC1] + 1;
              if(source_port[5])
                no_tdata_next[32*SRC2+31:32*SRC2] = no_tdata[32*SRC2+31:32*SRC2] + 1;
              if(source_port[7])
                no_tdata_next[32*SRC2+31:32*SRC2] = no_tdata[32*SRC3+31:32*SRC3] + 1;
              no_tdata_next[32*SRCA+31:32*SRCA] = no_tdata[32*SRCA+31:32*SRCA] + 1;
          end
        end
        STATE_IP_PACKET: begin
          M_AXIS_TVALID = !in_fifo_empty;
          M_AXIS_TUSER = fifo_axis_tuser;
          M_AXIS_TDATA = fifo_axis_tdata;
          M_AXIS_TLAST = fifo_axis_tlast;
          M_AXIS_TSTRB = fifo_axis_tstrb;
          in_fifo_rd_en = M_AXIS_TVALID && local_M_AXIS_TREADY;
          if(M_AXIS_TVALID && local_M_AXIS_TREADY && M_AXIS_TLAST)begin
            state_next = STATE_IDLE;
          end
          if(M_AXIS_TVALID && local_M_AXIS_TREADY) begin
            if(source_port[1])
                no_tdata_next[32*SRC0+31:32*SRC0] = no_tdata[32*SRC0+31:32*SRC0] + 1;
            if(source_port[3])
              no_tdata_next[32*SRC1+31:32*SRC1] = no_tdata[32*SRC1+31:32*SRC1] + 1;
            if(source_port[5])
              no_tdata_next[32*SRC2+31:32*SRC2] = no_tdata[32*SRC2+31:32*SRC2] + 1;
            if(source_port[7])
              no_tdata_next[32*SRC2+31:32*SRC2] = no_tdata[32*SRC3+31:32*SRC3] + 1;
            no_tdata_next[32*SRCA+31:32*SRCA] = no_tdata[32*SRCA+31:32*SRCA] + 1;
          end
        end
      endcase
    end


   always @(posedge ACLK) begin
      if(~RESETN) begin
        state <= STATE_IDLE;

        no_tdata <= 0;
        no_packet <= 0;
        no_user_packet <= 0;
        total_length <= 0;
        clock_counter <= 0;
		  speed_packet <= 0;
		  speed_data 	<= 0;
		  prev_data	<= 0;
		  prev_packet <= 0;
      end
      else begin
        state <= state_next;
        if(benchmark_rst) begin
          no_tdata <= 0;
          no_packet <= 0;
          no_user_packet <= 0;
          total_length <= 0;
          clock_counter <= 0;
        end 
        else if(benchmark_en) begin
          no_tdata <= no_tdata_next;
          no_packet <= no_packet_next;
          no_user_packet <= no_user_packet_next;
          total_length <= total_length_next;
          clock_counter <= clock_counter + 1;
          if(clock_counter == 1000000)begin
            clock_counter <= 0;
            prev_data <= total_length_next;
            prev_packet <= no_packet_next;
            
            speed_packet[31:0] <= no_packet[31:0] - prev_packet[31:0];
            speed_packet[63:32] <= no_packet[63:32] - prev_packet[63:32];
            speed_packet[95:64] <= no_packet[95:64] - prev_packet[95:64];
            speed_packet[127:96] <= no_packet[127:96] - prev_packet[127:96];
            speed_packet[159:128] <= no_packet[159:128] - prev_packet[159:128];

            speed_data[31:0] <= total_length[31:0] - prev_data[31:0];
            speed_data[63:32] <= total_length[63:32] - prev_data[63:32];
            speed_data[95:64] <= total_length[95:64] - prev_data[95:64];
            speed_data[127:96] <= total_length[127:96] - prev_data[127:96];
            speed_data[159:128] <= total_length[159:128] - prev_data[159:128];
          end
        end
      end
   end

   // Rev 1.00
   assign {dbg_ctrl_3, dbg_ctrl_2, dbg_ctrl_1, dbg_ctrl_0} = dbg_ctrl_out[3:0];

endmodule
