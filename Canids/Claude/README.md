# Genome-Wide Positive Selection in Red Fox (*Vulpes vulpes*)

A comprehensive phylogenomics pipeline for detecting adaptive evolution in the red fox lineage through comparative genomic analysis with the domestic dog.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXX)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

This project performs **genome-wide detection of positive selection** in red fox (*Vulpes vulpes*) compared to domestic dog (*Canis lupus familiaris*) using 18,008 orthologous genes.

### Key Findings

- **1,780 genes (9.9%)** under positive selection in red fox lineage
- Strong adaptive signals in:
  - **Metabolism & Energy** (11.8%) - Dietary adaptation to omnivory
  - **Signal Transduction** (21.7%) - Environmental adaptation
  - **Neural & Behavioral** (4.4%) - Solitary foraging behavior
  - **Sensory Systems** - Olfactory and chemosensory genes

### Biological Context

Red foxes are highly adaptable generalist carnivores with:
- **Diet:** Omnivorous (fruits, small mammals, insects, carrion)
- **Habitat:** Urban and rural environments worldwide
- **Behavior:** Solitary, territorial

This contrasts with domestic dogs (derived from wolves):
- **Diet:** Primarily carnivorous (or human-provided)
- **Habitat:** Human-associated
- **Behavior:** Pack-oriented (ancestral wolf behavior)

**Hypothesis:** Positive selection on metabolic, neural, and signaling genes reflects red fox adaptation to omnivorous diet and solitary lifestyle.

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/biopixl/PhD_Projects.git
cd PhD_Projects/Canids/Claude
```

### 2. Install Dependencies

```bash
# Create conda environment
conda env create -f environment.yml
conda activate canid_phylogenomics

# Verify installations
hyphy --version    # Should be v2.5.62+
mafft --version    # Should be v7.520+
python --version   # Should be 3.9+
```

### 3. Download Data

#### Option A: Download from Ensembl (Recommended for Reproducibility)

```bash
# Dog CDS sequences
curl -o data/cds/Canis_familiaris.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.ROS_Cfam_1.0.cds.all.fa.gz"
gunzip data/cds/Canis_familiaris.cds.fa.gz

# Red fox CDS sequences
curl -o data/cds/Vulpes_vulpes.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/vulpes_vulpes/cds/Vulpes_vulpes.VulVul2.2.cds.all.fa.gz"
gunzip data/cds/Vulpes_vulpes.cds.fa.gz
```

See [DATA_SOURCES.md](DATA_SOURCES.md) for complete data provenance.

#### Option B: Download Ortholog Table from BioMart

Follow instructions in [BIOMART_GUIDE.md](BIOMART_GUIDE.md) to download one-to-one orthologs between dog and red fox.

Save as: `data/orthologs/ensembl_compara_table.tsv`

### 4. Run Analysis

#### Step 1: Extract Orthologous Sequences

```bash
python scripts/alignment/extract_cds_biomart.py \
  --orthologs data/orthologs/ensembl_compara_table.tsv \
  --cds_dir data/cds \
  --out data/orthologs \
  --min_species 2
```

**Output:** 18,008 ortholog groups in `data/orthologs/Gene_*/`

#### Step 2: Run Pipeline with Snakemake

```bash
# Dry run (shows planned jobs)
snakemake -n

# Full run with 8 cores
snakemake --cores 8 --keep-going -p
```

**Pipeline steps:**
1. Protein alignment (MAFFT L-INS-i)
2. Codon alignment back-translation (pal2nal)
3. Positive selection testing (HyPhy aBSREL)

**Expected runtime:** ~24 hours for 18,008 genes (8 cores)

#### Step 3: Parse Results

```bash
python scripts/parse_all_absrel_results.py
```

**Output:** `results_summary.tsv` - Complete list of selected genes

---

## Results

### Main Results File

**File:** `results_summary.tsv`
**Format:** Tab-separated values

| Gene_ID | Gene_Symbol | Omega (dN/dS) | Sites | Description |
|---------|-------------|---------------|-------|-------------|
| Gene_00845008187 | MECR | >1000 | N/A | Mitochondrial fatty acid synthesis |
| Gene_00845005853 | HCRTR1 | >1000 | N/A | Hypocretin receptor 1 (feeding behavior) |
| Gene_00845027006 | PER3 | >1000 | N/A | Period circadian regulator 3 |
| Gene_00845030623 | GLYCTK | >1000 | N/A | Glycerate kinase (carbohydrate metabolism) |

**Full list:** 1,780 genes under positive selection (9.9% of genes analyzed)

### Functional Enrichment

Top enriched categories:
- **Signal Transduction** (21.7%) - Cellular communication, receptor signaling
- **Metabolism & Energy** (11.8%) - Fatty acid synthesis, carbohydrate metabolism
- **Neural & Behavioral** (4.4%) - Neurotransmission, circadian rhythm, feeding
- **Sensory & Receptor** - Olfactory receptors, taste receptors

See [INTERPRETATION_GUIDE.md](INTERPRETATION_GUIDE.md) for detailed interpretation.

---

## Documentation

### Core Documentation

- **[METHODS.md](METHODS.md)** - Detailed pipeline methodology
- **[DATA_SOURCES.md](DATA_SOURCES.md)** - Data provenance and accessions
- **[INTERPRETATION_GUIDE.md](INTERPRETATION_GUIDE.md)** - How to interpret results
- **[GLOSSARY.md](GLOSSARY.md)** - Technical terminology (100+ terms)
- **[LITERATURE.md](LITERATURE.md)** - Complete bibliography with DOIs

### Guides

- **[BIOMART_GUIDE.md](BIOMART_GUIDE.md)** - How to download orthologs from Ensembl
- **[GITHUB_ARCHIVE_GUIDE.md](GITHUB_ARCHIVE_GUIDE.md)** - Reproducing analysis from GitHub

---

## Methods Summary

### Data

- **Species:** *Canis lupus familiaris* (dog) vs *Vulpes vulpes* (red fox)
- **Data Source:** Ensembl Release 111 (July 2023)
- **Ortholog Groups:** 18,008 one-to-one orthologs
- **Genome Assemblies:**
  - Dog: ROS_Cfam_1.0 (GCA_014441545.1)
  - Red fox: VulVul2.2 (GCA_003160815.1)

### Pipeline

1. **Ortholog Extraction**
   - Source: Ensembl Compara (BioMart)
   - Filter: One-to-one orthologs only
   - Quality: Remove frameshifts, internal stops

2. **Sequence Alignment**
   - Protein: MAFFT L-INS-i (high accuracy)
   - Codon: pal2nal (preserves reading frames)

3. **Selection Testing**
   - Method: HyPhy aBSREL (Adaptive Branch-Site Random Effects Likelihood)
   - Test branch: Red fox lineage
   - Significance: p < 0.05 (FDR-corrected)
   - Interpretation: ω > 1 indicates positive selection

4. **Functional Annotation**
   - Gene symbols from Ensembl
   - Functional categorization by keyword
   - Enrichment analysis

### Statistical Rigor

- **Multiple testing correction:** False Discovery Rate (FDR)
- **Significance threshold:** p < 0.05 (after FDR)
- **Model:** Likelihood ratio test (aBSREL vs neutral)
- **Robustness:** 9.9% selection rate is realistic for mammalian genomes (5-15% typical)

---

## Repository Structure

```
Canids/Claude/
├── README.md                      # This file
├── CITATION.cff                   # Citation metadata
├── .gitignore                     # Version control
│
├── docs/                          # Documentation
│   ├── LITERATURE.md              # Bibliography
│   ├── GLOSSARY.md                # Terminology
│   ├── DATA_SOURCES.md            # Data provenance
│   ├── METHODS.md                 # Methodology
│   ├── INTERPRETATION_GUIDE.md    # Results interpretation
│   ├── BIOMART_GUIDE.md           # Ortholog download
│   └── GITHUB_ARCHIVE_GUIDE.md    # Reproduction instructions
│
├── scripts/                       # Analysis code
│   ├── alignment/
│   │   ├── extract_cds_biomart.py
│   │   ├── extract_cds.py
│   │   └── filter_alignments.py
│   ├── selection/
│   │   └── parse_hyphy_results.py
│   ├── categorize_selected_genes.py
│   ├── parse_all_absrel_results.py
│   └── monitor_progress.sh
│
├── data/                          # Data (excluded by .gitignore)
│   ├── phylogeny/
│   │   └── canid_pruned.tre       # Phylogenetic tree (KEPT)
│   ├── cds/                       # CDS sequences (excluded)
│   └── orthologs/                 # Ortholog groups (excluded)
│
├── results_summary.tsv            # Main results
├── Snakefile                      # Snakemake workflow
├── environment.yml                # Conda environment
└── environment_minimal.yml        # Minimal dependencies
```

**Note:** Large data files (CDS, alignments, HyPhy results) are excluded from Git but can be regenerated using the pipeline or downloaded from Ensembl.

---

## Citation

If you use this pipeline or data, please cite:

```bibtex
@software{canid_phylogenomics_2025,
  author = {Isaac [Your Last Name]},
  title = {Genome-Wide Positive Selection in Red Fox (Vulpes vulpes)},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/biopixl/PhD_Projects/tree/main/Canids/Claude},
  doi = {10.5281/zenodo.XXXXX}
}
```

### Key Software

Please also cite the software used:

- **HyPhy:** Kosakovsky Pond et al. (2020) *Mol Biol Evol* 37(1):295-299
- **aBSREL:** Smith et al. (2015) *Mol Biol Evol* 32(5):1342-1353
- **MAFFT:** Katoh & Standley (2013) *Mol Biol Evol* 30(4):772-780
- **pal2nal:** Suyama et al. (2006) *Nucleic Acids Res* 34:W609-W612
- **Snakemake:** Mölder et al. (2021) *F1000Research* 10:33
- **Ensembl:** Cunningham et al. (2022) *Nucleic Acids Res* 50(D1):D988-D995

See [LITERATURE.md](LITERATURE.md) for complete references.

---

## Data Availability

### Raw Data

All raw genomic data are publicly available from Ensembl:

1. **Dog CDS:** https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/
2. **Red fox CDS:** https://ftp.ensembl.org/pub/release-111/fasta/vulpes_vulpes/cds/
3. **Ortholog predictions:** Ensembl Compara (via BioMart)

### Processed Data

- **Selected genes:** `results_summary.tsv` (this repository)
- **Full results:** Available upon request or regenerate using pipeline
- **Pipeline code:** This GitHub repository

### Long-Term Archive

A permanent archive of this project will be created on Zenodo upon publication with a DOI for long-term accessibility.

---

## Reproducibility

This pipeline is designed for full reproducibility:

✅ **Version control:** All code in Git
✅ **Environment management:** Conda environment.yml
✅ **Workflow automation:** Snakemake for deterministic execution
✅ **Data provenance:** All sources documented with accessions
✅ **Software versions:** All tools versioned in environment.yml

To reproduce this analysis from scratch, follow [GITHUB_ARCHIVE_GUIDE.md](GITHUB_ARCHIVE_GUIDE.md).

---

## Troubleshooting

### Common Issues

**Q: Pipeline fails with "tree file not found"**

A: Ensure you have `data/phylogeny/canid_pruned.tre`. This should be tracked in Git.

**Q: No CDS sequences found for species**

A: Download CDS files from Ensembl as shown in Quick Start section.

**Q: HyPhy fails with "Invalid alignment"**

A: Check for:
- Sequences not in-frame (length not divisible by 3)
- Internal stop codons
- Misaligned sequences

The pipeline includes quality control filters to prevent these issues.

**Q: How long does the analysis take?**

A: ~24 hours for 18,008 genes on 8 cores. Use `bash scripts/monitor_progress.sh` to check progress.

---

## Advanced Usage

### Monitor Progress

```bash
# Check analysis progress
bash scripts/monitor_progress.sh

# View Snakemake log
tail -f logs/snakemake_*.log
```

### Resume Failed Run

```bash
# Snakemake automatically resumes from last successful step
snakemake --cores 8 --keep-going -p
```

### Run on HPC Cluster

```bash
# SLURM example
snakemake --cores 100 \
  --cluster "sbatch -n 1 -c {threads} -t 24:00:00 --mem=8G" \
  --jobs 50
```

---

## Contributing

Issues and pull requests welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## License

MIT License - See LICENSE file for details

---

## Contact

**Isaac [Your Name]**
- GitHub: [@biopixl](https://github.com/biopixl)
- Email: [your.email@institution.edu]
- Institution: [Your Institution]

---

## Acknowledgments

This pipeline was developed for comparative genomic analysis of red fox evolutionary adaptations.

Special thanks to:
- **Ensembl** team for maintaining high-quality genomic resources
- **HyPhy** developers for powerful selection analysis tools
- **Snakemake** community for workflow management framework

---

**Generated with Claude Code** 🤖

*Last updated: November 17, 2025*
