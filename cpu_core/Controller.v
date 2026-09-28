module Controller (
    input clk, rst, cpu_en,
    input stall,
    input [5:0] op_code,
    input [5:0] funct,
    output reg_write_enE, reg_write_enM, reg_write_enDM, mem_read_enM,
    output reg_write_enW, alu_src_muxE,  reg_dst_muxE, reg_data_muxDM, mem_write_enM,
    output reg_data_muxE, reg_data_muxM,
    output branchD, jumpD,
    output used_rsD, used_rtD,
    output imm_zero_extD, branch_neD,
    output [2:0] alu_controlE
);
    wire [11:0] sign;

    wire mem_read_enD, mem_read_enE;
    wire reg_write_enD;
    wire reg_dst_muxD;
    wire alu_src_muxD;
    wire mem_write_enD, mem_write_enE;
    wire reg_data_muxD;
    wire [2:0] alu_controlD;

    main_desc u_main_desc(
        .op_code(op_code),
        .funct(funct),
        .sign(sign),
        .alu_control(alu_controlD)
    );

    // 判断是否用到了rs 后续可做优化
    assign {reg_write_enD, alu_src_muxD,  reg_dst_muxD, reg_data_muxD, mem_write_enD, branchD, jumpD, used_rsD, used_rtD, mem_read_enD,
            imm_zero_extD, branch_neD} = sign;

    // mem_read_en
    flopenrc #(1) u_flopenrc_mem_read_enE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_read_enD), .dout(mem_read_enE));
    flopenrc #(1) u_flopenrc_mem_read_enM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_read_enE), .dout(mem_read_enM));

    // branch

    // reg_write_en
    flopenrc #(1) u_flopenrc_reg_write_enE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_write_enD), .dout(reg_write_enE));
    flopenrc #(1) u_flopenrc_reg_write_enM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_write_enE), .dout(reg_write_enM));
    flopenrc #(1) u_flopenrc_reg_write_enDM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_write_enM), .dout(reg_write_enDM));
    flopenrc #(1) u_flopenrc_reg_write_enW(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_write_enDM), .dout(reg_write_enW));

    // reg_dst_mux
    flopenrc #(1) u_flopenrc_reg_dst_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_dst_muxD), .dout(reg_dst_muxE));


    // alu_src_mux
    flopenrc #(1) u_flopenrc_alu_src_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(alu_src_muxD), .dout(alu_src_muxE));

    // mem_write_en
    flopenrc #(1) u_flopenrc_mem_write_enE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_write_enD), .dout(mem_write_enE));
    flopenrc #(1) u_flopenrc_mem_write_enM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_write_enE), .dout(mem_write_enM));

    // reg_data_mux
    flopenrc #(1) u_flopenrc_reg_data_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxD), .dout(reg_data_muxE));
    flopenrc #(1) u_flopenrc_reg_data_muxM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxE), .dout(reg_data_muxM));
    flopenrc #(1) u_flopenrc_reg_data_muxDM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxM), .dout(reg_data_muxDM));

    // alu_control
    flopenrc #(3) u_flopenrc_alu_controlE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(alu_controlD), .dout(alu_controlE));

endmodule

module main_desc (
    input [5:0] op_code,
    input [5:0] funct,
    output [11:0] sign,
    output [2:0] alu_control
);
    wire [2:0] aluop;
    wire [14:0] signs;

    assign signs = (op_code == 6'b000000) ? 15'b111_10_1000_0110_00 : // R-Type
                   (op_code == 6'b100011) ? 15'b000_11_0100_0101_00 : // lw
                   (op_code == 6'b101011) ? 15'b000_01_0010_0110_00 : // sw
                   (op_code == 6'b000100) ? 15'b001_00_0001_0110_00 : // beq
                   (op_code == 6'b000010) ? 15'b001_00_0000_1000_00 : // jump
                   (op_code == 6'b001000) ? 15'b000_11_0000_0100_00 : // addi
                   (op_code == 6'b000101) ? 15'b001_00_0001_0110_01 : // bne
                   (op_code == 6'b001101) ? 15'b011_11_0000_0100_10 : // ori
                   (op_code == 6'b001100) ? 15'b010_11_0000_0100_10 : // andi
                   (op_code == 6'b001110) ? 15'b100_11_0000_0100_10 : // xori
                   (op_code == 6'b001111) ? 15'b110_11_0000_0010_00 : // lui
                   15'b00000000000000;

    assign aluop = signs[14:12];
    assign sign = signs[11:0];

    assign alu_control = (aluop == 3'b000) ? 3'b000 : // lw/sw/addi -- add
                         (aluop == 3'b001) ? 3'b001 : // beq/jump -- sub
                         (aluop == 3'b010) ? 3'b010 : // andi -- and
                         (aluop == 3'b011) ? 3'b011 : // ori -- or
                         (aluop == 3'b100) ? 3'b100 : // xori -- xor
                         (aluop == 3'b110) ? 3'b110 : // xori -- xor
                         (aluop == 3'b111) ? ((funct == 6'b100000) ? 3'b000 : // R-add
                                             (funct == 6'b100010) ? 3'b001 : // R-sub
                                             (funct == 6'b100100) ? 3'b010 : // R-and
                                             (funct == 6'b100101) ? 3'b011 : // R-or
                                             (funct == 6'b101010) ? 3'b101 : // R-less-than
                                            3'b000
                         ) : 3'b000;

endmodule