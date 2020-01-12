`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2018 11:09:52 AM
// Design Name: 
// Module Name: mux2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux2(
    sel, dout, din_0, din_1
    );   
parameter data_size = 32;

input sel;
input [data_size-1:0]din_0, din_1;
output reg [data_size-1:0]dout;

wire sel;
wire [data_size-1:0]din_0, din_1;

always @ (sel or din_0 or din_1)
begin
    case(sel)
    1'b0: dout = din_0;
    1'b1: dout = din_1;
    default: dout = {data_size{1'b0}};
    endcase
end

endmodule
