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
    output [3:0] alu_controlE,
    output jrD
);
    wire [11:0] sign;
    wire [2:0] aluop;

    wire mem_read_enD, mem_read_enE;
    wire reg_write_en_tempD, reg_write_enD;
    wire [1:0] reg_dst_muxD;
    wire alu_src_muxD;
    wire mem_write_enD, mem_write_enE;
    wire [1:0] reg_data_muxD;
    wire [3:0] alu_controlD;

    // 主控制信号译码
    main_decode u_main_decode(
        .op_code(op_code),
        .funct(funct),
        .sign(sign),
        .aluop(aluop)
    );

    assign {
        reg_write_en_tempD, 
        alu_src_muxD,  
        reg_dst_muxD, 
        reg_data_muxD, 
        mem_write_enD, 
        branchD, jumpD, 
        mem_read_enD,
        imm_zero_extD, 
        branch_neD} = sign;

    // alu控制信号译码
    alu_decode u_alu_decode(
        .aluop(aluop),
        .funct(funct),
        .alu_control(alu_controlD)
    );

    // used_rs used_rt冒险辅助信号译码
    assist_decode u_assist_decode(
        .op_code(op_code),
        .funct(funct),
        .used_rs(used_rsD),
        .used_rt(used_rtD)
    );

    // 针对jr指令的特殊处理
    assign jrD = ((op_code == 6'b000000) && (funct == 6'b001000)) ? 1'b1 : 1'b0;
    assign reg_write_enD = jrD ? 1'b0 : reg_write_en_tempD;
  

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
    flopenrc #(4) u_flopenrc_alu_controlE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(alu_controlD), .dout(alu_controlE));

endmodule

module main_decode (
    input [5:0] op_code,
    input [5:0] funct,
    output [11:0] sign,
    output [2:0] aluop
);
    wire [2:0] aluop;
    wire [14:0] signs;

    assign signs = (op_code == 6'b000000) ? 15'b10_0100_000_000_111 : // R-Type
                   (op_code == 6'b100011) ? 15'b11_0001_000_100_000 : // lw
                   (op_code == 6'b101011) ? 15'b01_0000_100_000_000 : // sw
                   (op_code == 6'b000100) ? 15'b00_0000_010_000_001 : // beq
                   (op_code == 6'b000010) ? 15'b00_0000_001_000_001 : // jump
                   (op_code == 6'b001000) ? 15'b11_0000_000_000_000 : // addi
                   (op_code == 6'b000101) ? 15'b00_0000_010_001_001 : // bne
                   (op_code == 6'b001101) ? 15'b11_0000_000_010_011 : // ori
                   (op_code == 6'b001100) ? 15'b11_0000_000_010_010 : // andi
                   (op_code == 6'b001110) ? 15'b11_0000_000_010_100 : // xori
                   (op_code == 6'b001111) ? 15'b11_0000_000_000_110 : // lui
                   (op_code == 6'b000011) ? 15'b10_1010_001_000_001 : // jal
                   15'd0;

    assign aluop = signs[2:0];
    assign sign = signs[14:3];

endmodule

module alu_decode (
    input [2:0] aluop,
    input [5:0] funct,
    output [3:0] alu_control
);
    assign alu_control = (aluop == 3'b000) ? 4'b0000 : // lw/sw/addi -- add
                         (aluop == 3'b001) ? 4'b0001 : // beq/jump -- sub
                         (aluop == 3'b010) ? 4'b0010 : // andi -- and
                         (aluop == 3'b011) ? 4'b0011 : // ori -- or
                         (aluop == 3'b100) ? 4'b0100 : // xori -- xor
                         (aluop == 3'b110) ? 4'b0110 : // lui -- lui
                         (aluop == 3'b111) ? ((funct == 6'b100000) ? 4'b0000 : // R-add
                                             (funct == 6'b100010) ? 4'b0001 : // R-sub
                                             (funct == 6'b100100) ? 4'b0010 : // R-and
                                             (funct == 6'b100101) ? 4'b0011 : // R-or
                                             (funct == 6'b101010) ? 4'b0101 : // R-less-than
                                             (funct == 6'b100001) ? 4'b0000 : // R-add
                                             (funct == 6'b100011) ? 4'b0001 : // R-sub
                                             (funct == 6'b000000) ? 4'b0111 : // R-sll
                                             (funct == 6'b000010) ? 4'b1000 : // R-srl
                                            4'b0000
                         ) : 4'b0000;
    
endmodule

module assist_decode (
    input [5:0] op_code,
    input [5:0] funct,
    output reg  used_rs,
    output reg  used_rt
);
    always @(*) begin
        used_rs = 1'b0; // default
        used_rt = 1'b0;
        case (op_code)
            6'b000000: begin //R-Type
                case (funct)
                    6'b000000, // sll
                    6'b000010: begin // srl
                        used_rs = 1'b0;
                        used_rt = 1'b1;
                    end
                    6'b001000: begin // jr
                        used_rs = 1'b1;
                        used_rt = 1'b0;
                    end
                    
                    default: begin
                        used_rs = 1'b1;
                        used_rt = 1'b1;
                    end
                endcase
            end
            6'b100011, // lw
            6'b001000, // addi
            6'b001101, // ori
            6'b001100, // andi
            6'b001110: begin // xori
                used_rs = 1'b1;
                used_rt = 1'b0;
            end
            6'b000010, // jump
            6'b001111, // lui
            6'b000011: begin // jal
                used_rs = 1'b0;
                used_rt = 1'b0;
            end
            6'b101011, // sw
            6'b000100, // beq
            6'b000101: begin // bne
                used_rs = 1'b1;
                used_rt = 1'b1;
            end
            default: begin
                used_rs = 1'b0;
                used_rt = 1'b0; 
            end
        endcase
    end
    
endmodule