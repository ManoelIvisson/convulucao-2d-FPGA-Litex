# Convulução 2D na FPGA Colorlight i9 com Litex

## Kernels

### Kernel Sobel horinzotal

    kernel_wr = 1;

    kernel_addr = 0; kernel_data = -16'sd1; @(posedge clk);
    kernel_addr = 1; kernel_data =  16'sd0; @(posedge clk);
    kernel_addr = 2; kernel_data =  16'sd1; @(posedge clk);

    kernel_addr = 3; kernel_data = -16'sd2; @(posedge clk);
    kernel_addr = 4; kernel_data =  16'sd0; @(posedge clk);
    kernel_addr = 5; kernel_data =  16'sd2; @(posedge clk);

    kernel_addr = 6; kernel_data = -16'sd1; @(posedge clk);
    kernel_addr = 7; kernel_data =  16'sd0; @(posedge clk);
    kernel_addr =  8; kernel_data = 16'sd1; @(posedge clk);

    kernel_wr = 0;

### Kernel Blur simples

