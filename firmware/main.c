#include <stdint.h>
#include <generated/csr.h>

/* ========================================================= */
/* UART helpers (printf bare-metal)                          */
/* ========================================================= */

static void uart_putc(char c) {
    /* espera TX ter espaço */
    while (uart_txfull_read());
    uart_rxtx_write(c);
}

static void uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');  // terminal friendly
        uart_putc(*s++);
    }
}

int main(void) {
    /* limpa eventos pendentes da UART */
    uart_ev_pending_write(uart_ev_pending_read());

    /* mensagem inicial */
    uart_puts("\n==============================\n");
    uart_puts(" Firmware LiteX iniciado\n");
    uart_puts(" Aguardando imagem pela UART...\n");
    uart_puts("==============================\n");

    while (1) {
        if (!uart_rxempty_read()) {

            uint8_t px = uart_rxtx_read();

            // envia para o hardware
            main_csr_pixel_re_write(px);
        }
    }
}
