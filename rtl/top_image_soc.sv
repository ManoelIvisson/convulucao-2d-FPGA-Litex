module top_image_soc #(
    parameter IMG_W = 640,
    parameter IMG_H = 960,
    parameter PIX_W = 8
)(
    input  logic clk,
    input  logic rstn,
    input  logic        i_csr_pixel_valid,
    input  logic [7:0]  i_csr_pixel_data,

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

    logic [7:0] uart_data;
    logic       uart_valid;
    logic       uart_ready;
    logic       uart_tx_pin;


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
    pixel_feeder_uart feeder (
        .clk        (clk),
        .rstn       (rstn),

        .px_valid   (i_csr_pixel_valid),
        .px_in      (i_csr_pixel_data),

        .valid_out  (px_valid),
        .px_out     (px_data)
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

    fifo_to_uart streamer (
        .clk(clk),
        .rstn(rstn),

        .fifo_dout (fifo_dout),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),

        .uart_data (uart_data),
        .uart_valid(uart_valid),
        .uart_ready(uart_ready)
    );


    uart_tx #(
        .CLK_FREQ(60_000_000),
        .BAUD(115200)
    ) uart (
        .clk  (clk),
        .rstn (rstn),

        .data (uart_data),
        .valid(uart_valid),
        .ready(uart_ready),

        .tx   (uart_tx_pin)
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
