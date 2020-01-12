`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:00:11 05/19/2017 
// Design Name: 
// Module Name:    memory 
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
module memory(
address,
dout,
memory_out_en, 
clk, 
load_mem, 
reset,
din
);

parameter data_size = 32;
input [3:0] address;
output reg [data_size-1:0] dout;
input memory_out_en; 
input clk;
input load_mem; 
input reset;
input	[data_size-1:0] din;


wire [data_size-1:0] dout_sig [15:0];
reg [data_size-1:0] din_sig [15:0];
reg [15:0] load;
reg [15:0] out_en;
genvar i;
generate
    for (i=0; i<=15; i=i+1) begin : mem_registers
    register8 mr1(
		  .out_en(out_en[i]),
		  .load(load[i]),
        .clk(clk),
        .reset(reset),
        .din(din_sig[i]),
        .dout(dout_sig[i])
    );
end
endgenerate
always @ *
begin
	dout = dout_sig[address];
end

always @(address or memory_out_en)
begin
out_en = 16'h0000;
case (memory_out_en) 
	1'b0:
		out_en[address] = 0;
	1'b1:
		out_en[address] = 1;
	default:
		out_en = 16'h0000;
endcase
end

always @ *
begin
load = 16'h0000;
din_sig[address] = {data_size{1'b0}};
case (load_mem) 
	1'b0: begin
		load[address] = 0;
		din_sig[address] = din;
		end
	1'b1: begin
		load[address] = 1;
		din_sig[address] = din;
		end
	default: begin
		load = 16'h0000;
		din_sig[address] = {data_size{1'b0}};
	end
endcase
end

endmodule
