# Invisible Watermarking with 2D DWT

This project explores invisible image watermarking using the 2D Discrete Wavelet Transform (DWT). A binary watermark is embedded into a chosen wavelet subband of a grayscale image, and the reconstructed image is evaluated for both visual quality and watermark recoverability.

The project is set up to help answer these questions:

- How does embedding strength `alpha` affect image quality?
- Which wavelet subband gives the best results?
- How robust is the watermark under distortion attacks?

## Project Structure

- `src/embed.py`: basic watermark embedding demo
- `src/extract.py`: basic watermark extraction demo
- `src/alpha_sweep.py`: tests multiple `alpha` values and saves metric plots/tables
- `src/subband_comparison.py`: compares `LL`, `LH`, `HL`, and `HH`
- `src/attack_robustness.py`: tests watermark recovery after image attacks
- `src/watermark_utils.py`: shared helper functions
- `data/original/image.jpg`: host image
- `data/original/watermark.png`: watermark image
- `data/watermarked/`: output watermarked image(s)
- `results/images/`: saved visual outputs
- `results/plots/`: saved charts
- `results/tables/`: saved CSV tables

## Input Files

Before running the scripts, make sure these files exist:

- `data/original/image.jpg`
- `data/original/watermark.png`

Recommended watermark:

- black-and-white or grayscale
- simple text or logo
- high contrast
- not overly detailed

The code will resize the watermark automatically to match the selected wavelet subband.

## Setup

If your virtual environment still works, activate it and install dependencies:

```powershell
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If your current `venv` is broken because it points to an inaccessible Python installation, recreate it:

```powershell
py -3 -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Run all commands from the `invisible-watermarking-dwt` folder.

## Basic Workflow

### 1. Embed a watermark

```powershell
python .\src\embed.py
```

This:

- loads `image.jpg`
- applies a 2D DWT with `db4`
- embeds the watermark into the `LH` subband
- reconstructs the image
- saves the watermarked image
- prints `MSE` and `PSNR`

### 2. Extract the watermark

```powershell
python .\src\extract.py
```

This:

- loads the original and watermarked images
- applies the DWT again
- estimates the embedded watermark
- saves the extracted watermark image
- prints the correlation coefficient

## Experiment Scripts

### Alpha Sweep

```powershell
python .\src\alpha_sweep.py
```

Purpose:

- tests different embedding strengths
- measures `MSE`, `PSNR`, and correlation
- saves a CSV table and report-ready plots

Outputs:

- `results/tables/alpha_sweep_metrics.csv`
- `results/plots/alpha_sweep_metrics.png`
- `results/images/alpha_sweep_grid.png`

Use this when you want to study the tradeoff between invisibility and robustness.

### Subband Comparison

```powershell
python .\src\subband_comparison.py
```

Purpose:

- embeds the watermark into `LL`, `LH`, `HL`, and `HH`
- compares distortion and recovery quality across subbands

Outputs:

- `results/tables/subband_comparison_metrics.csv`
- `results/plots/subband_comparison_metrics.png`
- `results/images/subband_comparison_grid.png`

Use this when you want to answer which wavelet subband gives the best balance.

### Attack Robustness

```powershell
python .\src\attack_robustness.py
```

Purpose:

- embeds the watermark
- applies several attacks to the watermarked image
- measures how well the watermark can still be extracted

Current attacks:

- no attack
- Gaussian noise
- Gaussian blur
- JPEG compression
- resizing
- cropping and resizing

Outputs:

- `results/tables/attack_robustness_metrics.csv`
- `results/plots/attack_robustness_metrics.png`
- `results/images/attack_robustness_extractions.png`

Use this when you want to evaluate robustness under distortion.

## Important Parameters

The main parameters you may want to adjust are:

- `alpha`:
  embedding strength
- `subband_name`:
  one of `LL`, `LH`, `HL`, `HH`
- `wavelet`:
  currently set to `db4`

In general:

- smaller `alpha` gives better image quality but weaker recovery
- larger `alpha` gives stronger recovery but more visible distortion
- `LL` often affects the image more strongly
- `LH`, `HL`, and `HH` are usually less visually intrusive

## Suggested Order for Your Final Project

1. Run `embed.py` and `extract.py` once to verify the pipeline.
2. Run `alpha_sweep.py` to choose a reasonable `alpha`.
3. Run `subband_comparison.py` to compare the wavelet subbands.
4. Run `attack_robustness.py` to evaluate robustness.
5. Use the saved tables and plots in your report.

## Interpreting the Results

- `MSE`:
  lower is better
- `PSNR`:
  higher is better
- `Correlation`:
  higher means the extracted watermark is more similar to the original watermark

A good project discussion usually focuses on the tradeoff:

- invisible watermarking prefers low distortion
- robust watermarking prefers stronger embedding
- the best choice is usually a compromise

## Notes

- The code currently uses the Daubechies-4 wavelet (`db4`).
- The watermark image is converted to a binary image internally.
- The scripts are designed for grayscale images.
- If you want to compare Haar and Daubechies later, you can change the wavelet name from `db4` to `haar` in the experiment scripts and compare the outputs.
