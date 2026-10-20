`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 14:56:33
// Design Name: 
// Module Name: hdmi_tx
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


module hdmi_tx(
        input  wire       pixel_clk,
        input  wire       clk_5x,

        input  wire       rst_n,

        input             hsync,
        input             vsync,

        input             de,

        input      [7:0]  R,
        input      [7:0]  G,
        input      [7:0]  B,

        output     [9:0]  tmds_B,

        output            hdmi_d0_p,
        output            hdmi_d0_n,

        output            hdmi_d1_p,
        output            hdmi_d1_n,

        output            hdmi_d2_p,
        output            hdmi_d2_n,

        output            hdmi_clk_p,
        output            hdmi_clk_n
    );

    wire [9:0] tmds_R;
    wire [9:0] tmds_G;
    // wire [9:0] tmds_B;

    wire            serial_out_r;
    wire            serial_out_g;
    wire            serial_out_b;

    wire [1:0] ctrl;

    assign ctrl = {vsync, hsync};

    tmds_encoder u_tmds_encoder_R(
        .pixel_clk(pixel_clk),
        .rst_n(rst_n),

        .de(de),

        .data(R),
        .ctrl(2'b00),

        .tmds(tmds_R)
    );
    tmds_encoder u_tmds_encoder_G(
        .pixel_clk(pixel_clk),
        .rst_n(rst_n),

        .de(de),

        .data(G),
        .ctrl(2'b00),

        .tmds(tmds_G)
    );
    tmds_encoder u_tmds_encoder_B(
        .pixel_clk(pixel_clk),
        .rst_n(rst_n),

        .de(de),

        .data(B),
        .ctrl(ctrl),

        .tmds(tmds_B)
    );


    tmds_serializer u_tmds_serializer_R(
        .pixel_clk(pixel_clk),
        .clk_5x(clk_5x),
        .rst(!rst_n),

        .tmds_data(tmds_R),

        .serial_out(serial_out_r)
    );
    tmds_serializer u_tmds_serializer_G(
        .pixel_clk(pixel_clk),
        .clk_5x(clk_5x),
        .rst(!rst_n),

        .tmds_data(tmds_G),

        .serial_out(serial_out_g)
    );
    tmds_serializer u_tmds_serializer_B(
        .pixel_clk(pixel_clk),
        .clk_5x(clk_5x),
        .rst(!rst_n),

        .tmds_data(tmds_B),

        .serial_out(serial_out_b)
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
    ) u_OBUFDS_channel0 (
        .O(hdmi_d0_p),     // Diff_p output (connect directly to top-level port)
        .OB(hdmi_d0_n),   // Diff_n output (connect directly to top-level port)
        .I(serial_out_b)      // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
    ) u_OBUFDS_channel1 (
        .O(hdmi_d1_p),     // Diff_p output (connect directly to top-level port)
        .OB(hdmi_d1_n),   // Diff_n output (connect directly to top-level port)
        .I(serial_out_g)      // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
    ) u_OBUFDS_channel2 (
        .O(hdmi_d2_p),     // Diff_p output (connect directly to top-level port)
        .OB(hdmi_d2_n),   // Diff_n output (connect directly to top-level port)
        .I(serial_out_r)      // Buffer input
    );

    //**********时钟***********
    wire tmds_clk_se;

    ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
    ) u_ODDR_tmds_clk (
      .Q(tmds_clk_se),   // 1-bit DDR output
      .C(pixel_clk),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

   OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
   ) u_OBUFDS_clk (
        .O(hdmi_clk_p),     // Diff_p output (connect directly to top-level port)
        .OB(hdmi_clk_n),   // Diff_n output (connect directly to top-level port)
        .I(tmds_clk_se)      // Buffer input
    );



endmodule
