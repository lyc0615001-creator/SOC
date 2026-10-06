module CPU_TOP (
    input clk,
    input rst,
    input [31:0] cpu_rdataM, // 获得读数据
    output cpu_en, // 分频信号
    output cpu_readM, // 读使能
    output cpu_writeM, // 写使能
    output [3:0] cpu_wstrbM, // 字节写使能
    output wire [31:0] cpu_addrM, // 读地址
    output wire [31:0] cpu_wdataM, // 写数据
    
    output wire rom_en, // 指令读使能
    output wire [31:0] pc_oF, // 指令读地址
    input [31:0] instrIM, //获得指令

    input  irq, // 中断

    output cpu_requestM, // cpu有效请求
    input  cpu_ready     // 请求处理就绪
  );

    localparam T_clk = 1;
    wire mem_read_en_effM, mem_write_en_effM;
    wire [31:0] early_resultM, DM_data_iM, DM_data_oM;

    assign DM_data_oM = cpu_rdataM; 
    assign cpu_readM = mem_read_en_effM;
    assign cpu_writeM = mem_write_en_effM;
    assign cpu_addrM = early_resultM;
    assign cpu_wdataM = DM_data_iM;
    assign cpu_wstrbM = cpu_writeM ? 4'b1111 : 4'b0000;

    // 非固定周期延迟
    wire mem_accessM, bus_wait;
    assign mem_accessM = mem_read_en_effM || mem_write_en_effM;
    assign cpu_requestM = mem_accessM;
    assign bus_wait = mem_accessM && !cpu_ready;

    MIPS u_mips(
      .clk(clk),
      .rst(rst),
      .irq(irq),
      .cpu_en(cpu_en),
      .instrIM(instrIM),
      .DM_data_oM(DM_data_oM),
      .bus_wait(bus_wait),
      // out
      .mem_write_en_effM(mem_write_en_effM),
      .mem_read_en_effM(mem_read_en_effM),
      .rom_en(rom_en),
      .pc_oF(pc_oF),
      .early_resultM(early_resultM),
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