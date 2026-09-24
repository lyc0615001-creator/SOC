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
        input             ram_reM,
        input             ram_weM,
        input     [31:0]  ram_addrM,
        input     [31:0]  ram_wdataM,
        output  reg  [31:0]  ram_rdataDM
    );

    reg [31:0] ram [0: ((1 << ADDR_WIDTH) - 1)];

    always @(posedge clk) begin
        if (ram_reM) begin
            ram_rdataDM <= ram[ram_addrM];
        end
        if (ram_weM) begin
            ram[ram_addrM] <= ram_wdataM;
        end
    end
endmodule
