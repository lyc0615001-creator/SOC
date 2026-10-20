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
        input              cpu_request,
        input              cpu_read,
        input              cpu_write,
        input      [3:0]   cpu_wstrb,
        input      [31:0]  cpu_addr,
        input      [31:0]  cpu_wdata,

        output reg         cpu_ready,
        output reg [31:0]  cpu_rdata,

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

        //================ SLOW slave =================
        output             slow_request,
        output             slow_re,
        output             slow_we,
        output     [3:0]   slow_wstrb,
        output     [7:0]   slow_addr,
        output     [31:0]  slow_wdata,

        input              slow_ready,
        input      [31:0]  slow_rdata,

        //================ DDR slave =================
        output             ddr_request,
        output             ddr_re,
        output             ddr_we,
        output     [3:0]   ddr_wstrb,
        output     [31:0]  ddr_addr,
        output     [31:0]  ddr_wdata,

        input              ddr_ready,
        input      [31:0]  ddr_rdata
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

    // 0x1000_5000 ~ 0x1000_50FF
    wire sel_slow;

    // 0x8000_0000 ~ 0x87FF_FFFF
    wire sel_ddr;
    

    // 锁存当前事务的数据
    reg [31:0] latched_addr;
    reg [31:0] latched_wdata;
    reg [3:0]  latched_wstrb;
    reg        latched_read;
    reg        latched_write;
    
    
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

    // slow
    assign sel_slow = (cpu_addr[31:8] == 24'h100050);

    // ddr
    assign sel_ddr = (cpu_addr[31:27] == 5'b10000);

    //==================================================
    // Write / Read request distribution
    //==================================================

    // ram
    assign ram_re = cpu_en && sel_ram && latched_read ;

    assign ram_we = cpu_en && sel_ram && latched_write;

    assign ram_wstrb = latched_wstrb;

    assign ram_addr = (latched_addr - 32'h0001_0000) >> 2;

    assign ram_wdata = latched_wdata;

    // gpio
    assign gpio_re = cpu_en && sel_gpio && latched_read;

    assign gpio_we = cpu_en && sel_gpio && latched_write;

    assign gpio_wstrb = latched_wstrb;

    assign gpio_addr = latched_addr[7:0] >> 2;

    assign gpio_wdata = latched_wdata;

    // uart
    assign uart_re = cpu_en && sel_uart && latched_read;

    assign uart_we = cpu_en && sel_uart && latched_write;

    assign uart_wstrb = latched_wstrb;

    assign uart_addr = latched_addr[7:0];

    assign uart_wdata = latched_wdata;

    // timer
    assign timer_re = cpu_en && sel_timer && latched_read;

    assign timer_we = cpu_en && sel_timer && latched_write;

    assign timer_wstrb = latched_wstrb;

    assign timer_addr = latched_addr[7:0];

    assign timer_wdata = latched_wdata;

    // irq
    assign irq_re = cpu_en && sel_irq && latched_read;

    assign irq_we = cpu_en && sel_irq && latched_write;

    assign irq_wstrb = latched_wstrb;

    assign irq_addr = latched_addr[7:0];

    assign irq_wdata = latched_wdata;

    // slow
    assign slow_re = cpu_en && sel_slow && latched_read;

    assign slow_we = cpu_en && sel_slow && latched_write;

    assign slow_wstrb = latched_wstrb;

    assign slow_addr = latched_addr[7:0];

    assign slow_wdata = latched_wdata;

    // ddr
    assign ddr_re = cpu_en && sel_ddr && latched_read;

    assign ddr_we = cpu_en && sel_ddr && latched_write;

    assign ddr_wstrb = latched_wstrb;

    assign ddr_addr = (latched_addr - 32'h8000_0000);

    assign ddr_wdata = latched_wdata;

    //==================================================
    // Read source pipeline: M -> ***
    //=================================================

    reg busy;

    // 000 none 001 RAM 010 GPIO 011 UART 100 TIMER 101 IRQ 110 SLOW
    reg [2:0] active_sel;

    localparam SEL_NONE  = 3'b000;
    localparam SEL_RAM   = 3'b001;
    localparam SEL_GPIO  = 3'b010;
    localparam SEL_UART  = 3'b011;
    localparam SEL_TIMER = 3'b100;
    localparam SEL_IRQ   = 3'b101;
    localparam SEL_SLOW  = 3'b110;
    localparam SEL_DDR   = 3'b111;

    wire transaction_done;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            latched_addr  <= 32'd0;
            latched_wdata <= 32'd0;
            latched_wstrb <= 4'd0;
            latched_read  <= 1'd0;
            latched_write <= 1'd0;
            active_sel    <= 3'd0;
            busy          <= 1'b0;
        end else begin
             if (!busy && cpu_request) begin
                busy <= 1'b1;
                latched_addr  <= cpu_addr;
                latched_wdata <= cpu_wdata;
                latched_wstrb <= cpu_wstrb;
                latched_read  <= cpu_read;
                latched_write <= cpu_write;
                
                if (sel_ram) active_sel <= SEL_RAM;
                else if (sel_gpio) active_sel <= SEL_GPIO;
                else if (sel_uart) active_sel <= SEL_UART;
                else if (sel_timer) active_sel <= SEL_TIMER;
                else if (sel_irq) active_sel <= SEL_IRQ;
                else if (sel_slow) active_sel <= SEL_SLOW;
                else if (sel_ddr) active_sel <= SEL_DDR;
                else active_sel <= SEL_NONE;
             end else if (transaction_done) begin
                busy <= 1'b0;
                active_sel <= SEL_NONE;
            end
        end
    end

    assign ram_request   = busy && active_sel == SEL_RAM;
    assign gpio_request  = busy && active_sel == SEL_GPIO;
    assign uart_request  = busy && active_sel == SEL_UART;
    assign timer_request = busy && active_sel == SEL_TIMER;
    assign irq_request   = busy && active_sel == SEL_IRQ;
    assign slow_request  = busy && active_sel == SEL_SLOW;
    assign ddr_request   = busy && active_sel == SEL_DDR;

    assign transaction_done = busy && cpu_ready;

    always @(*) begin
        cpu_ready = 1'b0;
        cpu_rdata = 32'd0;

        case (active_sel)
            SEL_RAM: begin
                cpu_rdata = ram_rdata;
                cpu_ready = ram_ready;
            end
            SEL_GPIO: begin
                cpu_rdata = gpio_rdata;
                cpu_ready = gpio_ready;
            end
            SEL_UART: begin
                cpu_rdata = uart_rdata;
                cpu_ready = uart_ready;
            end
            SEL_TIMER: begin
                cpu_rdata = timer_rdata;
                cpu_ready = timer_ready;
            end
            SEL_IRQ: begin
                cpu_rdata = irq_rdata;
                cpu_ready = irq_ready;
            end
            SEL_SLOW: begin
                cpu_rdata = slow_rdata;
                cpu_ready = slow_ready;
            end
            SEL_DDR: begin
                cpu_rdata = ddr_rdata;
                cpu_ready = ddr_ready;
            end
            SEL_NONE: begin
                cpu_rdata = 32'd0;
                cpu_ready = 1'd0;
            end
            default: begin
                cpu_rdata = 32'd0;
                cpu_ready = 1'd0;
            end
        endcase
    end
endmodule
