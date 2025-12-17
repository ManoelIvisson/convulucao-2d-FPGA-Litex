# view_output.py
# Script to convert hex output from simulation back to image

import numpy as np
from PIL import Image
import sys

if len(sys.argv) != 3:
    print("Usage: python view_output.py <input.hex> <output.png>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

try:
    pixels = []
    with open(input_file, 'r') as f:
        for line in f:
            pixels.append(int(line.strip(), 16))

    img_array = np.array(pixels).reshape(480, 640)
    img = Image.fromarray(img_array.astype('uint8'))
    img.save(output_file)
    print(f"Output saved to {output_file}")

except Exception as e:
    print(f"Error: {e}")