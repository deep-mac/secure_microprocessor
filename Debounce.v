`timescale 1ns / 1ps
module Debounce(clock, btn, sig);
output	sig;
input	btn;
input	clock; 

reg	[11:0]	cnt;
reg	[2:0]	rBtn;
reg 		sig=1;

always @(posedge clock) begin
	rBtn<={rBtn[1:0],btn};
	
	if(sig==rBtn[2]) cnt<=0;
	else  cnt <= cnt + 1'b1;	
	
	if(&cnt) sig <= rBtn[2];  // If the counter is maxed out, push button changed!
end
endmodule 