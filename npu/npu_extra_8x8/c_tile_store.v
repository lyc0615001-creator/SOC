`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 16:23:21
// Design Name: 
// Module Name: c_tile_store
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


module c_tile_store(
    input  wire               clk,
    input  wire               rst_n,

    input  wire               start,
    output wire               busy,
    output wire               done,

    input  wire               tile_m,
    input  wire               tile_n,

    // Local C Scratchpad
    output wire [3:0]         local_c_rd_addr,
    input  wire signed [31:0] local_c_rd_data,

    // Global C Memory
    output wire               gmem_c_wr_en,
    output wire [5:0]         gmem_c_wr_addr,
    output wire signed [31:0] gmem_c_wr_data
);
    localparam IDLE = 2'd0;
    localparam STORE = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    reg [3:0] store_cnt;

    reg tile_m_reg;
    reg tile_n_reg;

    // 定义状态
    assign busy = state == STORE;
    assign done = state == DONE;

    
    assign local_c_rd_addr = store_cnt;

    assign gmem_c_wr_en = state == STORE;

    assign gmem_c_wr_addr = {tile_m_reg, store_cnt[3:2], tile_n_reg, store_cnt[1:0]};

    assign gmem_c_wr_data = local_c_rd_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            store_cnt <= 4'd0;

            tile_m_reg <= 1'd0;
            tile_n_reg <= 1'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= STORE;
                        store_cnt <= 4'd0;

                        tile_m_reg <= tile_m;
                        tile_n_reg <= tile_n;
                    end
                end
                STORE: begin
                    if (store_cnt == 4'd15) begin
                        state <= DONE;
                        store_cnt <= 4'd0;
                    end else begin
                        store_cnt <= store_cnt + 4'd1;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                    store_cnt <= 4'd0;
                end
            endcase
        end
    end

endmodule
