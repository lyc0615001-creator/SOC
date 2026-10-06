`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 20:07:07
// Design Name: 
// Module Name: uart_mmio
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


module uart_mmio(
        input              clk,
        input              rst,

        // bus side
        input              uart_request,
        input              uart_re,
        input              uart_we,
        input       [3:0]  uart_wstrb,
        input       [7:0]  uart_addr,
        input       [31:0] uart_wdata,
        output  reg        uart_ready,
        output  reg [31:0] uart_rdata,
        
        // uart tx side
        output  reg [7:0]  tx_data,
        output  reg        tx_start,
        input              tx_busy,

        // uart rx side
        input       [7:0]  rx_data,
        input              rx_valid
    );

    localparam DATA_ADDR = 8'd0;
    localparam STATUS_ADDR = 8'd4;

    wire tx_ready;
    reg rx_ready;
    reg [7:0] rx_data_reg;

    assign tx_ready = ~(tx_busy | tx_start);

    wire re_uart;
    wire we_uart;
    wire tx_we_fire;
    wire rx_re_fire;

    assign re_uart = uart_re && uart_request;

    assign we_uart = uart_we && uart_request;
    
    assign tx_we_fire = we_uart && uart_addr == DATA_ADDR && tx_ready && uart_wstrb[0];

    assign rx_re_fire = re_uart && uart_addr == DATA_ADDR && rx_ready;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            tx_start <= 1'b0;
            tx_data <= 8'd0;

            rx_ready <= 1'b0;
            rx_data_reg <= 8'd0;
        end else begin
            tx_start <= 1'b0;

            // uart tx
            if (tx_we_fire) begin
                tx_data <= uart_wdata[7:0];
                tx_start <= 1'b1;
            end

            // uart rx 接收新数据
            if (rx_valid) begin
                rx_ready <= 1'b1;
                rx_data_reg <= rx_data;
            end

            if (rx_re_fire) begin
                rx_ready <= 1'b0;
            end

        end
    end

    always @(*) begin
        uart_ready = 1'b0;
        uart_rdata = 32'd0;
        if (re_uart) begin
            case (uart_addr)
                DATA_ADDR: begin
                    uart_ready = rx_ready;
                    if (rx_ready) begin
                        uart_rdata = {24'd0, rx_data_reg};
                    end
                end
                STATUS_ADDR: begin
                    uart_ready = 1'b1;
                    uart_rdata = {30'd0, rx_ready, tx_ready};
                end
                default: begin
                    uart_ready = 1'b1;
                    uart_rdata = 32'd0;
                end
            endcase
        end else if (we_uart) begin
            case (uart_addr)
                DATA_ADDR: begin
                    uart_ready = tx_ready;
                end
                default: begin
                    uart_ready = 1'b1;
                end
            endcase
        end
    end

endmodule
