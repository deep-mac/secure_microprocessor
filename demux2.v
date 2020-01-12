`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2018 09:59:02 PM
// Design Name: 
// Module Name: demux2
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


module demux2(
    sel, din, dout_0, dout_1
    );
parameter data_size = 32;

input sel;
input [data_size-1:0] din;
output reg [data_size-1:0] dout_0, dout_1;

wire sel;
wire [data_size-1:0] din;


always @ (sel or din)
begin
    case(sel)
    1'b0: 
    begin
        dout_0 = din;
        dout_1 = {data_size{1'b0}};
    end
    1'b1: 
    begin
        dout_1 = din;
        dout_0 = {data_size{1'b0}};
    end
    default:
    begin
        dout_0 = {data_size{1'b0}};
        dout_1 = {data_size{1'b0}};        
    end
    endcase
end

endmodule
