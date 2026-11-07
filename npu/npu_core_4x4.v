`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 14:59:03
// Design Name: 
// Module Name: npu_core_4x4
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


module npu_core_4x4 (
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    start,
    input  wire                    clear,
    output wire                    busy,
    output wire                    done,

    // A矩阵写入口：row-major
    input  wire                    a_wr_en,
    input  wire [3:0]              a_wr_addr,
    input  wire signed [7:0]       a_wr_data,

    // B矩阵写入口：row-major
    input  wire                    b_wr_en,
    input  wire [3:0]              b_wr_addr,
    input  wire signed [7:0]       b_wr_data,

    input  wire [3:0]              rd_addr,
    output wire signed [31:0]      rd_data
);

    //==================================================
    // npu_controller
    //==================================================

    wire [3:0]  cycle_cnt;

    // 结果矩阵
    wire signed [31:0]      c00;
    wire signed [31:0]      c01;
    wire signed [31:0]      c02;
    wire signed [31:0]      c03;

    wire signed [31:0]      c10;
    wire signed [31:0]      c11;
    wire signed [31:0]      c12;
    wire signed [31:0]      c13;

    wire signed [31:0]      c20;
    wire signed [31:0]      c21;
    wire signed [31:0]      c22;
    wire signed [31:0]      c23;

    wire signed [31:0]      c30;
    wire signed [31:0]      c31;
    wire signed [31:0]      c32;
    wire signed [31:0]      c33;

    wire       c_wr_en;
    
    wire [3:0] c_wr_addr;

    wire signed [31:0] c_wr_data;

    npu_controller u_npu_controller(
        .clk(clk),
        .rst_n(rst_n),
        // .clear(clear),

        .start(start),
        .busy(busy),
        .done(done),

        .cycle_cnt(cycle_cnt),

        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33),

        .wr_en    (c_wr_en),
        .wr_addr  (c_wr_addr),
        .wr_data  (c_wr_data)
    );

    //==================================================
    // Scratchpad A
    //==================================================

    wire [1:0] a_addr0;
    wire [1:0] a_addr1;
    wire [1:0] a_addr2;
    wire [1:0] a_addr3;

    wire signed [7:0] a_data0;
    wire signed [7:0] a_data1;
    wire signed [7:0] a_data2;
    wire signed [7:0] a_data3;

    scratchpad_a u_spad_a (
        .clk      (clk),

        .wr_en    (a_wr_en),
        .wr_addr  (a_wr_addr),
        .wr_data  (a_wr_data),

        .rd_addr0 (a_addr0),
        .rd_addr1 (a_addr1),
        .rd_addr2 (a_addr2),
        .rd_addr3 (a_addr3),

        .rd_data0 (a_data0),
        .rd_data1 (a_data1),
        .rd_data2 (a_data2),
        .rd_data3 (a_data3)
    );


    //==================================================
    // Scratchpad B
    //==================================================

    wire [1:0] b_addr0;
    wire [1:0] b_addr1;
    wire [1:0] b_addr2;
    wire [1:0] b_addr3;

    wire signed [7:0] b_data0;
    wire signed [7:0] b_data1;
    wire signed [7:0] b_data2;
    wire signed [7:0] b_data3;

    scratchpad_b u_spad_b (
        .clk      (clk),

        .wr_en    (b_wr_en),
        .wr_addr  (b_wr_addr),
        .wr_data  (b_wr_data),

        .rd_addr0 (b_addr0),
        .rd_addr1 (b_addr1),
        .rd_addr2 (b_addr2),
        .rd_addr3 (b_addr3),

        .rd_data0 (b_data0),
        .rd_data1 (b_data1),
        .rd_data2 (b_data2),
        .rd_data3 (b_data3)
    );


    //==================================================
    // Feeder
    //==================================================

    wire signed [7:0] act_in0;
    wire signed [7:0] act_in1;
    wire signed [7:0] act_in2;
    wire signed [7:0] act_in3;

    wire act_valid0;
    wire act_valid1;
    wire act_valid2;
    wire act_valid3;

    wire signed [7:0] weight_in0;
    wire signed [7:0] weight_in1;
    wire signed [7:0] weight_in2;
    wire signed [7:0] weight_in3;

    wire weight_valid0;
    wire weight_valid1;
    wire weight_valid2;
    wire weight_valid3;


    feeder_4x4 u_feeder (
        .cycle_cnt (cycle_cnt),

        .a_bank0_data (a_data0),
        .a_bank1_data (a_data1),
        .a_bank2_data (a_data2),
        .a_bank3_data (a_data3),

        .b_bank0_data (b_data0),
        .b_bank1_data (b_data1),
        .b_bank2_data (b_data2),
        .b_bank3_data (b_data3),

        .a_addr0 (a_addr0),
        .a_addr1 (a_addr1),
        .a_addr2 (a_addr2),
        .a_addr3 (a_addr3),

        .b_addr0 (b_addr0),
        .b_addr1 (b_addr1),
        .b_addr2 (b_addr2),
        .b_addr3 (b_addr3),

        .act_in0 (act_in0),
        .act_in1 (act_in1),
        .act_in2 (act_in2),
        .act_in3 (act_in3),

        .act_valid0 (act_valid0),
        .act_valid1 (act_valid1),
        .act_valid2 (act_valid2),
        .act_valid3 (act_valid3),

        .weight_in0 (weight_in0),
        .weight_in1 (weight_in1),
        .weight_in2 (weight_in2),
        .weight_in3 (weight_in3),

        .weight_valid0 (weight_valid0),
        .weight_valid1 (weight_valid1),
        .weight_valid2 (weight_valid2),
        .weight_valid3 (weight_valid3)
    );


    //==================================================
    // 4x4 Systolic Array
    //==================================================

    systolic_array_4x4 u_array (
        .clk   (clk),
        .rst_n (rst_n),
        .clear (clear),

        .act_in0 (act_in0),
        .act_in1 (act_in1),
        .act_in2 (act_in2),
        .act_in3 (act_in3),

        .act_valid0 (act_valid0),
        .act_valid1 (act_valid1),
        .act_valid2 (act_valid2),
        .act_valid3 (act_valid3),

        .weight_in0 (weight_in0),
        .weight_in1 (weight_in1),
        .weight_in2 (weight_in2),
        .weight_in3 (weight_in3),

        .weight_valid0 (weight_valid0),
        .weight_valid1 (weight_valid1),
        .weight_valid2 (weight_valid2),
        .weight_valid3 (weight_valid3),

        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    

    //==================================================
    // Scratchpad C
    //==================================================

    scratchpad_c u_spad_c (
        .clk      (clk),

        .wr_en    (c_wr_en),
        .wr_addr  (c_wr_addr),
        .wr_data  (c_wr_data),

        .rd_addr  (rd_addr),
        .rd_data  (rd_data)
    );

endmodule