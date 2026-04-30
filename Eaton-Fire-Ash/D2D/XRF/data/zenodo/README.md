# Eaton Fire Ash — Zenodo Deposit

Final, publication-ready datasets for the manuscript *"Rapid detection of metal
contamination in ash on outdoor surfaces after the 2025 Eaton Fire in a
Wildland-Urban Interface."*

## Files

| File | Format | Rows | Purpose |
|------|--------|------|---------|
| `EFA_ICPMS_PPM.csv` | wide CSV | 42 samples | ICP-MS reference concentrations (>50 elements) |
| `EFA_XRF_Ash.csv` | wide CSV | 83 measurements | XRF Pb data per sample × method (pellet/powder), with calibrated `Pb_prediction` |
| `EFA_XRF_Ash_Metadata.csv` | wide CSV | 44 samples | Sample inventory linking ICP-MS, XRF pellet, and XRF powder identifiers with location and measurement dates |
| `EFA_XRF_Clay_Metadata.csv` | wide CSV | 24 standards | PBP01–PBP04 kaolinite-clay calibration standards with measured Pb intensities and LOOCV predictions |
| `EFA_XRF.xls` | Excel | — | Master Excel workbook (analyst-facing source for the CSVs) |

## Schema notes

### `EFA_ICPMS_PPM.csv`
Sample identifier: `EFA.ID`. Concentrations in ppm. The `EFA.ID.XRF` and
`EFA.ID.ICPMS` columns record the specific aliquot identifiers used by each
instrument; `alq.type` is `ASH` or `SOIL`; `Lat`/`Lon` in WGS84 decimal degrees.

### `EFA_XRF_Ash.csv`
One row per (sample, prep method) measurement. Columns:

- `ID`, `method` — sample identifier and prep method (`pellet` or `powder`)
- `Pb_La1_cps` … `Pb_Lb4_cps` and matching `_err_cps` — net peak intensity in
  counts per second for each Pb L-line and its uncertainty
- `Pb_FP_ppm`, `Pb_FP_err` — fundamental-parameters concentration estimate
  reported by the instrument software (uncalibrated)
- `Pb_prediction` — Pb concentration in ppm predicted by the calibrated
  intensity model for the matching prep method (pellet → pellet-intensity
  arm; powder → powder-intensity arm). Source: `D2D/XRF/data/validation/
  ash_predicted_Pb.csv`.

### `EFA_XRF_Ash_Metadata.csv`
Sample inventory cross-walking analytical platforms:

- `ID`, `EFA.ID`, `EFA.ID.XRF`, `EFA.ID.ICPMS` — sample identifiers across
  workflows. `NA` indicates the sample wasn't measured on that platform.
- `alq.type`, `Lat`, `Lon` — sample type and WGS84 location
- `xrf-powder-date`, `xrf-pellet-date` — measurement date(s) per prep method
  (`MM/DD/YY`); `NA` if no measurement on file
- `icpms-date` — ICP-MS measurement date

### `EFA_XRF_Clay_Metadata.csv`
PBP01–PBP04 kaolinite-clay calibration standards:

- `ID`, `method`, `Series` — standard identifier (e.g., PBP01_pellet_A)
- `Known_Pb_ppm` — certified Pb concentration (0, 100, 500, 1000 ppm)
- `FP_value_ppm`, `FP_value_err_ppm` — instrument FP-derived concentration
- `Pb_La1_cps` … `Pb_Lb4` and `_err` columns — per-line emission intensities
- `Pred_Pb_ppm` — leave-one-out cross-validated prediction from the
  intensity calibration model
- `Error` — signed residual (`Pred_Pb_ppm` − `Known_Pb_ppm`)

## Reproducibility

The full statistical pipeline — clay calibration on the PBP standards,
ash-matrix correction with Cook's-distance outlier handling and LOOCV
slope, validation against ICP-MS, Bland-Altman agreement, and the
six-threshold classification matrix — runs end-to-end from the four
files in this folder via a single R script:

```
Rscript D2D/XRF/scripts/eaton_xrf_pipeline.R
```

The script writes Tables~3 and~4 to `D2D/XRF/results/` and the
calibration / validation / Bland-Altman 4-panel figures to
`D2D/XRF/figures/`. No intermediate files are produced. The same script
recomputes the `Pb_prediction` column in `EFA_XRF_Ash.csv` and the
`Pred_Pb_ppm` / `Error` columns in `EFA_XRF_Clay_Metadata.csv` so the
deposit stays in sync with the analysis.

For the full multi-element ICP-MS data and per-line XRF intensities
beyond Pb, use the long-format inputs in `D2D/XRF/data/cleaned/` —
those are the working files the helper Python scripts in
`D2D/XRF/scripts/` produce from the raw instrument exports
(`parse_xrf_data.py`, `extract_xrf_raw_counts.py`,
`clean_xrf_raw_to_d2d.py`, `build_xrf_metadata.py`).

## Contact

Isaac N. Aguilar, Caltech (`iaguilar@caltech.edu`)
