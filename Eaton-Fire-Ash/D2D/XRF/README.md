# XRF Pb Calibration: 4-Model Comparison Workflow

## Overview

Systematic comparison of 4 XRF calibration methods for detecting Pb in wildfire ash, validated against ICP-MS.

## Model Comparison Summary

| Model | Preparation | Response | Cal R² | Val r | RMSE (ppm) | Sensitivity | Rank |
|-------|-------------|----------|--------|-------|------------|-------------|------|
| **Pellet + Intensity** | Pellet | Emission | 0.998 | 0.998 | **213** | **100%** | **1** |
| Pellet + FP | Pellet | FP Conc. | 0.995 | 0.991 | 1880 | 83% | 2 |
| Powder + Intensity | Powder | Emission | 0.913 | 0.929 | 1470 | 100% | 3 |
| Powder + FP | Powder | FP Conc. | 0.920 | 0.992 | 1493 | 100% | 4 |

## Optimal Method: Pellet + Intensity Calibration

```
[Pb]ash = (Pb_Lα₁_Intensity - 47.2) / 0.60
```

**Performance**: r = 0.998, RMSE = 213 ppm, 100% sensitivity/specificity at EPA RSL (400 ppm)

## Directory Structure

```
XRF/
├── data/
│   ├── raw/                     # Original XRF files
│   ├── cleaned/                 # Harmonized data
│   ├── calibration/             # PBP clay standards
│   │   ├── PBP_calibration_detailed.csv
│   │   └── Pb_clay_calibration_complete.csv
│   └── validation/              # ICP-MS validation
│       └── Pb_predictions_corrected.csv
├── figures/main/
│   ├── Fig_Pb_calibration_main.*        # Clay calibration curves
│   ├── Fig_Pb_intensity_calibration_validation.*  # ICP-MS validation
│   └── Fig_model_comparison_facet.*     # 4-model comparison
├── results/
│   └── model_comparison_summary.csv     # Summary table
├── docs/                        # Protocols & guides
├── archive/                     # Previous iterations
└── README.md
```

## Key Findings

1. **Pellet > Powder**: Better precision (CV 7.5% vs 9.3%) and calibration fit
2. **Intensity > FP**: Matrix-corrected intensity achieves 9× lower RMSE than FP
3. **Correction Essential**: Clay calibration underestimates Pb in ash by ~70%

## Field Screening Decision

| XRF Prediction | Priority | Action |
|----------------|----------|--------|
| < 200 ppm | Low | Routine monitoring |
| 200-400 ppm | Medium | Confirm with lab analysis |
| > 400 ppm | High | Exceeds EPA residential RSL |
| > 800 ppm | Critical | Exceeds EPA industrial RSL |
