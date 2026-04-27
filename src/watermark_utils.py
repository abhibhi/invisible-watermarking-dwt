import csv
from pathlib import Path

import cv2
import numpy as np
import pywt


BASE_DIR = Path(__file__).resolve().parent.parent
IMAGE_PATH = BASE_DIR / "data" / "original" / "image.jpg"
WATERMARK_PATH = BASE_DIR / "data" / "original" / "watermark.png"
RESULTS_DIR = BASE_DIR / "results"
PLOTS_DIR = RESULTS_DIR / "plots"
TABLES_DIR = RESULTS_DIR / "tables"
IMAGES_DIR = RESULTS_DIR / "images"


def ensure_result_dirs():
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    TABLES_DIR.mkdir(parents=True, exist_ok=True)
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def calculate_mse(original, modified):
    original = original.astype(np.float64)
    modified = modified.astype(np.float64)
    return np.mean((original - modified) ** 2)


def calculate_psnr(original, modified):
    mse = calculate_mse(original, modified)
    if mse == 0:
        return float("inf")
    return 10 * np.log10((255 ** 2) / mse)


def normalize_for_display(arr):
    arr = arr.astype(np.float64)
    arr = arr - np.min(arr)
    max_val = np.max(arr)
    if max_val != 0:
        arr = arr / max_val
    return arr


def correlation(original, extracted):
    original = original.flatten()
    extracted = extracted.flatten()
    return np.corrcoef(original, extracted)[0, 1]


def load_grayscale_image(path):
    image = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    if image is None:
        raise FileNotFoundError(f"Could not load image at: {path}")
    return image


def load_host_image():
    return load_grayscale_image(IMAGE_PATH)


def load_watermark(target_shape):
    watermark = load_grayscale_image(WATERMARK_PATH)
    watermark = cv2.resize(
        watermark, (target_shape[1], target_shape[0]), interpolation=cv2.INTER_AREA
    )
    _, watermark = cv2.threshold(watermark, 127, 1, cv2.THRESH_BINARY)
    return watermark.astype(np.float64)


def get_subbands(image, wavelet="db4"):
    coeffs = pywt.dwt2(image, wavelet)
    ll, (lh, hl, hh) = coeffs
    return ll, lh, hl, hh


def reconstruct_image(ll, lh, hl, hh, wavelet="db4"):
    reconstructed = pywt.idwt2((ll, (lh, hl, hh)), wavelet)
    return np.clip(reconstructed, 0, 255).astype(np.uint8)


def embed_watermark(image, alpha, subband_name="LH", wavelet="db4"):
    ll, lh, hl, hh = get_subbands(image, wavelet)
    subband_map = {"LL": ll, "LH": lh, "HL": hl, "HH": hh}
    if subband_name not in subband_map:
        raise ValueError(f"Unsupported subband: {subband_name}")

    watermark = load_watermark(subband_map[subband_name].shape)
    subband_map[subband_name] = subband_map[subband_name] + alpha * watermark

    watermarked = reconstruct_image(
        subband_map["LL"],
        subband_map["LH"],
        subband_map["HL"],
        subband_map["HH"],
        wavelet,
    )
    return watermarked, watermark


def extract_watermark(original, watermarked, alpha, subband_name="LH", wavelet="db4"):
    ll_o, lh_o, hl_o, hh_o = get_subbands(original, wavelet)
    ll_w, lh_w, hl_w, hh_w = get_subbands(watermarked, wavelet)
    original_map = {"LL": ll_o, "LH": lh_o, "HL": hl_o, "HH": hh_o}
    watermarked_map = {"LL": ll_w, "LH": lh_w, "HL": hl_w, "HH": hh_w}

    watermark = load_watermark(original_map[subband_name].shape)
    extracted = (watermarked_map[subband_name] - original_map[subband_name]) / alpha
    return watermark, extracted


def evaluate_embedding(original, alpha, subband_name="LH", wavelet="db4"):
    watermarked, _ = embed_watermark(original, alpha, subband_name, wavelet)
    watermark, extracted = extract_watermark(
        original, watermarked, alpha, subband_name, wavelet
    )

    return {
        "watermarked": watermarked,
        "watermark": watermark,
        "extracted": extracted,
        "mse": calculate_mse(original, watermarked),
        "psnr": calculate_psnr(original, watermarked),
        "corr": correlation(watermark, extracted),
        "diff": cv2.absdiff(original, watermarked),
    }


def attack_gaussian_noise(image, sigma=8, seed=414):
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, sigma, image.shape)
    attacked = image.astype(np.float64) + noise
    return np.clip(attacked, 0, 255).astype(np.uint8)


def attack_blur(image, kernel_size=5):
    return cv2.GaussianBlur(image, (kernel_size, kernel_size), 0)


def attack_resize(image, scale=0.6):
    new_width = max(1, int(image.shape[1] * scale))
    new_height = max(1, int(image.shape[0] * scale))
    resized = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)
    return cv2.resize(
        resized, (image.shape[1], image.shape[0]), interpolation=cv2.INTER_LINEAR
    )


def attack_crop_and_resize(image, crop_fraction=0.85):
    height, width = image.shape
    crop_h = max(1, int(height * crop_fraction))
    crop_w = max(1, int(width * crop_fraction))
    y0 = (height - crop_h) // 2
    x0 = (width - crop_w) // 2
    cropped = image[y0 : y0 + crop_h, x0 : x0 + crop_w]
    return cv2.resize(
        cropped, (width, height), interpolation=cv2.INTER_LINEAR
    )


def attack_jpeg_compression(image, quality=40):
    success, encoded = cv2.imencode(
        ".jpg", image, [int(cv2.IMWRITE_JPEG_QUALITY), quality]
    )
    if not success:
        raise RuntimeError("JPEG compression attack failed during encoding.")
    decoded = cv2.imdecode(encoded, cv2.IMREAD_GRAYSCALE)
    if decoded is None:
        raise RuntimeError("JPEG compression attack failed during decoding.")
    return decoded


def get_attack_map():
    return {
        "none": lambda img: img.copy(),
        "gaussian_noise": lambda img: attack_gaussian_noise(img, sigma=8),
        "gaussian_blur": lambda img: attack_blur(img, kernel_size=5),
        "jpeg_q40": lambda img: attack_jpeg_compression(img, quality=40),
        "resize_60pct": lambda img: attack_resize(img, scale=0.6),
        "crop_85pct": lambda img: attack_crop_and_resize(img, crop_fraction=0.85),
    }


def save_csv(path, fieldnames, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
