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
    We study invisible digital image watermarking in the wavelet domain. A
    binary watermark is embedded into a chosen subband of the
    two-dimensional Daubechies-4 (`db4`) discrete wavelet transform of a
    grayscale host image by additive perturbation of magnitude $alpha$,
    and is extracted non-blindly by re-transforming both the original and
    the watermarked image. We analyze the scheme along three axes ---
    embedding strength, choice of subband, and robustness under standard
    attacks (Gaussian noise, Gaussian blur, JPEG compression, resizing,
    and cropping) --- and report quantitative results in mean-squared
    error, peak signal-to-noise ratio, and normalized correlation. We
    derive a closed-form expression for the embedding-strength threshold
    below which the 8-bit pixel quantization destroys the watermark, and
    show that this threshold matches the empirical plateau observed in
    our experiments exactly. We also explain, via the energy-compaction
    property of the wavelet transform, why the approximation subband
    yields the highest extraction correlation despite being the
    perceptually worst place to hide information.
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

The proliferation of digital images on the open internet has made it
trivial to copy, edit, redistribute, and forge visual content. Modern
generative-AI systems exacerbate the problem: provenance and authenticity
of an image can no longer be assumed from its mere existence. Digital
watermarking is one of the oldest and most studied responses to this
problem. Rather than relying on metadata that a downstream actor can
strip, a watermarking scheme embeds an identifying signal directly into
the pixels themselves, in such a way that the signal can later be
recovered by an authorized party but does not visibly disturb the
image @cox2007book.

This paper studies a particular family of such schemes --- _invisible_,
_semi-robust_, _non-blind_ watermarking in the _wavelet transform
domain_. The four adjectives select a specific cell of the watermarking
design space. _Invisible_ means that the embedded signal must not be
perceptible to a human viewer; this is in contrast to visible
watermarking, used for example by stock-photo agencies. _Semi-robust_
means that the watermark must survive moderate, non-adversarial
processing (compression, mild filtering, resizing) but is not required
to survive a determined adversary. _Non-blind_ means that the original,
un-watermarked image is available at extraction time, which is realistic
in copyright-verification scenarios where the rights holder retains the
original. _Transform domain_ means that the watermark is added to the
coefficients of a frequency-like representation of the image, rather
than directly to the pixel values: this exploits the human visual
system's reduced sensitivity to high-frequency perturbations and
provides a natural mechanism for distributing the watermark over many
pixels at once. We use the two-dimensional discrete wavelet transform
(2-D DWT) with the Daubechies-4 (`db4`) wavelet as the transform.

The choice of the wavelet domain is not arbitrary. The DWT is a
multi-resolution analysis: it simultaneously localizes a signal in
space _and_ frequency, in a sense made precise by Mallat's
theory @mallat1989. Each level of decomposition splits an image into
four subbands corresponding to coarse approximation and to horizontal,
vertical, and diagonal detail at the next-finer scale. This decomposition
is well aligned with the multi-channel, scale-sensitive structure of the
human visual system, which makes it a natural place to hide
imperceptible signals @barni2001.

== Contributions

This paper makes three contributions.

+ A clean, well-documented reference implementation of additive 2-D-DWT
  watermarking in Python (using PyWavelets @pywavelets and
  OpenCV @opencv), exposing three design parameters: the embedding
  strength $alpha$, the choice of subband, and the wavelet family.

+ A systematic empirical study of those three parameters, reporting
  mean-squared error, peak signal-to-noise ratio, and normalized
  cross-correlation between the embedded and extracted watermarks.
  Robustness is measured against five standard attacks: additive
  Gaussian noise, Gaussian blur, JPEG compression, bilinear resizing,
  and centered cropping.

+ A mathematical interpretation of two non-obvious empirical findings:
  (i) the existence of a sharp _quantization floor_ at $alpha = 1$ below
  which the embedded signal is completely destroyed by the 8-bit pixel
  cast, derived in closed form from the synthesis filters of `db4`; and
  (ii) the counter-intuitive observation that the approximation
  subband `LL` yields the highest extraction correlation, explained
  via the energy-compaction property of the wavelet transform.

== Roadmap

@sec:math reviews the mathematical background needed to make the rest of
the paper self-contained: multiresolution analysis, the discrete wavelet
transform as a filter bank, the Daubechies family of wavelets and our
specific choice of `db4`, the separable two-dimensional construction,
and the standard image-quality metrics. @sec:application develops the
watermarking system itself: the embedding equation, the (non-blind)
extraction equation, and the rationale for working in the wavelet
domain. @sec:results reports our experiments and results across three
axes. @sec:discussion gives the mathematical interpretation of the
results, including the closed-form quantization-floor derivation.
@sec:conclusions concludes and outlines avenues for future work.

= Mathematical Background <sec:math>

This section develops, with as much mathematical rigor as space permits,
the wavelet machinery on which the rest of the paper depends. Readers
familiar with multiresolution analysis may skip directly to
@sec:application.

== Multiresolution Analysis <sec:mra>

The discrete wavelet transform is best understood not as a clever
algorithm but as the projection step of a particular kind of
hierarchical orthogonal decomposition of $L^2(RR)$, called a
_multiresolution analysis_ (MRA), introduced by Mallat and
Meyer @mallat1989, @mallat2009book.

#figure(kind: "definition", supplement: "Definition", caption: [
  Multiresolution analysis of $L^2(RR)$.
])[]
A _multiresolution analysis_ of $L^2(RR)$ is a sequence
$\{V_j\}_(j in ZZ)$ of closed subspaces of $L^2(RR)$ together with a
function $phi in V_0$ satisfying

+ _Nestedness:_ $dots subset V_(-1) subset V_0 subset V_1 subset dots$

+ _Density and triviality:_
  $overline(union_(j in ZZ) V_j) = L^2(RR)$ and
  $inter_(j in ZZ) V_j = \{0\}$.

+ _Scale invariance:_ $f(t) in V_j arrow.l.r.double f(2t) in V_(j+1)$.

+ _Shift invariance:_ $f(t) in V_0 arrow.l.r.double f(t-k) in V_0$ for
  every $k in ZZ$.

+ _Orthonormal basis:_ The shifts $\{phi(t-k)\}_(k in ZZ)$ form an
  orthonormal basis of $V_0$.

The function $phi$ is called the _scaling function_. Intuitively the
space $V_j$ contains the signals that can be represented at resolution
$2^j$; the nestedness axiom says a coarser representation is contained
in any finer one, the density axiom says one can approximate any
finite-energy signal arbitrarily well by going to fine enough
resolution, and the scale-invariance axiom ties the spaces together by
dyadic dilation.

Define the _wavelet space_ $W_j$ to be the orthogonal complement of
$V_j$ inside $V_(j+1)$:
$ V_(j+1) = V_j plus.o W_j. $ <eq:vw-decomp>
Iterating @eq:vw-decomp and using the density axiom yields the
orthogonal decomposition
$ L^2(RR) = plus.o.big_(j in ZZ) W_j, $ <eq:l2-decomp>
which is the central reason multiresolution analysis is useful: a
function in $L^2(RR)$ can be split, _orthogonally_, into pieces living
at each scale.

A foundational theorem of Mallat @mallat1989 states that the existence
of an MRA is equivalent to the existence of a _mother wavelet_
$psi in W_0$ whose integer shifts $\{psi(t-k)\}_(k in ZZ)$ form an
orthonormal basis of $W_0$; together with @eq:l2-decomp, the doubly
indexed family
$ psi_(j,k)(t) = 2^(j slash 2) psi(2^j t - k), quad j,k in ZZ, $
is then an orthonormal basis of $L^2(RR)$. The two-scale equations
$
  phi(t) &= sqrt(2) sum_(k in ZZ) h_k med phi(2t - k), \
  psi(t) &= sqrt(2) sum_(k in ZZ) g_k med phi(2t - k),
$ <eq:two-scale>
express both the scaling function and the mother wavelet in terms of
the next-finer-resolution version of the scaling function. The two
finite (in our case) sequences $h = (h_k)$ and $g = (g_k)$ are the
_low-pass_ and _high-pass_ analysis filters of the MRA, and the
quadrature-mirror-filter relation
$ g_k = (-1)^k med h_(1-k) $ <eq:qmf>
follows from the orthogonality of $\{phi(t-k)\}_k$ and
$\{psi(t-k)\}_k$ and the inclusion $W_0 subset V_1$ @daubechies1992.

== The 1-D Discrete Wavelet Transform <sec:dwt-1d>

For a discrete signal of length $N$ that we identify with the
coefficients of a function in $V_0$, Mallat's pyramidal algorithm
@mallat1989 gives a recursive procedure to compute the projections onto
$V_(-1), V_(-2), dots$ and the corresponding wavelet detail coefficients
in $W_(-1), W_(-2), dots$. Writing $a_j[n]$ for the level-$j$
approximation coefficients and $d_j[n]$ for the detail coefficients,
the analysis (decomposition) step is
$
  a_(j+1)[n] = sum_(k in ZZ) h_(k - 2 n) med a_j[k], quad
  d_(j+1)[n] = sum_(k in ZZ) g_(k - 2 n) med a_j[k],
$ <eq:analysis>
which is exactly the convolution of $a_j$ with the time-reversed
filters followed by downsampling by a factor of two. The synthesis
(reconstruction) step is the dual operation: upsample the
next-coarser approximation and detail by a factor of two and convolve
with the synthesis filters $tilde(h)$ and $tilde(g)$. For an
orthonormal MRA the synthesis filters coincide with the analysis
filters, so reconstruction is given by
$ a_j[n] = sum_(k in ZZ) h_(n - 2 k) med a_(j+1)[k] + sum_(k in ZZ) g_(n - 2 k) med d_(j+1)[k]. $ <eq:synthesis>
Because each level halves the length of the signal, the total cost of
the full $L$-level transform is $O(N)$ rather than the
$O(N log N)$ of the fast Fourier transform.

The pair @eq:analysis -- @eq:synthesis is the _filter-bank_ realization
of the DWT @burrus1998. It bypasses the scaling function and wavelet
entirely: only the discrete filter taps $h_k$ and $g_k$ are needed at
runtime.

== The Daubechies Family and `db4` <sec:db4>

A wavelet family is determined by a choice of low-pass filter $h$
satisfying the orthogonality and normalization conditions
$
  sum_(k) h_k med h_(k+2 ell) = delta_(ell, 0), quad
  sum_(k) h_k = sqrt(2). $ <eq:ortho-cond>
These leave room for further design choices. The _Daubechies-N_
wavelet, denoted `dbN`, is the unique orthogonal compactly supported
wavelet whose low-pass filter has minimum support consistent with $N$
_vanishing moments_ @daubechies1988, that is,
$ integral_(-infinity)^(+infinity) t^p med psi(t) med d t = 0 quad
  "for" quad p = 0, 1, dots, N-1. $ <eq:vanishing-moments>
A wavelet with $N$ vanishing moments produces small detail coefficients
on signals that are locally polynomial of degree less than $N$, which
makes such wavelets effective at compressing smooth signals into a few
large approximation coefficients and many near-zero detail
coefficients. The cost of more vanishing moments is a longer filter:
`dbN` has filter length $2N$ and support width $2N-1$.

We use $N = 4$. The eight low-pass analysis taps of `db4` are listed in
@tab:db4-filter; the high-pass taps follow from the
quadrature-mirror-filter relation @eq:qmf. They satisfy
$sum_k h_k = sqrt(2) approx 1.41421356$ and
$sum_k h_k^2 = 1$ to machine precision, which is the orthonormality
condition @eq:ortho-cond at $ell = 0$.

#figure(
  table(
    columns: 3,
    align: (right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*$k$*][*$h_k$ (low-pass)*][*$g_k$ (high-pass)*],
    [0], [$-0.010597$], [$-0.230378$],
    [1], [$+0.032883$], [$+0.714847$],
    [2], [$+0.030841$], [$-0.630881$],
    [3], [$-0.187035$], [$-0.027984$],
    [4], [$-0.027984$], [$+0.187035$],
    [5], [$+0.630881$], [$+0.030841$],
    [6], [$+0.714847$], [$-0.032883$],
    [7], [$+0.230378$], [$-0.010597$],
  ),
  caption: [Analysis filter coefficients of the Daubechies-4 wavelet.
  The high-pass filter $g$ is the quadrature mirror of $h$ via
  @eq:qmf, equivalently $g_k = (-1)^k h_(7-k)$.],
) <tab:db4-filter>

The simplest member of the Daubechies family is `db1`, better known as
the _Haar wavelet_, which has only $N = 1$ vanishing moment, filter
length $2$, and a discontinuous mother wavelet
$psi(t) = bb(1)_([0,1 slash 2)) - bb(1)_([1 slash 2, 1))$. While
mathematically convenient, the Haar wavelet introduces severe blocking
artifacts in image processing because its synthesis basis cannot
represent any non-constant local trend. We use `db4` rather than `db1`
precisely because the four vanishing moments allow `db4` to represent
locally cubic regions with vanishing detail energy --- a property that,
as we will see in @sec:why-ll, has direct consequences for
watermarking. The course's own constraint that "the Haar wavelet may be
used only in conjunction with another wavelet" thus aligns with the
practical engineering choice.

== The Two-Dimensional Separable DWT <sec:dwt-2d>

The 2-D DWT is the tensor product of two 1-D DWTs. Given an image
$I in RR^(M times N)$, one applies the 1-D analysis @eq:analysis to
each row, producing two arrays of half the column count corresponding
to row-low-pass and row-high-pass output, and then to each column of
each of those, producing four subbands of size
$(M slash 2) times (N slash 2)$:

- *LL*: low-pass on rows, low-pass on columns --- the _approximation_
  subband, a smoothed and decimated version of $I$.

- *LH*: low-pass on rows, high-pass on columns --- horizontal-detail
  coefficients, capturing variation in the horizontal scan direction.

- *HL*: high-pass on rows, low-pass on columns --- vertical-detail
  coefficients.

- *HH*: high-pass on both --- diagonal-detail coefficients.

The four subbands are usually displayed in the standard "Mallat
quad-tree" layout, schematically shown in @fig:subband-layout and
applied to our host image in @fig:host-subbands. As @fig:host-subbands
makes visually obvious, almost all of the image's energy is
concentrated in `LL`: an explicit computation on our host gives the
fractions
$E_("LL") approx 99.84%$,
$E_("LH") approx 0.079%$,
$E_("HL") approx 0.064%$,
and $E_("HH") approx 0.020%$ of the total. We will return to this
extreme energy compaction in @sec:why-ll. Multi-level decomposition
recurses on the `LL` subband only, producing the familiar
wavelet-pyramid representation used by JPEG 2000 @jpeg2000.

#figure(
  block(
    width: 5cm,
    height: 5cm,
    stroke: 0.7pt,
    {
      grid(
        columns: 2,
        rows: 2,
        column-gutter: 0pt,
        row-gutter: 0pt,
        block(width: 100%, height: 100%, stroke: (right: 0.5pt, bottom: 0.5pt),
          align(center + horizon)[*LL*]),
        block(width: 100%, height: 100%, stroke: (bottom: 0.5pt),
          align(center + horizon)[*HL*]),
        block(width: 100%, height: 100%, stroke: (right: 0.5pt),
          align(center + horizon)[*LH*]),
        block(width: 100%, height: 100%,
          align(center + horizon)[*HH*]),
      )
    }
  ),
  caption: [Standard Mallat layout of the four subbands produced by one
  level of the 2-D DWT. Each subband has dimensions $(M slash 2)
  times (N slash 2)$.],
) <fig:subband-layout>

#figure(
  image("/results/images/host_subbands.png", width: 75%),
  caption: [The four subbands of one level of `db4` 2-D DWT applied to
  the host image. The contrast in each panel is normalized
  independently for visualization. Approximately $99.84%$ of the
  signal energy lives in `LL`; the three detail subbands together
  hold less than $0.2%$.],
) <fig:host-subbands>

== Image-Quality Metrics <sec:metrics>

To quantify perceptual fidelity of the watermarked image and the
quality of watermark recovery we use three standard metrics. For two
$M times N$ images $I$ and $hat(I)$ with pixel values in $[0, 255]$,
the _mean-squared error_ and _peak signal-to-noise ratio_ are defined by
$
  "MSE"(I, hat(I)) &= 1 / (M N) sum_(i=1)^M sum_(j=1)^N (I_(i j) - hat(I)_(i j))^2, \
  "PSNR"(I, hat(I)) &= 10 log_10 frac(255^2, "MSE"(I, hat(I))).
$ <eq:psnr>
PSNR is reported in decibels; for natural images, values above $40$ dB
are typically considered visually indistinguishable from the original.
For watermark recovery, we use the _Pearson normalized
cross-correlation_
$ rho(W, hat(W)) = frac(
  sum_(i, j) (W_(i j) - macron(W))(hat(W)_(i j) - macron(hat(W))),
  sqrt(sum_(i,j) (W_(i j) - macron(W))^2) dot.c sqrt(sum_(i,j) (hat(W)_(i j) - macron(hat(W)))^2)
). $ <eq:corr>
$rho$ is invariant to affine rescaling of the extracted signal, which
is appropriate because the extracted watermark is in general only
recoverable up to an unknown scalar factor.

= The Application: Invisible Watermarking via 2-D DWT <sec:application>

== The Watermarking System <sec:system>

A watermarking system is described by a quintuple
$(I, W, E, A, D)$ consisting of a host signal $I$, a watermark $W$, an
embedder $E$, a channel or attack $A$, and an extractor $D$. The
embedder produces a watermarked signal $I' = E(I, W)$, the channel
transports it (possibly maliciously transforming it into
$tilde(I) = A(I')$), and the extractor produces
$hat(W) = D(I, tilde(I))$ in the non-blind case or
$hat(W) = D(tilde(I))$ in the blind case. The pipeline is depicted in
@fig:pipeline. A scheme is judged on three criteria simultaneously:

- _Imperceptibility:_ $I'$ should be indistinguishable from $I$.
- _Robustness:_ $rho(W, hat(W))$ should remain large under the channel
  $A$.
- _Payload:_ the number of bits encoded in $W$ should be as large as
  practical.

#figure(
  block(stroke: 0.7pt, inset: 8pt, width: 100%)[
    #align(center)[
      $I, space W$ #h(0.4em) #sym.arrow #h(0.4em)
      #box(stroke: 0.5pt, inset: 4pt, [*Embedder $E$*])
      #h(0.4em) #sym.arrow #h(0.4em) $I'$
      #h(0.4em) #sym.arrow #h(0.4em)
      #box(stroke: 0.5pt, inset: 4pt, [*Channel $A$*])
      #h(0.4em) #sym.arrow #h(0.4em) $tilde(I)$
      #h(0.4em) #sym.arrow #h(0.4em)
      #box(stroke: 0.5pt, inset: 4pt, [*Extractor $D$*])
      #h(0.4em) #sym.arrow #h(0.4em) $hat(W)$
    ]
    #v(0.4em)
    #align(center, text(size: 9.5pt)[
      The dashed input $I$ to the extractor is present only in the
      _non-blind_ setting we study here.
    ])
  ],
  caption: [Block diagram of a generic watermarking system.],
) <fig:pipeline>

== The Imperceptibility--Robustness--Payload Trilemma <sec:trilemma>

It is a folklore observation in watermarking that the three criteria
above cannot all be optimized at once @cox2007book. To make the
watermark more robust one typically increases its amplitude (raising the
embedding strength $alpha$), but a larger amplitude makes the
perturbation more visible. To increase payload one typically
distributes more bits across fewer coefficients each, which makes each
bit easier to corrupt. Practical schemes therefore _commit to two_ of
the three criteria and treat the third as a constraint. Our scheme
fixes payload (a single binary watermark image of fixed dimensions) and
trades imperceptibility against robustness through the parameter
$alpha$, the wavelet, and the choice of subband.

== Why the Wavelet Domain? <sec:why-dwt>

Pure spatial-domain watermarking --- adding $alpha W$ directly to the
pixels --- is ineffective because spatial-domain modifications are
visible (the eye is excellent at detecting low-amplitude additive
patterns) and easily destroyed by the simplest filtering. Transform-
domain watermarking instead modifies the coefficients of an image
representation in which the human visual system has different
sensitivity to different coefficients.

The wavelet domain is particularly well-suited for this for three
reasons.

First, the human visual system is itself approximately a multi-channel
multi-scale frequency analyzer; its _contrast sensitivity function_
(CSF) is band-pass with peak sensitivity around mid-spatial-frequencies
and reduced sensitivity at very high frequencies @barni2001. The DWT's
subband decomposition aligns naturally with this and lets us inject
energy into a band where the eye is least likely to notice it.

Second, unlike the discrete cosine transform that underlies JPEG, the
wavelet transform is _spatially localized_. Modifying a single DCT
coefficient changes every pixel of the image; modifying a single
wavelet coefficient at level $j$ changes only a $2^j times 2^j$
neighborhood. This makes wavelet-domain modifications less visible at
sharp edges (where the eye is more forgiving due to luminance masking)
and easier to confine to non-salient regions.

Third, the orthogonality of the wavelet basis means that the additive
embedding equation has a clean inverse: subtracting the host's wavelet
coefficients from the watermarked image's wavelet coefficients recovers
the embedded perturbation exactly, modulo any noise added by the
channel and by the round-trip through pixel quantization.

These properties motivated the early DWT watermarking literature, of
which Wang and Wiederhold's _WaveMark_ system @wang1999wavemark is
representative, and they remain the standard justification for
wavelet-domain methods today.

== Embedding Scheme <sec:embed>

Let $I$ denote the grayscale host image, treated as an $M times N$
real matrix with values in $[0, 255]$, and let $W$ denote the binary
watermark image, eventually resized so that its dimensions match those
of the chosen subband. We compute one level of `db4` 2-D DWT,
$
  ("LL", ("LH", "HL", "HH")) = "DWT"_2(I; med "db4"),
$
choose a subband $S in \{"LL", "LH", "HL", "HH"\}$, and form the
modified subband
$ S' = S + alpha W, $ <eq:embed>
leaving the other three subbands unchanged. The embedding strength
$alpha > 0$ is the central tunable parameter of the scheme. The
watermarked image is recovered by inverse DWT, clipped to the valid
pixel range, and cast back to 8-bit unsigned integers:
$ I' = "round"("clip"_([0, 255]) ("IDWT"_2(dots, S', dots; "db4"))). $
The clip-and-round step is essential because the IDWT output is in
general a real-valued matrix, but the digital channel demands an 8-bit
image. As we will see in @sec:quantization-floor, this innocuous-
looking step is the source of the most striking phenomenon in our
experiments.

The watermark itself is preprocessed before embedding: it is loaded as
grayscale, resized to the dimensions of the chosen subband using
area-averaging interpolation, and thresholded at $127$ to produce a
binary $\{0, 1\}$-valued matrix.

== Extraction Scheme (Non-Blind) <sec:extract>

Extraction is the algebraic inverse of @eq:embed. Re-applying the
DWT to both the original host and the (possibly attacked) watermarked
image,
$
  S_("orig") &= "DWT"_2(I; med "db4")_S, \
  S_("rec") &= "DWT"_2(tilde(I); med "db4")_S,
$
the linearity of the DWT gives
$
  hat(W) = (S_("rec") - S_("orig")) / alpha, $ <eq:extract>
which equals $W$ exactly in the absence of any channel noise or
quantization. In practice the recovered $hat(W)$ is real-valued and
must be compared to the binary $W$ via the normalized correlation
@eq:corr. Note that this extractor is _non-blind_: it requires the
original host $I$ for re-transformation. A blind extractor would have
to either decide each watermark pixel directly from $S_("rec")$
(typically by sign-thresholding) or use a more elaborate scheme such
as quantization-index modulation @chen2001qim.

== Implementation Notes <sec:impl>

The pipeline is implemented in approximately 200 lines of Python using
PyWavelets @pywavelets for the DWT and OpenCV @opencv for image and
attack operations. The full source code is available on the project's
external storage submission. @fig:pipeline-demo shows the four panels
of the end-to-end pipeline at the default configuration $alpha = 1$,
subband `LH`, wavelet `db4`: the watermarked image is visually
indistinguishable from the host (PSNR $approx 51$ dB), and the
extracted watermark visually resembles the binary input despite
significant quantization noise.

#figure(
  grid(
    columns: 4,
    gutter: 4pt,
    image("/data/original/image.jpg", width: 100%),
    image("/data/original/watermark.png", width: 100%),
    image("/data/watermarked/watermarked_image.png", width: 100%),
    image("/results/images/extracted_watermark.png", width: 100%),
  ),
  caption: [End-to-end pipeline at the default configuration
  ($alpha = 1$, subband `LH`, wavelet `db4`). Left to right: original
  host image, binary watermark, watermarked image, extracted
  watermark.],
) <fig:pipeline-demo>

= Experiments and Results <sec:results>

== Setup <sec:setup>

All experiments use a single grayscale host image of size
$350 times 642$ and a binary watermark depicting a small logo,
both stored in `data/original/`. The wavelet is `db4` throughout. The
subband is `LH` and the embedding strength is $alpha = 5$ unless
otherwise stated. All metrics are computed against the original
unwatermarked host. Each experiment is reproducible from a single
Python script (`alpha_sweep.py`, `subband_comparison.py`, and
`attack_robustness.py` respectively) included in the external
submission.

== Experiment 1: Embedding-Strength Sweep <sec:exp-alpha>

We first sweep the embedding strength
$alpha in \{0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20\}$ on the `LH` subband.
@tab:alpha-sweep and @fig:alpha-sweep-plot summarize the metrics; the
visual evidence is shown in @fig:alpha-sweep-grid.

#figure(
  table(
    columns: 4,
    align: (right, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*$alpha$*][*MSE*][*PSNR (dB)*][*$rho$*],
    [0.01], [$0.494$], [$51.19$], [$0.634$],
    [0.05], [$0.494$], [$51.19$], [$0.634$],
    [0.10], [$0.494$], [$51.19$], [$0.634$],
    [0.50], [$0.494$], [$51.19$], [$0.634$],
    [1.00], [$0.494$], [$51.19$], [$0.634$],
    [5.00], [$6.106$], [$40.27$], [$0.696$],
    [10.0], [$23.627$], [$34.40$], [$0.696$],
    [20.0], [$93.841$], [$28.41$], [$0.695$],
  ),
  caption: [Embedding-strength sweep on subband `LH` with `db4`.
  Source: `results/tables/alpha_sweep_metrics.csv`.],
) <tab:alpha-sweep>

#figure(
  image("/results/plots/alpha_sweep_metrics.png", width: 100%),
  caption: [MSE, PSNR, and watermark correlation as a function of
  embedding strength $alpha$, on subband `LH` with `db4`. The
  $alpha$-axis is logarithmic. The flat region for $alpha lt.eq 1$
  is the 8-bit quantization floor analyzed in
  @sec:quantization-floor.],
) <fig:alpha-sweep-plot>

Two qualitative observations stand out. First, the expected
imperceptibility--robustness tradeoff is clearly visible at large
$alpha$: as $alpha$ grows from $5$ to $20$, MSE grows by a factor of
roughly $alpha^2$ (consistent with the additive embedding equation
@eq:embed) while the extraction correlation $rho$ stays nearly
constant, a sign that the channel (the $"uint8"$ cast) is no longer
the bottleneck once $alpha$ is well above the quantization step.
Second, and more striking, _all five rows with $alpha lt.eq 1$ are
identical to six significant figures_. No information about $alpha$
appears in any metric below the threshold $alpha approx 1$. This is
not a numerical coincidence; @sec:quantization-floor derives the
threshold $alpha = 1$ in closed form from the synthesis filters of
`db4`.

#figure(
  image("/results/images/alpha_sweep_grid.png", width: 92%),
  caption: [Visual sweep over embedding strengths. Columns, left to
  right: original host, watermarked image, absolute pixel difference
  (hot colormap), extracted watermark. Rows correspond to $alpha
  in \{0.01, 0.05, 0.1, 0.5, 1, 5, 10, 20\}$.],
) <fig:alpha-sweep-grid>

== Experiment 2: Subband Comparison <sec:exp-subband>

Fixing $alpha = 5$, we now sweep the choice of subband over
$\{"LL", "LH", "HL", "HH"\}$. The metrics are reported in @tab:subband
and @fig:subband-plot, and the visual evidence in @fig:subband-grid.

#figure(
  table(
    columns: 4,
    align: (left, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*Subband*][*MSE*][*PSNR (dB)*][*$rho$*],
    [`LL`], [$3.77$], [$42.37$], [$0.991$],
    [`LH`], [$6.11$], [$40.27$], [$0.696$],
    [`HL`], [$6.11$], [$40.27$], [$0.796$],
    [`HH`], [$6.10$], [$40.27$], [$0.613$],
  ),
  caption: [Subband comparison at $alpha = 5$ with `db4`. Source:
  `results/tables/subband_comparison_metrics.csv`.],
) <tab:subband>

#figure(
  image("/results/plots/subband_comparison_metrics.png", width: 100%),
  caption: [MSE, PSNR, and correlation per subband at $alpha = 5$
  with `db4`.],
) <fig:subband-plot>

The result is, on its face, surprising: the `LL` subband
simultaneously achieves the _lowest_ MSE and the _highest_ extraction
correlation, beating the three detail subbands by a large margin in
both metrics. A naive intuition would predict the opposite, since
embedding into the approximation subband should affect the most
visually salient component of the image. The visual grid in
@fig:subband-grid resolves part of the puzzle: the per-pixel difference
when embedding into `LL` is spread smoothly and at low intensity over
the entire image, whereas the detail subbands produce
edge-concentrated, higher-amplitude perturbations. We give the
mathematical explanation in @sec:why-ll, where the energy-compaction
property of the wavelet transform is shown to imply the observed
result. We emphasize, however, that the metrics do not measure
perceptual quality directly: an `LL`-band perturbation that smoothly
shifts global luminance is precisely the kind of change a human viewer
notices most easily.

#figure(
  image("/results/images/subband_comparison_grid.png", width: 92%),
  caption: [Visual subband comparison at $alpha = 5$. Rows: `LL`,
  `LH`, `HL`, `HH`. Columns: original, watermarked, absolute
  difference, extracted watermark.],
) <fig:subband-grid>

== Experiment 3: Robustness under Attacks <sec:exp-attacks>

We finally test the recovered correlation $rho$ when an adversary or
the channel applies one of five standard attacks to the watermarked
image. The attacks are:

- _Gaussian noise:_ add i.i.d. Gaussian noise of standard deviation
  $sigma = 8$ to each pixel before clipping.
- _Gaussian blur:_ convolve with a $5 times 5$ Gaussian kernel.
- _JPEG compression:_ encode and decode at quality factor $40$.
- _Resize:_ bilinearly downsample to $60%$ of each linear dimension
  and bilinearly upsample back.
- _Centered crop:_ crop the central $85%$ of each linear dimension and
  bilinearly upsample back.

Each attack is applied to the watermarked image at three embedding
strengths $alpha in \{1, 5, 10\}$ on the `LH` subband. The
correlations are reported in @tab:attacks; the bar chart in
@fig:attacks-plot shows the trends graphically and the visual
extractions in @fig:attacks-extracted illustrate the qualitative
catastrophe of most of the attacks.

#figure(
  table(
    columns: 4,
    align: (left, right, right, right),
    inset: 6pt,
    stroke: 0.5pt,
    table.header[*Attack*][*$alpha = 1$*][*$alpha = 5$*][*$alpha = 10$*],
    [none], [$0.634$], [$0.696$], [$0.696$],
    [Gaussian noise ($sigma = 8$)], [$0.026$], [$0.143$], [$0.273$],
    [Gaussian blur ($5 times 5$)], [$-0.006$], [$-0.005$], [$-0.004$],
    [JPEG ($Q = 40$)], [$-0.010$], [$0.021$], [$0.042$],
    [resize to $60%$], [$-0.002$], [$0.001$], [$0.004$],
    [crop to $85%$], [$-0.008$], [$-0.013$], [$-0.016$],
  ),
  caption: [Watermark recovery correlation $rho$ after each attack,
  by embedding strength. Source:
  `results/tables/attack_robustness_metrics.csv`.],
) <tab:attacks>

#figure(
  image("/results/plots/attack_robustness_metrics.png", width: 100%),
  caption: [Correlation $rho$ after each attack, grouped by
  $alpha in \{1, 5, 10\}$. Note the wide gap between Gaussian
  noise (partially survivable) and the other attacks (essentially
  destroyed).],
) <fig:attacks-plot>

#figure(
  image("/results/images/attack_robustness_extractions.png", width: 100%),
  caption: [Extracted watermark after each attack at $alpha = 5$,
  subband `LH`. Only the un-attacked extraction visibly resembles
  the original watermark.],
) <fig:attacks-extracted>

The qualitative finding is unambiguous: the present scheme is _fragile_.
Only Gaussian noise admits any meaningful recovery, and even then the
correlation hovers in the $0.14$--$0.27$ range. Increasing $alpha$ from
$1$ to $10$ has a measurable but limited effect on noise robustness
(roughly tripling $rho$) and essentially no effect on the other
attacks. We give a frequency-domain explanation in @sec:why-attacks.

= Discussion <sec:discussion>

== Why `LL` Wins the Metric Race <sec:why-ll>

The most striking finding of @sec:exp-subband is that `LL` simultaneously
achieves the lowest MSE and the highest extraction correlation. We can
explain both halves of this observation using the energy-compaction
property of the wavelet transform.

The wavelet transform conserves total signal energy by Parseval's
identity:
$ sum_(i, j) I_(i j)^2 = norm("LL")^2 + norm("LH")^2 + norm("HL")^2 + norm("HH")^2. $
For our host image the empirical distribution of this energy is
extremely uneven:
$
  E_("LL") med& approx 99.84%, quad
  E_("LH") med approx 0.079%, \
  E_("HL") med& approx 0.064%, quad
  E_("HH") med approx 0.020%.
$
This is a direct consequence of the four vanishing moments of `db4`:
locally smooth (cubic) regions of the image produce vanishing detail
coefficients, so almost all of the signal collects in the approximation
band.

This explains the MSE result first. The watermark has the same
amplitude $alpha$ regardless of subband, but the _signal-to-perturbation
ratio_ differs by orders of magnitude between subbands: in `LL` the
host coefficients have standard deviation $approx 127$, so
$alpha = 5$ is a $4%$ relative perturbation, whereas in `LH` the host
coefficients have standard deviation $approx 7$, so the same $alpha$
is a $70%$ relative perturbation. Because the IDWT is linear and
norm-preserving, the resulting pixel-domain perturbations have the
same total energy --- and consequently the same MSE before clipping.
The MSE difference between subbands therefore comes entirely from the
clipping behavior of the cast back to $"uint8"$: an `LL`-band
perturbation, being smoothly distributed through the synthesis
scaling function, rarely pushes a pixel out of the valid $[0, 255]$
range, while detail-band perturbations land more often near edges and
saturate.

The correlation result has a related explanation. Extraction
@eq:extract subtracts the original `LL` from the watermarked `LL`, so
the dominant noise source in the recovered $hat(W)$ is the
quantization error introduced by the round-trip through $"uint8"$.
For a fixed $alpha$ that quantization noise has roughly the same total
energy regardless of which subband received the watermark; but when
re-DWT'd it distributes itself across all four subbands roughly in
proportion to the magnitudes of the synthesis filters in each
direction. Because `LL` itself contains nearly all the host energy,
the quantization-noise contribution to `LL` extraction sits on top of
a much larger signal and is in relative terms negligible; in the
detail subbands the noise can dominate. This is why $rho$ for `LL`
($0.991$) is closer to one than for any detail subband.

We emphasize again that none of this implies `LL` is the best subband
to embed in _perceptually_. The contrast sensitivity function of the
human visual system peaks in the low-spatial-frequency range that
`LL` represents, so a uniformly-distributed `LL` perturbation that is
metrically small can still be visually obvious as a global brightness
shift. Standard practice in the watermarking literature is therefore
to embed in the detail subbands despite their metric disadvantage,
sometimes weighted by perceptual masks @barni2001.

== The 8-Bit Quantization Floor <sec:quantization-floor>

We now derive the quantization floor responsible for the flat region
in @tab:alpha-sweep. Model the cast-to-$"uint8"$ step as a uniform
scalar quantizer with step $Delta = 1$. The full embedding-and-extract
round-trip applied to a watermarked image with embedding subband $S$
and embedding strength $alpha$ is:
$
  P(I, alpha W) = "round"("clip"_([0, 255]) (I + alpha dot.c "IDWT"_2(0, dots, W_S, dots))),
$
where $"IDWT"_2(0, dots, W_S, dots)$ denotes the IDWT with $W$ placed
in the $S$ subband and zeros elsewhere. The watermark is destroyed by
the round step whenever the per-pixel contribution
$ epsilon_(i j) = alpha dot.c ("IDWT"_2(0, dots, W_S, dots))_(i j) $
satisfies $|epsilon_(i j)| < Delta slash 2 = 0.5$ uniformly over
$(i, j)$, because then every pixel rounds independently of the
watermark.

The IDWT-of-a-pure-subband-input quantity is small and computable.
For our setup ($S = "LH"$, watermark $W$ all-ones, `db4` synthesis
filters), the per-pixel magnitude of
$"IDWT"_2(0, "LH" = 1, 0, 0)$ is _exactly_ $0.5$ for every pixel,
to numerical precision. Multiplying by $alpha$, the per-pixel
contribution is $0.5 alpha$, and the destruction condition becomes
$ alpha < 1. $ <eq:quant-threshold>
This is precisely the empirical boundary we observe in @tab:alpha-sweep:
all rows with $alpha lt.eq 1$ produce identical metrics, while
$alpha = 5$ jumps clear of the threshold and exhibits genuine
embedding behavior. The plateau correlation $rho approx 0.634$ that
we record below threshold is _not_ a measurement of the watermark; it
is the correlation of the binary watermark against the deterministic
quantization-noise pattern of the round-trip itself, which is an
artifact of the host image and the wavelet, not the embedding strength.

This analysis also tells us how to lower the threshold: any change
that increases the per-pixel synthesis contribution per unit watermark
energy, such as embedding into multiple subbands simultaneously or
using a wavelet with longer synthesis support, would proportionally
lower $alpha^*$. Conversely, the threshold cannot be removed entirely
without abandoning $"uint8"$ pixel storage --- a fundamental constraint
of consumer image formats.

== Why Blur, JPEG, Resize, and Crop Destroy the Watermark <sec:why-attacks>

The robustness experiment in @sec:exp-attacks shows that our scheme
survives only Gaussian additive noise, and even then poorly. This is
explained almost entirely by the spectral characters of the four
attack operators.

_Gaussian blur_ is a low-pass filter; it suppresses high-frequency
content and therefore selectively attacks exactly the detail subbands
of the wavelet decomposition. Embedding into `LH` and then blurring
attenuates the embedded signal in proportion to the filter's stop-band
gain at the corresponding frequencies, which for a $5 times 5$
Gaussian is essentially zero. The watermark is therefore destroyed
deterministically and increasing $alpha$ provides no help, as confirmed
by the sub-$10^(-2)$ correlations across $alpha in \{1, 5, 10\}$ in
@tab:attacks.

_JPEG compression_ is mathematically a quantization in the DCT domain.
Because the JPEG quantization matrix (especially at low quality
factors) coarsely quantizes high-frequency DCT coefficients, and
because the LH subband of a wavelet decomposition is dominated by
exactly those high-frequency DCT components, JPEG also acts as a
high-frequency suppressor. The slight positive correlations at
$alpha = 5, 10$ in @tab:attacks reflect the fact that a sufficiently
strong watermark can keep some of its DCT coefficients above the
JPEG quantization step, but the recovery is far from reliable.

_Resizing_ destroys the watermark for a different reason: the
2-D DWT is not shift-invariant, and a downsample-and-upsample round
trip is essentially a non-trivial geometric transformation in the
wavelet basis. The recovered subband $S_("rec")$ no longer represents
the same coefficients as $S_("orig")$, and the difference contains
mostly resampling noise rather than the embedded watermark.

_Cropping and re-scaling_ amplifies the same misalignment problem:
even after rescaling back to the original dimensions, the wavelet
basis is _spatially shifted_ by a fractional amount with respect to
the original embedding grid, and shift sensitivity of the DWT means
that the recovered subband is essentially uncorrelated with the
embedded one.

The pattern across all four "non-noise" attacks is the same: the
attack acts coherently on the wavelet domain in a way that cannot be
counteracted by simply increasing $alpha$, because the attack does
not add noise to the watermarked coefficients but _replaces them_ with
attacked versions. Robust watermarking schemes mitigate this by
spreading the watermark across many coefficients with random signs
(_spread spectrum_, Cox et al. @cox1997) so that any one attack only
corrupts part of the embedded signal, and by adding error-correcting
codes (as in WaveMark @wang1999wavemark) so that the
remaining unattacked coefficients suffice to recover the watermark
bits.

== Limitations <sec:limitations>

Beyond the attack-robustness limitations exposed above, our scheme has
four further structural limitations worth naming. (i) It uses a
_single level_ of decomposition; in a multi-level decomposition the
watermark could be replicated across scales for redundancy. (ii) It
embeds into a _single subband_; spreading the watermark across all
three detail subbands would simultaneously raise capacity and improve
robustness against subband-selective attacks. (iii) It is _non-blind_;
in many real-world copyright disputes the original is unavailable.
(iv) It uses a _spatially uniform_ embedding strength $alpha$; a
perceptually-weighted $alpha$ that adapts to local luminance, contrast,
and texture masking would let the same total embedding energy hide
behind more of the image without being seen.

= Conclusions <sec:conclusions>

We have presented a complete reference implementation and study of
invisible image watermarking via additive embedding in a single subband
of the two-dimensional `db4` discrete wavelet transform. Our experiments
revealed three findings, each accompanied by a mathematical
explanation in @sec:discussion. First, there is a sharp embedding-
strength threshold $alpha^* = 1$ below which the watermark is destroyed
by the 8-bit pixel quantization, and we showed in
@sec:quantization-floor that this threshold can be derived in closed
form from the magnitude of the IDWT applied to a pure unit-amplitude
subband input. Second, the approximation subband `LL` simultaneously
minimizes mean-squared error and maximizes extraction correlation,
which we explained in @sec:why-ll using the energy-compaction property
of the wavelet transform; the explanation also clarifies why this
mathematical optimum is _not_ the perceptual optimum for hiding a
watermark. Third, the scheme is fragile against geometric and lossy
attacks, and we showed in @sec:why-attacks that this fragility is a
direct consequence of the spectral character of the attacks combined
with the shift-sensitivity of the DWT.

For a practitioner, the recommended operating point is
$alpha approx 5$ on the `LH` or `HL` subband: this configuration sits
just above the quantization floor, achieves PSNR around $40$ dB (well
within visually-indistinguishable territory), and gives a meaningful
extraction correlation of $approx 0.7$ in the absence of attacks.

Several directions for future work emerge naturally. _Multi-level_
embedding would distribute the watermark across scales and provide
redundancy against scale-selective attacks. _Biorthogonal_ wavelet
families such as the CDF 9/7 used in JPEG 2000 @jpeg2000 admit
symmetric synthesis filters and would reduce the edge artifacts that
limit perceptual quality. _Spread-spectrum_ and _quantization-index-
modulation_ embeddings @cox1997, @chen2001qim distribute each watermark
bit across many coefficients with pseudo-random signs and dramatically
improve robustness against the four lossy attacks where our scheme
fails. _Error-correcting codes_ on the watermark bitstream would give
graceful recovery from partial corruption. Finally, _perceptually-
weighted_ embedding using the contrast sensitivity function and
spatial-masking models would allow larger total embedding energy ---
and hence stronger robustness --- under the same imperceptibility
constraint.

// References are emitted by the template after this.

// ---------------- Appendix ----------------
//
// The full source code for the implementation is provided separately on
// external storage and is not reproduced here.

#pagebreak()
#set heading(numbering: "A.1")
#counter(heading).update(0)

= Full Result Tables <sec:appendix-tables>

The three CSV result files generated by the experiment scripts are
reproduced verbatim below as a reproducibility reference.

#set text(size: 9pt)
#set par(leading: 0.55em)

== Alpha sweep

#raw(read("/results/tables/alpha_sweep_metrics.csv"), lang: "csv", block: true)

== Subband comparison

#raw(read("/results/tables/subband_comparison_metrics.csv"), lang: "csv", block: true)

== Attack robustness

#raw(read("/results/tables/attack_robustness_metrics.csv"), lang: "csv", block: true)
