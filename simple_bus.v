`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/23 15:03:07
// Design Name: 
// Module Name: simple_bus
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 1. 地址译码
// 2. 写请求分发
// 3. 读数据返回选择
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module simple_bus(
        input              clk,
        input              rst,
        input              cpu_en,

        //================ CPU master =================
        input              cpu_read,
        input              cpu_write,
        input      [3:0]   cpu_wstrb,
        input      [31:0]  cpu_addr,
        input      [31:0]  cpu_wdata,
        output reg [31:0]  cpu_rdata,

        //================ BRAM slave =================
        output             ram_re,
        output             ram_we,
        output     [3:0]   ram_wstrb,
        output     [31:0]  ram_addr,
        output     [31:0]  ram_wdata,
        input      [31:0]  ram_rdata,

        //================ GPIO slave =================
        output             gpio_re,
        output             gpio_we,
        output     [3:0]   gpio_wstrb,
        output     [7:0]   gpio_addr,
        output     [31:0]  gpio_wdata,
        input      [31:0]  gpio_rdata,

        //================ UART slave =================
        output             uart_re,
        output             uart_we,
        output     [3:0]   uart_wstrb,
        output     [7:0]   uart_addr,
        output     [31:0]  uart_wdata,
        input      [31:0]  uart_rdata,

        //================ Timer slave =================
        output             timer_re,
        output             timer_we,
        output     [3:0]   timer_wstrb,
        output     [7:0]   timer_addr,
        output     [31:0]  timer_wdata,
        input      [31:0]  timer_rdata,

        //================ IRQ slave =================
        output             irq_re,
        output             irq_we,
        output     [3:0]   irq_wstrb,
        output     [7:0]   irq_addr,
        output     [31:0]  irq_wdata,
        input      [31:0]  irq_rdata
    );

    //==================================================
    // M stage address decode
    //==================================================

    // 0x0001_0000 ~ 0x0001_FFFF 其中0x0001_F000 ~ 0x0001_FFFF保留给栈
    wire sel_ram;

    // 0x1000_0000 ~ 0x1000_00FF
    wire sel_gpio;

    // 0x1000_1000 ~ 0x1000_10FF
    wire sel_uart;

    // 0x1000_2000 ~ 0x1000_20FF
    wire sel_timer;

    // 0x1000_3000 ~ 0x1000_30FF
    wire sel_irq;


    // 字节写使能
    wire [3:0] ram_wstrb;
    wire [3:0] gpio_wstrb;
    wire [3:0] uart_wstrb;
    wire [3:0] timer_wstrb;
    wire [3:0] irq_wstrb;
    
    
    // ram
    assign sel_ram = (cpu_addr[31:16] == 16'h0001);

    // gpio
    assign sel_gpio = (cpu_addr[31:8] == 24'h100000);
    
    // uart
    assign sel_uart = (cpu_addr[31:8] == 24'h100010);

    // timer
    assign sel_timer = (cpu_addr[31:8] == 24'h100020);

    // irq
    assign sel_irq = (cpu_addr[31:8] == 24'h100030);

    //==================================================
    // Write / Read request distribution
    //==================================================

    // ram
    assign ram_re = cpu_en && sel_ram && cpu_read ;

    assign ram_we = cpu_en && sel_ram && cpu_write;

    assign ram_wstrb = cpu_wstrb;

    assign ram_addr = (cpu_addr - 32'h0001_0000) >> 2;

    assign ram_wdata = cpu_wdata;

    // gpio
    assign gpio_re = cpu_en && sel_gpio && cpu_read;

    assign gpio_we = cpu_en && sel_gpio && cpu_write;

    assign gpio_wstrb = cpu_wstrb;

    assign gpio_addr = cpu_addr[7:0] >> 2;

    assign gpio_wdata = cpu_wdata;

    // uart
    assign uart_re = cpu_en && sel_uart && cpu_read;

    assign uart_we = cpu_en && sel_uart && cpu_write;

    assign uart_wstrb = cpu_wstrb;

    assign uart_addr = cpu_addr[7:0];

    assign uart_wdata = cpu_wdata;

    // timer
    assign timer_re = cpu_en && sel_timer && cpu_read;

    assign timer_we = cpu_en && sel_timer && cpu_write;

    assign timer_wstrb = cpu_wstrb;

    assign timer_addr = cpu_addr[7:0];

    assign timer_wdata = cpu_wdata;

    // irq
    assign irq_re = cpu_en && sel_irq && cpu_read;

    assign irq_we = cpu_en && sel_irq && cpu_write;

    assign irq_wstrb = cpu_wstrb;

    assign irq_addr = cpu_addr[7:0];

    assign irq_wdata = cpu_wdata;

    //==================================================
    // Read source pipeline: M -> DM
    //==================================================

    reg sel_ram_next;
    reg sel_gpio_next;
    reg sel_uart_next;
    reg sel_timer_next;
    reg sel_irq_next;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sel_ram_next  <= 1'b0;
            sel_gpio_next <= 1'b0;
            sel_uart_next <= 1'b0;
            sel_timer_next <= 1'b0;
            sel_irq_next <= 1'b0;
        end
        else if (cpu_en) begin
            sel_ram_next  <= sel_ram  && cpu_read;
            sel_gpio_next <= sel_gpio && cpu_read;
            sel_uart_next <= sel_uart && cpu_read;
            sel_timer_next <= sel_timer && cpu_read;
            sel_irq_next <= sel_irq && cpu_read;
        end
    end


    //==================================================
    // DM stage read-data mux
    //==================================================

    always @(*) begin
        if (sel_ram_next)
            cpu_rdata = ram_rdata;
        else if (sel_gpio_next)
            cpu_rdata = gpio_rdata;
        else if (sel_uart_next) begin
            cpu_rdata = uart_rdata;
        end else if (sel_timer_next) begin
            cpu_rdata = timer_rdata;
        end else if (sel_irq_next) begin
            cpu_rdata = irq_rdata;
        end else begin
            cpu_rdata = 32'b0;
        end
    end

    


endmodule
