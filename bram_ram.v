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
        input     [3:0]   ram_wstrb,
        input     [31:0]  ram_addr,
        input     [31:0]  ram_wdata,
        output  reg  [31:0]  ram_rdata
    );

    reg [31:0] ram [0: ((1 << ADDR_WIDTH) - 1)];

    // initial begin
    //     ram[0] = 32'h11223344;
    //     ram[1] = 32'h55667788;
    // end

    always @(posedge clk) begin
        if (ram_re) begin
            ram_rdata <= ram[ram_addr];
        end
        if (ram_we) begin
            if (ram_wstrb[0]) begin
                ram[ram_addr][7:0] <= ram_wdata[7:0];
            end
            if (ram_wstrb[1]) begin
                ram[ram_addr][15:8] <= ram_wdata[15:8];
            end
            if (ram_wstrb[2]) begin
                ram[ram_addr][23:16] <= ram_wdata[23:16];
            end
            if (ram_wstrb[3]) begin
                ram[ram_addr][31:17] <= ram_wdata[31:17];
            end
        end
    end
endmodule
