module MIPS (
    input clk, rst,
    input cpu_en,
    input [31:0] instrIM,
    input [31:0] DM_data_oDM,
    output mem_write_en_effM, mem_read_en_effM,
    output rom_en,
    output [31:0] pc_oF,
    output [31:0] alu_resultM,
    output [31:0] DM_data_iM
);
    wire reg_write_enE, reg_write_enM, reg_write_enDM;
    wire reg_write_enW, alu_src_muxE, reg_data_muxDM, reg_dst_muxE;
    wire reg_data_muxE, reg_data_muxM;
    wire branchD, jumpD;
    wire used_rsD, used_rtD;
    wire [2:0] alu_controlE;
    wire [31:0] instrD;
    wire validM, mem_write_enM, mem_read_enM, stall;

    Datapath u_Datapath(
        .clk(clk), 
        .rst(rst),
        .cpu_en(cpu_en),
        .instrIM(instrIM),
        .DM_data_oDM(DM_data_oDM),
        .reg_write_enE(reg_write_enE), 
        .reg_write_enM(reg_write_enM), 
        .reg_write_enDM(reg_write_enDM), 
        .reg_write_enW(reg_write_enW),
        .alu_src_muxE(alu_src_muxE),
        .reg_data_muxE(reg_data_muxE),
        .reg_data_muxM(reg_data_muxM),
        .reg_data_muxDM(reg_data_muxDM),
        .reg_dst_muxE(reg_dst_muxE),
        .branchD(branchD),
        .jumpD(jumpD),
        .used_rsD(used_rsD),
        .used_rtD(used_rtD),
        .alu_controlE(alu_controlE),
        // out
        .pc_oF(pc_oF),
        .alu_resultM(alu_resultM),
        .DM_data_iM(DM_data_iM),
        .instrD(instrD),
        .stall(stall), 
        .validM(validM)
    );

    // 让valid 只生效在处理器内部
    assign mem_write_en_effM = validM && mem_write_enM;
    assign mem_read_en_effM = validM && mem_read_enM;
    assign rom_en = cpu_en && ~stall;

    Controller u_Controller(
        .clk(clk),
        .rst(rst),
        .cpu_en(cpu_en),
        .stall(stall), 
        .op_code(instrD[31:26]),
        .funct(instrD[5:0]),
        // out
        .reg_write_enE(reg_write_enE), 
        .reg_write_enM(reg_write_enM), 
        .reg_write_enDM(reg_write_enDM), 
        .reg_write_enW(reg_write_enW), 
        .alu_src_muxE(alu_src_muxE),  
        .reg_dst_muxE(reg_dst_muxE), 
        .reg_data_muxE(reg_data_muxE), 
        .reg_data_muxM(reg_data_muxM), 
        .reg_data_muxDM(reg_data_muxDM), 
        .mem_write_enM(mem_write_enM),
        .mem_read_enM(mem_read_enM),
        .branchD(branchD), 
        .jumpD(jumpD),
        .used_rsD(used_rsD),
        .used_rtD(used_rtD),
        .alu_controlE(alu_controlE)
    );
    
endmodule