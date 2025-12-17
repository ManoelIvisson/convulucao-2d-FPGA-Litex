# 2D Convolution Engine for FPGA

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-orange.svg)]()
[![FPGA](https://img.shields.io/badge/target-FPGA-green.svg)]()
[![Repo](https://img.shields.io/badge/repo-GitHub-black.svg)](https://github.com/ManoelIvisson/convulucao-2d-FPGA-Litex)

## 📋 Table of Contents

- [English Documentation](#english-documentation)
  - [Overview](#overview)
  - [Features](#features)
  - [Architecture](#architecture)
  - [Module Descriptions](#module-descriptions)
  - [Parameters](#parameters)
  - [Usage Examples](#usage-examples)
  - [Getting Started](#getting-started)
  - [Simulation](#simulation)
  - [Performance](#performance)
  - [Applications](#applications)
- [Documentação em Português](#documentação-em-português)
  - [Visão Geral](#visão-geral)
  - [Características](#características)
  - [Arquitetura](#arquitetura)
  - [Descrição dos Módulos](#descrição-dos-módulos)
  - [Parâmetros](#parâmetros)
  - [Exemplos de Uso](#exemplos-de-uso)
  - [Como Começar](#como-começar)
  - [Simulação](#simulação)
  - [Desempenho](#desempenho)
  - [Aplicações](#aplicações)

---

# English Documentation

## Overview

This project implements a **high-performance 2D convolution engine** designed for FPGA platforms. It processes 8-bit grayscale images using configurable 3×3 convolution kernels, ideal for real-time image processing applications such as edge detection, blurring, sharpening, and other computer vision tasks.

The design uses a streaming architecture with line buffers, enabling efficient processing of images of arbitrary height with minimal memory overhead.

## Features

- ✅ **3×3 Convolution Kernel**: Fully configurable coefficients
- ✅ **Streaming Architecture**: Processes one pixel per clock cycle
- ✅ **Parameterizable Design**: Configurable bit widths and image dimensions
- ✅ **Line Buffer**: Efficient memory usage for arbitrary image heights
- ✅ **Edge Handling**: Zero-padding for border pixels
- ✅ **Optional Absolute Value**: For gradient magnitude (Sobel, etc.)
- ✅ **Configurable Normalization**: Programmable bit-shift for output scaling
- ✅ **Pipeline Architecture**: Optimized for high clock frequencies
- ✅ **Overflow Protection**: Automatic clamping to valid pixel range

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         conv_top                            │
│                                                             │
│  ┌──────────────┐    ┌─────────────┐    ┌──────────────┐  │
│  │   Kernel     │    │ Line Buffer │    │     MAC9     │  │
│  │   Storage    │───▶│   (3x3)     │───▶│  Multiply &  │  │
│  │   (9 coefs)  │    │  Window     │    │  Accumulate  │  │
│  └──────────────┘    └─────────────┘    └──────────────┘  │
│         ▲                   ▲                    │         │
│         │                   │                    ▼         │
│    kernel_wr           valid_in             ┌────────┐    │
│    kernel_addr          px_in               │ Norm & │    │
│    kernel_data                              │ Clamp  │    │
│                                             └────────┘    │
│                                                  │         │
│                                                  ▼         │
│                                            valid_out       │
│                                            px_out          │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Input Stream**: Pixels arrive sequentially (left-to-right, top-to-bottom)
2. **Line Buffer**: Maintains a 3×3 sliding window across rows
3. **MAC Unit**: Performs 9 multiply-accumulate operations in parallel
4. **Normalization**: Applies optional absolute value and bit-shift
5. **Clamping**: Ensures output stays within valid range [0, 255]
6. **Output Stream**: Processed pixels output with `valid_out` signal

## Module Descriptions

### conv_top

**Top-level module** integrating all submodules and controlling the convolution pipeline.

**Ports:**

- `clk`, `rstn`: Clock and active-low reset
- `valid_in`, `px_in`: Input pixel stream
- `kernel_wr`, `kernel_addr`, `kernel_data`: Kernel programming interface
- `valid_out`, `px_out`: Output pixel stream

### linebuffer_3x3

**Line buffer implementation** that maintains the sliding 3×3 window across image rows.

**Key Features:**

- Stores two previous rows in internal RAM
- Uses shift registers for current row
- Handles edge cases with zero-padding
- Outputs valid window signals

### mac9

**Multiply-Accumulate Unit** performing the convolution computation.

**Operation:**

```
result = Σ(pixel[i] × kernel[i])  for i = 0 to 8
```

**Features:**

- Parallel multiplication of 9 pixel-coefficient pairs
- Pipelined adder tree for accumulation
- Signed arithmetic for negative kernels

## Parameters

| Parameter | Default | Description                                 |
| --------- | ------- | ------------------------------------------- |
| `PIX_W`   | 8       | Pixel bit width (typically 8 for grayscale) |
| `COEF_W`  | 16      | Coefficient bit width (signed)              |
| `ACC_W`   | 32      | Accumulator bit width                       |
| `IMG_W`   | 128     | Image width in pixels                       |
| `USE_ABS` | 1       | Enable absolute value (1=yes, 0=no)         |
| `SHIFT`   | 0       | Right shift for normalization               |

## Usage Examples

### Example 1: Gaussian Blur (3×3)

```
Kernel:
┌───┬───┬───┐
│ 1 │ 2 │ 1 │
├───┼───┼───┤
│ 2 │ 4 │ 2 │
├───┼───┼───┤
│ 1 │ 2 │ 1 │
└───┴───┴───┘
Total: 16 → Use SHIFT=4
```

**Configuration:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(0),
  .SHIFT(4)
) blur_inst (...);
```

**Kernel Programming:**

```systemverilog
kernel[0] = 1; kernel[1] = 2; kernel[2] = 1;
kernel[3] = 2; kernel[4] = 4; kernel[5] = 2;
kernel[6] = 1; kernel[7] = 2; kernel[8] = 1;
```

**Effect:** Smooths the image by averaging neighboring pixels

### Example 2: Sobel Edge Detection (Horizontal)

```
Kernel:
┌────┬───┬────┐
│ -1 │ 0 │  1 │
├────┼───┼────┤
│ -2 │ 0 │  2 │
├────┼───┼────┤
│ -1 │ 0 │  1 │
└────┴───┴────┘
```

**Configuration:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(1),  // Use absolute value
  .SHIFT(8)
) sobel_x_inst (...);
```

**Kernel Programming:**

```systemverilog
kernel[0] = -1; kernel[1] = 0; kernel[2] = 1;
kernel[3] = -2; kernel[4] = 0; kernel[5] = 2;
kernel[6] = -1; kernel[7] = 0; kernel[8] = 1;
```

**Effect:** Detects vertical edges in the image

### Example 3: Sharpen Filter

```
Kernel:
┌────┬────┬────┐
│  0 │ -1 │  0 │
├────┼────┼────┤
│ -1 │  5 │ -1 │
├────┼────┼────┤
│  0 │ -1 │  0 │
└────┴────┴────┘
```

**Configuration:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(0),
  .SHIFT(0)
) sharpen_inst (...);
```

**Effect:** Enhances edges and details in the image

### Example 4: Laplacian Edge Detection

```
Kernel:
┌────┬───┬────┐
│  0 │ -1 │  0 │
├────┼───┼────┤
│ -1 │  4 │ -1 │
├────┼───┼────┤
│  0 │ -1 │  0 │
└────┴───┴────┘
```

**Configuration:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(1),  // Use absolute value
  .SHIFT(0)
) laplacian_inst (...);
```

**Effect:** Detects edges by highlighting regions of rapid intensity change

## Getting Started

### Prerequisites

- **HDL Simulator**: ModelSim, Vivado Simulator, or Verilator
- **FPGA Tools**: Xilinx Vivado or Intel Quartus (for synthesis)
- **Python**: For image preprocessing (optional)

### Quick Start

1. **Clone the repository**

```bash
git clone https://github.com/ManoelIvisson/convulucao-2d-FPGA-Litex.git
cd convulucao-2d-FPGA-Litex
```

2. **Prepare input image**

```python
# convert_image.py
from PIL import Image
import numpy as np

img = Image.open('input.png').convert('L')
img = img.resize((640, 480))
pixels = np.array(img)

with open('image_in.hex', 'w') as f:
    for pixel in pixels.flatten():
        f.write(f'{pixel:02x}\n')
```

3. **Run simulation**

```bash
# Using ModelSim
vlog conv_top.sv linebuffer_3x3.sv mac9.sv tb_conv.sv
vsim -c tb_conv -do "run -all"

# Using Vivado
vivado -mode batch -source sim_script.tcl
```

4. **View results**

```python
# view_output.py
import numpy as np
from PIL import Image

pixels = []
with open('out_pixels.hex', 'r') as f:
    for line in f:
        pixels.append(int(line.strip(), 16))

img_array = np.array(pixels).reshape(480, 640)
img = Image.fromarray(img_array.astype('uint8'))
img.save('output.png')
img.show()
```

## Scripts and Tools

The repository includes Python scripts for image processing:

- `convert_image.py`: Converts a PNG image to hex format for simulation input
  ```bash
  python convert_image.py input.png image_in.hex
  ```

- `view_output.py`: Converts hex output from simulation to PNG image
  ```bash
  python view_output.py out_pixels.hex output.png
  ```

Install dependencies: `pip install pillow numpy`

## Simulation

### Prerequisites

- **FPGA Tools**: Xilinx Vivado (recommended) or Intel Quartus Prime
- **Target Device**: Any modern FPGA (e.g., Xilinx Artix-7, Kintex-7, or equivalent)

### Steps for Vivado

1. **Create a new project in Vivado**

   - Open Vivado and select "Create Project"
   - Set project name and location
   - Choose "RTL Project" and add the RTL files: `rtl/conv_top.sv`, `rtl/linebuffer_3x3.sv`, `rtl/mac9.sv`

2. **Configure synthesis settings**

   - In Project Settings > Synthesis, set target language to SystemVerilog
   - Add any necessary constraints (e.g., clock constraints in a .xdc file)

3. **Run synthesis and implementation**

   ```bash
   # In Vivado Tcl console or batch mode
   synth_design -top conv_top -part xc7a35tcpg236-1
   opt_design
   place_design
   route_design
   write_bitstream -force conv_top.bit
   ```

4. **Generate reports**

   - Check timing reports for clock frequency
   - Verify resource utilization matches estimates

### For Quartus (Intel FPGA)

1. Create a new project in Quartus Prime
2. Add RTL files and set top-level entity to `conv_top`
3. Configure device family (e.g., Cyclone V)
4. Run compilation and generate .sof file

### Tips

- Monitor timing closure; adjust pipeline if needed
- Use DSP blocks for multipliers to optimize resource usage
- Test on hardware with a simple test pattern before full images

## Performance

### Throughput

- **1 pixel per clock cycle** (after pipeline fill)
- For 100 MHz clock: **100 Megapixels/second**
- 640×480 image @ 100 MHz: **3.2 ms** (312 FPS)

### Latency

- Pipeline latency: **~5-7 clock cycles**
- Initial startup: **2 rows + 2 columns** before first valid output

### Resource Utilization (Typical for Xilinx 7-series)

| Resource | Usage    | Notes                        |
| -------- | -------- | ---------------------------- |
| LUTs     | ~500-800 | Varies with parameters       |
| FFs      | ~300-500 | Pipeline registers           |
| BRAMs    | 2        | Line buffers (for IMG_W=640) |
| DSPs     | 9        | Multipliers (MAC unit)       |

## Applications

### Computer Vision

- **Edge Detection**: Sobel, Prewitt, Laplacian
- **Image Smoothing**: Gaussian blur, average filter
- **Image Sharpening**: Unsharp mask, high-pass filters

### Video Processing

- Real-time video filtering
- Motion detection preprocessing
- Feature extraction

### Machine Learning

- Convolutional layer implementation
- Feature map generation
- CNN acceleration

### Scientific Imaging

- Medical image enhancement
- Microscopy image processing
- Satellite image analysis

## Troubleshooting

### Common Issues

- **Simulation fails with overflow**: Check kernel coefficients and SHIFT parameter. Ensure coefficients sum appropriately for normalization.
- **Timing violations in synthesis**: Reduce clock frequency or add pipeline stages. Monitor critical path in Vivado reports.
- **Incorrect output pixels**: Verify kernel programming order (row-major). Check image dimensions match IMG_W parameter.
- **BRAM usage high**: For larger IMG_W, consider external memory or adjust buffer size.
- **Python scripts fail**: Install dependencies: `pip install pillow numpy`. Ensure input image is grayscale.

### Debugging Tips

- Use waveform viewer to inspect `window_valid` and pixel streams
- Add debug signals for intermediate MAC results
- Test with simple kernels (e.g., identity) first

---

# Documentação em Português

## Visão Geral

Este projeto implementa um **motor de convolução 2D de alto desempenho** projetado para plataformas FPGA. Ele processa imagens em escala de cinza de 8 bits usando kernels de convolução 3×3 configuráveis, ideal para aplicações de processamento de imagem em tempo real, como detecção de bordas, desfoque, nitidez e outras tarefas de visão computacional.

O design usa uma arquitetura de streaming com buffers de linha, permitindo o processamento eficiente de imagens de altura arbitrária com overhead mínimo de memória.

## Características

- ✅ **Kernel de Convolução 3×3**: Coeficientes totalmente configuráveis
- ✅ **Arquitetura de Streaming**: Processa um pixel por ciclo de clock
- ✅ **Design Parametrizável**: Larguras de bits e dimensões de imagem configuráveis
- ✅ **Buffer de Linha**: Uso eficiente de memória para alturas de imagem arbitrárias
- ✅ **Tratamento de Bordas**: Zero-padding para pixels de borda
- ✅ **Valor Absoluto Opcional**: Para magnitude de gradiente (Sobel, etc.)
- ✅ **Normalização Configurável**: Deslocamento de bits programável para escalonamento de saída
- ✅ **Arquitetura Pipeline**: Otimizada para altas frequências de clock
- ✅ **Proteção contra Overflow**: Limitação automática para faixa válida de pixels

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         conv_top                            │
│                                                             │
│  ┌──────────────┐    ┌─────────────┐    ┌──────────────┐  │
│  │ Armazenamento│    │   Buffer    │    │     MAC9     │  │
│  │   de Kernel  │───▶│  de Linha   │───▶│ Multiplica & │  │
│  │  (9 coefs)   │    │   (3x3)     │    │   Acumula    │  │
│  └──────────────┘    └─────────────┘    └──────────────┘  │
│         ▲                   ▲                    │         │
│         │                   │                    ▼         │
│    kernel_wr           valid_in             ┌────────┐    │
│    kernel_addr          px_in               │ Norm & │    │
│    kernel_data                              │ Clamp  │    │
│                                             └────────┘    │
│                                                  │         │
│                                                  ▼         │
│                                            valid_out       │
│                                            px_out          │
└─────────────────────────────────────────────────────────────┘
```

### Fluxo de Dados

1. **Stream de Entrada**: Pixels chegam sequencialmente (esquerda-direita, cima-baixo)
2. **Buffer de Linha**: Mantém uma janela deslizante 3×3 através das linhas
3. **Unidade MAC**: Realiza 9 operações de multiplicação-acumulação em paralelo
4. **Normalização**: Aplica valor absoluto opcional e deslocamento de bits
5. **Limitação**: Garante que a saída permaneça dentro da faixa válida [0, 255]
6. **Stream de Saída**: Pixels processados com sinal `valid_out`

## Descrição dos Módulos

### conv_top

**Módulo de nível superior** integrando todos os submódulos e controlando o pipeline de convolução.

**Portas:**

- `clk`, `rstn`: Clock e reset ativo-baixo
- `valid_in`, `px_in`: Stream de pixels de entrada
- `kernel_wr`, `kernel_addr`, `kernel_data`: Interface de programação do kernel
- `valid_out`, `px_out`: Stream de pixels de saída

### linebuffer_3x3

**Implementação do buffer de linha** que mantém a janela deslizante 3×3 através das linhas da imagem.

**Características Principais:**

- Armazena duas linhas anteriores em RAM interna
- Usa registradores de deslocamento para a linha atual
- Trata casos de borda com zero-padding
- Gera sinais de janela válida

### mac9

**Unidade de Multiplicação-Acumulação** realizando a computação da convolução.

**Operação:**

```
resultado = Σ(pixel[i] × kernel[i])  para i = 0 até 8
```

**Características:**

- Multiplicação paralela de 9 pares pixel-coeficiente
- Árvore de somadores pipelined para acumulação
- Aritmética com sinal para kernels negativos

## Parâmetros

| Parâmetro | Padrão | Descrição                                                     |
| --------- | ------ | ------------------------------------------------------------- |
| `PIX_W`   | 8      | Largura de bits do pixel (tipicamente 8 para escala de cinza) |
| `COEF_W`  | 16     | Largura de bits do coeficiente (com sinal)                    |
| `ACC_W`   | 32     | Largura de bits do acumulador                                 |
| `IMG_W`   | 128    | Largura da imagem em pixels                                   |
| `USE_ABS` | 1      | Habilita valor absoluto (1=sim, 0=não)                        |
| `SHIFT`   | 0      | Deslocamento à direita para normalização                      |

## Exemplos de Uso

### Exemplo 1: Desfoque Gaussiano (3×3)

```
Kernel:
┌───┬───┬───┐
│ 1 │ 2 │ 1 │
├───┼───┼───┤
│ 2 │ 4 │ 2 │
├───┼───┼───┤
│ 1 │ 2 │ 1 │
└───┴───┴───┘
Total: 16 → Use SHIFT=4
```

**Configuração:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(0),
  .SHIFT(4)
) blur_inst (...);
```

**Programação do Kernel:**

```systemverilog
kernel[0] = 1; kernel[1] = 2; kernel[2] = 1;
kernel[3] = 2; kernel[4] = 4; kernel[5] = 2;
kernel[6] = 1; kernel[7] = 2; kernel[8] = 1;
```

**Efeito:** Suaviza a imagem fazendo média dos pixels vizinhos

### Exemplo 2: Detecção de Bordas Sobel (Horizontal)

```
Kernel:
┌────┬───┬────┐
│ -1 │ 0 │  1 │
├────┼───┼────┤
│ -2 │ 0 │  2 │
├────┼───┼────┤
│ -1 │ 0 │  1 │
└────┴───┴────┘
```

**Configuração:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(1),  // Usa valor absoluto
  .SHIFT(8)
) sobel_x_inst (...);
```

**Programação do Kernel:**

```systemverilog
kernel[0] = -1; kernel[1] = 0; kernel[2] = 1;
kernel[3] = -2; kernel[4] = 0; kernel[5] = 2;
kernel[6] = -1; kernel[7] = 0; kernel[8] = 1;
```

**Efeito:** Detecta bordas verticais na imagem

### Exemplo 3: Filtro de Nitidez

```
Kernel:
┌────┬────┬────┐
│  0 │ -1 │  0 │
├────┼────┼────┤
│ -1 │  5 │ -1 │
├────┼────┼────┤
│  0 │ -1 │  0 │
└────┴────┴────┘
```

**Configuração:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(0),
  .SHIFT(0)
) sharpen_inst (...);
```

**Efeito:** Realça bordas e detalhes na imagem

### Exemplo 4: Detecção de Bordas Laplaciano

```
Kernel:
┌────┬───┬────┐
│  0 │ -1 │  0 │
├────┼───┼────┤
│ -1 │  4 │ -1 │
├────┼───┼────┤
│  0 │ -1 │  0 │
└────┴───┴────┘
```

**Configuração:**

```systemverilog
conv_top #(
  .PIX_W(8),
  .IMG_W(640),
  .USE_ABS(1),  // Usa valor absoluto
  .SHIFT(0)
) laplacian_inst (...);
```

**Efeito:** Detecta bordas destacando regiões de mudança rápida de intensidade

## Como Começar

### Pré-requisitos

- **Simulador HDL**: ModelSim, Vivado Simulator ou Verilator
- **Ferramentas FPGA**: Xilinx Vivado ou Intel Quartus (para síntese)
- **Python**: Para pré-processamento de imagem (opcional)

### Início Rápido

1. **Clone o repositório**

```bash
git clone https://github.com/ManoelIvisson/convulucao-2d-FPGA-Litex.git
cd convulucao-2d-FPGA-Litex
```

2. **Prepare a imagem de entrada**

```python
# convert_image.py
from PIL import Image
import numpy as np

img = Image.open('entrada.png').convert('L')
img = img.resize((640, 480))
pixels = np.array(img)

with open('image_in.hex', 'w') as f:
    for pixel in pixels.flatten():
        f.write(f'{pixel:02x}\n')
```

3. **Execute a simulação**

```bash
# Usando ModelSim
vlog conv_top.sv linebuffer_3x3.sv mac9.sv tb_conv.sv
vsim -c tb_conv -do "run -all"

# Usando Vivado
vivado -mode batch -source sim_script.tcl
```

4. **Visualize os resultados**

```python
# view_output.py
import numpy as np
from PIL import Image

pixels = []
with open('out_pixels.hex', 'r') as f:
    for line in f:
        pixels.append(int(line.strip(), 16))

img_array = np.array(pixels).reshape(480, 640)
img = Image.fromarray(img_array.astype('uint8'))
img.save('saida.png')
img.show()
```

## Scripts e Ferramentas

O repositório inclui scripts Python para processamento de imagem:

- `convert_image.py`: Converte uma imagem PNG para formato hex para entrada de simulação
  ```bash
  python convert_image.py entrada.png image_in.hex
  ```

- `view_output.py`: Converte saída hex da simulação para imagem PNG
  ```bash
  python view_output.py out_pixels.hex saida.png
  ```

Instale dependências: `pip install pillow numpy`

## Simulação

### Pré-requisitos

- **Ferramentas FPGA**: Xilinx Vivado (recomendado) ou Intel Quartus Prime
- **Dispositivo Alvo**: Qualquer FPGA moderno (ex.: Xilinx Artix-7, Kintex-7 ou equivalente)

### Passos para Vivado

1. **Crie um novo projeto no Vivado**

   - Abra o Vivado e selecione "Create Project"
   - Defina nome e localização do projeto
   - Escolha "RTL Project" e adicione os arquivos RTL: `rtl/conv_top.sv`, `rtl/linebuffer_3x3.sv`, `rtl/mac9.sv`

2. **Configure as configurações de síntese**

   - Em Project Settings > Synthesis, defina a linguagem alvo como SystemVerilog
   - Adicione constraints necessários (ex.: constraints de clock em um arquivo .xdc)

3. **Execute síntese e implementação**

   ```bash
   # No console Tcl do Vivado ou modo batch
   synth_design -top conv_top -part xc7a35tcpg236-1
   opt_design
   place_design
   route_design
   write_bitstream -force conv_top.bit
   ```

4. **Gere relatórios**

   - Verifique relatórios de timing para frequência de clock
   - Confirme utilização de recursos com as estimativas

### Para Quartus (Intel FPGA)

1. Crie um novo projeto no Quartus Prime
2. Adicione arquivos RTL e defina entidade de nível superior como `conv_top`
3. Configure família de dispositivo (ex.: Cyclone V)
4. Execute compilação e gere arquivo .sof

### Dicas

- Monitore fechamento de timing; ajuste pipeline se necessário
- Use blocos DSP para multiplicadores para otimizar uso de recursos
- Teste em hardware com um padrão simples antes de imagens completas

## Desempenho

### Taxa de Processamento

- **1 pixel por ciclo de clock** (após preenchimento do pipeline)
- Para clock de 100 MHz: **100 Megapixels/segundo**
- Imagem 640×480 @ 100 MHz: **3,2 ms** (312 FPS)

### Latência

- Latência do pipeline: **~5-7 ciclos de clock**
- Inicialização: **2 linhas + 2 colunas** antes da primeira saída válida

### Utilização de Recursos (Típico para Xilinx série-7)

| Recurso | Uso      | Notas                             |
| ------- | -------- | --------------------------------- |
| LUTs    | ~500-800 | Varia com parâmetros              |
| FFs     | ~300-500 | Registradores de pipeline         |
| BRAMs   | 2        | Buffers de linha (para IMG_W=640) |
| DSPs    | 9        | Multiplicadores (unidade MAC)     |

## Aplicações

### Visão Computacional

- **Detecção de Bordas**: Sobel, Prewitt, Laplaciano
- **Suavização de Imagem**: Desfoque gaussiano, filtro de média
- **Nitidez de Imagem**: Máscara de nitidez, filtros passa-alta

### Processamento de Vídeo

- Filtragem de vídeo em tempo real
- Pré-processamento para detecção de movimento
- Extração de características

### Aprendizado de Máquina

- Implementação de camada convolucional
- Geração de mapas de características
- Aceleração de CNN

### Imagem Científica

- Realce de imagem médica
- Processamento de imagem de microscopia
- Análise de imagem de satélite

## Solução de Problemas

### Problemas Comuns

- **Simulação falha com overflow**: Verifique coeficientes do kernel e parâmetro SHIFT. Garanta que coeficientes somem adequadamente para normalização.
- **Violações de timing na síntese**: Reduza frequência de clock ou adicione estágios de pipeline. Monitore caminho crítico em relatórios do Vivado.
- **Pixels de saída incorretos**: Verifique ordem de programação do kernel (linha-principal). Confirme dimensões da imagem correspondem ao parâmetro IMG_W.
- **Uso alto de BRAM**: Para IMG_W maior, considere memória externa ou ajuste tamanho do buffer.
- **Scripts Python falham**: Instale dependências: `pip install pillow numpy`. Garanta que imagem de entrada seja em escala de cinza.

### Dicas de Depuração

- Use visualizador de formas de onda para inspecionar `window_valid` e streams de pixels
- Adicione sinais de debug para resultados intermediários do MAC
- Teste com kernels simples (ex.: identidade) primeiro

---

## 📁 Project Structure

```
convulucao-2d-FPGA-Litex/
├── rtl/
│   ├── conv_top.sv          # Top-level module
│   ├── linebuffer_3x3.sv    # Line buffer implementation
│   └── mac9.sv              # MAC unit
├── testbench/
│   └── tb_conv.sv           # Testbench
├── convert_image.py         # Image to hex converter
├── view_output.py           # Output visualizer
└── README.md                # This file
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

For questions or suggestions, please open an issue on GitHub.

## 🙏 Acknowledgments

- Inspired by classical image processing techniques
- Optimized for FPGA implementation efficiency
- Community feedback and contributions

---

**Note**: This is a hardware description, not software. Synthesis and implementation results will vary based on target FPGA device and tool settings.
