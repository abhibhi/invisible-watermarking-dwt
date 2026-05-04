# Report Outline — Invisible Image Watermarking via 2D DWT

**Course:** MATH 414-501, Spring 2026 (Narcowich) — Final Project
**Authors:** Isaac Chacko, Abhitej Devireddy, Allen Thomas
**Working title:** *Invisible Image Watermarking in the Discrete Wavelet Domain: A Study with the Daubechies-4 Wavelet*
**Format:** Typst, single-column, 12 pt, 1.5 line spacing, US Letter, 1 in margins.

---

## 1. Spec Compliance Crosswalk

The project assignment ("Math 414-501 Projects (Narcowich) Spring 2024") imposes the following requirements. Each is mapped to the section(s) of this report that satisfy it.

| Spec requirement | Where satisfied |
|---|---|
| Project involves wavelets | §2 (theory), §3 (application), §4 (experiments) |
| Mathematical content (not "show-and-tell" / "golly-gee-whiz") | §2 (full MRA + filter bank), §5 (quantizer & energy-compaction analysis) |
| **§1 Introduction** — describe project, summarize paper | §1 |
| **§2 Mathematical background** — wavelet(s) + related math | §2 |
| **§3 Application** — apply wavelets to a problem | §3 + §4 |
| **§4 Conclusions** — what your analysis yielded, with charts/pictures | §4 (figures), §5 (interpretation), §6 (summary) |
| **§5 References** — properly cited | §7 + `references.yml` |
| Use Haar only in conjunction with another wavelet | §2.3 — primary wavelet is `db4`; Haar (`db1`) is only discussed as a comparison baseline |
| Typed, 12 pt font, 1.5 line spacing, reasonable margins | Enforced by `report/template.typ` |
| ~10–12 pages of prose; cap at 25 pages total | Estimate ~11–14 prose pages, ~18–22 total with figures + appendices |

---

## 2. Document Structure (with page estimates)

| § | Section | Est. pages |
|---|---|---:|
| — | Title block + abstract | 0.5 |
| — | Table of contents *(optional, formal touch)* | 0.5 |
| 1 | Introduction | 1 |
| 2 | Mathematical Background | 3.5–4 |
| 3 | The Application: Invisible Watermarking via 2D DWT | 2.5–3 |
| 4 | Experiments and Results | 3–4 |
| 5 | Discussion | 1.5–2 |
| 6 | Conclusions | 0.5–1 |
| 7 | References | 0.5–1 |
| A | Appendix — Full result tables | 0.5–1 |

---

## 3. Detailed Section Plan

### § 1 — Introduction *(~1 page)* → Spec §1

- **1.1 Motivation.** Copyright protection, provenance, deepfake-era authentication of digital media.
- **1.2 Background terminology.** Visible vs invisible watermarking; fragile vs robust; blind vs non-blind. Position our work as **invisible, semi-robust, non-blind**.
- **1.3 Why the wavelet domain (teaser).** Multi-resolution + Human Visual System (HVS) argument — full development deferred to §2 and §3.
- **1.4 Contributions.**
  1. A clean reference DWT-watermarking pipeline in Python (PyWavelets + OpenCV).
  2. An empirical study of the three main design knobs — embedding strength `α`, choice of subband, and robustness under attack.
  3. A mathematical interpretation of the observed `uint8` quantization floor that emerges at small `α`.
- **1.5 Roadmap.** One-paragraph preview of the remaining sections.

### § 2 — Mathematical Background *(~3.5–4 pages)* → Spec §2 + math content + Haar rule

- **2.1 Multiresolution analysis (MRA).** Nested closed subspaces $\{V_j\} \subset L^2(\mathbb{R})$, density / separation / scaling / shift-invariance axioms; scaling function $\varphi$, mother wavelet $\psi$; the two-scale relations
  $$\varphi(t) = \sqrt{2}\sum_k h_k\,\varphi(2t-k), \qquad \psi(t) = \sqrt{2}\sum_k g_k\,\varphi(2t-k).$$
  Wavelet subspaces $W_j$ as orthogonal complements: $V_{j+1} = V_j \oplus W_j$.
- **2.2 The 1-D DWT and Mallat's pyramidal algorithm.** Analysis filters $h$ (low-pass) and $g$ (high-pass) as quadrature mirror filters; convolve and downsample by 2; recurse on the approximation. Reconstruction with synthesis filters $\tilde h, \tilde g$. Complexity $O(N)$.
- **2.3 The Daubechies family and `db4`.** Orthogonality, compact support of width $2N-1$, $N$ vanishing moments (annihilates polynomials of degree $< N$). Show the **`db4` filter coefficients** in a small table. **Compare with Haar (`db1`)**: Haar has only one vanishing moment, is discontinuous, and produces blocky artifacts — `db4` is smoother and gives better energy compaction, motivating our choice. *(This satisfies the "Haar only with another wavelet" rule.)*
- **2.4 The 2-D separable DWT.** Tensor-product construction; one-level decomposition produces four subbands `LL, LH, HL, HH` representing approximation, horizontal-detail, vertical-detail, diagonal-detail.
  - **Figure 2.1** — schematic of a one-level 2-D DWT (`cetz` block diagram of LL/HL/LH/HH layout).
  - **Figure 2.2** — the four real subbands of our host image (generated from `data/original/image.jpg`; will be added when writing).
- **2.5 Quality metrics.** Define
  $$\mathrm{MSE}(I,\hat I) = \tfrac{1}{MN}\sum_{i,j}(I_{ij}-\hat I_{ij})^2, \quad \mathrm{PSNR} = 10\log_{10}\!\frac{255^2}{\mathrm{MSE}},$$
  and the normalized cross-correlation $\rho(W,\hat W) = \frac{\langle W-\bar W,\, \hat W-\bar{\hat W}\rangle}{\|W-\bar W\|\,\|\hat W-\bar{\hat W}\|}$.

### § 3 — The Application *(~2.5–3 pages)* → Spec §3

- **3.1 The watermarking system.** Components: host $I$, watermark $W$, embedder $E$, channel/attack $A$, extractor $D$. Block diagram (`cetz`).
- **3.2 The invisibility–robustness–payload trilemma.** State and motivate; explain how design parameters trade these off.
- **3.3 Why the wavelet domain is well-suited for invisibility.** HVS contrast sensitivity function (CSF), luminance and texture masking; spatial localization of DWT (vs the global support of DCT). Cite Cox et al. 1997, Barni et al., Wang & Wiederhold (WaveMark).
- **3.4 Embedding scheme.**
  $$c'_S = c_S + \alpha\,W,$$
  where $c_S$ is one of the four subbands (we will study all four). Watermark preprocessing: load grayscale, resize to subband shape with area interpolation, threshold at 127 to a binary map. Reconstruct via IDWT, clip to $[0,255]$, cast to `uint8`.
- **3.5 Extraction scheme (non-blind).**
  $$\hat W = (c'_S - c_S)/\alpha.$$
  Discuss what makes this *non-blind* (requires the original host) and why that's a limitation.
- **3.6 Implementation notes.** PyWavelets + OpenCV + NumPy; reference the full source in **Appendix A**.
- **Figure 3.1** — pipeline overview: `original | watermark | watermarked | extracted` for the default `α = 1, LH, db4` configuration.

### § 4 — Experiments and Results *(~3–4 pages, image-heavy)* → Spec §3/§4

- **4.1 Setup.** Host: `image.jpg`; watermark: `watermark.png` (binary logo, resized per subband); wavelet: `db4`; defaults: subband `LH`, $\alpha = 5$ unless noted.
- **4.2 Experiment 1 — Embedding-strength sweep.**
  - Sweep $\alpha \in \{0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20\}$ on subband `LH`.
  - **Table 4.1** — from `results/tables/alpha_sweep_metrics.csv`.
  - **Figure 4.1** — `results/plots/alpha_sweep_metrics.png` (line plots of MSE / PSNR / correlation vs `α`).
  - **Figure 4.2 (full page)** — `results/images/alpha_sweep_grid.png` (original / watermarked / abs-diff / extracted across all `α`).
  - Observations: tradeoff curve, plus the **plateau at $\alpha \le 1$** (foreshadows §5.2).
- **4.3 Experiment 2 — Subband comparison.**
  - Embed at $\alpha = 5$ into each of `LL, LH, HL, HH`.
  - **Table 4.2** — from `results/tables/subband_comparison_metrics.csv`.
  - **Figure 4.3** — `results/plots/subband_comparison_metrics.png`.
  - **Figure 4.4 (full page)** — `results/images/subband_comparison_grid.png`.
  - Key finding: `LL` wins on MSE / correlation, but is the worst place perceptually.
- **4.4 Experiment 3 — Robustness under attacks.**
  - Define each attack mathematically: Gaussian noise ($\sigma = 8$), Gaussian blur ($5 \times 5$), JPEG compression ($Q = 40$), bilinear resize to 60 % and back, center crop at 85 % and resize back.
  - Run for $\alpha \in \{1, 5, 10\}$ on subband `LH`.
  - **Table 4.3** — from `results/tables/attack_robustness_metrics.csv`.
  - **Figure 4.5** — `results/plots/attack_robustness_metrics.png`.
  - **Figure 4.6** — `results/images/attack_robustness_extractions.png`.
  - Key finding: scheme is fragile; only Gaussian noise is partially survivable, and increasing `α` only modestly helps.

### § 5 — Discussion *(~1.5–2 pages)* → mathematical depth

- **5.1 Why `LL` won the metric race.** Energy compaction: most signal energy lives in the approximation subband, so the same additive perturbation $\alpha W$ has a smaller *relative* magnitude there; it also IDWTs back into a smoother spatial pattern that survives clipping. Conversely, perceptually `LL` is worst because the eye's CSF peaks at low spatial frequency.
- **5.2 The `uint8` quantization floor.** Model the cast-to-integer step as a uniform scalar quantizer of step $\Delta = 1$. Show that whenever $\alpha \cdot \max_{i,j}|(\text{IDWT contribution from } W)_{ij}| < \Delta/2$, the embedded signal lies below the quantizer threshold and is destroyed by the round-trip. This matches the empirical plateau at $\alpha \le 1$ in §4.2.
- **5.3 Why blur, JPEG, resize, and crop destroy the watermark.** Each attack is itself a low-pass / lossy / geometric operator whose noise lands in (or shifts) the same detail subbands we embed in. A multi-level DWT or spread-spectrum embedding — which spreads each watermark bit across many coefficients — survives much better. Brief comparison to Cox et al.'s spread-spectrum approach.
- **5.4 Limitations of our scheme.** Single-level DWT, single subband, non-blind, no perceptual weighting, fragile.

### § 6 — Conclusions *(~0.5–1 page)* → Spec §4

- **6.1 Recap.** Pipeline works; `α ≈ 5` is the sweet spot for `LH`; `LL` is mathematically best but perceptually worst; the scheme is fragile under realistic attacks.
- **6.2 Practical guidance** for someone implementing this.
- **6.3 Future work.** Multi-level DWT, biorthogonal wavelets (e.g., CDF 9/7 — symmetric filters → fewer edge artifacts, also used in JPEG 2000), spread-spectrum or QIM embedding, error-correcting codes on the bitstream, perceptual CSF-weighted `α`, blind extraction.

### § 7 — References → Spec §5

Hayagriva-format `references.yml`. Seed citation list:

- Mallat 1989 — *A Theory for Multiresolution Signal Decomposition*, IEEE TPAMI.
- Daubechies 1988 — *Orthonormal Bases of Compactly Supported Wavelets*, CPAM. Plus *Ten Lectures on Wavelets* (1992).
- Cox, Kilian, Leighton, Shamoon 1997 — *Secure Spread Spectrum Watermarking for Multimedia*, IEEE TIP.
- Wang & Wiederhold 1999 — *WaveMark: Digital Image Watermarking using Daubechies' Wavelets and Error-Correcting Coding*, SPIE.
- Barni et al. 2001 — *Improved Wavelet-Based Watermarking through Pixel-Wise Masking*, IEEE TIP.
- Software: PyWavelets, OpenCV, NumPy, Matplotlib.
- Course textbook chapter on wavelets.

### Appendix — Full result tables *(excluded from page count)*

The three result CSVs (`alpha_sweep_metrics.csv`, `subband_comparison_metrics.csv`, `attack_robustness_metrics.csv`) are reproduced verbatim as a reproducibility reference.

The full Python source code for the implementation is **submitted separately on external storage (USB)** and is not reproduced in the PDF.

---

## 4. Page-Padding Strategy *(legitimate — every item adds real content)*

- Two full-page figure grids (`alpha_sweep_grid`, `subband_comparison_grid`) that visually justify the analysis.
- A 2-D DWT decomposition diagram and a watermarking-pipeline block diagram (`cetz`).
- A subband visualization figure built from `image.jpg`.
- Three result tables rendered from the CSVs.
- Result-table appendix.
- All excluded from the 10–12-page prose count by the spec, so they keep us under the 25-page cap while inflating the visible thickness of the document.

---

## 5. Files in `report/`

- `paper.typ` — main document (calls the template, contains all section content).
- `template.typ` — template function enforcing 12 pt, 1.5 line spacing, single column, page geometry, heading numbering, figure/caption styles.
- `references.yml` — Hayagriva bibliography with the seed citations above.
- `outline.md` — this document.

Compile with (run from the project root, or pass `--root ..` so Typst can read the figures and source files in sibling directories):

```bash
cd report
typst compile --root .. paper.typ
# or for live preview while writing:
typst watch --root .. paper.typ
```

A convenience `Makefile` is included; `make -C report` compiles the PDF and `make -C report watch` starts the watcher.
