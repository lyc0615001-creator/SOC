`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/01 09:09:11
// Design Name: 
// Module Name: mux6
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


module mux6 #(parameter WIDTH = 32)(
        input [WIDTH-1:0] data_i1,
        input [WIDTH-1:0] data_i2,
        input [WIDTH-1:0] data_i3,
        input [WIDTH-1:0] data_i4,
        input [WIDTH-1:0] data_i5,
        input [WIDTH-1:0] data_i6,
        input [2:0] sel,
        output [WIDTH-1:0] data_o
    );

    assign data_o = (sel == 3'b000) ? data_i1 :
                    (sel == 3'b001) ? data_i2 :
                    (sel == 3'b010) ? data_i3 :
                    (sel == 3'b011) ? data_i4 :
                    (sel == 3'b100) ? data_i5 :
                    (sel == 3'b111) ? data_i6 :
                    {WIDTH{1'b0}};
endmodule
