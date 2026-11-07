`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 11:38:02
// Design Name: 
// Module Name: color_bar_gen
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


module color_bar_gen (
    input  wire        de,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,

    output reg  [7:0]  red,
    output reg  [7:0]  green,
    output reg  [7:0]  blue
);


    always @(*) begin
        if (!de) begin
            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00; 
        end else if (pixel_x < 80) begin
            red   = 8'hff;
            green = 8'hff;
            blue  = 8'hff; 
        end else if (pixel_x < 160) begin
            red   = 8'hff;
            green = 8'hff;
            blue  = 8'h00; 
        end else if (pixel_x < 240) begin
            red   = 8'h00;
            green = 8'hff;
            blue  = 8'hff; 
        end else if (pixel_x < 320) begin
            red   = 8'h00;
            green = 8'hff;
            blue  = 8'h00; 
        end else if (pixel_x < 400) begin
            red   = 8'hff;
            green = 8'h00;
            blue  = 8'hff; 
        end else if (pixel_x < 480) begin
            red   = 8'hff;
            green = 8'h00;
            blue  = 8'h00; 
        end else if (pixel_x < 560) begin
            red   = 8'h00;
            green = 8'h00;
            blue  = 8'hff; 
        end else if (pixel_x < 640) begin
            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00; 
        end
    end


endmodule
