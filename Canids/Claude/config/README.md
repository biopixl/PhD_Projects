# Configuration Directory

Configuration files for the phylogenomics pipeline.

## Files

### species_map.tsv
Master species name mapping table to harmonize names across databases.

**Format:**
```
scientific_name    ncbi_label       ensembl_label    trait_label       common_name
Canis lupus        Canis_lupus      canlup           Canis lupus       Gray wolf
Vulpes vulpes      Vulpes_vulpes    vulvul           Red fox           Red fox
Lycaon pictus      Lycaon_pictus    lycpic           Lycaon pictus     African wild dog
```

### species_list.txt
Simple list of species to include in analyses (one per line)

**Format:**
```
Canis_lupus
Vulpes_vulpes
Lycaon_pictus
```

### foreground_branches/
Branch labels for HyPhy selection tests

**Files:**
- `foreground_sociality.txt` - Pack-living species (wolves, African wild dogs, dholes)
- `foreground_cursorial.txt` - Open habitat/cursorial species
- `foreground_domestication.txt` - Domestic dog lineage
- `foreground_aridity.txt` - Desert-adapted species (fennec fox, kit fox)

### analysis_config.yaml
Main configuration file for Snakemake pipeline

**Contents:**
- Species list
- Minimum ortholog coverage threshold
- Alignment parameters (MAFFT settings)
- Selection test parameters
- Enrichment analysis settings
- Output paths

## Example: species_map.tsv

This file is **critical** for preventing name mismatches.

Create it by:
1. List all species in your phylogeny
2. Find corresponding names in NCBI, Ensembl, trait databases
3. Manually verify each mapping
4. Use this mapping in all preprocessing scripts

## Example: foreground_sociality.txt

List species or clade names (must match tree tip labels):
```
Canis_lupus
Cuon_alpinus
Lycaon_pictus
```

Or use clade labels if tree has internal node names:
```
Node_PackLiving
```
