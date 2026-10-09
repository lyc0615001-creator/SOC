`timescale 1ns / 1ps
module Datapath (
    input clk, rst,
    input cpu_en, irq,
    input [31:0] instrIM,
    input [31:0] DM_data_oM,
    input reg_write_enE, reg_write_enM, reg_write_enDM,
    input reg_write_enW, alu_src_muxE,
    input [1:0] reg_dst_muxE,
    input [1:0] reg_data_muxE, reg_data_muxM, reg_data_muxDM,
    input branchD, jumpD,
    input used_rsD, used_rtD,
    input imm_zero_extD, branch_neD,
    input [3:0] alu_controlE,
    input jrD, cp0_write_enE, eretD,
    input bus_wait,
    output [31:0] pc_oF, early_resultM, DM_data_iM, instrD,
    output hold_de, hold_em, hold_fim, validM,
    output bubble_e, bubble_dm
);

    // F阶段变量
    wire [31:0] pc_plus4F;

     // IM阶段变量
    wire [31:0] pc_plus4IM;
    
    // D阶段变量
    wire zeroD, branch_selD, jump_selD, jr_selD;
    wire [4:0] rsD, rtD, rdD, shamtD;
    wire [15:0] lw_offsetD;
    wire [31:0] pc_plus4D, pc_branchD, pc_jumpD, pc_iD, pc_jrD;
    wire [31:0] imm_extD, imm_ext_sl2D, jump_sl2D;
    wire [31:0] RF_data_o1D, RF_data_o2D;

    // E阶段变量
    wire [4:0] RF_address3E, rsE, rtE, rdE, shamtE;
    wire [31:0] imm_extE, pc_plus4E;
    wire [31:0] DM_data_iE, alu_src_i2E, alu_resultE;
    wire [31:0] RF_data_o1_mux4E, RF_data_o2_mux4E;
    wire [31:0] cp0_rdataE, early_resultE;
    wire cp0_weE;

    // M阶段变量
    wire [4:0] RF_address3M;
    wire [31:0] early_resultM;

    // DM阶段变量
    wire [4:0] RF_address3DM;
    wire [31:0] RF_data_iDM, early_resultDM, DM_data_oDM;
    wire RF_data_srcDM;

    // W阶段变量
    wire [4:0] RF_address3W;
    wire [31:0] RF_data_iW;

    // HAZARD 变量
    wire [1:0] forwardAD, forwardBD;
    wire [31:0] RF_data_o1_mux4D, RF_data_o2_mux4D;
    wire redirectD, stall;
    wire [31:0] ForwardValueE, ForwardValueM, ForwardValueDM;

    // Valid_pipeline 变量
    wire validIM, validD, validE, validM, validDM, validW;
    wire [5:0] valid_signs;
    wire rf_write_enW;

    // 前递E变量
    wire [31:0] alu_src_i1E, alu_src_i0E;
    wire forwardAE, forwardBE;

    // 中断处理变量
    wire status_ie, status_exl;
    wire interrupt_acceptD, eret_selD;
    wire [2:0] pc_src_selD;
    wire [31:0] pc_eretD;
    wire [31:0] cp0_status;

    // 流水线暂停变量
    wire  hold_pc, hold_imd;

    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    assign shamtD = instrD[10:6];
    assign lw_offsetD = instrD[15:0];

    assign DM_data_iE = alu_src_i0E;


    // =======中断处理 && pc_src=======
    assign status_ie = cp0_status[0];
    assign status_exl = cp0_status[1];
    assign interrupt_acceptD = irq && status_ie && !status_exl && validD && !(validE && cp0_write_enE) && !bus_wait;
    assign eret_selD = validD && eretD;

    // pc_src_selD
    pc_src u_pc_src(
        .branch_sel(branch_selD),
        .jump_sel(jump_selD),
        .jr_sel(jr_selD),
        .eret(eret_selD),
        .interrupt_accept(interrupt_acceptD),
        .pc_src_sel(pc_src_selD)
    );

    // pc_iD
    mux6 #(.WIDTH(32)) u_mux6_pc_iD (
        .data_i1(32'h0180),  // exception_target
        .data_i2(pc_eretD), 
        .data_i3(pc_jrD), 
        .data_i4(pc_jumpD), 
        .data_i5(pc_branchD), 
        .data_i6(pc_plus4F), 
        .sel(pc_src_selD), 
        .data_o(pc_iD)
    );



    // =========指令执行模块===========

    // pc 一级延迟
    pc u_pc(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_pc), .pc_i(pc_iD), .pc_o(pc_oF));
    
    adder u_adder_plus4(
        .add_i1(pc_oF), 
        .add_i2(32'd4), 
        .add_o(pc_plus4F)
        );
    
    // F -> IM 指令存储器延迟同步
    // 同步变量 pc_plus4F
    flopenrc #(32) u_flopenrc_pc_plus4IM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_fim), .clear(1'b0), .din(pc_plus4F), .dout(pc_plus4IM));

    // IM -> D 流水线触发器
    // 延迟变量 instrIM pc_plus4IM
    flopenrc #(32) u_flopenrc_instrD(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_imd), .clear(1'b0), .din(instrIM), .dout(instrD));
    flopenrc #(32) u_flopenrc_pc_plus4D(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_imd), .clear(1'b0), .din(pc_plus4IM), .dout(pc_plus4D));

    assign rf_write_enW = validW && reg_write_enW;
    Regfile u_Regfile(
        .clk(clk), 
        .rst(rst),
        .w_en(rf_write_enW),
        .cpu_en(cpu_en),
        .RF_address1(rsD),
        .RF_address2(rtD), 
        .RF_address3(RF_address3W),
        .RF_data_i(RF_data_iW),
        .RF_data_o1(RF_data_o1D), 
        .RF_data_o2(RF_data_o2D)
        );


    // D -> E 流水线触发器
    // 延迟变量 RF_data_o1_mux4D RF_data_o2_mux4D imm_extD rsD rtD rdD pc_plus4D shamtD
    flopenrc #(32) u_flopenrc_RF_data_o1_mux4E(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(RF_data_o1_mux4D), .dout(RF_data_o1_mux4E));
    flopenrc #(32) u_flopenrc_RF_data_o2_mux4E(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(RF_data_o2_mux4D), .dout(RF_data_o2_mux4E));
    flopenrc #(32) u_flopenrc_sign_extE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(imm_extD), .dout(imm_extE));

    flopenrc #(5) u_flopenrc_rsE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(rsD), .dout(rsE));
    flopenrc #(5) u_flopenrc_rtE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(rtD), .dout(rtE));
    flopenrc #(5) u_flopenrc_rdE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(rdD), .dout(rdE));
    flopenrc #(5) u_flopenrc_shamtE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(shamtD), .dout(shamtE));

    flopenrc #(32) u_flopenrc_pc_plus4E(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_de), .clear(bubble_e), .din(pc_plus4D), .dout(pc_plus4E));

    // E -> M 流水线触发器  
    // 延迟变量  DM_data_iE RF_address3E early_resultE
    flopenrc #(32) u_flopenrc_early_resultM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_em), .clear(1'b0), .din(early_resultE), .dout(early_resultM));
    flopenrc #(32) u_flopenrc_DM_data_iM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_em), .clear(1'b0), .din(DM_data_iE), .dout(DM_data_iM));
    flopenrc #(5) u_flopenrc_RF_address3M(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_em), .clear(1'b0), .din(RF_address3E), .dout(RF_address3M));

    // M -> DM 数据存储器延迟同步
    // 延迟变量  RF_address3M  early_resultM DM_data_oM
    flopenrc #(32) u_flopenrc_early_resultDM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(bubble_dm), .din(early_resultM), .dout(early_resultDM));
    flopenrc #(5) u_flopenrc_RF_address3DM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(bubble_dm), .din(RF_address3M), .dout(RF_address3DM));

    flopenrc #(32) u_flopenrc_DM_data_oDM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(bubble_dm), .din(DM_data_oM), .dout(DM_data_oDM));

    // DM -> W 流水线触发器
    // 延迟变量 RF_address3DM RF_data_iDM
    flopenrc #(5) u_flopenrc_RF_address3W(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(RF_address3DM), .dout(RF_address3W));
    flopenrc #(32) u_flopenrc_RF_data_iW(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(RF_data_iDM), .dout(RF_data_iW));

    //  pc F->M
    // wire [31:0] pc_oD, pc_oE, pc_oIM;
    wire [31:0] pc_oIM, pc_oD;
    flopenrc #(32) u_flopenrc_pc_oIM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_fim), .clear(1'b0), .din(pc_oF), .dout(pc_oIM));
    flopenrc #(32) u_flopenrc_pc_oD(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(~hold_imd), .clear(1'b0), .din(pc_oIM), .dout(pc_oD));
    // flopenrc #(32) u_flopenrc_pc_oE(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(pc_oD), .dout(pc_oE));
    // flopenrc #(32) u_flopenrc_pc_oM(.clk(clk), .rst(rst), .cpu_en(cpu_en), .en(1'b1), .clear(1'b0), .din(pc_oE), .dout(pc_oM));


    // ====R====
    alu u_alu(
        .alu_control(alu_controlE),
        .alu_data_i1(alu_src_i1E),
        .alu_data_i2(alu_src_i2E),
        .shamt(shamtE),
        .alu_data_o(alu_resultE)
    );
    
    // early_result
    mux4 #(32) u_mux4_early_result(
        .data_i1(alu_resultE),
        .data_i2(alu_resultE),
        .data_i3(pc_plus4E),
        .data_i4(cp0_rdataE),
        .sel(reg_data_muxE),
        .data_o(early_resultE)
    );

    // lw sw
    ImmExt u_ImmExt(.ext_i(lw_offsetD), .imm_zero_sel(imm_zero_extD), .ext_o(imm_extD));

    // alu_src_muxE
    mux2 #(32) u_mux2_alu_data_i2 (
        .data_i1(imm_extE), 
        .data_i2(alu_src_i0E), 
        .sel(alu_src_muxE), 
        .data_o(alu_src_i2E)
    );

    // [1:0] RF_data_iDM
    assign RF_data_srcDM = (reg_data_muxDM == 2'b01);
    mux2 #(32) u_mux2_RF_data_i (
        .data_i1(DM_data_oDM), 
        .data_i2(early_resultDM), 
        .sel(RF_data_srcDM), 
        .data_o(RF_data_iDM)
    );

    // [1:0] reg_dst_muxE
    mux4 #(5) u_mux4_RF_address3 (
        .data_i1(rtE), 
        .data_i2(rdE), 
        .data_i3(5'd31), 
        .data_i4(5'd0), 
        .sel(reg_dst_muxE), 
        .data_o(RF_address3E)
    );

    // ====beq & bne====
    assign zeroD = (RF_data_o1_mux4D == RF_data_o2_mux4D);
    assign branch_selD = validD && !hold_pc && branchD && (zeroD ^ branch_neD);


    sl2 u_sl2_branch(
        .sl2_i(imm_extD),
        .sl2_o(imm_ext_sl2D)
    );

    adder u_adder_branch(
        .add_i1(imm_ext_sl2D), 
        .add_i2(pc_plus4D), 
        .add_o(pc_branchD)
    );

    // ====jump====

    sl2 u_sl2_jump(
        .sl2_i(instrD), // 25:0(32)
        .sl2_o(jump_sl2D) // 27:0
    );

    assign pc_jumpD = {pc_plus4D[31:28], jump_sl2D[27:0]};
    assign jump_selD = validD && !hold_pc && jumpD;

    // ====jr====
    assign pc_jrD = RF_data_o1_mux4D;
    assign jr_selD = validD && !hold_pc && jrD;  // 实为stall && bus_wait

    // ====mfc0 mtc0====
    assign cp0_weE = cp0_write_enE && validE;

    cp0 u_cp0(
        .clk(clk),
        .rst(rst),
        .cpu_en(cpu_en),
        .interrupt_accept(interrupt_acceptD),
        .eret(eretD),
        .epc_i(pc_oD),
        .epc_o(pc_eretD),
        .cp0_status(cp0_status),
        .cp0_we(cp0_weE),
        .cp0_addr(rdE),
        .cp0_wdata(alu_src_i0E),
        .cp0_rdata(cp0_rdataE)
    );

    // HAZARD
    Hazard u_Hazard(
        .rsD(rsD), 
        .rtD(rtD),
        .rsE(rsE),
        .rtE(rtE),
        .used_rsD(used_rsD),
        .used_rtD(used_rtD),
        .RF_address3E(RF_address3E), 
        .RF_address3M(RF_address3M), 
        .RF_address3DM(RF_address3DM), 
        .reg_write_enE(reg_write_enE), 
        .reg_write_enM(reg_write_enM), 
        .reg_write_enDM(reg_write_enDM), 
        .reg_data_muxE(reg_data_muxE),
        .reg_data_muxM(reg_data_muxM),
        .reg_data_muxDM(reg_data_muxDM),
        .branch_selD(branch_selD),
        .jump_selD(jump_selD),
        .jr_selD(jr_selD),
        .validD(validD),
        .validE(validE),
        .validM(validM),
        .validDM(validDM),
        .branchD(branchD),
        .jrD(jrD),
        .eretD(eretD),
        // out
        .forwardAD(forwardAD), 
        .forwardBD(forwardBD),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE),
        .stall(stall), 
        .redirectD(redirectD)
    );

    // 针对R和jal的数据冒险，是否前递由forwardAD/BD判断，前递数据有assign语句判断

    assign ForwardValueE = early_resultE;
    assign ForwardValueM = early_resultM;
    assign ForwardValueDM = RF_data_iDM;

    mux4 #(32) u_mux4_RF_data1(
        .data_i1(RF_data_o1D),
        .data_i2(ForwardValueE),
        .data_i3(ForwardValueM),
        .data_i4(ForwardValueDM),
        .sel(forwardAD),
        .data_o(RF_data_o1_mux4D)
    );

    mux4 #(32) u_mux4_RF_data2(
        .data_i1(RF_data_o2D),
        .data_i2(ForwardValueE),
        .data_i3(ForwardValueM),
        .data_i4(ForwardValueDM),
        .sel(forwardBD),
        .data_o(RF_data_o2_mux4D)
    );

    // valid_pipeline 
    assign {validIM, validD, validE, validM, validDM, validW} = valid_signs;

    Valid_pipeline u_Valid_pipeline(
        .clk(clk),
        .rst(rst),
        .cpu_en(cpu_en),
        .stall(stall),
        .redirectD(redirectD),
        .bus_wait(bus_wait),
        .interrupt_acceptD(interrupt_acceptD),
        .valid_signs(valid_signs),
        .hold_pc(hold_pc),
        .hold_fim(hold_fim),
        .hold_imd(hold_imd),
        .hold_de(hold_de),
        .hold_em(hold_em),
        .bubble_e(bubble_e),
        .bubble_dm(bubble_dm)
    );
    
    // lw-use 前递E
    mux2 #(32) u_mux2_alu_src1 (
        .data_i1(RF_data_iDM), 
        .data_i2(RF_data_o1_mux4E), 
        .sel(forwardAE), 
        .data_o(alu_src_i1E)
    );

    mux2 #(32) u_mux2_alu_src0 (
        .data_i1(RF_data_iDM), 
        .data_i2(RF_data_o2_mux4E), 
        .sel(forwardBE), 
        .data_o(alu_src_i0E)
    );

endmodule