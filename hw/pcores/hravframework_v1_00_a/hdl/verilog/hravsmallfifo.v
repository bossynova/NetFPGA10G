module hravsmallfifo 
#( 
	parameter DINWIDTH 256,
	parameter DOUTWIDTH 8,
	parameter DEPTH 4
)
(
	input clk,
	input reset,
	input wr_en,
	input [DINWIDTH-1:0] din,
	input rd_en,
	output reg [DOUTWIDTH-1:0] dout,
	output reg empty,
	output reg full
);
	reg [DINWIDTH-1:0] buffer[2**DEPTH-1:0];
	reg [DEPTH-1:0] rd_ptr, wr_ptr;
	
	always @(posedge clk)
	begin
		if(reset) begin
			rd_ptr <= 0;
			wr_ptr <= 0;
			empty <= 1;
			full <= 0;
		end
		else begin
			if(!empty && rd_en) begin
				dout <= buffer[rd_ptr];
				rd_ptr <= rd_ptr + 1;
			end
			if(!full && wr_en) begin
				buffer[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				if(!rd_en & wr_ptr )
			end
		end
	end

endmodule
