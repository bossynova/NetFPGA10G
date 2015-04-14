// Reset sync. lib
module rst_sync (
	input   clk,
	input   rst_in,
	output  rst_out
);
	reg [1:0] sync_q;
	always @(posedge clk) begin
		sync_q[1:0] <= {sync_q[0], rst_in};
	end
	assign rst_out = sync_q[1];
endmodule

// Control/sync lib.
module single_bit_sync #(parameter RST_VAL = 1'b0) (
	input   clk,
	input   rst,
	input   in_sig,
	output  sync_sig
);
	reg [1:0] sync_q;
	always @(posedge clk) begin
    if   (rst) sync_q[1:0] <= {RST_VAL, RST_VAL};
	 else       sync_q[1:0] <= {sync_q[0], in_sig};
	end
	assign sync_sig = sync_q[1];
endmodule

module single_bit_sync_n #(parameter RST_VAL = 1'b0) (
	input   clk,
  input   rst_n,
	input   in_sig,
	output  sync_sig
);
	reg [1:0] sync_q;
	always @(posedge clk) begin
    if   (~rst_n) sync_q[1:0] <= {RST_VAL, RST_VAL};
	 else          sync_q[1:0] <= {sync_q[0], in_sig};
	end
	assign sync_sig = sync_q[1];
endmodule

module multi_bit_sync #(parameter BW = 2) (
	input   clk,
	input   rst,
  input  [BW-1:0] in_sig,
	output  [BW-1:0] sync_sig 
);
	reg [BW-1:0] sync_q_0;
	reg [BW-1:0] sync_q_1;
	always @(posedge clk) begin
    if (rst) begin
      sync_q_0 <= {BW{1'b0}};
      sync_q_1 <= {BW{1'b0}};
    end 
    else begin
      sync_q_0 <= in_sig;
      sync_q_1 <= sync_q_0;
    end
	end
	assign sync_sig = sync_q_1;
endmodule

