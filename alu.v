`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/17 18:57:02
// Design Name: 
// Module Name: alu
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


module alu(
    input [2:0] alu_control,
    input [31:0] alu_data_i1,
    input [31:0] alu_data_i2,
    output [31:0] alu_data_o
    );

    assign alu_data_o = (alu_control == 3'b010) ? (alu_data_i1 + alu_data_i2) :
                        (alu_control == 3'b110) ? (alu_data_i1 - alu_data_i2) :
                        (alu_control == 3'b000) ? (alu_data_i1 & alu_data_i2) :
                        (alu_control == 3'b001) ? (alu_data_i1 | alu_data_i2) :
                        (alu_control == 3'b111) ? ($signed(alu_data_i1) < $signed(alu_data_i2)) :
                        32'd0;

endmodule
