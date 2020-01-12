`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:39:59 05/18/2017 
// Design Name: 
// Module Name:    controller 
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
module controller( 
    //inputs
    input clk,
    input reset,
    input code_side_fifo_empty,
    input [5:0]op_bits,
    input data_mem_decrypt_done,
    input code_side_fifo_rd_rst_busy,
    input [5:0]func_from_ir,
    input [2:0]PSR,
    //input code_side_fifo_flush,
    
    //outputs
    output reg code_side_fifo_rd_en,
    output reg ir_enable,
    output reg ir_latch,
    output reg register_write,
    output reg alu_src_latch_1,
    output reg alu_src_latch_2,
    output reg ALU_out_l,
    output reg ALU_src_2_sel,
    output reg [1:0]reg_inp_src_sel, 
    output reg MWR_fifo_wr_en,
    output reg MWR_addr_fifo_wr_en,
    output reg MRR_fifo_wr_en,
    output reg reg_dest_fifo_wr_en,
    output reg reg_write_sel_mux_sel,
    output reg reg_dest_fifo_rd_en,
    output reg PC_inp_sel_en,
    output reg [1:0] PC_src_sel,
    output reg [5:0] func
);

wire data_blowfish_busy;

parameter idle = 4'b0000, code_fifo_read = 4'b0001, IR_state = 4'b0010, register_state = 4'b0011, ALU_state = 4'b0100, 
write_state = 4'b0101, decryption_write_state = 4'b0110, branch_wait_state = 4'b0111, dummy_state = 4'b1000;
reg [3:0]pr_state, nx_state;

always @ *
begin
    if (op_bits[5:4] == 2'b01)
    begin
        ALU_src_2_sel = 1;       
    end
    else
        ALU_src_2_sel = 0;
        
    if(op_bits[5:4] == 2'b01 && (op_bits[3:0] == 4'b1100 || op_bits == 4'b1101))
    begin
        reg_inp_src_sel = 0;
    end
    else 
        if (op_bits[5:4] == 2'b00 && op_bits[3:0] == 4'b1100)
        begin
            reg_inp_src_sel = 1;
        end
        else 
            if (pr_state == 4'b0110)
            begin
                reg_inp_src_sel = 3;
            end
            else
            begin
                reg_inp_src_sel = 2;
            end  
            
    if(op_bits[5:4] == 2'b00)
        func = func_from_ir;
    else
        func = 6'b000000;
    
end

/*-------------------------------Sequential logic--------------------*/
always @ (posedge(clk))
begin
    if (reset == 1)
        pr_state = idle;
    else
        pr_state = nx_state;
end
 
 /*-----------------------next state logic------------------------*/
 
 always @ *
 begin
    case (pr_state)
        idle:
        begin
            if (data_mem_decrypt_done)
                nx_state = decryption_write_state;
            else
                if (code_side_fifo_empty == 0)
                    nx_state = IR_state;
                else
                    nx_state = idle;
        end
        IR_state:
        begin
            nx_state = register_state;
        end
        register_state:
        begin
            nx_state = ALU_state;
        end
        ALU_state:
        begin
            nx_state = dummy_state;
        end
        dummy_state:
        begin
            nx_state = write_state;
        end
        write_state:
        begin
            if (op_bits[5:4] == 2'b10 || (op_bits[5:0] == 6'b110001 && PSR[1] == 1) || (op_bits[5:0] == 6'b111010 && PSR[1] == 0))
                if(code_side_fifo_rd_rst_busy == 1)
                    nx_state = branch_wait_state;
                else
                    nx_state = write_state;
            else
                nx_state = idle;
        end
        branch_wait_state:
        begin
            if(code_side_fifo_rd_rst_busy == 0)
                nx_state = idle;
            else
                nx_state = branch_wait_state;
        end
        decryption_write_state:
        begin
            nx_state = idle;
        end
        default:
        begin
            nx_state = idle;
        end
    endcase
 end

/*---------------------output logic--------------------*/

always @ *
begin
ir_enable = 1;
ir_latch = 0;
register_write = 0;
alu_src_latch_1 = 0;
alu_src_latch_2 = 0;
ALU_out_l = 0;
MWR_fifo_wr_en = 0;
MWR_addr_fifo_wr_en = 0;
MRR_fifo_wr_en = 0;
code_side_fifo_rd_en = 0;
reg_dest_fifo_wr_en = 0;
reg_write_sel_mux_sel = 0;
reg_dest_fifo_rd_en = 0;
PC_inp_sel_en = 0;
PC_src_sel = 2'b00;
    case (pr_state)
    idle: 
    begin
        
    end
    IR_state:
    begin
        code_side_fifo_rd_en = 1;
        ir_latch = 1;
    end
    register_state:
    begin
        alu_src_latch_1 = 1;
        alu_src_latch_2 = 1;        
    end
    ALU_state:
    begin
        ALU_out_l = 1;    
    end
    write_state:
    begin
        if (op_bits[5:4] == 2'b01)
            if (op_bits[3:0] == 4'b1111)
            begin
                MWR_fifo_wr_en = 1;
                MWR_addr_fifo_wr_en = 1;
                register_write = 0;
                MRR_fifo_wr_en = 0;
                reg_dest_fifo_wr_en = 0;               
            end
            else
                if (op_bits[3:0] == 4'b1110)
                begin
                    MWR_fifo_wr_en = 0;
                    MWR_addr_fifo_wr_en = 0;
                    MRR_fifo_wr_en = 1;
                    reg_dest_fifo_wr_en = 1;
                    register_write = 0;
                end
                else
                    begin
                        register_write = 1;
                    end
        else
        begin
            if(op_bits[5:4] == 2'b10)
            begin
                PC_inp_sel_en = 1;
                PC_src_sel = 2'b01;    
            end
            else
            begin
                if(op_bits[5:4] == 2'b11)
                begin
                    if(op_bits[3:0] == 4'b0001 && PSR[1] == 1)
                    begin
                        PC_inp_sel_en = 1;
                        PC_src_sel = 2'b10;
                    end
                    else
                    begin
                        if(op_bits[3:0] == 4'b1010 && PSR[1] == 0)
                        begin
                            PC_inp_sel_en = 1;
                            PC_src_sel = 2'b10;
                        end
                        else
                        begin
                            PC_inp_sel_en = 0;
                            PC_src_sel = 2'b00;
                        end
                    end
                end
                else
                begin
                    MWR_fifo_wr_en = 0;
                    MWR_addr_fifo_wr_en = 0;
                    register_write = 1;
                    MRR_fifo_wr_en = 0;
                    reg_dest_fifo_wr_en = 0;
                    PC_inp_sel_en = 0;
                    PC_src_sel = 2'b00;
                end
            end
        end
    end
    decryption_write_state:
    begin
        register_write = 1;
        reg_write_sel_mux_sel = 1;
        reg_dest_fifo_rd_en = 1;
    end
    branch_wait_state:
    begin
        PC_src_sel = 2'b01;
        PC_inp_sel_en = 0;
    end
    default:
    begin
        ir_enable = 1;
        ir_latch = 0;
        register_write = 0;
        alu_src_latch_1 = 0;
        alu_src_latch_2 = 0;
        ALU_out_l = 0;
        MWR_fifo_wr_en = 0;
        MWR_addr_fifo_wr_en = 0;
        MRR_fifo_wr_en = 0;
        code_side_fifo_rd_en = 0;
        reg_write_sel_mux_sel = 0;
        reg_dest_fifo_rd_en = 0;
        reg_dest_fifo_wr_en = 0;
        PC_inp_sel_en = 0;
        PC_src_sel = 2'b00;
    end
    endcase
end

endmodule


