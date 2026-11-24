`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 16:02:56
// Design Name: 
// Module Name: ROUND_ROBIN_ARBITER
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


module ROUND_ROBIN_ARBITER(
        input                 clk,
        input                 rst_n,
        input                 grant_en,
        input           [3:0] req,
        output          [3:0] grant
    );

    wire [1:0] grant_index;

    reg [1:0] last_grant;

    assign grant_index  = req[last_grant + 2'd1] ? last_grant + 2'd1 :
                          req[last_grant + 2'd2] ? last_grant + 2'd2 :
                          req[last_grant + 2'd3] ? last_grant + 2'd3 :
                          last_grant;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_grant <= 2'd3;
        end else begin
            if (grant_en) begin
                last_grant <= grant_index;
            end
            
        end
    end

    assign grant = (grant_index == 2'd0) ? 4'b0001 :
                    (grant_index == 2'd1) ? 4'b0010 :
                    (grant_index == 2'd2) ? 4'b0100 :
                    4'b1000;
endmodule
