`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 19:35:46
// Design Name: 
// Module Name: dma_slave
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


module dma_slave(
    input  wire        clk,
    input  wire        rst_n,

    // =========================
    // CPU / MMIO Slave Port
    // =========================
    input  wire        s_request,
    input  wire        s_re,
    input  wire        s_we,
    input  wire [3:0]  s_wstrb,
    input  wire [7:0]  s_addr,
    input  wire [31:0] s_wdata,

    output wire        s_ready,
    output wire [31:0] s_rdata,

    // =========================
    // Bus Master Port
    // =========================
    output wire        m_request,
    output wire        m_re,
    output wire        m_we,
    output wire [3:0]  m_wstrb,
    output wire [31:0] m_addr,
    output wire [31:0] m_wdata,

    input  wire        m_ready,
    input  wire [31:0] m_rdata,

    // =========================
    // Status
    // =========================
    output wire        dma_irq
);


    dma_engine u_dma_engine(
        .clk(clk),
        .rst_n(rst_n),

        // =========================
        // CPU / MMIO Slave Port
        // =========================
        .s_request(s_request),
        .s_re(s_re),
        .s_we(s_we),
        .s_wstrb(s_wstrb),
        .s_addr(s_addr),
        .s_wdata(s_wdata),

        .s_ready(s_ready),
        .s_rdata(s_rdata),

        // =========================
        // Bus Master Port
        // =========================
        .m_request(m_request),
        .m_re(m_re),
        .m_we(m_we),
        .m_wstrb(m_wstrb),
        .m_addr(m_addr),
        .m_wdata(m_wdata),

        .m_ready(m_ready),
        .m_rdata(m_rdata),

        // =========================
        // Status
        // =========================
        .dma_irq(dma_irq)
    );
endmodule
