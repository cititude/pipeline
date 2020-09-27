`timescale 1ns / 1ps


module SysTick(
    input reset,
    input clk,
    output reg[31:0] systick
    );

always @(posedge clk)begin
    if(reset)
        systick<=0;
    else begin
        systick<=systick+1;
    end
end
endmodule
