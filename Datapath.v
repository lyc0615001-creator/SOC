module Datapath (
    input clk, rst,
    input clk_en,
    input [31:0] instr,
    input [31:0] DM_data_o,
    input reg_write_en, alu_src_mux, reg_data_mux, reg_dst_mux,
    input branch, jump,
    input [2:0] alu_control,
    output [31:0] pc_o, alu_result, DM_data_i
);
    wire zero;
    wire [31:0] pc_i, pc_src, pc_plus4, pc_branch, pc_next, pc_jump;
    wire [4:0] rs, rt, rd, RF_address3;
    wire [31:0] RF_data_i, RF_data_o1, RF_data_o2, alu_data_i2;
    wire [31:0] sign_ext, sign_ext_sl2;

    wire [31:0] jump_sl2;
    wire [15:0] lw_offset;

    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign lw_offset = instr[15:0];

    assign DM_data_i = RF_data_o2;

    // Ö¸ÁîÖ´ÐÐÄ£¿é

    pc u_pc(.clk(clk), .rst(rst), .clk_en(clk_en), .pc_i(pc_i), .pc_o(pc_o));
    
    adder u_adder_plus4(
        .add_i1(pc_o), 
        .add_i2(32'd4), 
        .add_o(pc_plus4)
        );
    
    Regfile u_Regfile(
        .clk(clk), 
        .rst(rst),
        .w_en(reg_write_en),
        .clk_en(clk_en),
        .RF_address1(rs),
        .RF_address2(rt), 
        .RF_address3(RF_address3),
        .RF_data_i(RF_data_i),
        .RF_data_o1(RF_data_o1), 
        .RF_data_o2(RF_data_o2)
        );


    // ====R====
    alu u_alu(
        .alu_control(alu_control),
        .alu_data_i1(RF_data_o1),
        .alu_data_i2(alu_data_i2),
        .alu_data_o(alu_result)
        );

    // lw sw
    signext u_signext(.ext_i(lw_offset), .ext_o(sign_ext));

    // alu_src_mux
    mux2 #(32) u_mux2_alu_data_i2 (
        .data_i1(sign_ext), 
        .data_i2(RF_data_o2), 
        .sel(alu_src_mux), 
        .data_o(alu_data_i2)
        );

    // RF_data_i
    mux2 #(32) u_mux2_RF_data_i (
        .data_i1(DM_data_o), 
        .data_i2(alu_result), 
        .sel(reg_data_mux), 
        .data_o(RF_data_i)
        );

    // reg_dst_mux
    mux2 #(5) u_mux2_RF_address3 (
        .data_i1(rd), 
        .data_i2(rt), 
        .sel(reg_dst_mux), 
        .data_o(RF_address3)
        );

    // ====beq====
    assign zero = (RF_data_o1 - RF_data_o2) == 32'd0;
    assign pc_src = zero && branch;


    sl2 u_sl2_branch(
        .sl2_i(sign_ext),
        .sl2_o(sign_ext_sl2)
        );

    adder u_adder_branch(
        .add_i1(sign_ext_sl2), 
        .add_i2(pc_plus4), 
        .add_o(pc_branch)
        );

    // pc_src
    mux2 #(32) u_mux2_pc_next (
        .data_i1(pc_branch), 
        .data_i2(pc_plus4), 
        .sel(pc_src), 
        .data_o(pc_next)
        );


    // ====jump====

    sl2 u_sl2_jump(
        .sl2_i(instr), // 25:0(32)
        .sl2_o(jump_sl2) // 27:0
        );

    assign pc_jump = {pc_plus4[31:28], jump_sl2[27:0]};


    // jump
    mux2 #(32) u_mux2_pc_i (
        .data_i1(pc_jump), 
        .data_i2(pc_next), 
        .sel(jump), 
        .data_o(pc_i)
        );
    
endmodule