`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 11:10:15
// Design Name: 
// Module Name: video_timing
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


module video_timing(
    input  wire        pixel_clk,
    input  wire        rst_n,

    output wire        hsync,
    output wire        vsync,
    output wire        de,

    output wire [9:0]  pixel_x,  // 0-639
    output wire [9:0]  pixel_y   // 0-479
);
    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;

    localparam V_ACTIVE = 480;
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;

    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

    localparam H_SYNC_START = H_ACTIVE + H_FP;  // 656
    localparam H_SYNC_END   = H_SYNC_START + H_SYNC; // 752

    localparam V_SYNC_START = V_ACTIVE + V_FP;  // 490
    localparam V_SYNC_END   = V_SYNC_START + V_SYNC; // 492

    reg [9:0] count_h;
    reg [9:0] count_v;

    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            count_h <= 0;
            count_v <= 0;
        end else begin
            if (count_h == H_TOTAL - 1) begin
                count_h <= 0;

                if (count_v == V_TOTAL - 1) begin
                    count_v <= 0;
                end else begin
                    count_v <= count_v + 1;
                end

            end else begin
                count_h <= count_h + 1;
            end

            
        end
    end

    assign de = (count_h < H_ACTIVE) && (count_v < V_ACTIVE);

    assign hsync = ((count_h >= H_SYNC_START) && (count_h < H_SYNC_END)) ? 1'b0 : 1'b1;
    assign vsync = ((count_v >= V_SYNC_START) && (count_v < V_SYNC_END)) ? 1'b0 : 1'b1;

    assign pixel_x = count_h;
    assign pixel_y = count_v;

endmodule
