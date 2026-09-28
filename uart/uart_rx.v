`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/24 18:07:18
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
        input            clk,
        input            rst,
        input            tick_16x,

        input            rx,

        output reg [7:0] rx_data,
        output reg       rx_valid
    );

    // (* ASYNC_REG = "TRUE" *) reg  rx_ff1;
    // (* ASYNC_REG = "TRUE" *) reg  rx_ff2;
    reg  rx_ff1;
    reg  rx_ff2;
    

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rx_ff1 <= 1'b1;
            rx_ff2 <= 1'b1;
        end else begin
            rx_ff1 <= rx;
            rx_ff2 <= rx_ff1;
        end
    end

    localparam T_LAST = 15;
    localparam DATA_WIDTH_LAST = 7;
    localparam HALF_T_LAST = 7;
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    wire rx_sync;
    assign rx_sync = rx_ff2;

    reg [1:0] rx_status;
    reg [3:0] rx_cnt;

    reg [2:0] rx_bit_cnt;
    reg [7:0] rx_data_buf;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rx_data <= 8'd0;
            rx_valid <= 1'b0;

            rx_status <= IDLE;

            rx_cnt <= 4'd0;
            rx_bit_cnt <= 3'd0;
            rx_data_buf <= 8'd0;
        end else begin
            rx_valid <= 1'b0;
            case (rx_status)
                IDLE: begin
                    if (rx_sync == 1'b0) begin
                        // modify rx_status
                        rx_status <= START;
                        
                        // init next stage
                        rx_cnt <= 4'd0;
                    end
                end
                START: begin
                    if (tick_16x) begin
                        if (rx_cnt == HALF_T_LAST) begin
                            // 半个分频周期后，判断是否依旧是0
                            if (rx_sync == 1'b0) begin
                                // modify rx_status 
                                rx_status <= DATA;
                                
                                rx_cnt <= 4'd0; // reset

                                rx_bit_cnt <= 3'd0; // init next stage
                            end else begin
                                rx_status <= IDLE;
                                rx_cnt <= 4'd0;
                            end
                        end else begin
                            rx_cnt <= rx_cnt + 4'd1;
                        end
                    end
                    
                end
                DATA: begin
                    if (tick_16x) begin
                        if (rx_cnt == T_LAST) begin
                            // **********recept data************
                            rx_data_buf[rx_bit_cnt] <= rx_sync;
                            
                            rx_cnt <= 4'd0; // reset

                            if (rx_bit_cnt == DATA_WIDTH_LAST) begin
                                // modify statue
                                rx_status <= STOP;

                                rx_bit_cnt <= 3'd0; // reset 
                            end else begin
                                rx_bit_cnt <= rx_bit_cnt + 3'd1;
                            end
                        end else begin
                            rx_cnt <= rx_cnt + 4'd1;
                        end
                    end
                end
                STOP: begin
                    if (tick_16x) begin
                        if (rx_cnt == T_LAST) begin
                            // modify status 
                            rx_status <= IDLE;

                            rx_cnt <= 4'd0; // reset
                            if (rx_sync == 1'b1) begin
                                // assign 
                                rx_data <= rx_data_buf;
                                rx_valid <= 1'b1;
                            end
                        end else begin
                            rx_cnt <= rx_cnt + 4'd1;
                        end
                    end
                end
                default: begin
                    rx_data <= 8'd0;
                    rx_valid <= 1'b0;

                    rx_status <= IDLE;

                    rx_cnt <= 4'd0;
                    rx_bit_cnt <= 3'd0;
                    rx_data_buf <= 8'd0;
                end
            endcase
        end
    end
endmodule
