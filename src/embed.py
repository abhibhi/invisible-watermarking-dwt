import cv2
import pywt
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path


def calculate_mse(original, modified):
    original = original.astype(np.float64)
    modified = modified.astype(np.float64)
    return np.mean((original - modified) ** 2)


def calculate_psnr(original, modified):
    mse = calculate_mse(original, modified)

    if mse == 0:
        return float("inf")

    return 10 * np.log10((255 ** 2) / mse)


# set up paths
base_dir = Path(__file__).resolve().parent.parent

image_path = base_dir / "data" / "original" / "image.jpg"
output_dir = base_dir / "data" / "watermarked"
watermark_path = base_dir / "data" / "original" / "watermark.png"
output_dir.mkdir(parents=True, exist_ok=True)

output_path = output_dir / "watermarked_image.png"

# load original image
img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)

if img is None:
    raise FileNotFoundError(f"Could not load image at: {image_path}")

# apply 2D DWT using Daubechies wavelet
coeffs = pywt.dwt2(img, "db4")
LL, (LH, HL, HH) = coeffs

# load a binary watermark image resized to the LH subband
watermark = cv2.imread(str(watermark_path), cv2.IMREAD_GRAYSCALE)
if watermark is None:
    raise FileNotFoundError(f"Could not load watermark at: {watermark_path}")

watermark = cv2.resize(
    watermark, (LH.shape[1], LH.shape[0]), interpolation=cv2.INTER_AREA
)
_, watermark = cv2.threshold(watermark, 127, 1, cv2.THRESH_BINARY)
watermark = watermark.astype(np.float64)

# embed watermark into LH subband
alpha = 1
LH_watermarked = LH + alpha * watermark

# reconstruct watermarked image
coeffs_watermarked = (LL, (LH_watermarked, HL, HH))
watermarked_img = pywt.idwt2(coeffs_watermarked, "db4")

# clip values to valid image range
watermarked_img = np.clip(watermarked_img, 0, 255).astype(np.uint8)

# save output image
cv2.imwrite(str(output_path), watermarked_img)

# calculate quality metrics
mse = calculate_mse(img, watermarked_img)
psnr = calculate_psnr(img, watermarked_img)

print("Watermarked image saved to:", output_path)
print("Watermark image used:", watermark_path)
print("MSE:", mse)
print("PSNR:", psnr, "dB")

# Display original and watermarked image in one window.
fig, axes = plt.subplots(1, 3, figsize=(14, 4))
axes[0].imshow(img, cmap="gray", vmin=0, vmax=255)
axes[0].set_title("Original Image")
axes[0].axis("off")

axes[1].imshow(watermarked_img, cmap="gray", vmin=0, vmax=255)
axes[1].set_title("Watermarked Image")
axes[1].axis("off")

axes[2].imshow(watermark, cmap="gray", vmin=0, vmax=1)
axes[2].set_title("Binary Watermark")
axes[2].axis("off")

plt.tight_layout()
plt.show()
