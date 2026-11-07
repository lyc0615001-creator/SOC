`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 15:09:52
// Design Name: 
// Module Name: npu_controller
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


module npu_controller(
        input  wire                   clk,
        input  wire                   rst_n,
        // output wire                   clear,

        input  wire                   start,
        output wire                   busy,
        output wire                   done,

        output reg [2:0]              cycle_cnt,

        // 结果矩阵
        input wire signed [31:0]      c00,
        input wire signed [31:0]      c01,
        input wire signed [31:0]      c02,
        input wire signed [31:0]      c03,

        input wire signed [31:0]      c10,
        input wire signed [31:0]      c11,
        input wire signed [31:0]      c12,
        input wire signed [31:0]      c13,

        input wire signed [31:0]      c20,
        input wire signed [31:0]      c21,
        input wire signed [31:0]      c22,
        input wire signed [31:0]      c23,

        input wire signed [31:0]      c30,
        input wire signed [31:0]      c31,
        input wire signed [31:0]      c32,
        input wire signed [31:0]      c33,

        output  wire                  wr_en,
        output  wire [3:0]            wr_addr,
        output  reg  signed [31:0]    wr_data
    );

    localparam IDLE     = 3'd0;
    // localparam CLEAR    = 3'd1;
    localparam FEED     = 3'd2;
    localparam DRAIN    = 3'd3;
    localparam STORE    = 3'd4;
    localparam DONE     = 3'd5;

    localparam FEED_CYCLE  = 3'd6;
    localparam DRAIN_CYCLE = 3'd3;

    reg [2:0] state;
    reg [2:0] drain_cnt;

    reg [3:0] store_cnt;

    // 中间变量

    // 定义状态
    assign busy  = (state != IDLE) && (state != DONE);
    // assign clear = state == CLEAR;
    assign done  = state == DONE;

    assign wr_en = state == STORE;
    assign wr_addr = store_cnt;
    

    // 定义事件
    wire begin_affairs;
    assign begin_affairs = start;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cycle_cnt <= 3'd7;
            drain_cnt <= 3'd0;
            store_cnt <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (begin_affairs) begin
                        state <= FEED;
                    end
                end
                // CLEAR: begin
                //     state <= FEED;
                //     cycle_cnt <= 3'd0;
                // end
                FEED: begin
                    if (cycle_cnt == FEED_CYCLE) begin
                        cycle_cnt <= 3'd7;
                        state <= DRAIN;
                    end else begin
                        cycle_cnt <= cycle_cnt + 3'd1;
                    end
                end
                DRAIN: begin
                    if (drain_cnt == DRAIN_CYCLE) begin
                        drain_cnt <= 3'd0;
                        state <= STORE;
                    end else begin
                        drain_cnt <= drain_cnt + 3'd1;
                    end
                end
                STORE: begin
                    if (store_cnt == 4'd15) begin
                        store_cnt <= 4'd0;
                        state     <= DONE;
                    end else begin
                        store_cnt <= store_cnt + 4'd1;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                    cycle_cnt <= 3'd7;
                    drain_cnt <= 3'd0;
                end
            endcase
        end
    end

    always @(*) begin
        case (store_cnt)
            4'd0:  wr_data = c00;
            4'd1:  wr_data = c01;
            4'd2:  wr_data = c02;
            4'd3:  wr_data = c03;
            4'd4:  wr_data = c10;
            4'd5:  wr_data = c11;
            4'd6:  wr_data = c12;
            4'd7:  wr_data = c13;
            4'd8:  wr_data = c20;
            4'd9:  wr_data = c21;
            4'd10: wr_data = c22;
            4'd11: wr_data = c23;
            4'd12: wr_data = c30;
            4'd13: wr_data = c31;
            4'd14: wr_data = c32;
            4'd15: wr_data = c33;
            default: ;
        endcase
    end
endmodule
