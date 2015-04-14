module dispatcher 
(
	input 			clk,
	input 			reset,
	input [255:0]		s_axis_tdata,
	input [31:0]		s_axis_tstrb,
	input [127:0]		s_axis_tuser,
	input			s_axis_tvalid,
	output			s_axis_tready,
	input			s_axis_tlast,
	
	output 			dpt_dvld_scn,
	output reg [7:0] 	dpt_cmd_scn,
	output reg [23:0] 	dpt_id_scn,
	output reg [31:0] 	dpt_poff_scn,
	output 	   [255:0] 	dpt_data_scn,
	output     [31:0] 	dpt_bvld_scn,
	output			dpt_end_scn,
	input 			scn_rdy_dpt
);
	parameter HEADER = 1'b0;
	parameter PACKET = 1'b1;
	
	reg state;
	reg tran_end;
	
	assign s_axis_tready = scn_rdy_dpt;
	assign dpt_dvld_scn = state & s_axis_tvalid;
	assign dpt_end_scn = state & s_axis_tlast & tran_end;
	assign dpt_data_scn = s_axis_tdata;
	assign dpt_bvld_scn = s_axis_tstrb; 
	always @(posedge clk)
	begin
		if(reset) begin
			state <= HEADER;
			tran_end <= 1'b0;
			dpt_cmd_scn <= 8'h0;
			dpt_id_scn <= 32'h0;
			dpt_poff_scn <= 32'h0;
		end
		else begin
			if(s_axis_tvalid) begin
				if(state == HEADER) begin
					if(scn_rdy_dpt && (s_axis_tdata[23:0] == 24'hAECAFE)) state <= PACKET;
					tran_end <= s_axis_tdata[56];
					dpt_cmd_scn <= s_axis_tdata[31:24];
					dpt_id_scn <= s_axis_tdata[55:32];
					if(s_axis_tdata[57]) dpt_poff_scn <= s_axis_tdata[95:64];
				end
				else begin
					if(s_axis_tlast && scn_rdy_dpt) state <= HEADER;
				end
			end
		end
	end
endmodule
