`timescale 1ns / 1ps


module IF_ID_Reg(
    input clk,
    input reset,
    input [31:0] instruction_IF,
    input Flush,
    output reg [31:0] instruction_ID,
    input [31:0]PC_plus_4_IF,
    output reg [31:0] PC_plus_4_ID
    );

always @(posedge clk)begin
  if(~reset)begin
    if(Flush)begin
      instruction_ID<=32'h00000000;
    end
    else begin
      instruction_ID<=instruction_IF;
      PC_plus_4_ID<=PC_plus_4_IF;
    end
  end
  else begin
    instruction_ID<=32'h0;
    PC_plus_4_ID<=32'h0;
  end
end
endmodule
