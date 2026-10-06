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
        input               gpio_request,
        input               gpio_re,
        input               gpio_we,
        input       [3:0]   gpio_wstrb,
        input       [7:0]   gpio_addr,
        input       [31:0]  gpio_wdata,
        output              gpio_ready,
        output reg  [31:0]  gpio_rdata,
        output      [3:0]   led
    );

    localparam GPIO_ADDR = 8'b0;

    reg [31:0] gpio_data;

    wire re_gpio;
    wire we_gpio;
    assign re_gpio = gpio_request && gpio_re && gpio_addr == GPIO_ADDR;
    assign we_gpio = gpio_request && gpio_we && gpio_addr == GPIO_ADDR;

    assign gpio_ready = gpio_request;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            gpio_data <= 32'd0;
        end
        else begin
            if (we_gpio) begin
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
                    gpio_data[31:24] <= gpio_wdata[31:24];
                end
            end
        end
    end


    always @(*) begin
        gpio_rdata = 32'b0;
        if (re_gpio) begin
            gpio_rdata = gpio_data;
        end
    end

    assign led[3:0] = gpio_data[3:0];
    
endmodule
