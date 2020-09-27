`timescale 1ns / 1ps

module Control(OpCode, Funct,
	PCSrc, BranchEq,BranchNeq,BranchLez,BranchGtz,BranchLtz, 
	RegWrite, RegDst, MemRead, MemWrite, MemtoReg, 
	ALUSrc1, ALUSrc2, ExtOp, LuOp, ALUOp,Exception);
	input [5:0] OpCode;
	input [5:0] Funct;
	output [1:0] PCSrc;
	output BranchEq;
	output BranchNeq;
	output BranchLez;
	output BranchGtz;
	output BranchLtz;
	output RegWrite;
	output [1:0] RegDst;
	output MemRead;
	output MemWrite;
	output [1:0] MemtoReg;
	output ALUSrc1;
	output ALUSrc2;
	output ExtOp;
	output LuOp;
	output [3:0] ALUOp;
	output Exception;

	assign Exception=(~Branch && ~RegWrite && ~MemWrite && PCSrc!=2'd1 && PCSrc!=2'd2 && ~(Funct==0 && OpCode==0))?1:0;
	
	// Your code below
	assign BranchEq=(OpCode==6'h04)?1:0;
	assign BranchNeq=(OpCode==6'h05)?1:0;
	assign BranchLez=(OpCode==6'h06)?1:0;
	assign BranchGtz=(OpCode==6'h07)?1:0;
	assign BranchLtz=(OpCode==6'h01)?1:0;
	assign Branch=BranchEq || BranchNeq || BranchLez || BranchGtz || BranchLtz;
	assign PCSrc[1:0]=
		(OpCode==6'h02 || OpCode==6'h03)?2'b01:  // jump label
		(OpCode==0 && (Funct==6'h08 || Funct==6'h09) )?2'd2: // jump register
		Branch?2'd3:2'd0;                          // branch : pc_plus_4
	assign RegWrite=(OpCode==6'h23 || OpCode==6'h0f ||OpCode==6'h08 ||OpCode==6'h09 || OpCode==6'h0c || OpCode==6'h0a || OpCode==6'h0b || (OpCode==6'h00 && Funct!=6'h08 )||OpCode==6'h03|| OpCode==6'h0d)?1:0;
	assign RegDst=(OpCode==6'h03 )?2'b10: // jal
		OpCode==0?1:					// R-type (including jalr)
		0;								// I-type
	assign MemRead=(OpCode==6'h23 || OpCode==6'h0f)?1:0;
	assign MemWrite=(OpCode==6'h2b)?1:0;
	assign MemtoReg[1:0]=(OpCode==6'h03 || (OpCode==6'h00 && Funct==6'h09))?2'b10:   //write return address
		(OpCode==6'h23)?1														// write memory data
		:0;																		// write alu data
	assign ALUSrc1=(OpCode==0 && (Funct==0 || Funct==2 || Funct==3))?1:0;
	assign ALUSrc2=~(OpCode == 6'h00 || OpCode == 6'h04);
	assign ExtOp=(OpCode==6'h0b)?0:1;
	assign LuOp=(OpCode==6'h0f)?1:0;


	// Your code above
	assign ALUOp[2:0] = 
		(OpCode == 6'h00)? 3'b010: 
		(OpCode == 6'h04 || OpCode==6'h05 || OpCode==6'h06 || OpCode==6'h07 || OpCode ==6'h01)? 3'b001:   // loop 
		(OpCode == 6'h0c)? 3'b100: 
		(OpCode == 6'h0a || OpCode == 6'h0b)? 3'b101: 
		3'b000;
		
	assign ALUOp[3] = OpCode[0];
	
endmodule