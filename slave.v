`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/23 19:12:39
// Design Name: 
// Module Name: bus_pipeline
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


module slave(
        input              clk_cpu_50,
        input              clk_mig_160,
        input              clk_ref_200,
        input              sys_rst_n,  // 原始复位
        input              cpu_rst_n,  // CPU复位
        input              mig_rst_n,  // mig复位
        output    [3:0]    led,
        
        output             tx,
        input              rx,

        input              rom_en,
        input     [31:0]   pc_oF,
        input              cpu_en,
        output    [31:0]   instr,

        input              cpu_request,
        input              cpu_read,
        input              cpu_write,
        input      [3:0]   cpu_wstrb,
        input      [31:0]  cpu_addr,
        input      [31:0]  cpu_wdata,

        output             cpu_ready,
        output     [31:0]  cpu_rdata,
        output     [1:0]   cpu_resp,

        output             cpu_irq,

        // 性能分析
        input              cpu_instr_event,
        input              cpu_stall_event,

        // ddr
        inout       [15:0] ddr3_dq,
        inout       [1:0]  ddr3_dqs_n,
        inout       [1:0]  ddr3_dqs_p,

        output      [13:0] ddr3_addr,
        output      [2:0]  ddr3_ba,
        output             ddr3_ras_n,
        output             ddr3_cas_n,
        output             ddr3_we_n,
        output             ddr3_reset_n,
        output      [0:0]  ddr3_ck_p,
        output      [0:0]  ddr3_ck_n,
        output      [0:0]  ddr3_cke,
        output      [0:0]  ddr3_cs_n,
        output      [1:0]  ddr3_dm,
        output      [0:0]  ddr3_odt
    );
        //================ Arbiter =================
        wire              arbiter_request;
        wire              arbiter_re;
        wire              arbiter_we;
        wire      [3:0]   arbiter_wstrb;
        wire      [31:0]  arbiter_addr;
        wire      [31:0]  arbiter_wdata;

        wire              arbiter_ready;
        wire      [31:0]  arbiter_rdata;
        wire      [1:0]   arbiter_resp;

        wire              arbiter_source;

        //================ AXI4-Lite =================
        // AW
        wire      [31:0]  axi_awaddr;
        wire              axi_awvalid;
        wire              axi_awready;

        // W
        wire      [31:0]  axi_wdata;
        wire      [3:0]   axi_wstrb;
        wire              axi_wvalid;
        wire              axi_wready;

        // B
        wire      [1:0]   axi_bresp;
        wire              axi_bvalid;
        wire              axi_bready;

        // AR
        wire      [31:0]  axi_araddr;
        wire              axi_arvalid;
        wire              axi_arready;

        // R
        wire      [31:0]  axi_rdata;
        wire      [1:0]   axi_rresp;
        wire              axi_rvalid;
        wire              axi_rready;

        // AXI4-Lite monitor
        wire              txn_done;
        wire              txn_source;
        wire              txn_write;
        wire     [31:0]   txn_addr;
        wire     [1:0]    txn_resp;

        //================ BRAM slave =================
        wire              ram_request;
        wire              ram_re;
        wire              ram_we;
        wire      [3:0]   ram_wstrb;
        wire      [31:0]  ram_addr;
        wire      [31:0]  ram_wdata;

        wire              ram_ready;
        wire      [31:0]  ram_rdata;

        //================ GPIO slave =================
        wire              gpio_request;
        wire              gpio_re;
        wire              gpio_we;
        wire      [3:0]   gpio_wstrb;
        wire      [7:0]   gpio_addr;
        wire      [31:0]  gpio_wdata;

        wire              gpio_ready;
        wire      [31:0]  gpio_rdata;

        //================ UART slave =================
        wire              uart_request;
        wire              uart_re;
        wire              uart_we;
        wire      [3:0]   uart_wstrb;
        wire      [7:0]   uart_addr;
        wire      [31:0]  uart_wdata;

        wire              uart_ready;
        wire      [31:0]  uart_rdata;

        //================ TIMER slave =================
        wire              timer_request;
        wire              timer_re;
        wire              timer_we;
        wire      [3:0]   timer_wstrb;
        wire      [7:0]   timer_addr;
        wire      [31:0]  timer_wdata;

        wire              timer_ready;
        wire      [31:0]  timer_rdata;

        wire              timer_irq;

        //================ IRQ slave =================
        wire              irq_request;
        wire              irq_re;
        wire              irq_we;
        wire      [3:0]   irq_wstrb;
        wire      [7:0]   irq_addr;
        wire      [31:0]  irq_wdata;

        wire              irq_ready;
        wire      [31:0]  irq_rdata;

        //================ DDR slave =================
        wire              ddr_request;
        wire              ddr_re;
        wire              ddr_we;
        wire      [31:0]  ddr_addr;
        wire      [3:0]   ddr_wstrb;
        wire      [31:0]  ddr_wdata;

        wire              ddr_ready;
        wire      [31:0]  ddr_rdata;

        //================ NPU slave =================
        wire              npu_request;
        wire              npu_re;
        wire              npu_we;
        wire      [31:0]  npu_addr;
        wire      [3:0]   npu_wstrb;
        wire      [31:0]  npu_wdata;

        wire              npu_ready;
        wire      [31:0]  npu_rdata;

        wire              npu_irq;

        ///================ DMA slave =================
        wire              dma_s_request;
        wire              dma_s_re;
        wire              dma_s_we;
        wire      [3:0]   dma_s_wstrb;
        wire      [7:0]   dma_s_addr;
        wire      [31:0]  dma_s_wdata;

        wire              dma_s_ready;
        wire      [31:0]  dma_s_rdata;

        wire              dma_m_request;
        wire              dma_m_re;
        wire              dma_m_we;
        wire      [3:0]   dma_m_wstrb;
        wire      [31:0]  dma_m_addr;
        wire      [31:0]  dma_m_wdata;

        wire              dma_m_ready;
        wire      [31:0]  dma_m_rdata;
        wire      [1:0]   dma_m_resp;

        wire              dma_irq;

        //================ PERF slave =================
        wire              perf_request;
        wire              perf_re;
        wire              perf_we;
        wire      [7:0]   perf_addr;
        wire      [3:0]   perf_wstrb;
        wire      [31:0]  perf_wdata;

        wire              perf_ready;
        wire      [31:0]  perf_rdata;

        //================ FAULT slave =================
        wire              fault_request;
        wire              fault_re;
        wire              fault_we;
        wire      [3:0]   fault_wstrb;
        wire      [7:0]   fault_addr;
        wire      [31:0]  fault_wdata;

        wire              fault_ready;
        wire      [31:0]  fault_rdata;



        //==================================================
        // instruction instance
        //==================================================
        boot_rom #(10) u_boot_rom(
            .clk(clk_cpu_50),
            .en(rom_en),
            .pc(pc_oF),
            .instr(instr)
        );

        //==================================================
        // Arbiter
        //==================================================
        arbiter u_arbiter(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),

            .cpu_request(cpu_request),
            .cpu_read(cpu_read),
            .cpu_write(cpu_write),
            .cpu_wstrb(cpu_wstrb),
            .cpu_addr(cpu_addr),
            .cpu_wdata(cpu_wdata),

            .cpu_ready(cpu_ready),
            .cpu_rdata(cpu_rdata),
            .cpu_resp(cpu_resp),

            .dma_request(dma_m_request),
            .dma_re(dma_m_re),
            .dma_we(dma_m_we),
            .dma_wstrb(dma_m_wstrb),
            .dma_addr(dma_m_addr),
            .dma_wdata(dma_m_wdata),

            .dma_ready(dma_m_ready),
            .dma_rdata(dma_m_rdata),
            .dma_resp(dma_m_resp),

            .arbiter_request(arbiter_request),
            .arbiter_read(arbiter_re),
            .arbiter_write(arbiter_we),
            .arbiter_wstrb(arbiter_wstrb),
            .arbiter_addr(arbiter_addr),
            .arbiter_wdata(arbiter_wdata),

            .arbiter_ready(arbiter_ready),
            .arbiter_rdata(arbiter_rdata),
            .arbiter_resp(arbiter_resp),

            .arbiter_source(arbiter_source)
        );

        //==================================================
        // bus instance
        //==================================================

        // axi adapter
        simple_to_axil u_simple_to_axil(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),
            .s_source(arbiter_source), // 0: CPU, 1: DMA

            // =========================
            // simple request side
            // =========================
            .s_request(arbiter_request),
            .s_read(arbiter_re),
            .s_write(arbiter_we),
            .s_addr(arbiter_addr),
            .s_wdata(arbiter_wdata),
            .s_wstrb(arbiter_wstrb),

            .s_ready(arbiter_ready),
            .s_rdata(arbiter_rdata),
            .s_resp(arbiter_resp),

            // =========================
            // AXI4-Lite master
            // =========================

            // AW
            .m_axi_awaddr(axi_awaddr),
            .m_axi_awvalid(axi_awvalid),
            .m_axi_awready(axi_awready),

            // W
            .m_axi_wdata(axi_wdata),
            .m_axi_wstrb(axi_wstrb),
            .m_axi_wvalid(axi_wvalid),
            .m_axi_wready(axi_wready),

            // B
            .m_axi_bresp(axi_bresp),
            .m_axi_bvalid(axi_bvalid),
            .m_axi_bready(axi_bready),

            // AR
            .m_axi_araddr(axi_araddr),
            .m_axi_arvalid(axi_arvalid),
            .m_axi_arready(axi_arready),

            // R
            .m_axi_rdata(axi_rdata),
            .m_axi_rresp(axi_rresp),
            .m_axi_rvalid(axi_rvalid),
            .m_axi_rready(axi_rready),

            // =========================
            // AXI4-Lite monitor
            // =========================

            .txn_done(txn_done),
            .txn_source(txn_source),
            .txn_write(txn_write),
            .txn_addr(txn_addr),
            .txn_resp(txn_resp)
        );

        axil_reg_hub u_axil_reg_hub(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),

            //================ axi master =================
            .s_axi_awaddr(axi_awaddr),
            .s_axi_awvalid(axi_awvalid),
            .s_axi_awready(axi_awready),

            // W
            .s_axi_wdata(axi_wdata),
            .s_axi_wstrb(axi_wstrb),
            .s_axi_wvalid(axi_wvalid),
            .s_axi_wready(axi_wready),

            // B
            .s_axi_bresp(axi_bresp),
            .s_axi_bvalid(axi_bvalid),
            .s_axi_bready(axi_bready),

            // AR
            .s_axi_araddr(axi_araddr),
            .s_axi_arvalid(axi_arvalid),
            .s_axi_arready(axi_arready),

            // R
            .s_axi_rdata(axi_rdata),
            .s_axi_rresp(axi_rresp),
            .s_axi_rvalid(axi_rvalid),
            .s_axi_rready(axi_rready),

            //================ BRAM slave =================
            .ram_request(ram_request),
            .ram_re(ram_re),
            .ram_we(ram_we),
            .ram_wstrb(ram_wstrb),
            .ram_addr(ram_addr),
            .ram_wdata(ram_wdata),

            .ram_ready(ram_ready),
            .ram_rdata(ram_rdata),

            //================ GPIO slave =================
            .gpio_request(gpio_request),
            .gpio_re(gpio_re),
            .gpio_we(gpio_we),
            .gpio_wstrb(gpio_wstrb),
            .gpio_addr(gpio_addr),
            .gpio_wdata(gpio_wdata),

            .gpio_ready(gpio_ready),
            .gpio_rdata(gpio_rdata),

            //================ UART slave =================
            .uart_request(uart_request),
            .uart_re(uart_re),
            .uart_we(uart_we),
            .uart_wstrb(uart_wstrb),
            .uart_addr(uart_addr),
            .uart_wdata(uart_wdata),

            .uart_ready(uart_ready),
            .uart_rdata(uart_rdata),

            //================ TIMER slave =================
            .timer_request(timer_request),
            .timer_re(timer_re),
            .timer_we(timer_we),
            .timer_wstrb(timer_wstrb),
            .timer_addr(timer_addr),
            .timer_wdata(timer_wdata),

            .timer_ready(timer_ready),
            .timer_rdata(timer_rdata),

            //================ IRQ slave =================
            .irq_request(irq_request),
            .irq_re(irq_re),
            .irq_we(irq_we),
            .irq_wstrb(irq_wstrb),
            .irq_addr(irq_addr),
            .irq_wdata(irq_wdata),

            .irq_ready(irq_ready),
            .irq_rdata(irq_rdata),
            
            //================ DDR slave =================
            .ddr_request(ddr_request),
            .ddr_re(ddr_re),
            .ddr_we(ddr_we),
            .ddr_wstrb(ddr_wstrb),
            .ddr_addr(ddr_addr),
            .ddr_wdata(ddr_wdata),

            .ddr_ready(ddr_ready),
            .ddr_rdata(ddr_rdata),

            //================ NPU slave =================
            .npu_request(npu_request),
            .npu_re(npu_re),
            .npu_we(npu_we),
            .npu_wstrb(npu_wstrb),
            .npu_addr(npu_addr),
            .npu_wdata(npu_wdata),

            .npu_ready(npu_ready),
            .npu_rdata(npu_rdata),

            //================ DMA slave =================
            .dma_request(dma_s_request),
            .dma_re(dma_s_re),
            .dma_we(dma_s_we),
            .dma_wstrb(dma_s_wstrb),
            .dma_addr(dma_s_addr),
            .dma_wdata(dma_s_wdata),

            .dma_ready(dma_s_ready),
            .dma_rdata(dma_s_rdata),

            //================ PERF slave =================
            .perf_request(perf_request),
            .perf_re(perf_re),
            .perf_we(perf_we),
            .perf_wstrb(perf_wstrb),
            .perf_addr(perf_addr),
            .perf_wdata(perf_wdata),

            .perf_ready(perf_ready),
            .perf_rdata(perf_rdata),

            //================ FAULT slave =================
            .fault_request(fault_request),
            .fault_re(fault_re),
            .fault_we(fault_we),
            .fault_wstrb(fault_wstrb),
            .fault_addr(fault_addr),
            .fault_wdata(fault_wdata),

            .fault_ready(fault_ready),
            .fault_rdata(fault_rdata) 
        );


        //==================================================
        // bram instance
        //==================================================
        bram_ram #(14) u_bram_ram(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),
            .ram_request(ram_request),
            .ram_re(ram_re),
            .ram_we(ram_we),
            .ram_wstrb(ram_wstrb),
            .ram_addr(ram_addr),
            .ram_wdata(ram_wdata),
            .ram_ready(ram_ready),
            .ram_rdata(ram_rdata)
        );

        //==================================================
        // gpio instance
        //==================================================
        gpio_mmio u_gpio_mmio(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),
            .gpio_request(gpio_request),
            .gpio_re(gpio_re),
            .gpio_we(gpio_we),
            .gpio_wstrb(gpio_wstrb),
            .gpio_addr(gpio_addr),
            .gpio_wdata(gpio_wdata),
            .gpio_ready(gpio_ready),
            .gpio_rdata(gpio_rdata),
            .led(led)
        );


        //==================================================
        // UART instance
        //==================================================
        uart u_uart(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),

            // bus interface
            .uart_request(uart_request),
            .uart_re(uart_re),
            .uart_we(uart_we),
            .uart_wstrb(uart_wstrb),
            .uart_addr(uart_addr),
            .uart_wdata(uart_wdata),
            .uart_ready(uart_ready),
            .uart_rdata(uart_rdata),

            // physical pins
            .rx(rx),
            .tx(tx)
        );

        //==================================================
        // TIMER instance
        //==================================================
        timer_mimo u_timer_mimo(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),

            .timer_request(timer_request),
            .timer_re(timer_re),
            .timer_we(timer_we),
            .timer_wstrb(timer_wstrb),
            .timer_addr(timer_addr),
            .timer_wdata(timer_wdata),

            .timer_ready(timer_ready),
            .timer_rdata(timer_rdata),
            .timer_irq(timer_irq)
        );

        //==================================================
        // IRQ instance
        //==================================================
        irq_controller u_irq_controller(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),

            // interrupt sources
            .timer_irq(timer_irq),
            .npu_irq(npu_irq),
            .dma_irq(dma_irq),

            // MMIO
            .irq_request(irq_request),
            .irq_re(irq_re),
            .irq_we(irq_we),
            .irq_wstrb(irq_wstrb),
            .irq_addr(irq_addr),
            .irq_wdata(irq_wdata),
            .irq_ready(irq_ready),
            .irq_rdata(irq_rdata),

            // CPU
            .cpu_irq(cpu_irq)
        );

        //==================================================
        // ddr_slave instance   
        //==================================================
        ddr_slave u_ddr_slave(
            .clk_cpu_50(clk_cpu_50),
            .clk_mig_160(clk_mig_160),
            .clk_ref_200(clk_ref_200),
            .sys_rst_n(sys_rst_n),
            .cpu_rst_n(cpu_rst_n),
            .mig_rst_n(mig_rst_n),

            .ddr_request(ddr_request),
            .ddr_re(ddr_re),
            .ddr_we(ddr_we),

            .ddr_wstrb(ddr_wstrb),
            .ddr_addr(ddr_addr),  // 可以锁存addr
            .ddr_wdata(ddr_wdata),
            .ddr_ready(ddr_ready),
            .ddr_rdata(ddr_rdata),

            // ===========
            .ddr3_dq(ddr3_dq),
            .ddr3_dqs_n(ddr3_dqs_n),
            .ddr3_dqs_p(ddr3_dqs_p),

            .ddr3_addr(ddr3_addr),
            .ddr3_ba(ddr3_ba),
            .ddr3_ras_n(ddr3_ras_n),
            .ddr3_cas_n(ddr3_cas_n),
            .ddr3_we_n(ddr3_we_n),
            .ddr3_reset_n(ddr3_reset_n),
            .ddr3_ck_p(ddr3_ck_p),
            .ddr3_ck_n(ddr3_ck_n),
            .ddr3_cke(ddr3_cke),
            .ddr3_cs_n(ddr3_cs_n),
            .ddr3_dm(ddr3_dm),
            .ddr3_odt(ddr3_odt)
        );

        //==================================================
        // NPU instance
        //==================================================
        npu_slave u_npu_slave(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),

            .npu_request(npu_request),
            .npu_re(npu_re),
            .npu_we(npu_we),
            .npu_wstrb(npu_wstrb),
            .npu_addr(npu_addr),
            .npu_wdata(npu_wdata),

            .npu_ready(npu_ready),
            .npu_rdata(npu_rdata),

            .npu_irq(npu_irq)
        );

        //==================================================
        // DMA instance
        //==================================================
        dma_slave u_dma_slave(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),

            // =========================
            // CPU / MMIO Slave Port
            // =========================
            .s_request(dma_s_request),
            .s_re(dma_s_re),
            .s_we(dma_s_we),
            .s_wstrb(dma_s_wstrb),
            .s_addr(dma_s_addr),
            .s_wdata(dma_s_wdata),

            .s_ready(dma_s_ready),
            .s_rdata(dma_s_rdata),

            // =========================
            // Bus Master Port
            // =========================
            .m_request(dma_m_request),
            .m_re(dma_m_re),
            .m_we(dma_m_we),
            .m_wstrb(dma_m_wstrb),
            .m_addr(dma_m_addr),
            .m_wdata(dma_m_wdata),

            .m_ready(dma_m_ready),
            .m_rdata(dma_m_rdata),
            .m_resp(dma_m_resp),

            // =========================
            // Status
            // =========================
            .dma_irq(dma_irq)
        );

        //==================================================
        // PERF instance
        //==================================================
        performance_counter_slave u_performance_counter_slave(
            .clk(clk_cpu_50),
            .rst_n(cpu_rst_n),

            .instr_event(cpu_instr_event),
            .stall_event(cpu_stall_event),

            .perf_request(perf_request),
            .perf_re(perf_re),
            .perf_we(perf_we),
            .perf_wstrb(perf_wstrb),
            .perf_addr(perf_addr),
            .perf_wdata(perf_wdata),

            .perf_ready(perf_ready),
            .perf_rdata(perf_rdata)
        );

        //==================================================
        // FAULT instance
        //==================================================
        fault_status u_fault_status (
            .clk           (clk_cpu_50),
            .rst_n         (cpu_rst_n),

            // transaction monitor
            .txn_done      (txn_done),
            .txn_source    (txn_source),
            .txn_write     (txn_write),
            .txn_addr      (txn_addr),
            .txn_resp      (txn_resp),

            // MMIO
            .fault_request (fault_request),
            .fault_re      (fault_re),
            .fault_we      (fault_we),
            .fault_wstrb   (fault_wstrb),
            .fault_addr    (fault_addr),
            .fault_wdata   (fault_wdata),

            .fault_ready   (fault_ready),
            .fault_rdata   (fault_rdata)
        );

endmodule
