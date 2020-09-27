`timescale 1ns / 1ps

module Leds(
    input reset,
    input clk,
    input MemWrite,
    input [7:0]led_data,
    output reg[7:0] leds
    );

always @(posedge clk)begin
    if(reset)
        leds<=0;
    else begin
        leds<=led_data;
    end
end
endmodule
