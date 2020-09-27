`timescale  1ns / 1ps

module tb_CPU;

// CPU Parameters
parameter PERIOD  = 10;
parameter Instruction_MEMSIZE  = 128    ;
parameter Data_MEMSIZE         = 150    ;
parameter CLKS_PER_BIT         = 16'd5;

// CPU Inputs
reg   reset                                = 0 ;
reg   clk                                  = 0 ;
reg   Rx_Serial                            = 1 ;
reg   uart_on                              = 1 ;
reg   [1:0]  uart_mode                     = 0 ;


// CPU Outputs
wire   [7:0]  leds;
wire   [7:0] ssd;
wire Tx_Serial;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) reset  =  1;
    byte_cnt=0;
    fw=$fopen("E:/verilog/pipeline/data_out.txt","wb");
end

CPU #(
    .Instruction_MEMSIZE ( Instruction_MEMSIZE ),
    .Data_MEMSIZE        ( Data_MEMSIZE        ),
    .CLKS_PER_BIT        ( CLKS_PER_BIT        ))
 u_CPU (
    .reset                   ( reset        ),
    .clk                     ( clk          ),
    .Rx_Serial               ( Rx_Serial        ),
    .Tx_Serial               (Tx_Serial         ),
    .uart_on                 ( uart_on          ),
    .uart_mode               ( uart_mode  [1:0] ),

    .leds                     ( leds    [7:0] ),
    .ssd                       (ssd     [7:0])
);

integer i=0,j=0;
parameter DataSize=144;
parameter InstructionSize=90;
reg [7:0] data_to_sort [DataSize*4:1];
reg [31:0] data_sorted  [DataSize:1];
reg [7:0] instruction [InstructionSize*4:1];

wire Rx_DV;
wire [7:0] Rx_Byte;
uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_rx_inst
    (.i_Clock(clk),
        .i_Rx_Serial(Tx_Serial),
        .o_Rx_DV(Rx_DV),
        .o_Rx_Byte(Rx_Byte)
    );

reg [1:0] byte_cnt;
reg [7:0] addr0=0;
reg [31:0] word;

integer fw;
initial
begin
    #(PERIOD*10);
    //read data to sort
    $display("begin loading data");
    $readmemh("E:/verilog/pipeline/data.txt",data_to_sort);
    uart_on=1;
    uart_mode=1;
    reset=0;
    for(i=1;i<=DataSize*4;i=i+1)begin
        Rx_Serial=0;
        #(PERIOD*CLKS_PER_BIT);
        for(j=0;j<8;j=j+1)begin
            $display("sending [%d][%d] bit",i,j);
            Rx_Serial= data_to_sort[i][j];
            #(PERIOD*CLKS_PER_BIT);         
        end
        Rx_Serial=1;
        #(PERIOD*CLKS_PER_BIT*2);   
    end
    $display("Load data successfully");
    uart_on=0;
    #(PERIOD*10);
    //$finish;

    // loading instruction
    $display("begin loading instruction");
    $readmemh("E:/verilog/pipeline/instruction.txt",instruction);
    uart_on=1;
    uart_mode=0;
    #(PERIOD*1);
    reset=0;
    for(i=1;i<=InstructionSize*4;i=i+1)begin
        Rx_Serial=0;
        #(PERIOD*CLKS_PER_BIT);
        for(j=0;j<8;j=j+1)begin
            $display("sending [%d][%d] bit",i,j);
            Rx_Serial= instruction[i][j];
            #(PERIOD*CLKS_PER_BIT);         
        end
        Rx_Serial=1;
        #(PERIOD*CLKS_PER_BIT*2);   
    end
    $display("Load instruction successfully");
   // $finish;
    uart_on=0;
    #(PERIOD*10);
    //$finish;

    // launch progran    
    $display("Begin running program");
    uart_mode=2'b11;
    reset=0;
    #(PERIOD*200000);
   // $finish;


    // receive sorted data
    $display("receiving data");
    uart_on=1;
    uart_mode=2'b11;  
    //$finish;

    #(PERIOD*30000);
    uart_on=0;
    $finish;
    for(i=1;i<=DataSize;i=i+1)begin
        $fwrite(fw,"%h ",data_sorted[i]);
        $display(data_sorted[i]);
        #(PERIOD);
    end
    $finish;
end

always @(posedge clk)begin
  if(uart_on & uart_mode[1] & Rx_DV)begin
    if(byte_cnt==3'd3)begin
        addr0=addr0+1;
        byte_cnt=3'd0;
        word[31:24]=Rx_Byte;
        data_sorted[addr0]=word;
    end
    else begin
        if(byte_cnt==3'd0) word[7:0]<=Rx_Byte;
        else if(byte_cnt==3'd1) word[15:8]<=Rx_Byte;
        else if(byte_cnt==3'd2) word[23:16]<=Rx_Byte;
        else;
        byte_cnt=byte_cnt+1;
    end
  end
end

endmodule
