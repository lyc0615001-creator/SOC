`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/02 08:22:45
// Design Name: 
// Module Name: timer_mimo
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


module timer_mimo(
        input                clk,
        input                rst,

        input                timer_re,
        input                timer_we,
        input       [3:0]    timer_wstrb,
        input       [7:0]    timer_addr,
        input       [31:0]   timer_wdata,

        output reg  [31:0]   timer_rdata,
        output               timer_irq
    );

    localparam CTRL    = 8'h00;
    localparam COUNT   = 8'h04;
    localparam COMPARE = 8'h08;
    localparam STATUS  = 8'h0c;

    //========================
    // 状态寄存器
    //========================
    reg [31:0] count;
    reg [31:0] compare;
    reg        timer_en;
    reg        irq_en;   
    reg        pending;

    assign timer_irq = pending && irq_en;
    

    //================================================
    // MMIO write decode
    //================================================

    wire mimo_write;
    
    assign mimo_write = timer_we && (timer_wstrb == 4'b1111);

    wire wr_ctrl;
    wire wr_count;
    wire wr_compare;
    wire wr_status;

    assign wr_ctrl    = mimo_write && (timer_addr == CTRL);
    assign wr_count   = mimo_write && (timer_addr == COUNT);
    assign wr_compare = mimo_write && (timer_addr == COMPARE);
    assign wr_status  = mimo_write && (timer_addr == STATUS);

    //================================================
    // Timer event generation
    //================================================

    wire timer_match;

    assign timer_match = timer_en && (compare != 0) && (count == compare - 1);

    wire timer_clear;

    assign timer_clear = wr_status && timer_wdata[0];

    //================================================
    // next state logic
    //================================================
    reg [31:0] count_next;
    reg [31:0] compare_next;

    reg timer_en_next;
    reg irq_en_next;

    reg pending_next;

    always @(*) begin
        // 默认保持
        count_next    = count;
        compare_next  = compare;
        timer_en_next = timer_en;
        irq_en_next   = irq_en;
        pending_next  = pending;

        //=========================
        // 1. Timer计数
        //=========================
        if (timer_en) begin
            if (timer_match) begin
                count_next = 32'd0;
            end else begin
                count_next = count_next + 32'd1;
            end
        end

        //=========================
        // 2. MMIO写
        //=========================
        if (wr_ctrl) begin
            timer_en_next = timer_wdata[0];
            irq_en_next = timer_wdata[1];
        end

        if (wr_count) begin
            count_next = timer_wdata;
        end

        if (wr_compare) begin
            compare_next = timer_wdata;
        end

        if (timer_clear) begin
            pending_next = 1'b0;
        end else if (timer_match) begin
            pending_next = 1'b1;
        end   
    end

    //================================================
    // State registers
    //================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            count    <= 32'd0;
            pending  <= 1'd0;
            timer_en <= 1'd0;
            irq_en   <= 1'd0;
            compare  <= 32'd0;
        end else begin
            count    <= count_next;
            compare  <= compare_next;
            timer_en <= timer_en_next;
            irq_en   <= irq_en_next;
            pending  <= pending_next;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            timer_rdata <= 32'd0;
        end else if (timer_re) begin
            case (timer_addr)
                CTRL: begin
                    timer_rdata <= {30'd0, irq_en, timer_en};
                end 
                COUNT: begin
                    timer_rdata <= count;
                end
                COMPARE: begin
                    timer_rdata <= compare;
                end
                STATUS: begin
                    timer_rdata <= {31'd0, pending};
                end
                default: timer_rdata <= 32'd0;
            endcase
        end
    end
endmodule
