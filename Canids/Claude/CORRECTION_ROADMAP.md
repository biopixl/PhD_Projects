# Manuscript Correction Roadmap
**Date**: 2025-12-01
**Manuscript**: manuscript_proposal.tex (commit 17aa92c)
**Based on**: DATA_VERIFICATION_REPORT.md

---

## Summary of Issues

### Critical Errors (Must Fix Immediately)
1. **P-value missing zero** (Line 135): 0.037 → 0.0037
2. **Gene count discrepancy**: 401 vs actual data (430 or 347)
3. **Median omega rounding**: Should be 0.67 (currently 0.66 in text, 0.68 in figure)

### Moderate Issues (Should Fix)
4. Several unchecked numerical claims need verification

---

## Verified Omega Value

**Calculation from data** (`results_3species_dog_only.tsv`):
```
Total values: 409
Median omega: 0.6670
Mean omega: 11.5762
```

**Actual median**: 0.6670
**Correct rounding**: 0.67 (two decimal places)

**Current manuscript**:
- Line 94, 113 (text): "median 0.66" ← rounds down
- Line 90 (figure caption): "median = 0.68" ← rounds up (expert review change)

**Recommendation**: Use 0.67 for maximum accuracy, or keep 0.67 throughout for consistency

---

## CRITICAL CORRECTION #1: P-value Error

**File**: `manuscript_proposal.tex`
**Line**: 135
**Priority**: CRITICAL - Scientific accuracy

### Current (INCORRECT):
```latex
Protein binding hub genes (117 genes, \textit{p}=0.037) may coordinate...
```

### Corrected:
```latex
Protein binding hub genes (117 genes, \textit{p}=0.0037) may coordinate...
```

### Context:
This was changed by expert reviewer from "most statistically significant" to a p-value, but they omitted the leading zero. The correct value from `enrichment_results/enrichment_results_FULL.tsv` is 0.0036932... which rounds to 0.0037, NOT 0.037.

---

## CRITICAL CORRECTION #2: Gene Count Discrepancy

**Files affected**:
- manuscript_proposal.tex (multiple lines)
- Figures (captions)

**Priority**: CRITICAL - Core result

### Current manuscript claims:
- Line 23 (Abstract): "401 genes (2.35%)"
- Line 84: "401 genes (2.35%)"
- Multiple other references

### Data reality:
```bash
# From results_3species_dog_only.tsv
Total genes: 430 (dog-only, mixed significance)

# With Bonferroni filter (p < 2.93e-6)
Significant genes: 347 (dog-only, significant)

# Manuscript percentage 401/17046 = 2.35% exactly matches claim
# BUT no data file contains exactly 401 genes
```

### Possible scenarios:

#### SCENARIO A: 430 is correct (most likely based on file evidence)
```latex
% Abstract and all instances:
430 genes (2.52%) showed significant dog-specific positive selection

% Recalculate percentage:
% 430/17,046 = 2.52%
```

**Evidence for this**:
- `results_3species_dog_only.tsv` has exactly 430 genes
- Figure scripts reference "430 genes"
- Older manuscript files show "430 genes"

#### SCENARIO B: 347 is correct (if only Bonferroni-significant counted)
```latex
% Abstract and all instances:
347 genes (2.04%) showed significant dog-specific positive selection
after Bonferroni correction (α = 2.93×10⁻⁶)

% Recalculate:
% 347/17,046 = 2.04%
```

**Evidence for this**:
- Manuscript emphasizes "after Bonferroni correction"
- 347 = dog-only AND p<2.93e-6

#### SCENARIO C: 401 is correct (requires user clarification)
If 401 is somehow correct, user must:
- Identify the data file or analysis that produces exactly 401
- Document the filtering criteria used
- Provide the source file for verification

### **REQUIRED ACTION**:
**User must clarify which count is correct before making changes**

---

## CORRECTION #3: Median Omega Consistency

**Files affected**: manuscript_proposal.tex
**Lines**: 90, 94, 113
**Priority**: MODERATE - Consistency and accuracy

### Actual data:
**Median omega = 0.6670** (rounds to 0.67)

### Option A: Use precise rounding (0.67)
```latex
% Line 90 (Figure 1D caption):
\caption{... (median = 0.67), illustrating...}

% Line 94:
The distribution of gene-wide $\omega$ values (median 0.67, Figure~\ref{fig:qc}D)

% Line 113:
median = 0.67
```

### Option B: Keep 0.66 (acceptable, rounds down from 0.6670)
Update line 90 to match lines 94 and 113:
```latex
% Line 90:
\caption{... (median = 0.66), illustrating...}
% Keep lines 94 and 113 as is
```

### Option C: Use more precision (0.667)
```latex
median = 0.667
```

**Recommendation**: Option A (use 0.67) for best accuracy with reasonable precision

---

## UNCHECKED CLAIMS REQUIRING VERIFICATION

### 1. Annotation Coverage (Line 94)
**Claim**: "Annotation coverage approached 80%"
**Action needed**: Calculate annotated/total from dog-selected genes

### 2. Chi-square statistic (Line 99)
**Claim**: χ² = 58.3, p = 0.0186
**Action needed**: Verify from chromosome distribution analysis output

### 3. Gene count with p < 10⁻¹⁰ (Line 113)
**Claim**: "254 (63.3%) showed extremely small p-values (p < 1×10⁻¹⁰)"
**Action needed**: Count genes meeting this threshold
**Note**: 254/401 = 63.3% ✓, but if actual count is 430, then 254/430 = 59.1%

### 4. Genomic inflation factor λ = 127.6
**Claim**: (Lines 90-91, Figure caption)
**Action needed**: Verify from QQ-plot analysis output

---

## IMMEDIATE NEXT STEPS

### Step 1: Fix Critical P-value Error (Can do immediately)
```bash
# In manuscript_proposal.tex, line 135:
sed -i '' 's/p}=0.037)/p}=0.0037)/g' manuscript_proposal.tex
```

### Step 2: User Decision Required
**STOP - Cannot proceed without user input on:**
1. Is correct gene count 401, 430, or 347?
2. What filtering criteria should be applied?
3. Which omega rounding preference (0.66, 0.67, or 0.68)?

### Step 3: After User Clarification
- Update all gene count references
- Update percentage calculations
- Ensure figure captions match text
- Update supplementary materials
- Verify figure generation scripts use correct counts

### Step 4: Verification Pass
- Re-run complete verification
- Check all updated numbers
- Verify consistency across manuscript

---

## FILES REQUIRING UPDATES

### Primary Files:
1. `manuscript_proposal.tex` - Main manuscript
   - Lines to check: 23, 84, 90, 94, 113, 135, and others
2. Figure captions (if embedded in .tex)
3. Supplementary materials (if gene counts mentioned)

### Related Files (may need updates):
1. Figure generation R scripts (currently show "430 genes")
2. `REVISION_PLAN_V2_BALANCED.md` (if it references gene counts)
3. Any analysis logs or documentation

---

## VERIFICATION CHECKLIST

After corrections are made:

- [ ] Line 135: p=0.0037 (not 0.037)
- [ ] All gene counts consistent throughout manuscript
- [ ] Percentage calculation matches gene count
- [ ] Median omega consistent in text and figures
- [ ] All enrichment p-values verified
- [ ] All gene counts in GO terms verified
- [ ] Tier 1 genes correctly listed
- [ ] Figure captions match results text
- [ ] Supplementary materials updated

---

## RECOMMENDED WORKFLOW

1. **IMMEDIATE** (no user input needed):
   - Fix p=0.037 → p=0.0037 on line 135

2. **REQUIRES USER DECISION**:
   - Determine correct gene count (401/430/347)
   - Choose omega rounding (0.66/0.67/0.68)

3. **AFTER USER INPUT**:
   - Make systematic find-replace for gene counts
   - Update all percentage calculations
   - Ensure figure-text consistency
   - Complete remaining verifications

4. **FINAL**:
   - Run complete verification pass
   - Generate corrected manuscript
   - Create git commit with detailed change log

---

**Status**: AWAITING USER INPUT on gene count and omega rounding preferences
**Next Action**: User must review DATA_VERIFICATION_REPORT.md and provide decisions
