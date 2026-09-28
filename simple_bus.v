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
        input              mem_read,
        input              mem_write,
        input      [31:0]  cpu_addr,
        input      [31:0]  cpu_wdata,
        output reg [31:0]  cpu_rdata,

        //================ BRAM slave =================
        output             ram_re,
        output             ram_we,
        output     [31:0]  ram_addr,
        output     [31:0]  ram_wdata,
        input      [31:0]  ram_rdata,

        //================ GPIO slave =================
        output             gpio_re,
        output             gpio_we,
        output     [7:0]   gpio_addr,
        output     [31:0]  gpio_wdata,
        input      [31:0]  gpio_rdata,

        //================ UART slave =================
        output             uart_re,
        output             uart_we,
        output     [7:0]   uart_addr,
        output     [31:0]  uart_wdata,
        input      [31:0]  uart_rdata
    );

    //==================================================
    // M stage address decode
    //==================================================

    // 0x0001_0000 ~ 0x0001_FFFF
    wire sel_ram;

    // 正式地址：0x1000_0000 ~ 0x1000_00FF
    wire sel_gpio_main;

    // Lab5 临时 alias：0x0000_4000 ~ 0x0000_40FF
    wire sel_gpio_alias;

    wire sel_gpio;

    // 正式地址：0x1000_1000 ~ 0x1000_10FF
    wire sel_uart_main;

    // lab6 临时 alias：0x0000_4100 ~ 0x0000_41FF
    wire sel_uart_alias;

    wire sel_uart;
    
    
    // ram
    assign sel_ram = (cpu_addr[31:16] == 16'h0001);

    // gpio
    assign sel_gpio_main = (cpu_addr[31:8] == 24'h100000);

    assign sel_gpio_alias = (cpu_addr[31:8] == 24'h000040);
    
    assign sel_gpio = sel_gpio_main | sel_gpio_alias;

    
    // uart
    assign sel_uart_main = (cpu_addr[31:8] == 24'h100010);

    assign sel_uart_alias = (cpu_addr[31:8] == 24'h000041);

    assign sel_uart = sel_uart_main | sel_uart_alias;


    //==================================================
    // Write / Read request distribution
    //==================================================

    // ram
    assign ram_re = cpu_en && sel_ram && mem_read ;

    assign ram_we = cpu_en && sel_ram && mem_write;

    assign ram_addr = (cpu_addr - 32'h0001_0000) >> 2;

    assign ram_wdata = cpu_wdata;

    // gpio
    assign gpio_re = cpu_en && sel_gpio && mem_read;

    assign gpio_we = cpu_en && sel_gpio && mem_write;

    assign gpio_addr = cpu_addr[7:0] >> 2;

    assign gpio_wdata = cpu_wdata;

    // uart
    assign uart_re = cpu_en && sel_uart && mem_read;

    assign uart_we = cpu_en && sel_uart && mem_write;

    assign uart_addr = cpu_addr[7:0];

    assign uart_wdata = cpu_wdata;

    //==================================================
    // Read source pipeline: M -> DM
    //==================================================

    reg sel_ram_next;
    reg sel_gpio_next;
    reg sel_uart_next;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sel_ram_next  <= 1'b0;
            sel_gpio_next <= 1'b0;
            sel_uart_next <= 1'b0;
        end
        else if (cpu_en) begin
            sel_ram_next  <= sel_ram  && mem_read;
            sel_gpio_next <= sel_gpio && mem_read;
            sel_uart_next <= sel_uart && mem_read;
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
        end else begin
            cpu_rdata = 32'b0;
        end
    end

    


endmodule
