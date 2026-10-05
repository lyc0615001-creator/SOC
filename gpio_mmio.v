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
        input       [3:0]   gpio_wstrb,
        input       [7:0]   gpio_addr,
        input       [31:0]  gpio_wdata,
        output reg  [31:0]  gpio_rdata,
        output      [3:0]   led
    );

    reg [31:0] gpio_data;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            gpio_rdata <= 32'b0;
        end else begin
            if (gpio_re && gpio_addr == 8'b0) begin
                gpio_rdata <= gpio_data;
            end
            if (gpio_we && gpio_addr == 8'b0) begin
                if (gpio_wstrb[0]) begin
                    gpio_data[7:0] <= gpio_wdata[7:0];
                end
                if (gpio_wstrb[1]) begin
                    gpio_data[15:8] <= gpio_wdata[15:8];
                end
                if (gpio_wstrb[2]) begin
                    gpio_data[23:16] <= gpio_wdata[23:16];
                end
                if (gpio_wstrb[3]) begin
                    gpio_data[31:17] <= gpio_wdata[31:17];
                end
            end
        end
    end

    assign led[3:0] = gpio_data[3:0];
    
endmodule
