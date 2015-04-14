module scanner(
	input clk,
	input reset,
	
	input dpt_dvld_scn,
	input [7:0] dpt_cmd_scn,
	input [23:0] dpt_id_scn,
	input [31:0] dpt_poff_scn,
	input [255:0] dpt_data_scn,
	input [31:0] dpt_bvld_scn,
	input dpt_end_scn,
	output scn_rdy_dpt,
	
	output scn_dvld_clt,
	output [7:0] scn_cmd_clt,
	output [23:0] scn_id_clt,
	output [255:0] scn_data_clt,
	output [31:0] scn_bvld_clt,
	output scn_end_clt,
	input clt_rdy_scn
);

	reg [255:0] result;
	wire [31:0] pattern0; //PTRNXXXX
	wire [31:0] pattern1; //PTRNXXXX
	wire [31:0] pattern2; //PTRNXXXX
	wire [31:0] pattern3; //PTRNXXXX
	wire [31:0] pattern4; //PTRNXXXX
	wire [31:0] pattern5; //PTRNXXXX
	wire [31:0] pattern6; //PTRNXXXX
	wire [31:0] pattern7; //PTRNXXXX
	
	reg [7:0] match;
	reg [15:0] id0, id1, id2, id3, id4, id5, id6, id7;
	reg [7:0] count;
	reg [7:0] cmd;
	reg [23:0] bid;
	reg state;
	reg [31:0] sig_id;
	reg [31:0] sig_off;
	reg [31:0] sig_cnt;
	
	assign {pattern7, pattern6, pattern5, pattern4, pattern3, pattern2, pattern1, pattern0} = dpt_data_scn;
	assign scn_rdy_dpt = ~state;
	
	assign scn_dvld_clt = state;
	assign scn_cmd_clt = cmd;
	assign scn_id_clt = bid;
	assign scn_data_clt = {160'h0, sig_off, sig_id, sig_cnt};
	assign scn_bvld_clt = 32'hFFFFFFFF;
	assign scn_end_clt = 1'b1;
	
	always @(*)
	begin
		casex(match)
		8'b1xxx_xxxx: begin
			sig_id = id7;
			sig_off = {count,5'b11100};
			sig_cnt = 1;
		end
		8'b01xx_xxxx: begin
			sig_id = id6;
			sig_off = {count,5'b11000};
			sig_cnt = 1;
		end
		8'b001x_xxxx: begin
			sig_id = id5;
			sig_off = {count,5'b10100};
			sig_cnt = 1;
		end
		8'b0001_xxxx: begin
			sig_id = id4;
			sig_off = {count,5'b10000};
			sig_cnt = 1;
		end
		8'b0000_1xxx: begin
			sig_id = id3;
			sig_off = {count,5'b01100};
			sig_cnt = 1;
		end
		8'b0000_01xx: begin
			sig_id = id2;
			sig_off = {count,5'b01000};
			sig_cnt = 1;
		end
		8'b0000_001x: begin
			sig_id = id1;
			sig_off = {count,5'b00100};
			sig_cnt = 1;
		end
		8'b0000_0001: begin
			sig_id = id0;
			sig_off = {count,5'b00000};
			sig_cnt = 1;
		end
		default: begin
			sig_id = 32'hFFFFFFFF;
			sig_off = 32'hFFFFFFFF;
			sig_cnt = 0;
		end
		endcase
	end
	
	always @(posedge clk)
	begin
		if(reset) begin
			state <= 1'b0;
			result <= 0;
			match <= 0;
			count <= 0;
			cmd <= 0;
			bid <= 0;
		end
		else begin
			if(state == 1'b0) begin
				if(dpt_dvld_scn) begin
					match[7] <= (pattern7[31:16] == 16'hdead);
					match[6] <= (pattern6[31:16] == 16'hdead);
					match[5] <= (pattern5[31:16] == 16'hdead);
					match[4] <= (pattern4[31:16] == 16'hdead);
					match[3] <= (pattern3[31:16] == 16'hdead);
					match[2] <= (pattern2[31:16] == 16'hdead);
					match[1] <= (pattern1[31:16] == 16'hdead);
					match[0] <= (pattern0[31:16] == 16'hdead);
					id7 <= pattern7[15:0];
					id6 <= pattern6[15:0];
					id5 <= pattern5[15:0];
					id4 <= pattern4[15:0];
					id3 <= pattern3[15:0];
					id2 <= pattern2[15:0];
					id1 <= pattern1[15:0];
					id0 <= pattern0[15:0];
					count <= count + 1;
					cmd <= dpt_cmd_scn;
					bid <= dpt_id_scn;
					if(dpt_end_scn) state <= 1'b1;
				end
			end
			else begin
				if(clt_rdy_scn) state <= 1'b0;
			end
		end
	end 

endmodule

