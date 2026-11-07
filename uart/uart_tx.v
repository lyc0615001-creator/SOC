`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 15:42:06
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
        input           clk,
        input           rst,
        input           tick_16x,

        input     [7:0] tx_data,
        input           tx_start,

        output      reg tx,
        output      reg tx_busy
    );

    localparam T_LAST = 15;
    localparam DATA_WIDTH_LAST = 7;
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] tx_status;
    reg [3:0] tx_cnt;
    reg [2:0] tx_bit_cnt;

    reg [7:0] tx_data_buf;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            tx <= 1'b1;
            tx_busy <= 1'b0;

            tx_status <= IDLE;
            tx_cnt <= 4'b0000;
            tx_bit_cnt <= 2'b00;

            tx_data_buf <= 8'b0;
        end else begin
            case (tx_status)
                IDLE: begin // 准备状态
                    if (tx_start) begin
                        // lock data
                        tx_data_buf <= tx_data;

                        // modify status
                        tx_status <= START;
                        tx_busy <= 1'b1;

                        tx <= 1'b0; // init next stage
                    end
                end 
                START: begin // 即将开始发送数据
                    if (tick_16x) begin
                        if (tx_cnt == T_LAST) begin
                            // modify tx_status
                            tx_status <= DATA;
                            tx_bit_cnt <= 2'b00;

                            tx_cnt <= 4'b0; // cnt reset

                            tx <= tx_data_buf[0]; // init next stage
                        end else begin
                            tx_cnt <= tx_cnt + 4'b1;
                        end
                    end
                end
                DATA: begin // 发送数据
                    if (tick_16x) begin
                        if (tx_cnt == T_LAST) begin
                            tx_cnt <= 4'b0; // cnt reset

                            if (tx_bit_cnt == DATA_WIDTH_LAST) begin
                                // modify tx_status
                                tx_status <= STOP;

                                tx <= 1'b1; // init next stage

                                tx_bit_cnt <= 2'b00; // cnt reset
                            end else begin
                                // *************send data*************
                                tx <= tx_data_buf[tx_bit_cnt + 2'b01];
                                tx_bit_cnt <= tx_bit_cnt + 2'b01;
                            end
                        end else begin
                            tx_cnt <= tx_cnt + 4'b1;
                        end
                    end
                    
                end
                STOP: begin // 恢复正常，进入准备
                    if (tick_16x) begin
                        if (tx_cnt == T_LAST) begin
                            // modify tx_status
                            tx_status <= IDLE;
                            tx_busy <= 1'b0;

                            tx_cnt <= 4'b0; // cnt reset
                        end else begin
                            tx_cnt <= tx_cnt + 4'b1;
                        end
                    end
                end
                default: begin
                    tx_status <= 2'b00;
                    tx_cnt <= 4'b0;
                    tx_bit_cnt <= 2'b00;

                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                end
            endcase
        end
    end
endmodule
