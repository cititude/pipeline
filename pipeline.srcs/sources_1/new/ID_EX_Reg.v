`timescale 1ns / 1ps


module ID_EX_Reg(
    input clk,
    input reset,
    input Flush,
    input [31:0] PC_plus_4_ID,
    input [3:0]ALUOp_ID,
    input [1:0]RegDst_ID,
    input MemWrite_ID,
    input MemRead_ID,
    input BranchEq_ID,
    input BranchNeq_ID,
    input BranchLez_ID,
    input BranchGtz_ID,
    input BranchLtz_ID,
    input [1:0] MemtoReg_ID,
    input RegWrite_ID,
    input [4:0] shamt_ID,
    input [5:0] Funct_ID,
    input  ALUSrc1_ID,
    input ALUSrc2_ID,
    input [31:0] LU_out_ID,
    input [31:0] Databus1_ID,Databus2_ID,
    input [4:0] Write_register_ID,
    input [1:0] PCSrc_ID,
    input [31:0] ALU_in2_ID,

    output reg [31:0] PC_plus_4_EX,
    output reg [3:0]ALUOp_EX,
    output reg [1:0]RegDst_EX,
    output reg MemWrite_EX,
    output reg MemRead_EX,
    output reg BranchEq_EX,
    output reg BranchNeq_EX,
    output reg BranchLez_EX,
    output reg BranchGtz_EX,
    output reg BranchLtz_EX,
    output reg [1:0] MemtoReg_EX,
    output reg RegWrite_EX,
    output reg [4:0] shamt_EX,
    output reg [5:0] Funct_EX,
    output reg ALUSrc1_EX,
    output reg ALUSrc2_EX,
    output reg [31:0] LU_out_EX,
    output reg [31:0] Databus1_EX, Databus2_EX,
    output reg [4:0] Write_register_EX,
    output reg [1:0] PCSrc_EX,
    output reg [31:0] ALU_in2_EX
    );

always @(posedge clk)begin
  if(~reset && ~Flush)begin
    PC_plus_4_EX<=PC_plus_4_ID;
    ALUOp_EX<=ALUOp_ID;
    RegDst_EX<=RegDst_ID;
    MemWrite_EX<=MemWrite_ID;
    MemRead_EX<=MemRead_ID;
    BranchEq_EX<=BranchEq_ID;
    BranchNeq_EX<=BranchNeq_ID;
    BranchLez_EX<=BranchLez_ID;
    BranchGtz_EX<=BranchGtz_ID;
    BranchLtz_EX<=BranchLtz_ID;
    MemtoReg_EX<=MemtoReg_ID;
    RegWrite_EX<=RegWrite_ID;
    shamt_EX<=shamt_ID;
    Funct_EX<=Funct_ID;
    ALUSrc1_EX<=ALUSrc1_ID;
    ALUSrc2_EX<=ALUSrc2_ID;
    LU_out_EX<=LU_out_ID;
    Databus1_EX<=Databus1_ID;
    Databus2_EX<=Databus2_ID;
    Write_register_EX<=Write_register_ID;
    PCSrc_EX<=PCSrc_ID;
    ALU_in2_EX<=ALU_in2_ID;
  end
  else begin
    PC_plus_4_EX<=0;
    ALUOp_EX<=0;
    RegDst_EX<=0;
    MemWrite_EX<=0;
    MemRead_EX<=0;
    BranchEq_EX<=0;
    BranchNeq_EX<=0;
    BranchLez_EX<=0;
    BranchGtz_EX<=0;
    BranchLtz_EX<=0;
    MemtoReg_EX<=0;
    RegWrite_EX<=0;
    shamt_EX<=0;
    Funct_EX<=0;
    ALUSrc1_EX<=0;
    ALUSrc2_EX<=0;
    LU_out_EX<=0;
    Databus1_EX<=0;
    Databus2_EX<=0;
    Write_register_EX<=0;
    PCSrc_EX<=0;
    ALU_in2_EX<=0;
  end
end
endmodule