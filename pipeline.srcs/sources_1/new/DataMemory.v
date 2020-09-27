`timescale  1ns / 1ps

module DataMemory
	#(parameter RAM_SIZE=150)
	(
		input reset, clk,
		input [31:0] Address, Write_data,
		input MemWrite,
		input BeginSort,EndSort,
		input [31:0] dump_addr,
		output [31:0] dump_data,
		output [31:0] Read_data,
		output IRQ,
		output [7:0] leds,
		output [7:0] ssd
	);
	assign dump_data=RAM_data[dump_addr[RAM_SIZE_BIT+1:2]];
	parameter RAM_SIZE_BIT = 8;
	
	reg [31:0] RAM_data[RAM_SIZE - 1: 0];
	wire [31:0] systick;
	SysTick u_SysTick(.reset(reset|BeginSort),.clk(clk),.systick(systick));

	Leds u_Leds(.reset(reset),.clk(clk),.MemWrite(EndSort),.led_data(8'hff),.leds(leds));
	SSD u_SSD(.reset(reset),.clk(clk),.MemWrite(MemWrite&&Address==32'h40000010),.ssd_data(Write_data),.ssd(ssd));
	wire [31:0] timer_data;
	wire timer_memwrite;
	assign timer_memwrite=MemWrite && (Address>=32'h40000000 && Address <=32'h40000008);
	Timer u_Timer(.reset(reset),.clk(clk),.MemWrite(timer_memwrite|BeginSort),.Write_data(Write_data),.addr(Address[3:2]),.read_data(timer_data),.IRQ(IRQ));
	assign Read_data=	(Address==32'h40000014)?systick:
						 (Address==32'h4000000C)?leds:
						 (Address>=32'h40000000 && Address <=32'h40000008)?timer_data:
						 RAM_data[Address[RAM_SIZE_BIT + 1:2]];
	integer i;
	always @(posedge clk)begin
		if (MemWrite && ~Address[30])
			RAM_data[Address[RAM_SIZE_BIT + 1:2]] <= Write_data;
	end
endmodule
