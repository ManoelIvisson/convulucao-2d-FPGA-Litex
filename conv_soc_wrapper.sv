// conv_soc_wrapper.sv
module conv_soc_wrapper #(
    parameter PIX_W = 8,
    parameter COEF_W = 16,
    parameter ACC_W = 32,
    parameter IMG_W = 64
)(
    input  logic sys_clk,
    input  logic sys_rst,

    // Interface CSR (Control/Status Registers) do SoC
    input  logic                csr_kernel_wr,
    input  logic [3:0]          csr_kernel_addr,
    input  logic [COEF_W-1:0]   csr_kernel_data,

    input  logic                csr_pix_wr,
    input  logic [PIX_W-1:0]    csr_pix_data_in,
    
    input  logic                csr_pix_rd,    // Sinal de leitura da CPU (pop output)
    output logic [PIX_W-1:0]    csr_pix_data_out,

    output logic                status_in_full,
    output logic                status_out_empty
);

    // Sinais internos
    logic fifo_in_empty, fifo_in_rd;
    logic [PIX_W-1:0] core_pix_in;
    logic core_valid_out;
    logic [PIX_W-1:0] core_pix_out;
    logic fifo_out_full;

    // 1. FIFO de Entrada (CPU -> Core)
    // Simples FIFO síncrona "lookahead"
    // Nota: Em produção, use primitivas de bloco de memória da Lattice, 
    // mas aqui faremos inferência comportamental para portabilidade e clareza.
    logic [PIX_W-1:0] mem_in [0:127]; // Buffer pequeno
    logic [6:0] wr_ptr_in = 0, rd_ptr_in = 0;
    logic [6:0] count_in = 0;

    assign status_in_full = (count_in == 127);
    assign fifo_in_empty = (count_in == 0);
    assign core_pix_in = mem_in[rd_ptr_in];

    always_ff @(posedge sys_clk) begin
        if (sys_rst) begin
            wr_ptr_in <= 0; rd_ptr_in <= 0; count_in <= 0;
        end else begin
            // Escrita da CPU
            if (csr_pix_wr && !status_in_full) begin
                mem_in[wr_ptr_in] <= csr_pix_data_in;
                wr_ptr_in <= wr_ptr_in + 1;
                if (!fifo_in_rd) count_in <= count_in + 1;
            end else if (fifo_in_rd && !csr_pix_wr) begin
                count_in <= count_in - 1;
            end
            
            // Leitura pelo Core (automática se houver dados)
            if (fifo_in_rd) begin
                rd_ptr_in <= rd_ptr_in + 1;
            end
        end
    end

    // O core consome se a FIFO não estiver vazia E a FIFO de saída não estiver cheia
    assign fifo_in_rd = !fifo_in_empty && !fifo_out_full;

    // 2. Instância do Seu Core
    conv_top #(
        .PIX_W(PIX_W), .COEF_W(COEF_W), .ACC_W(ACC_W), 
        .IMG_W(IMG_W), .USE_ABS(1), .SHIFT(2) // Configurado para Sobel conforme seu exemplo
    ) core (
        .clk(sys_clk),
        .rstn(!sys_rst),
        .valid_in(fifo_in_rd),
        .px_in(core_pix_in),
        .kernel_wr(csr_kernel_wr),
        .kernel_addr(csr_kernel_addr),
        .kernel_data(csr_kernel_data),
        .valid_out(core_valid_out),
        .px_out(core_pix_out)
    );

    // 3. FIFO de Saída (Core -> CPU)
    logic [PIX_W-1:0] mem_out [0:127];
    logic [6:0] wr_ptr_out = 0, rd_ptr_out = 0;
    logic [6:0] count_out = 0;

    assign fifo_out_full = (count_out == 127);
    assign status_out_empty = (count_out == 0);
    assign csr_pix_data_out = mem_out[rd_ptr_out];

    always_ff @(posedge sys_clk) begin
        if (sys_rst) begin
            wr_ptr_out <= 0; rd_ptr_out <= 0; count_out <= 0;
        end else begin
            // Escrita pelo Core
            if (core_valid_out && !fifo_out_full) begin
                mem_out[wr_ptr_out] <= core_pix_out;
                wr_ptr_out <= wr_ptr_out + 1;
                if (!csr_pix_rd) count_out <= count_out + 1;
            end else if (csr_pix_rd && !core_valid_out) begin
                count_out <= count_out - 1;
            end

            // Leitura pela CPU
            if (csr_pix_rd && !status_out_empty) begin
                rd_ptr_out <= rd_ptr_out + 1;
            end
        end
    end

endmodule