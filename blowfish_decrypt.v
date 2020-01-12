`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2018 12:50:41
// Design Name: 
// Module Name: blowfish_decrpyt
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


module blowfish_decrypt(
input clk,
input [63:0]plain_text,
input start_cipher,
input reset,
output wire [63:0]cipher_text,
output reg busy,
output wire initializing,
//input [63:0]key,
output wire [7:0] s0_addr_b, s1_addr_b, s2_addr_b, s3_addr_b,
input  [31:0]s0_dout_b, s1_dout_b, s2_dout_b, s3_dout_b,
output reg fifo_rd_en,
input [31:0]P_fifo_out,
input encrypt_init_done,
input abort_blowfish
    );
    
//wire clk_in1, clk;
//wire locked;
//(*keep = "true"*)wire reset;

parameter idle = 4'b0000, before_sbox = 4'b0001, mem_rd_wait = 4'b0010, after_sbox = 4'b0011, last_itr = 4'b0100, 
          read_P = 4'b0110, mem_rd_wait2 = 4'b0111;
reg [3:0]pr_state, nx_state;

wire [63:0] pt;
wire [63:0] ct;
//reg sel_ctL, sel_ctR;  

reg regL_en, regR_en;
reg regL_l, regR_l;
wire [31:0]regL_in, regR_in;
wire [31:0]xL, xR;
wire [31:0]xLP, xLPF, xLPFR;
reg sel_xL, sel_xR;

//reg [31:0]P_init[17:0];
//reg [31:0]P_kinit[17:0];
reg [31:0]P_reg_in[17:0];
wire [31:0]P_reg_out[17:0];
//reg [17:0]sel_Ph, sel_Pl;
reg [17:0]regP_en, regP_l;

reg [31:0]P;
(*keep = "true"*)reg [4:0]feistel_count;
//reg [10:0] init_count;
reg feistel_count_en;//, init_count_en;
reg init_done;

//wire [7:0] s0_addr_b, s0_addr_b, s1_addr_a, s1_addr_b, s2_addr_a, s2_addr_b, s3_addr_a, s3_addr_b;
//wire [31:0]s0_dout_a, s1_dout_a, s2_dout_a, s3_dout_a, s0_dout_b, s1_dout_b, s2_dout_b, s3_dout_b;
wire ena, enb;
reg [31:0] dinb;

//reg P_mux_out;

//reg mem_write;
//reg [9:0]mem_addr_write;

//reg sel_mem_s0, sel_mem_s1, sel_mem_s2, sel_mem_s3;

reg start_cipher_reg;
wire start_cipher_pulse;

reg P_count_en;
(*keep = "true"*)reg [4:0]P_count;

integer i;

register8 regL (.din(regL_in), .dout(xL), .out_en(regL_en), .load(regL_l), .clk(clk), .reset(reset));
register8 regR (.din(regR_in), .dout(xR), .out_en(regR_en), .load(regR_l), .clk(clk), .reset(reset));

defparam regL.data_size = 32;
defparam regR.data_size = 32;

genvar k;
generate
for (k = 0; k<18; k = k+1)
begin   
    register8 regP (.din(P_fifo_out), .dout(P_reg_out[k]), .out_en(regP_en[k]), .load(regP_l[k]), .clk(clk), .reset(reset));
//    mux2 muxP (.din_0(), .din_1(), .dout(P_reg_in[k]))
end
endgenerate

//mux2 muxMem_s0 (.din_0(xLP[31:24]), .din_1(mem_addr_write[7:0]), .dout(s0_addr_b), .sel(sel_mem_s0));
//mux2 muxMem_s1 (.din_0(xLP[23:16]), .din_1(mem_addr_write[7:0]), .dout(s1_addr_b), .sel(sel_mem_s1));
//mux2 muxMem_s2 (.din_0(xLP[15:8]), .din_1(mem_addr_write[7:0]), .dout(s2_addr_b), .sel(sel_mem_s2));
//mux2 muxMem_s3 (.din_0(xLP[7:0]), .din_1(mem_addr_write[7:0]), .dout(s3_addr_b), .sel(sel_mem_s3));

//defparam muxMem_s0.data_size = 8;
//defparam muxMem_s1.data_size = 8;
//defparam muxMem_s2.data_size = 8;
//defparam muxMem_s3.data_size = 8;

//generate
//for (k=0; k<18; k= k+2)
//begin
//    mux2 muxPh (.din_0(P_kinit[k]), .din_1(pt[63:32]), .dout(P_reg_in[k]), .sel(sel_Ph[k]));
//    mux2 muxPl (.din_0(P_kinit[k+1]), .din_1(pt[31:0]), .dout(P_reg_in[k+1]), .sel(sel_Pl[k+1]));
//end
//endgenerate

mux2 mux_xL (.din_0(plain_text[63:32]), .din_1(xLPFR), .dout(regL_in), .sel(sel_xL));
mux2 mux_xR ( .din_0(plain_text[31:0]), .din_1(xLP), .dout(regR_in), .sel(sel_xR));

defparam mux_xL.data_size = 32;
defparam mux_xR.data_size = 32;

//demux2 demux_ctL (.din(ct[63:32]), .dout_1(cipher_text[63:32]), .dout_0(pt[63:32]), .sel(init_done));
//demux2 demux_ctR (.din(ct[31:0]), .dout_1(cipher_text[31:0]), .dout_0(pt[31:0]), .sel(init_done));

//defparam demux_ctL.data_size = 32;
//defparam demux_ctR.data_size = 32;

function[31:0] feistel_func;
input [31:0]s0, s1, s2, s3;
reg [31:0] x, y;
    begin
        x = s0 + s1;
        y = x ^ s2;
        feistel_func = y + s3;
    end
endfunction

initial 
begin
//    P_init[0] <= 32'h243f6a88;
//    P_init[1] <= 32'h85a308d3;
//    P_init[2] <= 32'h13198a2e;
//    P_init[3] <= 32'h03707344;
//    P_init[4] <= 32'ha4093822;
//    P_init[5] <= 32'h299f31d0;
//    P_init[6] <= 32'h082efa98;
//    P_init[7] <= 32'hec4e6c89;
//    P_init[8] <= 32'h452821e6;
//    P_init[9] <= 32'h38d01377;
//    P_init[10] <= 32'hbe5466cf;
//    P_init[11] <= 32'h34e90c6c;
//    P_init[12] <= 32'hc0ac29b7;
//    P_init[13] <= 32'hc97c50dd;
//    P_init[14] <= 32'h3f84d5b5;
//    P_init[15] <= 32'hb5470917;
//    P_init[16] <= 32'h9216d5d9;
//    P_init[17] <= 32'h8979fb1b;
    start_cipher_reg = 0;
    
//    pt <= 64'h0000000000000000;

/*---------------------------------P-array init----------------------*/ 
    

end


//assign ena = 1;
//assign enb = 1;
assign xLP = xL ^ P;
assign xLPF = feistel_func(s0_dout_b, s1_dout_b, s2_dout_b, s3_dout_b);
assign xLPFR = xLPF ^ xR;
assign ct[63:32] = xLP ^ P_reg_out[17];
assign ct[31:0] = xLPFR ^ P_reg_out[16];
assign initializing = ~init_done;
assign s0_addr_b = xLP[31:24];
assign s1_addr_b = xLP[23:16];
assign s2_addr_b = xLP[15:8];
assign s3_addr_b = xLP[7:0];
assign cipher_text = ct;

always @ *
begin
    P = P_reg_out[feistel_count[3:0]];
end

always @ (posedge(clk))
begin
    start_cipher_reg = start_cipher;
end

assign start_cipher_pulse = start_cipher & (~start_cipher_reg);

always @ (posedge(clk))
begin
    if(reset == 1 || start_cipher_pulse == 1)
        feistel_count = 0;
    else
         if (feistel_count_en == 1)
        begin
            feistel_count = feistel_count+1;
        end

end

always @ *
begin
    if(P_count == 0)
        init_done = 1;
    else
        init_done = 0;
end

always @ *
begin
    regP_l = {18{1'b0}};
    if(fifo_rd_en == 1)
        regP_l[P_count-1] = 1;
    else
        regP_l[P_count-1] = 0;
end

always @ (posedge(clk))
begin
    if(reset == 1)
        P_count = 18;
    else if (P_count_en == 1)
        P_count = P_count - 1;
end

/*---------------------------------State machine----------------------*/


/*---------------------------------Sequential logic-------------------*/

always @ (posedge(clk))
begin 
    if ((reset == 1) || (abort_blowfish == 1))
        pr_state = idle;
    else
        pr_state = nx_state;
end

/*---------------------------------Next state logic-------------------*/
always @ *
begin
    case(pr_state)
        idle:
        begin
            if(encrypt_init_done == 1 && init_done == 0)
                nx_state = read_P;
            else if(start_cipher == 1 && init_done == 1)
                nx_state = before_sbox;
                else
                    nx_state = idle;
        end 
        before_sbox: nx_state = mem_rd_wait;
        mem_rd_wait:
        begin
            if (feistel_count == 15)
                nx_state = last_itr;
            else if (feistel_count == 0)
                    nx_state = mem_rd_wait2;
                else
                    nx_state = after_sbox;
        end
        mem_rd_wait2: nx_state = after_sbox;
        after_sbox: nx_state = before_sbox;
        last_itr: nx_state = idle;
        read_P:
        begin
            if(P_count == 1)
                nx_state = idle;
           else
                nx_state = read_P;
        end
        
        default: nx_state = idle;
     endcase
end

/*---------------------------------Output logic-----------------------*/
always @ *
begin
    regR_en = 1;
    regL_en = 1;
    regP_en = {18{1'b1}};
    //initializing = 0;
    sel_xL = 0;
    sel_xR = 0;
    regL_l = 0;
    regR_l = 0;
    feistel_count_en = 0;
    fifo_rd_en = 0;
    P_count_en = 0;
    case (pr_state)
        idle:
        begin
           //xL = 0;
           //xR = 0;
           busy = 0;
        end
        before_sbox: 
        begin
            busy = 1; 
            if(feistel_count == 0)
            begin
                sel_xL = 0;
                sel_xR = 0;
                regL_l = 1;
                regR_l = 1;
            end
            else
            begin
               sel_xL = 1;
               sel_xR = 1;
               regL_l = 0;
               regR_l = 0; 
            end
        end
        mem_rd_wait: 
        begin
            busy = 1;
            regL_l = 0;
            regR_l = 0;
        end 
        after_sbox:
        begin
            busy = 1;
            feistel_count_en = 1;
            regL_l = 1;
            regR_l = 1;
            sel_xL = 1;
            sel_xR = 1;
        end  
        last_itr:
        begin
            busy = 1;
        end
        read_P:
        begin
            busy = 1;
            fifo_rd_en = 1;
            P_count_en = 1;
        end   
        mem_rd_wait2:
        begin
            busy = 1;
        end
        default: 
        begin
            regR_en = 1;
            regL_en = 1;
            regP_en = {18{1'b1}};
            //initializing = 0;
            sel_xL = 0;
            sel_xR = 0;
            regL_l = 0;
            regR_l = 0;
            feistel_count_en = 0;
            fifo_rd_en = 0;
            P_count_en = 0;
            busy = 0;
        end
        
    endcase
end

endmodule
