# Eaton Fire Ash Geochemical Characterization

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-4.5+-blue.svg)](https://www.r-project.org/)

Multi-modal geochemical and spectroscopic characterization of wildland-urban interface (WUI) fire ash from the 2025 Eaton Fire, Los Angeles County, California.

## Overview

This repository contains analysis code and outputs for characterizing trace metal contamination in WUI fire ash using:
- **ICP-MS**: Ground truth elemental concentrations
- **Portable XRF**: Field-deployable proxy validation
- **FTIR-ATR**: Infrared spectroscopic characterization
- **ASD FieldSpec**: Visible-near infrared reflectance spectroscopy
- **AVIRIS-NG**: Airborne imaging spectroscopy

## Key Findings

1. **Elevated Metal Concentrations**: WUI ash contains trace metals (Pb, Zn, Cu, As) exceeding EPA residential soil screening levels
2. **XRF Validation**: Portable XRF correlates strongly with ICP-MS (r > 0.92) but shows systematic offset (-92% to -120%)
3. **Matrix Effects**: XRF-derived organic proxy (100 - oxide sum) predicts offset magnitude (r = 0.53-0.67, p < 0.01)
4. **Spectral Limitations**: FTIR and ASD proxies show weak correlations after outlier removal (r ≈ 0.26-0.28, ns)

## Repository Structure

```
├── README.md                    # This file
├── LICENSE                      # MIT License
├── MANUSCRIPT_ROADMAP.md        # Detailed manuscript preparation guide
├── SATM_REVISED.md              # Science & Analysis Traceability Matrix
│
├── scripts/                     # R analysis scripts
│   ├── 01_data_harmonization.R
│   ├── 02_spectral_processing.R
│   ├── 03_aviris_extraction.R
│   ├── 04_psq1_spatial_analysis.R
│   ├── 05_psq2_spectral_prediction.R
│   ├── 06_psq3_ftir_analysis.R
│   ├── 07_qgis_layers.R
│   ├── 08_publication_figures.R
│   ├── 09_elemental_ratios_enrichment.R
│   ├── 10_enrichment_factor_analysis.R
│   ├── 11_multispectral_mineral_proxies.R
│   ├── 12_xrf_icpms_validation.R
│   ├── 13_spectral_xrf_validation.R
│   ├── 14_spectral_organic_proxies.R
│   ├── 15_ftir_organic_proxies.R
│   ├── 16_ftir_diagnostic_analysis.R
│   └── 17_ftir_reanalysis_cleaned.R
│
├── data/                        # Processed data files
│   ├── df_master_aviris.csv     # Master dataset
│   ├── ftir_organic_features.csv
│   ├── asd_organic_features.csv
│   ├── table*_*.csv             # Analysis output tables
│   └── ...
│
├── figures/                     # Generated figures
│   ├── Fig1_study_area.*
│   ├── Fig2_metal_concentrations.*
│   ├── Fig3_spatial_distribution.*
│   ├── Fig4_correlation_heatmap.*
│   ├── Fig5_xrf_validation.*
│   └── ...
│
├── qgis/                        # QGIS project files
│   └── ...
│
└── docs/                        # Documentation
    ├── ANALYTICAL_FRAMEWORK.md
    ├── ANALYSIS_SUMMARY.md
    └── MANUSCRIPT_PROPOSAL.md
```

## Analytical Framework

### Science Questions

| PSQ | Question | Primary Data |
|-----|----------|--------------|
| PSQ-1 | What are trace metal concentrations relative to regulatory thresholds? | ICP-MS |
| PSQ-2 | How effectively does portable XRF serve as a field proxy? | XRF + ICP-MS |
| PSQ-3 | What matrix factors affect XRF-ICP-MS agreement? | XRF majors |
| PSQ-4 | What mineral phases are present in WUI ash? | FTIR, XRF |

### Data Hierarchy

```
Level 1 (Ground Truth): ICP-MS elemental concentrations
         ↓
Level 2 (Field Proxy): XRF screening with correction models
         ↓
Level 3 (Supporting): Spectral characterization (FTIR, ASD, AVIRIS)
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `04_psq1_spatial_analysis.R` | ICP-MS characterization, spatial statistics |
| `12_xrf_icpms_validation.R` | XRF-ICP-MS method comparison, Bland-Altman |
| `16_ftir_diagnostic_analysis.R` | Outlier detection, multicollinearity assessment |
| `17_ftir_reanalysis_cleaned.R` | Cleaned proxy comparison (XPAH26 excluded) |

## Key Outputs

### Tables

| Table | Description | File |
|-------|-------------|------|
| Table 2 | ICP-MS summary statistics | `table2_summary_stats.csv` |
| Table 3 | EPA RSL exceedance summary | `table3_epa_exceedance.csv` |
| Table 4 | XRF-ICP-MS regression | `table4_xrf_regression.csv` |
| Table 5 | Bland-Altman statistics | `table5_bland_altman.csv` |
| Table 11 | Cleaned proxy correlations | `table11_proxy_correlations_cleaned.csv` |

### Figures

| Figure | Description |
|--------|-------------|
| Figure 1 | Study area map |
| Figure 2 | Metal concentrations vs EPA RSLs |
| Figure 3 | Spatial distribution with hotspots |
| Figure 4 | Inter-element correlation heatmap |
| Figure 5 | XRF-ICP-MS validation |
| Figure 10 | FTIR diagnostic analysis |
| Figure 11 | Cleaned organic proxy comparison |

## Requirements

### R Packages

```r
# Core
install.packages(c("tidyverse", "sf", "terra"))

# Visualization
install.packages(c("patchwork", "ggrepel", "viridis"))

# Spatial analysis
install.packages(c("spdep", "gstat"))

# Statistics
install.packages(c("MASS", "caret"))
```

### System Requirements

- R ≥ 4.5.0
- GDAL/GEOS for spatial operations
- ~2 GB disk space for data and outputs

## Usage

1. Clone the repository:
```bash
git clone https://github.com/[username]/Eaton-Fire-Ash.git
cd Eaton-Fire-Ash
```

2. Run analyses in sequence:
```bash
Rscript scripts/01_data_harmonization.R
Rscript scripts/04_psq1_spatial_analysis.R
Rscript scripts/12_xrf_icpms_validation.R
# ... etc
```

3. Or run all analyses:
```bash
for script in scripts/*.R; do Rscript "$script"; done
```

## Data Availability

- **Raw spectral data**: Available upon request
- **Processed datasets**: Included in `data/` directory
- **AVIRIS-NG imagery**: NASA/JPL AVIRIS data portal

## Citation

If you use this code or data, please cite:

```
[Author names]. (2025). Trace Metal Contamination in Wildland-Urban Interface
Fire Ash: Multi-Modal Characterization and Field Proxy Validation.
[Journal]. DOI: [pending]
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Principal Investigator**: [Name]
- **Email**: [email]
- **Institution**: [Institution]

## Acknowledgments

- NASA/JPL for AVIRIS-NG data
- [Funding agency] for support
- Field sampling team

---

*Last updated: December 4, 2025*
