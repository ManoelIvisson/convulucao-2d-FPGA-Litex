OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* * DEFINIÇÃO DE MEMÓRIA MANUAL
 * Baseada no padrão do VexRiscv/LiteX sem SDRAM externa.
 * Origem: 0x10000000 (SRAM Interna do FPGA)
 * Tamanho: 16KB (0x4000) - Conforme configuramos no build_soc.py
 */
MEMORY {
    sram (rwx) : ORIGIN = 0x10000000, LENGTH = 0x4000
}

SECTIONS
{
    /* Código (Text) */
    .text : {
        _start = .;
        *(.text .text.*)
    } > sram

    /* Dados Somente Leitura (Strings, Constantes) */
    .rodata : {
        . = ALIGN(4);
        *(.rodata .rodata.*)
    } > sram

    /* Dados Inicializados */
    .data : {
        . = ALIGN(4);
        *(.data .data.*)
    } > sram

    /* Dados Não Inicializados (Zeroed) */
    .bss : {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss .bss.*)
        . = ALIGN(4);
        _bss_end = .;
    } > sram

    /* Pilha (Stack) - Colocada no final da SRAM */
    .stack : {
        . = ALIGN(4);
        _stack_start = ORIGIN(sram) + LENGTH(sram);
    } > sram
}