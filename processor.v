`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:14:22 05/19/2017 
// Design Name: 
// Module Name:    processor 
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
module processor(
//    datalines,
    clk_in1, reset_in, data_mem_out, code_mem_write_done
    );
parameter data_size = 32;
parameter code_size = 26;

output wire [31:0] data_mem_out;
output code_mem_write_done;
//inout [data_size-1:0] datalines;
input clk_in1, reset_in;//, stop_count, load_mem;
//input [data_size-1:0]	ext_mem_data_lines;
//input [data_size-1:0] ext_addr_lines;

wire clk;
wire locked, reset; //reset_in;

//code burn signals
(*keep = "true"*)wire [2*data_size-1:0]ext_code_mem_din_pt;
wire code_mem_write_done;
//reg [2*data_size-1:0]ext_code_mem_din;

//code side blowfish
wire code_mem_start_cipher, code_mem_start_cipher_decrypt;
wire code_mem_initializing_encrypt, code_mem_initializing_decrypt;
(*keep = "true"*)wire [63:0]code_mem_key;
wire code_mem_busy_encrypt, code_mem_busy_decrypt;
(*keep = "true"*)wire [63:0]code_mem_blowfish_decrypt_out;
wire code_side_abort_blowfish;

//code memory signals
wire [2*data_size-1:0]code_mem_dout;
wire [12:0]  ext_code_addr_lines;
(*keep = "true"*)reg [12:0] code_addr_lines;
wire code_mem_write;
(*keep = "true"*)wire [2*data_size-1:0] code_mem_din;

//PC signals
wire [1:0] PC_inp_sel;
wire PC_regload;
wire PC_regen;
wire PC_addr_out;
reg [data_size-1:0]PC_data_in;
wire [1:0]PC_src_sel;
(*keep = "true"*)wire [12:0]PC_addr_lines;
wire PC_inp_sel_en;

//link signals
wire link_en, link_la;
wire [data_size-1:0] link_data_in;
wire [data_size-1:0]link_out;

//code side fifo signals
wire code_side_fifo_wr_en, code_side_fifo_rd_en;
wire code_side_fifo_full, code_side_fifo_empty;
wire code_side_fifo_flush;
wire code_side_fifo_reset;
wire code_side_fifo_wr_rst_busy;
wire code_side_fifo_rd_rst_busy;

//IR signals
(*keep = "true"*)wire [data_size-1:0]ir_dout;
wire ir_enable, ir_latch;
(*keep = "true"*)wire [data_size-1:0]ir_din;

//datapath signals
(*keep = "true"*)wire [data_size-1:0]register_dout_1, register_dout_2;
reg [data_size-1:0] register_din;
wire register_write;
wire [1:0]reg_inp_src_sel;
reg [4:0]reg_write_sel;
wire reg_write_sel_mux_sel;
wire [4:0]reg_dest_fifo_out;
wire reg_dest_fifo_full, reg_dest_fifo_empty;
wire reg_dest_fifo_rd_en, reg_dest_fifo_wr_en;

//ALU signals
(*keep = "true"*)wire [data_size-1:0]PSR_out, ALU_out;
wire ALU_out_l, alu_src_latch_1, alu_src_latch_2;
(*keep = "true"*)reg [data_size-1:0] ALU_src_2;
wire ALU_src_2_sel;
(*keep = "true"*)wire [5:0] func;

//data side blowfish
wire data_mem_start_cipher, data_mem_start_cipher_decrypt;
wire data_mem_initializing_encrypt, data_mem_initializing_decrypt;
wire data_mem_busy_encrypt, data_mem_busy_decrypt;
(*keep = "true"*)wire [63:0]data_mem_key;
(*keep = "true"*)wire [63:0]data_mem_cipher_text_decrypt;

//data memory signals
//wire [data_size-1:0] data_mem_reg_dout;(*keep = "true"*)
(*keep = "true"*)wire [63:0]data_mem_dout;
//reg [15:0]data_addr_lines;
wire data_mem_write;
(*keep = "true"*)wire [2*data_size-1:0]data_mem_din;
(*keep = "true"*)wire [data_size-1:0] reg_data_mem_din;
wire data_mem_decrypt_done;
//wire data_mem_addr_sel;

//MWR and MRR signals
(*keep = "true"*)wire [data_size-1:0] reg_din_from_data_mem;
wire MWR_fifo_wr_en, MWR_fifo_rd_en, MRR_fifo_wr_en, MRR_fifo_rd_en;
(*keep = "true"*)wire [2*data_size-1:0]MWR_fifo_dout, MRR_fifo_dout;
wire MWR_fifo_full, MWR_fifo_empty;
wire MRR_fifo_full, MRR_fifo_empty;
//wire MWR_wr_rst_busy, MWR_rd_rst_busy;
//wire MRR_wr_rst_busy, MRR_rd_rst_busy;
wire MWR_addr_fifo_wr_en, MWR_addr_fifo_rd_en;
wire MWR_addr_fifo_full, MWR_addr_fifo_empty;
//wire MWR_addr_wr_rst_busy, MWR_addr_rd_rst_busy;
(*keep = "true"*)wire [14:0]MWR_addr_fifo_out;

clk_wiz_0 clk_100MHz
(
    // Clock out ports
    .clk_out1(clk),     // output clk_out1
    // Status and control signals
    .reset(0), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_in1)
);

//Debounce debounce_reset(
//    .clock(clk_in1),
//    .btn(reset_bounce),
//    .sig(reset_in)
//); 

code_burner code_burn_automatic (
    .clk(clk),
    .reset(reset),
    .ext_code_addr_lines(ext_code_addr_lines), 
    .ext_code_encrypt_din(ext_code_mem_din_pt), 
    .ext_code_mem_write(code_mem_write), 
    .code_mem_write_done(code_mem_write_done), 
    .start_cipher(code_mem_start_cipher), 
    .cipher_busy(code_mem_busy_encrypt),
    .encrypt_initializing(code_mem_initializing_decrypt)
);
defparam code_burn_automatic.code_size = code_size;

blowfish_top code_mem_blowfish (
    .clk(clk),
    .plain_text(ext_code_mem_din_pt),
    .plain_text_decrypt(code_mem_dout),
    .start_cipher(code_mem_start_cipher),
    .start_cipher_decrypt(code_mem_start_cipher_decrypt),
    .reset(reset),
    .cipher_text(code_mem_din),
    .cipher_text_decrypt(code_mem_blowfish_decrypt_out),
    .busy_encrypt(code_mem_busy_encrypt),
    .busy_decrypt(code_mem_busy_decrypt),
    .initializing(code_mem_initializing_encrypt),
    .initializing_decrypt(code_mem_initializing_decrypt),
    .key(code_mem_key),
    .abort_blowfish(code_side_abort_blowfish)
);

blk_mem_gen_0 code_memory ( //This is 64kB memory
    .clka(clk),    // input wire clka
    .ena(1'b1),      // input wire ena
    .wea(code_mem_write),      // input wire [0 : 0] wea
    .addra(code_addr_lines),  // input wire [12 : 0] addra
    .dina(code_mem_din),    // input wire [63 : 0] dina
    .douta(code_mem_dout)  // output wire [63 : 0] douta
);
						
program_counter PC(
    .PC_IS(PC_inp_sel), 
    .PC_regload(PC_regload), 
    .PC_regen(PC_regen), 
    .Address_line(PC_addr_lines), 
    .AD_sel(PC_addr_out), 
    .clk_pc(clk),
    .reset_pc(reset), 
    .data_in(PC_data_in)
);

register8 link (
    .din({16'h0000, 3'b000, code_addr_lines}), 
    .dout(link_out), 
    .out_en(link_en), 
    .load(link_la), 
    .clk(clk), 
    .reset(reset)
);
defparam link.data_size = data_size;

code_side_fifo blowfish_fifo_IR (
    .rst(code_side_fifo_reset),                  // input wire rst
    .wr_clk(clk),            // input wire wr_clk
    .rd_clk(clk),            // input wire rd_clk
    .din(code_mem_blowfish_decrypt_out),                  // input wire [63 : 0] din
    .wr_en(code_side_fifo_wr_en),              // input wire wr_en
    .rd_en(code_side_fifo_rd_en),              // input wire rd_en
    .dout(ir_din),                // output wire [31 : 0] dout
    .full(code_side_fifo_full),                // output wire full
    .empty(code_side_fifo_empty),              // output wire empty
    .wr_rst_busy(code_side_fifo_wr_rst_busy),  // output wire wr_rst_busy
    .rd_rst_busy(code_side_fifo_rd_rst_busy)  // output wire rd_rst_busy
);

code_mem_fsm instruction_controller (

    .clk(clk),
    .reset(reset),
    .code_mem_write_done(code_mem_write_done),
    .code_mem_busy_decrypt(code_mem_busy_decrypt),
    .code_side_fifo_full(code_side_fifo_full),
    .PC_inp_sel_en(PC_inp_sel_en),
    .code_side_fifo_wr_rst_busy(code_side_fifo_wr_rst_busy),
    .PC_addr_lines(PC_addr_lines),
    
    .code_mem_start_cipher_decrypt(code_mem_start_cipher_decrypt),
    .PC_inp_sel(PC_inp_sel),
    .PC_regload_pulse(PC_regload),
    .PC_regen(PC_regen),
    .PC_addr_out(PC_addr_out),
    .link_la(link_la),
    .link_en(link_en),
    .code_side_fifo_wr_en(code_side_fifo_wr_en),
    .code_side_fifo_flush(code_side_fifo_flush),
    .code_side_abort_blowfish(code_side_abort_blowfish)
);
defparam instruction_controller.code_size = code_size/2;

register8 IR (
    .din(ir_din), 
    .dout(ir_dout), 
    .out_en(ir_enable), 
    .load(ir_latch), 
    .clk(clk), 
    .reset(reset)
);
defparam IR.data_size = data_size;

data_path DP( //these are registers only
    .dpclk(clk), 
    .rst(reset), 
    .read_sel_1(ir_dout[20:16]), 
    .read_sel_2(ir_dout[15:11]),
    .data_in(register_din), 
    .data_out_1(register_dout_1), 
    .data_out_2(register_dout_2),
    .write(register_write), 
    .out_en_1(1'b1), 
    .out_en_2(1'b1), 
    .write_sel(reg_write_sel), 
    .data_out_dest(reg_data_mem_din)
);
defparam DP.data_size = data_size;

ALU alu_inst( 
    .tr1_in(register_dout_1), 
    .tr2_in(ALU_src_2), 
    .ALU_out(ALU_out), 
    .op_bits(ir_dout[29:26]), 
    .ALU_out_en(1'b1),
    .tr1_en(1'b1), 
    .tr2_en(1'b1), 
    .tr1_l(alu_src_latch_1), 
    .tr2_l(alu_src_latch_2), 
    .clk_alu(clk), 
    .reset_alu(reset), 
    .ALU_out_l(ALU_out_l), 
    .PSR_out(PSR_out), 
    .func(func), 
    .shift_amount(ir_dout[10:6])
);
defparam alu_inst.data_size = data_size;

blowfish_top data_mem_blowfish (
    .clk(clk),
    .plain_text(MWR_fifo_dout),
    .plain_text_decrypt(MRR_fifo_dout),
    .start_cipher(data_mem_start_cipher),
    .start_cipher_decrypt(data_mem_start_cipher_decrypt),
    .reset(reset),
    .cipher_text(data_mem_din),
    .cipher_text_decrypt(data_mem_cipher_text_decrypt),
    .busy_encrypt(data_mem_busy_encrypt),
    .busy_decrypt(data_mem_busy_decrypt),
    .initializing(data_mem_initializing_encrypt),
    .initializing_decrypt(data_mem_initializing_decrypt),
    .key(data_mem_key),
    .abort_blowfish(0)
);

blk_mem_gen_1 data_memory (
    .clka(clk),    // input wire clka
    .ena(1'b1),      // input wire ena
    .wea(data_mem_write),      // input wire [0 : 0] wea
    .addra(MWR_addr_fifo_out),  // input wire [14 : 0] addra
    .dina(data_mem_din),    // input wire [63 : 0] dina
    .clkb(clk),    // input wire clkb
    .enb(1'b1),      // input wire enb
    .addrb(ALU_out[14:0]),  // input wire [14 : 0] addrb
    .doutb(data_mem_dout)  // output wire [63 : 0] doutb
);

data_write_fifo MWR_fifo (
    .rst(reset),                  // input wire rst
    .wr_clk(clk),            // input wire wr_clk
    .rd_clk(clk),            // input wire rd_clk
    .din({reg_data_mem_din,32'h00000000}),                  // input wire [63 : 0] din
    .wr_en(MWR_fifo_wr_en),              // input wire wr_en
    .rd_en(MWR_fifo_rd_en),              // input wire rd_en
    .dout(MWR_fifo_dout),                // output wire [63 : 0] dout
    .full(MWR_fifo_full),                // output wire full
    .empty(MWR_fifo_empty)              // output wire empty
//    .wr_rst_busy(MWR_wr_rst_busy),  // output wire wr_rst_busy
//    .rd_rst_busy(MWR_rd_rst_busy)  // output wire rd_rst_busy
);

data_write_fifo_addr MWR_fifo_addr (
    .rst(reset),                  // input wire rst
    .wr_clk(clk),            // input wire wr_clk
    .rd_clk(clk),            // input wire rd_clk
    .din(ALU_out[14:0]),                  // input wire [14 : 0] din
    .wr_en(MWR_addr_fifo_wr_en),              // input wire wr_en
    .rd_en(MWR_addr_fifo_rd_en),              // input wire rd_en
    .dout(MWR_addr_fifo_out),                // output wire [14 : 0] dout
    .full(MWR_addr_fifo_full),                // output wire full
    .empty(MWR_addr_fifo_empty)              // output wire empty
//    .wr_rst_busy(MWR_addr_wr_rst_busy),  // output wire wr_rst_busy
//    .rd_rst_busy(MWR_addr_rd_rst_busy)  // output wire rd_rst_busy
);

data_mem_write_fsm MWR_fsm(
    .clk(clk),
    .reset(reset),
    .MWR_fifo_empty(MWR_fifo_empty),
    .MWR_fifo_rd_en(MWR_fifo_rd_en),
    .data_mem_initializing_encrypt(data_mem_initializing_encrypt), 
    .data_mem_initializing_decrypt(data_mem_initializing_decrypt), 
    .data_mem_busy_encrypt(data_mem_busy_encrypt), 
    .data_mem_start_cipher_encrypt(data_mem_start_cipher),
    .data_mem_write(data_mem_write),
    .MWR_addr_fifo_rd_en(MWR_addr_fifo_rd_en)
//    .MWR_addr_fifo_empty(MWR_addr_fifo_empty)
);

data_read_fifo MRR_fifo (
    .rst(reset),                  // input wire rst
    .wr_clk(clk),            // input wire wr_clk
    .rd_clk(clk),            // input wire rd_clk
    .din(data_mem_dout),                  // input wire [63 : 0] din
    .wr_en(MRR_fifo_wr_en),              // input wire wr_en
    .rd_en(MRR_fifo_rd_en),              // input wire rd_en
    .dout(MRR_fifo_dout),                // output wire [63 : 0] dout
    .full(MRR_fifo_full),                // output wire full
    .empty(MRR_fifo_empty)              // output wire empty
//    .wr_rst_busy(MRR_wr_rst_busy),  // output wire wr_rst_busy
//    .rd_rst_busy(MRR_rd_rst_busy)  // output wire rd_rst_busy
);

register_dest_fifo MRR_fifo_dest (
    .rst(reset),                  // input wire rst
    .wr_clk(clk),            // input wire wr_clk
    .rd_clk(clk),            // input wire rd_clk
    .din(ir_dout[25:21]),                  // input wire [4 : 0] din
    .wr_en(reg_dest_fifo_wr_en),              // input wire wr_en
    .rd_en(reg_dest_fifo_rd_en),              // input wire rd_en
    .dout(reg_dest_fifo_out),                // output wire [4 : 0] dout
    .full(reg_dest_fifo_full),                // output wire full
    .empty(reg_dest_fifo_empty)       // output wire empty           
//    .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
//    .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
);


data_mem_read_fsm MRR_fsm(
    .clk(clk),
    .reset(reset),
    .MRR_fifo_empty(MRR_fifo_empty),
    .reg_dest_fifo_rd_en(reg_dest_fifo_rd_en), 
    .MRR_fifo_rd_en(MRR_fifo_rd_en), 
    .data_mem_busy_decrypt(data_mem_busy_decrypt), 
    .data_mem_start_cipher_decrypt(data_mem_start_cipher_decrypt), 
    .data_mem_initializing_decrypt(data_mem_initializing_decrypt),
    .data_mem_decrypt_done(data_mem_decrypt_done)
    );
										
controller control(
    //inputs
    .clk(clk),
    .reset(reset),
    .code_side_fifo_empty(code_side_fifo_empty),
    .op_bits(ir_dout[31:26]),
    .code_side_fifo_rd_rst_busy(code_side_fifo_rd_rst_busy),
    .PSR(PSR_out[2:0]),
    .data_mem_decrypt_done(data_mem_decrypt_done),
    
    //outputs
    .ir_enable(ir_enable),
    .ir_latch(ir_latch),
    .register_write(register_write),
    .alu_src_latch_1(alu_src_latch_1),
    .alu_src_latch_2(alu_src_latch_2),
    .ALU_out_l(ALU_out_l),
    .ALU_src_2_sel(ALU_src_2_sel),
    .reg_inp_src_sel(reg_inp_src_sel),
    .func_from_ir(ir_dout[5:0]),
    
    .MWR_fifo_wr_en(MWR_fifo_wr_en),
    .MWR_addr_fifo_wr_en(MWR_addr_fifo_wr_en),
    .MRR_fifo_wr_en(MRR_fifo_wr_en),
    .code_side_fifo_rd_en(code_side_fifo_rd_en),
    .reg_dest_fifo_wr_en(reg_dest_fifo_wr_en),
    .reg_write_sel_mux_sel(reg_write_sel_mux_sel),
    .reg_dest_fifo_rd_en(reg_dest_fifo_rd_en),
    .PC_inp_sel_en(PC_inp_sel_en),
    .PC_src_sel(PC_src_sel),
    .func(func)
);
                                                                    
assign reset = reset_in || ~(locked);
assign link_data_in = {16'h0000, 3'b000,code_addr_lines};
assign code_mem_key = 64'h1234567812345678;
assign data_mem_key = 64'h1234567812345678;
assign reg_din_from_data_mem = data_mem_cipher_text_decrypt[63:32];
assign code_side_fifo_reset = reset || code_side_fifo_flush;
assign data_mem_out = {data_mem_dout[63:56], ALU_out[31:24] , ALU_out[15:8], data_mem_dout[7:0]};
										
always @ *
begin
    case(PC_src_sel)
    2'b00: PC_data_in = link_out;
    2'b01: PC_data_in = {2'b00, (ir_dout[29:0]>>1)};
    2'b10: PC_data_in = {5'h00000, 1'b0, (ir_dout[10:0]>>1)};
    default: PC_data_in = link_out;
    endcase
    
    if(code_mem_write_done)
        code_addr_lines = PC_addr_lines;
    else
        code_addr_lines = ext_code_addr_lines;
    
    register_din = 0;    
    case (reg_inp_src_sel)
    2'b00: register_din = {16'h0000, ir_dout[15:0]};
    2'b01: register_din = register_dout_1;
    2'b10: register_din = ALU_out;
    2'b11: register_din = reg_din_from_data_mem;
    default: register_din = 0;
    endcase
    
    if(ALU_src_2_sel == 0)
        ALU_src_2 = register_dout_2;
    else
        ALU_src_2 = {16'h0000, ir_dout[15:0]};
        
    if(reg_write_sel_mux_sel == 1)
        reg_write_sel = reg_dest_fifo_out;
    else
        reg_write_sel = ir_dout[25:21];
        
//    if (data_mem_addr_sel == 1)
//        data_addr_lines = MWR_addr_fifo_out;
//    else
//        data_addr_lines = ALU_out;
    
end

endmodule
