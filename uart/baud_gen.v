`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 15:16:56
// Design Name: 
// Module Name: baud_gen
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


module baud_gen(
        input      clk,
        input      rst,
        output reg tick_16x
    );

    localparam CLK_FREQ = 50_000_000;
    localparam BAUD = 115200;
    localparam OVERSAMPLE = 16;
    localparam T = CLK_FREQ / BAUD / OVERSAMPLE;

    reg [5:0] baud_cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            baud_cnt <= 6'b0;
            tick_16x <= 1'b0;
        end else begin
            if (baud_cnt == T - 1) begin
                tick_16x <= 1'b1;
                baud_cnt <= 6'b0;
            end else begin
                tick_16x <= 1'b0;
                baud_cnt <= baud_cnt + 1;
            end
        end
    end

endmodule
