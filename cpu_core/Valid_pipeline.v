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
        input eretD,
        output [5:0] valid_signs
    ); 
    // 新增valid架构取代flush
    // 原因：flush过于依赖当前默认opcode，控制较为复杂
    // 解决措施：用valid区分有效和无效指令，在结果上进行控制

    // 产生条件：与stall和redirectD有关 + interrupt_acceptD
    // 生效条件：

    localparam V_IM = 5;
    localparam V_D  = 4;
    localparam V_E  = 3;
    localparam V_M  = 2;
    localparam V_DM = 1;
    localparam V_W  = 0;

    reg [5:0] valid_reg;

    assign valid_signs = valid_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_reg <= 6'b0;
        end else if (cpu_en) begin
            if (interrupt_acceptD) begin
                valid_reg <= {
                    1'b0,
                    1'b0,
                    1'b0,
                    valid_reg[V_E],
                    valid_reg[V_M],
                    valid_reg[V_DM]
                };
            end else if (redirectD || eretD)  begin
                valid_reg <= {
                    1'b0,
                    1'b0,
                    valid_reg[V_D],
                    valid_reg[V_E],
                    valid_reg[V_M],
                    valid_reg[V_DM]
                };
            end else if (stall) begin
                valid_reg <= {
                    valid_reg[V_IM],
                    valid_reg[V_D],
                    1'b0,
                    valid_reg[V_E],
                    valid_reg[V_M],
                    valid_reg[V_DM]
                };
            end else begin
                valid_reg <= {
                    1'b1,
                    valid_reg[V_IM],
                    valid_reg[V_D],
                    valid_reg[V_E],
                    valid_reg[V_M],
                    valid_reg[V_DM]
                };
            end
        end
    end

endmodule
