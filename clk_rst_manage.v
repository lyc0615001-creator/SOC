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


module clk_rst_manage(
        input              clk,
        input              rst,

        output             clk_cpu_50,

        output             clk_mig_160,

        output             clk_ref_200,

        output             cpu_rst_n,

        output             mig_rst_n
    );

    wire mig_rst_n;  // DDR-mig复位信号，低有效

    assign mig_rst_n = rst && clk_locked;

    wire cpu_reset_src_n;

    assign cpu_reset_src_n  = rst && clk_locked;

    clk_wiz_ddr u_clk_wiz_ddr (
        .clk_out1 (clk_cpu_50),
        .clk_out2 (clk_mig_160),
        .clk_out3 (clk_ref_200),

        .resetn   (1'b1),
        .locked   (clk_locked),

        .clk_in1  (clk)
    );

    cpu_system_rst u_cpu_system_rst(
        .clk_cpu_50(clk_cpu_50),
        .rst_n(cpu_reset_src_n),
        .cpu_rst_n(cpu_rst_n)
    );


endmodule
