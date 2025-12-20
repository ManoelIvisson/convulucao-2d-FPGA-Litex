#include <stdint.h>
#include <generated/csr.h>

/* ========================================================= */
/* UART helpers                                              */
/* ========================================================= */

static void uart_putc(char c) {
    while (uart_txfull_read());
    uart_rxtx_write(c);
}

static void uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

static void uart_puthex(uint8_t v) {
    const char hex[] = "0123456789ABCDEF";
    uart_putc(hex[(v >> 4) & 0xF]);
    uart_putc(hex[v & 0xF]);
}

/* ========================================================= */
/* Main                                                      */
/* ========================================================= */

int main(void) {
    uart_ev_pending_write(uart_ev_pending_read());

    uart_puts("\nFirmware ativo\n");
    uart_puts("Recebendo bytes (HEX):\n");

    while (1) {
        if (!uart_rxempty_read()) {
            uint8_t px = uart_rxtx_read();

            /* envia ao hardware */
            main_csr_pixel_re_write(px);

            /* ecoa no terminal */
            uart_puthex(px);
            uart_putc(' ');
        }
    }
}
