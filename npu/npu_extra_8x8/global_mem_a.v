`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 11:05:54
// Design Name: 
// Module Name: global_mem_a
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


module global_mem_a(
    input  wire              clk,

    input  wire              wr_en,
    input  wire [5:0]        wr_addr,
    input  wire signed [7:0] wr_data,

    input  wire [5:0]        rd_addr,
    output wire signed [7:0] rd_data
);

    reg signed [7:0] data_reg [63:0];

    always @(posedge clk) begin
        if (wr_en) begin
            data_reg[wr_addr] <= wr_data;
        end
    end

    assign rd_data = (rd_addr == wr_addr && wr_en) ? wr_data : data_reg[rd_addr];

endmodule
