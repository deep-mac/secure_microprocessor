`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2018 12:17:15 PM
// Design Name: 
// Module Name: data_mem_read_fsm
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


module data_mem_read_fsm(
clk, MRR_fifo_empty, reg_dest_fifo_rd_en, MRR_fifo_rd_en, data_mem_busy_decrypt, data_mem_start_cipher_decrypt, data_mem_initializing_decrypt,
data_mem_decrypt_done, reset 
    );

parameter data_size = 32;
    
input clk;
input reset;
input MRR_fifo_empty;
input reg_dest_fifo_rd_en;
output reg MRR_fifo_rd_en;
input data_mem_initializing_decrypt;
input data_mem_busy_decrypt;
output reg data_mem_start_cipher_decrypt;
output reg data_mem_decrypt_done;

parameter idle = 3'b000, fifo_read = 3'b001, decrypt = 3'b010, decrypt_wait = 3'b011, decrypt_done = 3'b100;

reg [2:0]pr_state, nx_state;

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
            if (data_mem_initializing_decrypt == 1)
                nx_state = idle;
            else
                if(MRR_fifo_empty == 0 )
                    nx_state = fifo_read;
                else
                    nx_state = idle;
        end
        fifo_read:
        begin
            nx_state = decrypt;
        end
        decrypt:
        begin
            nx_state = decrypt_wait;
        end
        decrypt_wait:
        begin
            if(data_mem_busy_decrypt == 0)
                nx_state = decrypt_done;
            else
                nx_state = decrypt_wait;
        end
        decrypt_done:
        begin
           if(reg_dest_fifo_rd_en == 1)
                nx_state = idle;
            else
                nx_state = decrypt_done; 
        end
        default: nx_state = idle;
     endcase
end

/*---------------------------------Output logic-----------------------*/
always @ *
begin
    MRR_fifo_rd_en = 0; 
    data_mem_start_cipher_decrypt = 0;
    data_mem_decrypt_done = 0; 
    case(pr_state)
        idle:
        begin
        //do nothing
        end
        fifo_read:
        begin
            MRR_fifo_rd_en = 1;
        end
        decrypt:
        begin
            data_mem_start_cipher_decrypt = 1;
        end
        decrypt_wait:
        begin
            //do nothing
        end
        decrypt_done:
        begin
           data_mem_decrypt_done = 1;
        end
        default:
        begin
            MRR_fifo_rd_en = 0; 
            data_mem_start_cipher_decrypt = 0;
            data_mem_decrypt_done = 0;    
        end
    endcase
end

endmodule
