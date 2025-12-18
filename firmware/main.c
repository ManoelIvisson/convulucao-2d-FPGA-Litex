#include <stdio.h>
#include <uart.h>
#include <generated/csr.h>

int main(void) {
    printf("Esperando por imagem...\n");

    while (1) {
        if (uart_rx_ready()) {
            uint8_t px = uart_rx_read();

            csr_pixel_write(px);   // escreve no hardware
        }
    }
}
