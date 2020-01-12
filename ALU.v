`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2017 17:01:58
// Design Name: 
// Module Name: ALU
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
//Flags - Carry, overflow, zero, parity, auxCarry, signed

module ALU(
 tr1_in,
 tr2_in,
 ALU_out,
 op_bits,
 func,
 shift_amount,
 PSR_out,
 ALU_out_en, tr1_en, tr2_en, tr1_l, tr2_l, clk_alu, reset_alu, ALU_out_l 
    );
parameter data_size = 32;
    
input [data_size-1:0]tr1_in;
input [data_size-1:0]tr2_in;
output [data_size-1:0]ALU_out;
input [3:0]op_bits;
output wire [data_size-1:0]PSR_out;
input [5:0]func;
input [4:0] shift_amount;
input ALU_out_en, tr1_en, tr2_en, tr1_l, tr2_l, clk_alu, reset_alu, ALU_out_l;
       
wire [data_size:0]add_out;
wire [data_size:0]add_out_c;
wire [data_size-1:0]tr1_out;
wire [data_size-1:0]tr2_out;
wire [data_size-1:0]mul_out;
wire [data_size:0] sub_out;
reg [data_size-1:0]alu_tout;
wire [data_size-1:0]PSR_in;
//wire [data_size-1:0]PSR_out;
wire [data_size:0]sub_out_c;
//wire carry = 0;
reg carry_reg;
wire [data_size-1:0]and_out;
wire [data_size-1:0]or_out;
wire [data_size-1:0]not_out;
wire [data_size-1:0]xor_out;
wire [data_size-1:0]neg_out;
wire [data_size-1:0]shift_out_ll;
wire [data_size-1:0]shift_out_rl;
wire [data_size-1:0]shift_out_lli;
wire [data_size-1:0]shift_out_rli;
//wire [data_size-1:0]shift_out_ra;

reg zero = 0, overflow = 0;
reg [data_size:0]add_out_t;
reg [data_size:0]sub_out_t;
reg [data_size-1:0]shift_out_t;
//integer i;
//reg test;

initial
begin
    carry_reg = 0;
end


register8 tr1 (.din(tr1_in), .dout(tr1_out), .out_en(tr1_en), .load(tr1_l), .clk(clk_alu), .reset(reset_alu));
register8 tr2 (.din(tr2_in), .dout(tr2_out), .out_en(tr2_en), .load(tr2_l), .clk(clk_alu), .reset(reset_alu));
register8 AL_R (.din(alu_tout), .dout(ALU_out), .out_en(ALU_out_en), .load(ALU_out_l), .clk(clk_alu), .reset(reset_alu));
register8 PSR (.din(PSR_in), .dout(PSR_out), .out_en(1'b1), .load(1'b1), .clk(clk_alu), .reset(reset_alu));

//assign {carry, add_out} = tr1_out + tr2_out;
assign {add_out} = tr1_out + tr2_out;
assign {add_out_c} = tr1_out + tr2_out + {28'h0000000, 3'b000, PSR_out[0]};
assign mul_out = tr1_out[15:0] * tr2_out[15:0];
assign sub_out = tr1_out - tr2_out;
assign sub_out_c = tr1_out - tr2_out - {28'h0000000, 3'b000, PSR_out[0]};
assign and_out = tr1_out & tr2_out;
assign or_out = tr1_out | tr2_out;
assign not_out = ~tr1_out; 
assign xor_out = tr1_out ^ tr2_out;
assign neg_out = (~tr1_out) + 1;
assign shift_out_ll = tr1_out << tr2_out;
assign shift_out_rl = tr1_out >> tr2_out;
assign shift_out_lli = tr1_out << shift_amount;
assign shift_out_rli = tr1_out >> shift_amount;
//assign shift_out_ra = tr1_out >>> tr2_out;

assign PSR_in[data_size-1:3] = 0;
assign PSR_in[2] = overflow;
assign PSR_in[1] = zero;
assign PSR_in[0] = carry_reg;
//assign alu_tout = (ALU_sel == 0)? add_out: {data_size{1'b1}};

//always @ (tr2_out or tr1_out)
//begin
//    for(i = 0; i < 32; i = i+1)
//    begin
//        if(i + tr2_out < 32)
//        begin
//            test = 1;
//            shift_out_rl[i] = tr1_out[i + tr2_out];
//        end
//        else
//        begin
//            test = 0;
//            shift_out_rl[i] = 1'b0;
//        end
//    end
//end

always @ *
begin
    add_out_t = 0;
    sub_out_t = 0;
    shift_out_t = 0;
    case (func)
    6'b000000:
    begin
        add_out_t = add_out;
        sub_out_t = sub_out;
        shift_out_t = shift_out_ll;
    end
    6'b000001:
    begin
        add_out_t = add_out_c;
        sub_out_t = sub_out_c;
        shift_out_t = shift_out_rl;    
    end
    6'b000011:
    begin
        add_out_t = 0;
        sub_out_t = 0;
        shift_out_t = shift_out_lli;
//        shift_out_t = shift_out_ra;
    end
    6'b000100:
    begin
        add_out_t = 0;
        sub_out_t = 0;
        shift_out_t = shift_out_rli;
    end
    default:
    begin
        add_out_t = 0;
        sub_out_t = 0;
        shift_out_t = 0;    
    end
    endcase
end 
  
always @ *
begin
    alu_tout = 0;
    carry_reg = 0;
    case (op_bits)
        4'b0000: begin
            alu_tout = add_out_t[data_size-1:0];
            carry_reg = add_out_t[data_size];
        end    
        4'b0001: begin
            alu_tout = sub_out_t[data_size-1:0];
            carry_reg = sub_out_t[data_size];
        end
        4'b0010: alu_tout = mul_out;
        4'b0100: alu_tout = and_out;
        4'b0101: alu_tout = or_out;
        4'b0110: alu_tout = not_out;
        4'b0111: alu_tout = xor_out;
        4'b1000: alu_tout = neg_out;
        4'b1001: alu_tout = shift_out_t;
        4'b1010: alu_tout = sub_out_t[data_size-1:0];
        4'b1110: alu_tout = add_out_t[data_size-1:0];
        4'b1111: alu_tout = add_out_t[data_size-1:0];
        default: begin
            alu_tout = 0;
            carry_reg = 0;
        end
    endcase       
end

always @ *
begin
    if (alu_tout == 0)
        zero = 1;
    else
        zero = 0;
end

always @ *
begin
    if((add_out[data_size-1] == 0 && tr1_out[data_size-1] == 1 && tr2_out[data_size-1] == 1) || 
       (add_out[data_size-1] == 1 && tr1_out[data_size-1] == 0 && tr2_out[data_size-1] == 0))
        overflow = 1;
    else
        overflow = 0;
end

endmodule
