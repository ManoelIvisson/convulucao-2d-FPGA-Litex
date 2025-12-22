#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

#define IMG_WIDTH  128
#define IMG_HEIGHT 128
#define TOTAL_PIXELS (IMG_WIDTH * IMG_HEIGHT)

static void process_image(void) {
    uint8_t input_pixel;
    uint8_t output_pixel;
    int i;
    
    printf("Ready to receive RAW image (%d bytes)...\n", TOTAL_PIXELS);

    for (i = 0; i < TOTAL_PIXELS; i++) {
        // 1. Ler byte da UART (bloqueante)
        input_pixel = uart_read();

        // 2. Escrever no módulo de Convolução
        conv_core_pixel_in_write(input_pixel);
        
        // 3. Pulsar o sinal de validade (High -> Low)
        conv_core_valid_in_write(1);
        
        // Pequeno delay
        conv_core_valid_in_write(0); 

        // 4. Aguardar o hardware sinalizar dado válido na saída
        
        while(conv_core_valid_out_read() == 0) {
            // Busy wait até o hardware processar
        }

        // 5. Ler o resultado
        output_pixel = conv_core_pixel_out_read();

        // 6. Enviar de volta pela UART
        uart_write(output_pixel);
    }
    
    printf("\nProcessing Complete.\n");
}

int main(void) {
    irq_setmask(0);
    irq_setie(1);
    uart_init();

    printf("\n--- FPGA Convolution Accelerator ---\n");
    printf("Board: Colorlight i9 - ECP5\n");

    while (1) {
        process_image();
    }

    return 0;
}