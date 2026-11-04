`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 14:54:59
// Design Name: 
// Module Name: tiling_controller
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


module tiling_controller(
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    output wire busy,
    output wire done,

    // Tile Loader
    output reg tile_load_start,
    input  wire tile_load_done,

    // 4x4 compute engine
    output wire compute_start,
    output wire clear_acc,
    input  wire compute_done,

    // C tile store
    output reg store_start,
    input  wire store_done,

    // 当前tile坐标
    output reg  tile_m,
    output reg  tile_n,
    output reg  tile_k
);

    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam COMPUTE_START = 3'd2;
    localparam COMPUTE_WAIT  = 3'd3;
    localparam STORE  = 3'd4;
    localparam DONE  = 3'd5;

    localparam M_CHECK = 1'b1;
    localparam N_CHECK = 1'b1;
    localparam K_CHECK = 1'b1;

    reg [2:0] state;

    // 中间变量


    // 定义状态
    assign busy = (state != IDLE) && (state != DONE);
    assign done = state == DONE;

    assign compute_start = state == COMPUTE_START;
    assign clear_acc = (state == COMPUTE_START) && tile_k == 1'b0;

    // 定义事件

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            tile_m <= 1'd0;
            tile_n <= 1'd0;
            tile_k <= 1'd0;

            tile_load_start <= 1'b0;
            store_start <= 1'b0;
        end else begin
            tile_load_start <= 1'b0;
            store_start <= 1'b0;
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD;
                        tile_load_start <= 1'b1;
                    end
                end
                LOAD: begin
                    if (tile_load_done) begin
                        state <= COMPUTE_START;
                    end
                end
                COMPUTE_START: begin
                    state <= COMPUTE_WAIT;
                end
                COMPUTE_WAIT: begin
                    if (compute_done) begin
                        if (tile_k == K_CHECK) begin
                            tile_k <= 1'b0;

                            state <= STORE;
                            store_start <= 1'b1;
                        end else begin
                            tile_k <= tile_k + 1'b1;

                            state <= LOAD;
                            tile_load_start <= 1'b1;
                        end
                    end
                end
                STORE: begin
                    if (store_done) begin
                        if (tile_n == N_CHECK) begin
                            if (tile_m == M_CHECK) begin
                                tile_m <= 1'b0;
                                tile_n <= 1'b0;

                                state <= DONE;
                            end else begin
                                tile_m <= tile_m + 1'b1;
                                tile_n <= 1'b0;

                                state <= LOAD;
                                tile_load_start <= 1'b1;
                            end
                        end else begin
                            tile_n <= tile_n + 1'b1;

                            state <= LOAD;
                            tile_load_start <= 1'b1;
                        end
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;

                    tile_m <= 1'd0;
                    tile_n <= 1'd0;
                    tile_k <= 1'd0;

                    tile_load_start <= 1'b0;
                    store_start <= 1'b0;
                end
            endcase
        end
    end




endmodule
