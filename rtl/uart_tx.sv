module uart_tx #(
    parameter CLK_FREQ = 60_000_000,
    parameter BAUD     = 115200
)(
    input  logic       clk,
    input  logic       rstn,

    input  logic [7:0] data,
    input  logic       valid,
    output logic       ready,

    output logic       tx
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD;
    localparam integer CTR_W    = $clog2(BAUD_DIV);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state;
    logic [CTR_W-1:0] baud_cnt;
    logic [2:0]       bit_idx;
    logic [7:0]       shreg;

    assign ready = (state == IDLE);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            state    <= IDLE;
            tx       <= 1'b1;
            baud_cnt <= 0;
            bit_idx  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (valid) begin
                        shreg    <= data;
                        baud_cnt <= 0;
                        state    <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (baud_cnt == BAUD_DIV-1) begin
                        baud_cnt <= 0;
                        bit_idx  <= 0;
                        state    <= DATA;
                    end else
                        baud_cnt <= baud_cnt + 1;
                end

                DATA: begin
                    tx <= shreg[bit_idx];
                    if (baud_cnt == BAUD_DIV-1) begin
                        baud_cnt <= 0;
                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        baud_cnt <= baud_cnt + 1;
                end

                STOP: begin
                    tx <= 1'b1;
                    if (baud_cnt == BAUD_DIV-1) begin
                        baud_cnt <= 0;
                        state    <= IDLE;
                    end else
                        baud_cnt <= baud_cnt + 1;
                end
            endcase
        end
    end
endmodule
