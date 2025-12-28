// linebuffer_3x3.sv
// Produces a 3x3 window from a stream of pixels (left-to-right, top-to-bottom)
module linebuffer_3x3 #(
  parameter PIX_W = 8,
  parameter IMG_W = 128
)(
  input  logic                 clk,
  input  logic                 rstn,
  input  logic                 valid_in,
  input  logic [PIX_W-1:0]     px_in,

  output logic [PIX_W-1:0] w00, w01, w02,
  output logic [PIX_W-1:0] w10, w11, w12,
  output logic [PIX_W-1:0] w20, w21, w22,

  output logic                 valid_out
);

  // line RAMs: store previous two rows
  logic [PIX_W-1:0] line0 [0:IMG_W-1]; // oldest (y-2)
  logic [PIX_W-1:0] line1 [0:IMG_W-1]; // middle (y-1)
  // shift registers for current line sliding window
  logic [PIX_W-1:0] sreg0, sreg1;

  integer col;
  integer row;
  integer c0, c1, c2;
  // counters to manage start/end and valid window
  logic first_rows_filled;

  // initialize
  always_ff @(posedge clk) begin
    if (!rstn) begin
      col <= 0;
      row <= 0;
      first_rows_filled <= 1'b0;
      valid_out <= 1'b0;
      // optional: clear RAMs (synth may ignore initial values)
      // for synth, you may want to leave as-is or fill on reset by writes
    end else begin
      if (valid_in) begin
        // shift registers for current line window
        sreg1 <= sreg0;
        sreg0 <= px_in;

        // produce window values
        // w20,w21,w22 = current line pixels: sreg1, sreg0, px_in in order for 3-wide
        w20 <= line1[col]; // top-left = oldest line (y-2)
        // But careful: we need consistent mapping; to keep it simple we'll map as:
        // w00,w01,w02 = line0[col-2], line0[col-1], line0[col] etc.
        // To avoid negative indices manage with modulo and edge handling.

        // write incoming pixel into line buffers (rotate lines after finishing a row)
        line0[col] <= line1[col];
        line1[col] <= px_in;

        // update column
        if (col == IMG_W-1) begin
          col <= 0;
          row <= row + 1;
          // after two full rows written, window becomes valid
          if (row >= 1) first_rows_filled <= 1'b1;
        end else begin
          col <= col + 1;
        end

        // compute window outputs with edge handling (zero padding)
        // indices for previous columns: c-1 and c-2
        c0 = (col >= 2) ? (col-2) : -1;
        c1 = (col >= 1) ? (col-1) : -1;
        c2 = col;

        // top row (y-2) -> line0
        if (c0 == -1) w00 <= 0; else w00 <= line0[c0];
        if (c1 == -1) w01 <= 0; else w01 <= line0[c1];
        w02 <= line0[c2];

        // middle row (y-1) -> line1
        if (c0 == -1) w10 <= 0; else w10 <= line1[c0];
        if (c1 == -1) w11 <= 0; else w11 <= line1[c1];
        w12 <= line1[c2];

        // current row (y) -> constructed from recent writes: we used sreg1,sreg0,px_in
        // but due to the timing of assignment, we must assign carefully:
        // after shifting: sreg1 holds px_in(t-2), sreg0 px_in(t-1), px_in is current.
        w20 <= (c0 == -1) ? 0 : /* value at column c0 for current line */ ( (c0 == col) ? px_in : (c0 == col-1 ? sreg0 : sreg1) );
        w21 <= (c1 == -1) ? 0 : ( (c1 == col) ? px_in : (c1 == col-1 ? sreg0 : sreg1) );
        w22 <= ( (c2 == col) ? px_in : (c2 == col-1 ? sreg0 : sreg1) );

        // valid_out only after we've filled at least two previous rows and are beyond first two cols
        if (first_rows_filled && col >= 2) valid_out <= 1'b1;
        else valid_out <= 1'b0;
      end else begin
        valid_out <= 1'b0;
      end
    end
  end

endmodule
