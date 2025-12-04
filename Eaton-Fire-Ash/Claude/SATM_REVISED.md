# Science and Analysis Traceability Matrix (SATM) - REVISED
## Eaton Fire Ash Geochemical Characterization

**Date:** December 4, 2025
**Status:** Final Framework (Post-Diagnostic Analysis)

---

## Critical Update: Proxy Analysis Findings

### Diagnostic Analysis Summary

The original proxy analysis was compromised by:
1. **One outlier sample (XPAH26)** with anomalous FTIR intensity (~15x higher than other samples)
2. **Extreme multicollinearity** among FTIR proxies (r > 0.99 for most pairs)
3. **Spurious correlations** driven by single influential point (Cook's D = 21.4)

### Corrected Results (XPAH26 Excluded, n=33)

| Proxy | Source | Pb r | Zn r | Cu r | Mean |r| | Significance |
|-------|--------|------|------|------|---------|--------------|
| **XRF_organic** | **XRF** | **0.53** | **0.42** | **0.67** | **0.54** | **Pb\*\*, Zn\*, Cu\*\*\*** |
| CH_stretch_2920 | FTIR | 0.28 | 0.20 | 0.31 | 0.26 | ns |
| Vis_slope | ASD | -0.49 | -0.15 | 0.01 | 0.22 | Pb* only |

### Key Conclusions

1. **XRF_organic (100 - oxide sum) is the best organic/matrix proxy**
   - Only proxy with statistically significant correlations across all elements
   - Contradicts earlier conclusion that XRF was unreliable

2. **FTIR proxies show weak, non-significant correlations (r ≈ 0.26-0.28)**
   - Original r = 0.50 was entirely driven by XPAH26 outlier
   - Matrix normalization does not improve performance

3. **ASD proxies are element-specific**
   - Vis_slope: moderate for Pb only (r = -0.49*)
   - Weak/non-significant for Zn and Cu

---

## Revised Analytical Framework

### Simplified Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 1: GROUND TRUTH - ICP-MS                                     │
│  • Acid-extractable metal concentrations                            │
│  • Reference for regulatory comparison                              │
│  • Benchmark for all proxy validation                               │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 2: FIELD PROXY - XRF                                         │
│  • Elemental screening (majors + traces)                            │
│  • Matrix-dependent but correctable                                 │
│  • XRF_organic proxy for matrix characterization                    │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 3: SUPPORTING CHARACTERIZATION - Spectral (Limited Role)     │
│  • Mineral phase identification (FTIR)                              │
│  • Spatial mapping potential (AVIRIS)                               │
│  • NOT reliable for quantitative organic proxy                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Revised Manuscript Strategy

### Option A: Focus on XRF Validation (Recommended)

**Strengths:**
- Clear analytical hierarchy (ICP-MS → XRF)
- Statistically robust findings
- Practical implications for field deployment
- XRF_organic as effective matrix proxy

**Structure:**
1. ICP-MS characterization (contamination assessment)
2. XRF as field proxy (method comparison, matrix effects)
3. XRF correction model development
4. Spectral as supporting mineralogical characterization (limited)

**Key Messages:**
- WUI ash contains elevated metals exceeding RSLs
- XRF provides reliable field screening with known matrix effects
- XRF_organic (100 - oxide sum) predicts measurement offset
- Correction models improve XRF accuracy by 40-96%

### Option B: Expanded Multi-Modal Framework

**If spectral analysis is essential:**
- Acknowledge FTIR/ASD limitations explicitly
- Focus spectral analysis on mineral identification, not quantitative proxies
- Use AVIRIS for spatial extrapolation, not point validation
- Report all results with appropriate caveats

---

## Revised Science Questions

| PSQ | Question | Primary Data | Supporting Data |
|-----|----------|--------------|-----------------|
| **PSQ-1** | What are trace metal concentrations in Eaton Fire ash relative to regulatory thresholds? | ICP-MS | — |
| **PSQ-2** | How effectively does portable XRF serve as a field proxy for ICP-MS? | XRF + ICP-MS | XRF majors |
| **PSQ-3** | What matrix factors affect XRF-ICP-MS agreement and can they be corrected? | XRF majors + offset | — |
| **PSQ-4** | What mineral phases are present in WUI ash? | FTIR, XRD | XRF majors |

**Note:** Original PSQ-3 (spectral validation of XRF) is deprioritized due to weak statistical support.

---

## Updated SATM Tables

### PSQ-1: Elemental Characterization (No Changes)

| Objective | Output | Status |
|-----------|--------|--------|
| SO-1.1: Metal concentrations | Table 2, Figure 2 | ✅ Complete |
| SO-1.2: RSL exceedances | Table 3 | ✅ Complete |
| SO-1.3: Spatial distribution | Figure 3 | ✅ Complete |
| SO-1.4: Inter-element associations | Figure 4 | ✅ Complete |

### PSQ-2: XRF Validation (Updated Emphasis)

| Objective | Output | Status | Key Finding |
|-----------|--------|--------|-------------|
| SO-2.1: XRF-ICP-MS correlation | Table 4 | ✅ Complete | r = 0.92-0.99 |
| SO-2.2: Systematic offset | Figure 5, Table 5 | ✅ Complete | Bias = -92% to -120% |
| SO-2.3: Matrix effects | Table (matrix cors) | ✅ Complete | **XRF_organic r = 0.53-0.67** |
| SO-2.4: Correction model | Table (model) | ✅ Complete | R² = 0.86-0.96 |

### PSQ-3: Matrix Proxy Evaluation (Revised)

| Objective | Output | Status | Key Finding |
|-----------|--------|--------|-------------|
| SO-3.1: Evaluate organic proxies | Table 11 | ✅ Complete | XRF_organic best |
| SO-3.2: FTIR proxy assessment | Fig 10, 11 | ✅ Complete | Weak (r ≈ 0.28, ns) |
| SO-3.3: ASD proxy assessment | Fig 11 | ✅ Complete | Pb only (r = -0.49*) |
| SO-3.4: Outlier diagnostics | Fig 10 | ✅ Complete | XPAH26 excluded |

### PSQ-4: Mineral Characterization (New/Refocused)

| Objective | Output | Status | Notes |
|-----------|--------|--------|-------|
| SO-4.1: FTIR mineral ID | Spectra analysis | ⚠️ Partial | Focus on qualitative |
| SO-4.2: XRF mineralogy | Ternary plots | ⚠️ Partial | Ca-Si-Fe system |

---

## Revised Figure Plan

| Figure | Content | Priority | Status |
|--------|---------|----------|--------|
| Fig 1 | Study area map | High | ✅ Complete |
| Fig 2 | Metal concentrations vs RSLs | High | ✅ Complete |
| Fig 3 | Spatial distribution | High | ✅ Complete |
| Fig 4 | Inter-element correlations | Medium | ✅ Complete |
| **Fig 5** | **XRF-ICP-MS method comparison** | **High** | ✅ Complete |
| **Fig 6** | **Matrix effects on XRF offset** | **High** | Needs revision |
| Fig 7 | Correction model performance | Medium | ✅ Complete |
| ~~Fig 8~~ | ~~Spectral organic proxies~~ | ~~Low~~ | ⚠️ Deprioritized |
| ~~Fig 9~~ | ~~FTIR comparison~~ | ~~Low~~ | ⚠️ Deprioritized |
| **Fig 10** | **Diagnostic analysis (outliers)** | **Medium** | ✅ Complete |
| **Fig 11** | **Cleaned proxy comparison** | **Medium** | ✅ Complete |

---

## Revised Manuscript Outline

### Title
"Trace Metal Contamination in Wildland-Urban Interface Fire Ash: ICP-MS Characterization and XRF Field Proxy Validation"

### Abstract (250 words)
- Eaton Fire WUI context
- ICP-MS characterization: widespread RSL exceedances (Pb, Zn, Cu, As)
- XRF validation: strong correlation (r > 0.92), systematic offset (-92% to -120%)
- Matrix effects: XRF_organic proxy predicts offset (r = 0.53-0.67)
- Correction models improve accuracy by 40-96%
- Implications for rapid field assessment

### 1. Introduction
- WUI fire contamination risks
- Need for rapid field screening
- XRF as potential field proxy
- Study objectives (revised PSQs)

### 2. Methods
- 2.1 Study area (Eaton Fire)
- 2.2 Sample collection
- 2.3 Laboratory analysis
  - ICP-MS (reference method)
  - XRF (field proxy)
  - FTIR (mineral characterization)
- 2.4 Statistical analysis
  - Method comparison (correlation, Bland-Altman)
  - Matrix effect evaluation
  - Correction model development

### 3. Results
- **3.1 Trace Metal Concentrations (PSQ-1)**
  - Summary statistics
  - RSL exceedances
  - Spatial patterns

- **3.2 XRF-ICP-MS Method Comparison (PSQ-2)**
  - Correlation and regression
  - Systematic offset characterization
  - Bland-Altman analysis

- **3.3 Matrix Effects and Correction (PSQ-3)**
  - XRF_organic as matrix proxy
  - Correction model development
  - Validation statistics

- **3.4 Ash Mineralogy (PSQ-4)** [Brief]
  - FTIR mineral identification
  - XRF major element composition

### 4. Discussion
- 4.1 Contamination implications
- 4.2 XRF field deployment recommendations
- 4.3 Limitations
  - Spectral proxies not validated for organics
  - Sample size constraints
- 4.4 Future directions

### 5. Conclusions

---

## Key Manuscript Messages (Revised)

### What the Data Support:
1. WUI ash contains metals exceeding EPA RSLs
2. XRF correlates strongly with ICP-MS (r > 0.92)
3. XRF systematically overestimates concentrations
4. XRF_organic predicts offset magnitude
5. Correction models improve accuracy

### What the Data Do NOT Support:
1. ~~FTIR proxies for organic quantification~~ (r ≈ 0.28, ns)
2. ~~ASD as universal organic proxy~~ (element-specific only)
3. ~~Spectral validation of XRF matrix effects~~ (weak correlations)

---

## File Inventory (Updated)

### Primary Data Files
| File | Description | Status |
|------|-------------|--------|
| df_master_aviris.csv | Master dataset | ✅ Current |
| ftir_organic_features.csv | FTIR extracted features | ✅ Current |
| asd_organic_features.csv | ASD organic proxies | ✅ Current |

### Analysis Outputs
| File | Description | Status |
|------|-------------|--------|
| table11_proxy_correlations_cleaned.csv | **Cleaned proxy results** | ✅ New |
| ftir_diagnostic_results.rds | Diagnostic analysis | ✅ New |
| table4_xrf_regression.csv | XRF-ICP-MS regression | ✅ Complete |
| table5_bland_altman.csv | Method agreement stats | ✅ Complete |

### Figures
| File | Description | Status |
|------|-------------|--------|
| Fig5_xrf_validation.pdf | XRF-ICP-MS comparison | ✅ Complete |
| Fig10_ftir_diagnostic.pdf | Outlier diagnostics | ✅ Complete |
| Fig11_organic_proxies_cleaned.pdf | Cleaned proxy analysis | ✅ Complete |

---

## Action Items

### Immediate (Manuscript Preparation)
1. ☐ Revise manuscript to XRF-focused structure
2. ☐ Update methods section (exclude XPAH26, justify)
3. ☐ Create consolidated Fig 6 (matrix effects summary)
4. ☐ Write discussion section addressing spectral limitations

### If Retaining Spectral Analysis
1. ☐ Add explicit caveats about weak FTIR/ASD correlations
2. ☐ Report all p-values and significance levels
3. ☐ Discuss outlier sensitivity
4. ☐ Focus FTIR on mineral ID, not organic proxy

---

*SATM Version 3.0 — Revised based on cleaned diagnostic analysis, emphasizing XRF_organic as primary matrix proxy*
