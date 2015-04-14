module collector (
	input 			clk,
	input 			reset,
	output [255:0]		m_axis_tdata,
	output [31:0]		m_axis_tstrb,
	output [127:0]		m_axis_tuser,
	output				m_axis_tvalid,
	input				m_axis_tready,
	output				m_axis_tlast,
	
	input 				scn_dvld_clt,
	input [7:0]			scn_cmd_clt,
	input [23:0] 		scn_id_clt,
	input [255:0] 		scn_data_clt,
	input [31:0] 		scn_bvld_clt,
	input 				scn_end_clt,
	output 				clt_rdy_scn
);
	
	wire data_wr_en;
	wire [287:0] data_din;
	wire data_rd_en;
	wire [287:0] data_dout;
	wire data_full;
	wire data_empty;
	
	wire ctrl_wr_en;
	wire [71:0] ctrl_din;
	wire ctrl_rd_en;
	wire [71:0] ctrl_dout;
	wire ctrl_full;
	wire ctrl_empty;
	
	reg sending;
	reg [7:0] count, len, tlen;
	
	//DATAFIFO: BVLD|DATA
	//CTRLFIFO: CMD|ID|STATUS|COUNT

	assign clt_rdy_scn = ~data_full;
	
	assign data_wr_en = scn_dvld_clt;
	assign data_din = {scn_bvld_clt, scn_data_clt};
	assign data_rd_en = sending & m_axis_tready;
	assign m_axis_tdata = sending ? data_dout[255:0] : {ctrl_dout[39:0], 24'hAECAFE};
	assign m_axis_tstrb = sending ? data_dout[287:256] : 32'hFFFFFFFF;
	assign m_axis_tvalid = sending ? ~data_empty : ~ctrl_empty;
	assign m_axis_tuser[15:0] = sending ? {3'b000, tlen, 5'b00000} : {3'b000, ctrl_dout[47:40], 5'b00000};
//	assign m_axis_tuser[15:0] = 16'h003C;
	assign m_axis_tuser[23:16] = 8'h01; //NET0
	assign m_axis_tuser[31:24] = 8'h02; //CPU0
	assign m_axis_tuser[127:32] = 0;
	assign m_axis_tlast = sending & (count == 2);
	
	assign ctrl_wr_en = scn_dvld_clt/* & (~data_full)*/ & scn_end_clt;
	assign ctrl_din = {len, 8'h03, scn_id_clt, scn_cmd_clt}; //FIRST + LAST
	assign ctrl_rd_en = (~sending) & m_axis_tready;
	
	always @(posedge clk)
	begin
		if(reset) begin
			sending <= 1'b0;
			count <= 8'h2;
			len <= 8'h2;
			tlen <= 8'h2;
		end
		else begin
			if(scn_dvld_clt & (~data_full)) begin
				if(scn_end_clt) len <= 8'h2;
				else len <= len+1;
			end
			if(sending == 1'b0) begin
				if(~ctrl_empty & m_axis_tready) begin
					sending <= 1'b1;
					count <= ctrl_dout[47:40];
					tlen <= ctrl_dout[47:40];
				end
			end
			else begin
				if(m_axis_tready) begin
					if(count == 2) begin
						sending <= 1'b0;
					end
					else begin
						count <= count - 1;
					end
				end
			end
		end
	end

fifo288x128 data (
	.rst(reset),
	.clk(clk),
	.wr_en(data_wr_en),
	.din(data_din),
	.rd_en(data_rd_en),
	.dout(data_dout),
	.full(data_full),
	.empty(data_empty)
	);

fifo72x128 ctrl (
	.rst(reset),
	.clk(clk),
	.wr_en(ctrl_wr_en),
	.din(ctrl_din),
	.rd_en(ctrl_rd_en),
	.dout(ctrl_dout),
	.full(ctrl_full),
	.empty(ctrl_empty)
	);

endmodule
