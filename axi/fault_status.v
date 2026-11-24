module fault_status (
    input  wire         clk,
    input  wire         rst_n,

    // =========================
    // transaction monitor
    // =========================
    input  wire         txn_done,
    input  wire         txn_source,
    input  wire         txn_write,
    input  wire [31:0]  txn_addr,
    input  wire [1:0]   txn_resp,

    // =========================
    // MMIO slave
    // =========================
    input  wire         fault_request,
    input  wire         fault_re,
    input  wire         fault_we,
    input  wire [3:0]   fault_wstrb,
    input  wire [7:0]   fault_addr,
    input  wire [31:0]  fault_wdata,

    output wire         fault_ready,
    output reg  [31:0]  fault_rdata
);

    localparam FAULT_STATUS = 8'h00; // 32'h1000_A000;
    localparam FAULT_ADDR   = 8'h04; // 32'h1000_A004;
    localparam FAULT_INFO   = 8'h08; // 32'h1000_A008;

    reg fault_valid;

    reg [31:0] addr_reg;
    reg        source_reg;
    reg        rw_reg;
    reg [1:0]  resp_reg;

    // state
    assign fault_ready = fault_request;

    // affair
    wire fault_event;
    wire clear_event; 
    wire mmio_re;
    wire mmio_we;


    assign fault_event = txn_done && (txn_resp == 2'b10 || txn_resp == 2'b11);
    assign clear_event = mmio_we && (fault_addr == FAULT_STATUS) &&  fault_wdata[0];

    assign mmio_re = fault_request && fault_re;
    assign mmio_we = fault_request && fault_we && (fault_wstrb == 4'b1111);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_valid <= 1'b0;

            addr_reg   <= 32'd0;
            source_reg <= 1'b0;
            rw_reg     <= 1'b0;
            resp_reg   <= 2'b00;
        end else begin
            if (fault_event && (!fault_valid || clear_event)) begin
                addr_reg   <= txn_addr;
                source_reg <= txn_source;
                rw_reg     <= txn_write;
                resp_reg   <= txn_resp;

                fault_valid <= 1'b1;
            end

            else if (clear_event) begin
                fault_valid <= 1'b0;
            end
        end
    end

    // source
    wire reference;
    wire direction;

    assign reference = source_reg; // 0 CPU 1 DMA
    assign direction = rw_reg;  // 0 read 1 write

    always @(*) begin
        fault_rdata = 32'd0;
        if (mmio_re) begin
            case (fault_addr)
                FAULT_STATUS: fault_rdata = {31'd0, fault_valid};
                FAULT_ADDR: fault_rdata = addr_reg;
                FAULT_INFO: fault_rdata = {28'd0, reference, direction, resp_reg};
                default: ;
            endcase
        end
    end

endmodule