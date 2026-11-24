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
        input  wire [1:0]  m_resp,

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

    reg [1:0] state;

    reg [31:0] src_addr;
    reg [31:0] dst_addr;
    reg [31:0] length;

    // 定义中间变量
    // s侧
    reg dma_en;
    reg irq_en;
    reg pending;

    wire s_write;
    wire s_read;

    assign s_write = s_request && s_we && (s_wstrb == 4'b1111);
    assign s_read  = s_request && s_re;

    wire dma_clear;
    wire dma_busy;

    assign dma_clear = s_write && (s_addr == STATUS) && s_wdata[1];
    assign dma_busy = (state != IDLE);

    // m侧
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

    assign m_request  = m_re | m_we;
    assign m_re   = state == READ;
    assign m_addr = m_re ? cur_src :
                    m_we ? cur_dst : 32'd0;

    assign m_we   = state == WRITE;
    assign m_wstrb = 4'b1111;
    assign m_wdata = data_buf;


    // 定义状态
    assign s_ready = s_request;

    assign dma_irq = pending && irq_en;

    // =======================
    // 11-24 异常判断与处理
    localparam RESP_OKAY   = 2'b00;

    reg       error;
    reg [1:0] error_resp;

    wire dma_bus_error;

    assign dma_bus_error = m_ready && (m_resp != RESP_OKAY);

    wire dma_finish;

    assign dma_finish =
       (m_read_done  && dma_bus_error)
    || (m_write_done && dma_bus_error)
    || (m_write_done && !dma_bus_error && reach_top);

    // =====================
    // 11-24 最小配置保护
    wire start_req;

    assign start_req = s_write && (s_addr == CTRL) && s_wdata[0];

    reg cfg_error;

    wire cfg_fault_event;

    assign cfg_fault_event =
        (start_req && (dma_busy || !config_valid))
        || (s_write &&
            (s_addr == SRC_ADDR ||
            s_addr == DST_ADDR ||
            s_addr == LENGTH) &&
            dma_busy);

    
    // 长度合法
    wire legal_length;
    assign legal_length = (length != 0) && (length[1:0] == 2'b00);

    wire addr_ok;

    assign addr_ok = (src_addr[1:0] == 2'b00) && (dst_addr[1:0] == 2'b00);

    wire [32:0] src_last;
    wire [32:0] dst_last;

    assign src_last = {1'b0, src_addr} + {1'b0, length} - 33'd1;

    assign dst_last = {1'b0, dst_addr} + {1'b0, length} - 33'd1;

    wire src_range_ok;
    wire dst_range_ok;

    // ram 0x0001_0000 ~ 0x0001_FFFF
    // npu 0x4000_0000 ~ 0x4000_0FFF  A(wr) 0x100~0x1FC B(wr) 0x200~0x2FC  C(read) 0x300~0x3FC
    // ddr 0x8000_0000 ~ 0x87FF_FFFF
    assign src_range_ok = ((src_addr[31:16] == 16'h0001) && (src_last[31:16] == 16'h0001))
                    || ((src_addr[31:8] == 24'h400003) && (src_last[31:8] == 24'h400003))
                    || ((src_addr[31:27] == 5'b10000) && (src_last[31:27] == 5'b10000));
    
    assign dst_range_ok = ((dst_addr[31:16] == 16'h0001) && (dst_last[31:16] == 16'h0001))
                    || ((dst_addr[31:8] == 24'h400001 || dst_addr[31:8] == 24'h400002) && (dst_last[31:8] == 24'h400001 || dst_last[31:8] == 24'h400002))
                    || ((dst_addr[31:27] == 5'b10000) && (dst_last[31:27] == 5'b10000));

    // 地址合法
    wire legal_addr;
    assign legal_addr = addr_ok && src_range_ok && dst_range_ok;

    // 禁止重叠 越界
    wire no_overlap;
    assign no_overlap = ((src_last < {1'b0, dst_addr}) || (dst_last < {1'b0, src_addr}));

    wire no_overflow;

    assign no_overflow = !src_last[32] && !dst_last[32];

    wire config_valid;

    assign config_valid = legal_length && legal_addr && no_overlap && no_overflow;


    // 配置 slave侧
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_en <= 1'd0;
            irq_en <= 1'd0;

            src_addr <= 32'd0;
            dst_addr <= 32'd0;
            length <= 32'd0;

            cfg_error <= 1'b0;
        end else begin
            dma_en <= 1'd0;

            // cfg_error维护
            if (cfg_fault_event)
                cfg_error <= 1'b1;
            else if (dma_clear)
                cfg_error <= 1'b0;

            // MMIO配置写
            if (s_write) begin
                case (s_addr)
                    CTRL: begin
                        irq_en <= s_wdata[1];
                        if (start_req && !dma_busy && config_valid) begin
                            dma_en <= s_wdata[0];
                        end
                    end
                    SRC_ADDR: begin
                        if (!dma_busy) begin
                            src_addr <= s_wdata;
                        end
                    end
                    DST_ADDR: begin
                        if (!dma_busy) begin
                            dst_addr <= s_wdata;
                        end
                    end
                    LENGTH: begin
                        if (!dma_busy) begin
                            length   <= s_wdata;
                        end
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
                STATUS: s_rdata = {26'd0, cfg_error, error_resp, error, pending, dma_busy};
                SRC_ADDR: s_rdata = src_addr;
                DST_ADDR: s_rdata = dst_addr;
                LENGTH: s_rdata = length;
                default: ;
            endcase
        end
    end

    // master侧
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            data_buf <= 32'd0;
            
            cur_src <= 32'd0;
            cur_dst <= 32'd0;
            remaining <= 32'd0;

            error      <= 1'b0;
            error_resp <= RESP_OKAY;
        end else begin
            case (state)
                IDLE: begin
                    if (dma_en) begin
                        state <= READ;

                        cur_src <= src_addr;
                        cur_dst <= dst_addr;
                        remaining <= length;

                        error      <= 1'b0;
                        error_resp <= RESP_OKAY;
                    end
                end
                READ: begin
                    if (m_read_done) begin
                        if (dma_bus_error) begin
                            // error
                            error      <= 1'b1;
                            error_resp <= m_resp;
                            state <= IDLE;
                        end
                        else begin
                            state <= WRITE;

                            // 保存数据
                            data_buf  <= m_rdata;
                        end
                    end
                end
                WRITE: begin
                    if (m_write_done) begin
                        if (dma_bus_error) begin
                            // error
                            error      <= 1'b1;
                            error_resp <= m_resp;
                            state <= IDLE;
                        end
                        else begin
                            if (reach_top) begin
                                state <= IDLE;

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
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'd0;
        end else begin
            if (dma_finish) begin
                pending <= 1'd1;
            end else if (dma_clear) begin
                pending <= 1'd0;
            end  
        end
    end

endmodule
