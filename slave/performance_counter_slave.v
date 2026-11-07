`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/07 14:55:54
// Design Name: 
// Module Name: performance_counter
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


module performance_counter_slave(
        input             clk,
        input             rst_n,

        input             instr_event,
        input             stall_event,

        // simple_bus slave
        input             perf_request,
        input             perf_re,
        input             perf_we,
        input [3:0]       perf_wstrb,
        input [7:0]       perf_addr,
        input [31:0]      perf_wdata,

        output            perf_ready,
        output reg [31:0] perf_rdata
    );

    localparam CTRL    = 8'h00;
    localparam CYCLE   = 8'h04;
    localparam INSTRET = 8'h08;
    localparam STALL = 8'h0C;

    // 定义中间变量
    reg perf_en;

    wire mmio_read;
    wire mmio_write;

    assign mmio_read  = perf_request && perf_re;
    assign mmio_write = perf_request && perf_we && (perf_wstrb == 4'b1111);

    

    // 定义状态
    assign perf_ready = perf_request;

    // 定义事件
    wire perf_clear;
    wire wr_ctrl;

    assign perf_clear   = mmio_write && perf_addr == CTRL && perf_wdata[1];
    assign wr_ctrl      = mmio_write && perf_addr == CTRL;

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            perf_en <= 1'd0;
        end else begin
            if (mmio_write) begin
                if (wr_ctrl) begin
                    perf_en    <= perf_wdata[0];
                end
            end
        end
    end

    always @(*) begin
        perf_rdata = 32'd0;
        if (mmio_read) begin
            case (perf_addr)
                CTRL: begin
                    perf_rdata = {31'd0, perf_en};
                end
                CYCLE: begin
                    perf_rdata = cycle_count;
                end
                INSTRET: begin
                    perf_rdata = instret_count;
                end
                STALL: begin
                    perf_rdata = stall_count;
                end
                default: perf_rdata = 32'd0;
            endcase
        end
    end


    // 定义业务变量
    reg [31:0] cycle_count;
    reg [31:0] instret_count;
    reg [31:0] stall_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count    <= 32'd0;
            instret_count  <= 32'd0;
            stall_count    <= 32'd0;
        end else begin
            

            if (perf_clear) begin
                cycle_count    <= 32'd0;
                instret_count  <= 32'd0;
                stall_count    <= 32'd0;
            end else if (perf_en) begin
                cycle_count    <= cycle_count + 32'd1;
                if (instr_event) begin
                    instret_count  <= instret_count + 32'd1;
                end
                if (stall_event) begin
                    stall_count    <= stall_count + 32'd1;
                end   
            end
        end
    end


endmodule
