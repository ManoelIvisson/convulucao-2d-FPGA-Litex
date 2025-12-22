from PIL import Image
import sys

def convert_to_raw(input_path, output_path):
    # Abre a imagem
    img = Image.open(input_path)
    
    # FORÇA A CONVERSÃO PARA ESCALA DE CINZA (8-bit)
    img = img.convert('L') 
    
    # Redimensiona se necessário (Bicubic para melhor qualidade)
    img = img.resize((128, 128), Image.BICUBIC)
    
    # Obtém os bytes crus
    raw_data = img.tobytes()
    
    # Salva
    with open(output_path, 'wb') as f:
        f.write(raw_data)
        
    print(f"Convertido: {len(raw_data)} bytes salvos em {output_path}")

# Uso: python3 convert_image.py entrada.jpg image_raw.hex
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python convert_image.py <input> <output>")
    else:
        convert_to_raw(sys.argv[1], sys.argv[2])