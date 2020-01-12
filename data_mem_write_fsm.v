`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2018 11:33:52 AM
// Design Name: 
// Module Name: data_mem_write_fsm
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


module data_mem_write_fsm(
clk, MWR_fifo_empty, MWR_fifo_rd_en, data_mem_initializing_encrypt, data_mem_busy_encrypt, 
data_mem_start_cipher_encrypt,data_mem_initializing_decrypt,
MWR_addr_fifo_rd_en, data_mem_write, reset
    );
    
parameter data_size = 32;

input clk;
input reset;
input MWR_fifo_empty;
output reg MWR_fifo_rd_en;
input data_mem_initializing_encrypt;
input data_mem_initializing_decrypt;
input data_mem_busy_encrypt;
output reg data_mem_start_cipher_encrypt;
//output reg data_mem_encrypt_done;
output reg MWR_addr_fifo_rd_en;
output reg data_mem_write;

parameter idle = 3'b000, fifo_read = 3'b001, encrypt = 3'b010, encrypt_wait = 3'b011, encrypt_over = 3'b100,
          fifo_addr_read = 3'b101;

reg [2:0]pr_state, nx_state;
wire encrypt_done;

assign encrypt_done = ~data_mem_busy_encrypt;

/*---------------------------------State machine----------------------*/


/*---------------------------------Sequential logic-------------------*/

always @ (posedge(clk))
begin 
    if ((reset))
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
            if ((data_mem_initializing_encrypt == 1) || (data_mem_initializing_decrypt == 1))
                nx_state = idle;
            else
                if(MWR_fifo_empty == 0)
                    nx_state = fifo_read;
                else
                    nx_state = idle;
        end
        fifo_read:
        begin
            nx_state = encrypt;
        end
        encrypt:
        begin
            nx_state = encrypt_wait;
        end
        encrypt_wait:
        begin
            if(encrypt_done == 1)
                nx_state = encrypt_over;
            else
                nx_state = encrypt_wait;
        end
        encrypt_over:
        begin
           if(MWR_fifo_empty == 0)
                nx_state = fifo_read;
            else
                nx_state = idle; 
        end
        default: nx_state = idle;
     endcase
end

/*---------------------------------Output logic-----------------------*/
always @ *
begin
    MWR_fifo_rd_en = 0; 
    MWR_addr_fifo_rd_en = 0; 
    data_mem_start_cipher_encrypt = 0; 
    //data_mem_encrypt_done = 0;
    data_mem_write = 0;
    case(pr_state)
        idle:
        begin
        //do nothing
        end
        fifo_read:
        begin
            MWR_fifo_rd_en = 1;
        end
        encrypt:
        begin
            data_mem_start_cipher_encrypt = 1;
        end
        encrypt_wait:
        begin
            //do nothing
        end
        encrypt_over:
        begin
            MWR_addr_fifo_rd_en = 1;      
            //data_mem_encrypt_done = 1;
            data_mem_write = 1;
        end
        default:
        begin
            MWR_addr_fifo_rd_en = 0;      
            MWR_fifo_rd_en = 0; 
            data_mem_start_cipher_encrypt = 0; 
            //data_mem_encrypt_done = 0;
            data_mem_write = 0;   
        end
    endcase
end

endmodule
