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
        input               gpio_re,
        input               gpio_we,
        input       [7:0]   gpio_addr,
        input       [31:0]  gpio_wdata,
        output reg  [31:0]  gpio_rdata,
        output      [3:0]   led
    );

    reg [31:0] gpio_data;

    always @(posedge clk) begin
        if (!rst) begin
            gpio_rdata <= 32'b0;
        end else begin
            if (gpio_re && gpio_addr == 8'b0) begin
                gpio_rdata <= gpio_data;
            end
            if (gpio_we && gpio_addr == 8'b0) begin
                gpio_data <= gpio_wdata;
            end
        end
    end

    assign led[3:0] = gpio_data[3:0];
    
endmodule
