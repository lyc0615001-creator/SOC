`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/22 09:50:31
// Design Name: 
// Module Name: Valid_pipeline
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


module Valid_pipeline(
        input clk,
        input rst,
        input cpu_en,
        input stall,
        input redirectD,
        input interrupt_acceptD,
        input bus_wait,
        output [3:0] valid_signs,
        output       hold_front,
        output       hold_pc,
        output       hold_fd,
        output       hold_de,
        output       hold_em,
        output       bubble_e,
        output       bubble_w
    ); 
    // 新增valid架构取代flush
    // 原因：flush过于依赖当前默认opcode，控制较为复杂
    // 解决措施：用valid区分有效和无效指令，在结果上进行控制

    // 产生条件：与stall和redirectD有关 + interrupt_acceptD
    // 生效条件：

    localparam V_D  = 3;
    localparam V_E  = 2;
    localparam V_M  = 1;
    localparam V_W  = 0;

    reg [3:0] valid_reg;

    assign valid_signs = valid_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_reg <= 4'b0;
        end else if (cpu_en) begin
            if (bus_wait) begin
                valid_reg <= {
                    valid_reg[V_D],
                    valid_reg[V_E],
                    valid_reg[V_M],
                    1'b0
                };
            end else if (interrupt_acceptD) begin
                valid_reg <= {
                    1'b0,
                    1'b0,
                    valid_reg[V_E],
                    valid_reg[V_M]
                };
            end else if (redirectD)  begin
                valid_reg <= {
                    1'b0,
                    valid_reg[V_D],
                    valid_reg[V_E],
                    valid_reg[V_M]
                };
            end else if (stall) begin
                valid_reg <= {
                    valid_reg[V_D],
                    1'b0,
                    valid_reg[V_E],
                    valid_reg[V_M]
                };
            end else begin
                valid_reg <= {
                    1'b1,
                    valid_reg[V_D],
                    valid_reg[V_E],
                    valid_reg[V_M]
                };
            end
        end
    end

    // stall data
    assign hold_front= stall || bus_wait;

    assign hold_pc   = hold_front;
    assign hold_fd   = hold_front;
    assign hold_de   = bus_wait;
    assign hold_em   = bus_wait;

    assign bubble_e  = stall && ~ bus_wait;
    assign bubble_w = bus_wait;
endmodule
