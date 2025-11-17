# Glossary - Phylogenomics & Selection Analysis Terms

Comprehensive definitions of terms used in this comparative genomics pipeline.

---

## A

**aBSREL (Adaptive Branch-Site Random Effects Likelihood)**
- Statistical test for detecting episodic positive selection
- Tests each branch independently for selection
- More powerful than traditional branch-site models for genome-wide scans
- Implemented in HyPhy software

**Adaptive Evolution**
- Evolution driven by natural selection favoring beneficial mutations
- Results in increased fitness
- Detected as elevated dN/dS ratios (ω > 1)

**Alignment (Sequence)**
- Arrangement of DNA, RNA, or protein sequences to identify regions of similarity
- **Protein alignment**: Alignment of amino acid sequences
- **Codon alignment**: Alignment of nucleotide sequences preserving reading frames
- **Multiple sequence alignment (MSA)**: Alignment of three or more sequences

**Assembly (Genome)**
- Computational reconstruction of a genome from sequencing reads
- Quality metrics: N50, completeness, contiguity
- Examples used: ROS_Cfam_1.0 (Dog), VulVul2.2 (Red fox)

---

## B

**Background Branch**
- Branches in a phylogeny NOT being tested for selection
- Used as null model for comparison in aBSREL
- Also called "reference branches"

**BioMart**
- Data mining tool for Ensembl databases
- Used to extract ortholog relationships across species
- Web interface: https://ensembl.org/biomart

**Branch**
- Lineage in a phylogenetic tree connecting nodes
- **Test branch**: Branch tested for selection (e.g., red fox lineage)
- **Background branch**: Other branches in the tree

---

## C

**CDS (Coding Sequence)**
- Portion of DNA or RNA that codes for protein
- Starts with start codon (ATG), ends with stop codon
- Used as input for selection analysis

**Codon**
- Three-nucleotide sequence coding for one amino acid
- 64 possible codons, 20 amino acids
- Synonymous codons code for same amino acid

**Codon Alignment**
- Nucleotide alignment preserving reading frames
- Each codon (3 nucleotides) aligns as a unit
- Required for accurate dN/dS calculation
- Generated using pal2nal in this pipeline

**Comparative Genomics**
- Study of similarities and differences between genomes
- Identifies conserved and divergent regions
- Reveals evolutionary relationships and functional elements

**Conda**
- Package and environment management system
- Ensures reproducible software installations
- Used for managing bioinformatics tools (MAFFT, HyPhy, etc.)

---

## D

**dN (Non-synonymous substitution rate)**
- Rate of mutations that CHANGE amino acid sequence
- Subject to natural selection
- Numerator in dN/dS ratio

**dS (Synonymous substitution rate)**
- Rate of mutations that DO NOT change amino acid sequence
- Largely neutral, not affected by selection
- Denominator in dN/dS ratio
- Proxy for background mutation rate

**dN/dS Ratio (ω, omega)**
- Ratio of non-synonymous to synonymous substitution rates
- **ω < 1**: Purifying selection (conserved)
- **ω = 1**: Neutral evolution
- **ω > 1**: Positive selection (adaptive)
- **ω >> 1**: Strong positive selection

---

## E

**Ensembl**
- Genome database and annotation system
- Provides genome assemblies, gene annotations, orthologs
- Release 111 used in this study
- Website: https://ensembl.org

**Ensembl Compara**
- Comparative genomics database within Ensembl
- Provides ortholog and paralog predictions
- Based on phylogenetic gene trees

**Episodic Selection**
- Positive selection occurring in short bursts
- Affects specific lineages or time periods
- Detected by aBSREL
- Contrasts with pervasive selection (ongoing)

---

## F

**FASTA Format**
- Text-based format for representing nucleotide or protein sequences
- Header line starts with `>`
- Sequence on following lines

**FDR (False Discovery Rate)**
- Statistical method for multiple testing correction
- Controls proportion of false positives among rejected hypotheses
- Used in HyPhy p-value correction
- Benjamini-Hochberg procedure

**Foreground Branch**
- See **Test Branch**

---

## G

**Gene Tree**
- Phylogenetic tree representing evolution of a single gene family
- May differ from species tree due to duplication, loss, incomplete lineage sorting
- Used for ortholog inference in Ensembl Compara

**Genome-wide**
- Analysis covering all or most genes in a genome
- This study: 18,008 orthologous genes
- Provides comprehensive view of selection across genome

**GO (Gene Ontology)**
- Standardized vocabulary for gene function
- Three domains: Biological Process, Molecular Function, Cellular Component
- Used for functional enrichment analysis

---

## H

**HyPhy (Hypothesis Testing using Phylogenies)**
- Software package for molecular evolution analysis
- Implements aBSREL, BUSTED, FEL, and other selection tests
- Command-line and web interface available
- Website: http://www.hyphy.org

**Homolog**
- Genes descended from common ancestral gene
- **Ortholog**: Homologs separated by speciation
- **Paralog**: Homologs separated by duplication

---

## I

**In-frame alignment**
- Alignment where codons are preserved as triplets
- No frameshifts or indels disrupting reading frame
- Essential for accurate selection analysis

---

## K

**KEGG (Kyoto Encyclopedia of Genes and Genomes)**
- Database of biological pathways and functions
- Used for pathway enrichment analysis
- Website: https://www.genome.jp/kegg/

---

## L

**Likelihood Ratio Test (LRT)**
- Statistical test comparing goodness-of-fit of two models
- Used in aBSREL to test for selection
- Compares model with selection (ω > 1 allowed) vs. neutral model (ω ≤ 1)

**Lineage-specific selection**
- Positive selection unique to a particular evolutionary lineage
- Example: genes under selection only in red fox lineage
- Detected by comparing test branch to background branches

---

## M

**MAFFT (Multiple Alignment using Fast Fourier Transform)**
- Fast and accurate multiple sequence alignment tool
- Used for protein alignment in this pipeline
- L-INS-i algorithm for high accuracy

**Miniforge**
- Conda distribution using conda-forge channel
- Open-source alternative to Anaconda
- Used for environment management in this project

**MSA (Multiple Sequence Alignment)**
- See **Alignment (Sequence)**

---

## N

**Newick Format**
- Text-based format for representing phylogenetic trees
- Example: `((Dog:1.0,Dingo:0.5):0.5,Fox:2.0);`
- Used in HyPhy for specifying tree topology

**Neutral Evolution**
- Evolution not affected by natural selection
- dN/dS = 1
- Mutations drift randomly

**Non-synonymous Substitution**
- Nucleotide mutation that changes amino acid sequence
- Subject to selection pressure
- See **dN**

---

## O

**Omega (ω)**
- See **dN/dS Ratio**

**Ortholog**
- Genes in different species derived from common ancestral gene through speciation
- Often retain same function across species
- Used for comparative genomics
- Example: Dog MECR and Fox MECR are orthologs

**Ortholog Group**
- Set of orthologous genes across multiple species
- One-to-one, one-to-many, or many-to-many relationships
- This study: 18,008 ortholog groups

---

## P

**pal2nal**
- Tool to convert protein alignment to codon alignment
- Preserves reading frames
- Required input for selection analysis in HyPhy

**Paralog**
- Genes within same genome derived from duplication
- Often evolve new or specialized functions
- Example: Different UDP-glucuronosyltransferase family members

**Pervasive Selection**
- Ongoing positive selection throughout gene's history
- Contrasts with episodic selection
- Detected by different statistical tests (e.g., BUSTED, FEL)

**Phylogenetic Tree**
- Branching diagram showing evolutionary relationships
- **Species tree**: Relationships among species
- **Gene tree**: Relationships among genes
- Branch lengths represent evolutionary distance

**Phylogenomics**
- Intersection of genomics and phylogenetics
- Uses genome-wide data to infer evolutionary relationships
- This study: Comparative phylogenomics of Canidae

**Positive Selection**
- Natural selection favoring advantageous mutations
- dN/dS > 1
- Indicates adaptive evolution
- Also called "diversifying selection"

**Purifying Selection**
- Natural selection removing deleterious mutations
- dN/dS < 1
- Indicates functional constraint
- Most common type of selection
- Also called "negative selection"

---

## R

**Reading Frame**
- Way nucleotide sequence is divided into codons
- Three possible frames (0, +1, +2)
- Must be preserved in codon alignment

**Reproducibility**
- Ability to recreate analysis results
- Ensured by version control, containerization, workflow management
- Key principle of this pipeline

---

## S

**Selection (Natural)**
- Differential survival and reproduction based on traits
- **Positive selection**: Favors beneficial mutations (ω > 1)
- **Purifying selection**: Removes harmful mutations (ω < 1)
- **Neutral**: No selection (ω = 1)

**Snakemake**
- Workflow management system for reproducible analyses
- Python-based
- Handles dependencies, parallelization, and error recovery
- Used to orchestrate this pipeline

**Speciation**
- Formation of new species
- Event that creates orthologs
- Node in phylogenetic tree

**Substitution**
- Replacement of one nucleotide with another
- **Synonymous**: No amino acid change (silent)
- **Non-synonymous**: Amino acid change
- Measured as substitutions per site

**Synonymous Substitution**
- Nucleotide mutation that does NOT change amino acid sequence
- Example: Both CAA and CAG code for glutamine
- See **dS**

---

## T

**Test Branch**
- Branch in phylogeny being tested for positive selection
- In this study: Red fox lineage
- Also called "foreground branch"

**Transcriptome**
- Complete set of RNA transcripts in a cell/tissue
- Can be used for gene expression analysis
- CDS extracted from genome used here

---

## W

**Workflow**
- Series of connected steps in computational pipeline
- This pipeline: Ortholog extraction → Alignment → Selection testing → Results parsing
- Managed by Snakemake

---

## ω (Omega)

**See dN/dS Ratio**

---

## Abbreviations

| Abbreviation | Full Term | Meaning |
|--------------|-----------|---------|
| aBSREL | Adaptive Branch-Site Random Effects Likelihood | Selection test |
| BLAST | Basic Local Alignment Search Tool | Sequence similarity search |
| CDS | Coding Sequence | Protein-coding portion of gene |
| DNA | Deoxyribonucleic Acid | Genetic material |
| dN | Non-synonymous substitution rate | Rate of amino acid-changing mutations |
| dS | Synonymous substitution rate | Rate of silent mutations |
| FASTA | Fast-All | Sequence file format |
| FDR | False Discovery Rate | Multiple testing correction |
| GO | Gene Ontology | Standardized gene function vocabulary |
| HyPhy | Hypothesis Testing using Phylogenies | Selection analysis software |
| KEGG | Kyoto Encyclopedia of Genes and Genomes | Pathway database |
| LRT | Likelihood Ratio Test | Statistical test |
| MAFFT | Multiple Alignment using Fast Fourier Transform | Alignment software |
| MSA | Multiple Sequence Alignment | Alignment of 3+ sequences |
| ORF | Open Reading Frame | Potential protein-coding region |
| RNA | Ribonucleic Acid | Transcribed genetic material |
| UTR | Untranslated Region | Non-coding region of mRNA |
| ω (omega) | dN/dS ratio | Selection metric |

---

## Statistical Terms

**p-value**
- Probability of observing data as extreme as observed under null hypothesis
- p < 0.05 typically considered statistically significant
- Corrected for multiple testing in genome-wide analyses

**Significance Level (α)**
- Threshold for statistical significance
- Usually 0.05 or 0.01
- FDR-corrected in this study

**Power**
- Probability of detecting true positive selection
- Increases with sequence divergence and alignment quality
- aBSREL designed for high power in genome-wide scans

---

## File Formats Used

**.fa / .fasta** - FASTA sequence file
**.tre / .nwk** - Newick tree file
**.json** - HyPhy results file (JSON format)
**.tsv** - Tab-separated values table
**.yml** - YAML configuration file (Conda, Snakemake)
**.py** - Python script
**.sh** - Shell script

---

## Common Parameter Values

**Significance threshold**: p < 0.05 (FDR-corrected)
**Selection criterion**: ω > 1 with p < 0.05
**Minimum ortholog count**: 2 species (2-species analysis), 3 species (3-species analysis)
**Cores used**: 8 (for parallelization)
**Alignment method**: MAFFT L-INS-i

---

*This glossary is designed to help researchers understand and use the Canidae phylogenomics pipeline. For additional terms or clarifications, please open an issue on GitHub.*

*Last updated: November 17, 2025*
