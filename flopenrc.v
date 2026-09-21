`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/19 09:04:07
// Design Name: 
// Module Name: flopenrc
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

module flopenrc #(parameter WIDTH = 32)(
        input clk,
        input rst,
        input clk_en,
        input en,
        input clear,
        input [WIDTH-1:0] din,
        output reg [WIDTH-1:0] dout
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dout <= {WIDTH{1'b0}};
        end else if (clk_en & clear) begin
                dout <= {WIDTH{1'b0}};
        end else if (clk_en & en) begin
                dout <= din;
        end
    end


endmodule
