# Science and Analysis Traceability Matrix (SATM)
## Eaton Fire Ash Geochemical Characterization

**Date:** December 4, 2025
**Status:** Reevaluation Draft

---

## Revised Conceptual Framework

### Analytical Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 1: GROUND TRUTH                                              │
│  ICP-MS Elemental Concentrations                                    │
│  - Acid-extractable metal concentrations (ppm)                      │
│  - Reference standard for all other measurements                    │
│  - Regulatory comparison (EPA RSLs)                                 │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 2: MATRIX-DEPENDENT PROXY                                    │
│  XRF Major/Trace Elements                                           │
│  - Total element abundance (matrix-dependent)                       │
│  - Requires statistical evaluation of ICP-MS agreement              │
│  - Matrix effects from organic content, mineralogy                  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 3: COMPOSITIONAL PROXIES                                     │
│  Spectral Data (ASD, FTIR, AVIRIS)                                  │
│  - Indirect indicators of ash composition                           │
│  - Validate/explain XRF-ICP-MS discrepancies                        │
│  - Characterize matrix effects (organics, mineralogy)               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Primary Science Questions (Revised)

| PSQ | Question | Hierarchy Level |
|-----|----------|-----------------|
| **PSQ-1** | What are the elemental concentrations in Eaton Fire ash and how do they compare to regulatory thresholds? | Level 1 (ICP-MS) |
| **PSQ-2** | How well does XRF serve as a field-deployable proxy for ICP-MS, and what matrix factors affect measurement agreement? | Level 1→2 (ICP-MS↔XRF) |
| **PSQ-3** | Can spectral proxies characterize ash composition and validate/explain XRF measurement variability? | Level 2→3 (XRF↔Spectral) |

---

## SATM: PSQ-1 — Elemental Characterization (Ground Truth)

### Objective
Characterize elemental concentrations in WUI ash using ICP-MS as the reference analytical method.

| Science Objective | Measurement | Data Source | Analysis Method | Output |
|-------------------|-------------|-------------|-----------------|--------|
| SO-1.1: Quantify metal concentrations | 60+ elements (ppm) | ICP-MS | Descriptive statistics | Table: Summary stats (mean, median, IQR, range) |
| SO-1.2: Assess regulatory exceedance | Pb, As, Cd, Cr, Cu, Ni, Zn, Mn | ICP-MS vs EPA RSL | Threshold comparison | Table: Exceedance rates, factors |
| SO-1.3: Characterize spatial distribution | Metal concentrations + GPS | ICP-MS + field GPS | Moran's I, Getis-Ord Gi* | Maps: Hotspot analysis |
| SO-1.4: Identify inter-element associations | All metals | ICP-MS | Correlation matrix, PCA | Figure: Correlation heatmap |

### Key Outputs (PSQ-1)
- **Table 1:** Sample metadata and analytical coverage
- **Table 2:** ICP-MS summary statistics (n, mean, median, IQR, range)
- **Table 3:** EPA RSL exceedance summary
- **Figure 1:** Study area map with sample locations
- **Figure 2:** Metal concentration boxplots with RSL reference lines
- **Figure 3:** Spatial distribution maps with hotspot overlay
- **Figure 4:** Inter-element correlation heatmap

### Status
| Output | Script | File | Status |
|--------|--------|------|--------|
| Table 2 | 04_psq1_spatial_analysis.R | data/table2_summary_stats.csv | ✅ Complete |
| Table 3 | 04_psq1_spatial_analysis.R | data/table3_epa_exceedance.csv | ✅ Complete |
| Figure 1 | 08_publication_figures.R | figures/Fig1_study_area.pdf | ✅ Complete |
| Figure 2 | 08_publication_figures.R | figures/Fig2_metal_concentrations.pdf | ✅ Complete |
| Figure 3 | 04_psq1_spatial_analysis.R | figures/Fig3_spatial_distribution.pdf | ✅ Complete |
| Figure 4 | 08_publication_figures.R | figures/Fig4_correlation_heatmap.pdf | ✅ Complete |
| Moran's I | 04_psq1_spatial_analysis.R | data/moran_spatial_autocorrelation.csv | ✅ Complete |

---

## SATM: PSQ-2 — XRF as Field Proxy (Statistical Evaluation)

### Objective
Evaluate XRF as a matrix-dependent proxy for ICP-MS and quantify factors affecting measurement agreement.

| Science Objective | Measurement | Data Source | Analysis Method | Output |
|-------------------|-------------|-------------|-----------------|--------|
| SO-2.1: Quantify XRF-ICP-MS correlation | Pb, Zn, Cu (paired) | XRF + ICP-MS | Pearson r, linear regression | Table: Correlation coefficients, slopes |
| SO-2.2: Characterize systematic offset | Log ratio ICP-MS/XRF | XRF + ICP-MS | Descriptive stats, Bland-Altman | Figure: Method comparison plots |
| SO-2.3: Identify matrix effects | Offset vs composition | XRF majors + ratio | Correlation, regression | Table: Matrix effect correlations |
| SO-2.4: Develop correction factors | Offset ~ matrix predictors | XRF + ICP-MS | Multiple regression | Equation: Correction model |

### Matrix Factors to Evaluate
| Factor | Proxy | Expected Effect | Rationale |
|--------|-------|-----------------|-----------|
| Organic/volatile content | 100 - oxide sum (%) | ↓ XRF relative to ICP-MS | Mass absorption, volatilization |
| Fe-oxide content | Fe₂O₃ (%) | ↑ XRF relative to ICP-MS | Secondary fluorescence |
| Silicate content | SiO₂/Al₂O₃ | Variable | Lower mass absorption |
| Clay content | Al₂O₃/SiO₂ | ↑ XRF relative to ICP-MS | Surface adsorption effects |
| Calcium carbite | CaO/SiO₂ | Variable |Ite mineralogy |

### Key Outputs (PSQ-2)
- **Table 4:** XRF-ICP-MS correlation and regression statistics
- **Table 5:** Matrix effect correlations (offset vs. composition)
- **Figure 5:** XRF vs ICP-MS scatter plots with regression
- **Figure 6:** Bland-Altman (method agreement) plots
- **Figure 7A:** Log ratio distributions by metal
- **Figure 7B:** Offset vs. organic content relationship

### Status
| Output | Script | File | Status |
|--------|--------|------|--------|
| XRF-ICP-MS correlation | 12_xrf_icpms_validation.R | data/table4_xrf_regression.csv | ✅ Complete |
| Bland-Altman statistics | 12_xrf_icpms_validation.R | data/table5_bland_altman.csv | ✅ Complete |
| Matrix correlations | 12_xrf_icpms_validation.R | data/table_matrix_effect_correlations.csv | ✅ Complete |
| Correction model | 12_xrf_icpms_validation.R | data/table_xrf_correction_model.csv | ✅ Complete |
| Figure 5 (XRF validation) | 12_xrf_icpms_validation.R | figures/Fig5_xrf_validation.pdf | ✅ Complete |

### Key Findings (Updated)
- **Correlation:** Pb r=0.992 (R²=0.983), Zn r=0.997 (R²=0.994), Cu r=0.921 (R²=0.848)
- **Systematic offset:** ICP-MS ~18-25% of XRF values (median ratios: Pb=0.18, Zn=0.25, Cu=0.22)
- **Bland-Altman bias:** Pb=-120%, Zn=-92%, Cu=-114% (ICP-MS lower than XRF)
- **Matrix effects:**
  - Organic content: r = 0.58 (Pb), 0.35 (Zn) — higher organics → smaller offset
  - Fe-oxide: r = -0.55 (Pb), -0.53 (Zn) — higher Fe → larger offset
  - Silicate: r = 0.58 (Pb) — higher silicate → smaller offset
- **Correction model performance:**
  - Pb: R² = 0.920, RMSE reduced by 64%
  - Zn: R² = 0.957, RMSE reduced by 96%
  - Cu: R² = 0.862, RMSE reduced by 41%

---

## SATM: PSQ-3 — Spectral Validation of XRF (Compositional Proxies)

### Objective
Use spectral data to characterize ash composition and validate/explain XRF measurement variability.

| Science Objective | Measurement | Data Source | Analysis Method | Output |
|-------------------|-------------|-------------|-----------------|--------|
| SO-3.1: Derive compositional proxies | Spectral indices | ASD, FTIR, AVIRIS | Feature extraction | Table: Spectral proxy definitions |
| SO-3.2: Correlate proxies with XRF | Spectral vs XRF majors | ASD + XRF | Correlation matrix | Figure: Proxy validation heatmap |
| SO-3.3: Explain XRF-ICP-MS offset | Offset vs spectral proxies | All datasets | Multiple regression | Table: Spectral predictors of offset |
| SO-3.4: Characterize mineral phases | Spectral features | FTIR, ASD | Band assignment | Table: Mineral identification |

### Spectral Proxies Available

| Proxy | Source | Derivation | Target Property |
|-------|--------|------------|-----------------|
| Char_index | ASD | Overall albedo inverse | Organic/char content |
| Charash_fraction | AVIRIS | Spectral unmixing | Char abundance |
| Fe_index | ASD | 530nm/670nm depth ratio | Fe-oxide content |
| Carbonate_index | ASD | 2300nm depth | Carbonate content |
| Carbonate_proxy | XRF | CaO/SiO₂ | Calcite abundance |
| FeOx_proxy | XRF | Fe₂O₃% | Fe-oxide abundance |
| Silicate_proxy | XRF | SiO₂/Al₂O₃ | Silicate vs clay |
| Organic_proxy | XRF | 100 - oxide sum | Volatile/organic content |

### Key Outputs (PSQ-3)
- **Table 6:** Spectral proxy correlation with XRF composition
- **Table 7:** Spectral predictors of XRF-ICP-MS offset
- **Figure 7C:** Multi-source proxy correlation heatmap
- **Figure 7D:** ASD char index vs metal concentration
- **Figure 8:** Spectral-XRF validation scatter plots

### Status
| Output | Script | File | Status |
|--------|--------|------|--------|
| Proxy correlations | 11_multispectral_mineral_proxies.R | data/multispectral_proxy_correlations.csv | ✅ Complete |
| Spectral-XRF validation | 13_spectral_xrf_validation.R | data/table6_spectral_xrf_validation.csv | ✅ Complete |
| Spectral offset predictors | 13_spectral_xrf_validation.R | data/table7_spectral_offset_correlations.csv | ✅ Complete |
| Figure 6 (Spectral-XRF) | 13_spectral_xrf_validation.R | figures/Fig6_spectral_xrf_validation.pdf | ✅ Complete |
| FTIR mineral ID | 06_psq3_ftir_analysis.R | — | ⚠️ Partial |

### Key Findings (Updated)
- **Validated proxy pairs:**
  - ASD Fe_index vs XRF Fe₂O₃: r = 0.509 ✅
  - ASD Depth_1900nm vs XRF Clay: r = 0.476 ✅
- **Weak/Invalid proxy pairs:**
  - ASD Char_darkness vs XRF Organic: r = 0.006 ❌ (NO correlation)
  - AVIRIS Charash vs XRF Organic: r = -0.111 ❌
  - ASD Carbonate_index vs XRF Carbonate: r = 0.120 (weak)

**CRITICAL FINDING: XRF is NOT a reliable proxy for organic content**
- ASD Char_darkness shows NO correlation with XRF organic proxy (r = 0.006)
- This confirms XRF (100 - oxide sum) does not measure organic/char content

### Improved Spectral Organic Proxies (Script 14)
| Proxy | Description | Pb Offset r | Performance |
|-------|-------------|-------------|-------------|
| Vis_slope | Visible slope 450-700nm | -0.488 | **Best** |
| Organic_index_1 | Vis_slope × (1-albedo) | -0.481 | Excellent |
| Organic_index_2 | 1 - (R450/R650) | -0.481 | Excellent |
| Char_darkness | 1 - mean reflectance | 0.394 | Good |
| Blue_slope | Blue slope 400-550nm | -0.372 | Good |
| XRF_organic | 100 - oxide sum | 0.211 | **Poor** |

- **Spectral proxies outperform XRF** for predicting matrix effects on XRF-ICP-MS offset
- **Key insight:** ASD visible slope is the best indicator of organic/char content affecting XRF accuracy

---

## Gap Analysis

### Completed Analyses

| Analysis | Priority | Script | Status |
|----------|----------|--------|--------|
| Bland-Altman plots | High | 12_xrf_icpms_validation.R | ✅ Complete |
| XRF correction model | High | 12_xrf_icpms_validation.R | ✅ Complete |
| Spectral-XRF cross-validation | Medium | 13_spectral_xrf_validation.R | ✅ Complete |

### Remaining Gaps

| Gap | Priority | Required Data | Proposed Analysis |
|-----|----------|---------------|-------------------|
| FTIR mineral quantification | Medium | FTIR spectra | Peak fitting, mineral abundance |
| Detection limit analysis | Low | XRF + ICP-MS | Evaluate XRF LOD for trace metals |
| Uncertainty propagation | Low | All | Monte Carlo error estimation |

### Manuscript Structure Revision

| Current Structure | Revised Structure | Rationale |
|-------------------|-------------------|-----------|
| PSQ-1: Contamination + Spatial | PSQ-1: ICP-MS Characterization | Ground truth first |
| PSQ-2: Spectral Prediction | PSQ-2: XRF Proxy Evaluation | XRF as field proxy |
| PSQ-3: Mineral Associations | PSQ-3: Spectral Validation | Spectral supports XRF |
| Enrichment Factors (Section 3.3) | Move to Discussion | Interpretive, not primary |
| Source Apportionment | Remove | Lacks direct evidence |

---

## Revised Manuscript Outline

### Abstract (250 words)
- WUI ash contamination context
- ICP-MS characterization (RSL exceedances)
- XRF as field proxy (correlation, matrix effects)
- Spectral validation (compositional proxies)
- Implications for rapid assessment

### 1. Introduction
- WUI fire contamination risks
- Need for rapid field assessment
- Analytical hierarchy: ICP-MS → XRF → Spectral
- Science questions (revised PSQ-1, 2, 3)

### 2. Methods
- 2.1 Study area
- 2.2 Sample collection
- 2.3 ICP-MS analysis (reference method)
- 2.4 XRF analysis (field proxy)
- 2.5 Spectral measurements (ASD, FTIR, AVIRIS)
- 2.6 Statistical analysis
  - Descriptive statistics
  - XRF-ICP-MS comparison (correlation, Bland-Altman)
  - Matrix effect analysis
  - Spatial statistics

### 3. Results
- **3.1 ICP-MS Elemental Characterization (PSQ-1)**
  - Concentration distributions
  - EPA RSL exceedances
  - Spatial patterns (Moran's I, hotspots)
  - Inter-element correlations

- **3.2 XRF as Field Proxy (PSQ-2)**
  - XRF-ICP-MS correlation statistics
  - Systematic offset characterization
  - Matrix effects on measurement agreement
  - Correction factor development

- **3.3 Spectral Validation (PSQ-3)**
  - Spectral proxy derivation
  - Correlation with XRF composition
  - Explanation of XRF-ICP-MS variability
  - Mineral phase identification

### 4. Discussion
- 4.1 Contamination implications (regulatory context)
- 4.2 XRF field deployment considerations
- 4.3 Spectral remote sensing potential
- 4.4 Limitations and uncertainty
- 4.5 Recommendations for rapid WUI assessment

### 5. Conclusions

---

## Action Items

### Completed
| Priority | Task | Script | Status |
|----------|------|--------|--------|
| **1** | Create Bland-Altman plots for XRF-ICP-MS | 12_xrf_icpms_validation.R | ✅ Complete |
| **2** | Develop XRF correction regression model | 12_xrf_icpms_validation.R | ✅ Complete |
| **4** | Add spectral-XRF cross-validation | 13_spectral_xrf_validation.R | ✅ Complete |

### Remaining
| Priority | Task | Effort | Dependencies |
|----------|------|--------|--------------|
| **3** | Reorganize manuscript to revised outline | 3 hr | None |
| **5** | Consolidate figures (Fig5=XRF, Fig6=Spectral, Fig7=Summary) | 1 hr | Items 1, 4 |
| **6** | Update tables for revised PSQ structure | 2 hr | Manuscript reorg |

---

## Data Inventory

### ICP-MS (Ground Truth)
- **Samples:** 42 (39 ASH, 3 SOIL)
- **Elements:** 60+ including Pb, As, Cd, Cr, Cu, Ni, Zn
- **File:** data/df_master_aviris.csv

### XRF (Field Proxy)
- **Samples:** 37 (paired with ICP-MS)
- **Majors:** SiO₂, Al₂O₃, Fe₂O₃, CaO, MgO, K₂O, TiO₂, P₂O₅, MnO, SO₃
- **Traces:** Pb_xrf, Zn_xrf, Cu_xrf
- **File:** data/df_master_aviris.csv

### Spectral (Compositional Proxies)
- **ASD:** 21 samples, 18 features
- **FTIR:** 36 samples (raw spectra)
- **AVIRIS:** 27 samples with charash_fraction
- **Files:** data/asd_features_all.csv, df_master_aviris.csv

---

*SATM Version 2.0 — Revised analytical hierarchy emphasizing ICP-MS as ground truth, XRF as proxy requiring validation, spectral as compositional support*
