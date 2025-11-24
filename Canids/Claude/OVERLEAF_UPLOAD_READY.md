# Overleaf Upload Package - Ready for Review

## ✓ All Harmonized Figures Integrated

### Files Ready for Upload to Overleaf:

#### 1. LaTeX Manuscript
- **File:** `manuscript_concise.tex` (18KB)
- **Location:** Root directory
- **Status:** ✓ Updated with all enhancements

**Key Updates:**
- ✓ Title: "Episodic Selection in Wnt Signaling and Neurotransmitter Pathways..."
- ✓ Correct numbers: **401 genes** (not 430), **λ=127.6** (not 67.7)
- ✓ Validation-first Results structure (QC → Distribution → Selection → Enrichment → Prioritization)
- ✓ Episodic selection emphasis throughout
- ✓ Convergent evidence: **4/6 Tier 1 genes are Wnt-associated**
- ✓ All figure paths correctly reference `figures/` directory

#### 2. Bibliography
- **File:** `references.bib` (17KB)
- **Location:** Root directory
- **Status:** ✓ Complete with all citations

#### 3. Harmonized Figures
- **Location:** `figures/` directory
- **Status:** ✓ All 5 main figures ready

**Figure Files:**
1. `Figure1_QualityControl.png` (689KB)
   - Quality control validation with λ=127.6, annotation coverage, omega distribution

2. `Figure2_ChromosomeDistribution.png` (652KB)
   - Genome-wide distribution validating polygenic architecture

3. `Figure3_SelectionResults.png` (555KB)
   - Volcano plot and selection landscape showing episodic selection pattern

4. `Figure4_WntEnrichment.png` (1.1MB)
   - GO enrichment analysis and Wnt pathway gene distributions

5. `Figure5_GenePrioritization.png` (625KB)
   - Multi-criteria prioritization showing convergent evidence for Wnt pathway

**Bonus:** `Figure5_GenePrioritization_Heatmap.png` (536KB)
   - Detailed heatmap of top 30 genes (optional supplementary figure)

---

## Upload Instructions for Overleaf:

### Step 1: Upload Main Files
Upload these 3 files to the **root directory** of your Overleaf project:
- `manuscript_concise.tex`
- `references.bib`
- README (optional)

### Step 2: Create Figures Directory
In Overleaf, create a new folder called `figures`

### Step 3: Upload All Figures
Upload all 5 (or 6) figure PNG files into the `figures/` folder:
- Figure1_QualityControl.png
- Figure2_ChromosomeDistribution.png
- Figure3_SelectionResults.png
- Figure4_WntEnrichment.png
- Figure5_GenePrioritization.png
- Figure5_GenePrioritization_Heatmap.png (optional)

### Step 4: Compile
Click "Recompile" in Overleaf. The manuscript should compile successfully with all figures properly integrated.

---

## Figure Integration Verification

### Current References in manuscript_concise.tex:
```latex
\includegraphics[width=\textwidth]{figures/Figure1_QualityControl.png}
\includegraphics[width=\textwidth]{figures/Figure2_ChromosomeDistribution.png}
\includegraphics[width=\textwidth]{figures/Figure3_SelectionResults.png}
\includegraphics[width=\textwidth]{figures/Figure4_WntEnrichment.png}
\includegraphics[width=\textwidth]{figures/Figure5_GenePrioritization.png}
```

All paths match the actual figure files in the `figures/` directory ✓

---

## What Each Figure Shows:

### Figure 1: Quality Control (Figure1_QualityControl.png)
**Panels:**
- (A) Q-Q plot with λ=127.6 (genuine widespread selection)
- (B) Annotation coverage: 78.9% (318/401 genes)
- (C) No annotation bias in selection detection
- (D) Omega distribution: median ω=0.66 (episodic selection signature)

### Figure 2: Chromosome Distribution (Figure2_ChromosomeDistribution.png)
**Panels:**
- (A) Gene counts per chromosome (no clustering)
- (B) Proportion of genes under selection (~1.5% across genome)
- (C) Genomic positions showing dispersed distribution (polygenic)

### Figure 3: Selection Results (Figure3_SelectionResults.png)
**Panels:**
- (A) Volcano plot: ω vs -log₁₀(p-value) with top genes labeled
- (B) Omega distribution showing episodic selection pattern
- (C) Selection strength categories: 254 very strong (63.3%)

### Figure 4: Wnt Enrichment (Figure4_WntEnrichment.png)
**Panels:**
- (A) GO enrichment bar plot highlighting Wnt signaling pathway
- (B) Wnt genes showing ω<1 yet p<10⁻¹⁰ (episodic selection)
- (C) Functional categories across pathway levels

### Figure 5: Gene Prioritization (Figure5_GenePrioritization.png)
**Panels:**
- (A) Tier distribution: 6 Tier 1, 47 Tier 2, 284 Tier 3
- (B) Score distributions across criteria
- (C) Tier 1 gene details showing 4/6 Wnt-associated
- (D) Scatter plot of selection vs total score

---

## Key Scientific Messages Integrated:

1. **Validation-First Approach**
   - Figures 1-2 establish analytical validity before biological results
   - QC metrics (λ=127.6) interpreted as genuine widespread selection
   - No annotation bias, no chromosome clustering

2. **Episodic Selection Mechanism**
   - Median ω=0.66 yet highly significant p-values
   - Site-specific positive selection within constrained genes
   - Allows morphological plasticity while maintaining function

3. **Data-Driven Wnt Discovery**
   - Unexpected enrichment from unbiased analysis
   - 12-15 Wnt pathway genes significantly enriched
   - Selection across multiple pathway levels (receptors, transducers, TFs)

4. **Convergent Evidence**
   - **4 of 6 Tier 1 genes show Wnt associations**
   - Independent criteria (selection, function, tractability, literature)
   - FZD3, FZD4, EDNRB, GABRA3 all link to Wnt signaling

5. **Polygenic Architecture**
   - 401 genes dispersed across genome
   - No selection hotspots
   - Consistent ~1.5% per chromosome

---

## GitHub Status:

**Repository:** https://github.com/biopixl/PhD_Projects
**Branch:** main
**Latest Commit:** 9b245c2 "Fix figure integration and paths for Overleaf"

All changes committed and pushed to GitHub ✓

---

## Alternative: Comprehensive Version

If you want the more detailed manuscript with extended QC interpretation:

**File:** `manuscript/manuscript_harmonized.tex` (28KB)

This version includes:
- More detailed QC discussion
- Extended episodic selection explanation
- Additional Data Availability and Acknowledgments sections
- Same figures (references `figures/` directory)

You can upload either manuscript version - both are complete and properly integrated with the harmonized figures.

---

**Last Updated:** 2025-11-24
**Commit:** 9b245c2
