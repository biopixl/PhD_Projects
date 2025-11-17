# Canidae Comparative Genomics and Phylogenomics Pipeline

A comprehensive workflow for comparative genomic analysis of Canidae, focusing on three evolutionary themes:
1. **Sociality** - Pack behavior and cooperative hunting
2. **Habitat Adaptation** - Cursoriality and environmental adaptation
3. **Domestication** - Dog domestication signatures

## Overview

This pipeline performs:
- Ortholog extraction and sequence alignment
- Codon alignment back-translation
- Branch-site selection tests (HyPhy: aBSREL, BUSTED, RELAX)
- Functional enrichment analysis
- Comparative trait analysis

## Quick Start

### 1. Installation

Create the conda environment:

```bash
conda env create -f environment.yml
conda activate canid_phylogenomics
```

### 2. Directory Structure

```
canid_phylogenomics/
├── data/                      # All input data
│   ├── genomes/              # Genome FASTA files
│   ├── annotations/          # GFF3 annotation files
│   ├── cds/                  # CDS sequences
│   ├── orthologs/            # Ortholog groups
│   ├── traits_raw/           # Raw trait data
│   ├── traits_clean/         # Harmonized traits
│   └── phylogeny/            # Phylogenetic trees
├── scripts/                   # Analysis scripts
│   ├── preprocessing/        # Data harmonization
│   ├── alignment/            # Sequence alignment
│   ├── selection/            # Selection analysis
│   └── enrichment/           # Functional enrichment
├── config/                    # Configuration files
│   ├── species_map.tsv       # Species name mapping
│   ├── species_list.txt      # Species included
│   ├── foreground_branches/  # Branch labels for selection tests
│   └── analysis_config.yaml  # Pipeline parameters
├── Snakefile                  # Snakemake workflow
└── environment.yml            # Conda environment
```

### 3. Data Preparation

#### Step 1: Create Species Mapping

```bash
Rscript scripts/preprocessing/harmonize_species_names.R \
    --output config/species_map.tsv
```

Edit `config/species_map.tsv` to match your actual species names across databases.

#### Step 2: Download Genomes and Annotations

Download from:
- **NCBI Assembly**: https://www.ncbi.nlm.nih.gov/assembly
- **Ensembl**: https://www.ensembl.org
- **VGP**: https://vgp.github.io

Required files per species:
- `Species_name.fa` → `data/genomes/`
- `Species_name.gff3` → `data/annotations/`
- `Species_name.cds.fa` → `data/cds/`

#### Step 3: Get Ortholog Data

Download from Ensembl Compara (BioMart):
1. Go to https://www.ensembl.org/biomart
2. Select "Ensembl Genes" database
3. Choose reference species (e.g., dog)
4. Retrieve: Gene ID, Transcript ID, Species, Ortholog IDs
5. Save as `data/orthologs/compara_table.tsv`

#### Step 4: Extract Orthologous Sequences

```bash
python scripts/alignment/extract_cds.py \
    --orthologs data/orthologs/compara_table.tsv \
    --cds_dir data/cds/ \
    --out data/orthologs/ \
    --min_species 4
```

#### Step 5: Prepare Phylogeny

Download a published Carnivora tree (e.g., Meredith et al. 2011), then prune:

```bash
Rscript scripts/preprocessing/prune_phylogeny.R \
    --tree data/phylogeny/published_tree.tre \
    --species_list config/species_list.txt \
    --species_map config/species_map.tsv \
    --output data/phylogeny/canid_pruned.tre
```

#### Step 6: Harmonize Trait Data

Collect trait data from:
- **AnAge**: https://genomics.senescence.info/species/
- **PanTHERIA**: http://esapubs.org/archive/ecol/E090/184/
- **IUCN**: https://www.iucnredlist.org

Place raw files in `data/traits_raw/`, then:

```bash
Rscript scripts/preprocessing/clean_trait_data.R \
    --input data/traits_raw/ \
    --species_map config/species_map.tsv \
    --output data/traits_clean/canid_traits.tsv
```

**IMPORTANT**: The template script generates placeholder data. Replace with actual trait values.

### 4. Define Foreground Branches

Edit files in `config/foreground_branches/` to specify which species/lineages to test:

- `foreground_sociality.txt` - Pack-living species
- `foreground_cursorial.txt` - Open habitat specialists
- `foreground_domestication.txt` - Domestic dog lineage

Species names must **exactly match** tree tip labels.

### 5. Run the Pipeline

#### Option A: Full Pipeline with Snakemake

```bash
# Dry run to see planned jobs
snakemake -n

# Run with 10 cores
snakemake --cores 10 --use-conda

# Run specific test
snakemake --cores 10 selection_tables/absrel_results_fdr.csv
```

#### Option B: Step-by-Step Manual Execution

**Align proteins:**
```bash
bash scripts/alignment/batch_align_protein.sh \
    --input data/orthologs \
    --output alignments \
    --threads 4
```

**Back-translate to codons:**
```bash
bash scripts/alignment/batch_codon_align.sh \
    --protein_aln alignments \
    --cds data/orthologs \
    --output codon_alignments
```

**Filter alignments:**
```bash
python scripts/alignment/filter_alignments.py \
    --input codon_alignments \
    --output codon_alignments \
    --max_gap_fraction 0.5 \
    --min_species 4 \
    --trim_edges
```

**Run HyPhy tests:**
```bash
# aBSREL (episodic selection)
hyphy absrel \
    --alignment codon_alignments/GENE.filtered.fa \
    --tree data/phylogeny/canid_pruned.tre \
    --output hyphy_results/absrel/GENE.json

# BUSTED (gene-wide selection on foreground)
hyphy busted \
    --alignment codon_alignments/GENE.filtered.fa \
    --tree data/phylogeny/canid_pruned.tre \
    --branches Foreground \
    --output hyphy_results/busted_sociality/GENE.json

# RELAX (intensification/relaxation)
hyphy relax \
    --alignment codon_alignments/GENE.filtered.fa \
    --tree data/phylogeny/canid_pruned.tre \
    --test Foreground \
    --output hyphy_results/relax_sociality/GENE.json
```

**Parse results:**
```bash
python scripts/selection/parse_hyphy_results.py \
    --input hyphy_results/absrel/ \
    --output selection_tables/absrel_results.csv \
    --test absrel
```

**Aggregate and apply FDR correction:**
```bash
Rscript scripts/selection/aggregate_selection_results.R \
    --input selection_tables/absrel_results.csv \
    --output selection_tables/absrel_results_fdr.csv \
    --fdr_threshold 0.1
```

**Enrichment analysis:**
```bash
Rscript scripts/enrichment/run_go_enrichment.R \
    --genes selection_tables/absrel_results_fdr_top_genes.txt \
    --output enrichment/absrel_go_enrichment.csv \
    --organism hsapiens
```

## Configuration

Edit `config/analysis_config.yaml` to customize:
- Alignment parameters (MAFFT strategy, filtering thresholds)
- Selection test settings (FDR threshold, which tests to run)
- Enrichment analysis parameters
- Computational resources

## Expected Outputs

### Alignments
- `alignments/GENE/GENE.protein_aligned.fa` - Protein alignments
- `codon_alignments/GENE.codon.fa` - Codon alignments
- `codon_alignments/GENE.filtered.fa` - Quality-filtered alignments

### Selection Results
- `hyphy_results/absrel/GENE.json` - aBSREL output (episodic selection)
- `hyphy_results/busted_THEME/GENE.json` - BUSTED output (gene-wide selection)
- `hyphy_results/relax_THEME/GENE.json` - RELAX output (relaxation/intensification)

### Aggregated Tables
- `selection_tables/TEST_results.csv` - Parsed results
- `selection_tables/TEST_results_fdr.csv` - FDR-corrected results
- `selection_tables/TEST_results_fdr_top_genes.txt` - Significant genes

### Enrichment
- `enrichment/TEST_go_enrichment.csv` - Full enrichment results
- `enrichment/TEST_go_enrichment_significant.csv` - Significant terms only

## Interpretation

### aBSREL
- Tests for **episodic positive selection** on individual branches
- Significant p-value → that branch experienced positive selection
- Look for branches in socially complex species, cursorial lineages, etc.

### BUSTED
- Tests if **any sites** in the gene evolved under positive selection in **foreground** lineages
- Significant p-value → gene has selection signal in your trait group
- Useful for identifying candidate genes for trait adaptation

### RELAX
- Tests if selection **intensified** (k > 1) or **relaxed** (k < 1) in foreground
- **k > 1**: Selection pressure increased (trait is important)
- **k < 1**: Selection relaxed (constraint loss, e.g., domestication)
- Combine with trait data for functional interpretation

## Citation

If you use this pipeline, please cite:

- **MAFFT**: Katoh & Standley (2013) MAFFT Multiple Sequence Alignment Software
- **HyPhy**: Kosakovsky Pond et al. (2020) HyPhy 2.5
- **aBSREL**: Smith et al. (2015) Less is more: an adaptive branch-site random effects model
- **BUSTED**: Murrell et al. (2015) Gene-wide identification of episodic selection
- **RELAX**: Wertheim et al. (2015) RELAX: detecting relaxed selection
- **gprofiler2**: Kolberg et al. (2020) gprofiler2
- **Snakemake**: Mölder et al. (2021) Sustainable data analysis with Snakemake

## Troubleshooting

### Common Issues

**1. Species names don't match**
- Check `config/species_map.tsv` - names must match exactly across all files
- Use `grep -r "Species_name"` to find all instances

**2. HyPhy fails with "Invalid tree"**
- Ensure tree is ultrametric: `is.ultrametric()` in R
- Check tree tip labels match alignment sequence IDs
- Use `prune_phylogeny.R` to standardize names

**3. Empty alignment after filtering**
- Lower `--max_gap_fraction` threshold
- Reduce `--min_species` requirement
- Check CDS quality (frameshifts, stop codons)

**4. Enrichment returns no results**
- Gene names may not map to human orthologs
- Try using `organism = "clfamiliaris"` for dog genes
- Pre-map to human orthologs using Ensembl BioMart

**5. Snakemake can't find files**
- Ensure you're in the project root directory
- Check file paths in `config/analysis_config.yaml`
- Run `snakemake --list` to see available rules

## Advanced Usage

### Running on HPC Cluster

```bash
# SLURM example
snakemake --cores 100 \
    --cluster "sbatch -n 1 -c {threads} -t 24:00:00 --mem=8G" \
    --jobs 50
```

### Visualizing Workflow

```bash
snakemake --dag | dot -Tpdf > workflow.pdf
```

### Custom Selection Tests

Add custom tests in `Snakefile`:

```python
rule meme:
    input:
        alignment = "codon_alignments/{gene}.filtered.fa",
        tree = "data/phylogeny/canid_pruned.tre"
    output:
        json = "hyphy_results/meme/{gene}.json"
    shell:
        "hyphy meme --alignment {input.alignment} --tree {input.tree}"
```

## Contributing

Issues and pull requests welcome at: https://github.com/USERNAME/canid_phylogenomics

## License

MIT License - See LICENSE file for details

## Contact

Isaac - PhD Student
GitHub: @USERNAME
Email: your.email@university.edu

## Acknowledgments

This pipeline was developed for comparative genomic analysis of Canidae evolutionary adaptations. Thanks to the broader phylogenomics community for developing these excellent tools.

---

**Generated with Claude Code** 🤖
