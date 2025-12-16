from litex.gen import *
from litex.soc.interconnect.csr import *

class ConvCSR(LiteXModule):
    def __init__(self):
        # CSR visíveis ao CPU
        self.pixel = CSRStatus(8, description="Pixel processado")
        self.valid = CSRStatus(1, description="Pixel válido")
        self.count = CSRStatus(32, description="Total de pixels lidos")

        # sinais vindos do FIFO (hardware)
        self.fifo_dout  = Signal(8)
        self.fifo_empty = Signal()
        self.fifo_rd_en = Signal()

        # ===============================
        # Lógica
        # ===============================
        self.sync += [
            # Quando CPU lê pixel
            If(self.pixel.we,
                If(~self.fifo_empty,
                    self.pixel.status.eq(self.fifo_dout),
                    self.valid.status.eq(1),
                    self.count.status.eq(self.count.status + 1),
                    self.fifo_rd_en.eq(1)
                ).Else(
                    self.valid.status.eq(0),
                    self.fifo_rd_en.eq(0)
                )
            ).Else(
                self.fifo_rd_en.eq(0)
            )
        ]
