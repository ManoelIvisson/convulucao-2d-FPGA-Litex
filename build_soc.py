#!/usr/bin/env python3

from migen import *
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.interconnect.csr import *

# Importações de Hardware
from litex_boards.platforms import colorlight_i5

# Tenta importar o CRG padrão, fallback genérico se falhar
try:
    from litex_boards.targets.colorlight_i5 import _CRG
except ImportError:
    from litex.soc.cores.clock import *
    class _CRG(Module):
        def __init__(self, platform, sys_clk_freq):
            self.rst = Signal()
            self.clock_domains.cd_sys = ClockDomain()
            self.submodules.pll = pll = ECP5PLL()
            self.comb += pll.reset.eq(self.rst)
            pll.register_clkin(platform.request("clk25"), 25e6)
            pll.create_clkout(self.cd_sys, sys_clk_freq)

# ------------------------------------------------------------------------------------------
# 1. Wrapper do Acelerador (Hardware Customizado)
# ------------------------------------------------------------------------------------------
class ConvolutionSoC(Module, AutoCSR):
    def __init__(self, platform):
        # --- CSRs de Controle ---
        self.control = CSRStorage(fields=[
            CSRField("kernel_wr", size=1, pulse=True),
            CSRField("reserved", size=7)
        ])
        
        self.kernel_addr = CSRStorage(4)
        self.kernel_data = CSRStorage(16)
        
        # --- CSRs de Dados (Streaming) ---
        self.pixel_in = CSRStorage(8) 
        self.pixel_out = CSRStatus(8)
        self.status = CSRStatus(2)
        
        # Instância Verilog
        self.specials += Instance("conv_soc_wrapper",
            # Parâmetros
            p_PIX_W=8, p_COEF_W=16, p_ACC_W=32, p_IMG_W=64,
            
            # Clock e Reset
            i_sys_clk = ClockSignal(),
            i_sys_rst = ResetSignal(),
            
            # Interface Kernel
            i_csr_kernel_wr   = self.control.fields.kernel_wr,
            i_csr_kernel_addr = self.kernel_addr.storage,
            i_csr_kernel_data = self.kernel_data.storage,
            
            # Interface Pixel In (CPU -> FPGA)
            i_csr_pix_wr      = self.pixel_in.re,      
            i_csr_pix_data_in = self.pixel_in.storage, 
            
            # Interface Pixel Out (FPGA -> CPU)
            i_csr_pix_rd       = self.pixel_out.we,     
            o_csr_pix_data_out = self.pixel_out.status, 
            
            # Status
            o_status_in_full   = self.status.status[0],
            o_status_out_empty = self.status.status[1]
        )
        
        # Fontes Verilog
        platform.add_source("./rtl/conv_top.sv")
        platform.add_source("./rtl/linebuffer_3x3.sv")
        platform.add_source("./rtl/mac9.sv")
        platform.add_source("conv_soc_wrapper.sv")

# ------------------------------------------------------------------------------------------
# 2. Definição do SoC (System on Chip)
# ------------------------------------------------------------------------------------------
class BaseSoC(SoCCore):
    def __init__(self, sys_clk_freq=int(25e6), **kwargs):
        # A. Configurar Plataforma Colorlight i9 (Baseada na i5 v7.0)
        platform = colorlight_i5.Platform(revision="7.0")
        
        # CORREÇÃO: String completa do dispositivo para o parser do Trellis/Nextpnr
        # LFE5U = ECP5
        # 45F   = 45k LUTs
        # 6     = Speed Grade 6
        # BG381 = Pacote Ball Grid Array 381 pinos
        # C     = Commercial Grade
        platform.device = "LFE5U-45F-6BG381C"
        
        # B. Inicializar SoCCore com Memórias Internas
        SoCCore.__init__(self, platform, clk_freq=sys_clk_freq,
                         ident="LiteX SoC - Colorlight i9 Custom", ident_version=True,
                         integrated_rom_size=0x8000,  
                         integrated_sram_size=0x4000, 
                         **kwargs)
        
        # C. Clock Reset Generator
        self.submodules.crg = _CRG(platform, sys_clk_freq)
        
        # D. Adicionar Acelerador
        self.submodules.conv = ConvolutionSoC(platform)

# ------------------------------------------------------------------------------------------
# 3. Build Script
# ------------------------------------------------------------------------------------------
def main():
    soc = BaseSoC(toolchain="trellis")
    builder = Builder(soc, output_dir="build", csr_csv="csr.csv")
    builder.build(build_name="colorlight_i9")

if __name__ == "__main__":
    main()