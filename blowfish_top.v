`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2018 12:50:07
// Design Name: 
// Module Name: blowfish_top
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


module blowfish_top(
input clk,
input [63:0]plain_text,
input [63:0]plain_text_decrypt,
input start_cipher,
input start_cipher_decrypt,
input reset,
output wire [63:0]cipher_text,
output wire [63:0]cipher_text_decrypt,
output wire busy_encrypt,
output wire busy_decrypt,
output wire initializing,
output wire initializing_decrypt,
input [63:0]key,
input abort_blowfish
    );
 
wire [7:0] s0_addr_a, s1_addr_a, s2_addr_a, s3_addr_a;
wire [31:0]s0_dout_a, s1_dout_a, s2_dout_a, s3_dout_a;
wire s0_wea, s1_wea, s2_wea, s3_wea;
wire [31:0]mem_din;
wire clk_in1, clk_out1;
//wire locked;
(*keep = "true"*)wire sys_reset;
wire ena, enb;
wire [31:0] P_fifo_in, P_fifo_out;
wire fifo_wr_en, fifo_rd_en;
wire full, empty;
wire web;
wire [7:0] s0_addr_b, s1_addr_b, s2_addr_b, s3_addr_b;
wire [31:0]s0_dout_b, s1_dout_b, s2_dout_b, s3_dout_b;
wire [31:0]dinb;

assign clk_out1 = clk;

fifo_generator_0 P_fifo(
  .rst(sys_reset),                  // input wire rst
  .wr_clk(clk_out1),            // input wire wr_clk
  .rd_clk(clk_out1),            // input wire rd_clk
  .din(P_fifo_in),                  // input wire [31 : 0] din
  .wr_en(fifo_wr_en),              // input wire wr_en
  .rd_en(fifo_rd_en),              // input wire rd_en
  .dout(P_fifo_out),                // output wire [31 : 0] dout
  .full(full),                // output wire full
  .empty(empty)              // output wire empty
//  .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
//  .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
);
 
blowfish encrypt_core(
    .clk(clk_out1),
    .plain_text(plain_text),
    .start_cipher(start_cipher),
    .reset(sys_reset),
    .cipher_text(cipher_text),
    .busy(busy_encrypt),
    .initializing(initializing),
    .key(key),
    .s0_addr_a(s0_addr_a), .s1_addr_a(s1_addr_a), .s2_addr_a(s2_addr_a), .s3_addr_a(s3_addr_a),
    .s0_dout_a(s0_dout_a), .s1_dout_a(s1_dout_a), .s2_dout_a(s2_dout_a), .s3_dout_a(s3_dout_a),
    .s0_wea(s0_wea), .s1_wea(s1_wea), .s2_wea(s2_wea), .s3_wea(s3_wea),
    .mem_din(mem_din),
    .fifo_wr_en(fifo_wr_en),
    .P_fifo_in(P_fifo_in)
    );

blowfish_decrypt decrpyt_core(
   .clk(clk_out1),
   .plain_text(plain_text_decrypt),
   .start_cipher(start_cipher_decrypt),
   .reset(sys_reset),
   .cipher_text(cipher_text_decrypt),
   .busy(busy_decrypt),
   .initializing(initializing_decrypt),
   //.key(key),
   .s0_addr_b(s0_addr_b), .s1_addr_b(s1_addr_b), .s2_addr_b(s2_addr_b), .s3_addr_b(s3_addr_b),
   .s0_dout_b(s0_dout_b), .s1_dout_b(s1_dout_b), .s2_dout_b(s2_dout_b), .s3_dout_b(s3_dout_b),
   .fifo_rd_en(fifo_rd_en),
   .P_fifo_out(P_fifo_out),
   .encrypt_init_done(~initializing),
   .abort_blowfish(abort_blowfish)
   );
    
blk_mem_gen_2 memoryS0 (
          .clka(clk_out1),            // input wire clka
          .rsta(sys_reset),            // input wire rsta
          .ena(ena),              // input wire ena
          .wea(s0_wea),              // input wire [0 : 0] wea
          .addra(s0_addr_a),          // input wire [7 : 0] addra
          .dina(mem_din),            // input wire [31 : 0] dina
          .douta(s0_dout_a),          // output wire [31 : 0] douta
          .clkb(clk_out1),            // input wire clkb
          .enb(enb),              // input wire enb
          .web(web),              // input wire [0 : 0] web
          .addrb(s0_addr_b),          // input wire [7 : 0] addrb
          .dinb(dinb),            // input wire [31 : 0] dinb
          .doutb(s0_dout_b)          // output wire [31 : 0] doutb
          //.rsta_busy(rsta_busy),  // output wire rsta_busy
          //.rstb_busy(rstb_busy)  // output wire rstb_busy
        );
    
    blk_mem_gen_2 memoryS1 (
          .clka(clk_out1),            // input wire clka
          .rsta(sys_reset),            // input wire rsta
          .ena(ena),              // input wire ena
          .wea(s1_wea),              // input wire [0 : 0] wea
          .addra(s1_addr_a),          // input wire [7 : 0] addra
          .dina(mem_din),            // input wire [31 : 0] dina
          .douta(s1_dout_a),          // output wire [31 : 0] douta
          .clkb(clk_out1),            // input wire clkb
          .enb(enb),              // input wire enb
          .web(web),              // input wire [0 : 0] web
          .addrb(s1_addr_b),          // input wire [7 : 0] addrb
          .dinb(dinb),            // input wire [31 : 0] dinb
          .doutb(s1_dout_b)          // output wire [31 : 0] doutb
//          .rsta_busy(rsta_busy),  // output wire rsta_busy
//          .rstb_busy(rstb_busy)  // output wire rstb_busy
        );
    
    blk_mem_gen_2 memoryS2 (
          .clka(clk_out1),            // input wire clka
          .rsta(sys_reset),            // input wire rsta
          .ena(ena),              // input wire ena
          .wea(s2_wea),              // input wire [0 : 0] wea
          .addra(s2_addr_a),          // input wire [7 : 0] addra
          .dina(mem_din),            // input wire [31 : 0] dina
          .douta(s2_dout_a),          // output wire [31 : 0] douta
          .clkb(clk_out1),            // input wire clkb
          .enb(enb),              // input wire enb
          .web(web),              // input wire [0 : 0] web
          .addrb(s2_addr_b),          // input wire [7 : 0] addrb
          .dinb(dinb),            // input wire [31 : 0] dinb
          .doutb(s2_dout_b)          // output wire [31 : 0] doutb
//          .rsta_busy(rsta_busy),  // output wire rsta_busy
//          .rstb_busy(rstb_busy)  // output wire rstb_busy
        );
    
    blk_mem_gen_2 memoryS3 (
          .clka(clk_out1),            // input wire clka
          .rsta(sys_reset),            // input wire rsta
          .ena(ena),              // input wire ena
          .wea(s3_wea),              // input wire [0 : 0] wea
          .addra(s3_addr_a),          // input wire [7 : 0] addra
          .dina(mem_din),            // input wire [31 : 0] dina
          .douta(s3_dout_a),          // output wire [31 : 0] douta
          .clkb(clk_out1),            // input wire clkb
          .enb(enb),              // input wire enb
          .web(web),              // input wire [0 : 0] web
          .addrb(s3_addr_b),          // input wire [7 : 0] addrb
          .dinb(dinb),            // input wire [31 : 0] dinb
          .doutb(s3_dout_b)          // output wire [31 : 0] doutb
//          .rsta_busy(rsta_busy),  // output wire rsta_busy
//          .rstb_busy(rstb_busy)  // output wire rstb_busy
        );

assign clk_in1 = clk;
assign sys_reset = reset;
assign ena = 1;
assign enb = 1;
assign web = 0;
assign dinb = 0;

endmodule
