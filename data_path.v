`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:55:13 05/18/2017 
// Design Name: 
// Module Name:    data_path 
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
module data_path(
dpclk, rst, read_sel_1, read_sel_2, data_in, data_out_1, data_out_2, write, out_en_1, out_en_2, write_sel, data_out_dest
    );

parameter data_size = 32;

input dpclk, rst;
input [4:0]read_sel_1, read_sel_2, write_sel;
input [data_size-1:0] data_in;
input out_en_1, out_en_2, write;
reg [31:0] load;
output reg [data_size-1:-0] data_out_1, data_out_2, data_out_dest;
wire [data_size-1:0]din_sig;
wire [data_size-1:0]dout_sig [31:0];
//register8 IR (.din(instruction_in), .dout(controller_in), .out_en(ir_en), .load(ir_la), .clk(dpclk), .reset(rst));
//register8 A (.din(databus_sig_in), .dout(databus_sig), .out_en(A_en), .load(A_l), .clk(dpclk), .reset(rst));
//register8 B (.din(databus_sig_in), .dout(databus_sig), .out_en(B_en), .load(B_l), .clk(dpclk), .reset(rst));
//register8 C (.din(databus_sig_in), .dout(databus_sig), .out_en(C_en), .load(C_l), .clk(dpclk), .reset(rst));
//register8 D (.din(databus_sig_in), .dout(databus_sig), .out_en(D_en), .load(D_l), .clk(dpclk), .reset(rst));

assign din_sig = data_in;

genvar i;
generate
    for (i=0; i<=31; i=i+1) begin : DP_registers
    register8 R(
		.out_en(1'b1),
		.load(load[i]),
        .clk(dpclk),
        .reset(rst),
        .din(din_sig),
        .dout(dout_sig[i])
    );
end
endgenerate

always @ *
begin
    if (out_en_1 == 1)
        data_out_1 = dout_sig[read_sel_1];
    else
        data_out_1 = 0;
        
    if (out_en_2 == 1)
        data_out_2 = dout_sig[read_sel_2];
    else
        data_out_2 = 0;
    
    data_out_dest = dout_sig[write_sel];

    load = 32'h00000000;
    case (write)
    1'b1: load[write_sel] = 1;
    1'b0: load[write_sel] = 0;
    default: load = 32'h00000000;
    endcase
        
    

end


endmodule
