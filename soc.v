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
        output    [3:0]    led
        
    );
        //================ CPU master =================
        wire              mem_readM;
        wire              mem_writeM;
        wire      [31:0]  cpu_addrM;
        wire      [31:0]  cpu_wdataM;
        wire      [31:0]  cpu_rdataDM;

        wire              rom_en;
        wire      [31:0]  pc_oF;
        wire      [31:0]  instrIM;

        //================ BRAM slave =================
        wire              ram_reM;
        wire              ram_weM;
        wire      [31:0]  ram_addrM;
        wire      [31:0]  ram_wdataM;
        wire      [31:0]  ram_rdataDM;

        //================ GPIO slave =================
        wire              gpio_reM;
        wire              gpio_weM;
        wire      [7:0]   gpio_addrM;
        wire      [31:0]  gpio_wdataM;
        wire      [31:0]  gpio_rdataDM;


        //==================================================
        // CPU instance
        //==================================================
        CPU_TOP u_CPU_TOP(
            .clk(clk),
            .rst(rst),
            .cpu_rdataDM(cpu_rdataDM), // 获得读数据
            .cpu_en(cpu_en), // 分频信号
            .mem_readM(mem_readM), // 读使能
            .mem_writeM(mem_writeM), // 写使能
            .cpu_addrM(cpu_addrM), // 读写地址
            .cpu_wdataM(cpu_wdataM), // 写数据
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
            .mem_readM(mem_readM),
            .mem_writeM(mem_writeM),
            .cpu_addrM(cpu_addrM),
            .cpu_wdataM(cpu_wdataM),
            .cpu_rdataDM(cpu_rdataDM),

            //================ BRAM slave =================
            .ram_reM(ram_reM),
            .ram_weM(ram_weM),
            .ram_addrM(ram_addrM),
            .ram_wdataM(ram_wdataM),
            .ram_rdataDM(ram_rdataDM),

            //================ GPIO slave =================
            .gpio_reM(gpio_reM),
            .gpio_weM(gpio_weM),
            .gpio_addrM(gpio_addrM),
            .gpio_wdataM(gpio_wdataM),
            .gpio_rdataDM(gpio_rdataDM)
        );


        //==================================================
        // bram instance
        //==================================================
        bram_ram #(15) u_bram_ram(
            .clk(clk),
            .ram_reM(ram_reM),
            .ram_weM(ram_weM),
            .ram_addrM(ram_addrM),
            .ram_wdataM(ram_wdataM),
            .ram_rdataDM(ram_rdataDM)
        );

        //==================================================
        // gpio instance
        //==================================================
        gpio_mmio u_gpio_mmio(
            .clk(clk),
            .rst(rst),
            .gpio_reM(gpio_reM),
            .gpio_weM(gpio_weM),
            .gpio_addrM(gpio_addrM),
            .gpio_wdataM(gpio_wdataM),
            .gpio_rdataDM(gpio_rdataDM),
            .led(led)
        );
    
endmodule
