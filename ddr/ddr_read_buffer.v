module ddr_read_buffer (
    input  wire          clk,
    input  wire          rst_n,

    // upstream: hub / DDR slave side
    input  wire          s_request,
    input  wire          s_re,
    input  wire          s_we,
    input  wire [15:0]   s_wmask,
    input  wire [31:0]   s_addr,
    input  wire [127:0]  s_wdata,

    output wire          s_ready,
    output wire [127:0]  s_rdata,

    // downstream: original CDC side
    output wire          m_request,
    output wire          m_re,
    output wire          m_we,
    output wire [15:0]   m_wmask,
    output wire [31:0]   m_addr,
    output wire [127:0]  m_wdata,

    input  wire          m_ready,
    input  wire [127:0]  m_rdata
);

    localparam IDLE     = 2'b00;
    localparam WAIT_CDC = 2'b01;
    localparam RESP     = 2'b10;

    reg [1:0]  state;

    reg [31:0]  req_addr_reg;
    reg         req_re_reg;
    reg         req_we_reg;
    reg [15:0]  req_wmask_reg;
    reg [127:0] req_wdata_reg;

    reg [127:0] rsp_rdata_reg;

    reg [127:0] line_data;
    reg [27:0]  line_tag;
    reg         line_valid;

    // 定义内部状态
    wire start     = s_request;
    wire write     = s_we;
    wire read      = s_re;
    wire cdc_valid = m_ready;

    wire read_hit;

    assign read_hit = line_valid && s_request && s_re && (s_addr[31:4] == line_tag);

    // 定义外部接口
    assign m_request = state == WAIT_CDC; //
    assign m_re      = req_re_reg;
    assign m_we      = req_we_reg;
    assign m_wmask   = req_wmask_reg;
    assign m_addr    = req_addr_reg;
    assign m_wdata   = req_wdata_reg;

    assign s_rdata   = rsp_rdata_reg;
    assign s_ready   = state == RESP;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;

            req_addr_reg    <= 32'd0;
            req_re_reg      <= 1'b0;
            req_we_reg      <= 1'b0;
            req_wmask_reg   <= 16'd0;
            req_wdata_reg   <= 128'd0;

            rsp_rdata_reg   <= 128'd0;

            line_valid      <= 1'b0;
            line_data       <= 128'd0;
            line_tag        <= 28'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        req_addr_reg    <= s_addr;
                        req_re_reg      <= s_re;
                        req_we_reg      <= s_we;
                        req_wmask_reg   <= s_wmask;
                        req_wdata_reg   <= s_wdata;

                        if (write) begin
                            line_valid <= 1'b0;
                            state <= WAIT_CDC; 
                        end

                        else if (read && read_hit) begin
                            rsp_rdata_reg <= line_data;
                            state         <= RESP;
                        end

                        else begin
                            state <= WAIT_CDC;
                        end
                    end
                end 
                WAIT_CDC: begin
                    if (cdc_valid) begin
                        if (req_re_reg) begin
                            rsp_rdata_reg <= m_rdata;

                            line_data     <= m_rdata;
                            line_tag      <= req_addr_reg[31:4];
                            line_valid    <= 1'b1;
                        end

                        state <= RESP;
                    end
                end 
                RESP: begin
                    state <= IDLE;
                end 
                default: state <= IDLE;
            endcase
        end
    end
endmodule