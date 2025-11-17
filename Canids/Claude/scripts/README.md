# Scripts Directory

Helper scripts for data processing, analysis, and visualization.

## Subdirectories

### preprocessing/
Scripts for data cleaning and harmonization:
- `harmonize_species_names.R` - Create species name mapping
- `clean_trait_data.R` - Merge and harmonize trait datasets
- `prune_phylogeny.R` - Prune published trees to Canidae species set
- `validate_genomes.py` - Check BUSCO scores and assembly quality

### alignment/
Scripts for sequence alignment and processing:
- `extract_cds.py` - Extract orthologous CDS sequences from genome annotations
- `batch_align_protein.sh` - Run MAFFT on all protein sequences
- `batch_codon_align.sh` - Back-translate to codon alignments using pal2nal
- `filter_alignments.py` - Remove gappy sequences and trim alignments

### selection/
Scripts for running selection tests:
- `prepare_foreground_branches.R` - Define foreground sets for each trait
- `parse_hyphy_results.py` - Extract p-values and omega values from HyPhy JSON output
- `aggregate_selection_results.R` - Combine results across genes and apply FDR correction
- `trait_selection_regression.R` - Correlate selection intensity with trait values

### enrichment/
Scripts for functional enrichment analysis:
- `map_to_human_orthologs.R` - Convert gene IDs using gprofiler2 or biomaRt
- `run_go_enrichment.R` - Perform GO term enrichment analysis
- `pathway_enrichment.R` - KEGG/Reactome pathway analysis
- `compare_themes.R` - Compare enrichment results across sociality/habitat/domestication

### visualization/
Scripts for generating publication figures:
- `plot_trait_phylogeny.R` - Trait-mapped phylogenetic tree
- `plot_selection_manhattan.R` - Manhattan plot of selection signals
- `plot_convergence_upset.R` - UpSet plot showing gene overlap across themes
- `plot_enrichment_heatmap.R` - Pathway enrichment comparison heatmap
- `plot_environment_pca.R` - Environmental variable PCA for habitat project

## Usage

Most scripts can be run independently or through the Snakemake pipeline.

### Example: Extract CDS for orthologs
```bash
python scripts/alignment/extract_cds.py \
    --orthologs data/orthologs/compara_table.tsv \
    --cds_dir data/cds/ \
    --out data/orthologs/
```

### Example: Harmonize trait data
```bash
Rscript scripts/preprocessing/clean_trait_data.R \
    --input data/traits_raw/ \
    --species_map config/species_map.tsv \
    --output data/traits_clean/canid_traits.tsv
```

## Dependencies

See `environment.yml` in the root directory for complete list of required packages.
