# Methods - Canidae Phylogenomics Pipeline

Detailed methodology for genome-wide positive selection analysis.

---

## Overview

This pipeline performs genome-wide detection of positive selection in Canidae using:
1. Ortholog identification
2. Sequence alignment
3. Statistical selection testing (aBSREL)
4. Functional annotation

**Pipeline Design:** Modular, reproducible, scalable
**Workflow Manager:** Snakemake
**Parallelization:** Up to 8 cores

---

## Step 1: Data Acquisition

### 1.1 Genome Data Download

**Source:** Ensembl Release 111
**Species:** Dog, Red fox, (optional: Dingo)

```bash
# Download CDS sequences
curl -o data/cds/Canis_familiaris.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/..."
gunzip data/cds/*.gz
```

### 1.2 Ortholog Table Download

**Method:** Ensembl BioMart web interface
**Orthology Type:** One-to-one orthologs
**Output:** Tab-separated table with gene IDs

See `BIOMART_GUIDE.md` for detailed instructions.

---

## Step 2: Ortholog Extraction

### 2.1 Script
`scripts/alignment/extract_cds_biomart.py`

### 2.2 Algorithm

1. Parse BioMart ortholog table
2. Extract dog gene IDs with orthologs in target species
3. For each ortholog group:
   - Extract CDS sequences from FASTA files
   - Create multi-FASTA file with all species
4. Filter groups by minimum species count

### 2.3 Quality Control

- Verify all sequences are in-frame (divisible by 3)
- Remove sequences with internal stop codons
- Ensure start codon (ATG) present

### 2.4 Output

```
data/orthologs/Gene_XXXXX/Gene_XXXXX.fa
```

**Expected:** 18,008 ortholog groups (2-species)
            ~15,000-16,000 groups (3-species)

---

## Step 3: Sequence Alignment

### 3.1 Protein Alignment (MAFFT)

**Tool:** MAFFT v7.520
**Algorithm:** L-INS-i (iterative refinement)
**Parameters:**
```bash
mafft --localpair --maxiterate 1000 \
  input.protein.fa > output.protein_aligned.fa
```

**Why L-INS-i?**
- High accuracy for divergent sequences
- Accounts for local similarities
- Appropriate for protein-coding genes

### 3.2 Codon Alignment (pal2nal)

**Tool:** pal2nal v14
**Purpose:** Convert protein alignment to codon alignment
**Preserves:** Reading frames, synonymous/non-synonymous distinctions

```bash
pal2nal.pl protein_aligned.fa nucleotide.fa \
  -output fasta > codon_aligned.fa
```

**Quality Control:**
- Verify no frameshifts
- Check alignment length = 3 × protein length
- Confirm no internal stop codons

---

## Step 4: Positive Selection Testing

### 4.1 aBSREL Method

**Software:** HyPhy v2.5.62
**Test:** Adaptive Branch-Site Random Effects Likelihood
**Null Hypothesis:** ω ≤ 1 (no positive selection)
**Alternative:** ω > 1 (positive selection)

**Publication:**
Smith et al. (2015) MBE 32(5):1342-1353

### 4.2 Statistical Model

**Model Features:**
- Multiple ω rate categories per branch
- Branch-specific selection
- Episodic selection detection
- Likelihood ratio test

**Rate Categories:** Up to 3 ω classes per branch

### 4.3 HyPhy Command

```bash
hyphy absrel \
  --alignment codon_aligned.fa \
  --tree species.tre \
  --branches TEST \
  --output results.json
```

**Parameters:**
- `--branches TEST`: Test red fox branch
- Branch label format: `Vulpes_vulpes #TEST#`

### 4.4 Statistical Thresholds

- **Significance:** p < 0.05 (uncorrected)
- **Multiple testing:** FDR correction applied
- **Selection criterion:** ω > 1 AND p < 0.05

---

## Step 5: Results Parsing

### 5.1 Extraction Script

`scripts/parse_all_absrel_results.py`

**Extracts:**
- Gene ID
- ω (dN/dS) value
- p-value
- Number of selected sites
- Gene symbol and description

### 5.2 Output Format

**File:** `results_summary.tsv`

```
Gene_ID          Symbol   Omega    P_value   Description
Gene_00845000    MECR     >1000    0.00001   mitochondrial trans-2...
```

---

## Step 6: Functional Analysis

### 6.1 Categorization Script

`scripts/categorize_selected_genes.py`

**Categories:**
- Signal Transduction
- Metabolism & Energy
- Transcription & Regulation
- Cell Cycle & Division
- RNA Processing
- Neural & Synaptic
- Sensory & Receptor
- Other/Unknown

### 6.2 Annotation Sources

- Gene symbols from Ensembl
- Descriptions from CDS FASTA headers
- Keywords extracted from descriptions

---

## Workflow Execution

### Snakemake Pipeline

**File:** `Snakefile`

**Rules:**
1. `align_protein` - MAFFT alignment
2. `convert_to_codon` - pal2nal conversion
3. `run_absrel` - HyPhy selection test

**Execution:**
```bash
snakemake --cores 8 --keep-going -p
```

**Features:**
- Automatic dependency resolution
- Parallel execution
- Error handling (--keep-going)
- Progress tracking

---

## Computational Requirements

**Hardware:**
- CPU: 8 cores recommended
- RAM: 16 GB minimum
- Storage: ~5 GB (scripts + results), ~250 MB (raw CDS)

**Software:**
- Python 3.9+
- BioPython
- MAFFT 7.520+
- HyPhy 2.5.62+
- Snakemake 7.0+

**Time:**
- 2-species (18,008 genes): ~24 hours (8 cores)
- 3-species (15,000 genes): ~20 hours (8 cores)

---

## Quality Control Checks

### During Analysis

1. **Alignment quality:** Check for gaps, length
2. **Codon alignment:** Verify in-frame
3. **HyPhy errors:** Monitor log files
4. **Convergence:** Check model convergence

### Post-Analysis

1. **Selection rate:** Expected ~10% (realistic for genome-wide)
2. **Functional enrichment:** Biological coherence
3. **Outlier detection:** Extremely high ω values (investigate)

---

## Reproducibility

**Version Control:**
- Git repository for code
- Conda for software versions
- Snakemake for workflow

**Random Seeds:** Not applicable (deterministic algorithms)

**Documentation:**
- This file (METHODS.md)
- GLOSSARY.md (terms)
- DATA_SOURCES.md (data provenance)

---

*Detailed methods for Canidae phylogenomics pipeline*

*Last updated: November 17, 2025*
