`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CITY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Tran Trung Hieu
// Email: hieutt@hcmut.edu.vn
// 
// Create Date:    13:33:47 10/08/2014 
// Design Name: 
// Module Name:    scanner_wrapper 
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
module scanner_wrapper(
	input clk,
	input reset,

	input ctrl_en_scn,		//enable scanner
	
	input dpt_dvld_scn,
	input [7:0] dpt_cmd_scn,
	input [31:0] dpt_id_scn,
	input [31:0] dpt_poff_scn,
	input [255:0] dpt_data_scn,
	input [31:0] dpt_bvld_scn,
	input dpt_end_scn,
	output reg scn_rdy_dpt,
	
	output scn_dvld_clt,
	output [7:0] scn_cmd_clt,
	output [31:0] scn_id_clt,
	output [255:0] scn_data_clt,
	output [31:0] scn_bvld_clt,
	output scn_end_clt,
	input clt_rdy_scn
);
	parameter S_WAIT = 2'h0;
	parameter S_LOOP = 2'h1;
	
	reg [1:0] state, next_state;
	reg [255:0] buf_data;
	reg [31:0] buf_id;
	reg [7:0] buf_cmd;
	reg buf_end;
	reg [31:0] buf_bvld;
	//wire buf_rdy; // inform buffer is ready
	reg load_data;
	reg [31:0] read_status;

	
	always@(posedge clk)begin
		if(reset) begin
			state <= S_WAIT;
		end
		else begin
			state <= next_state;
		end
	end
	
	always@(*)begin
		case(state)
			S_WAIT:begin
				scn_rdy_dpt = 1'b1;
				if(dpt_dvld_scn)begin
					load_data = 1'b1; 
					next_state = S_LOOP;
				end
				else begin
					next_state = state;
					load_data = 1'b0;
				end
			end
			S_LOOP:begin
				scn_rdy_dpt = 1'b0;
				load_data = 1'b0;
				if(read_status == 'd0)
					next_state = S_WAIT;
				else
					next_state = state;
			end
			default:begin
				next_state = state;
				load_data = 1'b0;
				scn_rdy_dpt = 1'b0;
			end
		endcase//case(state)
	end

	wire char_rdy;
	wire char_vld;
	wire char_end;
	reg sid_rdy;
	wire [7:0] char;
	//assign buf_rdy = |(read_status);
	always@(posedge clk)begin
		if(reset)begin
			read_status 	<= 32'h0001;
			buf_end 		<= 1'b0;
			buf_data 		<= 256'h0;
			buf_id 			<= 32'h0;
			buf_bvld		<= 32'h0;
			buf_cmd		<= 'd0;
		end
		else begin
			if(load_data)begin
				buf_end 	<= dpt_end_scn;
				buf_data 	<= dpt_data_scn;
				buf_bvld 	<= dpt_bvld_scn;
				buf_id		<= dpt_id_scn;
				buf_cmd 	<= dpt_cmd_scn;
				read_status	<= 32'h0001;
			end 
			else begin
				if(char_rdy) begin
					read_status	<= read_status << 1;
					buf_data 	<= buf_data >> 8;
				end
			end
		end
	end

	assign char = buf_data[7:0];
	assign char_vld = |(buf_bvld&read_status) | char_end;
	assign char_end = buf_end & read_status[31];
	wire [31:0] sid, offset;
	wire sid_vld, sid_end;
	simple_scanner scanner0(
		.clk(clk),
		.reset(reset),

		.iEn(ctrl_en_scn), //enable scanner
		.iChar(char),
		.iValid(char_vld),
		.oReady(char_rdy),
		.iEnd(char_end),

		.iReady(sid_rdy),
		.oSID(sid), //32 bit SID
		.oOffset(offset), //32  bit offset.
		.oValid(sid_vld),
		.oEnd(sid_end)
	);


	/* Hanlde SID return */
	parameter SID_IDLE = 2'b00;
	parameter SID_WAIT = 2'b01;
	parameter SID_HANLE = 2'b10;

	reg [1:0] sid_state, sid_next_state;
	
	always@(posedge clk)begin
		if(reset)begin
			sid_state <= SID_IDLE;
		end
		else begin
			sid_state <= sid_next_state;
		end
	end

	always@(*)begin
		sid_rdy = 1'b0;
		sid_next_state = sid_state;
		case (sid_state)
			SID_IDLE: begin
				if(char_end && char_rdy)
					sid_next_state = SID_WAIT;
			end
			SID_WAIT:begin
				sid_rdy = 1'b1;
				if(sid_vld && sid_rdy && sid_end) begin
					sid_next_state = SID_IDLE;
				end
			end
		endcase //case (state)
	end

	reg [255:0] result_reg; // |NO_SIG|SID_0|OFFSET_0|SID_1|OFFSET_1|SID_2|OFFSET_2|
	wire virus_found;
	reg [2:0] sid_index;
	reg  result_ready;
	parameter SID_0 = 3'd0;
	parameter SID_1 = 3'd1;
	parameter SID_2 = 3'd2;

	assign virus_found = |sid;


	always@(posedge clk) begin
		if(reset) begin
			sid_index <= 3'd0;
			result_reg <= 'd0;
			result_ready <= 'b0;
		end
		else begin
			if (sid_vld && sid_rdy) begin
				if(sid_end) begin
					sid_index <= 3'd0;
					result_reg[31:0] <= virus_found?{29'b0,sid_index+1'd1}:'b0;
					result_ready <= 1'b1;
				end
				else begin
					sid_index <= sid_index +1'd1;
				end

				case (sid_index)
					SID_0: begin
						result_reg[(SID_0 * 64) + 63:(SID_0 * 64) + 32] <= sid;
						result_reg[(SID_0 * 64) + 63 + 32: (SID_0*64) + 32 +32] <= offset;
					end
					SID_1: begin
						result_reg[(SID_1 * 64) + 63:(SID_1 * 64) + 32] <= sid;
						result_reg[(SID_1 * 64) + 63 + 32: (SID_1*64) + 32 +32] <= offset;
					end
					SID_2: begin
						result_reg[(SID_2 * 64) + 63:(SID_2 * 64) + 32] <= sid;
						result_reg[(SID_2 * 64) + 63 + 32: (SID_2*64) + 32 +32] <= offset;
					end
				endcase
			end
			else if(result_ready && clt_rdy_scn)
					result_ready <= 'b0;
		end
	end

	assign scn_end_clt = result_ready;
	assign scn_dvld_clt = result_ready;
	assign scn_bvld_clt = 32'hFFFFFFFF;
	assign scn_data_clt = result_reg;
	assign scn_id_clt = buf_id;
	assign scn_cmd_clt = buf_cmd;
endmodule
