//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Nguyen Van Quang Anh
// Email: hieutt@hcmut.edu.vn
// 
// Create Date:    
// Design Name: 
// Module Name:    pr_hrav_icap_controller_regfile
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//      * This module is icap_controller register with AXI-Lite interface
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module pr_hrav_icap_controller_regfile
  #(
    // Master AXI Lite Data Width
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32
    )
   (
    // To/From other modules
    output [23:0] magic_code,
    input  [31:0] icap_pkt_cnt,
    output [31:0] core_ctrl,

    input  [31:0] no_config_blk_pkt,
    input  [31:0] no_config_byte,
    input  [31:0] icap_config_status,

    // ICAP debug
    output reg  reg2icap_rd_req,
    input       icap2reg_rd_ready,
    input [31:0] icap2reg_rd_data, 

    output reg        reg2icap_wr_req,
    input             icap2reg_wr_ready,
    output reg [31:0] reg2icap_wr_data, 
	 
    // AXI-Lite interface for registers access
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
   localparam WRITE_ICAP_WAIT = 3;

   localparam READ_IDLE = 0;
   localparam READ_RESPONSE = 1;
   localparam READ_ICAP_WAIT = 2;
   localparam READ_ICAP_RESPONSE = 3;

   localparam ADDR_CONTROL          = 6'h00;
   localparam ADDR_TEST0            = 6'h20;
   localparam ADDR_ICAP_DBG_0       = 6'h24;
   localparam ADDR_MAGIC_CODE       = 6'h28;
   
   localparam ADDR_ICAP_PKT_CNT     = 6'h2C;
   localparam ADDR_ICAP_CONFIG_BLK_PKT  = 6'h30;
   localparam ADDR_ICAP_CONFIG_BYTE     = 6'h34;
   localparam ADDR_ICAP_CONFIG_STAT      = 6'h38;

   reg [1:0]                     write_state, write_state_next;
   reg [1:0]                     read_state, read_state_next;
   reg [ADDR_WIDTH-1:0]          read_addr, read_addr_next;
   reg [ADDR_WIDTH-1:0]          write_addr, write_addr_next;
   reg [1:0]                     BRESP_next;


   reg [31:0] reg_test_0, reg_icap_pkt_cnt;
   reg [31:0] reg_test_0_next, reg_icap_pkt_cnt_next;
   reg [31:0] ctrl_reg, ctrl_reg_next;
   reg [23:0] magic_code_reg, magic_code_reg_next;

   reg [31:0] config_blk_pkt_reg, config_byte_reg;
   reg [31:0] config_stat_reg;

   // Read control
   reg reg2icap_rd_req_next; 
   always @(*) begin
      read_state_next = read_state;   
      reg2icap_rd_req_next = 1'b0;
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
            ADDR_TEST0: begin
              RDATA = reg_test_0;
            end
            ADDR_ICAP_DBG_0: begin
              RVALID = 1'b0;
              read_state_next = READ_ICAP_WAIT;
              reg2icap_rd_req_next = 1'b1;
            end
            ADDR_ICAP_PKT_CNT: begin
              RDATA = reg_icap_pkt_cnt;
            end
            ADDR_MAGIC_CODE: begin
              RDATA = magic_code_reg;
            end
            ADDR_ICAP_CONFIG_BLK_PKT: RDATA = config_blk_pkt_reg;
            ADDR_ICAP_CONFIG_BYTE: RDATA = config_byte_reg;
            ADDR_ICAP_CONFIG_STAT: RDATA = config_stat_reg;
           endcase

           if(RVALID & RREADY) begin
              read_state_next = READ_IDLE;
           end
        end
        READ_ICAP_WAIT: begin
          ARREADY = 1'b0;
          reg2icap_rd_req_next = 1'b1; // Keep requesting in this state
          if (icap2reg_rd_ready) begin
            reg2icap_rd_req_next = 1'b0;
            read_state_next = READ_ICAP_RESPONSE;
          end
        end
        READ_ICAP_RESPONSE: begin
          RDATA = icap2reg_rd_data;
          RVALID = 1'b1;
          ARREADY = 1'b0;
          if(RREADY) begin
            read_state_next = READ_IDLE;
          end
        end
      endcase
   end

   always @(posedge ACLK) begin
      if(~ARESETN) reg2icap_rd_req <= 1'b0;
      else         reg2icap_rd_req <= reg2icap_rd_req_next;
   end
   
   // Write control
   reg        reg2icap_wr_req_next;
   reg [31:0] reg2icap_wr_data_next; 
   always @(*) begin
      write_state_next = write_state;
      write_addr_next = write_addr;

      reg2icap_wr_req_next = 1'b0;
      reg2icap_wr_data_next = 32'h0; 

      AWREADY = 1'b1;
      WREADY = 1'b0;
      BVALID = 1'b0;  
      BRESP_next = BRESP;

      ctrl_reg_next = ctrl_reg;
      reg_test_0_next = reg_test_0;
      reg_icap_pkt_cnt_next = icap_pkt_cnt;
      magic_code_reg_next = magic_code_reg;

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
              
              BRESP_next = AXI_RESP_OK;
              write_state_next = WRITE_RESPONSE;

              case(write_addr[5:0])
                ADDR_CONTROL: begin
                  ctrl_reg_next = WDATA;   
                end
                ADDR_TEST0: begin
                  reg_test_0_next = WDATA;
                end
                ADDR_ICAP_DBG_0: begin
                  reg2icap_wr_req_next = 1'b1;
                  reg2icap_wr_data_next = WDATA; 
                  write_state_next = WRITE_ICAP_WAIT;
                  WREADY = 1'b0;
                end
                ADDR_ICAP_PKT_CNT: begin
                  reg_icap_pkt_cnt_next = WDATA;
                end
                ADDR_MAGIC_CODE: begin
                  magic_code_reg_next = WDATA[23:0];
                end
              endcase
              
           end
        end
        WRITE_ICAP_WAIT: begin
          AWREADY = 1'b0;
          WREADY  = 1'b0;
          BRESP_next = AXI_RESP_OK;
          reg2icap_wr_req_next = reg2icap_wr_req;    // Hold the request
          reg2icap_wr_data_next = reg2icap_wr_data; 
          if (icap2reg_wr_ready) begin
            write_state_next = WRITE_RESPONSE;
            WREADY = 1'b1;
            reg2icap_wr_req_next = 1'b0;    // Clear the request
            reg2icap_wr_data_next = 32'h0; 
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

         ctrl_reg   <= {8'h02, 8'h01, 16'h000c};
         reg_test_0 <= 32'hAAAAAA;
         reg_icap_pkt_cnt <= 32'h000000;
         magic_code_reg <= 24'hEECCAB;

         reg2icap_wr_req <= 1'b0;
         reg2icap_wr_data <= 32'h0;

         config_blk_pkt_reg  <= 32'h0;
         config_byte_reg <= 32'h0;
         config_stat_reg <= 32'h0;
      end
      else begin
         write_state <= write_state_next;
         read_state <= read_state_next;
         read_addr <= read_addr_next;
         write_addr <= write_addr_next;
         BRESP <= BRESP_next;

         ctrl_reg <= ctrl_reg_next;
         reg_test_0 <= reg_test_0_next;
         reg_icap_pkt_cnt <= reg_icap_pkt_cnt_next;
         magic_code_reg <= magic_code_reg_next;

         reg2icap_wr_req <= reg2icap_wr_req_next;
         reg2icap_wr_data <= reg2icap_wr_data_next;

         config_blk_pkt_reg  <= no_config_blk_pkt;
         config_byte_reg <= no_config_byte;
         config_stat_reg <= icap_config_status;
      end
   end

   // Internal module IF
   assign magic_code = magic_code_reg;

   // S/W register for scanner cores
   assign core_ctrl = ctrl_reg[31:0];
endmodule

