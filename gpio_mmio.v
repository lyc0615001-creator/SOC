`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/23 19:33:23
// Design Name: 
// Module Name: gpio_mmio
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


module gpio_mmio(
        input               clk,
        input               rst,
        input               gpio_reM,
        input               gpio_weM,
        input       [7:0]   gpio_addrM,
        input       [31:0]  gpio_wdataM,
        output reg  [31:0]  gpio_rdataDM,
        output      [3:0]   led
    );

    reg [31:0] gpio_data;

    always @(posedge clk) begin
        if (!rst) begin
            gpio_rdataDM <= 32'b0;
        end else begin
            if (gpio_reM && gpio_addrM == 8'b0) begin
                gpio_rdataDM <= gpio_data;
            end
            if (gpio_weM && gpio_addrM == 8'b0) begin
                gpio_data <= gpio_wdataM;
            end
        end
    end

    assign led[3:0] = gpio_data[3:0];
    
endmodule
