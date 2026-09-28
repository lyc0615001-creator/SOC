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
        wire              mem_read;
        wire              mem_write;
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
        wire      [31:0]  ram_addr;
        wire      [31:0]  ram_wdata;
        wire      [31:0]  ram_rdata;

        //================ GPIO slave =================
        wire              gpio_re;
        wire              gpio_we;
        wire      [7:0]   gpio_addr;
        wire      [31:0]  gpio_wdata;
        wire      [31:0]  gpio_rdata;

        //================ UART slave =================
        wire              uart_re;
        wire              uart_we;
        wire      [7:0]   uart_addr;
        wire      [31:0]  uart_wdata;
        wire      [31:0]  uart_rdata;


        //==================================================
        // CPU instance
        //==================================================
        CPU_TOP u_CPU_TOP(
            .clk(clk),
            .rst(rst),
            .cpu_rdataDM(cpu_rdata), // 获得读数据
            .cpu_en(cpu_en), // 分频信号
            .mem_readM(mem_read), // 读使能
            .mem_writeM(mem_write), // 写使能
            .cpu_addrM(cpu_addr), // 读写地址
            .cpu_wdataM(cpu_wdata), // 写数据
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
            .mem_read(mem_read),
            .mem_write(mem_write),
            .cpu_addr(cpu_addr),
            .cpu_wdata(cpu_wdata),
            .cpu_rdata(cpu_rdata),

            //================ BRAM slave =================
            .ram_re(ram_re),
            .ram_we(ram_we),
            .ram_addr(ram_addr),
            .ram_wdata(ram_wdata),
            .ram_rdata(ram_rdata),

            //================ GPIO slave =================
            .gpio_re(gpio_re),
            .gpio_we(gpio_we),
            .gpio_addr(gpio_addr),
            .gpio_wdata(gpio_wdata),
            .gpio_rdata(gpio_rdata),

            //================ UART slave =================
            .uart_re(uart_re),
            .uart_we(uart_we),
            .uart_addr(uart_addr),
            .uart_wdata(uart_wdata),
            .uart_rdata(uart_rdata)
        );


        //==================================================
        // bram instance
        //==================================================
        bram_ram #(15) u_bram_ram(
            .clk(clk),
            .ram_re(ram_re),
            .ram_we(ram_we),
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
        .uart_addr(uart_addr),
        .uart_wdata(uart_wdata),
        .uart_rdata(uart_rdata),

        // physical pins
        .rx(rx),
        .tx(tx)
    );
    
endmodule
