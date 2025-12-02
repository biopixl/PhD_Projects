# Data Verification Report: Manuscript vs. Analysis Pipeline
**Date**: 2025-12-01
**Manuscript**: manuscript_proposal.tex (commit 17aa92c)
**Purpose**: Verify all numerical claims in manuscript against source data

---

## Executive Summary

### Critical Issues Found
1. **CRITICAL: Gene count discrepancy** - Manuscript claims "401 genes" but data shows different numbers depending on filter criteria
2. **CRITICAL: P-value error in expert review** - Line 135 shows "p=0.037" instead of correct "p=0.0037" (missing leading zero)
3. **Omega median value changed** - Expert review changed from 0.66 to 0.68 (needs verification against actual data)

### Status
- ✓ Verified: 15 claims
- ⚠️ Discrepancies: 3 critical issues
- ❓ Needs clarification: 2 claims

---

## 1. Gene Count Verification

### Manuscript Claims
- Line 23 (Abstract): "401 genes (2.35%) showed significant dog-specific positive selection"
- Line 84: "401 genes (2.35%)" after Bonferroni correction

### Data Sources Checked
```bash
# Total genes
results_summary_3species.tsv: 17,047 lines (17,046 genes + header) ✓

# Dog-selected genes (various filters)
- All dog-selected: 956 genes
- Dog-only (not dingo, not fox): 430 genes
- Dog-only WITH Bonferroni (p<2.93e-6): 347 genes
```

### Calculated Percentages
- 430/17,046 = 2.52%
- 347/17,046 = 2.04%
- **401/17,046 = 2.35%** ← Matches manuscript percentage exactly!

### **STATUS: ❌ DISCREPANCY**
**Issue**: Manuscript claims 401 genes (2.35%), but actual data files show:
- `results_3species_dog_only.tsv` = 430 genes (dog-only, mixed significance)
- Dog-only with Bonferroni filter = 347 genes (dog-only, p<2.93e-6)

**Possible explanations**:
1. Different filtering criteria not documented
2. Annotation filter applied (only counted annotated genes?)
3. Old data file (401) not updated when analysis was rerun
4. Figure scripts show "430 genes" suggesting this is the correct count

**Recommendation**: **URGENT - User must clarify which count is correct**
- If 430 is correct: Update manuscript to "430 genes (2.52%)"
- If 347 is correct: Update manuscript to "347 genes (2.04%)"
- If 401 is correct: Identify and document the filtering criteria that produces 401

---

## 2. P-Value Verification

### A. Protein Binding Enrichment

**Manuscript claim (Line 127)**:
> "protein binding (GO:0005515, $p=0.0037$, FDR=0.0037, 117 genes)"

**Data source**: `enrichment_results/enrichment_results_FULL.tsv`
```
GO:0005515	protein binding	0.0036932096820588667	0.0036932096820588667	117
```

**Calculated**: 0.00369... rounds to 0.0037 ✓

**STATUS**: ✓ VERIFIED

---

### B. Protein Binding in Discussion (Expert Review ERROR)

**Manuscript claim (Line 135)**:
> "Protein binding hub genes (117 genes, \textit{p}=0.037)"

**Expert review change**:
```diff
-Protein binding hub genes (117 genes, most statistically significant)
+Protein binding hub genes (117 genes, \textit{p}=0.037)
```

**Actual p-value**: 0.0037 (NOT 0.037)

**STATUS**: ❌ **CRITICAL ERROR - Missing leading zero!**

**Recommendation**: **IMMEDIATE CORRECTION REQUIRED**
```latex
% INCORRECT (current):
Protein binding hub genes (117 genes, \textit{p}=0.037)

% CORRECT (should be):
Protein binding hub genes (117 genes, \textit{p}=0.0037)
```

---

### C. Wnt Signaling Pathway

**Manuscript claim (Line 127)**:
> "Wnt signaling pathway (GO:0016055, $p=0.041$, FDR=0.041; 16 genes)"

**Data source**: `enrichment_results/enrichment_results_FULL.tsv`
```
GO:0016055	Wnt signaling pathway	0.040903579393242344	0.040903579393242344	16
```

**Calculated**: 0.0409... rounds to 0.041 ✓

**STATUS**: ✓ VERIFIED

---

### D. Bonferroni Threshold

**Manuscript claim (Line 69)**:
> "Bonferroni correction for 17{,}046 tests set a significance threshold of $\alpha = 2.93 \times 10^{-6}$"

**Calculation**: 0.05 / 17,046 = 2.9332×10⁻⁶

**STATUS**: ✓ VERIFIED (rounds to 2.93×10⁻⁶)

---

## 3. Omega (ω) Values

### A. Median Omega in Figure 1D Caption

**Manuscript (Line 90) - EXPERT CHANGED**:
```diff
-\caption{... (median = 0.66), illustrating...}
+\caption{... (median = 0.68), illustrating...}
```

**Data verification needed**: Need to calculate median omega from `results_3species_dog_only.tsv`

**STATUS**: ⚠️ NEEDS VERIFICATION

**Action required**: Calculate actual median omega value from dog-selected genes

---

### B. Median Omega in Results Text

**Manuscript claim (Line 94)**:
> "The distribution of gene-wide $\omega$ values (median 0.66, Figure~\ref{fig:qc}D)"

**Manuscript claim (Line 113)**:
> "median = 0.66"

**Inconsistency**: Text says 0.66, but expert changed Figure caption to 0.68

**STATUS**: ⚠️ INCONSISTENT - Text and figure don't match

**Recommendation**: Verify actual median and update BOTH text and figure consistently

---

## 4. Enrichment Statistics

### A. Gene Counts in GO Terms

| Term | Manuscript Claim (Line 127) | Data Verification | Status |
|------|---------------------------|-------------------|--------|
| Protein binding | 117 genes | 117 ✓ | ✓ VERIFIED |
| Biological regulation (GO:0050789) | 179 genes | 179 ✓ | ✓ VERIFIED |
| Biological regulation (GO:0065007) | 184 genes | 184 ✓ | ✓ VERIFIED |
| Cytoplasm | 172 genes | 172 ✓ | ✓ VERIFIED |
| ER membrane network | 23-24 genes | 24, 23, 23 ✓ | ✓ VERIFIED |
| Mitochondrial genome | 5 genes | 5 ✓ | ✓ VERIFIED |
| Positive regulation | 92 genes | 92 ✓ | ✓ VERIFIED |
| Wnt signaling | 16 genes | 16 ✓ | ✓ VERIFIED |

**STATUS**: ✓ ALL VERIFIED

---

## 5. Tier 1 Gene Prioritization

### Manuscript Claims (Lines 148-150)

**Total Tier 1 genes**: 6 genes ✓
- GABRA3 ✓
- EDNRB ✓
- HTR2B ✓
- HCRTR1 ✓
- FZD3 ✓
- FZD4 ✓

**Data source**: `enrichment_results/TIER1_VALIDATION_GENES.tsv`

**Neurotransmitter receptors**: 3/6 = 50% ✓
1. GABRA3 (GABA-A receptor) ✓
2. HTR2B (serotonin receptor 2B) ✓
3. HCRTR1 (orexin/hypocretin receptor 1) ✓

**STATUS**: ✓ ALL VERIFIED

---

## 6. Chromosomal Distribution

### Manuscript Claim (Line 99)
> "chi-square test comparing observed to expected counts yielded $\chi^{2} = 58.3$ (\textit{p} = 0.0186)"

**STATUS**: ❓ NEEDS DATA SOURCE

**Action required**: Verify chi-square statistic from chromosome distribution analysis

---

## 7. Selection Statistics

### Manuscript Claim (Line 113)
> "254 (63.3%) showed extremely small \textit{p}-values (\textit{p} $<$ 1$\times$10$^{-10}$)"

**Calculation using 401 genes**: 254/401 = 63.3% ✓ (percentage matches)

**But if actual count is 430**: 254/430 = 59.1% ≠ 63.3%

**STATUS**: ⚠️ DEPENDS ON GENE COUNT RESOLUTION

---

## 8. Annotation Coverage

### Manuscript Claim (Line 94)
> "Annotation coverage approached 80\% (Figure~\ref{fig:qc}B)"

**STATUS**: ❓ NEEDS VERIFICATION

**Data needed**: Count annotated vs unannotated genes in dog-selected set

---

## Summary Table of All Numerical Claims

| Line | Claim | Data Source | Verified | Status |
|------|-------|-------------|----------|--------|
| 23 | 17,046 orthologous genes | results_summary_3species.tsv | 17,046 | ✓ |
| 23 | 401 genes (2.35%) | results_3species_dog_only.tsv | **430 genes (2.52%)** | ❌ DISCREPANCY |
| 23 | α = 2.93×10⁻⁶ | Calculation | 2.93×10⁻⁶ | ✓ |
| 90 | median = 0.68 | Dog omega values | **Needs calc** | ⚠️ |
| 94 | median 0.66 | Dog omega values | **Inconsistent with Fig** | ⚠️ |
| 94 | 80% annotation | Annotation counts | **Needs verification** | ❓ |
| 99 | χ² = 58.3 | Chromosome analysis | **Needs verification** | ❓ |
| 99 | p = 0.0186 | Chromosome analysis | **Needs verification** | ❓ |
| 113 | 254 genes (63.3%) | P-value distribution | **Depends on 401 vs 430** | ⚠️ |
| 113 | p < 10⁻¹⁰ | P-value threshold | **Needs verification** | ❓ |
| 127 | p=0.0037 (protein) | enrichment_results_FULL.tsv | 0.00369 | ✓ |
| 127 | 117 genes (protein) | enrichment_results_FULL.tsv | 117 | ✓ |
| 127 | p=0.041 (Wnt) | enrichment_results_FULL.tsv | 0.0409 | ✓ |
| 127 | 16 genes (Wnt) | enrichment_results_FULL.tsv | 16 | ✓ |
| 135 | p=0.037 (protein) | enrichment_results_FULL.tsv | **0.0037 (ERROR!)** | ❌ CRITICAL |
| 148 | 6 Tier 1 genes | TIER1_VALIDATION_GENES.tsv | 6 | ✓ |
| 150 | 3/6 = 50% neuro | TIER1_VALIDATION_GENES.tsv | 3/6 | ✓ |

---

## Recommendations

### IMMEDIATE ACTIONS REQUIRED

1. **FIX CRITICAL ERROR** (Line 135):
   ```latex
   % Change from:
   Protein binding hub genes (117 genes, \textit{p}=0.037)
   % To:
   Protein binding hub genes (117 genes, \textit{p}=0.0037)
   ```

2. **RESOLVE GENE COUNT DISCREPANCY**:
   - User must determine correct count: 401, 430, or 347?
   - Update ALL instances in manuscript (abstract, results, figures)
   - Update percentage calculation accordingly
   - Document filtering criteria used

3. **RESOLVE OMEGA MEDIAN INCONSISTENCY**:
   - Calculate actual median omega from data
   - Update BOTH text (lines 94, 113) AND figure caption (line 90) consistently

### VERIFICATION NEEDED

4. Calculate median omega from `results_3species_dog_only.tsv`
5. Verify annotation coverage (80% claim)
6. Verify chi-square statistics for chromosome distribution
7. Verify 254 genes with p < 10⁻¹⁰ claim

---

## Data Files Referenced

1. `results_summary_3species.tsv` - All 17,046 genes with selection results
2. `results_3species_dog_only.tsv` - 430 dog-only genes (needs clarification)
3. `results_3species_dog_only_ANNOTATED.tsv` - Annotated dog-only genes
4. `enrichment_results/enrichment_results_FULL.tsv` - GO enrichment results
5. `enrichment_results/TIER1_VALIDATION_GENES.tsv` - Top 6 prioritized genes
6. Figure generation scripts (show "430 genes" not "401")

---

## Next Steps

1. **USER INPUT REQUIRED**: Clarify correct gene count (401 vs 430 vs 347)
2. Calculate median omega value from actual data
3. Verify remaining unchecked claims
4. Create correction script to fix all identified errors
5. Re-verify after corrections applied

---

**Report Generated**: 2025-12-01
**Verification Status**: INCOMPLETE - Critical issues found requiring user clarification
