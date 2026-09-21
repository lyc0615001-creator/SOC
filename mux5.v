`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/19 19:18:28
// Design Name: 
// Module Name: mux5
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

    assign data_o = (sel == 3'b00) ? data_i1 :
                    (sel == 3'b01) ? data_i2 :
                    (sel == 3'b10) ? data_i3 :
                    (sel == 3'b11) ? data_i4 :
                    data_i1;
endmodule
