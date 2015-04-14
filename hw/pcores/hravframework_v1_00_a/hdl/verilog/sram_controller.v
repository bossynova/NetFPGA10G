module sram_controller
  #(
   parameter C_FAMILY = "virtex5",
   parameter USER_MAGIC_CODE = 32'h1234cafe,
	parameter C_BASEADDR=32'h80000000,
	parameter C_HIGHADDR=32'h80003FFF,
   // Master AXI Lite Data Width
   parameter DATA_WIDTH=32,
   parameter ADDR_WIDTH=32,
    
	parameter integer MASTERBANK_PIN_WIDTH = 3,
	parameter integer NUM_MEM_CHIPS      = 3,
	parameter integer NUM_MEM_INPUTS     = 6,
	parameter integer MEM_WIDTH          = 36,
	parameter integer MEM_ADDR_WIDTH     = 19,
	parameter integer MEM_CQ_WIDTH       = 1,
	parameter integer MEM_CLK_WIDTH      = 1,
	parameter integer MEM_BW_WIDTH       = 4
    )
   (   	
	input usr_rreq_sram,
	input [7:0] usr_rcnt_sram,
	output sram_rrdy_usr,
	input [NUM_MEM_CHIPS + MEM_ADDR_WIDTH-1:0] usr_raddr_sram,
	output reg sram_dvld_usr,
	output reg [4*MEM_WIDTH-1:0] sram_rdata_usr,
	
	input usr_wreq_sram,
	input [7:0] usr_wcnt_sram,
	output sram_awrdy_usr,
	output sram_dwrdy_usr,
	input [NUM_MEM_CHIPS + MEM_ADDR_WIDTH-1:0] usr_waddr_sram,
	input [4*MEM_WIDTH-1:0] usr_wdata_sram,
	input [4*MEM_BW_WIDTH-1:0] usr_bw_sram,
	
	input	memclk,
	input	memclk_270,
	input	memclk_200,
	input [(MEM_WIDTH)-1:0]  qdr_q_0,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_0,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_0,
	output             qdr_dll_off_n_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_0,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_0,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_0,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_0,
	output             qdr_w_n_0,
	output [(MEM_WIDTH)-1:0]  qdr_d_0,
	output             qdr_r_n_0,

	input [(MEM_WIDTH)-1:0]  qdr_q_1,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_1,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_1,
	output             qdr_dll_off_n_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_1,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_1,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_1,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_1,
	output             qdr_w_n_1,
	output [(MEM_WIDTH)-1:0]  qdr_d_1,
	output             qdr_r_n_1,

	input [(MEM_WIDTH)-1:0]  qdr_q_2,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_2,
	input [MEM_CQ_WIDTH-1:0]    qdr_cq_n_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_c_n_2,
	output             qdr_dll_off_n_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_2,
	output [MEM_CLK_WIDTH-1:0]  qdr_k_n_2,
	output [MEM_ADDR_WIDTH-1:0] qdr_sa_2,
	output [(MEM_BW_WIDTH)-1:0]   qdr_bw_n_2,
	output             qdr_w_n_2,
	output [(MEM_WIDTH)-1:0]  qdr_d_2,
	output             qdr_r_n_2,

	/*synthesis syn_keep = 1 */(* S = "TRUE" *)
	input  [MASTERBANK_PIN_WIDTH-1:0]  masterbank_sel_pin,

	input		locked
    );
    
    reg user_ad_w_n_0;
	wire user_d_w_n_0;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_wr_0;
	wire [2*MEM_BW_WIDTH-1:0] user_bw_n_0;
	wire [2*MEM_WIDTH-1:0] user_dw_0;
	reg  user_r_n_0;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_rd_0;         
	wire user_wr_full_0;
	wire user_rd_full_0;
	wire [2*MEM_WIDTH-1:0] user_qr_0;
	wire user_qr_valid_0;
	wire cal_done_0;
	
	reg user_ad_w_n_1;
	wire user_d_w_n_1;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_wr_1;
	wire [2*MEM_BW_WIDTH-1:0] user_bw_n_1;
	wire [2*MEM_WIDTH-1:0] user_dw_1;
	reg user_r_n_1;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_rd_1;         
	wire user_wr_full_1;
	wire user_rd_full_1;
	wire [2*MEM_WIDTH-1:0] user_qr_1;
	wire user_qr_valid_1;
	wire cal_done_1;
	
	reg user_ad_w_n_2;
	wire user_d_w_n_2;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_wr_2;
	wire [2*MEM_BW_WIDTH-1:0] user_bw_n_2;
	wire [2*MEM_WIDTH-1:0] user_dw_2;
	reg user_r_n_2;
	wire [MEM_ADDR_WIDTH-1:0] user_ad_rd_2;         
	wire user_wr_full_2;
	wire user_rd_full_2;
	wire [2*MEM_WIDTH-1:0] user_qr_2;
	wire user_qr_valid_2;
	wire cal_done_2;
	
	localparam CALIB = 3'h0;
	localparam RIDLE = 3'h1;
	localparam READ0 = 3'h2;
	localparam READ1 = 3'h3;
	localparam READ2 = 3'h4;
	
	localparam WIDLE = 3'h1;
	localparam WRITE0 = 3'h2;
	localparam WRITE1 = 3'h3;
	localparam WRITE2 = 3'h4;
	
	localparam ERROR_SRAM_Q = 72'heedeadbeefdeadbeef;
	
	reg [2:0] rstate, wstate;
	reg [NUM_MEM_CHIPS + MEM_ADDR_WIDTH-1:0] rd_addr, wr_addr;
	reg [4*MEM_WIDTH-1:0] wr_data;
	reg [4*MEM_BW_WIDTH-1:0] wr_bw;
	reg rd_req_pend;
	reg [7:0] rd_count, wr_count;
	
	//assign user_ad_w_n_0 = (wstate == WRITE0) ? 1'b0 : 1'b1;
	//assign user_ad_w_n_1 = (wstate == WRITE0) ? 1'b0 : 1'b1;
	//assign user_ad_w_n_2 = (wstate == WRITE0) ? 1'b0 : 1'b1;
	
	assign user_ad_wr_0 = wr_addr[18:0];
	assign user_ad_wr_1 = wr_addr[18:0];
	assign user_ad_wr_2 = wr_addr[18:0];
	
	assign user_d_w_n_0 = user_ad_w_n_0;
	assign user_d_w_n_1 = user_ad_w_n_1;
	assign user_d_w_n_2 = user_ad_w_n_2;
	
	assign user_bw_n_0 = wr_bw[7:0];
	assign user_bw_n_1 = wr_bw[7:0];
	assign user_bw_n_2 = wr_bw[7:0];
	
	assign user_dw_0 = wr_data[71:0];
	assign user_dw_1 = wr_data[71:0];
	assign user_dw_2 = wr_data[71:0];
	
	//assign user_r_n_0 = user_r_n;
	//assign user_r_n_1 = user_r_n;
	//assign user_r_n_2 = user_r_n;
	
	assign user_ad_rd_0 = rd_addr[18:0];
	assign user_ad_rd_1 = rd_addr[18:0];
	assign user_ad_rd_2 = rd_addr[18:0];
	
	assign sram_rrdy_usr = (rstate == RIDLE);
	assign sram_awrdy_usr = (wstate == WIDLE);
	assign sram_dwrdy_usr = (wstate == WRITE1);
	
	always @(posedge memclk)
	begin
		if(!locked)
		begin
			rstate <= CALIB;
			sram_dvld_usr <= 1'b0;
			sram_rdata_usr <= 0;
			rd_req_pend <= 1'b0;
			rd_count <= 8'h0;
		end
		else
		begin
			case(rstate)
			CALIB:
				if(cal_done_0 & cal_done_1 & cal_done_2) rstate <= RIDLE;
			RIDLE: begin
				sram_dvld_usr <= 1'b0;
				if(usr_rreq_sram) begin
					rstate <= READ0;
					rd_count <= usr_rcnt_sram;
					rd_addr <= usr_raddr_sram;
					if(usr_raddr_sram[20:19] == 2'b00) user_r_n_0 <= 1'b0;
					else if(usr_raddr_sram[20:19] == 2'b01) user_r_n_1 <= 1'b0;
					else user_r_n_2 <= 1'b0;
				end
			end
			READ0: 
				if(rd_addr[20:19] == 2'b00) begin
					if(!user_rd_full_0)
					begin
						rstate <= READ1;	
						user_r_n_0 <= 1'b1;				
						if(rd_count != 0) rd_req_pend <= 1'b1;
						else rd_req_pend <= 1'b0;
						rd_count <= rd_count - 1;
						rd_addr[7:0] <= rd_addr[7:0] + 1;
					end
					sram_dvld_usr <= 1'b0;
				end
				else if(rd_addr[20:19] == 2'b01) begin
					if(!user_rd_full_1)
					begin
						rstate <= READ1;	
						user_r_n_1 <= 1'b1;				
						if(rd_count != 0) rd_req_pend <= 1'b1;
						else rd_req_pend <= 1'b0;
						rd_count <= rd_count - 1;
						rd_addr[7:0] <= rd_addr[7:0] + 1;
					end;
					sram_dvld_usr <= 1'b0;
				end
				else begin
					if(!user_rd_full_2)
					begin
						rstate <= READ1;	
						user_r_n_2 <= 1'b1;				
						if(rd_count != 0) rd_req_pend <= 1'b1;
						else rd_req_pend <= 1'b0;
						rd_count <= rd_count - 1;
						rd_addr[7:0] <= rd_addr[7:0] + 1;
					end
					sram_dvld_usr <= 1'b0;
				end
			READ1:
				if(rd_addr[20:19] == 2'b00) begin
					if(user_qr_valid_0)
					begin
						rstate <= READ2;
						sram_rdata_usr[71:0] <= user_qr_0;
					end
				end
				else if(rd_addr[20:19] == 2'b01) begin
					if(user_qr_valid_1)
					begin
						rstate <= READ2;
						sram_rdata_usr[71:0] <= user_qr_1;
					end
				end
				else begin
					if(user_qr_valid_2)
					begin
						rstate <= READ2;
						sram_rdata_usr[71:0] <= user_qr_2;
					end
				end
			READ2:
				if(rd_addr[20:19] == 2'b00) begin
					if(user_qr_valid_0)
					begin
						if(rd_req_pend) begin
							rstate <= READ0;
							user_r_n_0 <= 1'b0;
						end
						else rstate <= RIDLE;
						sram_rdata_usr[143:72] <= user_qr_0;
						sram_dvld_usr <= 1'b1;
					end
				end
				else if(rd_addr[20:19] == 2'b01) begin
					if(user_qr_valid_1)
					begin
						if(rd_req_pend) begin
							rstate <= READ0;
							user_r_n_1 <= 1'b0;
						end
						else rstate <= RIDLE;
						sram_rdata_usr[143:72] <= user_qr_1;
						sram_dvld_usr <= 1'b1;
					end
				end
				else begin
					if(user_qr_valid_2)
					begin
						if(rd_req_pend) begin
							rstate <= READ0;
							user_r_n_2 <= 1'b0;
						end
						else rstate <= RIDLE;
						sram_rdata_usr[143:72] <= user_qr_2;
						sram_dvld_usr <= 1'b1;
					end
				end
			endcase 
		end
	end
	
	always @(posedge memclk)
	begin
		if(!locked)
		begin
			wstate <= CALIB;
		end
		else
		begin
			case(wstate)
			CALIB:
				if(cal_done_0 & cal_done_1 & cal_done_2) wstate <= WIDLE;
			WIDLE: begin
				if(usr_wreq_sram)
				begin
					wstate <= WRITE0;
					wr_count <= usr_wcnt_sram;
					wr_addr <= usr_waddr_sram;
					wr_data <= usr_wdata_sram;
					wr_bw <= ~usr_bw_sram;
					if(usr_waddr_sram[20:19] == 2'b00) user_ad_w_n_0 <= 1'b0;
					else if(usr_waddr_sram[20:19] == 2'b01) user_ad_w_n_1 <= 1'b0;
					else user_ad_w_n_2 <= 1'b0;
				end
			end
			WRITE0:
				if(wr_addr[20:19] == 2'b00) begin
					if(!user_wr_full_0) begin
						wstate <= WRITE1;
						user_ad_w_n_0 <= 1'b1;
						wr_data[71:0] <= wr_data[143:72];
						wr_bw[7:0] <= wr_bw[15:8];
					end
				end
				else if(wr_addr[20:19] == 2'b01) begin
					if(!user_wr_full_1) begin
						wstate <= WRITE1;
						user_ad_w_n_1 <= 1'b1;
						wr_data[71:0] <= wr_data[143:72];
						wr_bw[7:0] <= wr_bw[15:8];
					end
				end
				else begin
					if(!user_wr_full_2) begin
						wstate <= WRITE1;
						user_ad_w_n_2 <= 1'b1;
						wr_data[71:0] <= wr_data[143:72];
						wr_bw[7:0] <= wr_bw[15:8];
					end
				end
			WRITE1:
				if(wr_count == 0) begin
					wstate <= WIDLE;
				end
				else begin
					wstate <= WRITE0;
					if(wr_addr[20:19] == 2'b00) user_ad_w_n_0 <= 1'b0;
					else if(wr_addr[20:19] == 2'b01) user_ad_w_n_1 <= 1'b0;
					else user_ad_w_n_2 <= 1'b0;
					wr_addr[7:0] <= wr_addr[7:0] + 1;
					wr_count <= wr_count - 1;
					wr_data <= usr_wdata_sram;
					wr_bw <= ~usr_bw_sram;
				end
			endcase 
		end
	end

	sram_core 	sramcore
	(   
	.memclk(memclk),
	.memclk_270(memclk_270),
	.memclk_200(memclk_200),
	
	.user_ad_w_n_0(user_ad_w_n_0),
	.user_d_w_n_0(user_d_w_n_0),
	.user_ad_wr_0(user_ad_wr_0),
	.user_bw_n_0(user_bw_n_0),
	.user_dw_0(user_dw_0),
	.user_r_n_0(user_r_n_0),
	.user_ad_rd_0(user_ad_rd_0),         
	.user_wr_full_0(user_wr_full_0),
	.user_rd_full_0(user_rd_full_0),
	.user_qr_0(user_qr_0),
	.user_qr_valid_0(user_qr_valid_0),
	.cal_done_0(cal_done_0),
    
	.user_ad_w_n_1(user_ad_w_n_1),
	.user_d_w_n_1(user_d_w_n_1),
	.user_ad_wr_1(user_ad_wr_1),
	.user_bw_n_1(user_bw_n_1),
	.user_dw_1(user_dw_1),
	.user_r_n_1(user_r_n_1),
	.user_ad_rd_1(user_ad_rd_1),         
	.user_wr_full_1(user_wr_full_1),
	.user_rd_full_1(user_rd_full_1),
	.user_qr_1(user_qr_1),
	.user_qr_valid_1(user_qr_valid_1),
	.cal_done_1(cal_done_1),
    
	.user_ad_w_n_2(user_ad_w_n_2),
	.user_d_w_n_2(user_d_w_n_2),
	.user_ad_wr_2(user_ad_wr_2),
	.user_bw_n_2(user_bw_n_2),
	.user_dw_2(user_dw_2),
	.user_r_n_2(user_r_n_2),
	.user_ad_rd_2(user_ad_rd_2),         
	.user_wr_full_2(user_wr_full_2),
	.user_rd_full_2(user_rd_full_2),
	.user_qr_2(user_qr_2),
	.user_qr_valid_2(user_qr_valid_2),
	.cal_done_2(cal_done_2),
    
	.qdr_q_0(qdr_q_0),
	.qdr_cq_0(qdr_cq_0),
	.qdr_cq_n_0(qdr_cq_n_0),
	.qdr_c_0(qdr_c_0),
	.qdr_c_n_0(qdr_c_n_0),
	.qdr_dll_off_n_0(qdr_dll_off_n_0),
	.qdr_k_0(qdr_k_0),
	.qdr_k_n_0(qdr_k_n_0),
	.qdr_sa_0(qdr_sa_0),
	.qdr_bw_n_0(qdr_bw_n_0),
	.qdr_w_n_0(qdr_w_n_0),
	.qdr_d_0(qdr_d_0),
	.qdr_r_n_0(qdr_r_n_0),

	.qdr_q_1(qdr_q_1),
	.qdr_cq_1(qdr_cq_1),
	.qdr_cq_n_1(qdr_cq_n_1),
	.qdr_c_1(qdr_c_1),
	.qdr_c_n_1(qdr_c_n_1),
	.qdr_dll_off_n_1(qdr_dll_off_n_1),
	.qdr_k_1(qdr_k_1),
	.qdr_k_n_1(qdr_k_n_1),
	.qdr_sa_1(qdr_sa_1),
	.qdr_bw_n_1(qdr_bw_n_1),
	.qdr_w_n_1(qdr_w_n_1),
	.qdr_d_1(qdr_d_1),
	.qdr_r_n_1(qdr_r_n_1),

	.qdr_q_2(qdr_q_2),
	.qdr_cq_2(qdr_cq_2),
	.qdr_cq_n_2(qdr_cq_n_2),
	.qdr_c_2(qdr_c_2),
	.qdr_c_n_2(qdr_c_n_2),
	.qdr_dll_off_n_2(qdr_dll_off_n_2),
	.qdr_k_2(qdr_k_2),
	.qdr_k_n_2(qdr_k_n_2),
	.qdr_sa_2(qdr_sa_2),
	.qdr_bw_n_2(qdr_bw_n_2),
	.qdr_w_n_2(qdr_w_n_2),
	.qdr_d_2(qdr_d_2),
	.qdr_r_n_2(qdr_r_n_2),

	.masterbank_sel_pin(masterbank_sel_pin),

	.locked(locked)
    );
	
endmodule
