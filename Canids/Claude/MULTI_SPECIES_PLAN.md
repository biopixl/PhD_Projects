# Multi-Species Phylogenomics Expansion Plan

**Date:** November 17, 2025
**Current Status:** Preparing 3-species analysis while 2-species analysis runs

---

## Current Analysis (Running)

**2-Species Comparison:**
- Dog (*Canis lupus familiaris*)
- Red fox (*Vulpes vulpes*)
- Status: 11% complete, running smoothly
- Will continue uninterrupted

---

## Expansion Plan: 3-Species Analysis

### Species to Add

**1. Dingo** (*Canis lupus dingo*) ✅
- **Status:** Data available in BioMart, downloading CDS now
- **Assembly:** ASM325472v1
- **Scientific value:** Semi-wild dog lineage, Australian adaptation
- **Phylogenetic position:** Sister to domestic dog

### Why Dingo?

**Scientific Benefits:**
1. **Resolves dog-specific vs. Canis-wide adaptations**
   - Distinguish domestic dog selection from general Canis evolution
   - Identify red fox-specific vs. shared Vulpes adaptations

2. **Independent adaptation signal**
   - Dingo adapted to Australian environment (~5,000-10,000 years)
   - Semi-wild lifestyle (between dog and wolf)
   - Unique dietary ecology (marsupials, reptiles, insects)

3. **Already in ortholog table**
   - Minimal additional data processing needed
   - 18,008 ortholog groups already include Dingo annotations

**Phylogenetic Tree (3-species):**
```
        ┌─── Red fox (Vulpes vulpes)
    ────┤
        │   ┌─── Dog (Canis lupus familiaris)
        └───┤
            └─── Dingo (Canis lupus dingo)
```

---

## Additional Species Options (Future)

### Option 1: Add Gray Wolf (if available elsewhere)
- **Species:** *Canis lupus*
- **Value:** Distinguish domestication from wild Canis
- **Status:** Not in Ensembl release 111, check NCBI

### Option 2: Add Arctic Fox (if available)
- **Species:** *Vulpes lagopus*
- **Value:** Convergent adaptation to cold environments
- **Status:** Need to check NCBI or other databases

### Option 3: Add other dog breeds
- **Available:** German Shepherd, Great Dane, Basenji, Boxer
- **Value:** Population-level variation, breed-specific selection
- **Status:** Available in Ensembl

---

## Implementation Steps

### Phase 1: Dingo Integration (In Progress)

**Step 1: Download Data** ✅
- [x] Download Dingo CDS sequences (ASM325472v1)
- [x] Decompress and verify

**Step 2: Extract 3-Species Orthologs**
- [ ] Run extraction script with min_species=3
- [ ] Creates new ortholog sets with Dog + Dingo + Red fox
- [ ] Expected: ~15,000-16,000 3-species orthologs

**Step 3: Create 3-Species Phylogeny**
- [ ] Create Newick tree file for 3 species
- [ ] Estimate branch lengths (optional: use divergence times)

**Step 4: Run Selection Analysis**
- [ ] Same aBSREL pipeline
- [ ] Test selection on Red fox branch
- [ ] Optionally test Dog branch vs. Dingo branch

**Step 5: Compare Results**
- [ ] Dog+RedFox vs. Dog+Dingo+RedFox
- [ ] Identify genes where 3rd species changes selection inference

### Phase 2: Additional Species (Future)

**Option A: Download from NCBI**
- Check NCBI for wolf, Arctic fox genomes
- Download RefSeq assemblies if available

**Option B: Use BioMart for other comparisons**
- Download new ortholog tables with different species
- Expand to 4-5 species if available

---

## Analysis Strategy

### Current (2-species): Dog vs. Red Fox
- **Test branch:** Red fox
- **Background:** Dog
- **Question:** What genes evolved in red fox lineage?

### Proposed (3-species): (Dog + Dingo) vs. Red Fox
- **Test branch:** Red fox
- **Background:** Dog + Dingo (Canis clade)
- **Question:** What genes evolved in red fox vs. entire Canis lineage?
- **Advantage:** More power, better background estimation

### Alternative (3-species): Test multiple branches
- **Test 1:** Red fox vs. (Dog + Dingo)
- **Test 2:** Dog vs. (Dingo + Red fox)
- **Test 3:** Dingo vs. (Dog + Red fox)
- **Question:** Which lineage shows most adaptation?

---

## Expected Outcomes

### With Dingo Added:

**1. Increased Statistical Power**
- Better background nucleotide substitution rate estimation
- More accurate dN/dS calculations
- Reduced false positives

**2. Biological Insights**
- Genes under selection in red fox vs. ALL Canis (not just dog)
- Dingo-specific adaptations (Australian ecology)
- Dog vs. Dingo domestication differences

**3. Refined Hypotheses**
- Current: "Red fox adaptations vs. dogs"
- Refined: "Red fox adaptations vs. Canis clade"
- New: "Dingo vs. Dog domestication signatures"

---

## Timeline

### Immediate (While 2-species analysis runs)
- [x] Check available species
- [x] Download Dingo CDS (in progress)
- [ ] Verify Dingo data quality
- [ ] Extract 3-species orthologs (~2 hours)

### After 2-species analysis completes (~17 hours)
- [ ] Analyze 2-species results fully
- [ ] Launch 3-species analysis
- [ ] Compare 2-species vs. 3-species results

### Future (Days-Weeks)
- [ ] Explore NCBI for wolf/Arctic fox
- [ ] Consider 4-5 species phylogeny
- [ ] Population-level analysis with dog breeds

---

## Resource Requirements

### 3-Species Analysis
- **Orthologs:** ~15,000-16,000 groups (vs. 18,008 for 2-species)
- **Runtime:** Similar to 2-species (~17-20 hours)
- **Storage:** +50 MB for Dingo CDS, +500 MB for alignments
- **No conflict:** Can run after current analysis completes

---

## Scientific Benefits

### Immediate
1. ✅ Better statistical power for red fox selection detection
2. ✅ Distinguish dog-specific vs. Canis-wide patterns
3. ✅ Dingo adaptation insights

### Long-term
1. Foundation for larger Canidae phylogenomics project
2. Comparative framework for domestication studies
3. Multi-species selection analysis methods

---

## Decision Points

**Option 1: Conservative**
- Complete 2-species analysis
- Analyze results thoroughly
- Then add Dingo for comparison

**Option 2: Proactive (Recommended)**
- Download Dingo data now ✅
- Extract 3-species orthologs while 2-species runs
- Launch 3-species analysis after 2-species completes
- Compare both analyses

**Option 3: Aggressive**
- Stop current 2-species analysis
- Restart with 3-species from the beginning
- Risk: Lose 2+ hours of computation

**Recommendation: Option 2** - Prepare Dingo data now, run 3-species after current analysis

---

## Next Steps

1. ✅ Download Dingo CDS (in progress)
2. Verify download and decompress
3. Update extract_cds_biomart.py to handle Dingo
4. Extract 3-species orthologs to new directory
5. Create 3-species phylogenetic tree
6. Wait for 2-species analysis to complete
7. Launch 3-species analysis

---

*Preparing multi-species expansion while current analysis runs*
*No interruption to ongoing work*
