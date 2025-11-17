# Multi-Species Expansion - Status Update

**Date:** November 17, 2025, 1:35 PM PST
**Status:** Dingo data prepared, ready for 3-species analysis

---

## Current Status

### 2-Species Analysis (Running)
- **Species:** Dog + Red fox
- **Progress:** 11% complete (~2,000 genes)
- **Status:** Running smoothly, ~17 hours remaining
- **Results:** 193 genes under selection (10.1% of analyzed)

### 3-Species Preparation (Complete) ✅
- **Species:** Dog + Dingo + Red fox
- **Status:** All data downloaded and ready
- **Next:** Extract 3-species orthologs after 2-species analysis completes

---

## Downloaded CDS Sequences

| Species | Assembly | CDS Sequences | File Size | Status |
|---------|----------|---------------|-----------|--------|
| **Dog** (*Canis lupus familiaris*) | ROS_Cfam_1.0 | 43,525 | 88 MB | ✅ Ready |
| **Dingo** (*Canis lupus dingo*) | ASM325472v1 | 34,534 | 70 MB | ✅ Ready |
| **Red fox** (*Vulpes vulpes*) | VulVul2.2 | 41,026 | 90 MB | ✅ Ready |

**Total:** 119,085 CDS sequences across 3 species

---

## Phylogenetic Relationships

```
3-Species Tree (prepared):

        ┌──── Red fox (Vulpes vulpes) - TEST BRANCH
    ────┤
        │   ┌── Dog (Canis lupus familiaris)
        └───┤
            └── Dingo (Canis lupus dingo)
```

**Tree file:** `data/phylogeny/canid_3species.tre`

**Scientific value:**
- **Dingo** provides phylogenetic resolution between domestic dog and wild Canis
- Better statistical power for detecting red fox selection
- Enables testing Dog vs. Dingo domestication differences

---

## BioMart Ortholog Data

**Available species in ortholog table:**
- ✅ Dog gene IDs
- ✅ Dingo gene IDs
- ✅ Red fox gene IDs
- ✅ Dog paralogs (for gene family analysis)

**Total ortholog entries:** 646,905 rows
**Unique dog genes:** 20,500

**Expected 3-species orthologs:** ~15,000-16,000 groups
(Reduced from 18,008 because Dingo is more stringent - must have ortholog in all 3 species)

---

## Setup Complete

### Files Created

**Phylogenetic trees:**
- ✅ `data/phylogeny/canid_3species.tre` - 3-species Newick tree

**Setup scripts:**
- ✅ `scripts/setup_3species_analysis.sh` - Automated 3-species setup
- ✅ Extraction script ready (already handles min_species parameter)

**Output directories (created):**
- ✅ `data/orthologs_3species/` - Will contain 3-species ortholog groups
- ✅ `alignments_3species/` - Protein alignments
- ✅ `codon_alignments_3species/` - Codon alignments
- ✅ `hyphy_results_3species/` - Selection test results
- ✅ `logs_3species/` - Analysis logs

---

## Next Steps

### Option 1: Wait for 2-species completion (Recommended)
1. Let 2-species analysis finish (~17 hours)
2. Fully analyze 2-species results
3. Then launch 3-species analysis for comparison
4. Compare statistical power and results

**Timeline:** Start 3-species tomorrow morning

### Option 2: Start 3-species extraction now
1. Run `bash scripts/setup_3species_analysis.sh`
2. Extract 3-species orthologs (~2 hours)
3. Ready to launch immediately after 2-species completes
4. Minimal delay between analyses

**Timeline:** 3-species extraction happens while 2-species runs

### Option 3: Run both analyses in parallel
1. Keep 2-species running (8 cores)
2. Start 3-species on remaining cores (2 cores)
3. Both complete at roughly same time

**Timeline:** Both finish together, but slower overall

---

## Recommended Workflow

**Now:**
- ✅ Dingo CDS downloaded
- ✅ 3-species tree prepared
- ✅ Setup script ready

**After 2-species completes (~17 hours):**
1. Parse and analyze 2-species results fully
2. Run 3-species ortholog extraction
3. Launch 3-species aBSREL analysis
4. Compare 2 vs. 3 species results

**Scientific comparison:**
- Which genes consistent across both analyses?
- Does 3rd species provide more statistical power?
- Any genes only detected in 3-species analysis?

---

## Expected Outcomes from 3-Species

### Statistical Benefits
1. **Better background model** - 2 Canis species vs. 1 Vulpes
2. **Increased power** - More accurate dN/dS estimation
3. **Reduced false positives** - More conservative threshold

### Biological Insights
1. **Red fox vs. Canis clade** (not just vs. dog)
2. **Dog vs. Dingo** domestication signatures
3. **Dingo-specific** Australian adaptations

### Comparison Questions
- Are the same genes selected in 2 vs. 3 species?
- Does adding Dingo change red fox selection inference?
- Which analysis is more powerful?

---

## Command to Run 3-Species Setup

When ready (after 2-species completes):

```bash
bash scripts/setup_3species_analysis.sh
```

This will:
1. Verify all CDS files present
2. Create output directories
3. Extract 3-species orthologs (~2 hours)
4. Prepare for Snakemake analysis

---

## Storage Requirements

**Current (2-species):**
- Orthologs: ~500 MB
- Alignments: ~1 GB
- Results: ~50 MB

**Additional (3-species):**
- Orthologs: ~400 MB (fewer groups, but 3 species each)
- Alignments: ~1.5 GB (3-species alignments larger)
- Results: ~50 MB

**Total:** ~3.5 GB for both analyses

---

## Species Not Available (Checked)

- ❌ **Gray wolf** (*Canis lupus*) - Not in Ensembl release 111
- ❌ **Arctic fox** (*Vulpes lagopus*) - Not in Ensembl release 111
- ❌ **African wild dog** (*Lycaon pictus*) - Not in Ensembl

**Note:** These may be available from NCBI RefSeq. Could be added in future if needed.

---

## Summary

✅ **Dingo data successfully prepared**
✅ **3-species infrastructure ready**
✅ **No interference with running 2-species analysis**
⏳ **Ready to launch 3-species when 2-species completes**

**Recommendation:** Let current analysis finish, then expand to 3-species for statistical validation and biological comparison.

---

*Prepared: November 17, 2025, 1:35 PM PST*
*Ready for 3-species phylogenomic analysis*
