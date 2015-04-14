//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Tran Trung Hieu
// Email: hieutt@hcmut.edu.vn
// 
// Create Date:    
// Design Name: 
// Module Name:    dma_benchmark_controller 
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

module dma_benchmark_controller
  #(
    // Master AXI Lite Data Width
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32
    )
   (
    // Rev1.00
    output[31:0] dbg_ctrl_out, 
    //
 
    output  benchmark_rst,
    output  benchmark_en,
    output benchmark_inf_recv,
    output  [7:0] source_port_mask,
    input [31:0] clock_counter,
    input [5*32-1:0] reg_no_packet,
    input [5*32-1:0] reg_no_user_packet,
    input [5*32-1:0] reg_total_length,
    input [5*32-1:0] reg_no_tdata,
    input [5*32-1:0] reg_speed_packet,
    input [5*32-1:0] reg_speed_data,

    input                        ACLK,
    input                        ARESETN,
    
    input [ADDR_WIDTH-1: 0]      AWADDR,
    input                        AWVALID,
    output reg                   AWREADY,
    
    input [DATA_WIDTH-1: 0]      WDATA,
    input [DATA_WIDTH/8-1: 0]    WSTRB,
    input                        WVALID,
    output reg                   WREADY,
    
    output reg [1:0]             BRESP,
    output reg                   BVALID,
    input                        BREADY,
    
    input [ADDR_WIDTH-1: 0]      ARADDR,
    input                        ARVALID,
    output reg                   ARREADY,
    
    output reg [DATA_WIDTH-1: 0] RDATA, 
    output reg [1:0]             RRESP,
    output reg                   RVALID,
    input                        RREADY
    );

   localparam AXI_RESP_OK = 2'b00;
   localparam AXI_RESP_SLVERR = 2'b10;
   
   localparam WRITE_IDLE = 0;
   localparam WRITE_RESPONSE = 1;
   localparam WRITE_DATA = 2;

   localparam READ_IDLE = 0;
   localparam READ_RESPONSE = 1;

   localparam ADDR_CONTROL        = 6'd0;
   localparam ADDR_NO_PACKET      = 6'd1;
   localparam ADDR_NO_USER_PACKET = 6'd2;
   localparam ADDR_NO_TDATA       = 6'd3;
   localparam ADDR_TOTAL_LENGTH   = 6'd4;
   localparam ADDR_SPEED_PACKET   = 6'd5;
   localparam ADDR_SPEED_DATA     = 6'd6;
   localparam ADDR_CLOCK_COUNT    = 6'd7;
   localparam ADDR_DBG_CTRL_OUT   = 6'd32;
   localparam ADDR_TEST1          = 6'd33;
   localparam ADDR_TEST2          = 6'd34;
   localparam ADDR_TEST3          = 6'd35;

   localparam SRC0   = 8'd0;
   localparam SRC1   = 8'd1;
   localparam SRC2   = 8'd2;
   localparam SRC3   = 8'd3;
   localparam SRCA   = 8'd4;


   reg [1:0]                     write_state, write_state_next;
   reg [1:0]                     read_state, read_state_next;
   reg [ADDR_WIDTH-1:0]          read_addr, read_addr_next;
   reg [ADDR_WIDTH-1:0]          write_addr, write_addr_next;
   reg [1:0]                     BRESP_next;


   reg [31:0] reg_dbg_ctrl_out,reg_test_1, reg_test_2, reg_test_3;
   reg [31:0] reg_dbg_ctrl_out_next, reg_test_1_next, reg_test_2_next, reg_test_3_next;
   reg [31:0]                    ctrl_reg, ctrl_reg_next;

	initial ctrl_reg = 32'h0400FFF1;
	
   reg [31:0] reg_no_packet_src, reg_no_tdata_src, reg_no_user_packet_src, reg_total_length_src, reg_speed_data_src, reg_speed_packet_src;
   //control register 
   // 0: enable benchmark
   // 1: reset benchmark counter
   // 15:8: source port mark (onehot encoding) 1: cpu 0, 3: cpu 1, ...
   // 31:24: read register (decimal presentation) 0: cpu 0, ...
   wire [7:0] benchmark_src;

   assign benchmark_en = ctrl_reg[0];
   assign benchmark_rst = ctrl_reg[1];
   assign source_port_mask = ctrl_reg[15:8];
   assign benchmark_src = ctrl_reg[31:24]; //choosing benchamrk data source, rdaxi.
   assign benchmark_inf_recv = ctrl_reg[4];// set Master Axi ready to high.


   
   always @(*) begin
        reg_no_packet_src = reg_no_packet[32*SRCA+31: 32*SRCA];
        reg_no_user_packet_src = reg_no_user_packet[32*SRCA+31: 32*SRCA];
        reg_no_tdata_src = reg_no_tdata[32*SRCA+31: 32*SRCA];
        reg_total_length_src = reg_total_length[32*SRCA+31: 32*SRCA];
        reg_speed_packet_src = reg_speed_packet[32*SRCA+31: 32*SRCA];
        reg_speed_data_src = reg_speed_data[32*SRCA+31: 32*SRCA];
     case(benchmark_src[7:0])
      SRC0: begin
        reg_no_packet_src = reg_no_packet[32*SRC0+31: 32*SRC0];
        reg_no_user_packet_src = reg_no_user_packet[32*SRC0+31: 32*SRC0];
        reg_no_tdata_src = reg_no_tdata[32*SRC0+31: 32*SRC0];
        reg_total_length_src = reg_total_length[32*SRC0+31: 32*SRC0];
        reg_speed_packet_src = reg_speed_packet[32*SRC0+31: 32*SRC0];
        reg_speed_data_src = reg_speed_data[32*SRC0+31: 32*SRC0];
      end
      SRC1: begin 
        reg_no_packet_src = reg_no_packet[32*SRC1+31: 32*SRC1];
        reg_no_user_packet_src = reg_no_user_packet[32*SRC1+31: 32*SRC1];
        reg_no_tdata_src = reg_no_tdata[32*SRC1+31: 32*SRC1];
        reg_total_length_src = reg_total_length[32*SRC1+31: 32*SRC1];
        reg_speed_packet_src = reg_speed_packet[32*SRC1+31: 32*SRC1];
        reg_speed_data_src = reg_speed_data[32*SRC1+31: 32*SRC1];
      end
      SRC2: begin
        reg_no_packet_src = reg_no_packet[32*SRC2+31: 32*SRC2];
        reg_no_user_packet_src = reg_no_user_packet[32*SRC2+31: 32*SRC2];
        reg_no_tdata_src = reg_no_tdata[32*SRC2+31: 32*SRC2];
        reg_total_length_src = reg_total_length[32*SRC2+31: 32*SRC2];
        reg_speed_packet_src = reg_speed_packet[32*SRC2+31: 32*SRC2];
        reg_speed_data_src = reg_speed_data[32*SRC2+31: 32*SRC2];
      end
      SRC3: begin
        reg_no_packet_src = reg_no_packet[32*SRC3+31: 32*SRC3];
        reg_no_user_packet_src = reg_no_user_packet[32*SRC3+31: 32*SRC3];
        reg_no_tdata_src = reg_no_tdata[32*SRC3+31: 32*SRC3];
        reg_total_length_src = reg_total_length[32*SRC3+31: 32*SRC3];
        reg_speed_packet_src = reg_speed_packet[32*SRC3+31: 32*SRC3];
        reg_speed_data_src = reg_speed_data[32*SRC3+31: 32*SRC3];
      end
      SRCA: begin
        reg_no_packet_src = reg_no_packet[32*SRCA+31: 32*SRCA];
        reg_no_user_packet_src = reg_no_user_packet[32*SRCA+31: 32*SRCA];
        reg_no_tdata_src = reg_no_tdata[32*SRCA+31: 32*SRCA];
        reg_total_length_src = reg_total_length[32*SRCA+31: 32*SRCA];
        reg_speed_packet_src = reg_speed_packet[32*SRCA+31: 32*SRCA];
        reg_speed_data_src = reg_speed_data[32*SRCA+31: 32*SRCA];
      end
      default:begin
        reg_no_packet_src = reg_no_packet[32*SRCA+31: 32*SRCA];
        reg_no_user_packet_src = reg_no_user_packet[32*SRCA+31: 32*SRCA];
        reg_no_tdata_src = reg_no_tdata[32*SRCA+31: 32*SRCA];
        reg_total_length_src = reg_total_length[32*SRCA+31: 32*SRCA];
        reg_speed_packet_src = reg_speed_packet[32*SRCA+31: 32*SRCA];
        reg_speed_data_src = reg_speed_data[32*SRCA+31: 32*SRCA];
      end
     endcase
   end

   always @(*) begin
      read_state_next = read_state;   
      ARREADY = 1'b1;
      read_addr_next = read_addr;
      RDATA = 'hdeadbeef; 
      RRESP = AXI_RESP_OK;
      RVALID = 1'b0;
      
      case(read_state)
        READ_IDLE: begin
           if(ARVALID) begin
              read_addr_next = ARADDR;
              read_state_next = READ_RESPONSE;
           end
        end        
        
        READ_RESPONSE: begin
           RVALID = 1'b1;
           ARREADY = 1'b0;

           case(read_addr[5:0])
            ADDR_CONTROL: begin
              RDATA = ctrl_reg;
            end
            ADDR_NO_PACKET: begin
              RDATA = reg_no_packet_src;
            end
            ADDR_NO_USER_PACKET: begin
              RDATA = reg_no_user_packet_src;
            end
            ADDR_NO_TDATA: begin
              RDATA = reg_no_tdata_src;
            end
            ADDR_TOTAL_LENGTH: begin
              RDATA = reg_total_length_src;
            end
            ADDR_SPEED_DATA: begin
              RDATA = reg_speed_data_src;
            end
            ADDR_SPEED_PACKET: begin
              RDATA = reg_speed_packet_src;
            end
            ADDR_DBG_CTRL_OUT: begin
              RDATA = reg_dbg_ctrl_out;
            end
            ADDR_TEST1: begin
              RDATA = reg_test_1;
            end
            ADDR_TEST2: begin
              RDATA = reg_test_2;
            end
            ADDR_TEST3: begin
              RDATA = reg_test_3;
            end
            ADDR_CLOCK_COUNT: begin
              RDATA = clock_counter;
            end
           endcase

           if(RREADY) begin
              read_state_next = READ_IDLE;
           end
        end
      endcase
   end
   
   always @(*) begin
      write_state_next = write_state;
      write_addr_next = write_addr;

      AWREADY = 1'b1;
      WREADY = 1'b0;
      BVALID = 1'b0;  
      BRESP_next = BRESP;

      ctrl_reg_next = ctrl_reg;
      reg_dbg_ctrl_out_next = reg_dbg_ctrl_out;
      reg_test_1_next = reg_test_1;
      reg_test_2_next = reg_test_2;
      reg_test_3_next = reg_test_3;

      case(write_state)
        WRITE_IDLE: begin
           write_addr_next = AWADDR;
           if(AWVALID) begin
              write_state_next = WRITE_DATA;
           end
        end
        WRITE_DATA: begin
           AWREADY = 1'b0;
           WREADY = 1'b1;
           if(WVALID) begin
              
              case(write_addr[5:0])
                ADDR_CONTROL: begin
                  ctrl_reg_next = WDATA;   
                end
                ADDR_DBG_CTRL_OUT: begin
                  reg_dbg_ctrl_out_next = WDATA;
                end
                ADDR_TEST1: begin
                  reg_test_1_next = WDATA;
                end
                ADDR_TEST2: begin
                  reg_test_2_next = WDATA;
                end
                ADDR_TEST3: begin
                  reg_test_3_next = WDATA;
                end
              endcase
              
              BRESP_next = AXI_RESP_OK;
              write_state_next = WRITE_RESPONSE;
           end
        end
        WRITE_RESPONSE: begin
           AWREADY = 1'b0;
           BVALID = 1'b1;
           if(BREADY) begin                    
              write_state_next = WRITE_IDLE;
           end
        end
      endcase
   end

   always @(posedge ACLK) begin
      if(~ARESETN) begin
         write_state <= WRITE_IDLE;
         read_state <= READ_IDLE;
         read_addr <= 0;
         write_addr <= 0;
         BRESP <= AXI_RESP_OK;

         ctrl_reg <= 32'h0400FF01;
         reg_dbg_ctrl_out <= 32'h00000000;
         reg_test_1 <= 32'hcafe28;
         reg_test_2 <= 32'hcafe29;
         reg_test_3 <= 32'hcafe30;

      end
      else begin
         write_state <= write_state_next;
         read_state <= read_state_next;
         read_addr <= read_addr_next;
         write_addr <= write_addr_next;
         BRESP <= BRESP_next;

         ctrl_reg <= ctrl_reg_next;
         reg_dbg_ctrl_out <= reg_dbg_ctrl_out_next;
         reg_test_1 <= reg_test_1_next;
         reg_test_2 <= reg_test_2_next;
         reg_test_3 <= reg_test_3_next;

      end
   end

   // Rev 1.00
	single_bit_sync_n sync_0i (.clk(ACLK), .rst_n(ARESETN), .in_sig(reg_dbg_ctrl_out[0]), .sync_sig(dbg_ctrl_out[0]));
	single_bit_sync_n sync_1i (.clk(ACLK), .rst_n(ARESETN), .in_sig(reg_dbg_ctrl_out[1]), .sync_sig(dbg_ctrl_out[1]));
	single_bit_sync_n sync_2i (.clk(ACLK), .rst_n(ARESETN), .in_sig(reg_dbg_ctrl_out[2]), .sync_sig(dbg_ctrl_out[2]));
	single_bit_sync_n sync_3i (.clk(ACLK), .rst_n(ARESETN), .in_sig(reg_dbg_ctrl_out[3]), .sync_sig(dbg_ctrl_out[3]));	
endmodule
