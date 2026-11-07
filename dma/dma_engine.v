`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 16:07:12
// Design Name: 
// Module Name: dma_engine
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


module dma_engine(
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
        output reg  [31:0] s_rdata,

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

    localparam CTRL     = 8'h00;
    localparam STATUS   = 8'h04;
    localparam SRC_ADDR = 8'h08;
    localparam DST_ADDR = 8'h0C;
    localparam LENGTH   = 8'h10;

    localparam IDLE  = 2'd0;
    localparam READ  = 2'd1;
    localparam WRITE = 2'd2;
    localparam DONE  = 2'd3;

    reg [1:0] state;

    reg [31:0] src_addr;
    reg [31:0] dst_addr;
    reg [31:0] length;

    // 定义中间变量

    reg dma_en;
    reg irq_en;
    reg pending;

    wire s_write;
    wire s_read;

    assign s_write = s_request && s_we && (s_wstrb == 4'b1111);
    assign s_read  = s_request && s_re;

    wire dma_done;
    wire dma_clear;
    wire dma_busy;

    assign dma_done = state == DONE;
    assign dma_clear = s_write && (s_addr == STATUS) && s_wdata[1];
    assign dma_busy = (state != IDLE) && (state != DONE);


    // 定义状态
    assign s_ready = s_request;

    assign dma_irq = pending && irq_en;

    // 定义事件
    wire wr_ctrl;

    assign wr_ctrl   = s_write && s_addr == CTRL;


    // 配置 slave侧
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_en <= 1'd0;
            irq_en <= 1'd0;

            src_addr <= 32'd0;
            dst_addr <= 32'd0;
            length <= 32'd0;
        end else begin
            dma_en <= 1'd0;

            if (s_write) begin
                case (s_addr)
                    CTRL: begin
                        dma_en <= s_wdata[0];
                        irq_en <= s_wdata[1];
                    end
                    SRC_ADDR: begin
                        src_addr <= s_wdata;
                    end
                    DST_ADDR: begin
                        dst_addr <= s_wdata;
                    end
                    LENGTH: begin
                        length   <= s_wdata;
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        s_rdata = 32'd0;
        if (s_read) begin
            case (s_addr)
                CTRL: s_rdata = {30'd0, irq_en, 1'b0};
                STATUS: s_rdata = {30'd0, pending, dma_busy};
                SRC_ADDR: s_rdata = src_addr;
                DST_ADDR: s_rdata = dst_addr;
                LENGTH: s_rdata = length;
                default: ;
            endcase
        end
    end

    // 中间变量
    reg [31:0] data_buf;

    reg [31:0] cur_src;
    reg [31:0] cur_dst;
    reg [31:0] remaining;

    wire m_read_done;
    wire m_write_done;

    wire reach_top;

    assign m_read_done  = m_ready && m_re;
    assign m_write_done = m_ready && m_we;

    assign reach_top = remaining == 32'd4;

    // 定义状态
    assign m_request  = m_re | m_we;
    assign m_re   = state == READ;
    assign m_addr = m_re ? cur_src :
                    m_we ? cur_dst : 32'd0;

    assign m_we   = state == WRITE;
    assign m_wstrb = 4'b1111;
    assign m_wdata = data_buf;

    // master侧
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            data_buf <= 32'd0;
            
            cur_src <= 32'd0;
            cur_dst <= 32'd0;
            remaining <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (dma_en) begin
                        state <= READ;

                        cur_src <= src_addr;
                        cur_dst <= dst_addr;
                        remaining <= length;
                    end
                end
                READ: begin
                    if (m_read_done) begin
                        state <= WRITE;

                        // 保存数据
                        data_buf  <= m_rdata;
                    end
                end
                WRITE: begin
                    if (m_write_done) begin

                        if (reach_top) begin
                            state <= DONE;

                            cur_src <= 32'd0;
                            cur_dst <= 32'd0;
                        end else begin
                            state <= READ;

                            cur_src <= cur_src + 32'd4;
                            cur_dst <= cur_dst + 32'd4;
                            remaining <= remaining - 32'd4;
                        end
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'd0;
        end else begin
            if (dma_done) begin
                pending <= 1'd1;
            end else if (dma_clear) begin
                pending <= 1'd0;
            end  
        end
    end



endmodule
