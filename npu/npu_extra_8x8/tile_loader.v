`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 11:30:21
// Design Name: 
// Module Name: tile_loader
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


module tile_loader(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       start,
    output wire       busy,
    output wire       done,

    input  wire       tile_m,
    input  wire       tile_n,
    input  wire       tile_k,

    // Global A/B read
    output wire [5:0] gmem_a_rd_addr,
    input  wire signed [7:0] gmem_a_rd_data,

    output wire [5:0] gmem_b_rd_addr,
    input  wire signed [7:0] gmem_b_rd_data,

    // Local A write
    output wire       local_a_wr_en,
    output wire [3:0] local_a_wr_addr,
    output wire signed [7:0] local_a_wr_data,

    // Local B write
    output wire       local_b_wr_en,
    output wire [3:0] local_b_wr_addr,
    output wire signed [7:0] local_b_wr_data
);

    localparam IDLE = 2'd0;
    localparam LOAD = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    reg [3:0] load_cnt;

    reg tile_m_reg;
    reg tile_n_reg;
    reg tile_k_reg;

    // 定义状态
    assign busy = state == LOAD;
    assign done = state == DONE;

    assign gmem_a_rd_addr = {tile_m_reg, load_cnt[3:2], tile_k_reg, load_cnt[1:0]};
    assign gmem_b_rd_addr = {tile_k_reg, load_cnt[3:2], tile_n_reg, load_cnt[1:0]};

    assign local_a_wr_en = state == LOAD;
    assign local_b_wr_en = state == LOAD;

    assign local_a_wr_addr = load_cnt;
    assign local_b_wr_addr = load_cnt;

    assign local_a_wr_data = gmem_a_rd_data;
    assign local_b_wr_data = gmem_b_rd_data;

    // 定义事件
    wire fire;

    assign fire = start;

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            load_cnt <= 4'd0;

            tile_m_reg <= 1'd0;
            tile_n_reg <= 1'd0;
            tile_k_reg <= 1'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (fire) begin
                        state <= LOAD;
                        load_cnt <= 4'd0;

                        tile_m_reg <= tile_m;
                        tile_n_reg <= tile_n;
                        tile_k_reg <= tile_k;
                    end
                end
                LOAD: begin
                    if (load_cnt == 4'd15) begin
                        state <= DONE;
                        load_cnt <= 4'd0;
                    end else begin
                        load_cnt <= load_cnt + 4'd1;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                    load_cnt <= 4'd0;
                end
            endcase
        end
    end
endmodule
