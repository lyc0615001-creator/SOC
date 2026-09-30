module Controller (
    input clk, rst, cpu_en,
    input stall,
    input [5:0] op_code,
    input [5:0] funct,
    output reg_write_enE, reg_write_enM, reg_write_enDM, mem_read_enM,
    output reg_write_enW, alu_src_muxE, mem_write_enM,
    output [1:0] reg_dst_muxE, 
    output [1:0] reg_data_muxE, reg_data_muxM, reg_data_muxDM,
    output branchD, jumpD,
    output used_rsD, used_rtD,
    output imm_zero_extD, branch_neD,
    output [2:0] alu_controlE,
    output jrD
);
    wire [13:0] sign;

    wire mem_read_enD, mem_read_enE;
    wire reg_write_en_tempD, reg_write_enD;
    wire [1:0] reg_dst_muxD;
    wire alu_src_muxD;
    wire mem_write_enD, mem_write_enE;
    wire [1:0] reg_data_muxD;
    wire [2:0] alu_controlD;

    main_desc u_main_desc(
        .op_code(op_code),
        .funct(funct),
        .sign(sign),
        .alu_control(alu_controlD)
    );

    // 针对jr指令的特殊处理
    assign jrD = ((op_code == 6'b000000) && (funct == 6'b001000)) ? 1'b1 : 1'b0;
    assign reg_write_enD = jrD ? 1'b0 : reg_write_en_tempD;
  
    // 判断是否用到了rs 后续可做优化
    assign {reg_write_en_tempD, alu_src_muxD,  reg_dst_muxD, reg_data_muxD, mem_write_enD, branchD, jumpD, used_rsD, used_rtD, mem_read_enD,
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
    flopenrc #(2) u_flopenrc_reg_dst_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_dst_muxD), .dout(reg_dst_muxE));


    // alu_src_mux
    flopenrc #(1) u_flopenrc_alu_src_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(alu_src_muxD), .dout(alu_src_muxE));

    // mem_write_en
    flopenrc #(1) u_flopenrc_mem_write_enE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_write_enD), .dout(mem_write_enE));
    flopenrc #(1) u_flopenrc_mem_write_enM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(mem_write_enE), .dout(mem_write_enM));

    // reg_data_mux
    flopenrc #(2) u_flopenrc_reg_data_muxE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxD), .dout(reg_data_muxE));
    flopenrc #(2) u_flopenrc_reg_data_muxM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxE), .dout(reg_data_muxM));
    flopenrc #(2) u_flopenrc_reg_data_muxDM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(reg_data_muxM), .dout(reg_data_muxDM));

    // alu_control
    flopenrc #(3) u_flopenrc_alu_controlE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(alu_controlD), .dout(alu_controlE));

endmodule

module main_desc (
    input [5:0] op_code,
    input [5:0] funct,
    output [13:0] sign,
    output [2:0] alu_control
);
    wire [2:0] aluop;
    wire [16:0] signs;

    assign signs = (op_code == 6'b000000) ? 17'b10_0100_000_11000_111 : // R-Type
                   (op_code == 6'b100011) ? 17'b11_0001_000_10100_000 : // lw
                   (op_code == 6'b101011) ? 17'b01_0000_100_11000_000 : // sw
                   (op_code == 6'b000100) ? 17'b00_0000_010_11000_001 : // beq
                   (op_code == 6'b000010) ? 17'b00_0000_001_00000_001 : // jump
                   (op_code == 6'b001000) ? 17'b11_0000_000_10000_000 : // addi
                   (op_code == 6'b000101) ? 17'b00_0000_010_11001_001 : // bne
                   (op_code == 6'b001101) ? 17'b11_0000_000_10010_011 : // ori
                   (op_code == 6'b001100) ? 17'b11_0000_000_10010_010 : // andi
                   (op_code == 6'b001110) ? 17'b11_0000_000_10010_100 : // xori
                   (op_code == 6'b001111) ? 17'b11_0000_000_01000_110 : // lui
                   (op_code == 6'b000011) ? 17'b10_1010_001_00000_001 : // jal
                   17'd0;

    assign aluop = signs[2:0];
    assign sign = signs[16:3];

    // always @(*) begin
    //     sign = signs[16:3];
    //     jr = 1'b0;
    //     if (aluop == 3'b111) begin
    //         case (funct)
    //             6'b100000: alu_control = 3'b000; // R-add
    //             6'b100010: alu_control = 3'b001; // R-sub
    //             6'b100100: alu_control = 3'b010; // R-and
    //             6'b100101: alu_control = 3'b011; // R-or
    //             6'b101010: alu_control = 3'b101; // R-less-than
    //             6'b001000: begin // R-jr
    //                 jr = 1'b1;
    //                 sign[16] = 1'b0; // reg_write = false
    //             end 
    //             default: alu_control = 3'b000;
    //         endcase
    //     end else begin
    //         alu_control = aluop;
    //     end
    // end

    assign alu_control = (aluop == 3'b000) ? 3'b000 : // lw/sw/addi -- add
                         (aluop == 3'b001) ? 3'b001 : // beq/jump -- sub
                         (aluop == 3'b010) ? 3'b010 : // andi -- and
                         (aluop == 3'b011) ? 3'b011 : // ori -- or
                         (aluop == 3'b100) ? 3'b100 : // xori -- xor
                         (aluop == 3'b110) ? 3'b110 : // lui -- lui
                         (aluop == 3'b111) ? ((funct == 6'b100000) ? 3'b000 : // R-add
                                             (funct == 6'b100010) ? 3'b001 : // R-sub
                                             (funct == 6'b100100) ? 3'b010 : // R-and
                                             (funct == 6'b100101) ? 3'b011 : // R-or
                                             (funct == 6'b101010) ? 3'b101 : // R-less-than
                                            3'b000
                         ) : 3'b000;

endmodule