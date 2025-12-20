#include <stdint.h>
#include <generated/csr.h>

static void uart_putc(char c) {
    uart_rxtx_write(c);
}

static void uart_puts(const char *s) {
    while (*s)
        uart_putc(*s++);
}

static void uart_puthex8(uint8_t v) {
    const char hex[] = "0123456789ABCDEF";
    uart_putc(hex[v >> 4]);
    uart_putc(hex[v & 0xF]);
    uart_putc(' ');
}

int main(void) {
    uart_puts("Esperando bytes UART...\n");

    while (1) {
        if (!uart_rxempty_read()) {

            uint8_t px = uart_rxtx_read();

            // eco controlado (1 print por byte)
            uart_puthex8(px);

            // envia para o hardware
            main_csr_pixel_re_write(px);
        }
    }
}
