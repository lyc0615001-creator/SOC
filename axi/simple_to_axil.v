module simple_to_axil (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         s_source, // 0: CPU, 1: DMA

    // =========================
    // simple request side
    // =========================
    input  wire         s_request,
    input  wire         s_read,
    input  wire         s_write,
    input  wire [31:0]  s_addr,
    input  wire [31:0]  s_wdata,
    input  wire [3:0]   s_wstrb,

    output reg          s_ready,
    output reg  [31:0]  s_rdata,
    output reg  [1:0]   s_resp,

    // =========================
    // AXI4-Lite master
    // =========================

    // AW
    output wire  [31:0] m_axi_awaddr,
    output wire         m_axi_awvalid,
    input  wire         m_axi_awready,

    // W
    output wire  [31:0] m_axi_wdata,
    output wire  [3:0]  m_axi_wstrb,
    output wire         m_axi_wvalid,
    input  wire         m_axi_wready,

    // B
    input  wire [1:0]   m_axi_bresp,
    input  wire         m_axi_bvalid,
    output wire         m_axi_bready,

    // AR
    output wire  [31:0] m_axi_araddr,
    output wire         m_axi_arvalid,
    input  wire         m_axi_arready,

    // R
    input  wire [31:0]  m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,
    input  wire         m_axi_rvalid,
    output wire         m_axi_rready,

    // =========================
    // AXI4-Lite monitor
    // =========================

    output wire        txn_done,
    output wire        txn_source,
    output wire        txn_write,
    output wire [31:0] txn_addr,
    output wire [1:0]  txn_resp
);

    localparam IDLE    = 3'd0;
    localparam W_SEND  = 3'd1;
    localparam W_RESP  = 3'd2;
    localparam R_SEND  = 3'd3;
    localparam R_RESP  = 3'd4;
    localparam DONE    = 3'd5;

    reg [2:0] state;

    reg aw_done;
    reg w_done;

    // 锁存
    reg [31:0] addr_reg;
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;

    // monitor
    reg source_reg;
    reg write_reg;

    assign txn_done = (state == DONE);
    assign txn_source = source_reg;
    assign txn_write  = write_reg;
    assign txn_addr   = addr_reg;
    assign txn_resp   = s_resp;

    // 状态判断
    assign m_axi_awvalid = (state == W_SEND) && !aw_done;
    assign m_axi_wvalid  = (state == W_SEND) && !w_done;

    assign m_axi_bready  = (state == W_RESP);

    assign m_axi_arvalid = (state == R_SEND);

    assign m_axi_rready  = (state == R_RESP);


    // 数据
    assign m_axi_awaddr = addr_reg;
    assign m_axi_wdata  = wdata_reg;
    assign m_axi_wstrb  = wstrb_reg;

    assign m_axi_araddr = addr_reg;

    // 定义中间变量
    wire aw_fire = m_axi_awvalid && m_axi_awready;
    wire w_fire  = m_axi_wvalid  && m_axi_wready;
    wire ar_fire = m_axi_arvalid && m_axi_arready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            addr_reg  <= 32'd0;
            wdata_reg <= 32'd0;
            wstrb_reg <= 4'd0;

            aw_done <= 1'd0;
            w_done  <= 1'd0;

            s_resp  <= 2'd0;
            s_ready <= 1'b0;
            s_rdata <= 32'd0;

            source_reg <= 1'b0;
            write_reg  <= 1'b0;
        end else begin
            s_ready <= 1'b0;
            case (state)
                IDLE: begin
                    if (s_request) begin
                        addr_reg  <= s_addr;
                        wdata_reg <= s_wdata;
                        wstrb_reg <= s_wstrb;

                        source_reg <= s_source;
                        write_reg  <= s_write;

                        if (s_write) begin
                            state <= W_SEND;
                        end else if (s_read) begin
                            state <= R_SEND;
                        end
                    end
                end
                W_SEND: begin
                    if (aw_fire) begin
                        aw_done <= 1'd1;
                    end

                    if (w_fire) begin
                        w_done <= 1'd1;
                    end

                    if ((aw_done || aw_fire) && (w_done || w_fire)) begin
                        state <= W_RESP;

                        aw_done <= 1'd0;
                        w_done  <= 1'd0;
                    end
                end
                W_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        state <= DONE;

                        s_ready <= 1'b1;
                        s_resp  <= m_axi_bresp;
                    end
                end
                R_SEND: begin
                    if (ar_fire) begin
                        state <= R_RESP;
                    end
                end
                R_RESP: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        state <= DONE;

                        s_ready <= 1'b1;
                        s_resp  <= m_axi_rresp;
                        s_rdata <= m_axi_rdata;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;

                    addr_reg  <= 32'd0;
                    wdata_reg <= 32'd0;
                    wstrb_reg <= 4'd0;

                    aw_done <= 1'd0;
                    w_done  <= 1'd0;

                    s_resp  <= 2'd0;
                    s_ready <= 1'b0;
                    s_rdata <= 32'd0;

                    source_reg <= 1'b0;
                    write_reg  <= 1'b0;
                end
            endcase
            
        end
    end




endmodule