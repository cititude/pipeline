`timescale 1ns / 1ps


module MEM_WB_Reg(
    input clk,
    input reset,
    input RegWrite_MEM,
    input [4:0] Write_register_MEM,

    output reg RegWrite_WB,
    output reg [4:0] Write_register_WB
    );

always @(posedge clk)begin
  if(~reset)begin
    RegWrite_WB<=RegWrite_MEM;
    Write_register_WB<=Write_register_MEM;
  end
  else begin
    RegWrite_WB<=0;
    Write_register_WB<=0;
  end  
end
endmodule
