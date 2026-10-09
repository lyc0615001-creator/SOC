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

        output             cpu_irq,

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

        //================ SLOW slave =================
        wire              slow_request;
        wire              slow_re;
        wire              slow_we;
        wire      [7:0]   slow_addr;
        wire      [3:0]   slow_wstrb;
        wire      [31:0]  slow_wdata;

        wire              slow_ready;
        wire      [31:0]  slow_rdata;

        //================ DDR slave =================
        wire              ddr_request;
        wire              ddr_re;
        wire              ddr_we;
        wire      [31:0]  ddr_addr;
        wire      [3:0]   ddr_wstrb;
        wire      [31:0]  ddr_wdata;

        wire              ddr_ready;
        wire      [31:0]  ddr_rdata;


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
        // bus instance
        //==================================================

        simple_bus u_simple_bus(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),
            .cpu_en(cpu_en),

            //================ CPU master =================
            .cpu_request(cpu_request),
            .cpu_read(cpu_read),
            .cpu_write(cpu_write),
            .cpu_wstrb(cpu_wstrb),
            .cpu_addr(cpu_addr),
            .cpu_wdata(cpu_wdata),

            .cpu_ready(cpu_ready),
            .cpu_rdata(cpu_rdata),

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

            //================ TIMER slave =================
            .irq_request(irq_request),
            .irq_re(irq_re),
            .irq_we(irq_we),
            .irq_wstrb(irq_wstrb),
            .irq_addr(irq_addr),
            .irq_wdata(irq_wdata),

            .irq_ready(irq_ready),
            .irq_rdata(irq_rdata),

            //================ SLOW slave =================
            .slow_request(slow_request),
            .slow_re(slow_re),
            .slow_we(slow_we),
            .slow_wstrb(slow_wstrb),
            .slow_addr(slow_addr),
            .slow_wdata(slow_wdata),

            .slow_ready(slow_ready),
            .slow_rdata(slow_rdata),
            
            //================ SLOW slave =================
            .ddr_request(ddr_request),
            .ddr_re(ddr_re),
            .ddr_we(ddr_we),
            .ddr_wstrb(ddr_wstrb),
            .ddr_addr(ddr_addr),
            .ddr_wdata(ddr_wdata),

            .ddr_ready(ddr_ready),
            .ddr_rdata(ddr_rdata)
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
        // SLOW instance   ***ERROR !!!! 写数据与ready不同步
        //==================================================
        slow_slave tb_u_slow_slave(
            .clk(clk_cpu_50),
            .rst(cpu_rst_n),
            .req(slow_request),
            .read(slow_re),
            .write(slow_we),
            .wstrb(slow_wstrb),
            .addr(slow_addr),
            .wdata(slow_wdata),

            .rdata(slow_rdata),
            .ready(slow_ready)
        );

        //==================================================
        // ddr_subsystem instance   
        //==================================================
        ddr_subsystem u_ddr_subsystem(
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


endmodule
