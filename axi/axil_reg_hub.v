module axil_reg_hub (
    input  wire         clk,
    input  wire         rst_n,

    // =========================
    // AXI4-Lite Slave
    // =========================

    // AW
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,

    // W
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,

    // B
    output reg  [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,

    // AR
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,

    // R
    output reg  [31:0]  s_axi_rdata,
    output reg  [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,

    //================ BRAM slave =================
    output             ram_request,
    output             ram_re,
    output             ram_we,
    output     [3:0]   ram_wstrb,
    output     [31:0]  ram_addr,
    output     [31:0]  ram_wdata,

    input              ram_ready,
    input      [31:0]  ram_rdata,

    //================ GPIO slave =================
    output             gpio_request,
    output             gpio_re,
    output             gpio_we,
    output     [3:0]   gpio_wstrb,
    output     [7:0]   gpio_addr,
    output     [31:0]  gpio_wdata,

    input              gpio_ready,
    input      [31:0]  gpio_rdata,

    //================ UART slave =================
    output             uart_request,
    output             uart_re,
    output             uart_we,
    output     [3:0]   uart_wstrb,
    output     [7:0]   uart_addr,
    output     [31:0]  uart_wdata,

    input              uart_ready,
    input      [31:0]  uart_rdata,

    //================ Timer slave =================
    output             timer_request,
    output             timer_re,
    output             timer_we,
    output     [3:0]   timer_wstrb,
    output     [7:0]   timer_addr,
    output     [31:0]  timer_wdata,

    input              timer_ready,
    input      [31:0]  timer_rdata,

    //================ IRQ slave =================
    output             irq_request,
    output             irq_re,
    output             irq_we,
    output     [3:0]   irq_wstrb,
    output     [7:0]   irq_addr,
    output     [31:0]  irq_wdata,

    input              irq_ready,
    input      [31:0]  irq_rdata,

    //================ DDR slave =================
    output             ddr_request,
    output             ddr_re,
    output             ddr_we,
    output     [3:0]   ddr_wstrb,
    output     [31:0]  ddr_addr,
    output     [31:0]  ddr_wdata,

    input              ddr_ready,
    input      [31:0]  ddr_rdata,

    //================ NPU slave =================
    output             npu_request,
    output             npu_re,
    output             npu_we,
    output     [3:0]   npu_wstrb,
    output     [31:0]  npu_addr,
    output     [31:0]  npu_wdata,

    input              npu_ready,
    input      [31:0]  npu_rdata,

    //================ DMA slave =================
    output             dma_request,
    output             dma_re,
    output             dma_we,
    output     [3:0]   dma_wstrb,
    output     [7:0]   dma_addr,
    output     [31:0]  dma_wdata,

    input              dma_ready,
    input      [31:0]  dma_rdata,

    //================ PERF slave =================
    output             perf_request,
    output             perf_re,
    output             perf_we,
    output     [3:0]   perf_wstrb,
    output     [7:0]   perf_addr,
    output     [31:0]  perf_wdata,

    input              perf_ready,
    input      [31:0]  perf_rdata,

    //================ FAULT slave =================
    output             fault_request,
    output             fault_re,
    output             fault_we,
    output     [3:0]   fault_wstrb,
    output     [7:0]   fault_addr,
    output     [31:0]  fault_wdata,

    input              fault_ready,
    input      [31:0]  fault_rdata,

    //================ D-cache =================
    input      [31:0]  dcache_stat_cache_read,
    input      [31:0]  dcache_stat_hit,
    input      [31:0]  dcache_stat_miss,
    input      [31:0]  dcache_stat_fill_done,
    input      [31:0]  dcache_stat_fill_word,
    input      [31:0]  dcache_stat_fill_fail
);

    localparam IDLE          = 3'd0;
    localparam EXEC_WRITE    = 3'd1;
    localparam RESP_WRITE    = 3'd2;
    localparam EXEC_READ     = 3'd3;
    localparam RESP_READ     = 3'd4;

    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    localparam RESP_DECERR = 2'b11;

    reg [2:0] state;

    // AW W
    reg [31:0] awaddr_reg;
    reg        aw_stored;

    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;
    reg        w_stored;

    reg        ar_stored;
    
    // R
    reg [31:0] araddr_reg;


    // 状态判断
    assign s_axi_awready = (state == IDLE) && !aw_stored;
    assign s_axi_wready  = (state == IDLE) && !w_stored;

    assign s_axi_arready = (state == IDLE) && !ar_stored;

    assign s_axi_bvalid  = (state == RESP_WRITE);
    assign s_axi_rvalid  = (state == RESP_READ);


    wire [31:0] active_addr;

    assign active_addr =
        (state == EXEC_WRITE || state == RESP_WRITE) ? awaddr_reg :
        (state == EXEC_READ  || state == RESP_READ ) ? araddr_reg :
                                                    32'd0;
    

    // =======================================
    // 地址译码
    // =======================================
    
    // 0x0001_0000 ~ 0x0001_FFFF 其中0x0001_F000 ~ 0x0001_FFFF保留给栈
    wire sel_ram;

    // 0x1000_0000 ~ 0x1000_00FF
    wire sel_gpio;

    // 0x1000_1000 ~ 0x1000_10FF
    wire sel_uart;

    // 0x1000_A000 ~ 0x1000_A0FF
    wire sel_fault;

    // 0x1000_B000 ~ 0x1000_B0FF
    wire sel_dcache_stat;

    localparam  CONFIG = 8'h00;
    localparam  CACHE_READ_COUNT = 8'h04;
    localparam  HIT_COUNT = 8'h08;
    localparam  MISS_COUNT = 8'hC;
    localparam  FILL_DONE_COUNT = 8'h10;
    localparam  FILL_WORD_COUNT = 8'h14;
    localparam  FILL_FAIL_COUNT = 8'h18;

    // 0x1000_2000 ~ 0x1000_20FF
    wire sel_timer;

    // 0x1000_3000 ~ 0x1000_30FF
    wire sel_irq;

    // 0x1000_4000 ~ 0x1000_40FF
    wire sel_dma;

    // 0x1000_9000 ~ 0x1000_90FF
    wire sel_perf;

    // 0x4000_0000 ~ 0x4000_0FFF
    wire sel_npu;

    // 0x8000_0000 ~ 0x87FF_FFFF
    wire sel_ddr;

    // 地址判断
    // ram
    assign sel_ram   = (active_addr[31:16] == 16'h0001);

    // gpio
    assign sel_gpio  = (active_addr[31:8] == 24'h100000);
    
    // uart
    assign sel_uart  = (active_addr[31:8] == 24'h100010);

    // fault
    assign sel_fault = (active_addr[31:8] == 24'h1000A0);

    // Dcache-stat
    assign sel_dcache_stat  = (active_addr[31:8] == 24'h1000B0);

    // timer
    assign sel_timer = (active_addr[31:8] == 24'h100020);

    // irq
    assign sel_irq   = (active_addr[31:8] == 24'h100030);

    // dma
    assign sel_dma   = (active_addr[31:8] == 24'h100040);

    // perf
    assign sel_perf  = (active_addr[31:8] == 24'h100090);

    // npu
    assign sel_npu   = (active_addr[31:12] == 20'h40000);

    // ddr
    assign sel_ddr   = (active_addr[31:27] == 5'b10000);


    // =============地址校验 错误处理===========
    wire addr_hit;

    assign addr_hit = sel_ram
                    || sel_gpio
                    || sel_uart
                    || sel_fault
                    || sel_dcache_stat
                    || sel_timer
                    || sel_irq
                    || sel_dma
                    || sel_perf
                    || sel_npu
                    || sel_ddr;
    
    wire addr_aligned;

    assign addr_aligned = (active_addr[1:0] == 2'b00);

    wire partial_write_supported;

    assign partial_write_supported = sel_ram || sel_ddr;

    wire write_empty;
    wire write_full;
    wire write_strobe_ok;

    assign write_empty = (wstrb_reg == 4'b0000);
    assign write_full  = (wstrb_reg == 4'b1111);

    assign write_strobe_ok = write_empty || write_full || partial_write_supported;

    wire legal_read;
    wire legal_write;

    assign legal_read = addr_hit && addr_aligned;

    assign legal_write = addr_hit && addr_aligned && write_strobe_ok && !write_empty;

    //==================================================
    // Write / Read request distribution
    //==================================================

    // ram
    assign ram_request =  ram_re || ram_we;

    assign ram_re      =  sel_ram && (state == EXEC_READ)  && legal_read;

    assign ram_we      =  sel_ram && (state == EXEC_WRITE) && legal_write;

    assign ram_wstrb   =  wstrb_reg;

    assign ram_addr    =  (active_addr - 32'h0001_0000) >> 2;

    assign ram_wdata   =  wdata_reg;

    // gpio
    assign gpio_request =  gpio_re || gpio_we;

    assign gpio_re     =  sel_gpio && (state == EXEC_READ) && legal_read;

    assign gpio_we     =  sel_gpio && (state == EXEC_WRITE) && legal_write;

    assign gpio_wstrb  =  wstrb_reg;

    assign gpio_addr   =  active_addr[7:0] >> 2;

    assign gpio_wdata  =  wdata_reg;

    // uart
    assign uart_request =  uart_re || uart_we;

    assign uart_re     =  sel_uart && (state == EXEC_READ) && legal_read;

    assign uart_we     =  sel_uart && (state == EXEC_WRITE) && legal_write;

    assign uart_wstrb  =  wstrb_reg;

    assign uart_addr   =  active_addr[7:0];

    assign uart_wdata  =  wdata_reg;

    // fault
    assign fault_request =  fault_re || fault_we;

    assign fault_re     =  sel_fault && (state == EXEC_READ) && legal_read;

    assign fault_we     =  sel_fault && (state == EXEC_WRITE) && legal_write;

    assign fault_wstrb  =  wstrb_reg;

    assign fault_addr   =  active_addr[7:0];

    assign fault_wdata  =  wdata_reg;

    // timer
    assign timer_request =  timer_re || timer_we;
    
    assign timer_re    =  sel_timer && (state == EXEC_READ) && legal_read;

    assign timer_we    =  sel_timer && (state == EXEC_WRITE) && legal_write;

    assign timer_wstrb =  wstrb_reg;

    assign timer_addr  =  active_addr[7:0];

    assign timer_wdata =  wdata_reg;

    // irq
    assign irq_request =  irq_re || irq_we;

    assign irq_re      =  sel_irq && (state == EXEC_READ) && legal_read;

    assign irq_we      =  sel_irq && (state == EXEC_WRITE) && legal_write;

    assign irq_wstrb   =  wstrb_reg;

    assign irq_addr    =  active_addr[7:0];

    assign irq_wdata   =  wdata_reg;

    // dma
    assign dma_request =  dma_re || dma_we;

    assign dma_re      =  sel_dma && (state == EXEC_READ) && legal_read;

    assign dma_we      =  sel_dma && (state == EXEC_WRITE) && legal_write;

    assign dma_wstrb   =  wstrb_reg;

    assign dma_addr    =  active_addr[7:0];

    assign dma_wdata   =  wdata_reg;

    // perf
    assign perf_request =  perf_re || perf_we;

    assign perf_re     =  sel_perf && (state == EXEC_READ) && legal_read;

    assign perf_we     =  sel_perf && (state == EXEC_WRITE) && legal_write;

    assign perf_wstrb  =  wstrb_reg;

    assign perf_addr   =  active_addr[7:0];
 
    assign perf_wdata  =  wdata_reg;

    // npu
    assign npu_request =  npu_re || npu_we;

    assign npu_re      =  sel_npu && (state == EXEC_READ) && legal_read;

    assign npu_we      =  sel_npu && (state == EXEC_WRITE) && legal_write;

    assign npu_wstrb   =  wstrb_reg;

    assign npu_addr    =  (active_addr - 32'h4000_0000);

    assign npu_wdata   =  wdata_reg;

    // ddr
    assign ddr_request =  ddr_re || ddr_we;

    assign ddr_re      =  sel_ddr && (state == EXEC_READ) && legal_read;

    assign ddr_we      =  sel_ddr && (state == EXEC_WRITE) && legal_write;

    assign ddr_wstrb   =  wstrb_reg;

    assign ddr_addr    =  (active_addr - 32'h8000_0000);

    assign ddr_wdata   =  wdata_reg;

    // 定义中间变量
    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;
    wire ar_fire = s_axi_arvalid && s_axi_arready;

    wire write_complete;
    wire read_complete;

    assign write_complete = (aw_stored || aw_fire) && (w_stored  || w_fire);

    assign read_complete = ar_stored || ar_fire;

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;

            awaddr_reg <= 32'd0;
            wdata_reg  <= 32'd0;
            wstrb_reg  <= 4'd0;
            araddr_reg <= 32'd0;

            aw_stored  <= 1'b0;
            w_stored   <= 1'b0;
            ar_stored  <= 1'b0;

            s_axi_bresp <= RESP_DECERR;
            s_axi_rresp <= RESP_DECERR;

            s_axi_rdata <= 32'd0; 
        end else begin
            case (state)
                IDLE: begin
                    if (aw_fire) begin
                        awaddr_reg <= s_axi_awaddr;
                        aw_stored  <= 1'b1;
                    end

                    if (w_fire) begin
                        wdata_reg <= s_axi_wdata;
                        wstrb_reg <= s_axi_wstrb;
                        w_stored  <= 1'b1;
                    end

                    if (ar_fire) begin
                        araddr_reg <= s_axi_araddr;
                        ar_stored  <= 1'b1;
                    end

                    if (write_complete) begin
                        state <= EXEC_WRITE;

                        aw_stored <= 1'b0;
                        w_stored  <= 1'b0;

                    end
                    else if (read_complete) begin
                        state      <= EXEC_READ;

                        ar_stored  <= 1'b0;
                    end
                end
                EXEC_WRITE: begin
                    // 1. 地址不存在
                    if (!addr_hit) begin
                        s_axi_bresp <= RESP_DECERR;
                        state <= RESP_WRITE;
                    end
                    // 2. 地址未对齐
                    else if (!addr_aligned) begin
                        s_axi_bresp <= RESP_SLVERR;
                        state <= RESP_WRITE;
                    end

                    // 3. 空写：合法结束，但不产生副作用
                    else if (write_empty) begin
                        s_axi_bresp <= RESP_OKAY;
                        state <= RESP_WRITE;
                    end

                    // 4. 当前slave不支持这种WSTRB
                    else if (!write_strobe_ok) begin
                        s_axi_bresp <= RESP_SLVERR;
                        state <= RESP_WRITE;
                    end
                    else begin
                        case (1'b1)
                            sel_ram: begin
                                if (ram_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_gpio: begin
                                if (gpio_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_uart: begin
                                if (uart_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_fault: begin
                                if (fault_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_dcache_stat: begin
                                s_axi_bresp <= RESP_SLVERR;   // OKAY
                                state <= RESP_WRITE;
                            end
                            sel_timer: begin
                                if (timer_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_irq: begin
                                if (irq_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_dma: begin
                                if (dma_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_npu: begin
                                if (npu_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_perf: begin
                                if (perf_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            sel_ddr: begin
                                if (ddr_ready) begin
                                    s_axi_bresp <= RESP_OKAY;   // OKAY
                                    state <= RESP_WRITE;
                                end
                            end
                            default: begin
                                s_axi_bresp <= RESP_DECERR;   // DECERR
                                state <= RESP_WRITE;
                            end
                        endcase
                    end
                end
                RESP_WRITE: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        state <= IDLE;
                    end
                end
                EXEC_READ: begin
                    if (!addr_hit) begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= RESP_DECERR;
                        state <= RESP_READ;
                    end

                    else if (!addr_aligned) begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= RESP_SLVERR;
                        state <= RESP_READ;
                    end
                    else begin
                        case (1'b1)
                            sel_ram: begin
                                if (ram_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= ram_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_gpio: begin
                                if (gpio_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= gpio_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_uart: begin
                                if (uart_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= uart_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_fault: begin
                                if (fault_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= fault_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_dcache_stat: begin
                                s_axi_rresp <= RESP_OKAY;   // OKAY
                                case (active_addr[7:0])
                                    CONFIG :           s_axi_rdata <= 32'h0000_4041;
                                    CACHE_READ_COUNT : s_axi_rdata <= dcache_stat_cache_read;
                                    HIT_COUNT :        s_axi_rdata <= dcache_stat_hit;
                                    MISS_COUNT :       s_axi_rdata <= dcache_stat_miss;
                                    FILL_DONE_COUNT :  s_axi_rdata <= dcache_stat_fill_done;
                                    FILL_WORD_COUNT :  s_axi_rdata <= dcache_stat_fill_word;
                                    FILL_FAIL_COUNT :  s_axi_rdata <= dcache_stat_fill_fail;
                                    default: begin
                                        s_axi_rdata <= 32'd0;
                                        s_axi_rresp <= RESP_DECERR;
                                    end 
                                endcase
                                state <= RESP_READ;
                            end
                            sel_timer: begin
                                if (timer_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= timer_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_irq: begin
                                if (irq_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= irq_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_dma: begin
                                if (dma_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= dma_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_npu: begin
                                if (npu_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= npu_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_perf: begin
                                if (perf_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= perf_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            sel_ddr: begin
                                if (ddr_ready) begin
                                    s_axi_rresp <= RESP_OKAY;   // OKAY
                                    s_axi_rdata <= ddr_rdata;
                                    state <= RESP_READ;
                                end
                            end
                            default: begin
                                s_axi_rresp <= RESP_DECERR;   // DECERR
                                s_axi_rdata <= 32'd0;
                                state <= RESP_READ;
                            end
                        endcase
                    end
                end
                RESP_READ: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        state <= IDLE;
                    end
                end
                default: begin
                    state      <= IDLE;

                    awaddr_reg <= 32'd0;
                    wdata_reg  <= 32'd0;
                    wstrb_reg  <= 4'd0;
                    araddr_reg <= 32'd0;

                    aw_stored  <= 1'b0;
                    w_stored   <= 1'b0;
                    ar_stored  <= 1'b0;

                    s_axi_bresp <= RESP_DECERR;
                    s_axi_rresp <= RESP_DECERR;

                    s_axi_rdata <= 32'd0; 
                end
            endcase
        end
    end

endmodule