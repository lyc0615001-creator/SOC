`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/18 16:39:47
// Design Name: 
// Module Name: cpu_cpu_en
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

module cpu_cpu_en(
        input clk,
        input rst,
        input [31:0] T_clk,
        output reg cpu_en
    );

    reg [31:0] cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 32'd0;
            cpu_en <= 1'b0;
        end else begin
            if (T_clk != 32'b0 && cnt == T_clk - 1) begin
                cpu_en <= 1'b1;
                cnt <= 32'd0;
            end else begin
                cnt <= cnt + 1;
                cpu_en <= 1'b0;
            end
        end
    end

endmodule
