`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/23 15:36:46
// Design Name: 
// Module Name: bram_ram
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


module bram_ram #(parameter ADDR_WIDTH = 10)(
        input             clk,
        input             ram_re,
        input             ram_we,
        input     [31:0]  ram_addr,
        input     [31:0]  ram_wdata,
        output  reg  [31:0]  ram_rdata
    );

    reg [31:0] ram [0: ((1 << ADDR_WIDTH) - 1)];

    always @(posedge clk) begin
        if (ram_re) begin
            ram_rdata <= ram[ram_addr];
        end
        if (ram_we) begin
            ram[ram_addr] <= ram_wdata;
        end
    end
endmodule
