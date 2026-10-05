`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/01 09:00:24
// Design Name: 
// Module Name: pc_src
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


module pc_src(
        input           branch_sel,
        input           jump_sel,
        input           jr_sel,
        input           eret,
        input           interrupt_accept,
        output  [2:0]   pc_src_sel
    );

    assign pc_src_sel = interrupt_accept ? 3'b000 : 
                        eret ? 3'b001 : 
                        jr_sel ? 3'b010 : 
                        jump_sel ? 3'b011 : 
                        branch_sel ? 3'b100 :
                        3'b111;  //pc_plus
endmodule
