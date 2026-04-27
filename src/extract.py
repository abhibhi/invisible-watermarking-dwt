import cv2
import pywt
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path


def normalize_for_display(arr):
    arr = arr.astype(np.float64)
    arr = arr - np.min(arr)

    if np.max(arr) != 0:
        arr = arr / np.max(arr)

    return arr


def load_watermark_for_comparison(watermark_path, target_shape):
    watermark = cv2.imread(str(watermark_path), cv2.IMREAD_GRAYSCALE)

    if watermark is None:
        raise FileNotFoundError(f"Could not load watermark at: {watermark_path}")

    target_height, target_width = target_shape
    watermark = cv2.resize(
        watermark, (target_width, target_height), interpolation=cv2.INTER_AREA
    )
    _, watermark = cv2.threshold(watermark, 127, 1, cv2.THRESH_BINARY)
    return watermark.astype(np.float64)


def correlation(original, extracted):
    original = original.flatten()
    extracted = extracted.flatten()

    return np.corrcoef(original, extracted)[0, 1]

base_dir = Path(__file__).resolve().parent.parent

original_path = base_dir / "data" / "original" / "image.jpg"
watermarked_path = base_dir / "data" / "watermarked" / "watermarked_image.png"
watermark_path = base_dir / "data" / "original" / "watermark.png"
output_dir = base_dir / "results" / "images"
output_dir.mkdir(parents=True, exist_ok=True)

extracted_path = output_dir / "extracted_watermark.png"

alpha = 0.05

original = cv2.imread(str(original_path), cv2.IMREAD_GRAYSCALE)
watermarked = cv2.imread(str(watermarked_path), cv2.IMREAD_GRAYSCALE)

if original is None:
    raise FileNotFoundError(f"Could not load original image at: {original_path}")

if watermarked is None:
    raise FileNotFoundError(f"Could not load watermarked image at: {watermarked_path}")

# DWT of original and watermarked images
coeffs_original = pywt.dwt2(original, "db4")
LL_o, (LH_o, HL_o, HH_o) = coeffs_original

coeffs_watermarked = pywt.dwt2(watermarked, "db4")
LL_w, (LH_w, HL_w, HH_w) = coeffs_watermarked

watermark = load_watermark_for_comparison(watermark_path, LH_o.shape)

# Extract watermark from LH subband
extracted = (LH_w - LH_o) / alpha

# Normalize for visualization
extracted_display = normalize_for_display(extracted)
extracted_uint8 = (extracted_display * 255).astype(np.uint8)

cv2.imwrite(str(extracted_path), extracted_uint8)

print("Extracted watermark saved to:", extracted_path)
corr = correlation(watermark, extracted)
print("Correlation:", corr)

fig, axes = plt.subplots(1, 2, figsize=(10, 4))
axes[0].imshow(watermark, cmap="gray", vmin=0, vmax=1)
axes[0].set_title("Original Watermark")
axes[0].axis("off")

axes[1].imshow(extracted_display, cmap="gray")
axes[1].set_title("Extracted Watermark")
axes[1].axis("off")

plt.tight_layout()
plt.show()
