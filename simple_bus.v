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
        input              mem_readM,
        input              mem_writeM,
        input      [31:0]  cpu_addrM,
        input      [31:0]  cpu_wdataM,
        output reg [31:0]  cpu_rdataDM,

        //================ BRAM slave =================
        output             ram_reM,
        output             ram_weM,
        output     [31:0]  ram_addrM,
        output     [31:0]  ram_wdataM,
        input      [31:0]  ram_rdataDM,

        //================ GPIO slave =================
        output             gpio_reM,
        output             gpio_weM,
        output     [7:0]   gpio_addrM,
        output     [31:0]  gpio_wdataM,
        input      [31:0]  gpio_rdataDM
    );

    //==================================================
    // M stage address decode
    //==================================================

    // 0x0001_0000 ~ 0x0001_FFFF
    wire sel_ramM;

    // 正式地址：0x1000_0000 ~ 0x1000_00FF
    wire sel_gpio_mainM;

    // Lab5 临时 alias：0x0000_4000 ~ 0x0000_40FF
    wire sel_gpio_aliasM;

    wire sel_gpioM;

    assign sel_ramM = (cpu_addrM[31:16] == 16'h0001);

    assign sel_gpio_mainM = (cpu_addrM[31:8] == 24'h100000);

    assign sel_gpio_aliasM = (cpu_addrM[31:8] == 24'h000040);
    
    assign sel_gpioM = sel_gpio_mainM | sel_gpio_aliasM;


    //==================================================
    // Write / Read request distribution
    //==================================================

    assign ram_reM = cpu_en && sel_ramM && mem_readM ;

    assign ram_weM = cpu_en && sel_ramM && mem_writeM;

    assign ram_addrM = (cpu_addrM - 32'h0001_0000) >> 2;

    assign ram_wdataM = cpu_wdataM;

    assign gpio_reM = cpu_en && sel_gpioM && mem_readM;

    assign gpio_weM = cpu_en && sel_gpioM && mem_writeM;

    assign gpio_addrM = cpu_addrM[7:0] >> 2;

    assign gpio_wdataM = cpu_wdataM;


    //==================================================
    // Read source pipeline: M -> DM
    //==================================================

    reg sel_ramDM;
    reg sel_gpioDM;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sel_ramDM  <= 1'b0;
            sel_gpioDM <= 1'b0;
        end
        else if (cpu_en) begin
            sel_ramDM  <= sel_ramM  && mem_readM;
            sel_gpioDM <= sel_gpioM && mem_readM;
        end
    end


    //==================================================
    // DM stage read-data mux
    //==================================================

    always @(*) begin
        if (sel_ramDM)
            cpu_rdataDM = ram_rdataDM;
        else if (sel_gpioDM)
            cpu_rdataDM = gpio_rdataDM;
        else
            cpu_rdataDM = 32'b0;
    end

    


endmodule
