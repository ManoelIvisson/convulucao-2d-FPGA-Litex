// tb_conv.sv
`timescale 1ns/1ps
module tb_conv;
  parameter PIX_W = 8;
  parameter COEF_W = 16;
  parameter ACC_W = 32;
  parameter IMG_W = 64;
  parameter IMG_H = 64;
  parameter SHIFT = 8;

  logic clk = 0;
  always #5 clk = ~clk; // 100 MHz -> period 10ns

  logic rstn;
  initial begin
    rstn = 0;
    repeat (10) @(posedge clk);
    rstn = 1;
  end

  logic valid_in;
  logic [PIX_W-1:0] px_in;
  logic kernel_wr;
  logic [3:0] kernel_addr;
  logic signed [COEF_W-1:0] kernel_data;
  logic valid_out;
  logic [PIX_W-1:0] px_out;

  // instantiate DUT
  conv_top #(.PIX_W(PIX_W), .COEF_W(COEF_W), .ACC_W(ACC_W), .IMG_W(IMG_W), .SHIFT(SHIFT)) dut (
    .clk(clk), .rstn(rstn),
    .valid_in(valid_in), .px_in(px_in),
    .kernel_wr(kernel_wr), .kernel_addr(kernel_addr), .kernel_data(kernel_data),
    .valid_out(valid_out), .px_out(px_out)
  );

  // test image (simple gradient or pattern)
  reg [PIX_W-1:0] img [0:IMG_W*IMG_H-1];
  integer x, y, idx;

  initial begin
    // create a simple test image: gradient
    $readmemh("input.hex", img);

    @(posedge rstn);
    @(posedge clk);
    // write nine coefficients
    kernel_wr = 1;
    for (idx=0; idx<9; idx=idx+1) begin
      kernel_addr = idx;
      kernel_data = 16'sd1; // all ones
      @(posedge clk);
    end
    kernel_wr = 0;
  end

  // feed pixels line by line
  initial begin
    valid_in = 0;
    px_in = 0;
    @(posedge rstn);
    @(posedge clk);
    // small delay
    repeat (2) @(posedge clk);

    // stream pixels
    for (y=0; y<IMG_H; y=y+1) begin
      for (x=0; x<IMG_W; x=x+1) begin
        idx = y*IMG_W + x;
        px_in = img[idx];
        valid_in = 1;
        @(posedge clk);
      end
    end
    // finish stream
    valid_in = 0;
    px_in = 0;
    // wait some cycles for pipeline to flush
    repeat (50) @(posedge clk);
    $finish;
  end

  // capture output to file
  integer outfile;
  initial begin
    outfile = $fopen("output.hex","w");
    if (outfile == 0) begin
      $display("ERROR: cannot open out file");
      $finish;
    end
    forever begin
      @(posedge clk);
      if (valid_out) begin
        $fwrite(outfile, "%0h\n", px_out);
      end
    end
  end

endmodule
