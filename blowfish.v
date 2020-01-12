`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2018 13:58:13
// Design Name: 
// Module Name: blowfish
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


module blowfish(
input clk,
input [63:0]plain_text,
input start_cipher,
input reset,
output wire [63:0]cipher_text,
output reg busy,
output wire initializing,
input [63:0]key,
output wire [7:0] s0_addr_a, s1_addr_a, s2_addr_a, s3_addr_a,
input  [31:0]s0_dout_a, s1_dout_a, s2_dout_a, s3_dout_a,
output reg s0_wea, s1_wea, s2_wea, s3_wea,
output reg [31:0]mem_din,
output reg fifo_wr_en,
output reg [31:0]P_fifo_in
    );
    
//wire clk_in1, clk;
//wire locked;
//(*keep = "true"*)wire reset;

parameter idle = 4'b0000, before_sbox = 4'b0001, mem_rd_wait = 4'b0010, after_sbox = 4'b0011, last_itr = 4'b0100, 
          init_end = 4'b0101, init_start = 4'b0110, init_end2 = 4'b0111, write_P = 4'b1000, mem_rd_wait2 = 4'b1001; 
(*keep = "true"*) reg [3:0]pr_state, nx_state;

wire [63:0] pt;
wire [63:0] ct;
reg sel_ctL, sel_ctR;  

reg regL_en, regR_en;
reg regL_l, regR_l;
wire [31:0]regL_in, regR_in;
wire [31:0]xL, xR;
wire [31:0]xLP, xLPF, xLPFR;
reg [1:0]sel_xL, sel_xR;

reg [31:0]P_init[17:0];
reg [31:0]P_kinit[17:0];
wire [31:0]P_reg_in[17:0];
wire [31:0]P_reg_out[17:0];
reg [17:0]sel_Ph, sel_Pl;
reg [17:0]regP_en, regP_l;

reg [31:0]P;
(*keep = "true"*)reg [4:0]feistel_count;
(*keep = "true"*)reg [10:0] init_count;
reg feistel_count_en, init_count_en;
reg init_done;

//wire [7:0] s0_addr_a, s0_addr_b, s1_addr_a, s1_addr_b, s2_addr_a, s2_addr_b, s3_addr_a, s3_addr_b;
//wire [31:0]s0_dout_a, s1_dout_a, s2_dout_a, s3_dout_a, s0_dout_b, s1_dout_b, s2_dout_b, s3_dout_b;
wire ena, enb;
reg [31:0] dinb;


//reg P_mux_out;


reg mem_write;
reg [9:0]mem_addr_write;

reg sel_mem_s0, sel_mem_s1, sel_mem_s2, sel_mem_s3;

reg start_cipher_reg;
wire start_cipher_pulse;

reg P_count_en;
(*keep = "true"*)reg [4:0]P_count;
reg P_count_done;


integer i;


register8 regL (.din(regL_in), .dout(xL), .out_en(regL_en), .load(regL_l), .clk(clk), .reset(reset));
register8 regR (.din(regR_in), .dout(xR), .out_en(regR_en), .load(regR_l), .clk(clk), .reset(reset));

defparam regL.data_size = 32;
defparam regR.data_size = 32;

genvar k;
generate
for (k = 0; k<18; k = k+1)
begin   
    register8 regP (.din(P_reg_in[k]), .dout(P_reg_out[k]), .out_en(regP_en[k]), .load(regP_l[k]), .clk(clk), .reset(reset));
//    mux2 muxP (.din_0(), .din_1(), .dout(P_reg_in[k]))
end
endgenerate

mux2 muxMem_s0 (.din_0(xLP[31:24]), .din_1(mem_addr_write[7:0]), .dout(s0_addr_a), .sel(sel_mem_s0));
mux2 muxMem_s1 (.din_0(xLP[23:16]), .din_1(mem_addr_write[7:0]), .dout(s1_addr_a), .sel(sel_mem_s1));
mux2 muxMem_s2 (.din_0(xLP[15:8]), .din_1(mem_addr_write[7:0]), .dout(s2_addr_a), .sel(sel_mem_s2));
mux2 muxMem_s3 (.din_0(xLP[7:0]), .din_1(mem_addr_write[7:0]), .dout(s3_addr_a), .sel(sel_mem_s3));

defparam muxMem_s0.data_size = 8;
defparam muxMem_s1.data_size = 8;
defparam muxMem_s2.data_size = 8;
defparam muxMem_s3.data_size = 8;

generate
for (k=0; k<18; k= k+2)
begin
    mux2 muxPh (.din_0(P_kinit[k]), .din_1(pt[63:32]), .dout(P_reg_in[k]), .sel(sel_Ph[k]));
    mux2 muxPl (.din_0(P_kinit[k+1]), .din_1(pt[31:0]), .dout(P_reg_in[k+1]), .sel(sel_Pl[k+1]));
end
endgenerate

mux4 mux_xL (.din_0(0), .din_1(pt[63:32]), .din_2(plain_text[63:32]), .din_3(xLPFR), .dout(regL_in), .sel(sel_xL));
mux4 mux_xR (.din_0(0), .din_1(pt[31:0]), .din_2(plain_text[31:0]), .din_3(xLP), .dout(regR_in), .sel(sel_xR));

defparam mux_xL.data_size = 32;
defparam mux_xR.data_size = 32;

demux2 demux_ctL (.din(ct[63:32]), .dout_1(cipher_text[63:32]), .dout_0(pt[63:32]), .sel(init_done));
demux2 demux_ctR (.din(ct[31:0]), .dout_1(cipher_text[31:0]), .dout_0(pt[31:0]), .sel(init_done));

defparam demux_ctL.data_size = 32;
defparam demux_ctR.data_size = 32;

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
    P_init[0] <= 32'h243f6a88;
    P_init[1] <= 32'h85a308d3;
    P_init[2] <= 32'h13198a2e;
    P_init[3] <= 32'h03707344;
    P_init[4] <= 32'ha4093822;
    P_init[5] <= 32'h299f31d0;
    P_init[6] <= 32'h082efa98;
    P_init[7] <= 32'hec4e6c89;
    P_init[8] <= 32'h452821e6;
    P_init[9] <= 32'h38d01377;
    P_init[10] <= 32'hbe5466cf;
    P_init[11] <= 32'h34e90c6c;
    P_init[12] <= 32'hc0ac29b7;
    P_init[13] <= 32'hc97c50dd;
    P_init[14] <= 32'h3f84d5b5;
    P_init[15] <= 32'hb5470917;
    P_init[16] <= 32'h9216d5d9;
    P_init[17] <= 32'h8979fb1b;
    start_cipher_reg = 0;
    
//    pt <= 64'h0000000000000000;

/*---------------------------------P-array init----------------------*/ 
    

end


assign ena = 1;
assign enb = 1;
assign xLP = xL ^ P;
assign xLPF = feistel_func(s0_dout_a, s1_dout_a, s2_dout_a, s3_dout_a);
assign xLPFR = xLPF ^ xR;
assign ct[63:32] = xLP ^ P_reg_out[17];
assign ct[31:0] = xLPFR ^ P_reg_out[16];
assign initializing = ~(init_done & P_count_done);

always @ *
begin
    if (mem_write == 0)
    begin
        s0_wea = 0;
        s1_wea = 0;
        s2_wea = 0;
        s3_wea = 0;
    end
    else
    begin
        s0_wea = 0;
        s1_wea = 0;
        s2_wea = 0;
        s3_wea = 0;
        case (mem_addr_write[9:8])
            2'b00: s0_wea = 1;
            2'b01: s1_wea = 1;
            2'b10: s2_wea = 1;
            2'b11: s3_wea = 1;    
        endcase
    end
end

always @ *
begin
    if (reset == 1)
        init_done = 0;
    else
    if (init_count == 1042)
        init_done = 1;
    else
        init_done = 0;
end

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
    if(reset == 1 || start_cipher_pulse == 1 || init_count_en == 1)
        feistel_count = 0;
    else
         if (feistel_count_en == 1)
        begin
            feistel_count = feistel_count+1;
        end
    if (reset == 1)
    begin
        init_count = 0;
    end
    else if (init_count_en == 1)
        begin
            init_count = init_count + 2;
        end
end


always @ *
begin
    for (i = 0; i<18; i = i+2)
    begin
        P_kinit[i] <= key[63:32] ^ P_init[i];
        P_kinit[i+1] <= key[31:0] ^ P_init[i+1];
    end
end

always @ *
begin
    P_fifo_in = P_reg_out[P_count];
    if(P_count > 17)
    begin
        P_count_done = 1;
    end
    else
        P_count_done = 0;
end

always @ (posedge(clk))
begin
    if(reset == 1)
        P_count = 0;
    else if (P_count_en == 1)
        P_count = P_count + 1;

end

/*---------------------------------State machine----------------------*/


/*---------------------------------Sequential logic-------------------*/

always @ (posedge(clk))
begin 
    if (reset == 1)
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
            if(init_done == 0)
                nx_state = init_start;
            else if(start_cipher == 1)
                nx_state = before_sbox;
                else
                    nx_state = idle;
        end 
        before_sbox: nx_state = mem_rd_wait;
        init_start:
        begin
            if(init_done)
            begin
                nx_state = write_P;
            end
            else
                nx_state = mem_rd_wait;
        end
        mem_rd_wait:
        begin
            if (feistel_count == 15 && init_done == 0)
                nx_state = init_end;
            else if (feistel_count == 15 && init_done == 1)
                nx_state = last_itr;
                else if (feistel_count == 0 && init_done == 1)
                    nx_state = mem_rd_wait2;
                    else
                        nx_state = after_sbox;
        end
        mem_rd_wait2: nx_state = after_sbox;
        after_sbox: nx_state = before_sbox;
        last_itr: nx_state = idle;
        init_end: nx_state = init_end2;
        init_end2:
        begin
                nx_state = init_start;
        end
        write_P:
        begin
            if (P_count < 17) 
                nx_state = write_P;
            else
                nx_state = idle;
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
    sel_xL = 2'b00;
    sel_xR = 2'b00;
    sel_Ph = {18{1'b0}};
    sel_Pl = {18{1'b0}};
    regP_l = {18{1'b0}};
    regL_l = 0;
    regR_l = 0;
    feistel_count_en = 0;
    sel_ctL = 1'b0;
    sel_ctR = 1'b0;
    mem_write = 0;
    mem_din = 0;
    mem_addr_write[9:0] = 0;
    init_count_en = 0;
    sel_mem_s0 = 0;
    sel_mem_s1 = 0;
    sel_mem_s2 = 0;
    sel_mem_s3 = 0;
    fifo_wr_en = 0;
    P_count_en = 0;
    case (pr_state)
        idle:
        begin
           //xL = 0;
           //xR = 0;
           busy = 0;
        end
        init_start:
        begin
            busy = 1;
            //initializing = 1;
            if(init_count == 0 && feistel_count == 0)
            begin
                sel_xL = 2'b00;
                sel_xR = 2'b00;
                sel_Ph = {18{1'b0}};
                sel_Pl = {18{1'b0}};
                regP_l = {18{1'b1}};
                regL_l = 1;
                regR_l = 1;
            end
            else if(init_count != 0 && feistel_count == 0)
            begin
                regP_l[init_count-1] = 1'b0;
                regP_l[init_count-2] = 1'b0;
                sel_xL = 2'b01;
                sel_xR = 2'b01;
                regL_l = 0;
                regR_l = 0;
            end
            else
            begin
                sel_xL = 2'b11;
                sel_xR = 2'b11;
                regL_l = 0;
                regR_l = 0;
            end        
        end 
        before_sbox: 
        begin 
            busy = 1;
            sel_mem_s0 = 0;
            sel_mem_s1 = 0;
            sel_mem_s2 = 0;
            sel_mem_s3 = 0;
            if(feistel_count == 0)
            begin
                sel_xL = 2'b10;
                sel_xR = 2'b10;
                regL_l = 1;
                regR_l = 1;
            end
            else
            begin
               sel_xL = 2'b11;
               sel_xR = 2'b11;
               regL_l = 0;
               regR_l = 0; 
            end    
        end
        mem_rd_wait: 
        begin
            busy = 1;
            sel_mem_s0 = 0;
            sel_mem_s1 = 0;
            sel_mem_s2 = 0;
            sel_mem_s3 = 0;
            regL_l = 0;
            regR_l = 0;
            regP_l = {18{1'b0}};
        end 
        after_sbox:
        begin
            busy = 1;
            sel_mem_s0 = 0;
            sel_mem_s1 = 0;
            sel_mem_s2 = 0;
            sel_mem_s3 = 0;
            feistel_count_en = 1;
            regL_l = 1;
            regR_l = 1;
            sel_xL = 2'b11;
            sel_xR = 2'b11;
        end  
        last_itr:
        begin
            busy = 1;
            sel_ctL = 1'b0;
            sel_ctR = 1'b0;
        end
        init_end:
        begin
            busy = 1;
            sel_ctL = 1'b1;
            sel_ctR = 1'b1;
            sel_mem_s0 = 1;
            sel_mem_s1 = 1;
            sel_mem_s2 = 1;
            sel_mem_s3 = 1;
            if (init_count < 18)
            begin
                sel_Ph[init_count] = 1'b1;
                sel_Pl[init_count+1] = 1'b1;
                regP_l[init_count] = 1'b1;
                regP_l[init_count+1] = 1'b1;
                mem_write = 0;
                mem_din = 0;
                mem_addr_write = 0;
            end
            else
            begin
                mem_write = 1;
                sel_Ph[init_count] = 1'b1;
                sel_Pl[init_count+1] = 1'b1;
                regP_l[init_count] = 1'b0;
                regP_l[init_count+1] = 1'b0;
                mem_addr_write[9:0] = init_count - 18;
                mem_din = ct[63:32];
            end
        end
        init_end2:
        begin
            busy = 1;
            sel_mem_s0 = 1;
            sel_mem_s1 = 1;
            sel_mem_s2 = 1;
            sel_mem_s3 = 1;
            mem_din = ct[31:0];
            init_count_en = 1;
            mem_addr_write = init_count - 17;
            regL_l = 1;
            regR_l = 1;
            sel_xL = 1;
            sel_xR = 1;
            if (init_count > 17)
            begin
                mem_write = 1;
            end
            else
            begin
                mem_write = 0;            
            end
        end
        write_P:
        begin
            busy = 1;
            fifo_wr_en = 1;
            P_count_en = 1;
        end
        mem_rd_wait2:
        begin
            busy = 1;
        end
        default: 
        begin
            busy = 0;
            regR_en = 1;
            regL_en = 1;
            regP_en = {18{1'b1}};
            //initializing = 0;
            sel_xL = 2'b00;
            sel_xR = 2'b00;
            sel_Ph = {18{1'b0}};
            sel_Pl = {18{1'b0}};
            regP_l = {18{1'b0}};
            regL_l = 0;
            regR_l = 0;
            feistel_count_en = 0;
            sel_ctL = 1'b0;
            sel_ctR = 1'b0;
            mem_write = 0;
            mem_din = 0;
            mem_addr_write[9:0] = 0;
            init_count_en = 0;
            fifo_wr_en = 0;
            P_count_en = 0;
        end        
    endcase
end

endmodule



