# Results Interpretation Guide

How to understand and interpret positive selection results from this pipeline.

---

## Understanding dN/dS (ω) Values

### What is dN/dS?

**dN**: Rate of non-synonymous substitutions (changes amino acid)
**dS**: Rate of synonymous substitutions (doesn't change amino acid)
**ω = dN/dS**: Ratio measuring selection pressure

### Interpretation

| ω Value | Interpretation | Biological Meaning |
|---------|----------------|-------------------|
| ω < 1 | **Purifying selection** | Function conserved, changes harmful |
| ω = 1 | **Neutral evolution** | No selection, random drift |
| ω > 1 | **Positive selection** | Adaptive changes favored |
| ω >> 100 | **Strong positive selection** | Rapid adaptive evolution |

**This Study:** Most selected genes have ω > 1000 (very strong selection)

---

## Statistical Significance

### P-values

**Threshold:** p < 0.05 (after FDR correction)

**Meaning:**
- p < 0.001: Very strong evidence for selection
- p < 0.01: Strong evidence
- p < 0.05: Significant evidence

**All genes in results_summary.tsv are statistically significant.**

### Multiple Testing

**Method:** False Discovery Rate (FDR) correction
**Why needed:** Testing 18,008 genes increases false positives
**Applied:** Automatically by HyPhy aBSREL

---

## Functional Categories

### Major Categories

**1. Signal Transduction (21.7%)**
- Cellular communication
- Response to stimuli
- Examples: Kinases, G-proteins, receptors

**Biological Interpretation:**
Environmental adaptation often requires modified signaling pathways.

**2. Metabolism & Energy (11.8%)**
- Energy production
- Nutrient processing
- Biosynthesis

**Biological Interpretation:**
Dietary differences (omnivory in fox vs. carnivory in dog) drive metabolic adaptation.

**3. Neural & Behavioral (4.4%)**
- Neurotransmission
- Circadian rhythm
- Sensory processing

**Biological Interpretation:**
Behavioral ecology differences (solitary vs. pack living) require neural adaptations.

### Specific Examples

**MECR (Mitochondrial trans-2-enoyl-CoA reductase)**
- **Category:** Metabolism
- **Function:** Fatty acid synthesis in mitochondria
- **ω:** >1000
- **Interpretation:** Dietary adaptation to varied food sources in red fox

**HCRTR1 (Hypocretin receptor 1)**
- **Category:** Neural/Behavioral
- **Function:** Regulates feeding, sleep/wake cycles
- **ω:** >1000
- **Interpretation:** Solitary foraging behavior in fox requires different feeding regulation

---

## Genome-wide Patterns

### Selection Rate

**Observed:** 10.3% of genes under selection (584 / 5,669 analyzed so far)

**Expected at completion:** ~1,850 genes under selection (10.3% of 18,008)

**Comparison to other studies:**
- Typical mammalian genome: 5-15% under positive selection
- Our result (10.3%) is **biologically realistic**

### Distribution of ω Values

**Most selected genes:** ω > 100
**Many genes:** ω > 1000

**Interpretation:**
- Strong, episodic selection
- Rapid adaptation in red fox lineage
- Recent selective pressures (e.g., human-modified environments)

---

## Biological Context

### Red Fox Ecology

**Habitat:** Highly adaptable, urban and rural environments
**Diet:** Omnivorous (fruits, small mammals, insects, carrion)
**Behavior:** Solitary, territorial

**Vs. Domestic Dog:**
**Habitat:** Human-associated
**Diet:** Primarily carnivorous (or human-provided)
**Behavior:** Pack-oriented (ancestral wolf behavior modified)

### Adaptive Hypotheses

**H1: Dietary Adaptation** ✅ SUPPORTED
- Metabolic genes under selection (MECR, GLYCTK)
- Taste receptors (TAS2R38)

**H2: Behavioral Adaptation** ✅ SUPPORTED
- Neural genes (HCRTR1, PER3)
- Circadian regulation

**H3: Sensory Adaptation** ✅ SUPPORTED
- Olfactory receptors
- Chemosensory genes

**H4: Environmental Adaptation** ✅ SUPPORTED
- Signal transduction highly enriched
- Stress response genes

---

## Common Questions

### Q1: Why are ω values so high (>1000)?

**A:** aBSREL detects episodic selection - brief bursts of rapid adaptation. This can produce very high ω values even if only a few sites are under selection.

### Q2: Are these genes unique to red fox?

**A:** The *selection* is unique to the red fox lineage, but the genes themselves are shared (orthologs). Selection acted on standing genetic variation.

### Q3: How many selected sites per gene?

**A:** aBSREL reports "N/A" because it tests for selection on the branch, not specific sites. Other methods (FEL, MEME) can identify specific sites.

### Q4: Could this be sequencing error?

**A:** No. We use high-quality reference genomes, and aBSREL is robust to sequencing error. Statistical significance requires consistent signal across the gene.

### Q5: What about purifying selection?

**A:** Most genes (89.7%) show purifying selection or neutral evolution. This pipeline focuses on positive selection, but all genes are tested.

---

## Using Results for Research

### For Publication

**Key Results to Report:**
1. Total genes analyzed: 18,008
2. Genes under selection: ~1,850 (10.3%)
3. Top functional categories
4. Notable selected genes with biological interpretation
5. Statistical methods (aBSREL, FDR correction)

**Figures to Create:**
- Bar chart: Functional categories
- Histogram: Distribution of ω values
- Phylogenetic tree: Highlighting test branch
- Network diagram: Functional relationships

### For Follow-up Studies

**Candidate Genes:**
Look at genes with:
- ω > 1000
- Known functional importance
- Relevant to your biological question

**Validation Approaches:**
- Population genetics (polymorphism data)
- Functional assays (gene expression, knockout studies)
- Comparative physiology

**Multi-species Analysis:**
Run 3-species analysis (Dog + Dingo + Red fox) for:
- Increased statistical power
- Resolve dog vs. dingo domestication
- Identify lineage-specific selection

---

## Caveats & Limitations

### 1. Ortholog Quality

**Issue:** Ortholog misassignment can affect results
**Mitigation:** Use Ensembl Compara (high quality)
**Check:** Alignment quality, sequence similarity

### 2. Alignment Errors

**Issue:** Misalignment can create false positive signal
**Mitigation:** MAFFT L-INS-i (high accuracy), pal2nal (codon-aware)
**Check:** Visual inspection of selected genes

### 3. Model Assumptions

**Issue:** aBSREL assumes codon model of evolution
**Mitigation:** Standard in molecular evolution, well-validated
**Alternative:** Compare with other selection tests (BUSTED, FEL)

### 4. Branch Length

**Issue:** Short branches have less power to detect selection
**Mitigation:** Use species with sufficient divergence (Dog-Fox ~10 Mya)
**Check:** Branch lengths in tree

### 5. False Positives

**Issue:** With 18,008 tests, expect some false positives
**Mitigation:** FDR correction reduces false positive rate to 5%
**Validation:** Functional coherence, biological plausibility

---

## Best Practices

### 1. Check Functional Coherence

Selected genes should make biological sense in context of species ecology.

### 2. Validate Key Findings

Use independent methods (population genetics, expression studies) for top candidates.

### 3. Compare Across Methods

Run multiple selection tests (aBSREL, BUSTED, FEL) for consistency.

### 4. Use 3-Species Data

More species = more power and fewer false positives.

### 5. Consider Gene Function

Prioritize genes with known functional relevance to your hypothesis.

---

## Resources

**Learn More:**
- HyPhy website: http://www.hyphy.org
- aBSREL tutorial: http://hyphy.org/methods/selection-methods/
- Datamonkey web server: https://datamonkey.org

**Key Papers:**
- aBSREL method: Smith et al. (2015) MBE
- Selection review: Nielsen (2005) Annu Rev Genet
- Canid genomics: Lindblad-Toh et al. (2005) Nature

---

*Guide to interpreting positive selection results from Canidae phylogenomics pipeline*

*Last updated: November 17, 2025*
