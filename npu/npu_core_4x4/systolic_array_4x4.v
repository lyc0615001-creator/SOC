`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 09:55:51
// Design Name: 
// Module Name: systolic_array_4x4
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


module systolic_array_4x4(
        input  wire clk,
        input  wire rst_n,
        input  wire clear,

        input  wire signed [7:0] act_in0,
        input  wire signed [7:0] act_in1,
        input  wire signed [7:0] act_in2,
        input  wire signed [7:0] act_in3,

        input  wire               act_valid0,
        input  wire               act_valid1,
        input  wire               act_valid2,
        input  wire               act_valid3,

        input  wire signed [7:0] weight_in0,
        input  wire signed [7:0] weight_in1,
        input  wire signed [7:0] weight_in2,
        input  wire signed [7:0] weight_in3,

        input  wire               weight_valid0,
        input  wire               weight_valid1,
        input  wire               weight_valid2,
        input  wire               weight_valid3,

        output wire signed [31:0] c00,
        output wire signed [31:0] c01,
        output wire signed [31:0] c02,
        output wire signed [31:0] c03,
        output wire signed [31:0] c10,
        output wire signed [31:0] c11,
        output wire signed [31:0] c12,
        output wire signed [31:0] c13,
        output wire signed [31:0] c20,
        output wire signed [31:0] c21,
        output wire signed [31:0] c22,
        output wire signed [31:0] c23,
        output wire signed [31:0] c30,
        output wire signed [31:0] c31,
        output wire signed [31:0] c32,
        output wire signed [31:0] c33
    );

    //==================================================
    // A 横向连接
    //==================================================

    // row 0
    wire signed [7:0] a00_01;
    wire signed [7:0] a01_02;
    wire signed [7:0] a02_03;

    wire av00_01;
    wire av01_02;
    wire av02_03;

    // row 1
    wire signed [7:0] a10_11;
    wire signed [7:0] a11_12;
    wire signed [7:0] a12_13;

    wire av10_11;
    wire av11_12;
    wire av12_13;

    // row 2
    wire signed [7:0] a20_21;
    wire signed [7:0] a21_22;
    wire signed [7:0] a22_23;

    wire av20_21;
    wire av21_22;
    wire av22_23;

    // row 3
    wire signed [7:0] a30_31;
    wire signed [7:0] a31_32;
    wire signed [7:0] a32_33;

    wire av30_31;
    wire av31_32;
    wire av32_33;


    //==================================================
    // B 纵向连接
    //==================================================

    // column 0
    wire signed [7:0] w00_10;
    wire signed [7:0] w10_20;
    wire signed [7:0] w20_30;

    wire wv00_10;
    wire wv10_20;
    wire wv20_30;

    // column 1
    wire signed [7:0] w01_11;
    wire signed [7:0] w11_21;
    wire signed [7:0] w21_31;

    wire wv01_11;
    wire wv11_21;
    wire wv21_31;

    // column 2
    wire signed [7:0] w02_12;
    wire signed [7:0] w12_22;
    wire signed [7:0] w22_32;

    wire wv02_12;
    wire wv12_22;
    wire wv22_32;

    // column 3
    wire signed [7:0] w03_13;
    wire signed [7:0] w13_23;
    wire signed [7:0] w23_33;

    wire wv03_13;
    wire wv13_23;
    wire wv23_33;


    //==================================================
    // 最右侧 / 最下侧不用的输出
    //==================================================

    wire signed [7:0] unused_a0;
    wire signed [7:0] unused_a1;
    wire signed [7:0] unused_a2;
    wire signed [7:0] unused_a3;

    wire unused_av0;
    wire unused_av1;
    wire unused_av2;
    wire unused_av3;

    wire signed [7:0] unused_w0;
    wire signed [7:0] unused_w1;
    wire signed [7:0] unused_w2;
    wire signed [7:0] unused_w3;

    wire unused_wv0;
    wire unused_wv1;
    wire unused_wv2;
    wire unused_wv3;

    //************** row 0 ******************** 
    pe u_pe00(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(act_valid0),
        .weight_valid_in(weight_valid0),

        .act_in(act_in0),
        .weight_in(weight_in0),

        .act_valid_out(av00_01),
        .weight_valid_out(wv00_10),

        .act_out(a00_01),
        .weight_out(w00_10),

        .psum_out(c00)
    );
    pe u_pe01(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av00_01),
        .weight_valid_in(weight_valid1),

        .act_in(a00_01),
        .weight_in(weight_in1),

        .act_valid_out(av01_02),
        .weight_valid_out(wv01_11),

        .act_out(a01_02),
        .weight_out(w01_11),

        .psum_out(c01)
    );
    pe u_pe02(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av01_02),
        .weight_valid_in(weight_valid2),

        .act_in(a01_02),
        .weight_in(weight_in2),

        .act_valid_out(av02_03),
        .weight_valid_out(wv02_12),

        .act_out(a02_03),
        .weight_out(w02_12),

        .psum_out(c02)
    );
    pe u_pe03(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av02_03),
        .weight_valid_in(weight_valid3),

        .act_in(a02_03),
        .weight_in(weight_in3),

        .act_valid_out(unused_av0),
        .weight_valid_out(wv03_13),

        .act_out(unused_a0),
        .weight_out(w03_13),

        .psum_out(c03)
    );

    //************** row 1 ******************** 
    pe u_pe10(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(act_valid1),
        .weight_valid_in(wv00_10),

        .act_in(act_in1),
        .weight_in(w00_10),

        .act_valid_out(av10_11),
        .weight_valid_out(wv10_20),

        .act_out(a10_11),
        .weight_out(w10_20),

        .psum_out(c10)
    );
    pe u_pe11(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av10_11),
        .weight_valid_in(wv01_11),

        .act_in(a10_11),
        .weight_in(w01_11),

        .act_valid_out(av11_12),
        .weight_valid_out(wv11_21),

        .act_out(a11_12),
        .weight_out(w11_21),

        .psum_out(c11)
    );
    pe u_pe12(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av11_12),
        .weight_valid_in(wv02_12),

        .act_in(a11_12),
        .weight_in(w02_12),

        .act_valid_out(av12_13),
        .weight_valid_out(wv12_22),

        .act_out(a12_13),
        .weight_out(w12_22),

        .psum_out(c12)
    );
    pe u_pe13(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av12_13),
        .weight_valid_in(wv03_13),

        .act_in(a12_13),
        .weight_in(w03_13),

        .act_valid_out(unused_av1),
        .weight_valid_out(wv13_23),

        .act_out(unused_a1),
        .weight_out(w13_23),

        .psum_out(c13)
    );

    //************** row 2 ******************** 
    pe u_pe20(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(act_valid2),
        .weight_valid_in(wv10_20),

        .act_in(act_in2),
        .weight_in(w10_20),

        .act_valid_out(av20_21),
        .weight_valid_out(wv20_30),

        .act_out(a20_21),
        .weight_out(w20_30),

        .psum_out(c20)
    );
    pe u_pe21(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av20_21),
        .weight_valid_in(wv11_21),

        .act_in(a20_21),
        .weight_in(w11_21),

        .act_valid_out(av21_22),
        .weight_valid_out(wv21_31),

        .act_out(a21_22),
        .weight_out(w21_31),

        .psum_out(c21)
    );
    pe u_pe22(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av21_22),
        .weight_valid_in(wv12_22),

        .act_in(a21_22),
        .weight_in(w12_22),

        .act_valid_out(av22_23),
        .weight_valid_out(wv22_32),

        .act_out(a22_23),
        .weight_out(w22_32),

        .psum_out(c22)
    );
    pe u_pe23(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av22_23),
        .weight_valid_in(wv13_23),

        .act_in(a22_23),
        .weight_in(w13_23),

        .act_valid_out(unused_av2),
        .weight_valid_out(wv23_33),

        .act_out(unused_a2),
        .weight_out(w23_33),

        .psum_out(c23)
    );

    //************** row 3 ******************** 
    pe u_pe30(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(act_valid3),
        .weight_valid_in(wv20_30),

        .act_in(act_in3),
        .weight_in(w20_30),

        .act_valid_out(av30_31),
        .weight_valid_out(unused_wv0),

        .act_out(a30_31),
        .weight_out(unused_w0),

        .psum_out(c30)
    );
    pe u_pe31(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av30_31),
        .weight_valid_in(wv21_31),

        .act_in(a30_31),
        .weight_in(w21_31),

        .act_valid_out(av31_32),
        .weight_valid_out(unused_wv1),

        .act_out(a31_32),
        .weight_out(unused_w1),

        .psum_out(c31)
    );
    pe u_pe32(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av31_32),
        .weight_valid_in(wv22_32),

        .act_in(a31_32),
        .weight_in(w22_32),

        .act_valid_out(av32_33),
        .weight_valid_out(unused_wv2),

        .act_out(a32_33),
        .weight_out(unused_w2),

        .psum_out(c32)
    );
    pe u_pe33(
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .act_valid_in(av32_33),
        .weight_valid_in(wv23_33),

        .act_in(a32_33),
        .weight_in(w23_33),

        .act_valid_out(unused_av3),
        .weight_valid_out(unused_wv3),

        .act_out(unused_a3),
        .weight_out(unused_w3),

        .psum_out(c33)
    );

endmodule
