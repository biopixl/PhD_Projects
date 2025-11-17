# Canidae Data Sources and Availability

**Generated:** 2025-11-16

This document provides direct links and instructions for downloading all required data for the Canidae phylogenomics project.

## Summary of Available Data

Based on current NCBI/Ensembl databases (as of November 2024):

| Species | Common Name | Genome Status | NCBI | Ensembl | Priority |
|---------|-------------|---------------|------|---------|----------|
| *Canis lupus familiaris* | Dog | Chromosome-level | ✅ | ✅ | HIGH |
| *Canis lupus* | Gray wolf | Chromosome-level | ✅ | ✅ | HIGH |
| *Vulpes vulpes* | Red fox | Chromosome-level | ✅ | ✅ | HIGH |
| *Vulpes lagopus* | Arctic fox | Chromosome-level | ✅ | ✅ | MEDIUM |
| *Lycaon pictus* | African wild dog | Scaffold | ✅ | ❌ | HIGH |
| *Cuon alpinus* | Dhole | Scaffold | ✅ | ❌ | HIGH |
| *Canis latrans* | Coyote | Scaffold | ✅ | ❌ | HIGH |
| *Nyctereutes procyonoides* | Raccoon dog | Scaffold | ✅ | ❌ | MEDIUM |

## 1. Genome Assemblies

### High Priority Species (Start Here)

#### Canis lupus familiaris (Dog) - ROS_Cfam_1.0
**Best reference genome for Canidae**
```bash
# NCBI Assembly: GCF_011100685.1
# Direct download:
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/011/100/685/GCF_011100685.1_ROS_Cfam_1.0/GCF_011100685.1_ROS_Cfam_1.0_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/011/100/685/GCF_011100685.1_ROS_Cfam_1.0/GCF_011100685.1_ROS_Cfam_1.0_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/011/100/685/GCF_011100685.1_ROS_Cfam_1.0/GCF_011100685.1_ROS_Cfam_1.0_cds_from_genomic.fna.gz

# Uncompress
gunzip *.gz

# Rename
mv GCF_011100685.1_ROS_Cfam_1.0_genomic.fna data/genomes/Canis_familiaris.fa
mv GCF_011100685.1_ROS_Cfam_1.0_genomic.gff data/annotations/Canis_familiaris.gff3
mv GCF_011100685.1_ROS_Cfam_1.0_cds_from_genomic.fna data/cds/Canis_familiaris.cds.fa
```

**Ensembl (alternative):**
```bash
# Dog genome from Ensembl (UU_Cfam_GSD_1.0)
wget http://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/dna/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.dna.toplevel.fa.gz
wget http://ftp.ensembl.org/pub/release-111/gff3/canis_lupus_familiaris/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.111.gff3.gz
wget http://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.cds.all.fa.gz
```

#### Canis lupus (Gray Wolf) - ASM2732751v1
```bash
# NCBI Assembly: GCF_027327525.1
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/027/327/525/GCF_027327525.1_ASM2732751v1/GCF_027327525.1_ASM2732751v1_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/027/327/525/GCF_027327525.1_ASM2732751v1/GCF_027327525.1_ASM2732751v1_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/027/327/525/GCF_027327525.1_ASM2732751v1/GCF_027327525.1_ASM2732751v1_cds_from_genomic.fna.gz

gunzip *.gz
mv GCF_027327525.1_ASM2732751v1_genomic.fna data/genomes/Canis_lupus.fa
mv GCF_027327525.1_ASM2732751v1_genomic.gff data/annotations/Canis_lupus.gff3
mv GCF_027327525.1_ASM2732751v1_cds_from_genomic.fna data/cds/Canis_lupus.cds.fa
```

#### Vulpes vulpes (Red Fox) - VulVul2.2
```bash
# NCBI Assembly: GCF_003160815.1
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/160/815/GCF_003160815.1_VulVul2.2/GCF_003160815.1_VulVul2.2_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/160/815/GCF_003160815.1_VulVul2.2/GCF_003160815.1_VulVul2.2_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/160/815/GCF_003160815.1_VulVul2.2/GCF_003160815.1_VulVul2.2_cds_from_genomic.fna.gz

gunzip *.gz
mv GCF_003160815.1_VulVul2.2_genomic.fna data/genomes/Vulpes_vulpes.fa
mv GCF_003160815.1_VulVul2.2_genomic.gff data/annotations/Vulpes_vulpes.gff3
mv GCF_003160815.1_VulVul2.2_cds_from_genomic.fna data/cds/Vulpes_vulpes.cds.fa
```

#### Lycaon pictus (African Wild Dog) - UMICH_Lp_1.0
```bash
# NCBI Assembly: GCF_023612875.1
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/023/612/875/GCF_023612875.1_UMICH_Lp_1.0/GCF_023612875.1_UMICH_Lp_1.0_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/023/612/875/GCF_023612875.1_UMICH_Lp_1.0/GCF_023612875.1_UMICH_Lp_1.0_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/023/612/875/GCF_023612875.1_UMICH_Lp_1.0/GCF_023612875.1_UMICH_Lp_1.0_cds_from_genomic.fna.gz

gunzip *.gz
mv GCF_023612875.1_UMICH_Lp_1.0_genomic.fna data/genomes/Lycaon_pictus.fa
mv GCF_023612875.1_UMICH_Lp_1.0_genomic.gff data/annotations/Lycaon_pictus.gff3
mv GCF_023612875.1_UMICH_Lp_1.0_cds_from_genomic.fna data/cds/Lycaon_pictus.cds.fa
```

#### Cuon alpinus (Dhole) - ASM2211383v1
```bash
# NCBI Assembly: GCF_022113835.1
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/022/113/835/GCF_022113835.1_ASM2211383v1/GCF_022113835.1_ASM2211383v1_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/022/113/835/GCF_022113835.1_ASM2211383v1/GCF_022113835.1_ASM2211383v1_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/022/113/835/GCF_022113835.1_ASM2211383v1/GCF_022113835.1_ASM2211383v1_cds_from_genomic.fna.gz

gunzip *.gz
mv GCF_022113835.1_ASM2211383v1_genomic.fna data/genomes/Cuon_alpinus.fa
mv GCF_022113835.1_ASM2211383v1_genomic.gff data/annotations/Cuon_alpinus.gff3
mv GCF_022113835.1_ASM2211383v1_cds_from_genomic.fna data/cds/Cuon_alpinus.cds.fa
```

#### Canis latrans (Coyote) - ASM3099856v1
```bash
# NCBI Assembly: GCF_030988565.1
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/030/988/565/GCF_030988565.1_ASM3099856v1/GCF_030988565.1_ASM3099856v1_genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/030/988/565/GCF_030988565.1_ASM3099856v1/GCF_030988565.1_ASM3099856v1_genomic.gff.gz
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/030/988/565/GCF_030988565.1_ASM3099856v1/GCF_030988565.1_ASM3099856v1_cds_from_genomic.fna.gz

gunzip *.gz
mv GCF_030988565.1_ASM3099856v1_genomic.fna data/genomes/Canis_latrans.fa
mv GCF_030988565.1_ASM3099856v1_genomic.gff data/annotations/Canis_latrans.gff3
mv GCF_030988565.1_ASM3099856v1_cds_from_genomic.fna data/cds/Canis_latrans.cds.fa
```

### Automated Download Script

See `scripts/data_download/download_genomes.sh` for automated downloading.

## 2. Ortholog Data (Ensembl Compara)

### Option A: Use Ensembl BioMart (Recommended)

**Step-by-step:**

1. Go to https://www.ensembl.org/biomart/martview
2. Choose Database: **Ensembl Genes 111**
3. Choose Dataset: **Dog genes (UU_Cfam_GSD_1.0)**
4. Click **Filters** (left panel):
   - Gene type: `protein_coding`
   - Biotype: `protein_coding`
5. Click **Attributes** (left panel):
   - **Gene:**
     - Gene stable ID
     - Gene name
     - Transcript stable ID
     - Protein stable ID
   - **Homologues (Max select 6 orthologues):**
     - For each species (Wolf, Red fox, etc.):
       - [Species] Gene stable ID
       - [Species] Protein stable ID
       - [Species] orthology type
       - [Species] %id target [Species] gene identical to query gene
6. Click **Results** → Export as TSV
7. Save to: `data/orthologs/ensembl_compara_table.tsv`

### Option B: Use OrthoFinder (If you want to build orthologs yourself)

```bash
# Install OrthoFinder
conda install -c bioconda orthofinder

# Run on all protein sequences
orthofinder -f data/proteins/ -t 10 -o data/orthologs/orthofinder_results/
```

## 3. Phylogeny

### Option A: Download from TimeTree

1. Go to http://www.timetree.org/
2. Search for "Canidae"
3. Download Newick tree
4. Save to: `data/phylogeny/timetree_canidae.tre`

### Option B: Published Phylogenies

**Recommended:**

**Koepfli et al. 2015** - "Genome-wide Evidence Reveals that African and Eurasian Golden Jackals Are Distinct Species"
- PLOS Biology 13(1): e1002034
- Tree available in supplementary materials
- DOI: 10.1371/journal.pbio.1002034

**Nyakatura & Bininda-Emonds 2012** - "Updating the evolutionary history of Carnivora"
- BMC Biology 10:12
- Comprehensive Carnivora supertree
- DOI: 10.1186/1741-7007-10-12

### Option C: Build Your Own (Advanced)

Use concatenated single-copy orthologs:

```bash
# After extracting orthologs, select single-copy genes
# Concatenate alignments
# Run IQ-TREE
iqtree -s concatenated_alignment.fa -m MFP -bb 1000 -nt AUTO
```

## 4. Trait Data

### Life History (AnAge Database)

**URL:** https://genomics.senescence.info/species/

**Download:**
```bash
wget https://genomics.senescence.info/species/dataset.zip
unzip dataset.zip
mv anage_data.txt data/traits_raw/anage_data.txt
```

**Key variables:**
- Maximum longevity
- Body mass
- Litter size
- Gestation time

### Ecology & Habitat (PanTHERIA)

**URL:** http://esapubs.org/archive/ecol/E090/184/

**Download:**
```bash
wget http://esapubs.org/archive/ecol/E090/184/PanTHERIA_1-0_WR05_Aug2008.txt
mv PanTHERIA_1-0_WR05_Aug2008.txt data/traits_raw/pantheria.txt
```

**Key variables:**
- Habitat breadth
- Diet breadth
- Activity cycle
- Terrestriality

### Habitat & Range (IUCN Red List)

**Manual download required:**
1. Go to https://www.iucnredlist.org/
2. Search for each species
3. Download habitat classification
4. Record:
   - Habitat types (Forest, Savanna, Desert, etc.)
   - Elevation range
   - Climate zones

Save to: `data/traits_raw/iucn_habitat.csv`

### Social Behavior (Literature)

**Create manual database:**

Template: `data/traits_raw/social_behavior.csv`

```csv
species,pack_size_mean,pack_size_max,cooperative_hunting,social_structure,reference
Canis lupus,8,15,1,pack,"Mech & Boitani 2003"
Lycaon pictus,10,20,1,pack,"Creel & Creel 2002"
Cuon alpinus,12,18,1,pack,"Venkataraman et al. 1995"
Canis latrans,4,6,0.5,facultative,"Way 2007"
Vulpes vulpes,1,2,0,solitary,"Lloyd 1980"
```

**Key references:**
- Mech LD, Boitani L. (2003) *Wolves: Behavior, Ecology, and Conservation*
- Creel S, Creel NM. (2002) *The African Wild Dog*
- Macdonald DW, Sillero-Zubiri C. (2004) *The Biology and Conservation of Wild Canids*

## 5. Environmental Variables

### Climate Data (WorldClim)

```bash
# Download bioclimatic variables
wget https://geodata.ucdavis.edu/climate/worldclim/2_1/base/wc2.1_10m_bio.zip
unzip wc2.1_10m_bio.zip -d data/traits_raw/worldclim/
```

### Extract climate for species ranges

Use species range maps from IUCN and extract climate variables using R package `raster` or QGIS.

## 6. Validation Checklist

Before running analyses, verify:

```bash
# Check genome files exist
ls -lh data/genomes/*.fa

# Check annotations
ls -lh data/annotations/*.gff3

# Check CDS files
ls -lh data/cds/*.cds.fa

# Verify species counts match
wc -l config/species_list.txt
ls data/genomes/ | wc -l

# Check tree can be read
# (Run in R)
# library(ape)
# tree <- read.tree("data/phylogeny/canid_pruned.tre")
# plot(tree)
```

## Download Size Estimates

| Data Type | Size per Species | Total (10 species) |
|-----------|-----------------|-------------------|
| Genome FASTA | 0.5-2.5 GB | 10-25 GB |
| Annotations | 50-200 MB | 500 MB - 2 GB |
| CDS sequences | 20-50 MB | 200-500 MB |
| Trait data | < 1 MB | < 10 MB |

**Total:** ~15-30 GB

## Next Steps

After downloading data:

1. Run harmonization scripts (see QUICKSTART.md)
2. Verify species names match across all files
3. Extract orthologous sequences
4. Begin alignment pipeline

---

**Questions?** Check the main README.md or open an issue.
