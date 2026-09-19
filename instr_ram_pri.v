`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/18 10:21:53
// Design Name: 
// Module Name: instr_ram_pri
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


module instr_ram_pri(
        input [7:0] pc,
        output reg [31:0] instr
    );

    always @(*) begin
        case (pc)
            8'd0 : instr = 32'h20020005;
            8'd1 : instr = 32'h2003000c;
            8'd2 : instr = 32'h2067fff7;
            8'd3 : instr = 32'h00e22025;
            8'd4 : instr = 32'h00642824;
            8'd5 : instr = 32'h00a42820;
            8'd6 : instr = 32'h10a7000a;
            8'd7 : instr = 32'h0064202a;
            8'd8 : instr = 32'h10800001;
            8'd9 : instr = 32'h20050000;
            8'd10: instr = 32'h00e2202a;
            8'd11: instr = 32'h00853820;
            8'd12: instr = 32'h00e23822;
            8'd13: instr = 32'hac670044;
            8'd14: instr = 32'h8c020050;
            8'd15: instr = 32'h08000011;
            8'd16: instr = 32'h20020001;
            8'd17: instr = 32'hac020054;
            8'd18: instr = 32'h08000012;

            default: instr = 32'h00000000;
        endcase
    end
endmodule
