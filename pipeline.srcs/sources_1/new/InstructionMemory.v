`timescale 1ns / 1ps

module InstructionMemory 
	#(parameter Instruction_MEMSIZE=128) 
	(
		input clk,reset,
		input [31:0] Address,
		input MemWrite,
		input [31:0] Write_data,
		output [31:0] Instruction
	);

	reg [31:0] InstructionData[Instruction_MEMSIZE-1:0];
	assign Instruction=InstructionData[Address[9:2]];
	integer i;
	always @(posedge clk)begin
	if(MemWrite)begin
		InstructionData[Address[9:2]]<=Write_data;
	  end
	end

		
endmodule
