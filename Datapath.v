`timescale 1ns / 1ps
module Datapath (
    input clk, rst,
    input clk_en,
    input [31:0] instrIM,
    input [31:0] DM_data_oDM,
    input reg_write_enE, reg_write_enM, reg_write_enDM,
    input reg_write_enW, alu_src_muxE, reg_data_muxDM, reg_dst_muxD,
    input reg_data_muxE, reg_data_muxM,
    input branchD, jumpD,
    input used_rsD, used_rtD,
    input [2:0] alu_controlE,
    output [31:0] pc_oF, alu_resultM, DM_data_iM, pc_oM, instrD,
    output stall, validM
);

    // F阶段变量
    wire [31:0] pc_plus4F;

     // IM阶段变量
    wire [31:0] pc_plus4IM;
    
    // D阶段变量
    wire zeroD, branch_selD, jump_selD;
    wire [4:0] rsD, rtD, rdD, RF_address3D;
    wire [15:0] lw_offsetD;
    wire [31:0] pc_plus4D, pc_branchD, pc_jumpD, pc_nextD, pc_iD;
    wire [31:0] sign_extD, sign_ext_sl2D, jump_sl2D;
    wire [31:0] RF_data_o1D, RF_data_o2D;

    // E阶段变量
    wire [4:0] RF_address3E;
    wire [31:0] sign_extE;
    wire [31:0] DM_data_iE, alu_data_i2E, alu_resultE;
    wire [31:0] RF_data_o1_mux4E, RF_data_o2_mux4E;

    // M阶段变量
    wire [4:0] RF_address3M;
    // DM阶段变量
    wire [4:0] RF_address3DM;
    wire [31:0] alu_resultDM, RF_data_iDM;

    // W阶段变量
    wire [4:0] RF_address3W;
    wire [31:0] RF_data_iW;

    // HAZARD 变量
    wire [1:0] forwardAD, forwardBD;
    wire [31:0] RF_data_o1_mux4D, RF_data_o2_mux4D;
    wire redirectD;

    // Valid_pipeline 变量
    wire validIM, validD, validE, validM, validDM, validW;
    wire [5:0] valid_signs;
    wire rf_write_enW;

    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    assign lw_offsetD = instrD[15:0];

    assign DM_data_iE = RF_data_o2_mux4E;

    // 指令执行模块

    // pc 一级延迟
    pc u_pc(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .pc_i(pc_iD), .pc_o(pc_oF));
    
    adder u_adder_plus4(
        .add_i1(pc_oF), 
        .add_i2(32'd4), 
        .add_o(pc_plus4F)
        );
    
    // F -> IM 指令存储器延迟同步
    // 同步变量 pc_plus4F
    flopenrc #(32) u_flopenrc_pc_plus4IM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .clear(1'b0), .din(pc_plus4F), .dout(pc_plus4IM));

    // IM -> D 流水线触发器
    // 延迟变量 instrIM pc_plus4IM
    flopenrc #(32) u_flopenrc_instrD(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .clear(1'b0), .din(instrIM), .dout(instrD));
    flopenrc #(32) u_flopenrc_pc_plus4D(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .clear(1'b0), .din(pc_plus4IM), .dout(pc_plus4D));

    assign rf_write_enW = validW && reg_write_enW;
    Regfile u_Regfile(
        .clk(clk), 
        .rst(rst),
        .w_en(rf_write_enW),
        .clk_en(clk_en),
        .RF_address1(rsD),
        .RF_address2(rtD), 
        .RF_address3(RF_address3W),
        .RF_data_i(RF_data_iW),
        .RF_data_o1(RF_data_o1D), 
        .RF_data_o2(RF_data_o2D)
        );


    // D -> E 流水线触发器
    // 延迟变量 RF_address3D RF_data_o1_mux4D RF_data_o2_mux4D sign_extD
    flopenrc #(5) u_flopenrc_RF_address3E(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_address3D), .dout(RF_address3E));
    flopenrc #(32) u_flopenrc_RF_data_o1_mux4E(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_data_o1_mux4D), .dout(RF_data_o1_mux4E));
    flopenrc #(32) u_flopenrc_RF_data_o2_mux4E(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_data_o2_mux4D), .dout(RF_data_o2_mux4E));
    flopenrc #(32) u_flopenrc_sign_extE(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(sign_extD), .dout(sign_extE));

    // E -> M 流水线触发器  
    // 延迟变量 alu_resultE DM_data_iE RF_address3E
    flopenrc #(32) u_flopenrc_alu_resultM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(alu_resultE), .dout(alu_resultM));
    flopenrc #(32) u_flopenrc_DM_data_iM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(DM_data_iE), .dout(DM_data_iM));
    flopenrc #(5) u_flopenrc_RF_address3M(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_address3E), .dout(RF_address3M));


    // M -> DM 数据存储器延迟同步
    // 延迟变量 alu_resultM RF_address3M 
    flopenrc #(32) u_flopenrc_alu_resultDM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(alu_resultM), .dout(alu_resultDM));
    flopenrc #(5) u_flopenrc_RF_address3DM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_address3M), .dout(RF_address3DM));

    // DM -> W 流水线触发器
    // 延迟变量 RF_address3DM RF_data_iDM
    flopenrc #(5) u_flopenrc_RF_address3W(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_address3DM), .dout(RF_address3W));
    flopenrc #(32) u_flopenrc_RF_data_iW(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(RF_data_iDM), .dout(RF_data_iW));

    // LED展示 pc F->M
    wire [31:0] pc_oD, pc_oE, pc_oIM;
    flopenrc #(32) u_flopenrc_pc_oIM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .clear(1'b0), .din(pc_oF), .dout(pc_oIM));
    flopenrc #(32) u_flopenrc_pc_oD(.clk(clk), .rst(rst), .clk_en(clk_en), .en(~stall), .clear(1'b0), .din(pc_oIM), .dout(pc_oD));
    flopenrc #(32) u_flopenrc_pc_oE(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(pc_oD), .dout(pc_oE));
    flopenrc #(32) u_flopenrc_pc_oM(.clk(clk), .rst(rst), .clk_en(clk_en), .en(1'b1), .clear(1'b0), .din(pc_oE), .dout(pc_oM));


    // ====R====
    alu u_alu(
        .alu_control(alu_controlE),
        .alu_data_i1(RF_data_o1_mux4E),
        .alu_data_i2(alu_data_i2E),
        .alu_data_o(alu_resultE)
        );

    // lw sw
    signext u_signext(.ext_i(lw_offsetD), .ext_o(sign_extD));

    // alu_src_muxE
    mux2 #(32) u_mux2_alu_data_i2 (
        .data_i1(sign_extE), 
        .data_i2(RF_data_o2_mux4E), 
        .sel(alu_src_muxE), 
        .data_o(alu_data_i2E)
        );

    // RF_data_iDM
    mux2 #(32) u_mux2_RF_data_i (
        .data_i1(DM_data_oDM), 
        .data_i2(alu_resultDM), 
        .sel(reg_data_muxDM), 
        .data_o(RF_data_iDM)
        );

    // reg_dst_muxD
    mux2 #(5) u_mux2_RF_address3 (
        .data_i1(rdD), 
        .data_i2(rtD), 
        .sel(reg_dst_muxD), 
        .data_o(RF_address3D)
        );

    // ====beq====
    assign zeroD = (RF_data_o1_mux4D == RF_data_o2_mux4D);
    assign branch_selD = validD && !stall && zeroD && branchD;


    sl2 u_sl2_branch(
        .sl2_i(sign_extD),
        .sl2_o(sign_ext_sl2D)
        );

    adder u_adder_branch(
        .add_i1(sign_ext_sl2D), 
        .add_i2(pc_plus4D), 
        .add_o(pc_branchD)
        );

    // branch_selD
    mux2 #(32) u_mux2_pc_next (
        .data_i1(pc_branchD), 
        .data_i2(pc_plus4F), 
        .sel(branch_selD), 
        .data_o(pc_nextD)
        );


    // ====jump====

    sl2 u_sl2_jump(
        .sl2_i(instrD), // 25:0(32)
        .sl2_o(jump_sl2D) // 27:0
        );

    assign pc_jumpD = {pc_plus4D[31:28], jump_sl2D[27:0]};
    assign jump_selD = validD && !stall && jumpD;


    // jump_selD
    mux2 #(32) u_mux2_pc_i (
        .data_i1(pc_jumpD), 
        .data_i2(pc_nextD), 
        .sel(jump_selD), 
        .data_o(pc_iD)
        );

    // HAZARD
    Hazard u_Hazard(
        .rsD(rsD), 
        .rtD(rtD),
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
        .branch_selD(branch_selD),
        .jump_selD(jump_selD),
        .validD(validD),
        .validE(validE),
        .validM(validM),
        .validDM(validDM),
        // out
        .forwardAD(forwardAD), 
        .forwardBD(forwardBD),
        .stall(stall), 
        .redirectD(redirectD)
    );

    mux4 #(32) u_mux4_RF_data1(
        .data_i1(RF_data_o1D),
        .data_i2(alu_resultE),
        .data_i3(alu_resultM),
        .data_i4(RF_data_iDM),
        .sel(forwardAD),
        .data_o(RF_data_o1_mux4D)
    );

    mux4 #(32) u_mux4_RF_data2(
        .data_i1(RF_data_o2D),
        .data_i2(alu_resultE),
        .data_i3(alu_resultM),
        .data_i4(RF_data_iDM),
        .sel(forwardBD),
        .data_o(RF_data_o2_mux4D)
    );

    // valid_pipeline 
    assign {validIM, validD, validE, validM, validDM, validW} = valid_signs;

    Valid_pipeline u_Valid_pipeline(
        .clk(clk),
        .rst(rst),
        .clk_en(clk_en),
        .stall(stall),
        .redirectD(redirectD),
        .valid_signs(valid_signs)
    );
    
endmodule