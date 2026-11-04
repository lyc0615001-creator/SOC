`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 09:26:51
// Design Name: 
// Module Name: pe
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


module pe(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    clear,

    input  wire                    act_valid_in,
    input  wire                    weight_valid_in,

    input  wire signed [7:0]       act_in,
    input  wire signed [7:0]       weight_in,

    output reg                     act_valid_out,
    output reg                     weight_valid_out,

    output reg  signed [7:0]       act_out,
    output reg  signed [7:0]       weight_out,

    output reg  signed [31:0]      psum_out
);

    wire signed [15:0] product;

    assign product = act_in * weight_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psum_out <= 32'd0;
            act_valid_out <= 1'd0;
            weight_valid_out <= 1'd0;
            act_out <= 8'd0;
            weight_out <= 8'd0;
        end else begin
            if (clear) begin
                psum_out <= 32'd0;
                act_out <= 8'd0;
                weight_out <= 8'd0;
                act_valid_out <= 1'd0;
                weight_valid_out <= 1'd0;
            end else begin
                act_valid_out <= act_valid_in;
                if (act_valid_in) begin
                    act_out <= act_in;
                end

                weight_valid_out <= weight_valid_in;
                if (weight_valid_in) begin
                    weight_out <= weight_in;
                end

                if (act_valid_in && weight_valid_in) begin
                    psum_out <= psum_out + product;
                end
            end
        end
    end
endmodule
