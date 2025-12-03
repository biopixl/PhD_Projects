# Figure and Caption Updates Summary

**Date**: 2025-12-02
**Purpose**: Integrate multi-pathway narrative into figures and captions

---

## Figure Scripts Updated

### **Figure 3 - Selection Results** ✅ UPDATED & REGENERATED

**Script**: `scripts/figures/Figure3_SelectionResults.R`

**Change Made (Line 57-64):**
```r
# OLD: Only Tier 1 genes (6 genes)
top_genes <- c("GABRA3", "EDNRB", "HTR2B", "HCRTR1", "FZD3", "FZD4")

# NEW: Tier 1 + alternative hypothesis genes (9 genes)
top_genes <- c("GABRA3", "EDNRB", "HTR2B", "HCRTR1", "FZD3", "FZD4",
               "SLC6A4", "TFAP2B", "FGFR2")
```

**Result**: Figure 3 Panel A now labels **9 genes instead of 6**, including:
- Original Tier 1 (6): GABRA3, EDNRB, HTR2B, HCRTR1, FZD3, FZD4
- Alternative hypotheses (3): SLC6A4 (serotonin transporter), TFAP2B (neural crest), FGFR2 (craniofacial)

**Regenerated**: Yes ✅
- Files: `manuscript/figures/Figure3_SelectionResults.pdf` and `.png`
- Status: Successfully regenerated with expanded labels

---

## Manuscript Figure Captions Updated

### **Figure 3 Caption** ✅ UPDATED

**Location**: Line 121 in `manuscript_proposal.tex`

**OLD Caption (Panel A description):**
> "Volcano plot showing relationship between gene-wide ω (x-axis) and selection significance (y-axis, -log₁₀ p-value). Most candidate genes cluster at low ω (< 1) despite highly significant p-values..."

**NEW Caption (Panel A description):**
> "Volcano plot showing relationship between gene-wide ω (x-axis) and selection significance (y-axis, -log₁₀ p-value). **Labeled genes include Tier 1 candidates (GABRA3, EDNRB, HTR2B, HCRTR1, FZD3, FZD4) and high-significance genes from alternative hypotheses exploration (SLC6A4, TFAP2B, FGFR2), spanning neurotransmitter signaling, neural crest development, and craniofacial morphogenesis.** Most candidate genes cluster at low ω (< 1) despite highly significant p-values..."

**Addition**: ~60 words explicitly listing the 9 labeled genes and their functional categories

---

### **Figure 4 Caption (Enrichment/Wnt)** ✅ UPDATED

**Location**: Line 134 in `manuscript_proposal.tex`

**OLD Caption (Panel A description):**
> "Top enriched Gene Ontology terms among 430 candidate genes, sorted by statistical significance. Gene counts and -log₁₀(p-values) shown for each term."

**NEW Caption (Panel A description):**
> "Top enriched Gene Ontology terms among 430 candidate genes, sorted by statistical significance. **Protein binding emerged as the most significant category (117 genes, p=0.0037), followed by general biological regulation and Wnt signaling (16 genes, p=0.041), reflecting diverse biological processes rather than a single dominant pathway.** Gene counts and -log₁₀(p-values) shown for each term."

**OLD Caption (Panel B description):**
> "Selection strength (gene-wide ω) for neurotransmitter signaling genes and top Tier 1 candidates, grouped by functional category. Dashed line indicates neutral selection (ω=1)."

**NEW Caption (Panel B description):**
> "Selection strength (gene-wide ω) for neurotransmitter signaling genes and top Tier 1 candidates, grouped by functional category. **Categories include neurotransmitter receptors (GABRA3, HTR2B, HCRTR1), Wnt receptors (FZD3, FZD4), and neural crest development (EDNRB).** Dashed line indicates neutral selection (ω=1)."

**Addition**: Explicit mention of multi-pathway diversity (protein binding, general regulation, Wnt) and functional categories

---

### **Figure 5 Caption (Prioritization)** ✅ UPDATED

**Location**: Line 147 in `manuscript_proposal.tex`

**OLD Caption (Panel A description):**
> "Distribution of 430 candidate genes across priority tiers, showing 6 Tier 1 genes, 47 Tier 2 genes, and 377 Tier 3 genes."

**NEW Caption (Panel A description):**
> "Distribution of 430 candidate genes across priority tiers, showing 6 Tier 1 genes, 47 Tier 2 genes, and 377 Tier 3 genes. **Post-hoc analysis revealed that hypothesis-driven relevance scoring systematically underweighted genes outside predefined pathways, including SLC6A4 (score 14.0), TFAP2B (score 13.25), and FGFR2 (score 15.25) despite genome-wide statistical significance (p < 10⁻¹² to 10⁻¹⁶).**"

**OLD Caption (Panel D description):**
> "Scatter plot of total prioritization score vs. selection strength (-log₁₀ p-value)."

**NEW Caption (Panel D description):**
> "Scatter plot of total prioritization score vs. selection strength (-log₁₀ p-value), **illustrating that high prioritization requires both statistical significance and biological/practical relevance.**"

**Addition**: Acknowledges limitations of scoring system and identifies the three high-significance missed genes

---

## Summary Statistics

### **Figures Modified:**
- ✅ Figure 3: Script updated, figure regenerated, caption updated
- ✅ Figure 4: Caption updated (script already OK)
- ✅ Figure 5: Caption updated (script already OK)
- ✅ Figures 1 & 2: Captions remain accurate (no changes needed)

### **Total Caption Changes:**
- **3 figure captions** updated
- **~150 words** added across captions
- **Key themes**: Multi-pathway diversity, alternative hypotheses, limitations acknowledged

---

## Genes Now Highlighted in Figures

### **Figure 3 Panel A - Volcano Plot Labels:**

**Original (6 genes):**
1. GABRA3 - GABA receptor
2. EDNRB - Endothelin receptor
3. HTR2B - Serotonin receptor
4. HCRTR1 - Orexin receptor
5. FZD3 - Wnt receptor
6. FZD4 - Wnt receptor

**Updated (9 genes):**
1. GABRA3 - GABA receptor (Tier 1)
2. EDNRB - Endothelin receptor (Tier 1)
3. HTR2B - Serotonin receptor (Tier 1)
4. HCRTR1 - Orexin receptor (Tier 1)
5. FZD3 - Wnt receptor (Tier 1)
6. FZD4 - Wnt receptor (Tier 1)
7. **SLC6A4** - Serotonin transporter (p < 10⁻¹⁶, alternative hypothesis)
8. **TFAP2B** - Neural crest TF (p < 10⁻¹⁶, alternative hypothesis)
9. **FGFR2** - Craniofacial FGF receptor (p = 8.7×10⁻¹², alternative hypothesis)

**Categories Represented:**
- Neurotransmitter signaling: 4 genes (GABRA3, HTR2B, HCRTR1, **SLC6A4**)
- Wnt/developmental signaling: 2 genes (FZD3, FZD4)
- Neural crest: 2 genes (EDNRB, **TFAP2B**)
- Craniofacial: 1 gene (**FGFR2**)

---

## Caption Narrative Themes

### **Before (Original Captions):**
- Focused on technical methodology
- Listed results without interpretation
- No mention of pathway diversity
- No discussion of limitations

### **After (Updated Captions):**
- ✅ **Multi-pathway emphasis**: "diverse biological processes rather than a single dominant pathway"
- ✅ **Alternative hypotheses acknowledged**: "high-significance genes from alternative hypotheses exploration"
- ✅ **Functional categories explicit**: "neurotransmitter signaling, neural crest development, and craniofacial morphogenesis"
- ✅ **Limitations transparent**: "hypothesis-driven relevance scoring systematically underweighted genes"
- ✅ **Statistical rigor**: Exact p-values and scores provided for missed genes

---

## Alignment with Manuscript Text

### **Abstract → Figures → Results → Discussion → Conclusion**

All sections now consistently emphasize:

1. **Multi-pathway architecture**
   - Text: "distributed selection across multiple biological systems"
   - Figures: Labels span neurotransmitter, neural crest, craniofacial categories
   - Captions: "diverse biological processes rather than a single dominant pathway"

2. **Alternative hypotheses validation**
   - Text: Post-hoc analysis subsection (Lines 154-160)
   - Figures: SLC6A4, TFAP2B, FGFR2 labeled in Figure 3
   - Captions: "high-significance genes from alternative hypotheses exploration"

3. **High genetic complexity**
   - Text: "88% of significant genes did not fall into predefined categories"
   - Figures: Figure 5 caption acknowledges scoring limitations
   - Captions: Transparent about "systematically underweighted genes"

4. **Specific gene discoveries**
   - Text: Detailed discussion of SLC6A4, TFAP2B, FGFR2
   - Figures: All three labeled in Figure 3 Panel A
   - Captions: Listed with exact p-values and scores

---

## Technical Quality Checks

### **Figure 3 Regeneration:**
- ✅ Script modified successfully
- ✅ Figure regenerated without errors
- ✅ All 9 genes present in dataset (verified)
- ✅ PNG and PDF outputs created
- ✅ File sizes reasonable (~150-300 KB)
- ✅ Visual quality maintained

### **Caption Updates:**
- ✅ LaTeX syntax correct
- ✅ Special characters properly escaped (ω, subscripts, superscripts)
- ✅ Cross-references maintained (\ref{fig:...})
- ✅ Consistent formatting with other captions
- ✅ Line breaks appropriate for readability

### **Manuscript Compilation:**
- ⚠️ Not tested (pdflatex not installed on system)
- ✅ LaTeX syntax validated by manual inspection
- ✅ No obvious errors in figure inclusion commands
- ✅ File paths correct (figures/Figure*.png)

---

## Comparison: Original vs Updated Narrative

### **Original Figure Narrative:**
- Figure 3: "Top 6 candidates for validation"
- Figure 4: "Enrichment includes Wnt pathway"
- Figure 5: "6 Tier 1 genes prioritized by MCDA"
- **Overall**: Focus on hypothesis-confirming genes (neurotransmitter receptors, Wnt receptors)

### **Updated Figure Narrative:**
- Figure 3: "9 candidates spanning neurotransmitter, neural crest, and craniofacial systems"
- Figure 4: "Diverse processes with protein binding most significant, Wnt pathway one component"
- Figure 5: "6 Tier 1 genes, but scoring system underweighted 3 high-significance genes"
- **Overall**: Multi-pathway discovery with transparent acknowledgment of limitations

---

## Impact on Reader Understanding

### **Key Messages Now Conveyed Through Figures:**

1. **Visual Proof of Multi-Pathway Selection**
   - Figure 3 labels span 4 functional categories (not just 2)
   - Reader can SEE the diversity directly on volcano plot

2. **Transparency About Discovery Process**
   - Figure 5 caption acknowledges scoring limitations
   - Builds trust by showing "we found these despite our initial approach"

3. **Validation of Alternative Hypotheses**
   - TFAP2B labeled → neural crest hypothesis validated
   - FGFR2 labeled → craniofacial morphogenesis explained
   - SLC6A4 labeled → behavior beyond receptors

4. **Statistical Rigor**
   - Exact p-values provided in captions
   - Reader can assess significance independently
   - No "hand-waving" about gene importance

---

## Future Figure Improvements (Optional)

### **Not Yet Implemented (Beyond Scope):**

1. **Create New Figure 6 - Alternative Hypotheses Summary**
   - Bar chart showing gene counts per category
   - Emphasize 88% uncategorized
   - Would make multi-pathway architecture more visual

2. **Update Figure 4 Panel B - Expand Categories**
   - Add SLC6A4, TFAP2B, FGFR2 to plot
   - Color code by functional category:
     - Blue = Neurotransmitter
     - Red = Developmental
     - Green = Neural crest
     - Purple = Craniofacial

3. **Create Supplementary Figure S1 - Category Distributions**
   - Pie chart or treemap of categorized vs uncategorized
   - Detailed breakdown of 8 alternative hypothesis categories

### **Why Not Done Now:**
- Manuscript already significantly improved
- Main narrative goals achieved
- Additional figures = more complexity
- User can decide if these are needed

---

## Files Modified

### **R Scripts:**
1. `scripts/figures/Figure3_SelectionResults.R` - Lines 57-64 updated

### **Manuscript:**
1. `manuscript_proposal.tex` - Lines 121, 134, 147 updated (3 captions)

### **Figures Regenerated:**
1. `manuscript/figures/Figure3_SelectionResults.png`
2. `manuscript/figures/Figure3_SelectionResults.pdf`

### **Documentation:**
1. `FIGURE_UPDATES_Summary.md` (this file)
2. `MANUSCRIPT_UPDATES_Summary.md` (companion document for text changes)

---

## Validation Checklist

### **Figure 3:**
- [x] Script updated to include 9 genes
- [x] Figure regenerated successfully
- [x] Caption updated to list all 9 genes
- [x] Functional categories mentioned in caption
- [x] Visual quality maintained

### **Figure 4:**
- [x] Caption updated to emphasize diversity
- [x] Protein binding highlighted as most significant
- [x] Wnt pathway contextualized as "one component"
- [x] Functional categories listed in Panel B description
- [x] No script changes needed (already showing correct data)

### **Figure 5:**
- [x] Caption updated to acknowledge scoring limitations
- [x] Three missed genes listed with exact scores and p-values
- [x] Explanation of why genes were underweighted
- [x] Panel D description clarified
- [x] No script changes needed

### **Manuscript Integration:**
- [x] Figure captions align with Abstract
- [x] Figure captions align with Results section
- [x] Figure captions align with Discussion section
- [x] Figure captions align with Conclusion
- [x] Consistent terminology throughout (multi-pathway, alternative hypotheses, etc.)
- [x] All gene names spelled consistently
- [x] All p-values match between text and captions

---

## Summary

**Figures and captions successfully updated to reflect multi-pathway narrative:**

1. **Figure 3** now labels 9 genes (not 6), spanning neurotransmitter, neural crest, and craniofacial systems
2. **Figure 4 caption** emphasizes pathway diversity and multiple enriched categories
3. **Figure 5 caption** acknowledges scoring system limitations and identifies 3 underweighted genes
4. All captions **align with manuscript text** for consistent messaging
5. **Transparency** achieved by explicitly stating what was missed and why

The figures now **visually support** the multi-pathway narrative rather than contradicting it, and the captions provide sufficient context for readers to understand the complexity and distributed nature of selection during dog breed formation.
