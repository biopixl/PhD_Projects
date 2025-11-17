# Manual Download Guide for Canidae Genomes

**Issue:** Automated downloads are encountering 404 errors due to NCBI FTP path changes.

**Solution:** Use these verified methods to download genomes manually or via NCBI Datasets CLI.

---

## Method 1: NCBI Datasets CLI (Recommended - Fastest)

### Install NCBI Datasets

```bash
# Download and install (macOS)
curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/mac/datasets'
chmod +x datasets
sudo mv datasets /usr/local/bin/

# Verify installation
datasets --version
```

### Download Genomes

```bash
# Create download directory
mkdir -p ncbi_downloads
cd ncbi_downloads

# Download each genome by accession
# 1. Dog (Canis familiaris)
datasets download genome accession GCF_011100685.1 \
    --include genome,gff3,cds \
    --filename Canis_familiaris.zip

# 2. Gray Wolf
datasets download genome accession GCF_027327525.1 \
    --include genome,gff3,cds \
    --filename Canis_lupus.zip

# 3. Red Fox
datasets download genome accession GCF_003160815.1 \
    --include genome,gff3,cds \
    --filename Vulpes_vulpes.zip

# 4. Arctic Fox
datasets download genome accession GCF_001648805.2 \
    --include genome,gff3,cds \
    --filename Vulpes_lagopus.zip

# 5. African Wild Dog
datasets download genome accession GCF_023612875.1 \
    --include genome,gff3,cds \
    --filename Lycaon_pictus.zip

# 6. Dhole
datasets download genome accession GCF_022113835.1 \
    --include genome,gff3,cds \
    --filename Cuon_alpinus.zip

# Unzip all
for zip in *.zip; do unzip -q "$zip"; done

# Move files to project directories
cd ..
```

### Organize Downloaded Files

```bash
# After unzipping, NCBI Datasets creates ncbi_dataset/data/GCF_*/ directories
# Move and rename files to match expected structure

# Function to organize files
organize_genome() {
    local SPECIES=$1
    local ACCESSION=$2

    # Find the data directory
    local DATADIR="ncbi_downloads/ncbi_dataset/data/${ACCESSION}"

    if [ -d "$DATADIR" ]; then
        # Genome
        find "$DATADIR" -name "*_genomic.fna" -exec cp {} "data/genomes/${SPECIES}.fa" \;

        # Annotation
        find "$DATADIR" -name "genomic.gff" -exec cp {} "data/annotations/${SPECIES}.gff3" \;

        # CDS
        find "$DATADIR" -name "cds_from_genomic.fna" -exec cp {} "data/cds/${SPECIES}.cds.fa" \;

        echo "✓ Organized $SPECIES"
    else
        echo "✗ Data not found for $SPECIES"
    fi
}

# Organize each species
organize_genome "Canis_familiaris" "GCF_011100685.1"
organize_genome "Canis_lupus" "GCF_027327525.1"
organize_genome "Vulpes_vulpes" "GCF_003160815.1"
organize_genome "Vulpes_lagopus" "GCF_001648805.2"
organize_genome "Lycaon_pictus" "GCF_023612875.1"
organize_genome "Cuon_alpinus" "GCF_022113835.1"

# Verify
Rscript scripts/data_download/check_data_status.R
```

---

## Method 2: Manual Browser Download

### Step-by-Step for Each Species

#### 1. Canis familiaris (Dog)

**Assembly:** ROS_Cfam_1.0 (GCF_011100685.1)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_011100685.1/
2. Click "Download" → "Genome sequences (FASTA)"
3. Click "Download" → "Annotation features (GFF3)"
4. Click "Download" → "CDS sequences (FASTA)"
5. Save to:
   - Genome → `data/genomes/Canis_familiaris.fa`
   - GFF3 → `data/annotations/Canis_familiaris.gff3`
   - CDS → `data/cds/Canis_familiaris.cds.fa`

#### 2. Canis lupus (Gray Wolf)

**Assembly:** ASM2732751v1 (GCF_027327525.1)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_027327525.1/
2. Follow same download steps as above
3. Save to:
   - Genome → `data/genomes/Canis_lupus.fa`
   - GFF3 → `data/annotations/Canis_lupus.gff3`
   - CDS → `data/cds/Canis_lupus.cds.fa`

#### 3. Vulpes vulpes (Red Fox)

**Assembly:** VulVul2.2 (GCF_003160815.1)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_003160815.1/
2. Download genome, annotation, CDS
3. Save to appropriate directories

#### 4. Vulpes lagopus (Arctic Fox)

**Assembly:** ASM164880v2 (GCF_001648805.2)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_001648805.2/
2. Download files
3. Save to data directories

#### 5. Lycaon pictus (African Wild Dog)

**Assembly:** UMICH_Lp_1.0 (GCF_023612875.1)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_023612875.1/
2. Download files
3. Save to data directories

#### 6. Cuon alpinus (Dhole)

**Assembly:** ASM2211383v1 (GCF_022113835.1)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_022113835.1/
2. Download files
3. Save to data directories

---

## Method 3: Use Ensembl (Alternative for some species)

### Available on Ensembl

**Dog only:**
- URL: http://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/

```bash
# Download Dog genome from Ensembl
cd data/genomes
curl -O http://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/dna/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.dna.toplevel.fa.gz
gunzip Canis_lupus_familiaris.UU_Cfam_GSD_1.0.dna.toplevel.fa.gz
mv Canis_lupus_familiaris.UU_Cfam_GSD_1.0.dna.toplevel.fa Canis_familiaris.fa

# Download annotation
cd ../annotations
curl -O http://ftp.ensembl.org/pub/release-111/gff3/canis_lupus_familiaris/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.111.gff3.gz
gunzip Canis_lupus_familiaris.UU_Cfam_GSD_1.0.111.gff3.gz
mv Canis_lupus_familiaris.UU_Cfam_GSD_1.0.111.gff3 Canis_familiaris.gff3

# Download CDS
cd ../cds
curl -O http://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.UU_Cfam_GSD_1.0.cds.all.fa.gz
gunzip Canis_lupus_familiaris.UU_Cfam_GSD_1.0.cds.all.fa.gz
mv Canis_lupus_familiaris.UU_Cfam_GSD_1.0.cds.all.fa Canis_familiaris.cds.fa

cd ../../..
```

---

## Verification After Download

After downloading by any method, verify your files:

```bash
# Check all files are present
Rscript scripts/data_download/check_data_status.R

# Check genome file sizes (should be >100 MB each)
ls -lh data/genomes/

# Count sequences in CDS files
for f in data/cds/*.cds.fa; do
    echo "$f: $(grep -c '^>' $f) sequences"
done

# Verify genomes are not empty
for f in data/genomes/*.fa; do
    size=$(wc -c < "$f")
    if [ $size -lt 100000000 ]; then
        echo "WARNING: $f is too small ($size bytes)"
    else
        echo "✓ $f: $(echo "scale=1; $size/1000000" | bc) MB"
    fi
done
```

---

## Troubleshooting

### Issue: Downloads are slow
**Solution:** Use NCBI Datasets CLI - it's optimized for large files

### Issue: Out of disk space
**Solution:**
- Free up at least 20 GB
- Download genomes one at a time
- Or start with just 4 species: Dog, Wolf, Red Fox, African Wild Dog

### Issue: Unzipped files have weird structure
**Solution:** NCBI Datasets uses `ncbi_dataset/data/ACCESSION/` structure. Use the organize script above.

### Issue: Need to resume interrupted download
**Solution:** NCBI Datasets CLI supports resume:
```bash
datasets download genome accession GCF_011100685.1 --filename dog.zip
# If interrupted, just run again - it will resume
```

---

## Quick Start with Minimum Data

If you just want to test the pipeline, download **only 4 genomes**:

```bash
# Minimum viable dataset (fastest downloads)
datasets download genome accession GCF_011100685.1 --include genome,cds --filename dog.zip
datasets download genome accession GCF_027327525.1 --include genome,cds --filename wolf.zip
datasets download genome accession GCF_003160815.1 --include genome,cds --filename redfox.zip
datasets download genome accession GCF_023612875.1 --include genome,cds --filename africanwilddog.zip

# This gives you:
# - 2 pack species (wolf, African wild dog)
# - 1 solitary (red fox)
# - 1 domesticated (dog)
# - Enough for testing selection analyses
```

---

## After Successful Download

Once you have at least 4 genomes with CDS files:

1. **Verify data**:
   ```bash
   Rscript scripts/data_download/check_data_status.R
   ```

2. **Get ortholog data** from Ensembl BioMart (see DATA_SOURCES.md)

3. **Extract sequences**:
   ```bash
   python scripts/alignment/extract_cds.py \
       --orthologs data/orthologs/ensembl_compara_table.tsv \
       --cds_dir data/cds/ \
       --out data/orthologs/
   ```

4. **Start analysis**:
   ```bash
   snakemake --cores 10
   ```

---

## Support

If you continue having issues:
1. Check NCBI status: https://www.ncbi.nlm.nih.gov/
2. Try alternative assembly versions
3. Use Ensembl for dog genome
4. Start with fewer species and expand later

---

**Last Updated:** 2025-11-16
