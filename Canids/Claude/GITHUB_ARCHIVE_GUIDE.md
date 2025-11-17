# GitHub Archive Guide

**Repository:** https://github.com/biopixl/PhD_Projects/tree/main/Canids/Claude

---

## What's Included in Git

### ✅ Committed to GitHub (< 100 MB)

**Documentation:**
- All `.md` files (project documentation, results summaries, guides)
- CITATION.cff (citation information)
- README.md (project overview)

**Analysis Scripts:**
- All Python scripts (`scripts/**/*.py`)
- All shell scripts (`scripts/**/*.sh`)
- Snakemake workflow (`Snakefile`)
- Environment specifications (`environment*.yml`)

**Small Data Files:**
- Phylogenetic trees (`data/phylogeny/*.tre`)
- Results summary table (`results_summary.tsv`)

**Configuration:**
- `.gitignore` (file exclusions)

### ❌ NOT in Git (Excluded - Large Files)

These files are **excluded** but can be **regenerated** or **downloaded**:

**Raw Data (Can re-download from Ensembl):**
- `data/cds/*.fa` - CDS sequences (~250 MB)
- `data/genomes/*` - Genome assemblies (if downloaded)

**Generated Data (Can regenerate with scripts):**
- `data/orthologs/*/` - Extracted ortholog groups (~500 MB)
- `data/gene_annotations.json` - Gene annotations (3.2 MB)
- `alignments/` - Sequence alignments (~1 GB)
- `codon_alignments/` - Codon alignments (~500 MB)
- `hyphy_results/` - HyPhy output files (~50 MB)

**Logs:**
- `logs/` - Analysis logs (can regenerate)

---

## Reproducing the Analysis

To reproduce from GitHub checkout:

### 1. Clone Repository
```bash
git clone https://github.com/biopixl/PhD_Projects.git
cd PhD_Projects/Canids/Claude
```

### 2. Set Up Environment
```bash
# Install Miniforge if needed
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
bash Miniforge3-MacOSX-arm64.sh

# Create conda environment
conda env create -f environment_minimal.yml
conda activate canid_phylogenomics
```

### 3. Download Data

**Option A: Download CDS from Ensembl**
```bash
# Dog
curl -o data/cds/Canis_familiaris.cds.fa.gz \\
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.ROS_Cfam_1.0.cds.all.fa.gz"
gunzip data/cds/Canis_familiaris.cds.fa.gz

# Red fox
curl -o data/cds/Vulpes_vulpes.cds.fa.gz \\
  "https://ftp.ensembl.org/pub/release-111/fasta/vulpes_vulpes/cds/Vulpes_vulpes.VulVul2.2.cds.all.fa.gz"
gunzip data/cds/Vulpes_vulpes.cds.fa.gz

# Dingo (optional - for 3-species)
curl -o data/cds/Canis_lupus_dingo.cds.fa.gz \\
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_dingo/cds/Canis_lupus_dingo.ASM325472v1.cds.all.fa.gz"
gunzip data/cds/Canis_lupus_dingo.cds.fa.gz
```

**Option B: Download BioMart ortholog table**
- Go to https://ensembl.org/biomart
- Follow instructions in `BIOMART_GUIDE.md`
- Save as `data/orthologs/ensembl_compara_table.tsv`

### 4. Run Analysis

**Extract orthologs:**
```bash
python3 scripts/alignment/extract_cds_biomart.py \\
  --orthologs data/orthologs/ensembl_compara_table.tsv \\
  --cds_dir data/cds \\
  --out data/orthologs \\
  --min_species 2
```

**Create gene annotations:**
```bash
python3 scripts/create_gene_annotation_map.py
```

**Run selection analysis:**
```bash
snakemake --cores 8 -p
```

**Parse results:**
```bash
python3 scripts/parse_all_absrel_results.py
python3 scripts/categorize_selected_genes.py
```

---

## Supplementary Files for Manuscript

### Files to Submit as Supplementary Materials

**Supplementary Tables:**
1. **`results_summary.tsv`** - All genes under positive selection
2. Ortholog list (generate with script)
3. Full selection results (after analysis completes)

**Supplementary Methods:**
1. **`MANUSCRIPT_SUMMARY.md`** - Detailed methods and results
2. **`Snakefile`** - Complete computational workflow
3. **`environment_minimal.yml`** - Software versions

**Supplementary Figures:**
- Generate from results (functional categories, selection distribution)
- Create with R/Python plotting scripts

**Code Availability:**
- GitHub repository: https://github.com/biopixl/PhD_Projects
- All analysis scripts included
- Reproducible workflow

---

## Data Availability Statement

**For manuscript:**

> Genome sequences were obtained from Ensembl release 111 (https://ensembl.org):
> - *Canis lupus familiaris* (ROS_Cfam_1.0)
> - *Vulpes vulpes* (VulVul2.2)
> - *Canis lupus dingo* (ASM325472v1)
>
> Orthologous gene relationships were identified using Ensembl Compara.
> All analysis scripts, intermediate results, and documentation are available at:
> https://github.com/biopixl/PhD_Projects/tree/main/Canids/Claude
>
> Raw data files (CDS sequences, alignments) can be regenerated using the
> provided scripts or downloaded from the original sources.

---

## File Size Summary

| Category | Size | In Git? | Source |
|----------|------|---------|--------|
| Documentation | ~500 KB | ✅ Yes | Created |
| Scripts | ~100 KB | ✅ Yes | Created |
| Small data | ~50 KB | ✅ Yes | Created |
| CDS sequences | ~250 MB | ❌ No | Ensembl FTP |
| Orthologs | ~500 MB | ❌ No | Regenerate |
| Alignments | ~2 GB | ❌ No | Regenerate |
| Results | ~50 MB | ❌ No | Regenerate |

**GitHub repository size:** < 5 MB
**Full analysis (regenerated):** ~3-4 GB

---

## Citation

See `CITATION.cff` for citation information.

If you use this code or data, please cite:

```
Your Name et al. (2025). Comparative Phylogenomics of Canidae:
Evidence for Episodic Positive Selection in Red Fox.
GitHub repository: https://github.com/biopixl/PhD_Projects
```

---

*Last updated: November 17, 2025*
