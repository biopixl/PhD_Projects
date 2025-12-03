# Narrative Revision: From Single-Pathway to Multi-Pathway Framework

## Executive Summary

Our alternative hypotheses analysis revealed that the original narrative over-emphasized individual pathways (Wnt, neurotransmitters) while missing critical genes in **neural crest development**, **craniofacial morphology**, **additional Wnt pathway members**, and **behavior regulation**. This document explains why these genes were missed and proposes a revised multi-pathway narrative.

---

## Part 1: Why Critical Genes Were Missed

### 1.1 Scoring System Bias

The gene prioritization scoring system (`GENE_PRIORITIZATION_FOR_VALIDATION.tsv`) used a "relevance score" that was biased toward pre-selected pathway members:

| Gene | Tier | Total Score | **Relevance Score** | Category | Why Missed? |
|------|------|-------------|---------------------|----------|-------------|
| **TFAP2B** | 2 | 13.25 | **0.25** | Neural crest TF | Not in predefined pathways |
| **PORCN** | 3 | 11.0 | **0.0** | Wnt secretion | Not recognized as Wnt-related |
| **SLC6A4** | 2 | 14.0 | 3.0 | Serotonin transporter | Lower tractability score |
| **LEF1** | 2 | 14.5 | 2.0 | Wnt transcription | Not in Wnt enrichment |
| **FGFR2** | 2 | 15.25 | 2.75 | Craniofacial growth | Just below Tier 1 cutoff |

**Tier 1 cutoff: ≥16 points**

**Current Tier 1 genes:**
1. GABRA3 (18.75) - GABA receptor
2. EDNRB (17.75) - Endothelin receptor
3. HTR2B (16.25) - Serotonin receptor
4. HCRTR1 (16.25) - Orexin receptor
5. FZD3 (16.25) - Wnt receptor
6. FZD4 (16.0) - Wnt receptor

**Observation:** 4/6 (67%) are neurotransmitter receptors, 2/6 (33%) are Wnt receptors.

### 1.2 WNT Enrichment Incomplete

The WNT pathway enrichment (`WNT_PATHWAY_GENES.tsv`) only contained 7 genes:
- LEF1 (WNT transcription factor) ✓
- EDNRB (also cardiovascular)
- FZD3, FZD4 (receptors)
- CXXC4 (WNT inhibitor)
- SIX3 (homeodomain TF)
- DVL3 (dishevelled)

**Missing from enrichment:**
- **PORCN** - Porcupine O-acyltransferase (essential for ALL Wnt ligand secretion)
- **WIF1** - WNT inhibitory factor 1 (found in craniofacial category)

**Why?** The enrichment likely used a narrow gene list (e.g., KEGG WNT signaling pathway) that includes receptors and downstream effectors but misses ligand processing enzymes like PORCN.

### 1.3 Neural Crest Hypothesis Not Tested

The original analysis did not search for neural crest genes, despite the "neural crest hypothesis" being central to domestication syndrome theory (Wilkins et al. 2014).

**Major neural crest findings now revealed:**
- **TFAP2B** (p < 10⁻¹⁶, ω = 1.20) - Core neural crest specification factor
- **ZFPM2/FOG2** (p < 10⁻¹⁶, ω = 1.51) - Neural crest migration
- Multiple zinc finger proteins (ZNF598, ZMIZ2, ZNF662, ZNF692)

**TFAP2B** is particularly important:
- Transcription factor AP-2 beta
- Essential for neural crest induction and specification
- Loss causes craniofacial defects in mice
- Among the TOP 10 most significant genes in the entire dataset

---

## Part 2: Alternative Hypotheses Results Summary

### 2.1 Genes by Category (from 281 significant genes)

| Category | N Genes | Top Candidate | P-value | ω |
|----------|---------|---------------|---------|---|
| **Neural Crest** | 8 | TFAP2B | <10⁻¹⁶ | 1.20 |
| **Immune Function** | 8 | CD34, IL10, CCL21 | <10⁻¹⁶ | varied |
| **Pigmentation** | 6 | GABRA3 (also GABA) | <10⁻¹⁶ | 0.68 |
| **Craniofacial** | 4 | HOXC9, FGFR2, FGF18 | 10⁻¹⁵-10⁻¹¹ | 0.42-0.48 |
| **Behavior/Temperament** | 3 | **SLC6A4**, HCRTR1, HTR2B | <10⁻¹⁶ | 0.55-1.12 |
| **Metabolism/Growth** | 3 | IGFBP6, FGFR2 | <10⁻¹⁶ | 0.42-0.61 |
| **Stress Response** | 1 | SGK1 | 3.5×10⁻¹⁵ | 0.96 |
| **Cardiovascular** | 1 | EDNRB | <10⁻¹⁶ | 0.99 |

### 2.2 Major Discoveries

#### **SLC6A4 - Serotonin Transporter**
- **p < 10⁻¹⁶, ω = 1.12**
- THE gene for anxiety/fear behavior in mammals
- 5-HTTLPR polymorphism associated with human anxiety, depression
- Variants linked to dog temperament differences (Lit: Lit et al. 2013, Kubinyi et al. 2012)
- **This is a major finding** - strengthens neurotransmitter signaling hypothesis

#### **TFAP2B - Neural Crest Specification**
- **p < 10⁻¹⁶, ω = 1.20**
- Core transcription factor for neural crest cell fate
- Directly supports Wilkins' "neural crest hypothesis" of domestication syndrome
- Should be highlighted alongside neurotransmitter receptors

#### **FGFR2 - Craniofacial Development**
- **p = 8.7×10⁻¹², ω = 0.42**
- Mutations cause craniosynostosis syndromes in humans
- Central regulator of skull morphology
- Explains breed-specific craniofacial variation in dogs

#### **LEF1 and PORCN - Additional Wnt Members**
- **LEF1**: p < 10⁻¹⁶, ω = 0.52 - TCF/LEF transcription factor family
- **PORCN**: p < 10⁻¹⁶, ω = 0.69 - Required for Wnt ligand palmitoylation and secretion
- Both are core Wnt pathway genes but were **not in the WNT enrichment analysis**
- This means Wnt pathway has **9 significant genes**, not just 7

---

## Part 3: Statistical Re-evaluation

### 3.1 Updated Wnt Pathway Count

**Original WNT enrichment:**
- 7 genes, p = 0.0037 (11th ranked pathway)

**Corrected WNT pathway (including LEF1, PORCN, WIF1):**
- **9-10 genes** (depending on whether to count WIF1 as inhibitor)
- Re-run enrichment analysis to get updated p-value

### 3.2 Pathway Diversity Analysis

From 281 significant known genes:
- **Categorized in predefined hypotheses**: ~35 genes (12%)
- **Novel/unclassified**: ~246 genes (88%)

**This is a key finding:** The majority of significant genes do NOT fall into expected domestication categories, suggesting:
1. Domestication is highly **polygenic** and **complex**
2. Multiple biological systems are involved
3. Many genes have pleiotropic effects
4. We should not over-interpret single pathway hypotheses

---

## Part 4: Revised Narrative Framework

### 4.1 Multi-Pathway Model

**OLD narrative (over-simplified):**
> "We found enrichment for Wnt signaling pathway genes, suggesting Wnt pathway dysregulation underlies domestication traits."

**NEW narrative (balanced, multi-pathway):**
> "Positive selection in domestic dogs spans multiple biological systems, including **neurotransmitter signaling** (GABRA3, HTR2B, SLC6A4, HCRTR1), **developmental signaling pathways** (Wnt: FZD3, FZD4, LEF1, PORCN; FGF: FGFR2, FGF18), **neural crest specification** (TFAP2B, ZFPM2), and **immune function** (IL10, CD34, CCL21). This diversity suggests domestication involved coordinated changes across multiple systems rather than disruption of a single pathway."

### 4.2 Hierarchical Candidate Structure

**Tier 1: High-Confidence Validation Candidates (Original 6)**
- Neurotransmitter receptors: GABRA3, HTR2B, HCRTR1
- Wnt receptors: FZD3, FZD4
- Endothelin receptor: EDNRB

**Tier 1.5: High-Significance, Alternative Pathways (NEW)**
- Serotonin transporter: **SLC6A4**
- Neural crest TF: **TFAP2B**
- Craniofacial growth: **FGFR2**
- Wnt transcription/secretion: **LEF1**, **PORCN**

**Tier 2: Secondary Candidates**
- (Existing 68 genes)

**Tier 3: Exploratory Candidates**
- (Existing 254 genes)

### 4.3 Discussion Section Revisions

#### **Section 4.1: Multiple Biological Themes Emerge (NEW)**

"Unbiased genome-wide selection analysis identified 430 genes under positive selection in domestic dogs. Rather than clustering within a single biological pathway, significant genes span diverse functional categories:

**Neurotransmitter Signaling (50% of Tier 1):**
Three of six top candidates are neurotransmitter receptors (GABRA3, HTR2B, HCRTR1), and we additionally identified SLC6A4 (serotonin transporter, p < 10⁻¹⁶), a gene with well-established roles in anxiety and temperament regulation. Selection on neurotransmitter signaling genes likely underlies the behavioral changes characteristic of domestication.

**Neural Crest Development:**
TFAP2B (p < 10⁻¹⁶, ω = 1.20), a master regulator of neural crest specification, was among the most significant hits. This finding directly supports the 'neural crest hypothesis' of domestication syndrome (Wilkins et al. 2014), which proposes that selection on neural crest cells produces correlated changes in morphology, pigmentation, and behavior. ZFPM2/FOG2 (p < 10⁻¹⁶), another neural crest gene, reinforces this theme.

**Craniofacial Development:**
FGFR2 (p = 8.7×10⁻¹², ω = 0.42) and FGF18 (p = 3.7×10⁻¹¹) are core regulators of skull morphogenesis. Mutations in human FGFR2 cause craniosynostosis syndromes with dramatic craniofacial changes. Selection on FGF signaling genes likely contributes to the extreme skull shape diversity among dog breeds.

**Developmental Signaling Pathways:**
Wnt pathway genes showed modest enrichment (p = 0.0037), but our post-hoc analysis identified additional members not captured by standard pathway databases: LEF1 (Wnt transcription factor) and PORCN (Wnt ligand secretion enzyme), bringing the total to 9-10 Wnt-related genes. Wnt signaling regulates craniofacial development, pigmentation, and neural crest migration—all relevant to domestication phenotypes.

**Immune Function:**
Eight genes related to immune regulation were significant, including IL10 (anti-inflammatory cytokine, p = 4.5×10⁻¹⁵), CD34 (hematopoietic stem cell marker), and CCL21 (chemokine). This may reflect selection for altered immune responses or co-selection with other traits."

#### **Section 4.2: Why Single-Pathway Models Are Insufficient**

"Early studies proposed single-pathway explanations for domestication syndrome (e.g., 'neural crest hypothesis', 'Wnt pathway hypothesis'). Our data suggest a more complex picture:

1. **High genetic diversity**: 88% of significant genes do not fall into predefined domestication categories
2. **Pleiotropy**: Many genes (e.g., FGFR2, EDNRB) affect multiple traits
3. **Pathway crosstalk**: Wnt, FGF, and neural crest pathways interact during development
4. **Distributed targets**: Selection acts on receptors (FZD3/4), ligands (FGF18), transcription factors (LEF1, TFAP2B), and transporters (SLC6A4)

This distributed architecture is consistent with complex trait evolution, where many loci of small effect collectively produce phenotypic change."

---

## Part 5: Figure Revisions Needed

### 5.1 Figure 4 Panel B: Expand Categories

**Current:** Shows 6 Tier 1 genes grouped as "Neurotransmitter" vs "Developmental Signaling"

**Proposed revision:**
- Add **Tier 1.5 category** or expand to show "Extended Tier 1"
- Include: SLC6A4, TFAP2B, FGFR2, LEF1
- Color code by functional category:
  - **Blue**: Neurotransmitter signaling (GABRA3, HTR2B, HCRTR1, SLC6A4)
  - **Red**: Developmental signaling (FZD3, FZD4, LEF1, FGFR2)
  - **Green**: Neural crest (TFAP2B)
  - **Purple**: Cardiovascular (EDNRB)

### 5.2 New Supplementary Figure: Category Distribution

Create a bar chart showing number of significant genes per category:
- Neural crest: 8
- Immune: 8
- Pigmentation: 6
- Craniofacial: 4
- Behavior: 3
- Metabolism: 3
- Stress: 1
- Cardiovascular: 1
- **Uncategorized: 246** (emphasize this!)

### 5.3 Update Figure 3A Labels

Consider adding TFAP2B and SLC6A4 to the labeled genes (currently only shows Tier 1).

---

## Part 6: Manuscript Text Changes

### Results Section

**OLD (line ~180):**
> "Six genes met criteria for Tier 1 validation priority (Table X), including three neurotransmitter receptors (GABRA3, HTR2B, HCRTR1) and two Wnt receptors (FZD3, FZD4)."

**NEW:**
> "Six genes met initial criteria for Tier 1 validation priority (Table X), including three neurotransmitter receptors (GABRA3, HTR2B, HCRTR1) and two Wnt receptors (FZD3, FZD4). Post-hoc exploration of alternative hypotheses identified additional high-significance candidates narrowly excluded from Tier 1: SLC6A4 (serotonin transporter, score 14.0), TFAP2B (neural crest transcription factor, score 13.25), and FGFR2 (craniofacial growth factor receptor, score 15.25). Together, these nine genes represent diverse biological processes (neurotransmitter signaling, neural crest development, craniofacial morphogenesis, and developmental patterning)."

### Discussion Section

**Add new subsection after enrichment results:**

> **4.X Beyond Single-Pathway Hypotheses**
>
> "Our genome-wide approach identified selection signatures across multiple biological systems, challenging single-pathway models of domestication. While Wnt signaling showed enrichment (p = 0.0037), effect sizes were modest, and most significant genes (88%) did not fall into predefined domestication categories. This diversity suggests domestication involved distributed genetic changes rather than disruption of a master regulatory pathway.
>
> "Notably, we identified strong selection on genes central to alternative hypotheses:
> - **Neural crest hypothesis (Wilkins 2014):** TFAP2B (p < 10⁻¹⁶), a core neural crest specification factor, was among the most significant hits
> - **Craniofacial development:** FGFR2 and FGF18 (p = 10⁻¹¹-10⁻¹²) are master regulators of skull morphology
> - **Behavioral regulation:** SLC6A4 (p < 10⁻¹⁶), the serotonin transporter gene linked to temperament in dogs and humans
>
> "These findings support a **multi-system model** of domestication where coordinated selection on behavior, development, and physiology produced the domestication syndrome."

---

## Part 7: Limitations and Caveats

### 7.1 Post-hoc Analysis Caveat

**Add to Discussion:**

> "We note that the identification of TFAP2B, SLC6A4, and FGFR2 as high-priority candidates emerged from **post-hoc exploration** of alternative hypotheses, after observing strong neurotransmitter receptor and Wnt receptor enrichment. While these genes have genome-wide significant p-values (p < 10⁻¹⁶ to 10⁻¹²) and strong biological rationale, their lower prioritization scores reflect our original hypothesis-driven scoring system. Future work should use unbiased, data-driven prioritization methods that do not assume specific pathway involvement."

### 7.2 Pathway Database Limitations

> "Our Wnt pathway enrichment initially identified 7 genes, but post-hoc analysis revealed 2-3 additional Wnt members (LEF1, PORCN, WIF1) that were not captured by standard pathway annotations (KEGG, Reactome). This highlights limitations of pre-defined gene sets: PORCN (essential for ALL Wnt ligand secretion) received a relevance score of 0.0 because it was not in our Wnt pathway database. Comprehensive pathway analysis should combine multiple sources (KEGG, Reactome, GO, manual curation)."

---

## Part 8: Action Items

### Immediate:
1. ✅ Run alternative hypotheses analysis script (DONE)
2. ⬜ Re-run Wnt enrichment with LEF1, PORCN, WIF1 included
3. ⬜ Update manuscript Results section
4. ⬜ Add Discussion subsection on multi-pathway model
5. ⬜ Revise Figure 4 Panel B or create Supplementary Figure

### Secondary:
6. ⬜ Create supplementary table of categorized genes
7. ⬜ Add TFAP2B and SLC6A4 to Figure 3A labels
8. ⬜ Literature review on TFAP2B in domestication
9. ⬜ Literature review on SLC6A4 in dog behavior

---

## Part 9: Key Messages for Revised Narrative

**What to EMPHASIZE:**
1. **Multiple pathways** involved in domestication (not just Wnt)
2. **Neurotransmitter signaling** is strongest theme (4/6 Tier 1, includes SLC6A4)
3. **Neural crest genes** directly support Wilkins' hypothesis (TFAP2B, ZFPM2)
4. **Craniofacial development** explains morphological diversity (FGFR2, FGF18)
5. **Distributed genetic architecture** (88% of genes are uncategorized)

**What to DE-EMPHASIZE:**
1. Single-pathway causation ("Wnt pathway hypothesis")
2. Over-interpretation of enrichment p-values (p=0.0037 is significant but not dramatic)
3. Master regulator models (domestication is complex, polygenic)

**What to CAVEAT:**
1. Post-hoc discovery of TFAP2B, SLC6A4, FGFR2 (acknowledge data-driven vs hypothesis-driven)
2. Pathway database incompleteness (PORCN, LEF1 not in original enrichment)
3. Functional validation still needed (these are candidates, not proven causative)

---

## References for Narrative

- **Wilkins et al. 2014** - Neural crest hypothesis
- **Trut et al. 2009** - Fox domestication experiments
- **Lit et al. 2013** - SLC6A4 and dog behavior
- **Kubinyi et al. 2012** - Serotonin transporter polymorphism in dogs
- **Muenke & Wilkie 2001** - FGFR2 mutations and craniosynostosis
- **Sanchez-Villagra & van Schaik 2019** - Evolution of domestication syndrome

---

## Conclusion

The alternative hypotheses analysis revealed that our original narrative was **overly focused on individual pathways** due to:
1. Hypothesis-driven gene prioritization scoring
2. Incomplete pathway databases
3. Not testing neural crest or craniofacial hypotheses

A revised **multi-pathway narrative** better reflects the data:
- Strong selection on **neurotransmitter signaling** (receptors + transporter)
- Clear evidence for **neural crest involvement** (TFAP2B, ZFPM2)
- Selection on **craniofacial patterning** (FGFR2, FGF18)
- Multiple **developmental pathways** (Wnt, FGF, neural crest)
- High genetic **diversity** (88% uncategorized)

This complexity is consistent with domestication being a **polygenic, multi-system adaptation** rather than disruption of a single master pathway.
