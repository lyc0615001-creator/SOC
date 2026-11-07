`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/07 13:46:46
// Design Name: 
// Module Name: FIXED_ARBITER
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


module FIXED_ARBITER(
        input           [3:0] req,
        output          [3:0] grant
    );

    assign grant = (req[0] == 1'b1) ? 4'b0001 :
                   (req[1] == 1'b1) ? 4'b0010 :
                   (req[2] == 1'b1) ? 4'b0100 :
                   (req[3] == 1'b1) ? 4'b1000 :
                   4'b0000;
endmodule
