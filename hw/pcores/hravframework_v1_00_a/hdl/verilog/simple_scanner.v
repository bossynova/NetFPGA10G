module simple_scanner (
	input clk,
	input reset,

	input iEn,
	input [7:0] iChar,
	input iValid,
	output reg oReady,
	input iEnd,

	input iReady,
	output [31:0] oSID, //32 bit SID
	output [31:0] oOffset, //32  bit offset.
	output oValid,
	output oEnd
	);


	parameter PATTERN_0 = 32'h0a0b0c0d;
	parameter PATTERN_1 = 32'h1a1b1c1d;
	parameter PATTERN_2 = 32'h2a2b2c2d;
	parameter PATTERN_3 = 32'h3a3b3c3d;
	parameter PATTERN_4 = 32'h4a4b4c4d;
	parameter PATTERN_5 = 32'h5a5b5c5d;
	parameter PATTERN_6 = 32'h6a6b6c6d;
	parameter PATTERN_7 = 32'h7a7b7c7d;


	reg [39:0] data_buffer;
	reg [47:0] matching_sids;
	reg reset_result_reg;

	always@(posedge clk)begin
		if(reset)begin
			data_buffer <= 'd0;
		end
		else begin
			if(iValid && oReady)begin
				data_buffer <= data_buffer<<8 |iChar;
			end
		end
	end

	always@(posedge clk) begin
		if(reset || !iEn )begin
			matching_sids <= 48'd0;
		end
		else begin
			if(reset_result_reg)
				matching_sids <= 48'd0;
			else if(data_buffer[39:8] == PATTERN_0)
				matching_sids <= matching_sids<<16 | {8'h01,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_1)
				matching_sids <= matching_sids<<16 | {8'h02,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_2)
				matching_sids <= matching_sids<<16 | {8'h04,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_3)
				matching_sids <= matching_sids<<16 | {8'h08,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_4)
				matching_sids <= matching_sids<<16 | {8'h10,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_5)
				matching_sids <= matching_sids<<16 | {8'h20,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_6)
				matching_sids <= matching_sids<<16 | {8'h40,data_buffer[7:0]};
			else if(data_buffer[39:8] == PATTERN_7)
				matching_sids <= matching_sids<<16 | {8'h80,data_buffer[7:0]};
		end
	end

	parameter STATE_IDLE = 3'd0;
	parameter STATE_SEND_SID = 3'd1;
	reg [2:0] state;
	reg [2:0] next_state;
	reg send_sid;
	reg do_buffer_sids;

	always @(posedge clk) begin
		if(reset)
			state <= STATE_IDLE;
		else begin
			state <= next_state; 
		end
	end

	always@(*) begin
		next_state = state;
		do_buffer_sids = 1'b0;
		oReady = 1'b1;
		send_sid = 1'b0;
		case(state)
			STATE_IDLE: begin
				if(iValid && oReady && iEnd) begin
					next_state = STATE_SEND_SID;
					do_buffer_sids = 1'b1;
				end
			end
			STATE_SEND_SID: begin
				oReady = 1'b0;
				send_sid = 1'b1;
				if(reset_result_reg ) begin
					next_state = STATE_IDLE;
				end
			end
		endcase
	end


	wire found_sid;
	reg [47:0] buffer_matching_sids;
	assign found_sid = |buffer_matching_sids[15:0];
	assign oValid = send_sid;
	assign oSID = {16'b0,buffer_matching_sids[15:0]};
	assign oOffset = {16'b0,oSID ^ 16'hFFFF};
	assign  oEnd = ~(|buffer_matching_sids[31:16]);
	//Send result in revese order 
	always @(posedge clk) begin
		if (reset) begin
			buffer_matching_sids <= 'd0;
			reset_result_reg <= 1'b0;
		end
		else begin
			reset_result_reg <= 1'b0;
			if(do_buffer_sids) begin
				//do bufer datea
				buffer_matching_sids <= matching_sids;
			end
			else begin
				if(oValid && iReady )begin
					buffer_matching_sids <= buffer_matching_sids>>16;
					if(oEnd) 
						reset_result_reg <= 1'b1;
				end
			end
		end
	end
endmodule
