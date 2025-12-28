import serial
import time
import sys

# --- CONFIGURAÇÃO ---
# No Windows: 'COM3', 'COM4', etc. 
# No Linux: '/dev/ttyACM0' ou '/dev/ttyUSB0'
SERIAL_PORT = '/dev/ttyACM0'  # <--- EDITE AQUI
BAUD_RATE = 115200

def main():
    print(f"Conectando em {SERIAL_PORT} a {BAUD_RATE} baud...")
    
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
    except serial.SerialException as e:
        print(f"ERRO: Não foi possível abrir a porta {SERIAL_PORT}.")
        print("Verifique se o cabo está conectado e se o nome da porta está correto.")
        print(f"Detalhes: {e}")
        return

    # Limpar buffers para remover o "OK" do boot ou lixo anterior
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(0.1)

    # 1. Carregar Input
    try:
        print("Lendo input.hex...")
        with open("input.hex", "r") as f:
            # Converte hex string "FF\n" para int
            input_data = [int(line.strip(), 16) for line in f]
    except FileNotFoundError:
        print("ERRO: input.hex não encontrado. Rode convert_image.py primeiro.")
        return

    total_pixels = len(input_data)
    print(f"Imagem carregada: {total_pixels} pixels.")
    print("Iniciando transmissão síncrona (Stop-and-Wait)...")
    
    output_data = []
    start_time = time.time()

    # 2. Loop de Transmissão Sincronizada
    for i, pixel in enumerate(input_data):
        # Envia 1 Byte
        ser.write(bytes([pixel]))
        
        # Espera 1 Byte de resposta
        response = ser.read(1)
        
        if len(response) == 0:
            print(f"\nERRO: Timeout no pixel {i}! O FPGA parou de responder.")
            break
            
        output_data.append(response[0])
        
        # Barra de progresso simples
        if i % 64 == 0:
            percent = (i / total_pixels) * 100
            sys.stdout.write(f"\rProgresso: {percent:.1f}% [{i}/{total_pixels}]")
            sys.stdout.flush()

    print(f"\n\nConcluído em {time.time() - start_time:.2f} segundos.")

    # 3. Salvar Output
    if len(output_data) == total_pixels:
        print("Salvando output.hex...")
        with open("output.hex", "w") as f:
            for val in output_data:
                f.write(f"{val:02x}\n")
        print("Sucesso! Agora rode: python view_output.py")
    else:
        print("FALHA: Arquivo incompleto. Verifique o firmware.")

if __name__ == "__main__":
    main()