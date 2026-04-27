import matplotlib.pyplot as plt

from watermark_utils import (
    IMAGES_DIR,
    PLOTS_DIR,
    TABLES_DIR,
    ensure_result_dirs,
    extract_watermark,
    get_attack_map,
    load_host_image,
    normalize_for_display,
    save_csv,
    correlation,
    embed_watermark,
)


def main():
    ensure_result_dirs()
    original = load_host_image()
    attack_map = get_attack_map()
    alpha_values = [1, 5, 10]
    subband = "LH"

    rows = []
    snapshots = []

    for alpha in alpha_values:
        watermarked, _ = embed_watermark(original, alpha, subband_name=subband, wavelet="db4")

        for attack_name, attack_fn in attack_map.items():
            attacked = attack_fn(watermarked)
            watermark, extracted = extract_watermark(
                original, attacked, alpha, subband_name=subband, wavelet="db4"
            )
            corr = correlation(watermark, extracted)
            rows.append(
                {
                    "alpha": alpha,
                    "attack": attack_name,
                    "correlation": corr,
                }
            )

            if alpha == 5:
                snapshots.append((attack_name, attacked, extracted))

    print(f"{'alpha':>8} {'attack':>18} {'corr':>12}")
    for row in rows:
        print(f"{row['alpha']:>8g} {row['attack']:>18} {row['correlation']:>12.6f}")

    save_csv(TABLES_DIR / "attack_robustness_metrics.csv", rows[0].keys(), rows)

    fig, axes = plt.subplots(1, len(snapshots), figsize=(3.5 * len(snapshots), 6))
    if len(snapshots) == 1:
        axes = [axes]

    for ax, (attack_name, attacked, extracted) in zip(axes, snapshots):
        ax.imshow(normalize_for_display(extracted), cmap="gray")
        ax.set_title(f"{attack_name}\nExtracted")
        ax.axis("off")

    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "attack_robustness_extractions.png", dpi=200, bbox_inches="tight")

    attacks = list(attack_map.keys())
    fig, axes = plt.subplots(1, len(alpha_values), figsize=(5 * len(alpha_values), 4), sharey=True)
    if len(alpha_values) == 1:
        axes = [axes]

    for ax, alpha in zip(axes, alpha_values):
        alpha_rows = [row for row in rows if row["alpha"] == alpha]
        ax.bar(attacks, [row["correlation"] for row in alpha_rows])
        ax.set_title(f"Attack Robustness\nalpha={alpha:g}")
        ax.set_ylabel("Correlation")
        ax.tick_params(axis="x", rotation=45)

    plt.tight_layout()
    plt.savefig(PLOTS_DIR / "attack_robustness_metrics.png", dpi=200, bbox_inches="tight")
    plt.show()


if __name__ == "__main__":
    main()
