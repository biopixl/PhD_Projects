# Figure Integration Guide for manuscript_proposal_compact.tex

**Status: ✓ ALL FIGURES INTEGRATED CORRECTLY**

Last Updated: December 2, 2025

---

## Figure 1: Quality Control

- **LaTeX Reference:** `\includegraphics[width=\textwidth]{figures/Figure1_QualityControl.png}`
- **File Location:** `manuscript/figures/Figure1_QualityControl.png`
- **Status:** ✓ EXISTS

---

## Figure 2: Chromosome Distribution

- **LaTeX Reference:** `\includegraphics[width=\textwidth]{figures/Figure2_ChromosomeDistribution.png}`
- **File Location:** `manuscript/figures/Figure2_ChromosomeDistribution.png`
- **Status:** ✓ EXISTS

---

## Figure 3: Selection Results (Volcano + Distributions)

- **LaTeX Reference:** `\includegraphics[width=\textwidth]{figures/Figure3_SelectionResults.png}`
- **File Location:** `manuscript/figures/Figure3_SelectionResults.png`
- **Last Updated:** Dec 2, 2025 18:20
- **Status:** ✓ EXISTS

---

## Figure 4: Functional Enrichment (NEUROTRANSMITTER FOCUS) ⭐

**CRITICAL FIGURE - Contains all latest updates**

- **LaTeX Reference:** `\includegraphics[width=\textwidth]{figures/Figure4_WntEnrichment.png}`
- **File Location:** `manuscript/figures/Figure4_WntEnrichment.png`
- **Last Updated:** Dec 2, 2025 19:40 (LATEST VERSION)
- **Generate Script:** `scripts/figures/Figure4_WntEnrichment_NEUROTRANSMITTER_FOCUS.R`

### To Regenerate:

```bash
Rscript scripts/figures/Figure4_WntEnrichment_NEUROTRANSMITTER_FOCUS.R
```

### Outputs:
- `manuscript/figures/Figure4_WntEnrichment.png` (combined 3-panel)
- `manuscript/figures/Figure4_WntEnrichment.pdf`
- `manuscript/figures/Figure4A_GOenrichment.png` (individual panel)
- `manuscript/figures/Figure4B_Tier1Genes.png` (individual panel)
- `manuscript/figures/Figure4C_FunctionalComparison.png` (individual panel)

### Key Features (Latest Version):

**Panel A:**
- Updated color scheme:
  - Biological Process: #5DADE2
  - Cellular Component: #52BE80
  - Molecular: #95A5A6
  - Wnt Pathway: #E74C3C (red)

**Panel B:**
- Shows all **9 Tier 1 genes** (CRITICAL FIX: removed GABRR1 which is Tier 2)
- Grouped by functional category:
  - Neurotransmitter (purple): SLC6A4, HTR2B, GABRA3, HCRTR1 (4 genes)
  - Neural Crest (cyan): TFAP2B, EDNRB (2 genes)
  - Wnt Pathway (red): FZD3, FZD4 (2 genes)
  - Craniofacial (orange): FGFR2 (1 gene)

**Panel C:**
- **6 functional categories** (updated caption)
- Categories: Neurotransmitter, Neural Crest, Wnt Pathway, Craniofacial, Molecular, Other
- Z-ordering: Smaller points render on top of larger ones
- Neural Crest label positioned naturally (no cutoff)
- sqrt scale for wide p-value range (0-340)
- Manual jitter to separate overlapping points

**Status:** ✓ EXISTS (LATEST - all updates integrated)

---

## Figure 5: Gene Prioritization (MCDA + Hybrid Framework)

- **LaTeX Reference:** `\includegraphics[width=\textwidth]{figures/Figure5_GenePrioritization.png}`
- **File Location:** `manuscript/figures/Figure5_GenePrioritization.png`
- **Status:** ✓ EXISTS

---

## Figure Caption Consistency

### Figure 4 Caption (manuscript_proposal_compact.tex lines 111-112):

✓ **Panel B:** "nine Tier 1 candidates" (CORRECT)
✓ **Panel C:** "six functional categories" (CORRECT)

Categories listed: Neurotransmitter, Neural Crest, Wnt Pathway, Craniofacial, Molecular, Other

---

## Complete Regeneration Workflow

If you need to regenerate Figure 4 with all latest updates:

```bash
# 1. Generate figure
Rscript scripts/figures/Figure4_WntEnrichment_NEUROTRANSMITTER_FOCUS.R

# 2. Verify outputs
ls -lh manuscript/figures/Figure4*.png

# 3. Check LaTeX compilation (optional)
cd manuscript && pdflatex manuscript_proposal_compact.tex
```

---

## Verification Summary

✅ All 5 figures present and correctly integrated
✅ Figure 4 contains latest neurotransmitter-focused updates
✅ Updated color schemes applied
✅ 9 Tier 1 genes (up from 6)
✅ 6 functional categories properly displayed
✅ Z-ordering and label positioning fixes applied
✅ Unicode LaTeX errors fixed (commit f0fb334)
✅ Figure-caption consistency verified
✅ Narrative integration complete

---

## Recent Updates

- **Dec 2, 2025 21:00:** CRITICAL FIX - Panel B now shows exactly 9 Tier 1 genes (removed GABRR1 which is Tier 2)
- **Dec 2, 2025 21:00:** Script updated to filter neurotransmitter genes to only include Tier 1
- **Dec 2, 2025 21:00:** Console output messages corrected (9 genes, not 6)
- **Dec 2, 2025 19:40:** Figure 4 Panel C - Final z-ordering and label positioning fixes
- **Dec 2, 2025:** Unicode LaTeX errors fixed throughout manuscript
- **Dec 2, 2025:** Figure 4 caption updated to reflect 9 genes and 6 categories
- **Dec 2, 2025:** Panel A color scheme updated to avoid conflicts with Panels B/C
- **Dec 1, 2025:** Hybrid prioritization framework integrated (9 Tier 1 genes)
