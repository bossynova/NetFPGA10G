`timescale 1 ns / 1ps
module dma_benchmark_tb();

    reg clk, reset;
    reg [63:0]  tdata[4:0];
    reg [4:0]  tlast;
    wire[4:0]  tready;

   reg 	       tvalid_0 = 0;
   reg 	       tvalid_1 = 0;
   reg 	       tvalid_2 = 0;
   reg 	       tvalid_3 = 0;
   reg 	       tvalid_4 = 0;

    reg [3:0] random = 0;

    integer i;

    wire [63:0] header_word_0 = 64'hEFBEFECAFECAFECA; // Destination MAC
    wire [63:0] header_word_1 = 64'h00000008EFBEEFBE; // Source MAC + EtherType

    localparam HEADER_0 = 0;
    localparam HEADER_1 = 1;
    localparam PAYLOAD  = 2;
    localparam DEAD     = 3;

    reg [2:0] state, state_next;
    reg [7:0] counter, counter_next;

    always @(*) begin
       state_next = state;
       tdata[0] = 64'b0;
       tdata[1] = 64'b0;
       tdata[2] = 64'b0;
       tdata[3] = 64'b0;
       tdata[4] = 64'b0;
       tlast[0] = 1'b0;
       tlast[1] = 1'b0;
       tlast[2] = 1'b0;
       tlast[3] = 1'b0;
       tlast[4] = 1'b0;
       counter_next = counter;

        case(state)
            HEADER_0: begin
                tdata[random] = header_word_0;
                if(tready[random]) begin
                    state_next = HEADER_1;
                end
					 if (random == 0)
						tvalid_0 = 1;
					 else if (random == 1)
						tvalid_1 = 1;
					 else if (random == 2)
						tvalid_2 = 1;
					 else if (random == 3)
						tvalid_3 = 1;
					 else if (random == 4)
						tvalid_4 = 1;
					  end	
            HEADER_1: begin
                tdata[random] = header_word_1;
                if(tready[random]) begin
                    state_next = PAYLOAD;
                end
            end
            PAYLOAD: begin
                tdata[random] = {8{counter}};
                if(tready[random]) begin
                    counter_next = counter + 1'b1;
                    if(counter == 8'h1F) begin
                        state_next = DEAD;
                        counter_next = 8'b0;
                        tlast[random] = 1'b1;
                    end
                end
            end

            DEAD: begin

				 counter_next = counter + 1'b1;
				 tlast[random] = 1'b0;
					tvalid_0 = 0;
					tvalid_1 = 0;
					tvalid_2 = 0;
					tvalid_3 = 0;
					tvalid_4 = 0;
				 if(counter== 8'h22) begin
					 counter_next = 8'b0;
						random = 0;//$random % 5;
					 state_next = HEADER_0;
				 end
            end
        endcase
    end

    always @(posedge clk) begin
        if(reset) begin
            state <= HEADER_0;
            counter <= 8'b0;
        end
        else begin
            state <= state_next;
            counter <= counter_next;
        end
    end

  initial begin
      clk   = 1'b0;

      $display("[%t] : System Reset Asserted...", $realtime);
      reset = 1'b1;
      for (i = 0; i < 50; i = i + 1) begin
                 @(posedge clk);
      end
      $display("[%t] : System Reset De-asserted...", $realtime);
      reset = 1'b0;
  end

  always #2.5  clk = ~clk;      // 200MHz
	
	 dma_benchmark
    #(
      .C_S_AXIS_DATA_WIDTH ( 64 ),
      .C_M_AXIS_DATA_WIDTH ( 64 ),
      .C_BASEADDR ( 32'h7b000000 ),
      .C_HIGHADDR ( 32'h7b00ffff ),
      .USER_MAGIC_CODE ( 32'h1234cafe )
    )
    dma_benchmark_0 (
      .ACLK (clk ),
      .RESETN ( ~reset ),
      .S_AXIS_TREADY ( tready[0] ),
      .S_AXIS_TDATA ( tdata[0] ),
      .S_AXIS_TSTRB ( 8'hFF ),
      .S_AXIS_TUSER ( 128'h0004AAAA ),
      .S_AXIS_TLAST ( tlast[0] ),
      .S_AXIS_TVALID ( tvalid_0 ),
		//Axi stream master 
      .M_AXIS_TVALID (  ),
      .M_AXIS_TDATA (  ),
      .M_AXIS_TSTRB (  ),
      .M_AXIS_TUSER (  ),
      .M_AXIS_TLAST (  ),
      .M_AXIS_TREADY ( 1'b1 ),
		//Axi lite
      .S_AXI_ACLK ( clk ),
      .S_AXI_ARESETN ( ~reset )
//      .S_AXI_AWADDR ( S_AXI_AWADDR ),
//      .S_AXI_AWVALID ( S_AXI_AWVALID ),
//      .S_AXI_AWREADY ( S_AXI_AWREADY ),
//      .S_AXI_WDATA ( S_AXI_WDATA ),
//      .S_AXI_WSTRB ( S_AXI_WSTRB ),
//      .S_AXI_WVALID ( S_AXI_WVALID ),
//      .S_AXI_WREADY ( S_AXI_WREADY ),
//      .S_AXI_BRESP ( S_AXI_BRESP ),
//      .S_AXI_BVALID ( S_AXI_BVALID ),
//      .S_AXI_BREADY ( S_AXI_BREADY ),
//      .S_AXI_ARADDR ( S_AXI_ARADDR ),
//      .S_AXI_ARVALID ( S_AXI_ARVALID ),
//      .S_AXI_ARREADY ( S_AXI_ARREADY ),
//      .S_AXI_RDATA ( S_AXI_RDATA ),
//      .S_AXI_RRESP ( S_AXI_RRESP ),
//      .S_AXI_RVALID ( S_AXI_RVALID ),
//      .S_AXI_RREADY ( S_AXI_RREADY )
    );

endmodule