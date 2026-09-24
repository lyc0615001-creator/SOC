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
    output [2:0] alu_controlE
);
    wire [9:0] sign;

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
    assign {reg_write_enD, alu_src_muxD,  reg_dst_muxD, reg_data_muxD, mem_write_enD, branchD, jumpD, used_rsD, used_rtD, mem_read_enD} = sign;

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
    output [9:0] sign,
    output [2:0] alu_control
);
    wire [1:0] aluop;
    wire [11:0] signs;

    assign signs = (op_code == 6'b000000) ? 12'b101010000110 : // R-Type
                   (op_code == 6'b100011) ? 12'b001101000101 : // lw
                   (op_code == 6'b101011) ? 12'b000100100110 : // sw
                   (op_code == 6'b000100) ? 12'b010100010110 : // beq
                   (op_code == 6'b000010) ? 12'b000000001000 : // jump
                   (op_code == 6'b001000) ? 12'b001100000100 : // addi
                   12'b00000000000;

    assign aluop = signs[11:10];
    assign sign = signs[9:0];

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