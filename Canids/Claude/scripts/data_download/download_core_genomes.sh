#!/bin/bash
# download_core_genomes.sh
# Download high-priority Canidae genomes from NCBI

set -euo pipefail

echo "==================================="
echo "Canidae Genome Download Script"
echo "==================================="
echo ""
echo "This script downloads 6 high-priority Canidae genomes from NCBI"
echo "Total download size: ~10-15 GB"
echo "Estimated time: 30-60 minutes (depending on connection)"
echo ""

# Check if directories exist
if [ ! -d "data/genomes" ] || [ ! -d "data/annotations" ] || [ ! -d "data/cds" ]; then
    echo "ERROR: Required directories not found"
    echo "Please run this script from the project root directory"
    echo "Expected structure:"
    echo "  data/genomes/"
    echo "  data/annotations/"
    echo "  data/cds/"
    exit 1
fi

# Ask for confirmation
read -p "Download ~15 GB of genome data? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Download cancelled"
    exit 0
fi

# Create temporary download directory
mkdir -p tmp_downloads
cd tmp_downloads

echo ""
echo "Starting downloads..."
echo ""

# Function to download and process a genome
download_genome() {
    local SPECIES=$1
    local ASSEMBLY=$2
    local ACCESSION=$3

    echo "========================================="
    echo "Downloading: $SPECIES"
    echo "Assembly: $ASSEMBLY"
    echo "========================================="

    # Construct base URL
    BASE_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all"

    # Split accession into path components (e.g., GCF_011100685.1 -> GCF/011/100/685)
    PREFIX=$(echo $ACCESSION | cut -d'_' -f1)
    NUM=$(echo $ACCESSION | cut -d'_' -f2 | cut -d'.' -f1)
    P1=$(echo $NUM | cut -c1-3)
    P2=$(echo $NUM | cut -c4-6)
    P3=$(echo $NUM | cut -c7-9)

    URL="${BASE_URL}/${PREFIX}/${P1}/${P2}/${P3}/${ACCESSION}_${ASSEMBLY}"

    echo "  Downloading genome FASTA..."
    wget -q --show-progress "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.fna.gz" || {
        echo "  ERROR: Failed to download genome"
        return 1
    }

    echo "  Downloading annotation GFF..."
    wget -q --show-progress "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.gff.gz" || {
        echo "  WARNING: Failed to download annotation (continuing)"
    }

    echo "  Downloading CDS sequences..."
    wget -q --show-progress "${URL}/${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna.gz" || {
        echo "  WARNING: Failed to download CDS (continuing)"
    }

    echo "  Decompressing files..."
    gunzip -f *.gz 2>/dev/null || true

    echo "  Moving to data directories..."
    [ -f "${ACCESSION}_${ASSEMBLY}_genomic.fna" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_genomic.fna" "../data/genomes/${SPECIES}.fa"

    [ -f "${ACCESSION}_${ASSEMBLY}_genomic.gff" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_genomic.gff" "../data/annotations/${SPECIES}.gff3"

    [ -f "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" "../data/cds/${SPECIES}.cds.fa"

    echo "  ✓ Complete"
    echo ""
}

# Download high-priority genomes

# 1. Dog (reference genome)
download_genome "Canis_familiaris" "ROS_Cfam_1.0" "GCF_011100685.1"

# 2. Gray Wolf
download_genome "Canis_lupus" "ASM2732751v1" "GCF_027327525.1"

# 3. Red Fox
download_genome "Vulpes_vulpes" "VulVul2.2" "GCF_003160815.1"

# 4. Arctic Fox
download_genome "Vulpes_lagopus" "ASM164880v2" "GCF_001648805.2"

# 5. African Wild Dog
download_genome "Lycaon_pictus" "UMICH_Lp_1.0" "GCF_023612875.1"

# 6. Dhole
download_genome "Cuon_alpinus" "ASM2211383v1" "GCF_022113835.1"

# Clean up
cd ..
rm -rf tmp_downloads

echo ""
echo "========================================="
echo "Download Summary"
echo "========================================="
echo ""

# Count downloaded files
n_genomes=$(ls data/genomes/*.fa 2>/dev/null | wc -l)
n_annot=$(ls data/annotations/*.gff3 2>/dev/null | wc -l)
n_cds=$(ls data/cds/*.cds.fa 2>/dev/null | wc -l)

echo "Genomes downloaded: $n_genomes"
echo "Annotations downloaded: $n_annot"
echo "CDS files downloaded: $n_cds"
echo ""

if [ $n_genomes -ge 4 ]; then
    echo "✓ Minimum data requirements met (4+ genomes)"
    echo ""
    echo "Next steps:"
    echo "  1. Download additional species (optional)"
    echo "  2. Get ortholog data from Ensembl BioMart (see DATA_SOURCES.md)"
    echo "  3. Download phylogeny (see DATA_SOURCES.md)"
    echo "  4. Run: python scripts/alignment/extract_cds.py"
else
    echo "⚠ WARNING: Fewer than 4 genomes downloaded"
    echo "Check your internet connection and retry failed downloads"
fi

echo ""
echo "Done!"
