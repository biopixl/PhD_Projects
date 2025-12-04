# Manuscript Proposal: Multi-Modal Geochemical and Spectroscopic Characterization of Wildland-Urban Interface Ash from the 2025 Eaton Fire

## Working Title
**"Integrating Field Spectroscopy, Airborne Imaging, and Laboratory Geochemistry for Rapid Assessment of Heavy Metal Contamination in Wildland-Urban Interface Ash: The 2025 Eaton Fire"**

---

## 1. INTRODUCTION & RATIONALE

### 1.1 Research Context
The January 2025 Eaton Fire burned through the Altadena-Pasadena area of Los Angeles County, destroying over 9,000 structures and creating substantial volumes of heterogeneous ash containing potentially toxic metals. Wildland-urban interface (WUI) fires produce fundamentally different ash chemistry compared to wildland fires due to the combustion of building materials, electronics, vehicles, household chemicals, and other anthropogenic materials.

### 1.2 Unique Multi-Modal Dataset
This study leverages an unprecedented combination of co-located measurements:

| Measurement Type | Platform | Spectral Range | Samples/Coverage |
|------------------|----------|----------------|------------------|
| **ASD Field Spectroscopy** | Handheld FieldSpec 4 | 350–2500 nm (1 nm resolution) | 87 samples |
| **ATR-FTIR** | Laboratory benchtop | Mid-infrared (~4000–400 cm⁻¹) | ~50 samples |
| **AVIRIS-3 Imaging** | Airborne | 380–2500 nm (224 bands) | Full fire extent |
| **ICP-MS** | Laboratory | Elemental | 43 samples |
| **XRF** | Handheld/benchtop | Elemental | 49 samples |

### 1.3 Knowledge Gaps Addressed
1. **Scalability**: No validated methods exist for scaling point-based geochemical measurements to airborne imaging spectroscopy for WUI ash
2. **Rapid screening**: Need for spectroscopic proxies to estimate metal contamination without laboratory analysis
3. **Spatial heterogeneity**: Limited understanding of within-fire variability in ash composition
4. **Mineralogical controls**: Relationship between ash mineralogy (detectable via IR) and metal hosting

### 1.4 Study Significance
This is the first study to combine:
- Ground-truth spectroscopy with paired geochemistry
- Airborne hyperspectral imaging (AVIRIS-3) of a major WUI fire
- Laboratory IR mineralogy with field reflectance spectra
- Comprehensive ICP-MS trace element suite with XRF major elements

---

## 2. SCIENCE QUESTIONS & HYPOTHESES

### Overarching Science Question
**Can spectroscopic measurements (field, laboratory, and airborne) be used to predict heavy metal contamination in WUI ash, enabling rapid spatial mapping of environmental risk?**

### Primary Science Questions

| ID | Science Question | Hypothesis | Key Data |
|----|------------------|------------|----------|
| **PSQ-1** | What are the concentrations and spatial distribution of toxic metals in Eaton Fire ash? | >50% of ash samples exceed EPA RSLs for Pb, As; significant spatial clustering exists | ICP-MS, XRF, GPS |
| **PSQ-2** | Can VNIR-SWIR reflectance spectra predict metal concentrations? | Spectral features (Fe-oxides, organics, carbonite) correlate with Pb, Zn, Cu (R² > 0.5) | ASD spectra + ICP-MS |
| **PSQ-3** | What mineralogical phases host heavy metals in WUI ash? | ATR-FTIR reveals carbonates, Fe-oxides, and amorphous phases as primary metal hosts | ATR-FTIR + ICP-MS |

### Secondary Science Questions

| ID | Science Question | Hypothesis | Key Data |
|----|------------------|------------|----------|
| **SSQ-1** | Can AVIRIS-3 charred ash fraction maps predict ground contamination? | Char fraction correlates with elevated metals due to incomplete combustion concentrating contaminants | AVIRIS charash + ICP-MS |
| **SSQ-2** | Do spectral endmembers correspond to distinct geochemical signatures? | PCA of ASD spectra reveals 3+ clusters matching ICP-MS geochemical groups | ASD + ICP-MS clustering |
| **SSQ-3** | How do field ASD and laboratory ATR-FTIR spectra complement each other? | ASD captures Fe/organic features; ATR-FTIR resolves carbonate/silicate mineralogy | ASD + ATR-FTIR paired |
| **SSQ-4** | Can XRF serve as a rapid field proxy validated against ICP-MS? | XRF accurately screens metals >100 ppm (RMSE <20%) but underestimates trace levels | XRF vs ICP-MS |
| **SSQ-5** | Does burn severity (dNBR) predict ash metal contamination? | Higher dNBR correlates with metal enrichment due to more complete structure destruction | AVIRIS dNBR + ICP-MS |

---

## 3. SCIENCE TRACEABILITY MATRIX

### 3.1 Full Traceability Matrix

| Science Question | Measurable Objective | Data Required | Analysis Method | Expected Output | Success Criteria |
|------------------|---------------------|---------------|-----------------|-----------------|------------------|
| **PSQ-1** | Quantify metal contamination and spatial patterns | ICP-MS (n=43), GPS coordinates | Descriptive stats, kriging, Getis-Ord Gi* | Concentration maps, exceedance tables | Statistically significant clusters (p<0.05) |
| **PSQ-2** | Develop spectral-metal prediction models | ASD spectra (n=87) + ICP-MS (n=43 paired) | PLSR, Random Forest regression, feature importance | Prediction models, R², RMSE | R² > 0.5 for Pb, Zn, Cu; validated via cross-validation |
| **PSQ-3** | Identify mineralogical metal hosts | ATR-FTIR spectra + ICP-MS | Spectral unmixing, correlation with metal ratios | Mineral-metal association diagrams | Significant correlations between mineral abundance and metals |
| **SSQ-1** | Validate AVIRIS products vs ground truth | AVIRIS charash fraction + sample GPS + ICP-MS | Point extraction, regression analysis | Scatter plots, correlation coefficients | R² > 0.3 between char fraction and metal loading |
| **SSQ-2** | Classify ash types spectrally | ASD spectra full dataset | PCA, k-means clustering, discriminant analysis | Spectral endmember library, classification accuracy | ≥3 endmembers with >70% classification accuracy |
| **SSQ-3** | Compare field vs lab spectroscopy | Paired ASD + ATR-FTIR | Feature matching, spectral correlation | Complementarity assessment, feature identification | Unique features identified in each spectral range |
| **SSQ-4** | Validate XRF field screening | Paired XRF + ICP-MS (n=40) | Bland-Altman, regression, RMSE by element | Method comparison plots, bias quantification | Defined accuracy thresholds per element |
| **SSQ-5** | Link burn severity to contamination | AVIRIS dNBR + sample locations + ICP-MS | Zonal statistics, regression | Severity-contamination relationship | Significant correlation (p<0.05) |

### 3.2 Data Integration Matrix

| Sample ID Pattern | ICP-MS | XRF | ASD Field Spec | ATR-FTIR | AVIRIS Extract | Notes |
|-------------------|--------|-----|----------------|----------|----------------|-------|
| JPL##_bkB | ✓ | ✓ | ✓ (bkA suffix) | ✓ | ✓ | Full suite - priority samples |
| GPS## | ✓ | ✓ | ✓ | ✓ | ✓ | GPS-located samples |
| XPAH## | ✓ | ✓ | Limited | ✓ | ✓ | Extended area samples |
| Soil controls | ✓ | ✗ | ✗ | ✗ | ✓ | Background reference |

---

## 4. SPECTRAL DATA OVERVIEW

### 4.1 ASD Field Spectroscopy (FieldSpec 4)
- **Samples**: 87 unique locations
- **Spectral range**: 350–2500 nm at 1 nm resolution
- **Collection dates**: Feb 6, Apr 7, May 13, 2025
- **Key features detectable**:
  - Iron oxides: 480 nm, 530 nm, 670 nm, 870 nm absorption
  - Organic matter/char: Slope changes 400–700 nm
  - Carbonates: 2300–2350 nm absorption
  - Hydroxyl/clays: 1400 nm, 1900 nm, 2200 nm absorptions

### 4.2 ATR-FTIR Laboratory Spectroscopy
- **Samples**: ~50 (SPA format files)
- **Spectral range**: ~4000–400 cm⁻¹
- **Key features detectable**:
  - Carbonates: 1400, 870 cm⁻¹
  - Silicates: 1000–1100 cm⁻¹
  - Organic C: 2920, 2850, 1600 cm⁻¹
  - Metal oxides: <700 cm⁻¹
  - Phosphates: 1000–1100 cm⁻¹

### 4.3 AVIRIS-3 Airborne Imaging Spectroscopy
- **Coverage**: Full Eaton Fire extent
- **Spatial resolution**: ~5 m
- **Spectral range**: 380–2500 nm (224 bands)
- **Derived products available**:
  - Char/ash fraction maps
  - dNBR (differenced Normalized Burn Ratio)
  - PCA components
  - RGB composites

---

## 5. ANALYTICAL FRAMEWORK

### 5.1 Spectral-Geochemical Prediction Pipeline

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  ASD Spectra    │───▶│  Feature         │───▶│  PLSR/RF        │
│  (350-2500 nm)  │    │  Extraction      │    │  Regression     │
└─────────────────┘    │  - Absorptions   │    │  vs ICP-MS      │
                       │  - Derivatives   │    │  metals         │
┌─────────────────┐    │  - Continuum     │    └────────┬────────┘
│  ATR-FTIR       │───▶│    removal       │             │
│  (MIR)          │    └──────────────────┘             ▼
└─────────────────┘                           ┌─────────────────┐
                                              │  Prediction     │
┌─────────────────┐    ┌──────────────────┐   │  Models for     │
│  AVIRIS-3       │───▶│  Point           │──▶│  Pb, Zn, Cu,    │
│  Imagery        │    │  Extraction      │   │  As, Cd         │
└─────────────────┘    │  at sample locs  │   └─────────────────┘
                       └──────────────────┘
```

### 5.2 Multi-Scale Integration

| Scale | Data Source | Resolution | Purpose |
|-------|-------------|------------|---------|
| Point | ICP-MS, XRF | Bulk sample | Ground truth concentrations |
| Point | ASD, ATR-FTIR | mm–cm | Spectral signatures |
| Pixel | AVIRIS-3 | 5 m | Scalable mapping |
| Scene | AVIRIS-3 products | Fire extent | Contamination mapping |

---

## 6. KEY METALS OF CONCERN

| Metal | ICP-MS Range (ppm) | EPA RSL (ppm) | Concern | Spectral Proxy Potential |
|-------|-------------------|---------------|---------|--------------------------|
| **Pb** | 11 – 18,528 | 400 | **HIGH** | Low - no direct features |
| **Zn** | 33 – 23,829 | 23,000 | MODERATE | Low - no direct features |
| **Cu** | 14 – 3,650 | 3,100 | MODERATE | Possible via Fe-oxide association |
| **As** | 3.8 – 12.2 | 0.68 | **HIGH** | Possible via Fe-oxide sorption |
| **Cr** | 12 – 331 | 5.6 (VI) | **HIGH** | Possible via organics correlation |
| **Fe** | 8,335 – 64,081 | - | Matrix element | Strong - Fe-oxide absorptions |
| **Ca** | 2,681 – 322,441 | - | Matrix element | Strong - carbonate features |

---

## 7. PROPOSED FIGURES & TABLES

### Main Text Figures

| Figure | Science Question | Data Sources | Key Message |
|--------|------------------|--------------|-------------|
| **Fig 1**: Study area & sampling | Context | GPS, fire perimeter, AVIRIS RGB | Spatial coverage, fire context |
| **Fig 2**: Metal concentration boxplots | PSQ-1 | ICP-MS | Exceedance of EPA thresholds |
| **Fig 3**: Spatial interpolation maps | PSQ-1 | ICP-MS + GPS | Hotspots of Pb, Zn, Cu |
| **Fig 4**: Representative ASD spectra | PSQ-2, SSQ-2 | ASD | Spectral diversity, endmembers |
| **Fig 5**: PLSR prediction results | PSQ-2 | ASD + ICP-MS | Measured vs predicted metals |
| **Fig 6**: ATR-FTIR mineral identification | PSQ-3 | ATR-FTIR | Carbonate, silicate, oxide phases |
| **Fig 7**: Mineral-metal correlations | PSQ-3 | ATR-FTIR + ICP-MS | Metal hosting in mineral phases |
| **Fig 8**: AVIRIS validation | SSQ-1, SSQ-5 | AVIRIS + ICP-MS | Char fraction vs metal loading |
| **Fig 9**: Multi-method comparison | SSQ-3, SSQ-4 | All spectral + geochem | Integrated workflow diagram |

### Main Text Tables

| Table | Content | Data Sources |
|-------|---------|--------------|
| **Table 1**: Sample inventory | Locations, analysis coverage | Metadata |
| **Table 2**: Summary statistics | Mean, median, range for priority metals | ICP-MS |
| **Table 3**: EPA RSL comparison | Exceedance frequencies | ICP-MS + EPA |
| **Table 4**: Spectral prediction model performance | R², RMSE, key features | ASD + ICP-MS |
| **Table 5**: XRF vs ICP-MS accuracy | Bias, precision by element | Paired data |

### Supplementary Materials

| Item | Content |
|------|---------|
| Table S1 | Full ICP-MS dataset |
| Table S2 | Full XRF dataset |
| Table S3 | Spectral feature assignments |
| Fig S1 | All ASD spectra |
| Fig S2 | All ATR-FTIR spectra |
| Fig S3 | AVIRIS-derived products (charash, dNBR, PCA) |
| Code S1 | Spectral processing and prediction scripts |

---

## 8. PROPOSED MANUSCRIPT STRUCTURE

### Abstract (300 words)
- Context: Eaton Fire WUI, ash contamination hazard
- Innovation: First multi-modal spectral-geochemical integration for WUI ash
- Methods: n=87 spectral, n=43 geochemical, AVIRIS-3 imagery
- Key findings: Exceedance %, spectral prediction accuracy, scalability
- Implications: Rapid post-fire assessment methodology

### 1. Introduction
1. WUI fire trends and structure destruction
2. Ash as contamination pathway
3. Need for rapid spatial assessment methods
4. Potential of spectroscopy for contamination mapping
5. Study objectives

### 2. Methods
1. Study area (Eaton Fire, burn severity, urban context)
2. Sample collection (spatial strategy, timing, protocols)
3. Laboratory geochemistry (ICP-MS, XRF - prep, analysis, QA/QC)
4. Field spectroscopy (ASD FieldSpec 4, protocols, processing)
5. Laboratory IR spectroscopy (ATR-FTIR, protocols)
6. Airborne imaging (AVIRIS-3, products, point extraction)
7. Statistical analysis (PLSR, Random Forest, spatial, multivariate)

### 3. Results
1. Geochemical characterization and EPA comparisons
2. Spatial patterns of contamination
3. Spectral characteristics of ash types
4. Spectral-geochemical prediction models
5. ATR-FTIR mineralogical interpretation
6. AVIRIS product validation
7. Multi-method comparison

### 4. Discussion
1. Contamination levels in WUI fire context
2. Sources of spectral-geochemical relationships
3. Mineralogical controls on metal hosting
4. Scalability: point to pixel to scene
5. Operational implications for post-fire response
6. Method recommendations and limitations

### 5. Conclusions
- Validated spectral proxies for metal contamination
- Demonstrated AVIRIS applicability
- Operational pathway for rapid assessment

---

## 9. TARGET JOURNALS

| Journal | IF | Fit | Rationale |
|---------|-----|-----|-----------|
| **Remote Sensing of Environment** | 13.5 | Excellent | Spectral-geochemical integration, AVIRIS validation |
| **Environmental Science & Technology** | 11.4 | Excellent | Environmental contamination focus |
| **Science of the Total Environment** | 9.8 | Good | Comprehensive multi-method study |
| **ISPRS J. Photogrammetry & Remote Sensing** | 12.7 | Good | Remote sensing methodology |
| **Journal of Hazardous Materials** | 13.6 | Good | Contamination/toxicity emphasis |

**Recommended Primary Target**: *Remote Sensing of Environment* - ideal for multi-platform spectral integration with environmental applications

---

## 10. TIMELINE & MILESTONES

| Phase | Tasks | Duration | Deliverable |
|-------|-------|----------|-------------|
| **1. Data Integration** | Match sample IDs across all datasets, QA/QC | 2 weeks | Unified database |
| **2. Spectral Processing** | ASD/FTIR preprocessing, feature extraction | 2 weeks | Processed spectra, feature table |
| **3. Geochemical Analysis** | Descriptive stats, spatial analysis, EPA comparison | 2 weeks | Summary tables, maps |
| **4. Predictive Modeling** | PLSR/RF models, cross-validation | 3 weeks | Prediction models, accuracy metrics |
| **5. AVIRIS Validation** | Point extraction, correlation analysis | 2 weeks | Validation plots |
| **6. Figure Generation** | All publication figures | 2 weeks | Complete figure set |
| **7. Manuscript Draft** | Write all sections | 4 weeks | Complete draft |
| **8. Internal Review** | Co-author feedback, revisions | 2 weeks | Revised manuscript |
| **9. Submission** | Format, cover letter | 1 week | Submitted manuscript |

**Total: ~20 weeks**

---

## 11. DATA INVENTORY SUMMARY

| Dataset | Format | Samples | Key Variables | Status |
|---------|--------|---------|---------------|--------|
| ICP-MS | CSV | 43 | 60+ elements (ppm) | Complete |
| XRF | CSV | 49 | Major oxides (wt%), traces (ppm) | Complete |
| ASD Reflectance | CSV + raw .asd | 87 | 2151 channels (350-2500 nm) | Complete |
| ATR-FTIR | SPA files | ~50 | MIR spectra | Complete |
| AVIRIS-3 Imagery | GeoTIFF | Scene | 224 bands, derived products | Complete |
| GPS Coordinates | CSV | All | Lat/Lon | Complete |
| Metadata | CSV | All | Sample type, date, analyst | Complete |

---

## 12. COLLABORATION & AUTHORSHIP

### Core Team (from README)
- Mark Wronkiewicz (JPL) - Spectroscopy lead
- Ceth W. Parker (JPL) - Sample collection
- Francisco Ochoa (JPL/UCLA) - Field work
- Red Willow Coleman (JPL/UCLA) - Field work
- **Isaac N. Aguilar (Caltech)** - Geochemistry, integration
- Gregory S. Okin (UCLA) - PI, oversight
- K. Dana Chadwick (JPL) - Remote sensing
- Philip G. Brodrick (JPL) - AVIRIS processing

### Potential Additional Contributors
- XRF/ICP-MS analytical facility staff
- Statistical/ML modeling expertise
- Environmental health interpretation

---

## 13. APPENDIX: SPECTRAL FEATURE REFERENCE

### VNIR-SWIR (ASD) Key Features
| Wavelength (nm) | Feature | Interpretation |
|-----------------|---------|----------------|
| 480, 530 | Fe³⁺ crystal field | Hematite, goethite |
| 670 | Fe³⁺ absorption | Iron oxides |
| 870 | Fe³⁺ absorption | Iron oxides |
| 1400 | O-H stretch | Bound water, clays |
| 1900 | H-O-H bend | Molecular water |
| 2200 | Al-OH, Mg-OH | Clay minerals |
| 2300-2350 | C-O stretch | Carbonates |

### MIR (ATR-FTIR) Key Features
| Wavenumber (cm⁻¹) | Feature | Interpretation |
|-------------------|---------|----------------|
| 3400 | O-H stretch | Water, hydroxyls |
| 2920, 2850 | C-H stretch | Organic matter |
| 1600 | C=C aromatic | Char, organics |
| 1400-1450 | CO₃²⁻ asymmetric | Calcite, MgCO₃ |
| 1000-1100 | Si-O stretch | Silicates, glass |
| 870 | CO₃²⁻ out-of-plane | Calcite |
| 600-700 | Metal-O | Iron oxides |

---

*Document created: December 2025*
*Last updated: December 3, 2025*
*Version: 2.0 - Integrated spectroscopic measurements*
