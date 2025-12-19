from PIL import Image
import numpy as np
import matplotlib.pyplot as plt

# carregar imagem do disco
img = Image.open("porta.jpg").convert("L")
arr = np.array(img, dtype=np.uint8)

H, W = 960, 640

# salvar como valores hex
with open("image_in.hex", "w") as f:
    for y in range(H):
        for x in range(W):
            f.write(f"{arr[y, x]:02x}\n")

print("Arquivo image_in.hex gerado!")

# refazer pra ver se a imagem continua a mesma
data_in = [int(x.strip(),16) for x in open("image_in.hex")]
img_in = np.array(data_in, dtype=np.uint8).reshape((H, W))

plt.figure(figsize=(10,4))

plt.subplot(1,2,1)
plt.imshow(img_in, cmap='gray')
plt.title("Entrada (171 × 256)")
plt.axis("off")
