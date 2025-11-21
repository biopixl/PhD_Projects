# Manuscript Conceptual Flow Analysis

## Core Scientific Novelty

1. **Methodological Innovation**: Three-species phylogenetic design
   - Dog (modern breeds - test group)
   - Dingo (ancient domestication, no breeds - control)
   - Fox (wild outgroup)
   - **Key insight**: Isolates breed formation from initial domestication

2. **Three Independent Genomic Patterns** (mechanistically neutral presentation):
   - Wnt signaling pathway enrichment (16 genes, p=0.041)
   - Neurotransmitter receptor evolution (GABRA3 strongest signal)
   - Cell adhesion/migration machinery

3. **Multiple Mechanistic Interpretations** (non-prescriptive):
   - Neural crest hypothesis
   - Behavior-first hypothesis  
   - Developmental bias framework

## Manuscript Narrative Arc

### Introduction → Methods → Results → Discussion

**Results Section Structure:**
1. **Genome-wide selection** (430 genes, 2.5%)
   - Current refs: fig:selection, fig:qc, fig:chromosome
2. **Functional enrichment** (Wnt, adhesion, neurotransmitters)
3. **Gene prioritization** (6 Tier 1 candidates)

**Discussion Structure:**
1. Three lines of evidence
2. Alternative frameworks
3. Methodological innovation
4. Limitations

## Figure Mapping to Narrative

### FIGURE 1: Study Design & Three-Species Approach
**Purpose**: Establish methodological innovation
**Panels needed**:
- A+B (COMBINED): Phylogenetic tree + timeline (cladogram style)
- C (STANDALONE): Conceptual study design flowchart
**Narrative role**: Introduction → Methods transition

### FIGURE 2: Genome-Wide Selection Results  
**Purpose**: Core finding - 430 genes under selection
**Panels needed**:
- A: Selection strength distribution (histogram/density)
- B: Volcano plot (omega vs p-value) ← **CURRENTLY BROKEN**
- C: Top genes ranked
- D: QC metrics (Q-Q plot, lambda)
**Narrative role**: Results section 3.1
**CRITICAL**: Fix omega outliers (currently shows only line)

### FIGURE 3: Functional Enrichment - Wnt Pathway Focus
**Purpose**: First line of evidence (Wnt enrichment)
**Panels needed**:
- A: GO enrichment bar plot
- B: Wnt genes scatter/volcano
- C: Wnt pathway diagram (cellular compartments)
- D: Functional category summary
**Narrative role**: Results section 3.2

### FIGURE 4: Gene Prioritization & Multi-Criteria Scoring
**Purpose**: Translation to validation targets
**Panels needed**:
- A: Heatmap of Tier 1 candidates ← **NOT PLOTTING**
- B: Multi-criteria scoring visualization
- C: Validation strategy
**Narrative role**: Results section 3.3 → Discussion transition

## Priority Order for Fixes

### TIER 1 (CRITICAL - manuscript currently references these)
1. **SelectionStrength_Combined** - needs outlier filtering
2. **QualityControl_Combined** - verify plotting correctly
3. **ChromosomeDistribution_Combined** - check rendering

### TIER 2 (HIGH - core narrative)
4. **Figure 2 comprehensive** - fix volcano plot blank issue
5. **Figure 1 study design** - establish methodology

### TIER 3 (MEDIUM - enrichment details)
6. **Figure 3 Wnt panels** - separate for better visibility
7. **Figure 4 heatmap** - debug plotting issue

## Data Quality Issues Identified

**CRITICAL PROBLEM**: Computational artifacts in omega values
- 26 genes with omega > 100 (max: 7.02×10^15)
- These compress all real data to invisibility
- **Solution**: Filter omega <= 5 (biologically realistic for sustained selection)

**Affected figures**:
- Figure 2 volcano plot (currently blank except threshold line)
- SelectionStrength Panel D
- Any omega-based visualization

## Recommended Figure Structure

Following narrative flow and addressing all issues:

**Session 1**: Fix data filtering globally
**Session 2**: Regenerate Tier 1 figures (currently in manuscript)
**Session 3**: Create Figure 1 (study design)
**Session 4**: Fix Figure 2 (selection results - full panel set)
**Session 5**: Separate Figure 3 panels (Wnt enrichment)
**Session 6**: Debug Figure 4 (heatmap)
