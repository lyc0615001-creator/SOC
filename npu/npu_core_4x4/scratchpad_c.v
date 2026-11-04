`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 11:51:22
// Design Name: 
// Module Name: scratchpad_c
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


module scratchpad_c(
        input  wire               clk,

        input  wire               wr_en,
        input  wire [3:0]         wr_addr,
        input  wire signed [31:0] wr_data,

        input  wire [3:0]         rd_addr,
        output wire signed [31:0] rd_data
    );

    reg [31:0] data_reg [15:0];

    always @(posedge clk) begin
        if (wr_en) begin
            data_reg[wr_addr] <= wr_data;
        end
    end

    assign rd_data = (rd_addr == wr_addr) ? wr_data : data_reg[rd_addr];
endmodule
