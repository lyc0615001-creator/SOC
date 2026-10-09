// `default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/08 20:55:54
// Design Name: 
// Module Name: TOP
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
        input              rx,

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

    //================ CPU master =================
    wire              cpu_read;
    wire              cpu_write;
    wire      [3:0]   cpu_wstrb;
    wire      [31:0]  cpu_addr;
    wire      [31:0]  cpu_wdata;
    wire      [31:0]  cpu_rdata;

    wire              rom_en;
    wire      [31:0]  pc_oF;
    wire      [31:0]  instr;

    wire              cpu_en;

    wire              cpu_request;
    wire              cpu_ready;

    wire              cpu_irq;

    //================ CLK WIZ master =================

    wire clk_cpu_50;

    wire clk_mig_160;

    wire clk_ref_200;

    wire mig_rst_n;  // DDR-mig复位信号，低有效

    wire cpu_rst_n;  // 全局cpu复位信号，低有效


    clk_rst_manage u_clk_rst_manage(
        .clk(clk),
        .rst(rst),

        .clk_cpu_50(clk_cpu_50),
        .clk_mig_160(clk_mig_160),
        .clk_ref_200(clk_ref_200),

        .cpu_rst_n(cpu_rst_n),
        .mig_rst_n(mig_rst_n)
    );

    //==================================================
    // CPU instance
    //==================================================
    
    CPU_TOP u_CPU_TOP(
        .clk(clk_cpu_50),
        .rst(cpu_rst_n),
        .cpu_rdataM(cpu_rdata), // 获得读数据
        .cpu_en(cpu_en), // 分频信号
        .cpu_readM(cpu_read), // 读使能
        .cpu_writeM(cpu_write), // 写使能
        .cpu_wstrbM(cpu_wstrb), // 字节写使能
        .cpu_addrM(cpu_addr), // 读写地址
        .cpu_wdataM(cpu_wdata), // 写数据
        .irq(cpu_irq), // 中断使能
        .cpu_ready(cpu_ready), // 事务结束
        // instr
        .rom_en(rom_en),
        .pc_oF(pc_oF),
        .instrIM(instr),
        .cpu_requestM(cpu_request)
    );


    //==================================================
    // SLAVE instance
    //==================================================

    slave u_slave(
        .clk_cpu_50(clk_cpu_50),
        .clk_mig_160(clk_mig_160),
        .clk_ref_200(clk_ref_200),
        .sys_rst_n(rst),  
        .cpu_rst_n(cpu_rst_n),
        .mig_rst_n(mig_rst_n),

        .led(led),
        
        .tx(tx),
        .rx(rx),

        // CPU
        .rom_en(rom_en),
        .pc_oF(pc_oF),
        .instr(instr),
        .cpu_en(cpu_en),

        .cpu_request(cpu_request),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .cpu_wstrb(cpu_wstrb),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),

        .cpu_ready(cpu_ready),
        .cpu_rdata(cpu_rdata),

        .cpu_irq(cpu_irq),

        // DDR
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
