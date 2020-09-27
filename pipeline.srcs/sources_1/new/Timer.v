`timescale 1ns / 1ps


module Timer(
    input reset,
    input clk,
    input [1:0] addr,
    input MemWrite,
    input [31:0] Write_data,
    output [31:0] read_data,
    output IRQ
    );
    reg [31:0] TH;
    reg [31:0] TL;
    reg [31:0] TCON;
    assign read_data=(addr==0)?TH:(addr==1)?TL:(addr==2)?TCON:32'b0;
    assign IRQ=TCON[2]&TCON[1];
    always @(posedge clk)begin
        if(reset)begin // turn off timer
            TH<=0;
            TL<=0;
            TCON<=0;
        end
        else begin
        if(MemWrite)begin
            if(addr==0) TH<=Write_data;
            else if(addr==1)TL<=Write_data;
            else if (addr==2)TCON<=Write_data;
        end
        else begin
            if(TCON[0])begin  // timer is enabled
                if(TL==32'hffffffff)begin
                    TL<=TH;
                    if(TCON[1]) TCON[2]<=1'b1;
                end
                else TL<=TL+1;
            end
        end
        end
    end
endmodule
