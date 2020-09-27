`timescale 1ns / 1ps


module EX_MEM_Reg(
    input [31:0] PC_plus_4_EX,
    input clk,
    input reset,
    input [1:0]RegDst_EX,
    input MemWrite_EX,
    input MemRead_EX,
    input [1:0] MemtoReg_EX,
    input RegWrite_EX,
    input [31:0] ALU_out_EX,
    input [31:0] Databus2_EX,
    input [4:0] Write_register_EX,

    output reg[31:0] PC_plus_4_MEM,
    output reg [1:0]RegDst_MEM,
    output reg MemWrite_MEM,
    output reg MemRead_MEM,
    output reg [1:0] MemtoReg_MEM,
    output reg RegWrite_MEM,
    output reg [31:0] ALU_out_MEM,
    output reg [31:0] Databus2_MEM,
    output reg [4:0] Write_register_MEM
    );

always @(posedge clk)begin
  if(~reset)begin
    PC_plus_4_MEM<=PC_plus_4_EX;
    RegDst_MEM<=RegDst_EX;
    MemWrite_MEM<=MemWrite_EX;
    MemRead_MEM<=MemRead_EX;
    MemtoReg_MEM<=MemtoReg_EX;
    RegWrite_MEM<=RegWrite_EX;
    ALU_out_MEM<=ALU_out_EX;
    Databus2_MEM<=Databus2_EX;
    Write_register_MEM<=Write_register_EX;

  end
  else begin
    PC_plus_4_MEM<=0;
    RegDst_MEM<=0;
    MemWrite_MEM<=0;
    MemRead_MEM<=0;
    MemtoReg_MEM<=0;
    RegWrite_MEM<=0;
    ALU_out_MEM<=0;
    Databus2_MEM<=0;
    Write_register_MEM<=0;
  end  
end
endmodule
