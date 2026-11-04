`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 14:26:36
// Design Name: 
// Module Name: feeder_4x4
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


module feeder_4x4 (
    input  wire              [2:0] cycle_cnt,

    input  wire signed [7:0] a_bank0_data,
    input  wire signed [7:0] a_bank1_data,
    input  wire signed [7:0] a_bank2_data,
    input  wire signed [7:0] a_bank3_data,

    input  wire signed [7:0] b_bank0_data,
    input  wire signed [7:0] b_bank1_data,
    input  wire signed [7:0] b_bank2_data,
    input  wire signed [7:0] b_bank3_data,

    output wire [1:0] a_addr0,
    output wire [1:0] a_addr1,
    output wire [1:0] a_addr2,
    output wire [1:0] a_addr3,

    output wire [1:0] b_addr0,
    output wire [1:0] b_addr1,
    output wire [1:0] b_addr2,
    output wire [1:0] b_addr3,

    output wire signed [7:0] act_in0,
    output wire signed [7:0] act_in1,
    output wire signed [7:0] act_in2,
    output wire signed [7:0] act_in3,

    output wire act_valid0,
    output wire act_valid1,
    output wire act_valid2,
    output wire act_valid3,

    output wire signed [7:0] weight_in0,
    output wire signed [7:0] weight_in1,
    output wire signed [7:0] weight_in2,
    output wire signed [7:0] weight_in3,

    output wire weight_valid0,
    output wire weight_valid1,
    output wire weight_valid2,
    output wire weight_valid3
);

    assign act_valid0 = cycle_cnt < 4;
    assign act_valid1 = cycle_cnt >= 1 && cycle_cnt < 5;
    assign act_valid2 = cycle_cnt >= 2 && cycle_cnt < 6;
    assign act_valid3 = cycle_cnt >= 3 && cycle_cnt < 7;

    assign weight_valid0 = cycle_cnt < 4;
    assign weight_valid1 = cycle_cnt >= 1 && cycle_cnt < 5;
    assign weight_valid2 = cycle_cnt >= 2 && cycle_cnt < 6;
    assign weight_valid3 = cycle_cnt >= 3 && cycle_cnt < 7;

    assign a_addr0 = cycle_cnt - 0;
    assign a_addr1 = cycle_cnt - 1;
    assign a_addr2 = cycle_cnt - 2;
    assign a_addr3 = cycle_cnt - 3;

    assign b_addr0 = cycle_cnt - 0;
    assign b_addr1 = cycle_cnt - 1;
    assign b_addr2 = cycle_cnt - 2;
    assign b_addr3 = cycle_cnt - 3;

    assign act_in0 = a_bank0_data;
    assign act_in1 = a_bank1_data;
    assign act_in2 = a_bank2_data;
    assign act_in3 = a_bank3_data;

    assign weight_in0 = b_bank0_data;
    assign weight_in1 = b_bank1_data;
    assign weight_in2 = b_bank2_data;
    assign weight_in3 = b_bank3_data;


endmodule
