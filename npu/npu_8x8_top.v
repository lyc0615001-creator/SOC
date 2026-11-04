`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 16:41:59
// Design Name: 
// Module Name: npu_8x8_top
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


module npu_8x8_top(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    start,
    output wire                    busy,
    output wire                    done,

    // Global A write
    input  wire                    a_wr_en,
    input  wire [5:0]              a_wr_addr,
    input  wire signed [7:0]       a_wr_data,

    // Global B write
    input  wire                    b_wr_en,
    input  wire [5:0]              b_wr_addr,
    input  wire signed [7:0]       b_wr_data,

    // Global C read
    input  wire [5:0]              c_rd_addr,
    output wire signed [31:0]      c_rd_data
);

    wire tile_load_start;
    wire tile_load_done;
    wire clear_acc;

    wire compute_start;
    wire compute_done;

    wire store_start;
    wire store_done;

    wire       tile_m;
    wire       tile_n;
    wire       tile_k;

    tiling_controller u_tiling_controller(
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .busy(busy),
        .done(done),

        // Tile Loader
        .tile_load_start(tile_load_start),
        .tile_load_done(tile_load_done),

        // 4x4 compute engine
        .compute_start(compute_start),
        .clear_acc(clear_acc),
        .compute_done(compute_done),

        // C tile store
        .store_start(store_start),
        .store_done(store_done),

        // 当前tile坐标
        .tile_m(tile_m),
        .tile_n(tile_n),
        .tile_k(tile_k)
    );

    // ********************* LOAD ************************

    wire [5:0] gmem_a_rd_addr;
    wire [5:0] gmem_b_rd_addr;

    wire signed [7:0] gmem_a_rd_data;
    wire signed [7:0] gmem_b_rd_data;

    wire       local_a_wr_en;
    wire [3:0] local_a_wr_addr;
    wire signed [7:0] local_a_wr_data;

    wire       local_b_wr_en;
    wire [3:0] local_b_wr_addr;
    wire signed [7:0] local_b_wr_data;

    wire               gmem_c_wr_en;
    wire [5:0]         gmem_c_wr_addr;
    wire signed [31:0] gmem_c_wr_data;

    tile_loader u_tile_loader(
        .clk(clk),
        .rst_n(rst_n),

        .start(tile_load_start),
        .busy(),
        .done(tile_load_done),

        .tile_m(tile_m),
        .tile_n(tile_n),
        .tile_k(tile_k),

        // Global A/B read
        .gmem_a_rd_addr(gmem_a_rd_addr),
        .gmem_a_rd_data(gmem_a_rd_data),

        .gmem_b_rd_addr(gmem_b_rd_addr),
        .gmem_b_rd_data(gmem_b_rd_data),

        // Local A write
        .local_a_wr_en(local_a_wr_en),
        .local_a_wr_addr(local_a_wr_addr),
        .local_a_wr_data(local_a_wr_data),

        // Local B write
        .local_b_wr_en(local_b_wr_en),
        .local_b_wr_addr(local_b_wr_addr),
        .local_b_wr_data(local_b_wr_data)
    );

    // GLOBAL ABC 
    global_mem_a u_global_mem_a(
        .clk(clk),

        .wr_en(a_wr_en),
        .wr_addr(a_wr_addr),
        .wr_data(a_wr_data),

        .rd_addr(gmem_a_rd_addr),
        .rd_data(gmem_a_rd_data)
    );
    global_mem_b u_global_mem_b(
        .clk(clk),

        .wr_en(b_wr_en),
        .wr_addr(b_wr_addr),
        .wr_data(b_wr_data),

        .rd_addr(gmem_b_rd_addr),
        .rd_data(gmem_b_rd_data)
    );
    global_mem_c u_global_mem_c(
        .clk(clk),

        .wr_en(gmem_c_wr_en),
        .wr_addr(gmem_c_wr_addr),
        .wr_data(gmem_c_wr_data),

        .rd_addr(c_rd_addr),
        .rd_data(c_rd_data)
    );


    //******************** COMPUTE ***************
    wire [3:0] local_c_rd_addr;
    wire signed [31:0] local_c_rd_data;

    npu_core_4x4 u_npu_core_4x4(
        .clk(clk),
        .rst_n(rst_n),

        .start(compute_start),
        .clear(clear_acc),
        .busy(),
        .done(compute_done),

        // A矩阵写入口：row-major
        .a_wr_en(local_a_wr_en),
        .a_wr_addr(local_a_wr_addr),
        .a_wr_data(local_a_wr_data),

        // B矩阵写入口：row-major
        .b_wr_en(local_b_wr_en),
        .b_wr_addr(local_b_wr_addr),
        .b_wr_data(local_b_wr_data),

        .rd_addr(local_c_rd_addr),
        .rd_data(local_c_rd_data)
    );

    //******************** STORE ***************
    c_tile_store u_c_tile_store(
        .clk(clk),
        .rst_n(rst_n),

        .start(store_start),
        .busy(),
        .done(store_done),

        .tile_m(tile_m),
        .tile_n(tile_n),

        // Local C Scratchpad
        .local_c_rd_addr(local_c_rd_addr),
        .local_c_rd_data(local_c_rd_data),

        // Global C Memory
        .gmem_c_wr_en(gmem_c_wr_en),
        .gmem_c_wr_addr(gmem_c_wr_addr),
        .gmem_c_wr_data(gmem_c_wr_data)
    );

endmodule
