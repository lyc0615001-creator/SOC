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
    input [3:0] alu_control,
    input [31:0] alu_data_i1,
    input [31:0] alu_data_i2,
    input [4:0] shamt, //“∆Œª÷∏¡Ó
    output [31:0] alu_data_o
    );

    assign alu_data_o = (alu_control == 4'b0000) ? (alu_data_i1 + alu_data_i2) :
                        (alu_control == 4'b0001) ? (alu_data_i1 - alu_data_i2) :
                        (alu_control == 4'b0010) ? (alu_data_i1 & alu_data_i2) :
                        (alu_control == 4'b0011) ? (alu_data_i1 | alu_data_i2) :
                        (alu_control == 4'b0100) ? (alu_data_i1 ^ alu_data_i2) :
                        (alu_control == 4'b0101) ? ($signed(alu_data_i1) < $signed(alu_data_i2)) :
                        (alu_control == 4'b0110) ? {alu_data_i2[15:0], 16'b0} :
                        (alu_control == 4'b0111) ? (alu_data_i2 << shamt) :
                        (alu_control == 4'b1000) ? (alu_data_i2 >> shamt) :
                        32'd0;

endmodule
