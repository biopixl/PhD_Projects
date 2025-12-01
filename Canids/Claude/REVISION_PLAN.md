# Conceptual Revision Plan: Research Proposal Format
## Branch-Specific Phylogenomics of Canid Domestication

**Document Version:** 1.0
**Date:** December 1, 2025
**Prepared by:** Isaac N. Aguilar Rivera

---

## I. EXECUTIVE SUMMARY

### Current Status
- Manuscript written as completed research project
- Reviewer feedback: "really REALLY good" but needs conversion to proposal format
- Core analysis complete: 401 genes under selection in dog lineage
- Strong Wnt pathway enrichment signal identified

### Revision Objective
Transform completed analysis into compelling research proposal that:
1. Positions preliminary findings within current research landscape
2. Articulates clear research question and funding rationale
3. Presents data as proof-of-concept for expanded investigation
4. Proposes concrete next steps including 4-way phylogenetic analysis

---

## II. LITERATURE REVIEW & RESEARCH CONTEXT (2020-2025)

### A. Recent Advances in Canid Genomics

**Dog10K Consortium (2023-2024)**
- Published comprehensive analysis of 2,000+ canids (Genome Biology, August 2023)
- Database updated October 2024 (Nucleic Acids Research)
- Resources: 1,611 dogs (321 breeds), 309 village dogs, 63 wolves, 4 coyotes
- Key finding: 94.9% of breeds form monophyletic clusters, 25 major clades
- Genomic constraint: 3.5% of genome under purifying selection (240 mammal alignment)
- **Gap identified:** Limited branch-specific selection analysis separating domestication vs. breed formation

**Neural Crest Hypothesis Debate (2024)**
- Ongoing controversy regarding unified mechanisms for domestication syndrome
- Evidence for Wnt/FGF signaling in neural crest development
- Need for finer temporal resolution in evolutionary analyses
- **Our contribution:** Dingo as intermediate evolutionary timepoint

### B. Wnt Signaling in Domestication

**Recent Findings:**
- TXNRD3 involvement in Wnt pathway affecting adipocyte differentiation
- Wnt signaling implicated in craniofacial, pigmentation, neural development
- Breed formation may recapitulate domestication pathways
- **Our contribution:** Genome-wide unbiased discovery of Wnt enrichment in dog-specific selection

### C. Wolf Genome Availability

**Current Status (2024-2025):**
- Greenland wolf genome (Canis lupus orion) sequenced
- Genome: 2,447 Mb, 40 chromosomal pseudomolecules + X/Y
- Undergoing annotation via Ensembl pipeline at EBI
- **Not yet publicly available in Ensembl database**
- Expected release: 2025-2026 (estimated)

**Implication for Proposed Research:**
- Enables future 4-way phylogenetic framework
- Will distinguish early domestication (dog+dingo vs. wolf) from breed formation (dog vs. dingo)
- Allows temporal layering of selective pressures

---

## III. RESEARCH PROPOSAL NARRATIVE FRAMEWORK

### A. Central Research Question

**Primary Question:**
*"What genomic changes distinguish breed-associated artificial selection from early domestication processes in dogs, and can these signals reveal the molecular basis of rapid phenotypic diversification?"*

**Funding Rationale (One-Sentence Pitch):**
*"We propose to use comparative phylogenomics to identify genetic mechanisms underlying dog breed formation by distinguishing recent artificial selection from ancestral domestication signals, providing insights applicable to understanding rapid evolutionary adaptation and the genetic architecture of complex traits."*

### B. Proposal Structure Outline

**1. Introduction (~2-3 pages)**
- **Current:** "we did" language → **Revised:** "we propose" language
- Open with knowledge gap: separating domestication vs. breed formation
- Present dingo as unique evolutionary reference point
- Articulate hypothesis: breed formation involved episodic selection on pleiotropic pathways
- **Add:** Future directions preview (Wnt validation, 4-way analysis when wolf genome available)
- End with clear statement of objectives

**2. Preliminary Results (~4-5 pages)**
- **Renamed from:** "Results" → "Preliminary Results"
- Present 3-species analysis as proof-of-concept
- Integrate methods into figure captions
- Demonstrate feasibility and discovery potential
- Show all figure panels cited in text (reviewer requirement)

**3. Proposed Research Plan (~3-4 pages)**
- **New section** building from Figure 5 prioritization
- Three research aims:
  - **Aim 1:** Functional validation of Wnt pathway candidates
  - **Aim 2:** Expanded phylogenetic framework with wolf genome
  - **Aim 3:** Integration with Dog10K population genomic data
- Timeline and milestones
- Expected outcomes and deliverables

**4. Broader Impacts**
- Comparative domestication biology
- Translational applications (canine health, conservation)
- Methodological contributions (branch-specific selection frameworks)

**5. References**

**Note:** Discussion section set aside for now (per reviewer feedback)

---

## IV. PRELIMINARY RESULTS: SUMMARY & FIGURE STRATEGY

### A. Core Findings Summary

**Dataset:**
- 17,046 high-quality orthologous genes across dog, dingo, red fox
- aBSREL branch-site model testing dog-specific selection
- Bonferroni-corrected threshold: p < 2.93×10⁻⁶

**Key Results:**
- **401 genes (2.35%)** with dog-specific positive selection
- **λ = 127.6:** Extensive deviation from neutrality (polygenic signal)
- **Median ω = 0.66:** Episodic selection within constrained loci
- **Wnt pathway enrichment:** 12-15 genes (GO:0016055, FDR < 0.05)
- **Top candidates:** 6 genes (Tier 1) including GABRA3, EDNRB, HTR2B, HCRTR1, FZD3, FZD4
- **4/6 top genes** functionally connected to Wnt signaling

**Interpretation:**
- Breed formation targeted pleiotropic developmental pathways
- Selection acted on discrete sites within essential genes
- Polygenic architecture consistent with multi-trait syndrome

### B. Essential Figures for Proposal (Reviewer-Aligned)

**Figure 1: Quality Control & Model Performance**
- **Keep all panels (A-D)**
- **Panel citations required:**
  - A: Q-Q plot showing λ = 127.6
  - B: Annotation coverage (78%)
  - C: Selection significance by annotation status
  - D: Gene-wide ω distribution (median 0.66)
- **Expanded caption:** Add brief methods on aBSREL implementation, quality metrics rationale
- **Narrative function:** Establish analytical rigor and interpret elevated λ as biological signal

**Figure 2: Chromosomal Distribution**
- **Keep all panels (A-C)**
- **Panel citations required:**
  - A: Raw counts per chromosome
  - B: Size-normalized proportions (~1.5% uniform)
  - C: Genomic positions along karyotype
- **Expanded caption:** Add chi-square test details, explain normalization approach
- **Narrative function:** Demonstrate broadly polygenic signature, rule out chromosomal hotspots

**Figure 3: Selection Statistics**
- **Keep all panels (A-C)**
- **Panel citations required:**
  - A: Volcano plot (p-value vs. ω)
  - B: ω distribution across all genes
  - C: Frequency across significance thresholds
- **Expanded caption:** Explain episodic selection concept, contrast with pervasive selection
- **Narrative function:** Illustrate pattern of constrained yet adaptive evolution

**Figure 4: Wnt Pathway Enrichment**
- **Keep all panels (A-C)**
- **Panel citations required:**
  - A: GO enrichment bar plot
  - B: Wnt gene selection metrics (p-value vs. ω)
  - C: Functional categorization of Wnt genes
- **Expanded caption:** Add g:Profiler parameters, define annotation sources (12-15 gene discrepancy)
- **Narrative function:** Primary discovery - unbiased identification of Wnt signal

**Figure 5: Gene Prioritization**
- **Critical for proposal - builds to future directions**
- **Keep all panels (A-D)**
- **Panel citations required:**
  - A: Distribution across priority tiers
  - B: Component scores (selection, relevance, tractability, literature)
  - C: Tier 1 gene characteristics
  - D: Total score vs. selection strength
- **Expanded caption:** Explain MCDA framework, scoring criteria, Tier definitions
- **Narrative function:** Transition to proposed research (these are targets for Aim 1)

**NEW Figure 6: Proposed 4-Way Phylogenetic Framework** (to be generated)
- Panel A: Phylogeny schematic (((Dog, Dingo), Wolf), Fox)
- Panel B: Expected contrast patterns (3-way vs. 4-way)
- Panel C: Temporal layering of selection pressures
- Panel D: Power analysis simulation for wolf branch
- **Purpose:** Visualize future research plan (Aim 2)

### C. Text Revisions for Figure Citations

**Current problem:** Not all panels explicitly cited in results text
**Solution:** Add specific panel references for each figure

**Example revision for Figure 4:**
```
Current: "Wnt signaling pathway components (GO:0016055), with 12-15 genes... (Figure 4)."

Revised: "Wnt signaling pathway components (GO:0016055) showed significant enrichment
among candidate genes (Figure 4A). Individual Wnt pathway genes exhibited low median
ω (0.64) but highly significant p-values (Figure 4B), consistent with episodic selection
within constrained loci. Functional annotation revealed diverse roles including receptor
activity, transcriptional regulation, and cytoskeletal organization (Figure 4C)."
```

---

## V. CONNECTION TO PRESSING RESEARCH NEEDS

### A. Temporal Resolution of Domestication Processes

**Current Gap:**
- Dog-wolf comparisons conflate 15,000-40,000 years of evolutionary change
- Cannot distinguish early domestication from Victorian-era breed formation
- Limits mechanistic inference and trait mapping

**Our Contribution:**
- Dingo as 8,000-10,000 YA divergence point
- **Preliminary data:** Identified 401 breed-associated candidates
- **Proposed expansion:** Add wolf genome for 3-layer temporal framework

**Broader Impact:**
- Applicable to other domesticated species (cat, horse, cattle)
- Informs conservation genetics (managing domestic×wild hybrids)
- Agricultural relevance (breeding program design)

### B. Genetic Architecture of Complex Traits

**Current Gap:**
- Domestication syndrome involves 10+ correlated traits
- Pleiotropic pathways difficult to identify via GWAS alone
- Need genome-wide evolutionary frameworks

**Our Contribution:**
- **Preliminary data:** Wnt pathway enrichment from unbiased screen
- **Proposed validation:** Experimental tractability scoring system (Figure 5)
- **Proposed integration:** Dog10K population data (Aim 3)

**Broader Impact:**
- General principles of polygenic adaptation
- Evolutionary constraint vs. evolvability
- Translational medicine (canine models for human disease)

### C. Methodological Advances

**Current Gap:**
- aBSREL underutilized for domestication studies
- Few frameworks for multi-criteria candidate prioritization
- Need reproducible workflows for comparative phylogenomics

**Our Contribution:**
- **Preliminary data:** Scalable pipeline for 17,000+ genes
- **Proposed release:** Snakemake workflow + MCDA framework
- **Proposed benchmark:** 4-way analysis validation when wolf available

**Broader Impact:**
- Applicable to any phylogenetic contrast (crop domestication, island evolution, human adaptation)
- Open science resource for community

---

## VI. PROPOSED RESEARCH PLAN (Future Directions)

### Aim 1: Functional Validation of Wnt Pathway Candidates

**Rationale:**
- Preliminary data: 4/6 Tier 1 genes Wnt-associated (FZD3, FZD4, EDNRB, GABRA3)
- Need experimental validation to establish causality
- High tractability scores suggest feasibility

**Approach:**
1. **Comparative expression profiling** (RNA-seq)
   - Tissues: Embryonic (E14-E18), adult (brain, skin, craniofacial)
   - Contrasts: 3-5 dog breeds (diverse phenotypes) vs. dingo/wolf
   - Identify expression divergence at candidate loci

2. **Protein structure modeling**
   - Map dog-specific substitutions to 3D structures
   - Predict functional impacts (AlphaFold2 + molecular dynamics)
   - Prioritize variants for experimental testing

3. **Cell-based functional assays** (pilot)
   - Wnt reporter assays (TOPFlash/FOPFlash)
   - Test dog vs. ancestral alleles of FZD3/FZD4
   - Quantify pathway activity differences

**Expected Outcomes:**
- Expression signatures linking genotype to developmental timing
- Structural predictions for 10-15 high-priority substitutions
- Pilot functional data for 2-3 candidate variants

**Timeline:** 18-24 months
**Funding need:** $150K-$200K (RNA-seq, structural modeling, cell culture)

---

### Aim 2: Expanded Phylogenetic Framework with Wolf Genome

**Rationale:**
- Greenland wolf genome expected in Ensembl 2025-2026
- 4-way tree: (((Dog, Dingo), Wolf), Fox)
- Enables layering of domestication vs. breed formation signals

**Approach:**
1. **Re-analysis with wolf genome**
   - Apply same aBSREL pipeline to 4-species dataset
   - Test selection on: (a) dog branch, (b) dog+dingo branch, (c) wolf branch
   - Expected ~17,000 genes with 4-way orthologs

2. **Temporal partitioning of selection signals**
   - **Early domestication:** Dog+dingo branch (shared) vs. wolf
   - **Breed formation:** Dog branch only (current 401 genes)
   - **Wild canid:** Wolf branch (control for lineage-specific effects)

3. **Comparison of functional enrichments**
   - Test if Wnt enrichment specific to breed formation or shared with domestication
   - Identify pathways unique to each temporal layer

4. **Power analysis and simulation**
   - Assess statistical power for wolf branch given divergence time
   - Simulate false positive/negative rates with 4-way topology

**Expected Outcomes:**
- Refined set of breed-specific candidates (may reduce from 401)
- Identification of 50-100 early domestication genes (dog+dingo branch)
- Partitioned functional themes by evolutionary layer
- Validation of 3-species preliminary findings

**Timeline:** 12-18 months (contingent on wolf genome release)
**Funding need:** $75K-$100K (computational resources, validation analysis)

---

### Aim 3: Integration with Dog10K Population Genomic Data

**Rationale:**
- Dog10K database: 1,611 dogs, 321 breeds, population-level variation
- Our candidates: 401 genes under breed-specific selection
- Integration reveals breed-specific vs. pan-breed signals

**Approach:**
1. **Retrieve Dog10K data for candidate genes**
   - Download VCF files for 401 gene regions
   - Extract haplotype data across 321 breeds

2. **Haplotype-based selection scans**
   - Use Dog10K tools: iHS, XP-EHH, XP-nsl
   - Identify breed-specific sweeps at candidate loci
   - Compare to genome-wide background

3. **Genotype-phenotype association**
   - Cross-reference with AKC breed standards (size, coat, behavior)
   - Test for enrichment of candidates in trait-associated regions
   - Focus on Wnt genes and craniofacial/pigmentation traits

4. **Phylogenetic vs. population signal concordance**
   - Do branch-specific aBSREL signals correspond to population sweeps?
   - Identify genes with strong signal in both analyses (high-confidence)
   - Identify discordant cases (different evolutionary modes)

**Expected Outcomes:**
- Breed-specific sweep map for 401 candidates
- Subset of 50-100 genes with convergent phylogenetic + population evidence
- Trait associations for Wnt pathway genes
- Integrated candidate ranking system

**Timeline:** 12 months
**Funding need:** $50K-$75K (data access, computational analysis, collaboration)

---

### Timeline Summary

| Phase | Duration | Aims |
|-------|----------|------|
| Year 1 | Months 1-12 | Aim 1 (expression), Aim 3 (Dog10K integration) |
| Year 2 | Months 13-24 | Aim 1 (structure/function), Aim 2 (wolf analysis) |
| Year 3 | Months 25-36 | Synthesis, validation, manuscript preparation |

**Total Budget Estimate:** $275K-$375K over 3 years

---

## VII. EXPANDED FIGURE CAPTIONS (Proposal Format)

### Figure 1: Quality Control and Analytical Performance Metrics

**Methods integrated:** We applied the adaptive Branch-Site Random Effects Likelihood (aBSREL) model implemented in HyPhy v2.5.59 to 17,046 one-to-one orthologous genes across domestic dog, dingo, and red fox. aBSREL uses likelihood ratio tests to compare models allowing versus prohibiting positive selection (ω > 1) on specified branches. Quality control included assessment of genomic inflation (λ), functional annotation completeness, and gene-wide ω distributions.

**(A)** Quantile-quantile plot of observed vs. expected -log₁₀(p-values) under the null hypothesis of no selection. The genomic inflation factor (λ = 127.6) reflects extensive deviation from neutral expectations, consistent with polygenic selection during breed formation. **(B)** Annotation coverage among 401 candidate genes passing Bonferroni correction (α = 2.93×10⁻⁶), showing 78% with functional annotation from Ensembl BioMart. **(C)** Distribution of selection significance (p-values) stratified by annotation status, demonstrating no bias toward annotated genes. **(D)** Distribution of gene-wide ω estimates (dN/dS ratio) across all candidate genes (median = 0.66), illustrating that episodic positive selection (ω > 1 at subset of sites) occurs within otherwise constrained coding regions (gene-wide ω < 1).

**Interpretation:** These metrics validate analytical rigor and support biological interpretation of elevated genomic inflation as reflecting authentic polygenic selection rather than technical artifacts.

---

### Figure 2: Chromosomal Distribution of Genes Inferred to Be Under Positive Selection

**Methods integrated:** Candidate genes were mapped to dog chromosomes (CanFam4.0) using Ensembl coordinates. Chromosomal clustering was assessed using chi-square goodness-of-fit test comparing observed to expected counts based on chromosome size (number of genes). Proportions were normalized by dividing selected genes per chromosome by total genes per chromosome.

**(A)** Raw counts of selected genes across 38 autosomes and X chromosome, showing broad distribution with modest variation (range: 6-47 genes). **(B)** Proportion of selected genes normalized by chromosome size, revealing approximately uniform ~1.5-2% selection rate across all chromosomes. Chi-square test yielded χ² = 58.3 (p = 0.0186), indicating minor deviation from uniform expectation attributable to chromosome size variation rather than localized clustering. **(C)** Genomic positions of 401 candidate genes plotted along chromosomes (karyotype-style), with red points indicating significant selection (p < 2.93×10⁻⁶) and gray points showing non-significant genes. Positions are dispersed without obvious hotspots.

**Interpretation:** The broadly polygenic signature is consistent with breed formation targeting multiple distributed loci rather than concentrated chromosomal regions, supporting the hypothesis of selection on a complex multi-trait syndrome.

---

### Figure 3: Summary of Branch-Specific Selection Statistics

**Methods integrated:** For each gene, aBSREL estimates a gene-wide ω value (average across sites and branches) and reports a likelihood ratio test p-value for episodic positive selection on the dog branch. Genes were classified by significance thresholds (p < 10⁻⁶, p < 10⁻¹⁰, etc.) to assess strength of selection signals.

**(A)** Volcano plot showing relationship between gene-wide ω (x-axis) and selection significance (y-axis, -log₁₀ p-value). Most candidate genes cluster at low ω (< 1) despite highly significant p-values, illustrating episodic selection model where only a subset of sites experience ω > 1 while gene averages remain constrained. **(B)** Density distribution of gene-wide ω values across all 17,046 genes, with candidate genes (red) showing median ω = 0.66, only slightly elevated above genome-wide background. **(C)** Frequency distribution of genes across significance thresholds, showing 254/401 candidates (63%) with extremely significant p < 10⁻¹⁰.

**Interpretation:** This pattern is characteristic of developmental and regulatory genes under strong functional constraint but tolerating adaptive substitutions at specific residues influencing phenotype—precisely the expectation for domestication-related loci.

---

### Figure 4: Functional Enrichment of Genes Under Positive Selection

**Methods integrated:** Functional enrichment was performed using g:Profiler (g:GOSt) with Fisher's exact test and g:SCS multiple-testing correction. Background set: all 17,046 orthologous genes. Annotation sources: Gene Ontology (GO), KEGG pathways, Reactome. Significance threshold: FDR < 0.05. Wnt pathway genes were defined by GO:0016055 (Wnt signaling pathway) cross-referenced with KEGG and Reactome annotations (12-15 genes depending on source).

**(A)** Top enriched Gene Ontology biological process terms among 401 candidate genes, showing Wnt signaling pathway (GO:0016055) as most significant enrichment (16 genes, p = 1.2×10⁻⁴). Other enriched categories include positive regulation of biological process, catabolic process, and cellular process. Gene counts and -log₁₀(p-values) shown for each term. **(B)** Selection metrics for individual Wnt pathway genes, plotting -log₁₀(p-value) vs. gene-wide ω. Wnt genes exhibit low median ω (0.64) but strong statistical significance, with several genes exceeding p < 10⁻¹⁰. **(C)** Functional categorization of Wnt-associated candidate genes by role: receptors (FZD3, FZD4), ligands, transcription factors, and cytoskeletal/regulatory components.

**Interpretation:** Wnt signaling pathway emerged from an unbiased genome-wide screen, suggesting its role in breed-associated diversification was not anticipated a priori but discovered through data. The low ω values indicate selection acted on constrained pleiotropic genes, potentially enabling coordinated trait evolution.

---

### Figure 5: Prioritization Outcomes Using Multi-Criteria Scoring

**Methods integrated:** Multi-Criteria Decision Analysis (MCDA) framework integrated four components: (1) Selection strength (0-10 points, scaled from -log₁₀ p-value), (2) Biological relevance (0-3 points, involvement in domestication pathways including Wnt, neural crest, pigmentation), (3) Experimental tractability (0-3 points, availability of assays, model systems, antibodies), (4) Literature support (0-4 points, prior associations with domestication phenotypes, citation density). Total scores (0-20) were used to assign priority tiers: Tier 1 (≥16), Tier 2 (13-15), Tier 3 (<13).

**(A)** Distribution of 401 candidate genes across priority tiers, showing 6 Tier 1 genes, 47 Tier 2 genes, and 284 Tier 3 genes. **(B)** Component scores (selection, relevance, tractability, literature) averaged across genes within each tier, demonstrating that Tier 1 genes excel across all criteria, not driven by single factor. **(C)** Characteristics of six Tier 1 genes (GABRA3, EDNRB, HTR2B, HCRTR1, FZD3, FZD4), showing total scores (16-18), primary functional annotations, and Wnt pathway associations. Four of six genes are functionally connected to Wnt signaling. **(D)** Scatter plot of total prioritization score vs. selection strength (-log₁₀ p-value), showing that while selection strength contributes to final score, high-ranking genes also require biological relevance and tractability.

**Interpretation:** The convergence on Wnt-associated genes among top candidates, despite pathway membership contributing only a minority of available points, suggests this functional theme emerged independently from statistical, biological, and practical considerations—strengthening confidence in its importance for breed formation.

---

### Figure 6: Proposed 4-Way Phylogenetic Framework (NEW - to be generated)

**Methods (proposed):** When the wolf genome becomes available on Ensembl (expected 2025-2026), we will expand the phylogenetic framework to include four species: domestic dog, dingo, gray wolf, and red fox. The topology (((Dog, Dingo), Wolf), Fox) will enable partitioning of selection signals into temporal layers: breed formation (dog branch only), early domestication (dog+dingo clade vs. wolf), and wild canid evolution (wolf branch). aBSREL analysis will test for episodic selection on each branch independently. Power analysis will simulate detection sensitivity given divergence times and branch lengths.

**(A)** Phylogenetic tree schematic showing relationships and branch labels for selection tests. Estimated divergence times: Dog-Dingo (8-10 KYA), Dog/Dingo-Wolf (15-40 KYA), Canid-Fox (~10 MYA). **(B)** Venn diagram comparing expected overlap between 3-way analysis (current) and 4-way analysis, predicting subset of breed-specific genes will be refined and early domestication genes will be identified on dog+dingo branch. **(C)** Conceptual diagram showing temporal layering of selective pressures: Victorian-era breed formation (dog), Neolithic domestication (dog+dingo), wild canid divergence (wolf). **(D)** Power analysis simulation results showing detection sensitivity for positive selection on wolf branch as function of selection strength (ω) and proportion of sites under selection, based on expected branch lengths and sequence divergence.

**Interpretation:** This framework will provide unprecedented temporal resolution for understanding domestication processes, distinguishing genetic changes associated with early human-dog coevolution from those arising during recent breed diversification. Integration with preliminary 3-way results will validate current findings and expand discovery space.

---

## VIII. REVISED INTRODUCTION (Proposal Language)

### Draft Outline

**Paragraph 1: Opening - The Puzzle**
> Dog domestication represents one of the earliest and most extensive cases of human-mediated phenotypic diversification, yet a critical question remains unresolved: which genomic changes underlie **early domestication** (the transition from wolf to dog) versus **breed formation** (the diversification of modern breeds)? [Change from past tense "resulted" to present tense "remains"]

**Paragraph 2: Why This Matters**
> Understanding this distinction is essential for three reasons: (1) it reveals the genetic architecture of rapid evolutionary adaptation, (2) it informs comparative domestication biology across species, and (3) it enables translational applications in canine health and conservation genetics. **We propose** to address this gap using a comparative phylogenomic framework that distinguishes temporal layers of selection.

**Paragraph 3: The Dingo as Key Innovation**
> Australian dingoes (*Canis lupus dingo*) provide a unique evolutionary reference point, having diverged 8,000-10,000 years ago—after initial domestication but before intensive breed formation. **We hypothesize** that comparing dog and dingo genomes, with appropriate outgroups, will isolate breed-specific selection signals from ancestral variation. This approach complements ongoing population-level efforts (Dog10K Consortium) by providing phylogenetic context.

**Paragraph 4: Preliminary Evidence**
> Our preliminary analysis of 17,046 genes across dog, dingo, and red fox has identified 401 candidates under dog-specific positive selection, with significant enrichment of Wnt signaling components. These findings suggest that breed formation involved episodic modifications in pleiotropic developmental pathways—a hypothesis requiring functional validation and expanded phylogenetic sampling.

**Paragraph 5: Research Objectives** [NEW]
> Here, we propose a three-aim research program to: **(1)** functionally validate Wnt pathway candidates through expression profiling and structural modeling, **(2)** expand the phylogenetic framework to include gray wolf when genome resources become available, enabling temporal partitioning of domestication vs. breed formation signals, and **(3)** integrate findings with Dog10K population genomic data to identify breed-specific vs. pan-breed selection patterns. This work will provide genome-wide insights into the evolutionary forces shaping dog diversification and establish a mechanistic foundation for understanding rapid phenotypic evolution in domesticated species.

**Paragraph 6: Funding Rationale**
> **We seek support for** experimental validation, computational expansion, and database integration that will transform preliminary phylogenomic discoveries into causal understanding. The anticipated availability of the wolf genome in 2025-2026 creates a time-sensitive opportunity to achieve unprecedented temporal resolution in domestication genomics. Our multi-criteria prioritization framework has identified tractable candidates ready for immediate functional investigation, while our scalable computational pipeline positions us to rapidly incorporate new genomic resources as they emerge.

---

## IX. PRESSING RESEARCH NEEDS ADDRESSED

### 1. Temporal Resolution in Domestication Studies

**Problem:**
Current dog-wolf comparisons collapse 15,000-40,000 years into a single contrast, conflating processes with distinct evolutionary drivers (natural selection during early cohabitation vs. artificial selection during breed formation).

**Our Solution:**
- **Preliminary:** Dingo provides 8-10 KYA intermediate timepoint
- **Proposed:** Wolf genome addition creates 3-layer framework
- **Impact:** Broadly applicable to other domesticates (cat, horse, cattle)

### 2. Genetic Architecture of Correlated Traits

**Problem:**
Domestication syndrome involves 10+ correlated phenotypes (morphology, behavior, physiology). Traditional GWAS struggles with pleiotropic pathways due to population structure and linkage.

**Our Solution:**
- **Preliminary:** Wnt enrichment from unbiased genome-wide screen
- **Proposed:** Expression + structural validation of pleiotropic candidates
- **Impact:** General principles for polygenic adaptation

### 3. Integration of Phylogenetic and Population Genomics

**Problem:**
Dog10K database (2,000+ genomes) lacks phylogenetic selection framework. Conversely, evolutionary studies lack population-level validation.

**Our Solution:**
- **Preliminary:** 401 phylogenetically-defined candidates
- **Proposed:** Cross-validation with Dog10K haplotype scans
- **Impact:** Convergent evidence from independent approaches

### 4. Functional Validation Gap

**Problem:**
Most genomic studies identify candidates but rarely validate function. Domestication field needs experimental follow-through.

**Our Solution:**
- **Preliminary:** MCDA tractability scoring (Figure 5)
- **Proposed:** RNA-seq, protein structure, Wnt reporter assays
- **Impact:** Mechanistic understanding, not just statistical association

### 5. Open Science and Reproducibility

**Problem:**
Computational workflows for comparative phylogenomics often not shared. Hard to reproduce or extend.

**Our Solution:**
- **Preliminary:** Snakemake pipeline for 17,000 genes
- **Proposed:** Public release with documentation, test datasets
- **Impact:** Community resource for other comparative systems

---

## X. IMPLEMENTATION TIMELINE

### Immediate Actions (Months 1-3)
- [ ] Revise introduction to proposal language
- [ ] Expand all figure captions with integrated methods
- [ ] Ensure all panels cited in preliminary results text
- [ ] Draft Aim 1 detailed protocol (RNA-seq, structural modeling)
- [ ] Design Figure 6 (4-way phylogeny schematic)

### Short-Term (Months 4-6)
- [ ] Complete Proposed Research Plan section (Aims 1-3)
- [ ] Draft Broader Impacts section
- [ ] Generate Figure 6 panels A-C (phylogeny, Venn diagram, temporal layers)
- [ ] Monitor Ensembl for wolf genome release announcements

### Medium-Term (Months 7-12)
- [ ] Begin Aim 1 preliminary expression analysis (if funded)
- [ ] Retrieve Dog10K data for 401 candidates (Aim 3 startup)
- [ ] Prepare power analysis simulations for 4-way framework (Figure 6D)

### Long-Term (Year 2+)
- [ ] Execute Aim 2 when wolf genome available
- [ ] Complete Aim 1 functional validation
- [ ] Integrate Aim 3 population genomic results
- [ ] Publish research papers on: (1) 4-way phylogenomic analysis, (2) Wnt validation, (3) integrated candidate catalog

---

## XI. BUDGET CONSIDERATIONS

### Personnel
- Graduate student or postdoc (1.0 FTE, 3 years): $180K-$240K
- Undergraduate research assistants (summer, 3 years): $15K-$20K

### Computational Resources
- HPC cluster time (4-way aBSREL analysis): $10K-$15K
- Data storage (Dog10K integration): $5K-$10K

### Experimental Costs
- RNA-seq (tissue collection, library prep, sequencing): $75K-$100K
- Protein structural modeling (AlphaFold2, MD simulations): $10K-$15K
- Cell-based assays (Wnt reporters, reagents): $25K-$35K

### Travel and Dissemination
- Conference presentations (3 years): $10K-$15K
- Open-access publication fees: $5K-$10K

### Indirect Costs
- University overhead (varies by institution): $80K-$120K

**Total Estimated Budget:** $415K-$580K for 3-year program

---

## XII. KEY LITERATURE TO CITE

### Added/Updated References for Proposal

**Recent Dog10K Publications:**
- Wang et al. (2024) Dog10K database. *Nucleic Acids Research* 53:D939-D950.
- Dog10K Consortium (2023) Genome sequencing of 2000 canids. *Genome Biology* 24:187.

**Neural Crest Hypothesis Debate:**
- Sánchez-Villagra et al. (2024) Neural crest cell hypothesis revisited. *Genetics* (check exact citation)

**Wnt Signaling in Development:**
- Keep existing Logan & Nusse (2004), Nusse (2008)
- Add recent review if available (2023-2024)

**Wolf Genome:**
- Greenland wolf genome consortium (expected 2025-2026) - cite when available

**Methodological:**
- Keep existing Smith et al. (2015) for aBSREL
- Add HyPhy 2.5 software citation

---

## XIII. QUESTIONS FOR REVISION DISCUSSION

1. **Scope:** Should we present this as 3-year comprehensive program or focus on Aim 1 only for smaller grant?

2. **Wolf genome:** Firm timeline from EBI/Ensembl or should we frame as "when available" throughout?

3. **Experimental depth:** Aim 1 RNA-seq depth—how many breeds (3 vs. 5 vs. 10)?

4. **Collaboration:** Should we propose formal collaboration with Dog10K consortium or just data access?

5. **Figure strategy:** Generate Figure 6 now as conceptual or wait until wolf genome confirmed?

6. **Discussion section:** Reviewer said "set aside"—do we include shortened version or fully remove?

---

## XIV. CHECKLIST FOR FINAL PROPOSAL

### Structure
- [ ] Introduction rewritten in "we propose" language
- [ ] Clear research question stated in one sentence
- [ ] Future directions previewed in introduction
- [ ] Results renamed to "Preliminary Results"
- [ ] Methods integrated into figure captions
- [ ] New "Proposed Research Plan" section (Aims 1-3)
- [ ] Discussion removed or condensed
- [ ] References updated with 2023-2025 citations

### Figures
- [ ] All panels (A, B, C, D) cited explicitly in text for each figure
- [ ] Figure captions expanded with methods details
- [ ] Figure 1 caption explains λ interpretation
- [ ] Figure 2 caption includes chi-square test
- [ ] Figure 3 caption explains episodic selection
- [ ] Figure 4 caption details g:Profiler parameters
- [ ] Figure 5 caption describes MCDA framework
- [ ] Figure 6 generated (4-way phylogeny schematic)

### Content
- [ ] Reviewer feedback addressed (proposal format, figure citations, captions)
- [ ] Recent literature integrated (Dog10K 2023-2024)
- [ ] Wolf genome timeline clarified
- [ ] 4-way analysis plan detailed
- [ ] Connection to pressing research needs articulated
- [ ] Budget justified
- [ ] Timeline realistic

---

## XV. NOTES AND NEXT STEPS

**Version Control:**
- This is REVISION_PLAN v1.0
- Track changes in manuscript using Git
- Save figure edits with version numbers

**Collaboration:**
- Consider reaching out to Dog10K consortium members
- Potential co-authors for wolf genome analysis?
- EBI/Ensembl contact for wolf genome timeline

**Data Management:**
- Archive current 3-way analysis results
- Prepare for 4-way data integration
- Plan Dog10K data download strategy

**Key Decision Point:**
- **MUST DECIDE:** Generate Figure 6 now or wait for wolf confirmation?
  - **Pro (now):** Complete proposal package, shows preparedness
  - **Con (wait):** May need revision if wolf genome specs differ

---

**END OF REVISION PLAN**

*Next update: After reviewer discussion or wolf genome announcement*
