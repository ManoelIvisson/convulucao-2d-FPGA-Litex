import serial
import time
import sys
import os

# CONFIGURAÇÕES
SERIAL_PORT = '/dev/ttyACM0'
BAUD_RATE   = 115200
IMG_WIDTH   = 128
IMG_HEIGHT  = 128
TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT

# Caminhos dos arquivos
INPUT_FILE  = "image_raw.hex"
OUTPUT_FILE = "image_out.raw"

def main():
    print(f"--- FPGA Convolution Host Interface ---")
    print(f"Target: {IMG_WIDTH}x{IMG_HEIGHT} image ({TOTAL_PIXELS} bytes)")
    
    # 1. Abrir Porta Serial
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
        print(f"[+] Serial opened on {SERIAL_PORT} @ {BAUD_RATE}")
    except serial.SerialException as e:
        print(f"[!] Error opening serial: {e}")
        sys.exit(1)

    # 2. Ler Arquivo de Entrada
    try:
        with open(INPUT_FILE, "rb") as f:
            img_data = f.read()
            
        if len(img_data) != TOTAL_PIXELS:
            print(f"[!] Warning: Input file size ({len(img_data)}) does not match expected ({TOTAL_PIXELS}).")
    except FileNotFoundError:
        print(f"[!] Input file '{INPUT_FILE}' not found.")
        sys.exit(1)

    print("[*] Starting transmission/reception loop...")
    
    output_data = bytearray()
    start_time = time.time()

    # Limpar buffers antigos
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    # 3. Loop de Envio/Recebimento (Síncrono)
    for i in range(len(img_data)):
        byte_to_send = img_data[i:i+1]
        
        # Envia
        ser.write(byte_to_send)
        
        # Recebe
        response = ser.read(1)
        
        if len(response) == 0:
            print(f"\n[!] Timeout processing pixel {i}. FPGA stopped responding.")
            break
            
        output_data.extend(response)
        
        # Barra de progresso
        if i % 1024 == 0:
            sys.stdout.write(f"\rProgress: {i}/{TOTAL_PIXELS} ({(i/TOTAL_PIXELS)*100:.1f}%)")
            sys.stdout.flush()

    elapsed = time.time() - start_time
    print(f"\n[+] Processing finished in {elapsed:.2f} seconds.")
    print(f"    Speed: {len(output_data)/elapsed:.2f} bytes/sec")

    # 4. Salvar Resultado
    with open(OUTPUT_FILE, "wb") as f:
        f.write(output_data)
        
    print(f"[+] Output saved to '{OUTPUT_FILE}'")
    ser.close()

if __name__ == "__main__":
    main()