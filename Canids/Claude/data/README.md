# Data Directory

This directory contains all raw and processed data for the Canidae phylogenomics project.

## Subdirectories

### genomes/
Store genome FASTA files here (*.fa, *.fna)

**Naming convention:** `Species_name.fa`
- Example: `Canis_lupus.fa`, `Vulpes_vulpes.fa`

**Required:** BUSCO completeness > 85% preferred

### annotations/
Store GFF3/GTF annotation files

**Naming convention:** `Species_name.gff3`

### cds/
Store coding sequence (CDS) FASTA files

**Naming convention:** `Species_name.cds.fa`

These will be used for extracting orthologous sequences.

### orthologs/
Extracted orthologous gene sequences organized by gene family

**Structure:**
```
orthologs/
  ├── GeneName1/
  │   ├── GeneName1_Canis_lupus.cds.fa
  │   ├── GeneName1_Vulpes_vulpes.cds.fa
  │   └── ...
  ├── GeneName2/
  │   └── ...
```

### traits_raw/
Raw trait data downloaded from various sources:
- IUCN Habitat Use
- AnAge (lifespan, body size)
- PanTHERIA / EltonTraits
- Primary literature

Keep original files unchanged here.

### traits_clean/
Harmonized trait tables ready for analysis

**Main file:** `canid_traits.tsv`

Required columns:
- species (harmonized scientific name)
- sociality_index
- habitat_openness
- cursoriality_score
- domestication_level
- diet_breadth
- climate variables

### phylogeny/
Phylogenetic trees (Newick format)
- Published trees (Meredith et al., 2011, etc.)
- Pruned Canidae-specific trees
- Gene trees (if applicable)

## Data Sources

### Genomes
- NCBI Assembly: https://www.ncbi.nlm.nih.gov/assembly
- Ensembl: https://www.ensembl.org
- Vertebrate Genomes Project: https://vgp.github.io
- Dog10K: http://www.dog10k.org (optional)

### Orthologs
- Ensembl Compara (BioMart): https://www.ensembl.org/biomart
- OrthoDB: https://www.orthodb.org
- OMA Browser: https://omabrowser.org

### Traits
- IUCN Red List: https://www.iucnredlist.org
- AnAge: https://genomics.senescence.info/species/
- PanTHERIA: http://esapubs.org/archive/ecol/E090/184/
- EltonTraits: https://figshare.com/articles/dataset/EltonTraits_1_0/3559887
