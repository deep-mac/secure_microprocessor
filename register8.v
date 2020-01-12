`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:36:42 05/18/2017 
// Design Name: 
// Module Name:    register8 
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
module register8(
	out_en, load, clk, reset,
	din,
	dout
    );
parameter data_size = 32;

reg [data_size-1:0]q;
input out_en, load, clk, reset;
input [data_size-1:0]din;
output reg [data_size-1:0]dout;

always @ (posedge(clk) or posedge(reset))
begin
	if (reset == 1)
		q <= {data_size{1'b0}};
	else
		if (load == 1)
			q <= din;
end

always @ *
begin
	if (out_en == 1)
		dout = q;
	else
		dout = {data_size{1'bz}};
end

endmodule
