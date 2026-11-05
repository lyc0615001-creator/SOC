`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 14:46:57
// Design Name: 
// Module Name: npu_mmio
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


module npu_mmio (
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
    output reg  [31:0] npu_rdata,

    // NPU控制
    output wire        npu_start,
    input  wire        npu_busy,
    input  wire        npu_done,
    output             npu_irq,

    // A write
    output reg         a_wr_en,
    output reg  [5:0]  a_wr_addr,
    output reg  [7:0]  a_wr_data,

    // B write
    output reg         b_wr_en,
    output reg  [5:0]  b_wr_addr,
    output reg  [7:0]  b_wr_data,

    // C read
    output wire [5:0]  c_rd_addr,
    input  wire [31:0] c_rd_data
);
    localparam CTRL     = 12'h000;
    localparam STATUS   = 12'h004;
    // offset 0x100~0x1FC  A[0]~A[63]
    // offset 0x200~0x2FC  B[0]~B[63]
    // offset 0x300~0x3FC  C[0]~C[63]

    // 定义中间变量
    reg npu_en;
    reg irq_en;
    reg pending;

    wire [5:0] addr;

    assign addr = npu_addr[7:2];

    // 定义状态
    wire mimo_write;
    wire mimo_read;

    assign mimo_write = npu_we && (npu_wstrb == 4'b1111) && npu_request;
    assign mimo_read  = npu_re &&  npu_request;

    assign npu_ready = npu_request;

    assign npu_start = !npu_busy && npu_en;

    assign c_rd_addr = re_c ? addr : 6'd0;

    wire npu_clear;

    assign npu_clear = wr_status && npu_wdata[1];

    assign npu_irq = pending && irq_en;

    //定义事件
    wire wr_ctrl;
    wire wr_status;
    wire wr_a;
    wire wr_b;

    wire re_c;

    assign wr_ctrl   = mimo_write && (npu_addr[11:0] == CTRL);
    assign wr_status = mimo_write && (npu_addr[11:0] == STATUS);
    assign wr_a      = mimo_write && (npu_addr[11:8] == 4'd1) && (npu_addr[1:0] == 2'b00);
    assign wr_b      = mimo_write && (npu_addr[11:8] == 4'd2) && (npu_addr[1:0] == 2'b00);
    
    assign re_c      = mimo_read  && (npu_addr[11:8] == 4'd3) && (npu_addr[1:0] == 2'b00);


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            npu_en <= 1'd0;
            irq_en <= 1'd0;

            a_wr_en   <= 1'd0;
            a_wr_addr <= 6'd0;
            a_wr_data <= 8'd0;

            b_wr_en   <= 1'd0;
            b_wr_addr <= 6'd0;
            b_wr_data <= 8'd0;
        end else begin
            npu_en <= 1'd0;
            a_wr_en   <= 1'd0;
            b_wr_en   <= 1'd0;

            if (wr_ctrl) begin
                npu_en <= npu_wdata[0];
                irq_en <= npu_wdata[1];
            end
            if (wr_a) begin
                a_wr_en   <= 1'd1;
                a_wr_addr <= addr;
                a_wr_data <= npu_wdata[7:0];
            end
            if (wr_b) begin
                b_wr_en   <= 1'd1;
                b_wr_addr <= addr;
                b_wr_data <= npu_wdata[7:0];
            end
        end
    end

    always @(*) begin
        npu_rdata = 32'd0;
        if (mimo_read) begin
            case (npu_addr[11:0])
                CTRL: begin
                    npu_rdata = {30'd0, irq_en, 1'b0};
                end
                STATUS: begin
                    npu_rdata = {30'd0, pending, npu_busy};
                end
                default: npu_rdata = 32'd0;
            endcase
            if (re_c) begin
                npu_rdata = c_rd_data;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'd0;
        end else begin
            if (npu_done) begin
                pending <= 1'd1;
            end else if (npu_clear) begin
                pending <= 1'd0;
            end  
        end
    end
endmodule
