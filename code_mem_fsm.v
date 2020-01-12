`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2018 11:15:36
// Design Name: 
// Module Name: code_mem_fsm
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


module code_mem_fsm(

    input clk, reset,
    input code_mem_write_done,
    input code_mem_busy_decrypt,
    input code_side_fifo_full,
    input PC_inp_sel_en,
    input code_side_fifo_wr_rst_busy,
    input [12:0]PC_addr_lines,
    
    output reg code_mem_start_cipher_decrypt,
    output reg [1:0]PC_inp_sel,
    output wire PC_regload_pulse,
    output reg PC_regen,
    output reg PC_addr_out,
    //output reg [1:0]PC_src_sel,
    output reg link_la,
    output reg link_en,
    output reg code_side_fifo_wr_en,
    output reg code_side_fifo_flush,
    output reg code_side_abort_blowfish
    
);

parameter code_size = 3;
parameter idle = 3'b000, start_cipher_state = 3'b001, wait_state = 3'b010, write_state = 3'b011, 
          branch_state = 3'b100, fifo_flush_wait = 3'b101;
reg [2:0]pr_state, nx_state;

reg code_mem_read_done;
reg [15:0]code_addr_cnt;
reg code_addr_cnt_en;
reg regload_reg, PC_regload;
//wire regload_pulse;

assign   PC_regload_pulse = PC_regload & ~(regload_reg);

always @(posedge(clk))
begin
    regload_reg = PC_regload;
end

always @ (posedge(clk))
begin
    if (reset)
        code_addr_cnt = 0;
    else if (code_addr_cnt_en == 1)
        code_addr_cnt = code_addr_cnt + 1;
end

always @ *
begin
    if (PC_addr_lines == (code_size))
        code_mem_read_done = 1;
    else
        code_mem_read_done = 0;
end
/*------------------Sequential logic------------------*/
always @ (posedge(clk))
begin
    if(reset)
        pr_state = idle;
    else
    begin
        if(PC_inp_sel_en == 1)
            pr_state = branch_state;
        else
            pr_state = nx_state;
    end
end

/*-------------------Next state logic----------------*/
always @ *
begin
    case (pr_state)
        idle:
        begin
            if ((code_mem_write_done == 0))
                nx_state = idle;
            else if (code_mem_read_done == 1)
                    nx_state = idle;
            else
                    nx_state = start_cipher_state;
        end
        start_cipher_state:
        begin
            nx_state = wait_state;
        end
        wait_state:
        begin
            if(code_mem_busy_decrypt)
                nx_state = wait_state;
            else
                nx_state = write_state;
        end
        write_state:
        begin
            nx_state = idle;
        end
        branch_state:
        begin
           nx_state = fifo_flush_wait;
        end
        fifo_flush_wait:
        begin
            if(code_side_fifo_wr_rst_busy == 0)
                nx_state = idle;
            else
                nx_state = fifo_flush_wait;
        end
        default:
        begin
            nx_state = idle;
        end
    endcase
end

/*---------------------output logic-----------------*/
always @ *
begin
code_mem_start_cipher_decrypt = 0;
PC_inp_sel = 0;              
PC_regload = 0;               
PC_regen = 1;                     
PC_addr_out = 1;                  
//PC_src_sel = 0;              
link_la = 1;                       
link_en = 1;                      
code_side_fifo_wr_en = 0;
code_addr_cnt_en = 0;
code_side_abort_blowfish = 0;
code_side_fifo_flush = 0;    
    case(pr_state)
    idle:
    begin
        PC_inp_sel = 2'b11;
    end
    start_cipher_state:
    begin
        PC_inp_sel = 2'b11;
        PC_regload = 1;
        code_mem_start_cipher_decrypt = 1;
    end
    wait_state:
    begin
        PC_inp_sel = 2'b11;
    end
    write_state:
    begin
        code_side_fifo_wr_en = 1;
        code_addr_cnt_en = 1;
    end
    branch_state:
    begin
        PC_inp_sel = 2'b00;
        code_side_fifo_flush = 1;
        PC_regload = 1;
        code_side_abort_blowfish = 1;
    end
    fifo_flush_wait:
    begin
        code_side_fifo_flush = 0;
        PC_inp_sel = 2'b00;
        code_side_abort_blowfish = 1;
    end
    default:
    begin
        code_mem_start_cipher_decrypt = 0;
        PC_inp_sel = 0;              
        PC_regload = 0;               
        PC_regen = 1;                     
        PC_addr_out = 1;                  
        //PC_src_sel = 0;              
        link_la = 1;                       
        link_en = 1;                      
        code_side_fifo_wr_en = 0;
        code_addr_cnt_en = 0;
        code_side_abort_blowfish = 0;
        code_side_fifo_flush = 0;
    end
    endcase
end
endmodule
