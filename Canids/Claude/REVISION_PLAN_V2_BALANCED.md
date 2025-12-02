# Revision Plan V2: Balanced Multi-Pathway Interpretation
## Addressing Reviewer Feedback on Sections 3.4-3.5

**Date:** December 1, 2025
**Issue:** Current proposal over-prescribes Wnt pathway and under-discusses alternative pathways
**Reviewer Concern:** "Weak response to inability to refute possible explanations from multiple lines of evidence"

---

## I. PROBLEM IDENTIFICATION

### Current Issues in Sections 3.4-3.5

**Problem 1: Wnt Pathway Over-Emphasis**
- Wnt pathway is ranked **11th** in statistical significance (p = 0.041, FDR = 0.041)
- Yet proposal frames it as primary finding
- Title emphasizes Wnt: "Functional enrichment of genes under positive selection"
- Text: "Wnt signaling pathway emerged as the most significantly enriched category"
- **This is factually incorrect** - protein binding, biological regulation, and ER terms are all more significant

**Problem 2: Neurotransmitter Results Ignored**
- **3 of 6 Tier 1 genes** are neurotransmitter receptors:
  - **GABRA3**: GABA-A receptor (inhibitory neurotransmission, anxiety, sleep)
  - **HTR2B**: Serotonin receptor 2B (mood, social behavior, impulse control)
  - **HCRTR1**: Hypocretin/orexin receptor 1 (wakefulness, reward, motivation)
- These are **not Wnt pathway genes** but were grouped as "Wnt-associated" due to indirect connections
- No discussion of neurotransmitter signaling as a coherent theme

**Problem 3: Top Statistical Findings Under-Discussed**
From actual enrichment results, the TOP significant terms are:

| Rank | GO Term | P-value | FDR | Genes | Category |
|------|---------|---------|-----|-------|----------|
| 1 | Protein binding | 0.0037 | 0.0037 | 117 | Molecular Function |
| 2 | Regulation of biological process | 0.0068 | 0.0068 | 179 | Biological Process |
| 3 | Biological regulation | 0.0068 | 0.0068 | 184 | Biological Process |
| 4 | Cytoplasm | 0.0098 | 0.0098 | 172 | Cellular Component |
| 5 | Regulation of cellular process | 0.0099 | 0.0099 | 173 | Biological Process |
| ... | ... | ... | ... | ... | ... |
| **11** | **Wnt signaling pathway** | **0.041** | **0.041** | **16** | **Biological Process** |

**Problem 4: Missing Alternative Explanations**
- No discussion of why protein binding dominates (117 genes, p=0.0037)
- No consideration of ER/mitochondrial enrichment (p=0.019-0.032)
- No acknowledgment that broad regulatory terms may indicate distributed polygenic architecture
- Fails to address that enrichment could reflect general pleiotropy rather than specific pathway targeting

---

## II. COMPREHENSIVE DATA REVIEW

### A. Full Enrichment Results Re-Analysis

**TOP 15 SIGNIFICANT TERMS** (sorted by p-value):

```
1.  GO:0005515 | protein binding                           | p=0.0037 | 117 genes
2.  GO:0050789 | regulation of biological process          | p=0.0068 | 179 genes
3.  GO:0065007 | biological regulation                     | p=0.0068 | 184 genes
4.  GO:0005737 | cytoplasm                                 | p=0.0098 | 172 genes
5.  GO:0050794 | regulation of cellular process            | p=0.0099 | 173 genes
6.  GO:0042175 | nuclear outer membrane-ER network         | p=0.019  | 24 genes
7.  GO:0005789 | endoplasmic reticulum membrane            | p=0.023  | 23 genes
8.  GO:0098827 | endoplasmic reticulum subcompartment      | p=0.023  | 23 genes
9.  GO:0000002 | mitochondrial genome maintenance          | p=0.032  | 5 genes
10. GO:0048522 | positive regulation of cellular process   | p=0.032  | 92 genes
11. GO:0016055 | Wnt signaling pathway                     | p=0.041  | 16 genes ← CURRENT FOCUS
12. GO:0009056 | catabolic process                         | p=0.042  | 49 genes
13. GO:0048518 | positive regulation of biological process | p=0.042  | 95 genes
```

### B. Neurotransmitter System Genes in Tier 1

**GABRA3** (GABA-A Receptor Alpha-3 Subunit)
- **Function**: Inhibitory neurotransmission, GABAergic signaling
- **Relevance to domestication**:
  - Reduced fear/aggression (key domestication trait)
  - Tameness selection in foxes linked to GABAergic system
  - Anxiety regulation, social tolerance
- **Literature**: Trut et al. 2009 (fox domestication); Lin et al. 1999 (canine behavior)
- **Why not Wnt?**: No direct role in Wnt pathway; grouped as "Wnt-associated" due to indirect neural crest connection

**HTR2B** (5-Hydroxytryptamine Receptor 2B / Serotonin Receptor)
- **Function**: Serotonergic signaling, mood regulation, social behavior
- **Relevance to domestication**:
  - Impulse control, aggression modulation
  - Social bonding, human-directed behavior
  - Altered serotonin signaling in domesticated vs. wild canids
- **Literature**: Kukekova et al. 2018 (fox tame/aggressive behavioral genetics)
- **Why not Wnt?**: Serotonin receptor, not Wnt pathway component

**HCRTR1** (Hypocretin/Orexin Receptor 1)
- **Function**: Wakefulness, arousal, reward, motivation
- **Relevance to domestication**:
  - Sleep-wake regulation (narcolepsy in dogs, Lin et al. 1999)
  - Reward processing, human-directed attention
  - Motivation for human interaction
- **Literature**: Lin et al. 1999 (canine narcolepsy causative mutation)
- **Why not Wnt?**: Orexinergic signaling, distinct from Wnt

**CRITICAL OBSERVATION**: 50% of Tier 1 genes (3/6) are neurotransmitter receptors representing **three distinct neurotransmitter systems** (GABAergic, serotonergic, orexinergic). This is a coherent biological theme that was overlooked.

### C. Actual Wnt Pathway Genes in Tier 1

**FZD3** (Frizzled-3)
- **Function**: Wnt receptor, canonical Wnt signaling
- **Relevance**: Neural development, polarity, craniofacial patterning
- **Legitimately Wnt pathway**

**FZD4** (Frizzled-4)
- **Function**: Wnt receptor, vascular development, retinal angiogenesis
- **Relevance**: Ocular development, vascular patterning
- **Legitimately Wnt pathway**

**EDNRB** (Endothelin Receptor Type B)
- **Function**: Neural crest migration, pigmentation
- **Wnt connection**: Expressed in neural crest cells which are influenced by Wnt signaling
- **BUT**: EDNRB is NOT a Wnt pathway component itself - it's an endothelin receptor
- **Why relevant to domestication**: Piebald pigmentation phenotype (classic domestication syndrome trait)
- **More accurate categorization**: Neural crest development gene, indirectly related to Wnt

**REVISED TIER 1 CATEGORIZATION**:
- **Wnt pathway proper**: FZD3, FZD4 (2/6 = 33%)
- **Neurotransmitter receptors**: GABRA3, HTR2B, HCRTR1 (3/6 = 50%)
- **Neural crest development**: EDNRB (1/6 = 17%)

---

## III. ALTERNATIVE EXPLANATIONS FRAMEWORK

### A. Multiple Plausible Biological Themes

The enrichment data supports **at least 5 alternative/complementary explanations**:

**Hypothesis 1: Neurotransmitter System Modulation**
- **Evidence**: 3/6 Tier 1 genes are neurotransmitter receptors (GABA, serotonin, orexin)
- **Mechanistic link to domestication**:
  - Behavioral changes (reduced aggression, increased social tolerance)
  - Cognitive changes (human-directed attention, trainability)
  - Emotional regulation (fear reduction, tameness)
- **Literature support**: Strongest evidence from fox domestication experiments
- **Testable prediction**: Expression changes in brain regions controlling behavior/emotion
- **Cannot refute**: Behavioral domestication syndrome is well-documented

**Hypothesis 2: Protein-Protein Interaction Hub Evolution**
- **Evidence**: Protein binding is #1 enrichment (p=0.0037, 117 genes)
- **Mechanistic link**:
  - Hub proteins coordinate multiple pathways
  - Localized substitutions in interaction domains enable rewiring of regulatory networks
  - Pleiotropic effects via altered protein complexes
- **Literature support**: Epistasis and genetic architecture literature
- **Testable prediction**: Dog-specific substitutions cluster in interaction interfaces
- **Cannot refute**: Protein binding is the most significant enrichment

**Hypothesis 3: Endomembrane System Remodeling**
- **Evidence**: ER membrane terms rank #6-8 (p=0.019-0.023, 23-24 genes)
- **Mechanistic link**:
  - ER stress response, secretory pathway changes
  - Hormone signaling, receptor trafficking
  - Calcium signaling (ER is major Ca²⁺ store)
- **Relevance to domestication**:
  - Thyroid/adrenal hormone changes (HPA axis, stress response)
  - Altered development timing (paedomorphosis)
- **Cannot refute**: Significant enrichment, hormonal changes known in domestication

**Hypothesis 4: General Regulatory Network Evolution**
- **Evidence**: Broad regulatory GO terms rank #2-3, #5, #10, #13 (179-184 genes)
- **Mechanistic link**:
  - Polygenic architecture of domestication syndrome
  - Many small-effect regulatory changes distributed across genome
  - Coordinated trait evolution via shared regulatory modules
- **Literature support**: Polygenic adaptation theory, omnigenic model
- **Cannot refute**: Consistent with broadly distributed chromosomal signature (Fig 2)

**Hypothesis 5: Pleiotropic Developmental Pathway Targeting (includes Wnt)**
- **Evidence**: Wnt pathway ranks #11 (p=0.041, 16 genes); neural crest genes present
- **Mechanistic link**:
  - Wnt + neural crest + neurotransmitter receptors all pleiotropic
  - Coordinated craniofacial, pigmentation, behavioral traits
  - Shared developmental origin (neural crest → neurons + pigment cells)
- **Literature support**: Wilkins 2014 neural crest hypothesis
- **Cannot refute**: Multiple domestication-relevant genes converge on pleiotropic pathways

### B. Integrated Multi-Pathway Model

**The data does NOT support a single-pathway explanation.** Instead, evidence points to:

1. **Neurotransmitter signaling** (behavior, cognition) - **strongest Tier 1 signal**
2. **Protein interaction rewiring** (coordinating pleiotropy) - **strongest statistical signal**
3. **Developmental signaling** (Wnt, ER, neural crest) - **moderate signal, widely studied**
4. **Broad regulatory changes** (general biological regulation) - **consistent with polygenic architecture**

**CRITICAL POINT**: These are not mutually exclusive. Domestication syndrome likely involved:
- **Behavioral changes** → neurotransmitter receptors
- **Morphological changes** → developmental signaling (Wnt, neural crest)
- **Coordination mechanism** → protein binding hubs linking pathways
- **Distributed architecture** → many small-effect regulatory variants

---

## IV. REQUIRED REVISIONS TO SECTIONS 3.4-3.5

### A. Section 3.4: Functional Annotation and Pathway Enrichment

**CURRENT TEXT** (problematic):
> "Functional enrichment using a background of all 17,046 orthologs identified significant overrepresentation of Wnt signaling pathway components (GO:0016055), with 12-15 genes mapping to this pathway depending on annotation source (Figure 4)."

> "Wnt signaling pathway emerged as the most significantly enriched category (Figure 4A)..."

**REVISED TEXT** (balanced):
> "Functional enrichment analysis using all 17,046 orthologs as background identified multiple significant Gene Ontology terms spanning molecular function, biological process, and cellular component categories (Figure 4A). The most statistically significant enrichment was protein binding (GO:0005515, p=0.0037, FDR=0.0037, 117 genes), followed by general biological regulation terms (GO:0050789, GO:0065007; p=0.0068; 179-184 genes). Additional enrichments included endoplasmic reticulum membrane localization (p=0.019-0.023; 23-24 genes), mitochondrial genome maintenance (p=0.032; 5 genes), and Wnt signaling pathway (GO:0016055, p=0.041, FDR=0.041; 16 genes).

> "The diversity of enriched categories suggests that breed formation involved selection on multiple biological processes rather than a single pathway. Protein binding hub genes may coordinate pleiotropic effects across pathways, while specific signaling systems (Wnt, neurotransmitter receptors) may contribute to distinct domestication syndrome traits. We focus detailed analysis on three themes: **(1) neurotransmitter signaling** (behavioral/cognitive traits), **(2) protein interaction networks** (coordinating pleiotropy), and **(3) developmental signaling** (morphological traits including Wnt pathway)."

**NEW FIGURE 4 PANEL A** should show:
- TOP 10-15 GO terms sorted by p-value (not cherry-picked Wnt focus)
- Color-code by category: neurotransmitter (purple), protein binding (blue), developmental (orange), ER/mitochondrial (green), general regulation (gray)
- Horizontal bar chart with p-values, showing Wnt is 11th, not 1st

### B. Section 3.5: Prioritization of Candidate Genes

**CURRENT TEXT** (problematic):
> "Four of these six genes (FZD3, FZD4, EDNRB, GABRA3) are functionally associated with Wnt-related pathways or signaling components."

> "...convergence on these genes suggests that Wnt-associated processes may have been recurrent targets of lineage-specific selection."

**REVISED TEXT** (accurate):
> "The six Tier 1 genes represent **three distinct functional categories**: **(1) Wnt receptors** (FZD3, FZD4), **(2) neurotransmitter receptors** (GABRA3 [GABA], HTR2B [serotonin], HCRTR1 [orexin/hypocretin]), and **(3) neural crest development** (EDNRB [endothelin receptor, pigmentation]).

> "Notably, **neurotransmitter receptors constitute 50% of Tier 1 genes** (3/6), representing three independent neurotransmitter systems. This enrichment for neurotransmitter signaling components was not predicted a priori but emerges from convergent evidence across statistical selection strength, biological relevance, and experimental tractability. These genes provide plausible molecular substrates for behavioral domestication syndrome traits including reduced aggression (GABRA3), altered social behavior (HTR2B), and human-directed attention/motivation (HCRTR1). All three are expressed in behaviorally-relevant brain regions and have documented roles in canine behavior genetics.

> "The presence of both neurotransmitter receptors (behavioral) and developmental signaling genes (morphological) among top candidates suggests that breed formation involved **parallel selection on distinct trait dimensions** rather than a unified pathway mechanism. This aligns with the diverse phenotypic targets of artificial selection during breed diversification and argues against single-pathway explanations of domestication syndrome."

**NEW FIGURE 5 PANEL C** should categorize Tier 1 genes by:
- Neurotransmitter receptors (3): GABRA3, HTR2B, HCRTR1
- Wnt receptors (2): FZD3, FZD4
- Neural crest development (1): EDNRB
- Use color-coding matching Figure 4A theme colors

---

## V. REVISED AIM 1: MULTI-PATHWAY FUNCTIONAL VALIDATION

**CURRENT AIM 1 TITLE**:
"Functional Validation of Wnt Pathway Candidates"

**REVISED AIM 1 TITLE**:
"Functional Validation of Neurotransmitter and Developmental Signaling Candidates"

**Revised Aim 1.1: Comparative Expression Profiling**

**ADD** brain region-specific analysis for neurotransmitter receptors:
- **Amygdala** (fear/aggression - GABRA3)
- **Prefrontal cortex** (social cognition - HTR2B)
- **Hypothalamus** (arousal/motivation - HCRTR1)
- **Embryonic neural tissue** (development - FZD3, FZD4, EDNRB)

Compare across:
- 5 dog breeds (diverse behavioral/morphological phenotypes)
- Dingo (intermediate)
- Wolf (wild-type, when available)

**Revised Aim 1.3: Cell-Based Functional Assays**

**EXPAND** beyond Wnt reporters to include:
- **GABA receptor activity assays**:
  - Electrophysiology (patch-clamp) comparing dog vs. ancestral GABRA3 alleles
  - GABA-induced chloride flux measurements
  - Anxiety-related behavioral assay in transgenic mice (if feasible)

- **Serotonin receptor signaling assays**:
  - G-protein coupled receptor (GPCR) activation (cAMP, IP3 assays)
  - Dog vs. ancestral HTR2B variants
  - Mood/social behavior relevance

- **Wnt pathway activity** (retain original plan):
  - TOPFlash/FOPFlash reporters for FZD3, FZD4
  - Comparison of dog vs. ancestral alleles

**Expected Outcomes** (revised):
- Expression signatures for **both neurotransmitter and developmental genes**
- Functional validation of **behavioral AND morphological** candidate variants
- Comparative evidence across **multiple independent pathways**
- Manuscript: "Multi-pathway validation reveals neurotransmitter and developmental targets of dog breed formation"

---

## VI. DISCUSSION SECTION REVISIONS

### A. New Subsection: "Multiple Biological Themes Emerge from Unbiased Discovery"

**ADD NEW PARAGRAPH**:
> "A central finding of this study is the identification of **multiple biological themes** among genes under selection, rather than convergence on a single pathway. Neurotransmitter receptor genes (GABRA3, HTR2B, HCRTR1) constitute 50% of Tier 1 candidates and provide molecular substrates for behavioral domestication syndrome traits. Protein binding, the most statistically significant enrichment, may reflect evolution of hub proteins coordinating pleiotropic trait changes. Developmental signaling genes (FZD3, FZD4, EDNRB) contribute to morphological diversification via Wnt and neural crest pathways. The coexistence of these themes aligns with domestication syndrome comprising **multiple semi-independent trait dimensions** (behavioral, morphological, physiological) under distinct genetic control. This multi-pathway architecture argues against monolithic explanations and suggests that rapid phenotypic evolution during breed formation involved **parallel selection on functionally diverse loci** rather than coordinated changes in a single developmental program."

### B. Revised Subsection: "Wnt Pathway and Neural Crest Hypothesis"

**CURRENT TEXT**: Overemphasizes Wnt as primary finding

**REVISED TEXT**:
> "Among developmental signaling pathways, Wnt signaling showed significant enrichment (GO:0016055, p=0.041, 16 genes), consistent with prior hypotheses linking domestication to neural crest cell biology (Wilkins et al. 2014). However, Wnt enrichment ranked 11th among significant GO terms and was considerably less significant than protein binding (p=0.0037) or general biological regulation (p=0.0068). This suggests that while Wnt pathway genes underwent selection—plausibly contributing to craniofacial and pigmentation changes—they represent one component of a broader polygenic architecture rather than a dominant mechanistic driver. The neural crest hypothesis may explain **morphological** aspects of domestication syndrome, but complementary mechanisms (e.g., neurotransmitter receptor evolution) are needed to account for **behavioral** components."

### C. New Subsection: "Neurotransmitter Signaling and Behavioral Domestication"

**ADD NEW SECTION**:
> "The unexpected enrichment of neurotransmitter receptor genes among top candidates warrants focused discussion. GABRA3 (GABA-A receptor) mediates inhibitory neurotransmission and anxiety regulation; selection on this gene may underlie reduced fear responses characteristic of domesticated canids. HTR2B (serotonin receptor 2B) regulates mood and social behavior; altered serotonergic signaling has been documented in domesticated vs. wild foxes selected for tameness (Kukekova et al. 2018). HCRTR1 (orexin receptor) controls wakefulness and reward processing, potentially relevant to human-directed attention and trainability. Crucially, these three genes represent **independent neurotransmitter systems** (GABAergic, serotonergic, orexinergic), suggesting distributed selection on behavioral regulation rather than a single neuromodulatory pathway. This parallels findings from fox domestication experiments showing polygenic behavioral divergence between tame and aggressive lines. Future work integrating behavioral phenotyping with genotype data will be essential to validate proposed links between neurotransmitter receptor variants and specific temperament traits."

---

## VII. ABSTRACT REVISION

**CURRENT ABSTRACT**: Mentions Wnt prominently; neurotransmitters ignored

**REVISED ABSTRACT** (key sentence changes):

> REMOVE: "...with significant enrichment of Wnt signaling components (12-15 genes, GO:0016055)."

> REPLACE WITH: "Functional enrichment identified protein binding as the most significant category (GO:0005515, p=0.0037, 117 genes), followed by general biological regulation and endoplasmic reticulum localization. Specific pathways included Wnt signaling (GO:0016055, p=0.041, 16 genes) and multiple neurotransmitter systems."

> REMOVE: "Multi-criteria prioritization identified six high-confidence candidates—GABRA3, EDNRB, HTR2B, HCRTR1, FZD3, and FZD4—four functionally connected to Wnt pathways."

> REPLACE WITH: "Multi-criteria prioritization identified six high-confidence candidates representing three functional categories: neurotransmitter receptors (GABRA3, HTR2B, HCRTR1), Wnt receptors (FZD3, FZD4), and neural crest development (EDNRB). Notably, neurotransmitter receptors constituted 50% of top candidates, suggesting selection on behavioral regulation pathways."

---

## VIII. TITLE CONSIDERATION

**CURRENT TITLE**:
"Branch-Specific Phylogenomics to Identify Genetic Mechanisms of Dog Breed Formation: A Research Proposal"

**ALTERNATIVE TITLES** (less prescriptive):

**Option 1** (emphasizes discovery vs. prescription):
"Genome-Wide Discovery of Neurotransmitter and Developmental Genes Under Selection During Dog Breed Formation"

**Option 2** (emphasizes multi-pathway):
"Multi-Pathway Genomic Signatures of Dog Breed Formation: Neurotransmitter, Developmental, and Regulatory Gene Evolution"

**Option 3** (keeps current, but honest about findings):
"Branch-Specific Phylogenomics Reveals Distributed Selection on Neurotransmitter and Developmental Pathways During Dog Breed Formation"

**RECOMMENDATION**: Keep current title (general, doesn't prescribe pathway), but ensure abstract/introduction don't over-promise Wnt focus

---

## IX. FIGURE REVISIONS REQUIRED

### Figure 4 Panel A: GO Enrichment Bar Plot

**CURRENT**: Shows cherry-picked terms with Wnt prominent
**REQUIRED**: Show TOP 15 terms sorted by p-value

**New design**:
```
Protein binding (GO:0005515)                    ████████████████████ p=0.0037
Regulation of biological process (GO:0050789)   ████████████████     p=0.0068
Biological regulation (GO:0065007)              ████████████████     p=0.0068
Cytoplasm (GO:0005737)                         ███████████████      p=0.0098
Regulation of cellular process (GO:0050794)     ███████████████      p=0.0099
...
Wnt signaling pathway (GO:0016055)              ████████             p=0.041

Color key:
■ Protein binding (blue)
■ Neurotransmitter-related (purple) [if identifiable in top 15]
■ Developmental signaling (orange)
■ ER/mitochondrial (green)
■ General regulation (gray)
```

### Figure 5 Panel C: Tier 1 Gene Characteristics

**CURRENT**: Groups genes as "Wnt-associated" misleadingly
**REQUIRED**: Accurate functional categorization

**New table design**:
| Gene | Category | Function | Selection | Relevance | Tractability | Literature | Total |
|------|----------|----------|-----------|-----------|--------------|------------|-------|
| **Neurotransmitter Receptors** | | | | | | | |
| GABRA3 | GABA-A receptor | Inhibitory NT | 5.0 | 3.0 | 3.0 | 3.5 | 17.0 |
| HTR2B | Serotonin receptor | Mood/social | 4.8 | 3.0 | 3.0 | 3.2 | 16.5 |
| HCRTR1 | Orexin receptor | Arousal/reward | 4.5 | 3.0 | 3.0 | 4.0 | 17.5 |
| **Wnt Pathway** | | | | | | | |
| FZD3 | Wnt receptor | Development | 4.8 | 3.0 | 3.0 | 3.5 | 16.8 |
| FZD4 | Wnt receptor | Vascular/eye | 4.5 | 3.0 | 3.0 | 3.0 | 16.0 |
| **Neural Crest** | | | | | | | |
| EDNRB | Endothelin receptor | Pigmentation | 5.0 | 3.0 | 3.0 | 3.8 | 18.0 |

---

## X. IMPLEMENTATION CHECKLIST

### Immediate Actions (for next draft)

- [ ] **Abstract**: Remove Wnt-centric language; add neurotransmitter mention
- [ ] **Introduction**: Do NOT preview Wnt as expected finding; emphasize unbiased discovery
- [ ] **Section 3.4 (Enrichment)**:
  - [ ] Rewrite to present TOP enrichments first (protein binding, biological regulation)
  - [ ] Present Wnt as 11th-ranked term, not primary
  - [ ] Add discussion of neurotransmitter-related genes (cross-reference with Tier 1)
  - [ ] Acknowledge multiple biological themes framework
- [ ] **Section 3.5 (Prioritization)**:
  - [ ] Correct "4/6 Wnt-associated" error → "3/6 neurotransmitter, 2/6 Wnt, 1/6 neural crest"
  - [ ] Add paragraph on neurotransmitter receptor convergence
  - [ ] Discuss parallel selection on behavioral vs. morphological pathways
- [ ] **Figure 4A**: Regenerate showing all top 15 GO terms, color-coded by theme
- [ ] **Figure 5C**: Redesign table with accurate categorization
- [ ] **Aim 1**:
  - [ ] Retitle to include neurotransmitter validation
  - [ ] Add brain region-specific expression analysis
  - [ ] Add GABA/serotonin receptor functional assays
  - [ ] Revise expected outcomes to reflect multi-pathway approach
- [ ] **Discussion**:
  - [ ] Add "Multiple Biological Themes" subsection
  - [ ] Add "Neurotransmitter Signaling and Behavioral Domestication" subsection
  - [ ] Revise "Wnt Pathway" subsection to acknowledge it's one of several themes
  - [ ] Remove overly prescriptive language throughout

### Literature to Add

- [ ] Trut et al. 2009 (fox domestication, GABAergic system)
- [ ] Kukekova et al. 2018 (serotonergic signaling in tame/aggressive foxes)
- [ ] Lin et al. 1999 (canine narcolepsy, HCRTR1 mutation)
- [ ] Recent neurotransmitter + domestication papers (2020-2025)

### Data Re-Analysis (if time permits)

- [ ] Extract genes associated with GO terms for neurotransmitter signaling
- [ ] Check if GABRA3, HTR2B, HCRTR1 cluster in network analysis
- [ ] Quantify enrichment for "neurotransmitter receptor activity" GO term
- [ ] Cross-validate with Dog10K behavioral GWAS data (if accessible)

---

## XI. RESPONSE TO REVIEWER FRAMEWORK

**When addressing reviewer comments, structure response as**:

> **Reviewer Comment**: "The Go Analyses reveals alternative Go Terms that can be important like discussion of the neurotransmitter results. The proposal prescribes the Wnt pathway instead of acknowledging the inability to refute possible explanations from multiple lines of evidence."

> **Response**: We thank the reviewer for this critical observation. Upon re-examining our enrichment results, we recognize that the original manuscript **over-emphasized Wnt signaling** (ranked 11th, p=0.041) while **under-discussing** more statistically significant findings including protein binding (ranked 1st, p=0.0037, 117 genes) and neurotransmitter receptor genes comprising 50% of top prioritized candidates (GABRA3, HTR2B, HCRTR1).

> We have extensively revised Sections 3.4-3.5, the Abstract, Aim 1, and Discussion to:
> 1. **Present enrichment results in order of statistical significance**, acknowledging protein binding, general biological regulation, and ER localization as top-ranked terms
> 2. **Highlight neurotransmitter receptor enrichment** among Tier 1 genes (3/6 candidates: GABRA3 [GABA], HTR2B [serotonin], HCRTR1 [orexin])
> 3. **Explicitly discuss alternative explanations** including: (a) neurotransmitter signaling (behavioral traits), (b) protein interaction hub evolution (coordinating pleiotropy), (c) endomembrane system remodeling (hormonal signaling), (d) general regulatory network changes (polygenic architecture), and (e) developmental signaling pathways (morphological traits)
> 4. **Acknowledge that the data cannot refute** any of these explanations, and that domestication syndrome likely involved **parallel selection on multiple pathways** rather than a single mechanism
> 5. **Expand Aim 1** to include functional validation of neurotransmitter receptors (brain region-specific expression, GABA/serotonin receptor activity assays) in addition to Wnt pathway validation
> 6. **Revise interpretation framework** to emphasize multi-pathway architecture and data-driven discovery rather than prescriptive single-pathway narrative

> These changes align the proposal's interpretation with the actual statistical evidence and provide a more nuanced, scientifically defensible framework for understanding the genetic basis of dog breed formation.

---

## XII. KEY MESSAGES FOR REVISED PROPOSAL

**What the data actually show**:
1. **Protein binding** is the strongest statistical signal (117 genes, p=0.0037)
2. **Neurotransmitter receptors** dominate Tier 1 candidates (50%, 3/6 genes)
3. **Wnt signaling** is significant but ranked 11th (16 genes, p=0.041)
4. **Multiple biological processes** show enrichment, suggesting distributed polygenic architecture
5. **Cannot refute alternative explanations**: neurotransmitter, protein hubs, ER/mitochondria, general regulation

**What the proposal should argue**:
1. Breed formation involved **parallel selection on multiple pathways**
2. **Behavioral domestication** → neurotransmitter receptor evolution (GABA, serotonin, orexin)
3. **Morphological domestication** → developmental signaling (Wnt, neural crest)
4. **Coordination mechanism** → protein binding hubs enabling pleiotropy
5. **Integrated model** required; single-pathway explanations insufficient

**What the proposal should NOT argue**:
1. ~~Wnt pathway is the primary target of selection~~ (it's 11th!)
2. ~~4/6 Tier 1 genes are Wnt-associated~~ (factually incorrect - only 2/6)
3. ~~Convergence on Wnt indicates unified mechanism~~ (ignores neurotransmitter signal)
4. ~~Neural crest hypothesis explains domestication syndrome~~ (only morphological component)

---

## XIII. TIMELINE FOR REVISION

**Phase 1 (Days 1-2)**: Data review and figures
- Re-analyze enrichment results, extract neurotransmitter genes
- Regenerate Figure 4A (all top GO terms, color-coded)
- Regenerate Figure 5C (accurate Tier 1 categorization)

**Phase 2 (Days 3-4)**: Text revisions
- Revise Abstract, Introduction (remove Wnt prescription)
- Revise Sections 3.4-3.5 (balanced multi-pathway interpretation)
- Add literature on neurotransmitter systems + domestication

**Phase 3 (Days 5-6)**: Proposed Research Plan
- Revise Aim 1 title and approach (add neurotransmitter validation)
- Update Discussion (new subsections, balanced Wnt interpretation)
- Prepare response to reviewer document

**Phase 4 (Day 7)**: Final review and submission
- Comprehensive read-through for consistency
- Ensure all Wnt-prescriptive language removed
- Check that all alternative explanations discussed
- Submit revised proposal

---

## XIV. SUCCESS CRITERIA

**Revision will be successful if**:
1. Neurotransmitter receptors discussed with equal or greater prominence than Wnt
2. Enrichment results presented in order of actual statistical significance
3. Multiple alternative explanations explicitly acknowledged
4. Tier 1 gene categorization factually correct (3 neurotransmitter, 2 Wnt, 1 neural crest)
5. Aim 1 includes validation of both neurotransmitter AND developmental pathways
6. Discussion presents integrated multi-pathway model
7. Reviewer can confirm their concerns have been addressed comprehensively

---

**END OF REVISION PLAN V2**

*This plan provides a roadmap for transforming the current Wnt-centric proposal into a balanced, data-driven investigation of multiple pathways underlying dog breed formation. The key insight is that the data support neurotransmitter signaling as strongly as (or more strongly than) Wnt pathway involvement, and both should be investigated as complementary mechanisms for behavioral and morphological domestication syndrome traits, respectively.*
