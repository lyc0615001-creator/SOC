`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 11:43:22
// Design Name: 
// Module Name: scratchpad_a
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


module scratchpad_a(
        input  wire              clk,

        input  wire              wr_en,
        input  wire [3:0]        wr_addr,
        input  wire signed [7:0] wr_data,

        input  wire [1:0]        rd_addr0,
        input  wire [1:0]        rd_addr1,
        input  wire [1:0]        rd_addr2,
        input  wire [1:0]        rd_addr3,

        output wire signed [7:0] rd_data0,
        output wire signed [7:0] rd_data1,
        output wire signed [7:0] rd_data2,
        output wire signed [7:0] rd_data3
    );

    reg [7:0] bank0 [3:0];
    reg [7:0] bank1 [3:0];
    reg [7:0] bank2 [3:0];
    reg [7:0] bank3 [3:0];

    wire [1:0] bank;
    wire [1:0] index;

    assign bank = wr_addr[3:2];
    assign index = wr_addr[1:0];

    always @(posedge clk) begin
        if (wr_en) begin
            case (bank)
                2'b00: bank0[index] = wr_data; 
                2'b01: bank1[index] = wr_data; 
                2'b10: bank2[index] = wr_data; 
                2'b11: bank3[index] = wr_data; 
                default: ;
            endcase
        end
    end

    assign rd_data0 = bank0[rd_addr0];
    assign rd_data1 = bank1[rd_addr1];
    assign rd_data2 = bank2[rd_addr2];
    assign rd_data3 = bank3[rd_addr3];
endmodule
