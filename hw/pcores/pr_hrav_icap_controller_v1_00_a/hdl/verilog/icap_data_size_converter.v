`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:53:09 03/31/2015 
// Design Name: 
// Module Name:    icap_data_size_converter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:    This module is to convert 256 bit-width to 32-bit width
//                 It also detects the start and end of congiguration packe
//                 by parsing the header
//                 There is debug counter to count number of packet, packet size
//                 for debugging purpose
// Dependencies:
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module icap_data_size_converter	#(
		parameter DATA_SIZE = 256,
		parameter ICAP_DATA_SIZE = 32
	)
	(
		input 									clock,
		input 									rst_n,
    
    // 256bit FIFO interface
		input 	                      	          in_valid,
		input 	[DATA_SIZE - 1 :  0] 	            in_data,
    input 	[7:0] 	                          in_strb,
    input   [127:0]                           in_user,
    input                                     in_last,
		output  reg                               out_ready,	
    
    // 32-bit ICAP interfce
    input                             in_ready,
		output     [ICAP_DATA_SIZE - 1:0] out_data,
		output reg                     	  out_valid,

    // Internal interface
    output   reg                      config_blk_start,
    output   reg                      config_blk_end,
    output   reg                      config_end,
    input                             clr_stat_cnt, // Clear debug counter
    
    // Register interface
    output   reg [15:0]               no_config_blk,    
    output   reg [15:0]               no_config_pkt,
    output   reg [31:0]               no_config_byte
    );

    // State
		localparam IDLE 					= 2'b00;
    localparam DIVIDE_HEADER  = 2'b01;
		localparam DIVIDE_PKT		  = 2'b10;
		
		//enable and disable for fifo and icap
		localparam ENABLE 			= 1'b0;
		localparam DISABLE 			= 1'b1;
		
	//register
	reg [1 : 0] state, next_state;
	reg [7 : 0] data_sel, next_data_sel;
  reg [31:0]  next_no_config_pkt, next_no_config_byte;
  reg         next_config_blk_start, next_config_blk_end, next_config_end;
  
  reg         save_end_blk_bit, save_end_bit;
  reg         next_save_end_blk_bit, next_save_end_bit;
  
	always @(posedge clock)	begin
		if (~rst_n)	begin
      state            <= IDLE;
      data_sel         <= 8'b0000_0001;
      
      config_blk_start <= 1'b0;
      config_blk_end   <= 1'b0;
      config_end       <= 1'b0;
    end
  	else begin
      state            <= next_state;
      data_sel         <= next_data_sel;
      
      config_blk_start <= next_config_blk_start;
      config_blk_end   <= next_config_blk_end;
      config_end       <= next_config_end;  
    end
	end

	always @(posedge clock)	begin
		if (~rst_n)	begin
      {save_end_blk_bit, save_end_bit} = 2'b0;
    end
  	else begin
      {save_end_blk_bit, save_end_bit} = {next_save_end_blk_bit, next_save_end_bit};
    end
	end  
  
	always @(posedge clock)	begin
		if (~rst_n)	begin
      no_config_blk    <= 15'h0;
      no_config_pkt    <= 15'h0;
      no_config_byte   <= 32'h0;
    end
  	else if (clr_stat_cnt) begin
      no_config_blk    <= 15'h0;
      no_config_pkt    <= 15'h0;
      no_config_byte   <= 32'h0;    
    end
    else begin  
      if (config_blk_end) no_config_blk  <= no_config_blk + 1'b1;   
      no_config_pkt    <= next_no_config_pkt;      
      no_config_byte   <= next_no_config_byte;
    end
	end  

  wire start_blk_bit = in_data[57];
  wire end_blk_bit   = in_data[56];
  wire end_bit       = in_data[28];
	always @(*)	begin
    out_valid = 1'b0;
    out_ready = 1'b1;
    
    {next_save_end_blk_bit, next_save_end_bit} = {save_end_blk_bit, save_end_bit};
    
    next_config_blk_start = 1'b0;
    next_config_blk_end = 1'b0;
    next_config_end = 1'b0;
    
    next_state = state;
    next_data_sel = data_sel;

    next_no_config_pkt  = no_config_pkt;
    next_no_config_byte = no_config_byte;
		case(state)
			IDLE: begin
				if (in_valid ) begin
          out_valid = 1'b0; // Skip the header byte
          out_ready = 1'b0;
          next_state    = DIVIDE_HEADER;
          next_data_sel = 8'b0000_0100; // To skip first 8 bytes
          next_config_blk_start = start_blk_bit;
          next_no_config_byte   = no_config_byte + in_user[15:0];
          {next_save_end_blk_bit, next_save_end_bit} = {end_blk_bit, end_bit};
        end
			end
      DIVIDE_HEADER: begin    
        out_ready = 1'b0;
        out_valid = |(data_sel & in_strb); // Valid if the selected strobe is valid
        if (out_valid) begin // Still has byte to send
          out_ready     = in_ready & data_sel[7]; // Grant upper stream if the last byte can be sent
          next_data_sel = (in_ready) ? {data_sel[6:0], data_sel[7]} : data_sel; // Circular update selected byte       
          if (in_last) begin // End of packet (this is the case packet has only one cell
            next_state            = (in_ready  & data_sel[7]) ? IDLE : DIVIDE_HEADER;
            next_config_blk_end   = (in_ready  & data_sel[7]) & save_end_blk_bit; // Update last packet flag
            next_config_end       = (in_ready  & data_sel[7]) & save_end_bit; // Update last block flag
            // Update stats. counter
            next_no_config_pkt  = (in_ready  & data_sel[7]) ? no_config_pkt + 1'b1 : no_config_pkt;
          end
          else begin // Packet is has more than one cell
            next_state    = (in_ready & data_sel[7]) ? DIVIDE_PKT : DIVIDE_HEADER;
          end
        end
        else begin // The selected byte is not valid, no more data to send
          out_ready = 1'b1;
          next_data_sel = 8'b0000_00001;
          if (in_last) begin
            next_state    = IDLE;
            next_config_blk_end  = save_end_blk_bit; // Update last packet flag
            next_config_end = save_end_bit; // Update last block flag
            
            // Update stats. counter
            next_no_config_pkt  = no_config_pkt + 1'b1;      
          end
          else begin // This is case is un-likely happen
            next_state    = DIVIDE_PKT;
          end
        end   
      end
			DIVIDE_PKT: begin // Second cell of the packet, no header thus all valid byte are fwd. to down stream
        out_ready = 1'b0;
        out_valid = |(data_sel & in_strb);
        if (out_valid) begin
          out_ready     = in_ready & data_sel[7];
          next_data_sel = (in_ready) ? {data_sel[6:0], data_sel[7]} : data_sel;
          if (in_last) begin
            next_state    = (in_ready & data_sel[7]) ? IDLE : DIVIDE_PKT;
            next_config_blk_end  = (in_ready & data_sel[7]) & save_end_blk_bit; // Update last packet flag
            next_config_end      = (in_ready & data_sel[7]) & save_end_bit; // Update last block flag
            
            // Update stats. counter
            next_no_config_pkt  = (in_ready & data_sel[7]) ? no_config_pkt + 1'b1 : no_config_pkt;                     
          end
          else begin
            next_state    = DIVIDE_PKT;
          end
        end
        else begin
          out_ready = 1'b1;
          next_state = IDLE;
          next_data_sel = 8'b0000_00001;
          next_config_blk_end  = save_end_blk_bit; // Update last packet flag
          next_config_end = save_end_bit; // Update last block flag
          // Update stats. counter
          next_no_config_pkt  = no_config_pkt + 1'b1;      
        end
			end
		endcase
	end
  assign out_data =   ({32{data_sel[7]}} & in_data[(8*32 - 1) : (7*32)]) 
                    | ({32{data_sel[6]}} & in_data[(7*32 - 1) : (6*32)]) 
                    | ({32{data_sel[5]}} & in_data[(6*32 - 1) : (5*32)]) 
                    | ({32{data_sel[4]}} & in_data[(5*32 - 1) : (4*32)]) 
                    | ({32{data_sel[3]}} & in_data[(4*32 - 1) : (3*32)]) 
                    | ({32{data_sel[2]}} & in_data[(3*32 - 1) : (2*32)]) 
                    | ({32{data_sel[1]}} & in_data[(2*32 - 1) : (1*32)]) 
                    | ({32{data_sel[0]}} & in_data[(1*32 - 1) : (0*32)]); 
endmodule
