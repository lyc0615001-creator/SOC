module Controller (
    input clk,
    input [5:0] op_code,
    input [5:0] funct,
    output reg_write_en, alu_src_mux,  reg_dst_mux, reg_data_mux, dm_write_en,
    output branch, jump,
    output [2:0] alu_control
);
    wire [6:0] sign;

    main_desc u_main_desc(
        .op_code(op_code),
        .funct(funct),
        .sign(sign),
        .alu_control(alu_control)
    );

    assign {reg_write_en, alu_src_mux,  reg_dst_mux, reg_data_mux, dm_write_en, branch, jump} = sign;
    
endmodule

module main_desc (
    input [5:0] op_code,
    input [5:0] funct,
    output [6:0] sign,
    output [2:0] alu_control
);
    wire [1:0] aluop;
    wire [8:0] signs;

    assign signs = (op_code == 6'b000000) ? 9'b101000010 : // R-Type
                   (op_code == 6'b100011) ? 9'b110100000 : // lw
                   (op_code == 6'b101011) ? 9'b010010000 : // sw
                   (op_code == 6'b000100) ? 9'b010001001 : // beq
                   (op_code == 6'b000010) ? 9'b000000100 : // jump
                   (op_code == 6'b001000) ? 9'b110000000 : // addi
                   9'b000000000;

    assign aluop = signs[1:0];
    assign sign = signs[8:2];

    assign alu_control = (aluop == 2'b00) ? 3'b010 : // lw/sw -- add
                         (aluop == 2'b01) ? 3'b110 : // beq/jump -- sub
                         (aluop == 2'b10) ? ((funct == 6'b100000) ? 3'b010 : // R-add
                                             (funct == 6'b100010) ? 3'b110 : // R-sub
                                             (funct == 6'b100100) ? 3'b000 : // R-and
                                             (funct == 6'b100101) ? 3'b001 : // R-or
                                             (funct == 6'b101010) ? 3'b111 : // R-less-than
                                            3'b010
                         ) : 3'b010;

endmodule