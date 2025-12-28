#include <generated/csr.h>
#include <stdint.h>

// --- Funções Auxiliares de UART (Polling Puro) ---
// Substituem a necessidade de <uart.h> e <irq.h>

void uart_write_byte(uint8_t c) {
    // Aguarda o buffer de TX não estar cheio
    while(uart_txfull_read());
    // Escreve o char
    uart_rxtx_write(c);
}

uint8_t uart_read_byte(void) {
    // Aguarda ter dado no buffer de RX (polling)
    // rxempty_read retorna 1 se vazio
    while(uart_rxempty_read());
    // Lê o char
    uint8_t c = uart_rxtx_read();
    
    // Limpa o evento de RX (necessário em alguns cores do LiteX)
    uart_ev_pending_write(uart_ev_pending_read());
    return c;
}

// --- Funções do Acelerador ---

void load_kernel(void) {
    // Coeficientes Sobel
    const int16_t sob_k[9] = {
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    };

    for(int i=0; i<9; i++) {
        conv_kernel_addr_write(i);
        conv_kernel_data_write(sob_k[i] & 0xFFFF);
        
        // Pulso de escrita
        conv_control_write(1); 
    }
}

void process_image(void) {
    // 64x64 = 4096 pixels
    int total_pixels = 4096;
    int sent = 0;
    int received = 0;
    
    while(received < total_pixels) {
        
        // 1. Enviar (Se houver espaço na FIFO de entrada e dados na UART)
        if (sent < total_pixels) {
            // Se FIFO In não cheia (Bit 0 de status)
            if ((conv_status_read() & 1) == 0) {
                // Verifica se tem char na UART sem bloquear (peek)
                if (uart_rxempty_read() == 0) {
                    uint8_t pix = uart_read_byte();
                    conv_pixel_in_write(pix);
                    sent++;
                }
            }
        }
        
        // 2. Receber (Se FIFO Out não vazia)
        // Se FIFO Out não vazia (Bit 1 de status)
        if ((conv_status_read() & 2) == 0) {
            uint8_t out_pix = conv_pixel_out_read();
            uart_write_byte(out_pix);
            received++;
        }
    }
}

// --- Main ---

int main(void) {
    // Não precisamos de irq_init() pois estamos usando polling
    
    // Teste simples de vida
    uart_write_byte('O');
    uart_write_byte('K');
    uart_write_byte('\n');

    load_kernel();
    
    while(1) {
        process_image();
    }
    return 0;
}