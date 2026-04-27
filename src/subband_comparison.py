import matplotlib.pyplot as plt

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
    alpha = 5
    subbands = ["LL", "LH", "HL", "HH"]

    rows = []
    results = {}

    for subband in subbands:
        result = evaluate_embedding(original, alpha, subband_name=subband, wavelet="db4")
        results[subband] = result
        rows.append(
            {
                "subband": subband,
                "alpha": alpha,
                "mse": result["mse"],
                "psnr_db": result["psnr"],
                "correlation": result["corr"],
            }
        )

    print(f"{'subband':>8} {'alpha':>8} {'MSE':>12} {'PSNR(dB)':>12} {'corr':>12}")
    for row in rows:
        print(
            f"{row['subband']:>8} {row['alpha']:>8g} {row['mse']:>12.6f} "
            f"{row['psnr_db']:>12.6f} {row['correlation']:>12.6f}"
        )

    save_csv(TABLES_DIR / "subband_comparison_metrics.csv", rows[0].keys(), rows)

    fig, axes = plt.subplots(len(subbands), 4, figsize=(14, 3 * len(subbands)))
    for row_idx, subband in enumerate(subbands):
        result = results[subband]

        axes[row_idx, 0].imshow(original, cmap="gray", vmin=0, vmax=255)
        axes[row_idx, 0].set_title(f"Original\n{subband}")
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
    plt.savefig(IMAGES_DIR / "subband_comparison_grid.png", dpi=200, bbox_inches="tight")

    fig, axes = plt.subplots(1, 3, figsize=(14, 4))
    axes[0].bar(subbands, [row["mse"] for row in rows])
    axes[0].set_title("Subband vs MSE")
    axes[0].set_ylabel("MSE")

    axes[1].bar(subbands, [row["psnr_db"] for row in rows])
    axes[1].set_title("Subband vs PSNR")
    axes[1].set_ylabel("PSNR (dB)")

    axes[2].bar(subbands, [row["correlation"] for row in rows])
    axes[2].set_title("Subband vs Correlation")
    axes[2].set_ylabel("Correlation")

    plt.tight_layout()
    plt.savefig(PLOTS_DIR / "subband_comparison_metrics.png", dpi=200, bbox_inches="tight")
    plt.show()


if __name__ == "__main__":
    main()
