# Manuscript Roadmap: Eaton Fire Ash Geochemical Characterization

**Date:** December 4, 2025
**Working Title:** "Trace Metal Contamination in Wildland-Urban Interface Fire Ash: Multi-Modal Characterization and Field Proxy Validation"

---

## Manuscript Structure Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SECTION 1: ICP-MS CHARACTERIZATION (Ground Truth)                          │
│  • Elemental concentrations                                                 │
│  • Regulatory comparison (EPA RSLs)                                         │
│  • Spatial patterns                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  SECTION 2: XRF VALIDATION & ORGANIC PROXY COMPARISON                       │
│  • XRF-ICP-MS method agreement                                              │
│  • Systematic offset characterization                                       │
│  • XRF_organic vs spectral organic proxies                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  SECTION 3: MATRIX EFFECTS FROM SPECTRAL PROPERTIES                         │
│  • FTIR spectral characterization                                           │
│  • ASD reflectance properties                                               │
│  • Matrix effect correlations                                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│  SECTION 4: MINERAL CLASSIFICATION CORRELATIONS                             │
│  • FTIR mineral phase identification                                        │
│  • XRF-derived mineralogy                                                   │
│  • Mineral-metal associations                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Section 1: ICP-MS Characterization

### Objectives
- Establish ground truth elemental concentrations
- Assess regulatory exceedances
- Characterize spatial distribution

### Required Analyses

| Analysis | Script | Output | Status |
|----------|--------|--------|--------|
| Summary statistics (n, mean, median, IQR, range) | 04_psq1_spatial_analysis.R | Table 2 | ✅ Complete |
| EPA RSL exceedance rates | 04_psq1_spatial_analysis.R | Table 3 | ✅ Complete |
| Spatial autocorrelation (Moran's I) | 04_psq1_spatial_analysis.R | Table (Moran) | ✅ Complete |
| Hotspot analysis (Getis-Ord Gi*) | 04_psq1_spatial_analysis.R | Figure 3 | ✅ Complete |
| Inter-element correlation matrix | 08_publication_figures.R | Figure 4 | ✅ Complete |

### Key Figures
- **Figure 1:** Study area map with sample locations
- **Figure 2:** Metal concentration boxplots with RSL reference lines
- **Figure 3:** Spatial distribution with hotspot overlay
- **Figure 4:** Inter-element correlation heatmap

### Key Tables
- **Table 1:** Sample metadata and analytical coverage
- **Table 2:** ICP-MS summary statistics
- **Table 3:** EPA RSL exceedance summary

### Status: ✅ COMPLETE

---

## Section 2: XRF Validation & Organic Proxy Comparison

### Objectives
- Validate XRF as field proxy for ICP-MS
- Quantify systematic offset
- Compare XRF_organic vs spectral organic proxies

### Required Analyses

| Analysis | Script | Output | Status |
|----------|--------|--------|--------|
| XRF-ICP-MS correlation (Pb, Zn, Cu) | 12_xrf_icpms_validation.R | Table 4 | ✅ Complete |
| Bland-Altman method agreement | 12_xrf_icpms_validation.R | Table 5, Figure 5 | ✅ Complete |
| Log-ratio offset distributions | 12_xrf_icpms_validation.R | Figure 5 | ✅ Complete |
| XRF correction model | 12_xrf_icpms_validation.R | Table (model) | ✅ Complete |
| **Organic proxy comparison (cleaned)** | 17_ftir_reanalysis_cleaned.R | Table 11, Figure 11 | ✅ Complete |
| **Outlier diagnostics** | 16_ftir_diagnostic_analysis.R | Figure 10 | ✅ Complete |

### Organic Proxy Comparison Results (XPAH26 excluded, n=33)

| Proxy | Source | Pb r | Zn r | Cu r | Mean |r| | Significance |
|-------|--------|------|------|------|---------|--------------|
| XRF_organic | XRF | 0.53 | 0.42 | 0.67 | 0.54 | Pb**, Zn*, Cu*** |
| CH_stretch_2920 | FTIR | 0.28 | 0.20 | 0.31 | 0.26 | ns |
| Vis_slope | ASD | -0.49 | -0.15 | 0.01 | 0.22 | Pb* only |

### Key Figures
- **Figure 5:** XRF-ICP-MS validation (4-panel: scatter, Bland-Altman, offset distribution, correction)
- **Figure 6:** Organic proxy comparison (XRF vs FTIR vs ASD) - **NEEDS CREATION**

### Key Tables
- **Table 4:** XRF-ICP-MS regression statistics
- **Table 5:** Bland-Altman agreement statistics
- **Table 6:** Organic proxy comparison (cleaned analysis)

### Remaining Tasks

| Task | Priority | Effort | Notes |
|------|----------|--------|-------|
| Create consolidated Figure 6 (organic proxy comparison) | High | 1 hr | Combine Fig 10 & 11 key panels |
| Document XPAH26 exclusion rationale | High | 0.5 hr | Methods section |
| Summarize XRF correction model performance | Medium | 0.5 hr | Results text |

### Status: ⚠️ 90% COMPLETE (needs Figure 6 consolidation)

---

## Section 3: Matrix Effects from Spectral Properties

### Objectives
- Characterize ash spectral properties (FTIR, ASD)
- Evaluate spectral indicators of matrix composition
- Correlate spectral features with XRF-ICP-MS offset

### Required Analyses

| Analysis | Script | Output | Status |
|----------|--------|--------|--------|
| FTIR spectral feature extraction | 15_ftir_organic_proxies.R | ftir_organic_features.csv | ✅ Complete |
| ASD organic proxy extraction | 14_spectral_organic_proxies.R | asd_organic_features.csv | ✅ Complete |
| Spectral-offset correlations (raw) | 15_ftir_organic_proxies.R | Table 9 | ✅ Complete |
| Spectral-offset correlations (cleaned) | 17_ftir_reanalysis_cleaned.R | Table 11 | ✅ Complete |
| Multicollinearity assessment | 16_ftir_diagnostic_analysis.R | Figure 10 | ✅ Complete |
| **FTIR band assignments** | — | Table (new) | ☐ TODO |
| **ASD spectral characteristics** | — | Figure (new) | ☐ TODO |

### FTIR Spectral Bands Identified

| Band (cm⁻¹) | Assignment | Proxy Variable | Matrix Effect |
|-------------|------------|----------------|---------------|
| 2850-2960 | C-H stretch (aliphatic) | CH_total | Organic content |
| 1700-1750 | C=O carbonyl | CO_carbonyl_1720 | Oxidized organics |
| 1580-1620 | Aromatic C=C | Aromatic_1600 | Char content |
| 1080 | Si-O stretch | Silicate_1080 | Silicate minerals |
| 1420 | CO₃ asymmetric | Carbonate_1420 | Calcium carbonate |
| 875 | CO₃ out-of-plane | Carbonate_875 | Carbite confirmation |

### ASD Spectral Features

| Feature | Wavelength (nm) | Proxy Variable | Target Property |
|---------|-----------------|----------------|-----------------|
| Visible slope | 450-700 | Vis_slope | Char/organic darkness |
| Blue slope | 400-550 | Blue_slope | Iron oxides |
| Overall albedo | 350-2500 | Char_darkness | Total absorption |
| Fe absorption | 530, 900 | Fe_index | Fe-oxide content |
| Clay absorption | 1900, 2200 | Depth_1900nm | Clay minerals |

### Key Findings

1. **FTIR proxies highly multicollinear** (r > 0.99 between most bands)
   - All measure baseline spectral intensity, not independent chemistry
   - Matrix normalization (CH/Silicate) provides modest improvement

2. **ASD proxies element-specific**
   - Vis_slope correlates with Pb offset (r = -0.49*) but not Zn or Cu
   - Limited utility as universal organic proxy

3. **XRF_organic outperforms spectral proxies**
   - Significant correlations for all three elements
   - More practical for field deployment

### Key Figures
- **Figure 7:** FTIR spectral characterization - **NEEDS CREATION**
  - Panel A: Representative FTIR spectra with band assignments
  - Panel B: Spectral intensity distributions
  - Panel C: Multicollinearity heatmap

- **Figure 8:** ASD spectral characterization - **NEEDS CREATION**
  - Panel A: Representative reflectance spectra
  - Panel B: Vis_slope vs Pb offset (significant)
  - Panel C: Char_darkness distribution

### Remaining Tasks

| Task | Priority | Effort | Notes |
|------|----------|--------|-------|
| Create FTIR spectral figure (band assignments) | Medium | 2 hr | Representative spectra |
| Create ASD spectral figure | Medium | 1.5 hr | Reflectance curves |
| Write spectral characterization results | Medium | 1 hr | Descriptive text |
| Document multicollinearity limitations | High | 0.5 hr | Discussion section |

### Status: ⚠️ 70% COMPLETE (needs spectral characterization figures)

---

## Section 4: Mineral Classification Correlations

### Objectives
- Identify mineral phases in WUI ash
- Correlate mineralogy with metal concentrations
- Evaluate mineral controls on XRF matrix effects

### Required Analyses

| Analysis | Script | Output | Status |
|----------|--------|--------|--------|
| FTIR mineral identification | 06_psq3_ftir_analysis.R | Table (minerals) | ⚠️ Partial |
| XRF ternary classification (Ca-Si-Fe) | — | Figure (new) | ☐ TODO |
| Mineral-metal correlations | — | Table (new) | ☐ TODO |
| Carbonate index validation | 13_spectral_xrf_validation.R | Table 6 | ✅ Complete |
| Fe-oxide index validation | 13_spectral_xrf_validation.R | Table 6 | ✅ Complete |

### Mineral Phases Expected in WUI Ash

| Mineral | Formula | FTIR Bands (cm⁻¹) | XRF Proxy |
|---------|---------|-------------------|-----------|
| Calcite | CaCite₃ | 1420, 875, 712 | CaO_pct |
| Quartz | SiO₂ | 1080, 798, 778 | SiO2_pct |
| Hematite | Fe₂O₃ | 540, 470 | Fe2O3_pct |
| Gypsum | CaSO₄·2H₂O | 1140, 1115, 670 | SO3_pct, CaO_pct |
| Apatite | Ca₅(PO₄)₃(OH) | 1090, 1040, 603 | P2O5_pct, CaO_pct |
| Clay minerals | Variable | 1030, 915, 530 | Al2O3_pct |

### XRF-Based Mineral Classification

| Classification | Criteria | Expected Minerals |
|----------------|----------|-------------------|
| Calcium-rich | CaO > 30%, SiO2 < 30% | Calcite, gite calcium oxide |
| Silica-rich | SiO2 > 50%, CaO < 20% | Quartz, glass, feldspar |
| Fe-rich | Fe2O3 > 15% | Hematite, magnetite |
| Mixed calcium-silicate | CaO 20-40%, SiO2 30-50% | Ca-silicates, slag |

### Mineral-Metal Association Hypotheses

| Metal | Expected Association | Mechanism |
|-------|---------------------|-----------|
| Pb | Calcium phases | Isomorphous substitution for Ca |
| Zn | Fe-oxides, carbonates | Adsorption, co-precipitation |
| Cu | Organic matter, Fe-oxides | Complexation, adsorption |
| As | Fe-oxides | Strong arsenate-Fe affinity |

### Key Figures
- **Figure 9:** Mineral classification - **NEEDS CREATION**
  - Panel A: XRF ternary diagram (CaO-SiO2-Fe2O3)
  - Panel B: FTIR mineral identification spectra
  - Panel C: Mineral class vs metal concentration

### Key Tables
- **Table 7:** FTIR mineral phase assignments
- **Table 8:** Mineral class-metal correlations

### Remaining Tasks

| Task | Priority | Effort | Notes |
|------|----------|--------|-------|
| Create XRF ternary classification | High | 1.5 hr | CaO-SiO2-Fe2O3 system |
| FTIR mineral phase assignments | Medium | 2 hr | Match reference spectra |
| Calculate mineral-metal correlations | Medium | 1 hr | By mineral class |
| Create mineral classification figure | High | 2 hr | Ternary + correlations |

### Status: ☐ 30% COMPLETE (major work needed)

---

## Consolidated Figure Plan

| Figure | Content | Section | Priority | Status |
|--------|---------|---------|----------|--------|
| Fig 1 | Study area map | 1 | High | ✅ Complete |
| Fig 2 | Metal concentrations vs RSLs | 1 | High | ✅ Complete |
| Fig 3 | Spatial distribution (hotspots) | 1 | High | ✅ Complete |
| Fig 4 | Inter-element correlations | 1 | Medium | ✅ Complete |
| **Fig 5** | **XRF-ICP-MS validation** | **2** | **High** | ✅ Complete |
| **Fig 6** | **Organic proxy comparison** | **2** | **High** | ☐ TODO |
| **Fig 7** | **FTIR spectral characterization** | **3** | **Medium** | ☐ TODO |
| **Fig 8** | **ASD spectral characterization** | **3** | **Medium** | ☐ TODO |
| **Fig 9** | **Mineral classification** | **4** | **High** | ☐ TODO |

### Supplementary Figures
| Figure | Content | Status |
|--------|---------|--------|
| Fig S1 | FTIR diagnostic (outliers, multicollinearity) | ✅ Complete (Fig 10) |
| Fig S2 | Full proxy correlation table | ✅ Complete (Fig 11) |

---

## Consolidated Table Plan

| Table | Content | Section | Status |
|-------|---------|---------|--------|
| Table 1 | Sample metadata | Methods | ✅ Complete |
| Table 2 | ICP-MS summary statistics | 1 | ✅ Complete |
| Table 3 | EPA RSL exceedances | 1 | ✅ Complete |
| Table 4 | XRF-ICP-MS regression | 2 | ✅ Complete |
| Table 5 | Bland-Altman statistics | 2 | ✅ Complete |
| **Table 6** | **Organic proxy comparison** | **2** | ✅ Complete (Table 11) |
| **Table 7** | **FTIR mineral assignments** | **4** | ☐ TODO |
| **Table 8** | **Mineral-metal correlations** | **4** | ☐ TODO |

---

## Implementation Roadmap

### Phase 1: Complete Section 2 (1-2 days)

```
☐ Task 1.1: Create Figure 6 (Organic Proxy Comparison)
   - Panel A: Correlation heatmap (Pb, Zn, Cu × XRF/FTIR/ASD)
   - Panel B: Best proxy scatter plots by element
   - Panel C: Source comparison bar chart
   Script: 18_figure6_organic_proxy_comparison.R

☐ Task 1.2: Document XPAH26 exclusion
   - Add to Methods section
   - Justify based on diagnostic analysis (Cook's D = 21.4)

☐ Task 1.3: Write Section 2 results text
   - XRF-ICP-MS correlation statistics
   - Organic proxy comparison findings
   - Key conclusion: XRF_organic outperforms spectral proxies
```

### Phase 2: Complete Section 3 (2-3 days)

```
☐ Task 2.1: Create Figure 7 (FTIR Spectral Characterization)
   - Panel A: Representative spectra with band labels
   - Panel B: Band intensity distributions
   - Panel C: Multicollinearity matrix
   Script: 19_figure7_ftir_characterization.R

☐ Task 2.2: Create Figure 8 (ASD Spectral Characterization)
   - Panel A: Representative reflectance spectra
   - Panel B: Vis_slope vs Pb offset
   - Panel C: Spectral index distributions
   Script: 20_figure8_asd_characterization.R

☐ Task 2.3: Write Section 3 results text
   - FTIR spectral features identified
   - ASD spectral characteristics
   - Matrix effect correlations (with caveats)
```

### Phase 3: Complete Section 4 (2-3 days)

```
☐ Task 3.1: Create XRF ternary classification
   - CaO-SiO2-Fe2O3 ternary diagram
   - Classify samples by dominant mineralogy
   Script: 21_mineral_classification.R

☐ Task 3.2: FTIR mineral phase identification
   - Match spectra to reference minerals
   - Create mineral assignment table
   Script: 21_mineral_classification.R

☐ Task 3.3: Calculate mineral-metal correlations
   - Group samples by mineral class
   - Correlate with metal concentrations
   Script: 21_mineral_classification.R

☐ Task 3.4: Create Figure 9 (Mineral Classification)
   - Panel A: XRF ternary diagram
   - Panel B: FTIR mineral spectra
   - Panel C: Mineral-metal associations
   Script: 21_mineral_classification.R

☐ Task 3.5: Write Section 4 results text
   - Mineral phases identified
   - Classification results
   - Mineral-metal associations
```

### Phase 4: Manuscript Assembly (2-3 days)

```
☐ Task 4.1: Compile Methods section
   - Sample collection
   - Analytical methods (ICP-MS, XRF, FTIR, ASD)
   - Statistical analysis
   - Exclusion criteria (XPAH26)

☐ Task 4.2: Compile Results sections (1-4)

☐ Task 4.3: Write Discussion
   - Contamination implications
   - XRF field deployment recommendations
   - Spectral proxy limitations
   - Mineral controls on metal distribution

☐ Task 4.4: Write Abstract and Conclusions

☐ Task 4.5: Format references and supplementary material
```

---

## Timeline Summary

| Phase | Tasks | Estimated Effort | Dependencies |
|-------|-------|------------------|--------------|
| Phase 1 | Section 2 completion | 1-2 days | None |
| Phase 2 | Section 3 completion | 2-3 days | Phase 1 |
| Phase 3 | Section 4 completion | 2-3 days | Can parallel Phase 2 |
| Phase 4 | Manuscript assembly | 2-3 days | Phases 1-3 |
| **Total** | | **7-11 days** | |

---

## Key Messages by Section

### Section 1: ICP-MS Characterization
> "Eaton Fire ash contains trace metals at concentrations exceeding EPA residential soil screening levels, with Pb, Zn, and Cu showing the most consistent exceedances across the study area."

### Section 2: XRF Validation & Organic Proxy Comparison
> "Portable XRF provides reliable field screening for trace metals (r > 0.92 with ICP-MS), though systematic offsets require correction. The XRF-derived organic proxy (100 - oxide sum) significantly predicts offset magnitude (r = 0.53-0.67, p < 0.01), outperforming spectral alternatives."

### Section 3: Matrix Effects from Spectral Properties
> "FTIR and ASD spectral analysis characterize ash matrix composition but show limited utility as quantitative organic proxies due to high multicollinearity (FTIR) and element-specific responses (ASD)."

### Section 4: Mineral Classification Correlations
> "WUI ash composition spans a Ca-Si-Fe ternary system reflecting source material heterogeneity. Mineral phase associations suggest carbonate and Fe-oxide minerals influence trace metal distribution."

---

## Quality Control Checklist

### Statistical Rigor
- [x] Outlier identification and exclusion documented (XPAH26)
- [x] Multicollinearity assessed for FTIR proxies
- [x] Significance levels reported for all correlations
- [ ] Confidence intervals for regression models
- [ ] Sample size considerations for each analysis

### Reproducibility
- [x] All analyses scripted in R
- [x] Data files documented
- [ ] Random seed set for any stochastic analyses
- [ ] Package versions documented

### Manuscript Standards
- [ ] All figures publication quality (300 dpi)
- [ ] Consistent color scheme across figures
- [ ] Table formatting standardized
- [ ] References formatted (target journal style)

---

*Roadmap Version 1.0 — December 4, 2025*
