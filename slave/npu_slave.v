`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 16:56:52
// Design Name: 
// Module Name: npu_slave
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


module npu_slave(
    input  wire        clk,
    input  wire        rst_n,

    // simple_bus侧
    input  wire        npu_request,
    input  wire        npu_re,
    input  wire        npu_we,
    input  wire [3:0]  npu_wstrb,
    input  wire [31:0] npu_addr,
    input  wire [31:0] npu_wdata,

    output wire        npu_ready,
    output wire [31:0] npu_rdata,
    output             npu_irq
);
    // A write
    wire         a_wr_en;
    wire  [5:0]  a_wr_addr;
    wire  [7:0]  awire;
    // B write
    wire         b_wr_en;
    wire  [5:0]  b_wr_addr;
    wire  [7:0]  b_wr_data;

    // C read
    wire [5:0]  c_rd_addr;
    wire [31:0] c_rd_data;

    wire npu_busy;
    wire npu_done;

    npu_mmio u_npu_mmio(
        .clk(clk),
        .rst_n(rst_n),

        // simple_bus侧
        .npu_request(npu_request),
        .npu_re(npu_re),
        .npu_we(npu_we),
        .npu_wstrb(npu_wstrb),
        .npu_addr(npu_addr),
        .npu_wdata(npu_wdata),

        .npu_ready(npu_ready),
        .npu_rdata(npu_rdata),

        // NPU控制
        .npu_start(npu_start),
        .npu_busy(npu_busy),
        .npu_done(npu_done),
        .npu_irq(npu_irq),

        // A write
        .a_wr_en(a_wr_en),
        .a_wr_addr(a_wr_addr),
        .a_wr_data(a_wr_data),

        // B write
        .b_wr_en(b_wr_en),
        .b_wr_addr(b_wr_addr),
        .b_wr_data(b_wr_data),

        // C read
        .c_rd_addr(c_rd_addr),
        .c_rd_data(c_rd_data)
    );

    npu_8x8_top u_npu_8x8_top(
        .clk(clk),
        .rst_n(rst_n),

        .start(npu_start),
        .busy(npu_busy),
        .done(npu_done),

        // Global A write
        .a_wr_en(a_wr_en),
        .a_wr_addr(a_wr_addr),
        .a_wr_data(a_wr_data),

        // Global B write
        .b_wr_en(b_wr_en),
        .b_wr_addr(b_wr_addr),
        .b_wr_data(b_wr_data),

        // Global C read
        .c_rd_addr(c_rd_addr),
        .c_rd_data(c_rd_data)
    );

endmodule
