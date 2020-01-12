`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.03.2018 16:00:16
// Design Name: 
// Module Name: code_burn
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


module code_burner(
clk, ext_code_addr_lines, ext_code_encrypt_din, ext_code_mem_write, code_mem_write_done, start_cipher, cipher_busy,
encrypt_initializing, reset
                );
   
parameter data_size = 32;
parameter code_size = 6;
input clk;
input reset;
output reg start_cipher;    
output reg [12:0]ext_code_addr_lines;
output wire [(2*data_size)-1:0]ext_code_encrypt_din;
output reg ext_code_mem_write;
output wire code_mem_write_done;
input cipher_busy;
input encrypt_initializing;

parameter idle = 2'b00, encrypt = 2'b01, mem_write = 2'b10, encrypt_wait = 2'b11;

reg [data_size-1:0] ext_code_mem [code_size-1:0];
(*keep = "true"*)reg [13:0] count;
reg code_write_done;
//wire code_mem_write_done;
reg [1:0] pr_state, nx_state;
reg count_en;
wire cipher_done;

initial
begin
    ext_code_addr_lines = 0;
    code_write_done = 0;
    ext_code_mem_write = 0;
    start_cipher = 0;
    count = 0;
    count_en = 0;
    pr_state = idle;
    $readmemb("code.mem",ext_code_mem);
//    ext_code_mem[0] = 32'h80000004; //01110000001 00000 00000 00011111010
//    ext_code_mem[1] = 32'h70200523; //0111 1100 0010 0000 0000 0000 0000 0000
//    ext_code_mem[2] = 32'h70200123;
//    ext_code_mem[3] = 32'h70200223;
//    ext_code_mem[4] = 32'h70200323;
//    ext_code_mem[5] = 32'h70200423;    
//    ext_code_mem[2] = 32'h23456789;
//    ext_code_mem[3] = 32'habcdef12;
//    ext_code_mem[4] = 32'h3456789a;
//    ext_code_mem[5] = 32'hbcdef123;
end

assign code_mem_write_done = code_write_done;
assign ext_code_encrypt_din = {ext_code_mem[count], ext_code_mem[count+1]};
assign cipher_done = ~cipher_busy;

always @ *
begin
    if(count == code_size)
        code_write_done = 1;
    else
        code_write_done = 0;
end

always @ (posedge(clk))
begin
    if (count_en == 1)
    begin
        count = count + 2;
    end
end

/*---------------------------------State machine----------------------*/


/*---------------------------------Sequential logic-------------------*/

always @ (posedge(clk))
begin 
    if (reset)
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
            if(code_write_done == 1 || (encrypt_initializing == 1))
                nx_state = idle;
            else
                nx_state = encrypt;
        end
        encrypt:
        begin
            nx_state = encrypt_wait;
        end
        encrypt_wait:
        begin
            if(cipher_done == 1)
                nx_state = mem_write;
            else
                nx_state = encrypt_wait;
        end
        mem_write:
        begin
           nx_state = idle; 
        end
        default: nx_state = idle;
     endcase
end

/*---------------------------------Output logic-----------------------*/
always @ *
begin
    start_cipher = 0;
    //ext_code_encrypt_din = 0;
    count_en = 0;
    ext_code_mem_write = 0;
    ext_code_addr_lines = 0;
    case(pr_state)
        idle:
        begin
        //do nothing
        end
        encrypt:
        begin
            start_cipher = 1;
        end
        encrypt_wait:
        begin
            //do nothing
        end
        mem_write:
        begin
            ext_code_addr_lines = count/2;
            count_en = 1;
            ext_code_mem_write = 1;
        end
        default:
        begin
            start_cipher = 0;
            count_en = 0;
            ext_code_mem_write = 0;
            ext_code_addr_lines = 0;
            //code_write_done = 1;    
        end
    endcase
end
endmodule
