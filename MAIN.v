`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/18 17:24:12
// Design Name: 
// Module Name: MAIN
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


module MAIN(
        input clk,
        input rst,
        output [7:0] seg,
        output [1:0] sel,
        output [3:0] led
    );

    // parameter T = 50_000_000; //x HZ 可调
    parameter T = 32;

    reg [31:0] T_clk;

    wire [31:0] display_data;
    wire display_status;

    // 降频1hz
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            T_clk <= T; // 默认1HZ
        end
    end

    CPU_TOP u_CPU_TOP(
        .clk(clk),
        .rst(rst),
        .T_clk(T_clk),
        .dm_write_en_effM(display_status),
        .display_data(display_data)
    );

    // LED展示
    LED_display u_LED_display(
        .clk(clk),
        .rst(rst),
        .display_status(display_status),
        .T_clk(T_clk),
        .display_data(display_data),
        .seg(seg),
        .sel(sel),
        .led(led)
    );
endmodule
