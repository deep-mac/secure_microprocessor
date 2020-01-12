`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:39:33 05/19/2017 
// Design Name: 
// Module Name:    PC 
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
module program_counter (
    PC_IS, 
    PC_regload, 
    PC_regen,
    Address_line,
    AD_sel, clk_pc, reset_pc,
    data_in
);

parameter data_size = 32;

input [1:0] PC_IS; 
input PC_regload; 
input PC_regen;
output reg [12:0] Address_line;
input AD_sel, clk_pc, reset_pc;
input [data_size-1:0] data_in;

//wire [7:0] temp_out;
reg [data_size-1:0] PC_IS_MUX_out;
reg [data_size-1:0] incrementer;
reg [data_size-1:0] incrementer_in;
wire [data_size-1:0] PC_reg_out;
//wire [7:0] PC_reg1_out;
reg [data_size-1:0] address_line_32bit;
    


always @ *
begin
    case (PC_IS)
        2'b00:
        begin 
            PC_IS_MUX_out = data_in;
        end
        2'b01:
        begin	//interrupt
            PC_IS_MUX_out = 32'h0000E000;
        end
        2'b10:
        begin	//reset
            PC_IS_MUX_out = 0;
        end
        2'b11:
        begin //normal
            PC_IS_MUX_out = incrementer;
        end
        default:
        begin
            PC_IS_MUX_out = 0;
        end
    endcase
    
    if (AD_sel == 1)
        address_line_32bit = PC_reg_out;
    else 
        address_line_32bit = 32'h00000000;

    Address_line = address_line_32bit[12:0];
    incrementer_in = PC_reg_out;
    
end

//register8 pc0 (.out_en(PC_regen[0]), .load(PC_regload[0]), .clk(clk_pc), .reset(reset_pc), .din(data_in[7:0]), .dout(temp_out));
register8 pc_reg (.out_en(PC_regen), .load(PC_regload), .clk(clk_pc), .reset(reset_pc), .din(PC_IS_MUX_out), .dout(PC_reg_out));
//register8 pc11 (.out_en(PC_regen), .load(PC_regload), .clk(clk_pc), .reset(reset_pc), .din(PC_IS_MUX_out1), .dout(PC_reg1_out));	

//defparam pc10.data_size = 8;
defparam pc_reg.data_size = 32;

always @ (reset_pc , incrementer_in)
begin
    if (reset_pc == 1)
        incrementer = 32'h00000000;
    else 
        incrementer = incrementer_in + 1;
end

endmodule