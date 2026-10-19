`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 12:53:20
// Design Name: 
// Module Name: video_top
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


module video_top(
        input             clk,
        input             rst_n,

        output            hdmi_d0_p,
        output            hdmi_d0_n,

        output            hdmi_d1_p,
        output            hdmi_d1_n,

        output            hdmi_d2_p,
        output            hdmi_d2_n,

        output            hdmi_clk_p,
        output            hdmi_clk_n,

        output      [3:0] led
    );

    wire clk_video_25;

    wire clk_video_125;

    wire raw_rst_n;

    wire locked;

    assign raw_rst_n = rst_n && locked;

    //video

    wire        pixel_clk;
    wire        clk_5x;
    wire        video_rst_n;

    wire        hsync;
    wire        vsync;
    wire        de;

    wire [9:0]  pixel_x;  // 0-639
    wire [9:0]  pixel_y;   // 0-479

    assign pixel_clk = clk_video_25;
    assign clk_5x    = clk_video_125;


    clk_wiz_video u_clk_wiz_video(
        .clk_out1(clk_video_25),     // output clk_out1
        .clk_out2(clk_video_125),     // output clk_out2

        .resetn(rst_n), // input resetn
        .locked(locked),       // output locked

        .clk_in1(clk)      // input clk_in1
    );

    assign led[0] = locked;
    assign led[1] = pixel_x[9];
    assign led[2] = pixel_y[9];
    assign led[3] = raw_rst_n;

    video_system_rst u_video_system_rst(
        .clk_video_25(clk_video_25),
        .rst_n(raw_rst_n),
        .video_rst_n(video_rst_n)
    );

    video_timing u_video_timing(
        .pixel_clk(pixel_clk),
        .rst_n(video_rst_n),

        .hsync(hsync),
        .vsync(vsync),
        .de(de),

        .pixel_x(pixel_x),  // 0-639
        .pixel_y(pixel_y)   // 0-479
    );

    wire      [7:0]  R;
    wire      [7:0]  G;
    wire      [7:0]  B;

    color_bar_gen u_color_bar_gen(
        .de(de),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),

        .red(R),
        .green(G),
        .blue(B)
    );

    wire [9:0] tmds_B;

    hdmi_tx u_hdmi_tx(
        .pixel_clk(pixel_clk),
        .clk_5x(clk_5x),

        .rst_n(video_rst_n),

        .hsync(hsync),
        .vsync(vsync),

        .de(de),

        .R(R),
        .G(G),
        .B(B),

        .tmds_B(tmds_B),

        .hdmi_d0_p(hdmi_d0_p),
        .hdmi_d0_n(hdmi_d0_n),

        .hdmi_d1_p(hdmi_d1_p),
        .hdmi_d1_n(hdmi_d1_n),

        .hdmi_d2_p(hdmi_d2_p),
        .hdmi_d2_n(hdmi_d2_n),

        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_clk_n(hdmi_clk_n)
    );

    ila_0 u_ila_0 (
        .clk(clk_5x), // input wire clk


        .probe0(video_rst_n), // input wire [0:0]  probe0  
        .probe1(hsync), // input wire [0:0]  probe1 
        .probe2(vsync), // input wire [0:0]  probe2 
        .probe3(de), // input wire [0:0]  probe3 
        .probe4(pixel_x), // input wire [9:0]  probe4 
        .probe5(pixel_y), // input wire [9:0]  probe5 
        .probe6(B), // input wire [7:0]  probe6 
        .probe7(tmds_B) // input wire [9:0]  probe7
    );

endmodule
