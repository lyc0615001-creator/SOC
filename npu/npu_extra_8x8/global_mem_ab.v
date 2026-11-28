`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 11:05:54
// Design Name: 
// Module Name: global_mem_a
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


module global_mem_ab(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              wr_en,
    input  wire [3:0]        wr_group_addr,
    input  wire [31:0]       wr_data,
    input  wire [3:0]        wr_be,

    input  wire [5:0]        rd_addr,
    output wire signed [7:0] rd_data
);

    reg signed [7:0] bank0 [0:15];
    reg signed [7:0] bank1 [0:15];
    reg signed [7:0] bank2 [0:15];
    reg signed [7:0] bank3 [0:15];

    always @(posedge clk) begin
        if (wr_en) begin
            if (wr_be[0]) begin
                bank0[wr_group_addr] <= wr_data[7:0];
            end
            if (wr_be[1]) begin
                bank1[wr_group_addr] <= wr_data[15:8];
            end
            if (wr_be[2]) begin
                bank2[wr_group_addr] <= wr_data[23:16];
            end
            if (wr_be[3]) begin
                bank3[wr_group_addr] <= wr_data[31:24];
            end
            
        end
    end

    wire same_rw = (wr_en && rd_addr[5:2] == wr_group_addr && wr_be[rd_addr[1:0]]);

    reg signed [7:0] wr_lane_data;

    reg signed [7:0] normal_rd_data;


    always @(*) begin
        wr_lane_data   = 8'd0;
        normal_rd_data = 8'd0;
        case (rd_addr[1:0])
            2'b00: begin
                wr_lane_data   = wr_data[7:0];
                normal_rd_data = bank0[rd_addr[5:2]];
            end
            2'b01: begin
                wr_lane_data   =wr_data[15:8];
                normal_rd_data = bank1[rd_addr[5:2]];
            end
            2'b10: begin
                wr_lane_data   = wr_data[23:16];
                normal_rd_data = bank2[rd_addr[5:2]];
            end
            2'b11: begin
                wr_lane_data   = wr_data[31:24];
                normal_rd_data = bank3[rd_addr[5:2]];
            end
            default: ;
        endcase
    end

    assign rd_data = same_rw ? wr_lane_data : normal_rd_data;

endmodule
