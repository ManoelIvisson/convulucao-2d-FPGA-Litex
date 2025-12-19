import numpy as np
import matplotlib.pyplot as plt

H, W = 960, 640

# carregar entrada
data_in = [int(x.strip(),16) for x in open("image_in.hex")]
img_in = np.array(data_in, dtype=np.uint8).reshape((H, W))

# carregar saída
data_out = [int(x.strip(),16) for x in open("out_pixels.hex")]
img_out = np.array(data_out, dtype=np.int16).reshape((H-2, W-2))

plt.figure(figsize=(12,6))

plt.subplot(1,2,1)
plt.imshow(img_in, cmap='gray')
plt.title("Entrada (960 × 640)")
plt.axis("off")

plt.subplot(1,2,2)
plt.imshow(np.abs(img_out), cmap='gray')
plt.title("Saída convoluída (958 × 638)")
plt.axis("off")

plt.tight_layout()
plt.savefig("imagem_convuluida_sobel.png")
plt.show()
