import matplotlib.pyplot as plt
import numpy as np

from watermark_utils import (
    IMAGES_DIR,
    PLOTS_DIR,
    TABLES_DIR,
    ensure_result_dirs,
    evaluate_embedding,
    load_host_image,
    normalize_for_display,
    save_csv,
)


def main():
    ensure_result_dirs()
    original = load_host_image()
    alpha_values = [0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20]

    rows = []
    samples = []

    for alpha in alpha_values:
        result = evaluate_embedding(original, alpha, subband_name="LH", wavelet="db4")
        rows.append(
            {
                "alpha": alpha,
                "mse": result["mse"],
                "psnr_db": result["psnr"],
                "correlation": result["corr"],
            }
        )
        samples.append((alpha, result))

    print(f"{'alpha':>8} {'MSE':>12} {'PSNR(dB)':>12} {'corr':>12}")
    for row in rows:
        print(
            f"{row['alpha']:>8g} {row['mse']:>12.6f} "
            f"{row['psnr_db']:>12.6f} {row['correlation']:>12.6f}"
        )

    save_csv(TABLES_DIR / "alpha_sweep_metrics.csv", rows[0].keys(), rows)

    fig, axes = plt.subplots(len(samples), 4, figsize=(14, 3 * len(samples)))
    if len(samples) == 1:
        axes = np.array([axes])

    for row_idx, (alpha, result) in enumerate(samples):
        axes[row_idx, 0].imshow(original, cmap="gray", vmin=0, vmax=255)
        axes[row_idx, 0].set_title(f"Original\nalpha={alpha:g}")
        axes[row_idx, 0].axis("off")

        axes[row_idx, 1].imshow(result["watermarked"], cmap="gray", vmin=0, vmax=255)
        axes[row_idx, 1].set_title("Watermarked")
        axes[row_idx, 1].axis("off")

        axes[row_idx, 2].imshow(result["diff"], cmap="hot")
        axes[row_idx, 2].set_title("Absolute Difference")
        axes[row_idx, 2].axis("off")

        axes[row_idx, 3].imshow(normalize_for_display(result["extracted"]), cmap="gray")
        axes[row_idx, 3].set_title("Extracted Watermark")
        axes[row_idx, 3].axis("off")

    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "alpha_sweep_grid.png", dpi=200, bbox_inches="tight")

    fig, axes = plt.subplots(1, 3, figsize=(14, 4))
    axes[0].plot(alpha_values, [row["mse"] for row in rows], marker="o")
    axes[0].set_title("Alpha vs MSE")
    axes[0].set_xlabel("alpha")
    axes[0].set_ylabel("MSE")
    axes[0].set_xscale("log")
    axes[0].grid(True, alpha=0.3)

    axes[1].plot(alpha_values, [row["psnr_db"] for row in rows], marker="o")
    axes[1].set_title("Alpha vs PSNR")
    axes[1].set_xlabel("alpha")
    axes[1].set_ylabel("PSNR (dB)")
    axes[1].set_xscale("log")
    axes[1].grid(True, alpha=0.3)

    axes[2].plot(alpha_values, [row["correlation"] for row in rows], marker="o")
    axes[2].set_title("Alpha vs Correlation")
    axes[2].set_xlabel("alpha")
    axes[2].set_ylabel("Correlation")
    axes[2].set_xscale("log")
    axes[2].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(PLOTS_DIR / "alpha_sweep_metrics.png", dpi=200, bbox_inches="tight")
    plt.show()


if __name__ == "__main__":
    main()
