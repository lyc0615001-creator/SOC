module CPU_TOP (
    input clk,
    input rst,
    input [31:0] cpu_rdataDM, // 获得读数据
    output cpu_en, // 分频信号
    output mem_readM, // 读使能
    output mem_writeM, // 写使能
    output wire [31:0] cpu_addrM, // 读地址
    output wire [31:0] cpu_wdataM, // 写数据
    
    output wire rom_en, // 指令读使能
    output wire [31:0] pc_oF, // 指令读地址
    input [31:0] instrIM //获得指令
  );

    localparam T_clk = 1;
    wire mem_read_en_effM, mem_write_en_effM;
    wire [31:0] alu_resultM, DM_data_iM, DM_data_oDM;

    assign DM_data_oDM = cpu_rdataDM; 
    assign mem_readM = mem_read_en_effM;
    assign mem_writeM = mem_write_en_effM;
    assign cpu_addrM = alu_resultM;
    assign cpu_wdataM = DM_data_iM;

    MIPS u_mips(
      .clk(clk),
      .rst(rst),
      .cpu_en(cpu_en),
      .instrIM(instrIM),
      .DM_data_oDM(DM_data_oDM),
      // out
      .mem_write_en_effM(mem_write_en_effM),
      .mem_read_en_effM(mem_read_en_effM),
      .rom_en(rom_en),
      .pc_oF(pc_oF),
      .alu_resultM(alu_resultM),
      .DM_data_iM(DM_data_iM)
    );

    // 分频器
    cpu_cpu_en u_cpu_cpu_en(
        .clk(clk),
        .rst(rst),
        .T_clk(T_clk),
        .cpu_en(cpu_en)
    );

endmodule