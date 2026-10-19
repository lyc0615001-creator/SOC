`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 13:02:11
// Design Name: 
// Module Name: video_system_rst
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


module video_system_rst (
    input         clk_video_25,
    input         rst_n,
    output        video_rst_n
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] video_rst_sync;

    always @(posedge clk_video_25 or negedge rst_n) begin
        if (!rst_n)
            video_rst_sync <= 2'b00;
        else
            video_rst_sync <= {video_rst_sync[0], 1'b1};
    end

    assign video_rst_n = video_rst_sync[1];
endmodule
