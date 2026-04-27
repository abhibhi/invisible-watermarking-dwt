import cv2
import pywt
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# load image
image_path = Path(__file__).resolve().parent.parent / "data" / "original" / "image.jpg"
img = cv2.imread(str(image_path), 0)

# apply 2D DWT (Daubechies)
coeffs = pywt.dwt2(img, 'db4')
LL, (LH, HL, HH) = coeffs

# reconstruct image
reconstructed = pywt.idwt2(coeffs, 'db4')

plt.imshow(reconstructed, cmap='gray')
plt.title("Reconstructed Image")
plt.show()
