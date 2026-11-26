module dcache (
    input  wire        clk,
    input  wire        rst_n,

    // CPU side
    input  wire        s_request,
    input  wire        s_read,
    input  wire        s_write,
    input  wire [3:0]  s_wstrb,
    input  wire [31:0] s_addr,
    input  wire [31:0] s_wdata,

    output wire        s_ready,
    output wire [31:0] s_rdata,
    output wire [1:0]  s_resp,

    // bus / arbiter side
    output wire        m_request,
    output wire        m_read,
    output wire        m_write,
    output wire [3:0]  m_wstrb,
    output wire [31:0] m_addr,
    output wire [31:0] m_wdata,

    input  wire        m_ready,
    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_resp
);
    // addr[31:10] = tag
    // addr[9:4]   = index
    // addr[3:2]   = word
    // addr[1:0]   = byte
    (* ram_style = "block" *)
    reg [31:0] data_mem [0:255];
    reg [21:0] tag_mem  [0:63];
    reg        valid_mem[0:63];

    // FSM
    localparam IDLE      = 3'd0;
    localparam LOOKUP    = 3'd1;
    localparam BUS_WAIT  = 3'd2;
    localparam FILL_WAIT = 3'd3;
    localparam GAP       = 3'd4;
    localparam RESP      = 3'd5;

    localparam RESP_OKAY   = 2'b00;
    
    reg [2:0] state;

    reg [31:0] req_addr_reg;
    reg        req_read_reg;
    reg        req_write_reg;
    reg [3:0]  req_wstrb_reg;
    reg [31:0] req_wdata_reg;

    reg [31:0] rsp_rdata_reg;
    reg [1:0]  rsp_resp_reg;

    // 定义内部信号

    wire [21:0] req_tag;
    wire [5:0]  req_index;
    wire [1:0]  req_word;

    wire [21:0] pri_req_tag;
    wire [5:0]  pri_req_index;

    assign req_tag   = req_addr_reg[31:10];
    assign req_index = req_addr_reg[9:4];
    assign req_word  = req_addr_reg[3:2];

    assign pri_req_tag    = s_addr[31:10];
    assign pri_req_index  = s_addr[9:4];

    wire [7:0] data_index;
    wire [7:0] save_index;

    assign data_index = {req_index, req_word};
    assign save_index = {req_index, fill_word};

    // 0x8400_0000 ~ 0x87FF_FFFF
    wire cacheable;

    wire cache_region  = (s_addr[31:26] == 6'b100001);
    wire word_aligned  = (s_addr[1:0] == 2'b00);
    wire legal_op      = s_read ^ s_write;

    assign cacheable = cache_region && word_aligned && legal_op;

    reg [1:0] fill_word;
    wire [31:0] fill_line_base;

    assign fill_line_base = {req_addr_reg[31:4], 4'b0000};


    // 定义内部基本状态
    wire start     = s_request;
    wire write     = s_write;
    wire read      = s_read;
    wire write_hit = (valid_mem[pri_req_index]) && (tag_mem[pri_req_index] == pri_req_tag);
    wire read_hit  = (valid_mem[req_index]) && (tag_mem[req_index] == req_tag);

    wire write_invalidate = cacheable && (s_wstrb != 4'b0000) && write_hit;

    wire m_valid  = m_ready && (m_resp == RESP_OKAY);
    wire reach_top = (fill_word == 2'b11);

    // 定义外部状态
    assign m_request = (state == FILL_WAIT) || (state == BUS_WAIT);
    assign m_read    = (state == FILL_WAIT) ? 1'b1 : (state == BUS_WAIT) ? req_read_reg : 1'b0;
    assign m_write   = (state == BUS_WAIT) ? req_write_reg : 1'b0;
    assign m_addr    = (state == FILL_WAIT) ? (fill_line_base + {28'd0, fill_word, 2'b00}) : (state == BUS_WAIT) ? req_addr_reg : 32'd0;
    assign m_wstrb   = req_wstrb_reg;
    assign m_wdata   = req_wdata_reg;

    assign s_rdata   = rsp_rdata_reg;
    assign s_resp    = rsp_resp_reg;
    assign s_ready   = (state == RESP);

    // 综合RAM
    reg [31:0] data_rd_reg;

    // 独立写口：从原状态机中移出这次数组写入
    always @(posedge clk) begin
        if (rst_n && state == FILL_WAIT && m_valid)
            data_mem[save_index] <= m_rdata;
    end

    // 接收请求时启动同步读，下一拍 LOOKUP 使用结果
    always @(posedge clk) begin
        if (rst_n && state == IDLE &&
            s_request && s_read && cacheable)
            data_rd_reg <= data_mem[s_addr[9:2]];
    end

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;

            req_addr_reg  <= 32'd0;
            req_read_reg  <= 1'b0;
            req_write_reg <= 1'b0;
            req_wstrb_reg <= 4'd0;
            req_wdata_reg <= 32'd0;

            rsp_rdata_reg <= 32'd0;
            rsp_resp_reg  <= RESP_OKAY;

            fill_word  <= 2'd0;

            for (i = 0; i < 64; i = i + 1)
                valid_mem[i] <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        req_addr_reg  <= s_addr;
                        req_read_reg  <= s_read;
                        req_write_reg <= s_write;
                        req_wstrb_reg <= s_wstrb;
                        req_wdata_reg <= s_wdata;

                        if (write && write_invalidate) begin
                            valid_mem[pri_req_index] <= 1'b0;

                            state <= BUS_WAIT;
                        end

                        else if (read && cacheable) begin
                            state <= LOOKUP;
                        end

                        else begin
                            state <= BUS_WAIT;
                        end
                    end
                end
                LOOKUP: begin
                    if (read_hit) begin
                        rsp_rdata_reg <= data_rd_reg;
                        rsp_resp_reg  <= RESP_OKAY;
                        state         <= RESP;
                    end
                    else begin
                        valid_mem[req_index] <= 1'b0;
                        state         <= FILL_WAIT;

                        fill_word     <= 2'd0;
                    end
                end
                BUS_WAIT: begin
                    if (m_ready) begin
                        rsp_rdata_reg <= m_rdata;
                        rsp_resp_reg  <= m_resp;
                        state         <= RESP;
                    end
                end
                FILL_WAIT: begin
                    if (m_ready && m_resp != 2'b00) begin
                        rsp_resp_reg  <= m_resp;
                        state <= RESP;
                    end
                    else if (m_valid) begin
                        if (fill_word == req_word) begin
                            rsp_rdata_reg <= m_rdata;
                            rsp_resp_reg  <= RESP_OKAY;
                        end

                        if (reach_top) begin
                            tag_mem[req_index]   <= req_tag;
                            valid_mem[req_index] <= 1'b1;
                            
                            fill_word <= 2'b00;
                            state <= RESP;
                        end
                        else begin
                            fill_word <= fill_word + 2'd1;

                            state <= GAP;
                        end
                    end
                end
                GAP: begin
                    state <= FILL_WAIT;
                end
                RESP: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule