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


module soc(
        input              clk,
        input              rst,
        output    [3:0]    led,
        
        output             tx,
        input              rx
    );
        //================ CPU master =================
        wire              cpu_read;
        wire              cpu_write;
        wire      [3:0]   cpu_wstrb;
        wire      [31:0]  cpu_addr;
        wire      [31:0]  cpu_wdata;
        wire      [31:0]  cpu_rdata;

        wire              rom_en;
        wire      [31:0]  pc_oF;
        wire      [31:0]  instrIM;

        wire              cpu_en;

        //================ BRAM slave =================
        wire              ram_re;
        wire              ram_we;
        wire      [3:0]   ram_wstrb;
        wire      [31:0]  ram_addr;
        wire      [31:0]  ram_wdata;
        wire      [31:0]  ram_rdata;

        //================ GPIO slave =================
        wire              gpio_re;
        wire              gpio_we;
        wire      [3:0]   gpio_wstrb;
        wire      [7:0]   gpio_addr;
        wire      [31:0]  gpio_wdata;
        wire      [31:0]  gpio_rdata;

        //================ UART slave =================
        wire              uart_re;
        wire              uart_we;
        wire      [3:0]   uart_wstrb;
        wire      [7:0]   uart_addr;
        wire      [31:0]  uart_wdata;
        wire      [31:0]  uart_rdata;

        //================ TIMER slave =================
        wire              timer_re;
        wire              timer_we;
        wire      [3:0]   timer_wstrb;
        wire      [7:0]   timer_addr;
        wire      [31:0]  timer_wdata;
        wire      [31:0]  timer_rdata;

        wire              timer_irq;

        //================ TIMER slave =================
        wire              irq_re;
        wire              irq_we;
        wire      [3:0]   irq_wstrb;
        wire      [7:0]   irq_addr;
        wire      [31:0]  irq_wdata;
        wire      [31:0]  irq_rdata;

        wire              cpu_irq;


        //==================================================
        // CPU instance
        //==================================================
        CPU_TOP u_CPU_TOP(
            .clk(clk),
            .rst(rst),
            .cpu_rdataDM(cpu_rdata), // 获得读数据
            .cpu_en(cpu_en), // 分频信号
            .cpu_readM(cpu_read), // 读使能
            .cpu_writeM(cpu_write), // 写使能
            .cpu_wstrbM(cpu_wstrb), // 字节写使能
            .cpu_addrM(cpu_addr), // 读写地址
            .cpu_wdataM(cpu_wdata), // 写数据
            .irq(cpu_irq), // 中断使能
            // instr
            .rom_en(rom_en),
            .pc_oF(pc_oF),
            .instrIM(instrIM)
        );

        //==================================================
        // instruction instance
        //==================================================
        boot_rom #(10) u_boot_rom(
            .clk(clk),
            .en(rom_en),
            .pc(pc_oF),
            .instr(instrIM)
        );

        //==================================================
        // bus instance
        //==================================================

        simple_bus u_simple_bus(
            .clk(clk),
            .rst(rst),
            .cpu_en(cpu_en),

            //================ CPU master =================
            .cpu_read(cpu_read),
            .cpu_write(cpu_write),
            .cpu_wstrb(cpu_wstrb),
            .cpu_addr(cpu_addr),
            .cpu_wdata(cpu_wdata),
            .cpu_rdata(cpu_rdata),

            //================ BRAM slave =================
            .ram_re(ram_re),
            .ram_we(ram_we),
            .ram_wstrb(ram_wstrb),
            .ram_addr(ram_addr),
            .ram_wdata(ram_wdata),
            .ram_rdata(ram_rdata),

            //================ GPIO slave =================
            .gpio_re(gpio_re),
            .gpio_we(gpio_we),
            .gpio_wstrb(gpio_wstrb),
            .gpio_addr(gpio_addr),
            .gpio_wdata(gpio_wdata),
            .gpio_rdata(gpio_rdata),

            //================ UART slave =================
            .uart_re(uart_re),
            .uart_we(uart_we),
            .uart_wstrb(uart_wstrb),
            .uart_addr(uart_addr),
            .uart_wdata(uart_wdata),
            .uart_rdata(uart_rdata),

            //================ TIMER slave =================
            .timer_re(timer_re),
            .timer_we(timer_we),
            .timer_wstrb(timer_wstrb),
            .timer_addr(timer_addr),
            .timer_wdata(timer_wdata),
            .timer_rdata(timer_rdata),

            //================ TIMER slave =================
            .irq_re(irq_re),
            .irq_we(irq_we),
            .irq_wstrb(irq_wstrb),
            .irq_addr(irq_addr),
            .irq_wdata(irq_wdata),
            .irq_rdata(irq_rdata)
        );


        //==================================================
        // bram instance
        //==================================================
        bram_ram #(15) u_bram_ram(
            .clk(clk),
            .ram_re(ram_re),
            .ram_we(ram_we),
            .ram_wstrb(ram_wstrb),
            .ram_addr(ram_addr),
            .ram_wdata(ram_wdata),
            .ram_rdata(ram_rdata)
        );

        //==================================================
        // gpio instance
        //==================================================
        gpio_mmio u_gpio_mmio(
            .clk(clk),
            .rst(rst),
            .gpio_re(gpio_re),
            .gpio_we(gpio_we),
            .gpio_wstrb(gpio_wstrb),
            .gpio_addr(gpio_addr),
            .gpio_wdata(gpio_wdata),
            .gpio_rdata(gpio_rdata),
            .led(led)
        );


        //==================================================
        // UART instance
        //==================================================
        uart u_uart(
            .clk(clk),
            .rst(rst),

            // bus interface
            .uart_re(uart_re),
            .uart_we(uart_we),
            .uart_wstrb(uart_wstrb),
            .uart_addr(uart_addr),
            .uart_wdata(uart_wdata),
            .uart_rdata(uart_rdata),

            // physical pins
            .rx(rx),
            .tx(tx)
        );

        //==================================================
        // TIMER instance
        //==================================================
        timer_mimo u_timer_mimo(
            .clk(clk),
            .rst(rst),

            .timer_re(timer_re),
            .timer_we(timer_we),
            .timer_wstrb(timer_wstrb),
            .timer_addr(timer_addr),
            .timer_wdata(timer_wdata),

            .timer_rdata(timer_rdata),
            .timer_irq(timer_irq)
        );

        //==================================================
        // IRQ instance
        //==================================================
        irq_controller u_irq_controller(
            .clk(clk),
            .rst(rst),

            // interrupt sources
            .timer_irq(timer_irq),

            // MMIO
            .irq_re(irq_re),
            .irq_we(irq_we),
            .irq_wstrb(irq_wstrb),
            .irq_addr(irq_addr),
            .irq_wdata(irq_wdata),
            .irq_rdata(irq_rdata),

            // CPU
            .cpu_irq(cpu_irq)
        );

endmodule
