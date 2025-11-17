# Quick Start Guide

Get your Canidae phylogenomics analysis running in 10 steps.

## Prerequisites

- Conda or Mamba installed
- Basic familiarity with command line
- Access to genome assemblies and trait data

## Step-by-Step Setup

### 1. Set Up Environment (5 min)

```bash
# Create conda environment
conda env create -f environment.yml

# Activate environment
conda activate canid_phylogenomics

# Verify installation
snakemake --version
hyphy --version
mafft --version
```

### 2. Create Species Mapping (2 min)

```bash
# Generate template species mapping
Rscript scripts/preprocessing/harmonize_species_names.R

# Edit the file to match your data
# Make sure names match across all databases
nano config/species_map.tsv
```

### 3. Download Genomes (30-60 min)

**From NCBI:**
```bash
# Example for Canis lupus
cd data/genomes
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/.../GCF_*_genomic.fna.gz
gunzip *.fna.gz
mv GCF_*.fna Canis_lupus.fa

# Repeat for each species
```

**From Ensembl:**
```bash
cd data/cds
wget http://ftp.ensembl.org/pub/current_fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.*.cds.all.fa.gz
gunzip *.fa.gz
mv Canis_lupus_familiaris.*.cds.all.fa Canis_familiaris.cds.fa
```

### 4. Get Ortholog Table (10 min)

**Ensembl BioMart:**
1. Go to https://www.ensembl.org/biomart
2. Database: Ensembl Genes
3. Dataset: Choose reference (e.g., Dog genes)
4. Filters: Restrict to your Canidae species
5. Attributes: Select
   - Gene stable ID
   - Transcript stable ID
   - Gene name
   - Ortholog stable IDs for each species
6. Download as TSV → save to `data/orthologs/compara_table.tsv`

### 5. Extract Ortholog Sequences (15 min)

```bash
python scripts/alignment/extract_cds.py \
    --orthologs data/orthologs/compara_table.tsv \
    --cds_dir data/cds/ \
    --out data/orthologs/ \
    --min_species 4

# Should create directories in data/orthologs/GENENAME/
```

### 6. Get and Prune Phylogeny (5 min)

```bash
# Download published tree (example: TimeTree)
# http://www.timetree.org/

# Or use a published study tree
# Meredith et al. 2011, Nyakatura & Bininda-Emonds 2012

# Save to data/phylogeny/published_tree.tre

# Prune to your species
Rscript scripts/preprocessing/prune_phylogeny.R \
    --tree data/phylogeny/published_tree.tre \
    --species_list config/species_list.txt \
    --output data/phylogeny/canid_pruned.tre

# Check the output PDF
open data/phylogeny/canid_pruned.pdf
```

### 7. Collect Trait Data (20 min)

**Download from:**
- **AnAge**: https://genomics.senescence.info/species/
- **PanTHERIA**: http://esapubs.org/archive/ecol/E090/184/
- **IUCN**: https://www.iucnredlist.org

**Harmonize:**
```bash
# Place raw CSV files in data/traits_raw/

# Run harmonization
Rscript scripts/preprocessing/clean_trait_data.R \
    --input data/traits_raw/ \
    --species_map config/species_map.tsv \
    --output data/traits_clean/canid_traits.tsv

# IMPORTANT: Edit the script to load actual data, not template
```

### 8. Define Foreground Branches (5 min)

Edit these files to list species for each hypothesis:

```bash
# Sociality - pack-living species
nano config/foreground_branches/foreground_sociality.txt
# Add: Canis_lupus, Lycaon_pictus, Cuon_alpinus

# Cursoriality - open habitat specialists
nano config/foreground_branches/foreground_cursorial.txt
# Add: Lycaon_pictus, Canis_lupus

# Domestication
nano config/foreground_branches/foreground_domestication.txt
# Add: Canis_familiaris
```

**Critical**: Species names MUST match tree tip labels exactly!

### 9. Test Pipeline (5 min)

```bash
# Dry run - see what will execute
snakemake -n

# Test on first 5 genes
snakemake --cores 4 \
    alignments/BRCA1/BRCA1.protein_aligned.fa \
    codon_alignments/BRCA1.codon.fa \
    hyphy_results/absrel/BRCA1.json

# Check outputs
ls -lh alignments/BRCA1/
ls -lh hyphy_results/absrel/
```

### 10. Run Full Analysis

```bash
# Run entire pipeline
# Adjust --cores based on your system
snakemake --cores 10 --use-conda

# Or run specific analyses:

# Just aBSREL on all genes
snakemake --cores 10 selection_tables/absrel_results_fdr.csv

# BUSTED for sociality
snakemake --cores 10 \
    selection_tables/busted_sociality_results_fdr.csv

# Enrichment analysis
snakemake --cores 10 \
    enrichment/absrel_go_enrichment.csv
```

## Quick Analysis Examples

### Run aBSREL on a Single Gene

```bash
hyphy absrel \
    --alignment codon_alignments/OXTR.filtered.fa \
    --tree data/phylogeny/canid_pruned.tre \
    --output hyphy_results/absrel/OXTR.json
```

### Parse All aBSREL Results

```bash
python scripts/selection/parse_hyphy_results.py \
    --input hyphy_results/absrel/ \
    --output selection_tables/absrel_results.csv \
    --test absrel

Rscript scripts/selection/aggregate_selection_results.R \
    --input selection_tables/absrel_results.csv \
    --output selection_tables/absrel_results_fdr.csv \
    --fdr_threshold 0.1
```

### Check Top Significant Genes

```bash
cat selection_tables/absrel_results_fdr_top_genes.txt
```

### Run GO Enrichment

```bash
Rscript scripts/enrichment/run_go_enrichment.R \
    --genes selection_tables/absrel_results_fdr_top_genes.txt \
    --output enrichment/absrel_enrichment.csv \
    --organism hsapiens
```

## Monitoring Progress

### Check Snakemake Status

```bash
# See what's running
snakemake --summary

# See what will run
snakemake -n

# Check which files exist
snakemake --list-target-rules
```

### Monitor HyPhy Progress

```bash
# Watch log files
tail -f logs/hyphy/absrel/GENE.log

# Count completed analyses
ls hyphy_results/absrel/*.json | wc -l
```

## Estimated Run Times

Based on 20 Canidae species, 5000 genes:

| Step | Time | Cores |
|------|------|-------|
| Protein alignment | 2-4 hours | 10 |
| Codon alignment | 1-2 hours | 10 |
| aBSREL (all genes) | 24-48 hours | 20 |
| BUSTED (all genes) | 12-24 hours | 20 |
| RELAX (all genes) | 12-24 hours | 20 |
| Enrichment | < 5 min | 1 |

Total pipeline: ~3-5 days on 20-core workstation

## Next Steps

After running the pipeline:

1. **Explore results**: `selection_tables/*_fdr.csv`
2. **Check enrichment**: `enrichment/*_significant.csv`
3. **Compare themes**: Which genes show selection across multiple traits?
4. **Visualize**: Create Manhattan plots, trait-mapped trees
5. **Validate**: Literature search on candidate genes
6. **Follow-up**: Structural modeling, expression analysis

## Troubleshooting

**Q: Snakemake can't find input files**
- Check you're in the project root directory
- Verify file paths match what Snakefile expects
- Run `ls data/orthologs/*/` to see structure

**Q: HyPhy fails immediately**
- Check alignment format (should be FASTA)
- Verify tree tips match alignment IDs exactly
- Ensure alignment length divisible by 3

**Q: No significant results**
- This is biology - not all traits have strong selection signatures
- Try lower FDR threshold (0.1 → 0.2)
- Check if you have enough species (min 4-5 recommended)

**Q: Enrichment returns nothing**
- Gene IDs may not map - use human orthologs
- Try different organism (`clfamiliaris` for dog)
- Check gene list has valid gene symbols

## Getting Help

1. Check main README.md for detailed documentation
2. See individual script help: `python script.py --help`
3. Read HyPhy docs: https://hyphy.org
4. Open GitHub issue (if applicable)

---

Happy phylogenomics! 🧬🐺🦊
