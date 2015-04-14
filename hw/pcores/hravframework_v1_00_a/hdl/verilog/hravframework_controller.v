//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Tran Trung Hieu
// Email: hieutt@hcmut.edu.vn
// 
// Create Date:    
// Design Name: 
// Module Name:    hrav_framework_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module hrav_framework_controller
  #(
    // Master AXI Lite Data Width
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32
    )
   (
    output  ctrl_en_scn,  //enable scanner

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
   localparam ADDR_TEST0          = 6'd32;
   localparam ADDR_TEST1          = 6'd33;
   localparam ADDR_TEST2          = 6'd34;
   localparam ADDR_TEST3          = 6'd35;


   reg [1:0]                     write_state, write_state_next;
   reg [1:0]                     read_state, read_state_next;
   reg [ADDR_WIDTH-1:0]          read_addr, read_addr_next;
   reg [ADDR_WIDTH-1:0]          write_addr, write_addr_next;
   reg [1:0]                     BRESP_next;


   reg [31:0] reg_test_0,reg_test_1, reg_test_2, reg_test_3;
   reg [31:0] reg_test_0_next, reg_test_1_next, reg_test_2_next, reg_test_3_next;
   reg [31:0]                    ctrl_reg, ctrl_reg_next;

  localparam CONTROL_DEFAULT = 32'h00000001;
  //control register 
  // 0: enable scanner.
  // 
  // 

   assign ctrl_en_scn = ctrl_reg[0];


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
            ADDR_TEST0 : begin
              RDATA = reg_test_0;
            end
            ADDR_TEST1 : begin
              RDATA = reg_test_1;
            end
            ADDR_TEST2 : begin
              RDATA = reg_test_2;
            end  
            ADDR_TEST3 : begin
              RDATA = reg_test_3;
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
      reg_test_0_next = reg_test_0;
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
                ADDR_TEST0: begin
                  reg_test_0_next = WDATA;
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

         ctrl_reg <= CONTROL_DEFAULT;
         reg_test_0 <= 32'hfe0001;
         reg_test_1 <= 32'hcafe18;
         reg_test_2 <= 32'hcafe19;
         reg_test_3 <= 32'hcafe20;

      end
      else begin
         write_state <= write_state_next;
         read_state <= read_state_next;
         read_addr <= read_addr_next;
         write_addr <= write_addr_next;
         BRESP <= BRESP_next;

         ctrl_reg <= ctrl_reg_next;
         reg_test_0 <= reg_test_0_next;
         reg_test_1 <= reg_test_1_next;
         reg_test_2 <= reg_test_2_next;
         reg_test_3 <= reg_test_3_next;
      end
   end

endmodule
