`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2018 09:53:27 AM
// Design Name: 
// Module Name: mux4
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


module mux4(
    sel, dout, din_0, din_1, din_2, din_3
    );
parameter data_size = 32;

input [1:0]sel;
input [data_size-1:0]din_0, din_1, din_2, din_3;
output reg [data_size-1:0]dout;

wire [1:0]sel;
wire [data_size-1:0]din_0, din_1, din_2, din_3;

always @ (sel or din_0 or din_1 or din_2 or din_3)
begin
    case(sel)
    2'b00: dout = din_0;
    2'b01: dout = din_1;
    2'b10: dout = din_2;
    2'b11: dout = din_3;
    default: dout = {data_size{1'b0}};
    endcase
end

endmodule
