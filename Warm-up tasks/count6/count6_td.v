`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2022 07:37:30 AM
// Design Name: 
// Module Name: count6_td
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


module count6_td(

    );
    reg rst;
    reg clk;
    reg en;
    wire [3:0] count;
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
    count_6 count6(rst,clk,en,count,co); 
endmodule
