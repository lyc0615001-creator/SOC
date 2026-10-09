module cpu_system_rst (
    input         clk_cpu_50,
    input         rst_n,
    output        cpu_rst_n
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] cpu_rst_sync;

    always @(posedge clk_cpu_50 or negedge rst_n) begin
        if (!rst_n)
            cpu_rst_sync <= 2'b00;
        else
            cpu_rst_sync <= {cpu_rst_sync[0], 1'b1};
    end

    wire cpu_rst_n = cpu_rst_sync[1];
endmodule