`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/21 17:00:09
// Design Name: 
// Module Name: mux4
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


module mux4 #(parameter WIDTH = 32)(
        input [WIDTH-1:0] data_i1,
        input [WIDTH-1:0] data_i2,
        input [WIDTH-1:0] data_i3,
        input [WIDTH-1:0] data_i4,
        input [1:0] sel,
        output [WIDTH-1:0] data_o
    );

    assign data_o = (sel == 2'b00) ? data_i1 :
                    (sel == 2'b01) ? data_i2 :
                    (sel == 2'b10) ? data_i3 :
                    (sel == 2'b11) ? data_i4 :
                    data_i1;
endmodule

