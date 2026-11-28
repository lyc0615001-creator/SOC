module dma_cfg_checker (
    input  wire [31:0] src_addr,
    input  wire [31:0] dst_addr,
    input  wire [31:0] length,

    output wire        config_valid
);

    // ============================================================
    // Address map
    // ============================================================

    // BRAM
    localparam [31:0] BRAM_BASE         = 32'h0001_0000;
    localparam [31:0] BRAM_END          = 32'h0001_FFFF;

    // NPU legacy A/B
    // 合法32-bit起始地址为 0x100~0x1FC / 0x200~0x2FC
    // 但DMA按byte范围判断，因此END为0x1FF / 0x2FF
    localparam [31:0] NPU_LEGACY_A_BASE = 32'h4000_0100;
    localparam [31:0] NPU_LEGACY_A_END  = 32'h4000_01FF;

    localparam [31:0] NPU_LEGACY_B_BASE = 32'h4000_0200;
    localparam [31:0] NPU_LEGACY_B_END  = 32'h4000_02FF;

    // NPU C，DMA只允许作为source
    localparam [31:0] NPU_C_BASE        = 32'h4000_0300;
    localparam [31:0] NPU_C_END         = 32'h4000_03FF;

    // P2-3A packed A/B
    // 每个窗口 64 Byte = 16 x 32-bit word
    localparam [31:0] NPU_PACKED_A_BASE = 32'h4000_0500;
    localparam [31:0] NPU_PACKED_A_END  = 32'h4000_053F;

    localparam [31:0] NPU_PACKED_B_BASE = 32'h4000_0600;
    localparam [31:0] NPU_PACKED_B_END  = 32'h4000_063F;

    // DDR shared / uncached
    // 0x8400_0000以上仍属于CPU cacheable private区域，DMA禁止
    localparam [31:0] DDR_SHARED_BASE   = 32'h8000_0000;
    localparam [31:0] DDR_SHARED_END    = 32'h83FF_FFFF;


    // ============================================================
    // Basic legality
    // ============================================================

    wire legal_length;
    wire addr_aligned;

    // DMA按32-bit word搬运
    assign legal_length =
        (length != 32'd0) &&
        (length[1:0] == 2'b00);

    assign addr_aligned =
        (src_addr[1:0] == 2'b00) &&
        (dst_addr[1:0] == 2'b00);


    // ============================================================
    // Last byte address
    // ============================================================

    // 使用33bit捕获32bit地址空间overflow
    wire [32:0] src_last;
    wire [32:0] dst_last;

    assign src_last =
        {1'b0, src_addr} +
        {1'b0, length} -
        33'd1;

    assign dst_last =
        {1'b0, dst_addr} +
        {1'b0, length} -
        33'd1;

    wire no_overflow;

    assign no_overflow =
        !src_last[32] &&
        !dst_last[32];


    // ============================================================
    // Source range
    //
    // DMA source允许：
    //   BRAM
    //   NPU C
    //   shared DDR
    //
    // 不允许：
    //   legacy A/B
    //   packed A/B
    // ============================================================

    wire src_bram_ok;
    wire src_npu_c_ok;
    wire src_ddr_ok;

    wire src_range_ok;

    assign src_bram_ok =
        (src_addr >= BRAM_BASE) &&
        (src_last <= {1'b0, BRAM_END});

    assign src_npu_c_ok =
        (src_addr >= NPU_C_BASE) &&
        (src_last <= {1'b0, NPU_C_END});

    assign src_ddr_ok =
        (src_addr >= DDR_SHARED_BASE) &&
        (src_last <= {1'b0, DDR_SHARED_END});

    assign src_range_ok =
        src_bram_ok  ||
        src_npu_c_ok ||
        src_ddr_ok;


    // ============================================================
    // Destination range
    //
    // DMA destination允许：
    //   BRAM
    //   legacy A
    //   legacy B
    //   packed A
    //   packed B
    //   shared DDR
    //
    // 不允许NPU C
    // ============================================================

    wire dst_bram_ok;

    wire dst_legacy_a_ok;
    wire dst_legacy_b_ok;

    wire dst_packed_a_ok;
    wire dst_packed_b_ok;

    wire dst_ddr_ok;

    wire dst_range_ok;


    assign dst_bram_ok =
        (dst_addr >= BRAM_BASE) &&
        (dst_last <= {1'b0, BRAM_END});


    assign dst_legacy_a_ok =
        (dst_addr >= NPU_LEGACY_A_BASE) &&
        (dst_last <= {1'b0, NPU_LEGACY_A_END});

    assign dst_legacy_b_ok =
        (dst_addr >= NPU_LEGACY_B_BASE) &&
        (dst_last <= {1'b0, NPU_LEGACY_B_END});


    assign dst_packed_a_ok =
        (dst_addr >= NPU_PACKED_A_BASE) &&
        (dst_last <= {1'b0, NPU_PACKED_A_END});

    assign dst_packed_b_ok =
        (dst_addr >= NPU_PACKED_B_BASE) &&
        (dst_last <= {1'b0, NPU_PACKED_B_END});


    assign dst_ddr_ok =
        (dst_addr >= DDR_SHARED_BASE) &&
        (dst_last <= {1'b0, DDR_SHARED_END});


    assign dst_range_ok =
        dst_bram_ok     ||
        dst_legacy_a_ok ||
        dst_legacy_b_ok ||
        dst_packed_a_ok ||
        dst_packed_b_ok ||
        dst_ddr_ok;


    // ============================================================
    // Overlap
    // ============================================================

    wire no_overlap;

    // 两个闭区间：
    //
    // [src_addr, src_last]
    // [dst_addr, dst_last]
    //
    // 必须完全分离
    assign no_overlap =
        (src_last < {1'b0, dst_addr}) ||
        (dst_last < {1'b0, src_addr});


    // ============================================================
    // Final result
    // ============================================================

    assign config_valid =
        legal_length &&
        addr_aligned &&
        no_overflow &&
        src_range_ok &&
        dst_range_ok &&
        no_overlap;

endmodule