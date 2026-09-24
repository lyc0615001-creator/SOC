`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 08:34:39
// Design Name: 
// Module Name: boot_rom
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


module boot_rom #(parameter ADDR_WIDTH = 10)(
        input              clk,
        input              en,
        input      [31:0]  pc,
        output reg [31:0]  instr
    );

    reg [31:0] rom [0: ((1 << ADDR_WIDTH) - 1)];


    initial begin
        $readmemh("lab5_gpio.mem", rom);
    end

    always @(posedge clk) begin
        if (en) begin
            instr <= rom[pc[ADDR_WIDTH + 1:2]];
        end
    end


endmodule
