`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/02 13:53:50
// Design Name: 
// Module Name: irq_controller
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


module irq_controller(
        input                clk,
        input                rst,

        // interrupt sources
        input                timer_irq,

        // MMIO
        input                irq_re,
        input                irq_we,
        input      [3:0]     irq_wstrb,
        input      [7:0]     irq_addr,
        input      [31:0]    irq_wdata,
        output reg [31:0]    irq_rdata,

        // CPU
        output        cpu_irq
    );

    // 0x10003000  PENDING   Ö»¶Á
    // 0x10003004  MASK      ¶ÁÐ´
    localparam  PENDING =  8'h00;
    localparam  MASK    =  8'h04;

    wire [31:0] irq_pending;

    assign irq_pending = {31'd0, timer_irq};

    reg [31:0] irq_mask;

    assign cpu_irq = |(irq_pending & irq_mask);

    //================================================
    // MMIO read decode
    //================================================
    wire re_pending;

    wire re_mask;

    assign re_pending = irq_re && irq_addr == PENDING;

    assign re_mask    = irq_re && irq_addr == MASK;

    //================================================
    // MMIO read data
    //================================================
    wire wr_mask;

    assign wr_mask = irq_we && irq_addr == MASK;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            irq_mask <= 32'd0;
            irq_rdata = 32'd0;
        end else begin
            if (wr_mask) begin
                if (irq_wstrb[0]) begin
                    irq_mask[7:0] <= irq_wdata[7:0];
                end
                if (irq_wstrb[1]) begin
                    irq_mask[15:8] <= irq_wdata[15:8];
                end
                if (irq_wstrb[2]) begin
                    irq_mask[23:16] <= irq_wdata[23:16];
                end
                if (irq_wstrb[3]) begin
                    irq_mask[31:24] <= irq_wdata[31:24];
                end
            end

            if (re_pending) begin
                irq_rdata <= irq_pending;
            end

            if (re_mask) begin
                irq_rdata <= irq_mask;
            end
        end
        
        
    end

endmodule
