`timescale 1ns / 1ps

module CPU(reset, clk,Rx_Serial,uart_on,uart_mode,leds,ssd,Tx_Serial);
	input reset, clk;
	input Rx_Serial;
	input uart_on;
	input [1:0]uart_mode; // 0: read instruction; 1: read data; 2:send_data; 
	output wire [7:0] leds;
	output wire [7:0]ssd;
	output wire Tx_Serial;

	wire Exception;
	wire IRQ;
	wire ProgramRunning;
	assign ProgramRunning=~uart_on && uart_mode==2'b11;

	// sort beginning and endding signal
	reg BeginSort,EndSort;
	reg BeginSortAlready=0,EndSortAlready=0;
	always @(posedge clk)begin
		if(ProgramRunning)begin
			if(~BeginSortAlready & ~BeginSort)begin
				BeginSort<=1;
				BeginSortAlready<=1;
			end
			else BeginSort<=0;
		end
		else BeginSort<=0;
	end

	always @(posedge clk)begin
		if(PC==32'h0000006c &&~EndSortAlready)begin
			EndSort<=1;
			EndSortAlready<=1;
		end
		else EndSort<=0;
	end

    // instruction memory uart
    reg [31:0] addr0;
    reg rd_en0;
    reg wr_en0;
    wire [31:0] rdata0;
    reg [31:0] wdata0;

    // data memory uart
    reg [31:0] addr1;
    reg rd_en1;
    reg wr_en1;
    wire [31:0] rdata1;
    reg [31:0] wdata1;


	reg [31:0] PC;
	wire [31:0] PC_next;
	wire stall;
	assign stall=((Instruction[25:21]==Write_register || Instruction[20:16]==Write_register) && MemRead )?1:0;
	always @(posedge clk)
		if (reset)
			PC <= 32'h80000000;
		else if(!(uart_on==0 && uart_mode==2'b11))
			PC<=32'h80000000;
		else if(~stall)
			PC <= PC_next;
	
	wire [31:0] PC_plus_4;
	assign PC_plus_4 =(PC==32'h80000000)?32'h00000004:{PC[31],PC[30:0] + 31'd4};
	
	wire [31:0] Instruction;

	parameter Instruction_MEMSIZE=150;

	// stage IF:

	InstructionMemory #(.Instruction_MEMSIZE(Instruction_MEMSIZE)) instruction_memory1 (.clk(clk),.reset(reset && uart_on),.MemWrite(uart_on && uart_mode==0 && wr_en0),.Write_data(wdata0),.Address((uart_on && uart_mode==0)?addr0:PC), .Instruction(Instruction));

	wire [31:0] instruction_ID;
	wire [31:0] PC_plus_4_ID;
	wire Flush_IF_ID;
	assign Flush_IF_ID=Branch || Jump || Exception;
	
	IF_ID_Reg IF_ID_Reg_inst(.clk(clk),.reset(reset|~ProgramRunning),.Flush(Flush_IF_ID),.instruction_IF(Instruction),.PC_plus_4_IF(PC_plus_4),.instruction_ID(instruction_ID),.PC_plus_4_ID(PC_plus_4_ID));
	
	// control signals
	wire [1:0] RegDst;
	wire [1:0] PCSrc;
	wire BranchEq;
	wire BranchNeq;
	wire BranchLez;
	wire BranchGtz;
	wire BranchLtz;


	wire MemRead;
	wire [1:0] MemtoReg;
	wire [3:0] ALUOp;
	wire ExtOp;
	wire LuOp;
	wire MemWrite;
	wire ALUSrc1;
	wire ALUSrc2;
	wire RegWrite;
	
	// forward
	wire Forward_ALU_to_Databus1,Forward_ALU_to_Databus2;
	wire Forward_MEM_to_Databus1,Forward_MEM_to_Databus2;
	assign Forward_ALU_to_Databus1=(Write_register_EX==instruction_ID[25:21] && Write_register_EX!=0 && RegWrite_EX)?1:0;
	assign Forward_ALU_to_Databus2=(Write_register_EX==instruction_ID[20:16] && Write_register_EX!=0 && RegWrite_EX)?1:0;
	assign Forward_MEM_to_Databus1=(Write_register_MEM==instruction_ID[25:21] && Write_register_MEM!=0 && RegWrite_MEM)?1:0;
	assign Forward_MEM_to_Databus2=(Write_register_MEM==instruction_ID[20:16] && Write_register_MEM!=0 && RegWrite_MEM)?1:0;

	// stage ID
	wire Exception_ID;
	Control control1(
		.OpCode(instruction_ID[31:26]), .Funct(instruction_ID[5:0]),.PCSrc(PCSrc), 
		.BranchEq(BranchEq), .BranchNeq(BranchNeq),.BranchGtz(BranchGtz),.BranchLez(BranchLez),.BranchLtz(BranchLtz),
		.RegWrite(RegWrite), .RegDst(RegDst), 
		.MemRead(MemRead),	.MemWrite(MemWrite), .MemtoReg(MemtoReg),
		.ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .ExtOp(ExtOp), .LuOp(LuOp),	.ALUOp(ALUOp),.Exception(Exception_ID));

	assign Exception=Exception_ID && ~PC[31];

	wire [31:0] Databus1, Databus2, Databus3;
	wire [31:0] Databus1_reg,Databus2_reg,Databus3_reg;
	wire [4:0] Write_register;

	wire [7:0]a0;
	wire [7:0]v0;
	wire [7:0]sp;
	wire [7:0]ra;
	assign Write_register = (RegDst == 2'b00)? instruction_ID[20:16]: (RegDst == 2'b01)? instruction_ID[15:11]: 5'b11111;
	//wire [4:0] Write_register_WB;
	wire [4:0] Write_register_MEM;
	wire RegWrite_MEM;
	RegisterFile register_file1(.reset(reset), .clk(clk), .RegWrite((Exception|IRQ)?1'b1:RegWrite_MEM), 
		.Read_register1(instruction_ID[25:21]), .Read_register2(instruction_ID[20:16]), .Write_register((Exception|IRQ)?5'd26:Write_register_MEM),
		.Write_data((Exception|IRQ)?PC_next:Databus3), .Read_data1(Databus1_reg), .Read_data2(Databus2_reg),.a0(a0),.v0(v0),.ra(ra),.sp(sp));

	assign Databus1=Forward_ALU_to_Databus1?ALU_out:Forward_MEM_to_Databus1?Databus3:Databus1_reg;
	assign Databus2=Forward_ALU_to_Databus2?ALU_out:Forward_MEM_to_Databus2?Databus3:Databus2_reg;

	wire [31:0] Ext_out;
	assign Ext_out = {ExtOp? {16{instruction_ID[15]}}: 16'h0000, instruction_ID[15:0]};
	
	wire [31:0] LU_out;
	assign LU_out = LuOp? {instruction_ID[15:0], 16'h0000}: Ext_out;
	wire [31:0] ALU_in2_ID;
	assign ALU_in2_ID = ALUSrc2? LU_out: Databus2;
	wire [31:0] PC_plus_4_EX;
	wire [3:0] ALUOp_EX;
	wire [1:0]RegDst_EX;
	wire MemWrite_EX;
	wire MemRead_EX;
	wire BranchEq_EX;
	wire BranchNeq_EX;
	wire BranchLez_EX;
	wire BranchGtz_EX;
	wire BranchLtz_EX;
	wire [1:0] MemtoReg_EX;
	wire RegWrite_EX;
	wire [4:0] shamt_EX;
	wire [5:0] Funct_EX;
	wire ALUSrc1_EX;
	wire ALUSrc2_EX;
	wire [31:0] LU_out_EX;
	wire [31:0] Databus1_EX,Databus2_EX;
	wire [4:0] Write_register_EX;
	wire [1:0] PCSrc_EX;

	wire Flush_ID_EX;
	wire Jump;
	assign Jump=(PCSrc==2'b01)?1:0;
	assign Flush_ID_EX=Branch;
	wire [31:0] ALU_in2;
	ID_EX_Reg ID_EX_Reg_inst(
            .clk(clk), .reset(reset|~ProgramRunning), .Flush(Flush_ID_EX),.PC_plus_4_ID(PC_plus_4_ID),
			.ALUOp_ID(ALUOp),.RegDst_ID(RegDst),.MemWrite_ID(MemWrite),.MemRead_ID(MemRead),
			.BranchEq_ID(BranchEq), .BranchNeq_ID(BranchNeq), .BranchLez_ID(BranchLez), .BranchGtz_ID(BranchGtz), .BranchLtz_ID(BranchLtz), 
			.MemtoReg_ID(MemtoReg),.RegWrite_ID(RegWrite),.shamt_ID(instruction_ID[10:6]),.Funct_ID(instruction_ID[5:0]),
			.ALUSrc1_ID(ALUSrc1),.ALUSrc2_ID(ALUSrc2),.LU_out_ID(LU_out),
			.Databus1_ID(Databus1),.Databus2_ID(Databus2),
			.Write_register_ID(Write_register),
			.PCSrc_ID(PCSrc),.ALU_in2_ID(ALU_in2_ID),

			.PC_plus_4_EX(PC_plus_4_EX),.ALUOp_EX(ALUOp_EX),.RegDst_EX(RegDst_EX),.MemWrite_EX(MemWrite_EX),.MemRead_EX(MemRead_EX),
			.BranchEq_EX(BranchEq_EX), .BranchNeq_EX(BranchNeq_EX), .BranchLez_EX(BranchLez_EX), .BranchGtz_EX(BranchGtz_EX), .BranchLtz_EX(BranchLtz_EX),
			.MemtoReg_EX(MemtoReg_EX),.RegWrite_EX(RegWrite_EX) ,.shamt_EX(shamt_EX),.Funct_EX(Funct_EX),
			.ALUSrc1_EX(ALUSrc1_EX),.ALUSrc2_EX(ALUSrc2_EX),.LU_out_EX(LU_out_EX),
			.Databus1_EX(Databus1_EX),.Databus2_EX(Databus2_EX),
			.Write_register_EX(Write_register_EX),
			.PCSrc_EX(PCSrc_EX),.ALU_in2_EX(ALU_in2)
        );

	// stage: EX	
	wire [4:0] ALUCtl;
	wire Sign;
	ALUControl alu_control1(.ALUOp(ALUOp_EX), .Funct(Funct_EX), .ALUCtl(ALUCtl), .Sign(Sign));
	
	wire [31:0] ALU_in1;
	wire [31:0] ALU_out;
	wire Zero;
	wire [31:0]sub_out;
	wire Negative;
	assign ALU_in1 = ALUSrc1_EX? {27'h00000, shamt_EX}: Databus1_EX;
	ALU alu1(.in1(ALU_in1), .in2(ALU_in2), .ALUCtl(ALUCtl), .Sign(Sign), .out(ALU_out));
	assign Zero=(ALU_in1==ALU_in2)?1:0;
	assign sub_out=ALU_in1-ALU_in2;
	assign Negative=sub_out[31];
	wire [31:0] PC_plus_4_MEM;
	wire [1:0] RegDst_MEM;
    wire MemWrite_MEM;
	wire MemRead_MEM;
    wire [1:0] MemtoReg_MEM;
    wire [31:0] ALU_out_MEM;
	wire [31:0] Databus2_MEM;

	EX_MEM_Reg EX_MEM_Reg_inst(
            .clk(clk), .reset(reset|~ProgramRunning), .PC_plus_4_EX(PC_plus_4_EX),.RegDst_EX(RegDst_EX),.MemWrite_EX(MemWrite_EX),.MemRead_EX(MemRead_EX),
			.MemtoReg_EX(MemtoReg_EX),.RegWrite_EX(RegWrite_EX),.ALU_out_EX(ALU_out),.Databus2_EX(Databus2_EX),
			.Write_register_EX(Write_register_EX),

			.PC_plus_4_MEM(PC_plus_4_MEM),.RegDst_MEM(RegDst_MEM),.MemWrite_MEM(MemWrite_MEM),.MemRead_MEM(MemRead_MEM),
			.MemtoReg_MEM(MemtoReg_MEM),.RegWrite_MEM(RegWrite_MEM),.ALU_out_MEM(ALU_out_MEM),.Databus2_MEM(Databus2_MEM),
			.Write_register_MEM(Write_register_MEM)
          );

	// stage : MEM
	wire [31:0] Read_data;
	parameter Data_MEMSIZE=150;
	wire [31:0] DataMemory_address;
	wire [31:0] DataMemory_write_data;
	assign DataMemory_address=(uart_on && uart_mode==1)?addr1:ALU_out_MEM;
	assign DataMemory_write_data=(uart_on && uart_mode==1)?wdata1:Databus2_MEM;
	assign DataMemory_MemWrite=(uart_on && uart_mode==1)?wr_en1:MemWrite_MEM;

	wire dump_en;
	reg [31:0] dump_addr;
	wire [31:0] dump_data;
	wire IRQ_reg;
	DataMemory #(.RAM_SIZE(Data_MEMSIZE)) 
		data_memory1(.reset(reset&& uart_on), .clk(clk), .Address(DataMemory_address), 
					.Write_data(DataMemory_write_data), .Read_data(Read_data), 
					.MemWrite(DataMemory_MemWrite),.IRQ(IRQ_reg),.leds(leds),.ssd(ssd),
					.BeginSort(BeginSort),.EndSort(EndSort),
					.dump_addr(dump_addr),.dump_data(dump_data));
	assign IRQ=IRQ_reg&&~PC_plus_4_ID[31];
	assign Databus3 = (MemtoReg_MEM == 2'b00)? ALU_out_MEM: (MemtoReg_MEM == 2'b01)? Read_data: PC_plus_4_MEM;
	


	// MEM_WB_Reg MEM_WB_Reg_inst(
    //         .clk(clk), .reset(reset|~ProgramRunning),
	// 		.RegWrite_MEM(RegWrite_MEM),
	// 		.Write_register_MEM(Write_register_MEM),

	// 		.RegWrite_WB(RegWrite_WB),
	// 		.Write_register_WB(Write_register_WB)
    //       );
	

	// PCsrc

	wire [31:0] Jump_target;
	assign Jump_target = {PC_plus_4_ID[31:28], instruction_ID[25:0], 2'b00};
	
	wire [31:0] Branch_target;

	assign Branch=(BranchEq_EX & Zero) || (BranchNeq_EX & !Zero) || (BranchLez_EX & (Zero || Negative)) || (BranchGtz_EX & !Negative & !Zero) || (BranchLtz_EX & Negative);
	assign Branch_target = Branch? PC_plus_4_EX + {LU_out_EX[29:0], 2'b00}:PC_plus_4_EX;

	assign PC_next = ~BeginSortAlready?32'h80000000:
		IRQ ? 32'h80000004:
		Exception ?32'h80000008:
		(PCSrc_EX == 2'b11&&Branch)? Branch_target:  // branch at EX stage
		(PCSrc == 2'b01)? Jump_target: 
		(PCSrc==2'b10)?Databus1:		// jump register
		PC_plus_4;

	parameter CLKS_PER_BIT=16'd5;
	wire Rx_DV;
	wire [7:0] Rx_Byte;
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_rx_inst
		(.i_Clock(clk),
			.i_Rx_Serial(Rx_Serial),
			.o_Rx_DV(Rx_DV),
			.o_Rx_Byte(Rx_Byte)
			);

	assign dump_en=uart_on & uart_mode[1];
	reg Tx_DV;
	wire Tx_Done;
	reg Tx_Done_first;
	wire Tx_Active;
	reg [7:0] data_to_dump;
	reg [1:0] dump_byte_cnt;
	reg dump_ready;
	always @(posedge clk)begin
		if(~dump_en)begin
			dump_addr<=32'h00000004;
			dump_byte_cnt<=2'b00;
			Tx_Done_first<=1;
			Tx_DV<=0;
			dump_ready=0;
		end
		else begin
			if(Tx_DV==0 && dump_ready==0)begin
				data_to_dump<=dump_data[7:0];
				dump_ready=1;
			end
			else if(Tx_DV==0)begin
				Tx_DV=1;
			end

			if(Tx_Done & Tx_Done_first)begin
				if(dump_byte_cnt==2'd3 && dump_addr<512)begin
					dump_addr=dump_addr+4;
					data_to_dump=dump_data[7:0];
					dump_byte_cnt=0;
				end
				else begin
					if(dump_byte_cnt==0)data_to_dump=dump_data[15:8];
					else if(dump_byte_cnt==1)data_to_dump=dump_data[23:16];
					else if(dump_byte_cnt==2)data_to_dump=dump_data[31:24];
					dump_byte_cnt=dump_byte_cnt+1;
				end
				Tx_Done_first=0;
			end
			else if(Tx_Done & ~Tx_Done_first & dump_byte_cnt==0)begin
				data_to_dump=dump_data[7:0];
				Tx_Done_first=1;
			end
			else
				Tx_Done_first=1;
		end
	end
	uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx_inst
	(
		.i_Clock(clk),
		.i_Tx_DV(Tx_DV),
		.i_Tx_Byte(data_to_dump),
		.o_Tx_Active(Tx_Active),
		.o_Tx_Serial(Tx_Serial),
		.o_Tx_Done(Tx_Done)
	);


	reg [2:0] byte_cnt;
	reg [31:0] word;
	reg [31:0] cntByteTime;
	reg addr0_pass;
	always @(posedge reset or posedge clk)begin
		if(reset)begin
			addr0<=32'd0;
			rd_en0<=1'b0;
			wr_en0 <= 1'b0;
			wdata0 <= 32'd0;
			addr0_pass<=0;
			addr1<=32'd0;
			rd_en1<=1'b0;
			wr_en1 <= 1'b0;
			wdata1 <= 32'd0;
			byte_cnt<=3'd0;
			word<=32'd0;
			cntByteTime<=32'd0;		  
		end
		else begin
			if(Rx_DV && uart_on && (uart_mode==2'd0))begin
				// receive a word = 4Byte
				if(byte_cnt==3'd3)begin
					byte_cnt<=3'd0;
					if(addr0<Instruction_MEMSIZE*4)begin
						if(addr0_pass)addr0<=addr0+3'd4;
							else addr0_pass<=1;
						wr_en0<=1'b1;
						wdata0<={word[31:8],Rx_Byte};
					end
				end
				else begin
					byte_cnt<=byte_cnt+1'b1;
					if(byte_cnt==3'd0) word[31:24]<=Rx_Byte;
					else if(byte_cnt==3'd1) word[23:16]<=Rx_Byte;
					else if(byte_cnt==3'd2) word[15:8]<=Rx_Byte;
					else;
					wr_en0<=1'b0;
				end
			end
			else if(Rx_DV && uart_on && (uart_mode==2'd1))begin
				// receive a word = 4Byte
				if(byte_cnt==3'd3)begin
					byte_cnt<=3'd0;
					if(addr1<Data_MEMSIZE*4)begin
						addr1=addr1+3'd4;
						wr_en1<=1'b1;
						wdata1<={word[31:8],Rx_Byte};
					end
				end
				else begin
					byte_cnt<=byte_cnt+1'b1;
					if(byte_cnt==3'd0) word[31:24]<=Rx_Byte;
					else if(byte_cnt==3'd1) word[23:16]<=Rx_Byte;
					else if(byte_cnt==3'd2) word[15:8]<=Rx_Byte;
					else;
					wr_en1<=1'b0;
				end			  
			end
		end
	end

endmodule
	