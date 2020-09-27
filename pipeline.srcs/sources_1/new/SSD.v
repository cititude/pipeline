`timescale 1ns / 1ps

module SSD(
    input clk,
    input reset,
    input MemWrite,
    input [7:0] ssd_data,
    output reg [7:0] ssd
    );

always @ (posedge clk)
  begin
    if (reset)
      ssd <= 0;
    else
      if (MemWrite)
        ssd <= ssd_data;
  end
  
endmodule
