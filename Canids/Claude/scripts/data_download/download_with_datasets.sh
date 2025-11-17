#!/bin/bash
# download_with_datasets.sh
# Download Canidae genomes using NCBI Datasets CLI

set -euo pipefail

# Use datasets from Downloads or PATH
if [ -f ~/Downloads/datasets ]; then
    DATASETS=~/Downloads/datasets
    chmod +x "$DATASETS"
elif command -v datasets &> /dev/null; then
    DATASETS=datasets
else
    echo "ERROR: datasets command not found"
    echo "Please download from: https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/mac/datasets"
    exit 1
fi

echo "==================================="
echo "Canidae Genome Download"
echo "Using NCBI Datasets CLI"
echo "==================================="
echo ""
echo "Using: $DATASETS"
echo "Started: $(date)"
echo ""

# Create download directory
mkdir -p ncbi_downloads
cd ncbi_downloads

echo "Downloading 6 Canidae genomes..."
echo "This will take 30-60 minutes depending on your connection"
echo ""

# Track downloads
SUCCESS=0
FAILED=0

# Function to download a genome
download_genome() {
    local SPECIES=$1
    local ACCESSION=$2
    local FILENAME=$3

    echo "========================================="
    echo "[$SPECIES]"
    echo "Accession: $ACCESSION"
    echo "Time: $(date +%H:%M:%S)"
    echo "========================================="

    if $DATASETS download genome accession "$ACCESSION" \
        --include genome,gff3,cds \
        --filename "${FILENAME}.zip"; then

        echo "✓ Download complete: ${FILENAME}.zip"

        # Unzip
        echo "Extracting..."
        unzip -q "${FILENAME}.zip" -d "${FILENAME}_extracted"

        return 0
    else
        echo "✗ Download failed for $SPECIES"
        return 1
    fi
}

# Download each genome
echo ">>> Download 1/6: Dog (Canis familiaris)"
if download_genome "Canis_familiaris" "GCF_011100685.1" "dog"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo ">>> Download 2/6: Gray Wolf (Canis lupus)"
if download_genome "Canis_lupus" "GCF_027327525.1" "wolf"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo ">>> Download 3/6: Red Fox (Vulpes vulpes)"
if download_genome "Vulpes_vulpes" "GCF_003160815.1" "redfox"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo ">>> Download 4/6: Arctic Fox (Vulpes lagopus)"
if download_genome "Vulpes_lagopus" "GCF_001648805.2" "arcticfox"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo ">>> Download 5/6: African Wild Dog (Lycaon pictus)"
if download_genome "Lycaon_pictus" "GCF_023612875.1" "africanwilddog"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo ">>> Download 6/6: Dhole (Cuon alpinus)"
if download_genome "Cuon_alpinus" "GCF_022113835.1" "dhole"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi
echo ""

echo "========================================="
echo "Organizing Downloaded Files"
echo "========================================="
echo ""

# Function to organize files from NCBI Datasets output
organize_genome() {
    local SPECIES=$1
    local ACCESSION=$2
    local FILENAME=$3

    echo "Organizing $SPECIES..."

    # Find the extracted directory
    local EXTRACT_DIR="${FILENAME}_extracted/ncbi_dataset/data/${ACCESSION}"

    if [ ! -d "$EXTRACT_DIR" ]; then
        echo "  ⚠ Extraction directory not found: $EXTRACT_DIR"
        return 1
    fi

    # Copy genome
    if find "$EXTRACT_DIR" -name "*_genomic.fna" -exec cp {} "../data/genomes/${SPECIES}.fa" \; 2>/dev/null; then
        echo "  ✓ Genome: data/genomes/${SPECIES}.fa"
    else
        echo "  ⚠ Genome not found"
    fi

    # Copy annotation
    if find "$EXTRACT_DIR" -name "genomic.gff" -exec cp {} "../data/annotations/${SPECIES}.gff3" \; 2>/dev/null; then
        echo "  ✓ Annotation: data/annotations/${SPECIES}.gff3"
    else
        echo "  ⚠ Annotation not found"
    fi

    # Copy CDS
    if find "$EXTRACT_DIR" -name "cds_from_genomic.fna" -exec cp {} "../data/cds/${SPECIES}.cds.fa" \; 2>/dev/null; then
        echo "  ✓ CDS: data/cds/${SPECIES}.cds.fa"
    else
        echo "  ⚠ CDS not found"
    fi

    echo ""
}

# Organize all downloaded genomes
organize_genome "Canis_familiaris" "GCF_011100685.1" "dog"
organize_genome "Canis_lupus" "GCF_027327525.1" "wolf"
organize_genome "Vulpes_vulpes" "GCF_003160815.1" "redfox"
organize_genome "Vulpes_lagopus" "GCF_001648805.2" "arcticfox"
organize_genome "Lycaon_pictus" "GCF_023612875.1" "africanwilddog"
organize_genome "Cuon_alpinus" "GCF_022113835.1" "dhole"

# Return to project root
cd ..

echo "========================================="
echo "Download Summary"
echo "========================================="
echo "Finished: $(date)"
echo ""
echo "Downloads:"
echo "  Successful: $SUCCESS/6"
echo "  Failed: $FAILED/6"
echo ""

# Check what we have
n_genomes=$(ls data/genomes/*.fa 2>/dev/null | wc -l | tr -d ' ')
n_annot=$(ls data/annotations/*.gff3 2>/dev/null | wc -l | tr -d ' ')
n_cds=$(ls data/cds/*.cds.fa 2>/dev/null | wc -l | tr -d ' ')

echo "Files on disk:"
echo "  Genomes: $n_genomes"
echo "  Annotations: $n_annot"
echo "  CDS files: $n_cds"
echo ""

if [ $n_genomes -gt 0 ]; then
    echo "Genome sizes:"
    du -h data/genomes/*.fa 2>/dev/null | sort -h
    echo ""

    total_size=$(du -sh data/genomes/ 2>/dev/null | cut -f1)
    echo "Total genome data: $total_size"
    echo ""
fi

if [ $n_genomes -ge 4 ]; then
    echo "✓ SUCCESS: Ready for analysis!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify: Rscript scripts/data_download/check_data_status.R"
    echo "  2. Get ortholog table from Ensembl BioMart"
    echo "  3. Extract sequences: python scripts/alignment/extract_cds.py"
    echo ""
else
    echo "⚠ Only $n_genomes genomes downloaded (need 4 minimum)"
    echo "You can:"
    echo "  - Re-run this script to retry"
    echo "  - Continue with available genomes"
    echo ""
fi

echo "Done!"
