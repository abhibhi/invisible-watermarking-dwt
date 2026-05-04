#import "template.typ": report

#show: report.with(
  title: "Invisible Image Watermarking in the Discrete Wavelet Domain",
  subtitle: "A Study with the Daubechies-4 Wavelet",
  authors: (
    (name: "Isaac Chacko", email: "isaac.chacko05@tamu.edu"),
    (name: "Abhitej Devireddy", email: "abhitejd1@tamu.edu"),
    (name: "Allen Thomas", email: "allen.t_a28@tamu.edu"),
  ),
  date: "Spring 2026",
  abstract: [
    // TODO: rewrite once §§ 4-6 are finalized.
    We study invisible digital image watermarking in the wavelet domain. A
    binary watermark is embedded into a chosen subband of the two-dimensional
    Daubechies-4 (`db4`) discrete wavelet transform of a grayscale host image
    by additive perturbation of magnitude $alpha$, and is extracted
    non-blindly by re-transforming both the original and the watermarked
    image. We analyze the scheme along three axes -- embedding strength,
    choice of subband, and robustness under standard attacks (Gaussian noise,
    Gaussian blur, JPEG compression, resizing, and cropping) -- and report
    quantitative results in mean-squared error, peak signal-to-noise ratio,
    and normalized correlation. We give a mathematical interpretation of the
    observed quantization-floor effect at small $alpha$, and connect our
    findings to the broader watermarking literature.
  ],
  keywords: (
    "discrete wavelet transform",
    "Daubechies wavelets",
    "digital watermarking",
    "steganography",
    "multiresolution analysis",
  ),
  bibliography-file: "references.yml",
)

#outline(title: [Contents], indent: auto)
#pagebreak()

= Introduction <sec:intro>

// TODO §1.1 -- Motivation. Copyright protection, provenance, deepfake-era
// authentication of digital media. Tie the topic to the assignment's "Images
// and audio: hiding an image (steganography) / detection of altered images"
// suggestion.

// TODO §1.2 -- Background terminology. Visible vs invisible; fragile vs
// robust; blind vs non-blind. Position our work as invisible, semi-robust,
// non-blind.

// TODO §1.3 -- Why the wavelet domain (one-paragraph teaser). Multi-resolution
// localization + Human Visual System sensitivity. Defer the full argument to
// §2-3.

== Contributions

// TODO §1.4 -- Bullet list:
//  1. Reference DWT-watermarking pipeline in Python (PyWavelets + OpenCV).
//  2. Empirical study of three design knobs (alpha, subband, attack).
//  3. Mathematical interpretation of the uint8 quantization floor at
//     small alpha.

== Roadmap

// TODO §1.5 -- One paragraph previewing the remaining sections.

#pagebreak()

= Mathematical Background <sec:math>

== Multiresolution Analysis <sec:mra>

// TODO §2.1 -- Define MRA: nested closed subspaces {V_j} of L^2(R), with
// the density, separation, scaling, and shift-invariance axioms. Introduce
// the scaling function phi and mother wavelet psi. State the two-scale
// equations explicitly.

// Two-scale equations (placeholder block math):
$
  phi(t) = sqrt(2) sum_(k in ZZ) h_k phi(2t - k),
  quad
  psi(t) = sqrt(2) sum_(k in ZZ) g_k phi(2t - k).
$

// TODO -- introduce W_j and the orthogonal decomposition
// V_(j+1) = V_j ⊕ W_j and the limit L^2(R) = ⊕_j W_j.

== The 1-D Discrete Wavelet Transform <sec:dwt-1d>

// TODO §2.2 -- Mallat's pyramidal algorithm: convolve with low-pass h and
// high-pass g, downsample by 2, recurse on the approximation. Reconstruction
// with synthesis filters tilde h, tilde g. O(N) complexity. Mention the
// quadrature-mirror-filter relation g_k = (-1)^k h_(1-k) (or similar).
// Cite @mallat1989, @daubechies1992, @burrus1998.

== The Daubechies Family and `db4` <sec:db4>

// TODO §2.3 -- Properties of dbN: orthogonality, compact support of width
// 2N-1, N vanishing moments. Show the db4 filter coefficients (8 numbers)
// in a small table. Compare with Haar (db1): one vanishing moment,
// discontinuous, blocky. This subsection is what satisfies the spec rule
// "Use the Haar wavelet only in conjunction with some other wavelet".
// Cite @daubechies1988, @daubechies1992.

#figure(
  table(
    columns: 2,
    align: (left, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*Index $k$*][*$h_k$ (db4)*],
    [0], [-0.0106],
    [1], [0.0329],
    [2], [0.0308],
    [3], [-0.187],
    [4], [-0.028],
    [5], [0.6309],
    [6], [0.7148],
    [7], [0.2304],
  ),
  caption: [Low-pass analysis filter coefficients for the Daubechies-4 wavelet (placeholders -- regenerate from `pywt.Wavelet("db4").dec_lo` for exact values).],
) <tab:db4-filter>

== The 2-D Separable DWT <sec:dwt-2d>

// TODO §2.4 -- Tensor-product construction: apply the 1-D DWT to rows then
// columns, producing four subbands LL, LH, HL, HH per level. Multi-level
// recursion on the LL band gives the standard wavelet pyramid.

// TODO -- replace this placeholder with a cetz block diagram of the
// LL/HL/LH/HH layout once the writing is in place.
#figure(
  rect(width: 4cm, height: 4cm, stroke: 0.5pt)[
    #place(top + left, dx: 0.3cm, dy: 0.3cm)[LL]
    #place(top + right, dx: -0.3cm, dy: 0.3cm)[HL]
    #place(bottom + left, dx: 0.3cm, dy: -0.3cm)[LH]
    #place(bottom + right, dx: -0.3cm, dy: -0.3cm)[HH]
  ],
  caption: [One-level 2-D DWT subband layout (schematic placeholder).],
) <fig:subband-layout>

== Quality Metrics <sec:metrics>

// TODO §2.5 -- Define MSE, PSNR, normalized cross-correlation. State the
// formulas (and that we use cv2 / numpy implementations).

$
  "MSE"(I, hat(I)) = 1 / (M N) sum_(i,j) (I_(i j) - hat(I)_(i j))^2,
  quad
  "PSNR" = 10 log_10 (255^2 / "MSE").
$

$
  rho(W, hat(W)) = (chevron.l W - macron(W), space hat(W) - macron(hat(W)) chevron.r)
  / (norm(W - macron(W)) space norm(hat(W) - macron(hat(W)))).
$

#pagebreak()

= The Application: Invisible Watermarking via 2-D DWT <sec:application>

== The Watermarking System <sec:system>

// TODO §3.1 -- Components: host I, watermark W, embedder E, channel/attack A,
// extractor D. Replace this placeholder with a cetz block diagram.

#figure(
  rect(width: 12cm, height: 2cm, stroke: 0.5pt)[
    #align(center + horizon)[
      $I, W$ #h(0.5cm) $-->$ #h(0.3cm) $E$ #h(0.3cm) $-->$ #h(0.3cm) $I'$ #h(0.3cm) $-->$ #h(0.3cm) $A$ #h(
        0.3cm,
      ) $-->$ #h(0.3cm) $tilde(I)$ #h(0.3cm) $-->$ #h(0.3cm) $D$ #h(0.3cm) $-->$ #h(0.3cm) $hat(W)$
    ]
  ],
  caption: [Watermarking pipeline (placeholder for a cetz block diagram).],
) <fig:pipeline>

== The Invisibility-Robustness-Payload Trilemma <sec:trilemma>

// TODO §3.2 -- State the trilemma and explain how alpha, subband, and
// payload size trade off.

== Why the Wavelet Domain? <sec:why-dwt>

// TODO §3.3 -- Human Visual System contrast sensitivity function (CSF),
// luminance and texture masking; spatial localization of DWT vs the global
// support of DCT. Cite @cox1997, @barni2001, @wang1999wavemark.

== Embedding Scheme <sec:embed>

// TODO §3.4 -- Describe preprocessing of the watermark (load grayscale,
// resize to subband shape with INTER_AREA, threshold at 127 to a binary
// map). Then the additive embedding rule.

$
  c'_S = c_S + alpha thin W,
$

// where $c_S$ denotes the chosen subband. Reconstruct via IDWT, clip to
// [0, 255], cast to uint8.

== Extraction Scheme (Non-Blind) <sec:extract>

// TODO §3.5 -- Re-DWT both images, then

$
  hat(W) = (c'_S - c_S) / alpha.
$

// Discuss why this is non-blind and what that costs.

== Implementation Notes <sec:impl>

// TODO §3.6 -- PyWavelets, OpenCV, NumPy. Reference Appendix A for full
// listings. Cite @pywavelets, @opencv, @numpy.

#figure(
  grid(
    columns: 4,
    gutter: 4pt,
    image("../data/original/image.jpg", width: 100%),
    image("../data/original/watermark.png", width: 100%),
    image("../data/watermarked/watermarked_image.png", width: 100%),
    image("../results/images/extracted_watermark.png", width: 100%),
  ),
  caption: [End-to-end pipeline at the default configuration ($alpha = 1$, subband `LH`, wavelet `db4`). Left to right: original host image, binary watermark, watermarked image, extracted watermark.],
) <fig:pipeline-demo>

#pagebreak()

= Experiments and Results <sec:results>

== Setup <sec:setup>

// TODO §4.1 -- Host: data/original/image.jpg. Watermark:
// data/original/watermark.png (binary, resized per subband). Wavelet: db4.
// Defaults: subband LH, alpha = 5 unless noted. All experiments are
// reproducible from src/{alpha_sweep,subband_comparison,attack_robustness}.py.

== Experiment 1: Embedding-Strength Sweep <sec:exp-alpha>

// TODO §4.2 -- Sweep alpha in {0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20} on
// subband LH. Discuss the tradeoff and the plateau at small alpha
// (foreshadows §5.2).

#figure(
  table(
    columns: 4,
    align: (right, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*$alpha$*][*MSE*][*PSNR (dB)*][*$rho$*],
    [0.01], [0.494], [51.19], [0.634],
    [0.05], [0.494], [51.19], [0.634],
    [0.10], [0.494], [51.19], [0.634],
    [0.50], [0.494], [51.19], [0.634],
    [1.00], [0.494], [51.19], [0.634],
    [5.00], [6.106], [40.27], [0.696],
    [10.0], [23.627], [34.40], [0.696],
    [20.0], [93.841], [28.41], [0.695],
  ),
  caption: [Embedding-strength sweep on subband `LH`. Source: `results/tables/alpha_sweep_metrics.csv`.],
) <tab:alpha-sweep>

#figure(
  image("../results/plots/alpha_sweep_metrics.png", width: 100%),
  caption: [MSE, PSNR, and watermark correlation as a function of embedding strength $alpha$, on subband `LH` with `db4`. The flat region for $alpha lt.eq 1$ is the `uint8` quantization floor analyzed in @sec:quantization-floor.],
) <fig:alpha-sweep-plot>

#figure(
  image("../results/images/alpha_sweep_grid.png", width: 95%),
  caption: [Visual sweep over embedding strengths. Columns, left to right: original host, watermarked image, absolute pixel difference (hot colormap), extracted watermark. Rows correspond to $alpha in {0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20}$.],
) <fig:alpha-sweep-grid>

== Experiment 2: Subband Comparison <sec:exp-subband>

// TODO §4.3 -- Embed at alpha = 5 into each of LL, LH, HL, HH. Discuss why
// LL wins on MSE/correlation but is the perceptually worst choice.

#figure(
  table(
    columns: 4,
    align: (left, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*Subband*][*MSE*][*PSNR (dB)*][*$rho$*],
    [LL], [3.77], [42.37], [0.991],
    [LH], [6.11], [40.27], [0.696],
    [HL], [6.11], [40.27], [0.796],
    [HH], [6.10], [40.27], [0.613],
  ),
  caption: [Subband comparison at $alpha = 5$. Source: `results/tables/subband_comparison_metrics.csv`.],
) <tab:subband>

#figure(
  image("../results/plots/subband_comparison_metrics.png", width: 100%),
  caption: [MSE, PSNR, and correlation per subband at $alpha = 5$ with `db4`.],
) <fig:subband-plot>

#figure(
  image("../results/images/subband_comparison_grid.png", width: 95%),
  caption: [Visual subband comparison. Rows: `LL`, `LH`, `HL`, `HH`. Columns: original, watermarked, absolute difference, extracted watermark.],
) <fig:subband-grid>

== Experiment 3: Robustness under Attacks <sec:exp-attacks>

// TODO §4.4 -- Define each attack mathematically. Run for alpha in {1, 5, 10}
// on subband LH. Key finding: scheme is fragile; only Gaussian noise is
// partially survivable.

#figure(
  table(
    columns: 4,
    align: (left, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*Attack*][*$alpha=1$*][*$alpha=5$*][*$alpha=10$*],
    [none], [0.634], [0.696], [0.696],
    [Gaussian noise ($sigma = 8$)], [0.026], [0.143], [0.273],
    [Gaussian blur ($5 times 5$)], [-0.006], [-0.005], [-0.004],
    [JPEG ($Q = 40$)], [-0.010], [0.021], [0.042],
    [resize 60%], [-0.002], [0.001], [0.004],
    [crop 85%], [-0.008], [-0.013], [-0.016],
  ),
  caption: [Watermark recovery correlation $rho$ after each attack, by embedding strength. Source: `results/tables/attack_robustness_metrics.csv`.],
) <tab:attacks>

#figure(
  image("../results/plots/attack_robustness_metrics.png", width: 100%),
  caption: [Correlation $rho$ after each attack, grouped by $alpha in {1, 5, 10}$.],
) <fig:attacks-plot>

#figure(
  image("../results/images/attack_robustness_extractions.png", width: 100%),
  caption: [Extracted watermark after each attack at $alpha = 5$, subband `LH`.],
) <fig:attacks-extracted>

#pagebreak()

= Discussion <sec:discussion>

== Why `LL` Won the Metric Race <sec:why-ll>

// TODO §5.1 -- Energy-compaction argument. Most signal energy concentrates
// in LL, so the relative perturbation alpha*W / |LL| is small even at
// alpha = 5. The IDWT spreads the perturbation back into pixels through
// the smooth scaling function, so the result survives clipping more
// gracefully. Conversely, the eye's CSF peaks in low spatial frequencies,
// so LL is perceptually the worst place to hide a watermark.

== The `uint8` Quantization Floor <sec:quantization-floor>

// TODO §5.2 -- Model the cast to uint8 as a uniform scalar quantizer with
// step Delta = 1. Show that whenever
//
//   alpha * max_{i,j} |IDWT contribution from W|_{i,j} < Delta / 2,
//
// the watermark is below the quantizer threshold and is destroyed. This
// matches the empirical plateau at alpha <= 1 in §4.2. (You can compute
// the IDWT contribution constant numerically once and quote it.)

== Why Blur, JPEG, Resize, and Crop Destroy the Watermark <sec:why-attacks>

// TODO §5.3 -- Each attack is itself a low-pass / lossy / geometric
// operator whose noise lives in (or shifts) the same detail subbands we
// embed in. Spread-spectrum embedding (Cox et al. @cox1997) and quantization
// index modulation (Chen-Wornell @chen2001qim) handle this by spreading
// each watermark bit across many coefficients.

== Limitations <sec:limitations>

// TODO §5.4 -- Single-level DWT, single subband, non-blind, no perceptual
// weighting, fragile.

#pagebreak()

= Conclusions <sec:conclusions>

// TODO §6 -- Three short paragraphs:
//   1. Recap of findings (one sentence per experiment).
//   2. Practical guidance for a hypothetical implementer.
//   3. Future work: multi-level DWT, biorthogonal wavelets (CDF 9/7 as
//      used in JPEG 2000 @jpeg2000), spread-spectrum / QIM embedding,
//      error-correcting codes, perceptual CSF-weighted alpha, blind
//      extraction.

// References are emitted by the template after this.

// ---------------- Appendix ----------------
//
// The full source code for the implementation is provided separately on
// external storage and is not reproduced here.

#pagebreak()
#set heading(numbering: "A.1")
#counter(heading).update(0)

= Full Result Tables <sec:appendix-tables>

== Alpha sweep

#raw(read("../results/tables/alpha_sweep_metrics.csv"), lang: "csv", block: true)

== Subband comparison

#raw(read("../results/tables/subband_comparison_metrics.csv"), lang: "csv", block: true)

== Attack robustness

#raw(read("../results/tables/attack_robustness_metrics.csv"), lang: "csv", block: true)
