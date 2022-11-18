`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2022 12:37:35 PM
// Design Name: 
// Module Name: count60_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module count60_td(

    );
    reg rst;
    reg clk;
    reg en;
    wire [7:0] count;
    wire co;
    initial begin
        rst = 0;
        clk = 0;
        en = 0;
        #100
        rst = 1;
        #40
        rst = 0;
        en = 1;
    end
    
    always #10 clk = ~clk;
    count_60 count60(rst,clk,en,count,co); 
endmodule
