# Statistical Verdict: Manuscript-Ready Relationships

**Date:** December 4, 2025
**Criteria:** |r| ≥ 0.5 AND FDR-adjusted p < 0.05 AND survives outlier removal (Robust = TRUE)

---

## EXECUTIVE SUMMARY

Of 450 correlation tests performed, only **3 relationships** meet strict manuscript criteria:

| Target | Predictor | r | r_clean | p_FDR | Category |
|--------|-----------|------|---------|-------|----------|
| **Pb** | Anthro_index | 0.64 | **0.76** | <0.001 | Ratio |
| **Zn** | XRF_organic | 0.89 | **0.89** | <0.001 | XRF |
| **Cr** | K2O_pct | -0.58 | **-0.71** | 0.002 | XRF |

---

## CRITICAL FINDINGS

### 1. FTIR PROXIES: NOT ROBUST

**All 27 FTIR-Zn correlations (r ≈ 0.97) are DRIVEN BY OUTLIERS**

| Before outlier removal | After outlier removal |
|------------------------|----------------------|
| r = 0.97*** | r = 0.32 (ns) |
| Max Cook's D = 133-183 | - |

**Verdict:** FTIR spectral proxies should NOT be emphasized in manuscript. The apparent strong correlations are artifacts of 1-2 influential samples (likely XPAH26).

### 2. ASD PROXIES: NOT SUPPORTED

- Max |r| = 0.49 (below 0.5 threshold)
- Zero relationships pass FDR correction
- **Verdict:** ASD proxies should NOT be included as predictive tools

### 3. XRF-ICP-MS COMPARISON: STRONGLY SUPPORTED

| Metal | r | p | %Bias | Verdict |
|-------|---|---|-------|---------|
| Pb | 0.990 | <0.001 | -427% | ✓ Strong correlation, systematic bias |
| Zn | 0.996 | <0.001 | -287% | ✓ Strong correlation, systematic bias |
| Cu | 0.920 | <0.001 | -364% | ✓ Strong correlation, systematic bias |

**Verdict:** XRF-ICP-MS method comparison is the strongest finding. Systematic bias supports need for correction models.

### 4. MATRIX PROXY (XRF_organic): PARTIALLY SUPPORTED

- **Zn-XRF_organic:** r = 0.89, robust (r_clean = 0.89) ✓
- Pb, Cu: Not robust after outlier removal

**Verdict:** XRF_organic predicts Zn offset but not Pb or Cu

### 5. ELEMENTAL RATIOS: PARTIALLY SUPPORTED

- **Pb-Anthro_index:** r = 0.64 → r_clean = 0.76 ✓
- Pb_Zn, Cu_Zn, Pb_Cu: Not robust (driven by extreme values)

### 6. GEOGENIC CLASSIFICATION: SUPPORTED (CV-based)

| Classification | Metal | CV (%) |
|---------------|-------|--------|
| Fire-enriched | Pb | 464% |
| Fire-enriched | Zn | 292% |
| Fire-enriched | Cu | 284% |
| Geogenic | As | 33% |
| Geogenic | Cr | 91% |
| Geogenic | Ni | 143% |

**Verdict:** CV difference strongly supports fire-enriched vs geogenic classification

---

## RECOMMENDED MANUSCRIPT STRUCTURE

### Priority 1: STRONG SUPPORT
1. **ICP-MS Characterization** (descriptive statistics)
2. **XRF-ICP-MS Method Comparison** (r > 0.9 for all metals)
3. **Metal Classification** (fire-enriched vs geogenic via CV)

### Priority 2: MODERATE SUPPORT
4. **XRF_organic as Zn matrix proxy** (r = 0.89, robust)
5. **Systematic bias in XRF** (supports correction model need)

### Priority 3: WEAK/NO SUPPORT - DE-EMPHASIZE
6. ~~FTIR spectral proxies~~ (outlier-driven, not robust)
7. ~~ASD spectral proxies~~ (below statistical thresholds)
8. ~~Pb/Cu matrix proxies~~ (not robust)

---

## WHAT TO REMOVE FROM MANUSCRIPT

1. **Remove claims that FTIR predicts metal concentrations**
   - Original r = 0.97 is artifact
   - After outlier removal r = 0.32 (ns)

2. **Remove ASD as quantitative proxy**
   - No significant relationships after FDR correction

3. **Remove non-robust ratio relationships**
   - Pb_Zn, Cu_Zn driven by extreme samples

4. **Remove UCC-based enrichment factors**
   - Not a certified reference material

---

## WHAT TO KEEP/EMPHASIZE

1. **XRF-ICP-MS validation**
   - r = 0.92-0.99 (very strong)
   - Systematic bias quantified
   - Correction model justified

2. **XRF_organic for Zn**
   - r = 0.89, survives outlier removal
   - Mechanistically plausible (matrix effect)

3. **Metal classification**
   - Fire-enriched (Pb, Zn, Cu): CV > 200%
   - Geogenic (As, Cr, Ni): CV < 150%
   - Clear statistical separation

4. **Descriptive ICP-MS characterization**
   - No statistical inference needed
   - EPA RSL exceedances
   - Spatial patterns (qualitative)

---

## STATISTICAL SUMMARY

| Criterion | N passing |
|-----------|-----------|
| Raw p < 0.05 | 72/450 (16%) |
| FDR p < 0.05 | 46/450 (10%) |
| |r| ≥ 0.5 AND FDR p < 0.05 | 42/450 (9%) |
| **ROBUST** (survives outlier removal) | **3/450 (0.7%)** |

**Conclusion:** Only 0.7% of tested relationships are truly manuscript-ready.
