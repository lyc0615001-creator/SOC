`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 21:05:55
// Design Name: 
// Module Name: uart
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


module uart(
        input              clk,
        input              rst,

        // bus interface
        input              uart_request,
        input              uart_re,
        input              uart_we,
        input       [3:0]  uart_wstrb,
        input       [7:0]  uart_addr,
        input       [31:0] uart_wdata,
        output             uart_ready,
        output      [31:0] uart_rdata,

        // physical pins
        input              rx,
        output             tx
    );

    wire tick_16x;

    // uart tx side
    wire [7:0]  tx_data;
    wire        tx_start;
    wire        tx_busy;

    // uart rx side
    wire       [7:0]  rx_data;
    wire              rx_valid;


    //==================================================
    // uart_mmio instance
    //==================================================
    uart_mmio u_uart_mmio(
        .clk(clk),
        .rst(rst),

        // bus side
        .uart_request(uart_request),
        .uart_re(uart_re),
        .uart_we(uart_we),
        .uart_wstrb(uart_wstrb),
        .uart_addr(uart_addr),
        .uart_wdata(uart_wdata),
        .uart_ready(uart_ready),
        .uart_rdata(uart_rdata),
        
        // uart tx side
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        // uart rx side
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );


    //==================================================
    // uart_tx instance
    //==================================================
    uart_tx u_uart_tx(
        .clk(clk),
        .rst(rst),
        .tick_16x(tick_16x),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx(tx),
        .tx_busy(tx_busy)
    );

    //==================================================
    // uart_rx instance
    //==================================================
    uart_rx u_uart_rx(
        .clk(clk),
        .rst(rst),
        .tick_16x(tick_16x),

        .rx(rx),

        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );
    

    //==================================================
    // baud_gen instance
    //==================================================
    baud_gen u_baud_gen(
        .clk(clk),
        .rst(rst),
        .tick_16x(tick_16x)
    );

endmodule
