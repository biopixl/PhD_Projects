# Sample ID Harmonization Guide

## Overview

This guide documents the sample identification system for the Eaton Fire Ash XRF/ICP-MS dataset, enabling consistent data merging across analytical platforms.

## File Inventory

| File | Description | Rows | Key Columns |
|------|-------------|------|-------------|
| `XRF_elements_clean.csv` | XRF element concentrations (cleaned) | 2,304 | sample_id, method, element, value |
| `XRF-Pb_clean.csv` | XRF Pb emission lines (cleaned) | 754 | sample_id, method, line_symbol, cts_per_s |
| `sample_id_harmonization.csv` | Sample cross-reference table | 49 | Base_ID, ICPMS_ID, XRF_powder, XRF_pellet |
| `PBP_calibration_samples.csv` | Clay calibration standards | 24 | Base_ID, Series, Prep, Replicate |
| `../ICPMS/EFA_ICPMS_PPM.xlsx` | ICP-MS concentrations (ppm) | 42 | EFA.ID, EFA.ID.XRF, EFA.ID.ICPMS |

## Sample ID Naming Conventions

### Ash/Soil Samples (Field Collected)

| Prefix | Description | Example |
|--------|-------------|---------|
| `JPL##` | JPL campus locations | JPL06, JPL73 |
| `GPS##` | GPS-marked locations | GPS03, GPS09 |
| `XPAH##` | X-ray accessible samples | XPAH20, XPAH28 |
| `####` | Address-based IDs | 1590, 1620 |

### Calibration Standards (PBP Series)

Format: `PBP0{series}_{prep}_{replicate}`

| Component | Values | Description |
|-----------|--------|-------------|
| Series | 01, 02, 03, 04 | Pb concentration level |
| Prep | pellet, powder | Sample preparation method |
| Replicate | A/B/C (pellet), 1/2/3 (powder) | Measurement replicate |

Examples: `PBP01_pellet_A`, `PBP03_powder_2`

### XRF ID Suffixes (Legacy)

The ICP-MS file contains legacy XRF IDs with suffixes:

| Suffix | Meaning |
|--------|---------|
| `_bkB` | Bulk sample |
| `_bkB.S` | Bulk sample, sieved |
| `_bkB.S.A` | Bulk sample, sieved, aliquot A |

**For harmonization: Strip suffixes and use Base_ID only.**

## Sample Coverage Summary

| Status | Count | Description |
|--------|-------|-------------|
| COMPLETE | 24 | ICP-MS + XRF powder + XRF pellet |
| PARTIAL | 12 | ICP-MS + some XRF (missing powder or pellet) |
| ICPMS_ONLY | 6 | No XRF data available |
| XRF_ONLY | 7 | No ICP-MS reference data |

### Samples Missing XRF Data
- 1601, 1637, 1643, 1648, GPS02, XPAH17

### Samples Missing ICP-MS Data
- 1606, 1639, 1642, JPL28, JPL40, JPL52, JPL94

### SOIL Samples (Separate Analysis Required)
- 1637, 1643, 1648, XPAH55

## Harmonization Workflow

### Step 1: Load Data
```r
library(tidyverse)

xrf_elem <- read_csv("XRF_elements_clean.csv")
xrf_pb <- read_csv("XRF-Pb_clean.csv")
sample_map <- read_csv("sample_id_harmonization.csv")
```

### Step 2: Join Using Base_ID
```r
# Filter to pellet preparations for ICP-MS comparison
xrf_pellet <- xrf_elem %>%
  filter(method == "pellet") %>%
  rename(Base_ID = sample_id)

# Join with harmonization table
harmonized <- sample_map %>%
  filter(Status %in% c("COMPLETE", "PARTIAL")) %>%
  left_join(xrf_pellet, by = "Base_ID")
```

### Step 3: Merge with ICP-MS
```r
icpms <- readxl::read_excel("../ICPMS/EFA_ICPMS_PPM.xlsx", skip = 1) %>%
  mutate(Base_ID = as.character(EFA.ID))

final <- harmonized %>%
  left_join(icpms, by = "Base_ID")
```

## Data Quality Notes

1. **Preparation Methods**: XRF pellet data should be compared to ICP-MS (both use pressed pellets)
2. **Powder vs Pellet**: Powder preparations may show different matrix effects
3. **Pb Lines**: Use Pb_La1 (10.55 keV) as primary intensity for calibration
4. **Error Columns**: All XRF measurements include associated errors
5. **Units**: XRF concentrations in % or ppm; ICP-MS in ppm

## PBP Calibration Standards

| Series | Approximate Pb (ppm) | Purpose |
|--------|---------------------|---------|
| PBP01 | ~100 | Low concentration |
| PBP02 | ~500 | Medium-low |
| PBP03 | ~1000 | Medium-high |
| PBP04 | ~50 | Near detection limit |

All 24 PBP samples (4 series × 3 pellet + 3 powder replicates) have complete XRF data.

## Contact

For questions about sample preparation or analysis methods, refer to the manuscript methods section or contact the corresponding author.
