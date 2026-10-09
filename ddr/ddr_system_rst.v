module ddr_system_rst (
    input         ui_clk,
    input         rst_n,
    output        ui_system_rst
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] ui_rst_sync;

    always @(posedge ui_clk or negedge rst_n) begin
        if (!rst_n)
            ui_rst_sync <= 2'b11;
        else
            ui_rst_sync <= {ui_rst_sync[0], 1'b0};
    end

    assign ui_system_rst = ui_rst_sync[1];
endmodule