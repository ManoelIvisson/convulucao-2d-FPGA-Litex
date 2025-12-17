module top_image_soc #(
    parameter IMG_W = 640,
    parameter IMG_H = 960,
    parameter PIX_W = 8
)(
    input  logic clk,
    input  logic rstn,

    // ---- CSR interface (LiteX conecta aqui) ----
    input  logic        csr_pixel_re,
    output logic [7:0]  csr_pixel_r,
    output logic        csr_valid_r,
    output logic [31:0] pixel_count,

    // ---- Status ----
    output logic        done,
    output logic [31:0] cycle_count
);

    // ============================================================
    // Sinais internos
    // ============================================================

    // ROM → Feeder
    logic [PIX_W-1:0] rom_px;

    // Feeder → Convolução
    logic [PIX_W-1:0] feed_px;
    logic             feed_valid;
    logic             feeding_done;

    // Convolução → FIFO
    logic [PIX_W-1:0] conv_px;
    logic             conv_valid;

    // FIFO → CSR
    logic [7:0] fifo_dout;
    logic       fifo_empty;
    logic       fifo_rd_en;

    // ============================================================
    // Contador de ciclos (só hardware, sem CPU)
    // ============================================================
    always_ff @(posedge clk) begin
        if (!rstn)
            cycle_count <= 32'd0;
        else if (!done)
            cycle_count <= cycle_count + 1;
    end

    // ============================================================
    // Pixel Feeder (gera fluxo streaming)
    // ============================================================
    pixel_feeder #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .PIX_W(PIX_W)
    ) feeder (
        .clk       (clk),
        .rstn      (rstn),
        .px_in     (rom_px),
        .px_out    (feed_px),
        .valid_out (feed_valid),
        .done      (feeding_done)
    );

    // ============================================================
    // Convolução 2D 3x3 (PURO)
    // ============================================================
    conv_top conv (
        .clk       (clk),
        .rstn      (rstn),
        .px_in     (feed_px),
        .valid_in  (feed_valid),
        .px_out    (conv_px),
        .valid_out (conv_valid)
    );

    // ============================================================
    // FIFO de saída (buffer entre HW e CPU)
    // ============================================================
    output_fifo fifo (
        .clk        (clk),
        .rstn       (rstn),
        .wr_data    (conv_px),
        .wr_en      (conv_valid),
        .rd_data    (fifo_dout),
        .rd_en      (fifo_rd_en),
        .empty      (fifo_empty)
    );

    // ============================================================
    // CSR LiteX (CPU lê pixels processados)
    // ============================================================
    conv_csr csr_if (
        .clk(clk),
        .rst(~rstn),
        .fifo_dout(fifo_dout),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .csr_pixel_re(csr_pixel_re),
        .csr_pixel_r(csr_pixel_r),
        .csr_valid_r(csr_valid_r),
        .pixel_count(pixel_count)
    );


    // ============================================================
    // Done flag
    // ============================================================
    always_ff @(posedge clk) begin
        if (!rstn)
            done <= 1'b0;
        else if (feeding_done)
            done <= 1'b1;
    end

endmodule
