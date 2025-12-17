# convert_image.py
# Script to convert a grayscale image to hex format for simulation

from PIL import Image
import numpy as np
import sys

if len(sys.argv) != 3:
    print("Usage: python convert_image.py <input_image.png> <output.hex>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

try:
    img = Image.open(input_file).convert('L')  # Convert to grayscale
    img = img.resize((640, 480))  # Resize to default dimensions
    pixels = np.array(img)

    with open(output_file, 'w') as f:
        for pixel in pixels.flatten():
            f.write(f'{pixel:02x}\n')

    print(f"Image converted to {output_file}")

except Exception as e:
    print(f"Error: {e}")