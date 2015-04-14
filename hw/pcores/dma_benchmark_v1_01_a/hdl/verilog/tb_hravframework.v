`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: HOCHIMINH CIY UNIVERSITY OF TECHNOLOGY - HCMUT
// Project: HR-AV
// Engineer: Tran Trung Hieu
//
// Create Date:   16:17:29 10/23/2014
// Design Name:   hravframework
// Module Name:   /home/heckarim/work/netfpga10g/NetFPGA-10G-live-release_5.0.1/contrib-projects/hrav_test/hw/pcores/hravframework_v1_00_a/hdl/verilog/testbench/testbench_hrav_test/tb_hravframework.v
// Project Name:  testbench_hrav_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: hravframework
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_hravframework;

	// Inputs
	reg m_axis_tready;
	reg [255:0] s_axis_tdata;
	reg [31:0] s_axis_tstrb;
	reg [127:0] s_axis_tuser;
	reg s_axis_tvalid;
	reg s_axis_tlast;
	reg S_AXI_ACLK;
	reg S_AXI_ARESETN;
	reg [31:0] S_AXI_AWADDR;
	reg S_AXI_AWVALID;
	reg [31:0] S_AXI_WDATA;
	reg [3:0] S_AXI_WSTRB;
	reg S_AXI_WVALID;
	reg S_AXI_BREADY;
	reg [31:0] S_AXI_ARADDR;
	reg S_AXI_ARVALID;
	reg S_AXI_RREADY;
	reg [2:0] masterbank_sel_pin;
	
	integer vecfile;

	// Outputs
	wire [255:0] m_axis_tdata;
	wire [31:0] m_axis_tstrb;
	wire [127:0] m_axis_tuser;
	wire m_axis_tvalid;
	wire m_axis_tlast;
	wire s_axis_tready;
	wire S_AXI_AWREADY;
	wire S_AXI_WREADY;
	wire [1:0] S_AXI_BRESP;
	wire S_AXI_BVALID;
	wire S_AXI_ARREADY;
	wire [31:0] S_AXI_RDATA;
	wire [1:0] S_AXI_RRESP;
	wire S_AXI_RVALID;
	wire [0:0] qdr_c_0;
	wire [0:0] qdr_c_n_0;
	wire qdr_dll_off_n_0;
	wire [0:0] qdr_k_0;
	wire [0:0] qdr_k_n_0;
	wire [18:0] qdr_sa_0;
	wire [3:0] qdr_bw_n_0;
	wire qdr_w_n_0;
	wire [35:0] qdr_d_0;
	wire qdr_r_n_0;
	wire [35:0] qdr_q_0;
	wire [0:0] qdr_cq_0;
	wire [0:0] qdr_cq_n_0;
	wire [0:0] qdr_c_1;
	wire [0:0] qdr_c_n_1;
	wire qdr_dll_off_n_1;
	wire [0:0] qdr_k_1;
	wire [0:0] qdr_k_n_1;
	wire [18:0] qdr_sa_1;
	wire [3:0] qdr_bw_n_1;
	wire qdr_w_n_1;
	wire [35:0] qdr_d_1;
	wire qdr_r_n_1;
	wire [35:0] qdr_q_1;
	wire [0:0] qdr_cq_1;
	wire [0:0] qdr_cq_n_1;
	wire [0:0] qdr_c_2;
	wire [0:0] qdr_c_n_2;
	wire qdr_dll_off_n_2;
	wire [0:0] qdr_k_2;
	wire [0:0] qdr_k_n_2;
	wire [18:0] qdr_sa_2;
	wire [3:0] qdr_bw_n_2;
	wire qdr_w_n_2;
	wire [35:0] qdr_d_2;
	wire qdr_r_n_2;
	wire [35:0] qdr_q_2;
	wire [0:0] qdr_cq_2;
	wire [0:0] qdr_cq_n_2;
	wire locked;
	reg core_clk;
	reg core_resetn;
	wire core_clk_270;
	wire sram_clk_200;

	// Instantiate the Unit Under Test (UUT)
	hravframework uut (
		.axi_aclk(core_clk), 
		.axi_resetn(core_resetn), 
		.m_axis_tdata(m_axis_tdata), 
		.m_axis_tstrb(m_axis_tstrb), 
		.m_axis_tuser(m_axis_tuser), 
		.m_axis_tvalid(m_axis_tvalid), 
		.m_axis_tready(m_axis_tready), 
		.m_axis_tlast(m_axis_tlast), 
		.s_axis_tdata(s_axis_tdata), 
		.s_axis_tstrb(s_axis_tstrb), 
		.s_axis_tuser(s_axis_tuser), 
		.s_axis_tvalid(s_axis_tvalid), 
		.s_axis_tready(s_axis_tready), 
		.s_axis_tlast(s_axis_tlast), 
		.S_AXI_ACLK(core_clk), 
		.S_AXI_ARESETN(core_resetn), 
		.S_AXI_AWADDR(S_AXI_AWADDR), 
		.S_AXI_AWVALID(S_AXI_AWVALID), 
		.S_AXI_AWREADY(S_AXI_AWREADY), 
		.S_AXI_WDATA(S_AXI_WDATA), 
		.S_AXI_WSTRB(S_AXI_WSTRB), 
		.S_AXI_WVALID(S_AXI_WVALID), 
		.S_AXI_WREADY(S_AXI_WREADY), 
		.S_AXI_BRESP(S_AXI_BRESP), 
		.S_AXI_BVALID(S_AXI_BVALID), 
		.S_AXI_BREADY(S_AXI_BREADY), 
		.S_AXI_ARADDR(S_AXI_ARADDR), 
		.S_AXI_ARVALID(S_AXI_ARVALID), 
		.S_AXI_ARREADY(S_AXI_ARREADY), 
		.S_AXI_RDATA(S_AXI_RDATA), 
		.S_AXI_RRESP(S_AXI_RRESP), 
		.S_AXI_RVALID(S_AXI_RVALID), 
		.S_AXI_RREADY(S_AXI_RREADY), 
		.core_clk(core_clk), 
		.core_clk_270(core_clk_270), 
		.sram_clk_200(sram_clk_200), 
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

	always #5 core_clk = ~core_clk;
	
	integer count;
	reg valid;
	reg [127:0] user;
	reg [255:0] data;
	reg [31:0] strb;
	reg last;
	always @(posedge core_clk)
	begin
		if(!core_resetn) begin
			s_axis_tdata <= 0;
			s_axis_tstrb <= 0;
			s_axis_tuser <= 0;
			s_axis_tvalid <= 0;
			s_axis_tlast <= 0;
		end
		else begin
			if((!$feof(vecfile)) && s_axis_tready) begin
				count = $fscanf(vecfile, "%b\t%x\t%x\t%x\t%b\n", 
									valid, user, data, strb, last);
				if(count == 5) begin
					s_axis_tdata <= data;
					s_axis_tstrb <= strb;
					s_axis_tuser <= user;
					s_axis_tvalid <= valid;
					s_axis_tlast <= last;
				end
			end
		end
	end

	initial begin
		// Initialize Inputs
		core_clk = 0;
		core_resetn = 0;
		m_axis_tready = 1;
		s_axis_tdata = 0;
		s_axis_tstrb = 0;
		s_axis_tuser = 0;
		s_axis_tvalid = 0;
		s_axis_tlast = 0;

		S_AXI_ACLK = 0;
		S_AXI_ARESETN = 0;
		S_AXI_AWADDR = 0;
		S_AXI_AWVALID = 0;
		S_AXI_WDATA = 0;
		S_AXI_WSTRB = 0;
		S_AXI_WVALID = 0;
		S_AXI_BREADY = 0;
		S_AXI_ARADDR = 0;
		S_AXI_ARVALID = 0;
		S_AXI_RREADY = 0;
		masterbank_sel_pin = 0;
		
		vecfile = $fopen("saxis.vec", "r");
		if(!vecfile) begin
			$display("Cannot open vector\n");
			$finish;
		end
		// Wait 100 ns for global reset to finish
		#112;
        
		// Add stimulus here
		core_resetn = 1;
	end
      
endmodule
