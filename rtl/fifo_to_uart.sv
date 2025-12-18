module fifo_to_uart (
    input  logic clk,
    input  logic rstn,   // reset ativo baixo

    // FIFO
    input  logic [7:0] fifo_dout,
    input  logic       fifo_empty,
    output logic       fifo_rd_en,

    // UART
    output logic [7:0] uart_data,
    output logic       uart_valid,
    input  logic       uart_ready
);

    typedef enum logic [1:0] {
        WAIT_DATA,
        SEND,
        WAIT_UART
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            state      <= WAIT_DATA;
            fifo_rd_en <= 1'b0;
            uart_valid <= 1'b0;
        end else begin
            fifo_rd_en <= 1'b0;
            uart_valid <= 1'b0;

            case (state)
                WAIT_DATA: begin
                    if (!fifo_empty && uart_ready) begin
                        fifo_rd_en <= 1'b1;
                        state      <= SEND;
                    end
                end

                SEND: begin
                    uart_data  <= fifo_dout;
                    uart_valid <= 1'b1;
                    state      <= WAIT_UART;
                end

                WAIT_UART: begin
                    if (uart_ready)
                        state <= WAIT_DATA;
                end
            endcase
        end
    end
endmodule
