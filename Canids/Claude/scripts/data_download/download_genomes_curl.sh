#!/bin/bash
# download_genomes_curl.sh
# Download Canidae genomes using curl (macOS compatible)

set -euo pipefail

echo "==================================="
echo "Canidae Genome Download Script"
echo "==================================="
echo ""
echo "Downloading 6 high-priority Canidae genomes from NCBI"
echo "Using curl (macOS compatible)"
echo "Total download size: ~10-15 GB"
echo "Started: $(date)"
echo ""

# Check if directories exist
if [ ! -d "data/genomes" ] || [ ! -d "data/annotations" ] || [ ! -d "data/cds" ]; then
    echo "ERROR: Required directories not found"
    echo "Creating directories..."
    mkdir -p data/{genomes,annotations,cds}
fi

# Create temporary download directory
mkdir -p tmp_downloads
cd tmp_downloads

echo "Starting downloads..."
echo ""

# Function to download and process a genome
download_genome() {
    local SPECIES=$1
    local ASSEMBLY=$2
    local ACCESSION=$3

    echo "========================================="
    echo "[$SPECIES]"
    echo "Assembly: $ASSEMBLY ($ACCESSION)"
    echo "Time: $(date +%H:%M:%S)"
    echo "========================================="

    # Construct base URL
    BASE_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all"

    # Split accession into path components
    PREFIX=$(echo $ACCESSION | cut -d'_' -f1)
    NUM=$(echo $ACCESSION | cut -d'_' -f2 | cut -d'.' -f1)
    P1=$(echo $NUM | cut -c1-3)
    P2=$(echo $NUM | cut -c4-6)
    P3=$(echo $NUM | cut -c7-9)

    URL="${BASE_URL}/${PREFIX}/${P1}/${P2}/${P3}/${ACCESSION}_${ASSEMBLY}"

    # Download genome FASTA
    echo "Downloading genome FASTA..."
    if curl -# -L -f --connect-timeout 30 --max-time 3600 \
        -o "${ACCESSION}_${ASSEMBLY}_genomic.fna.gz" \
        "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.fna.gz" 2>&1 | \
        grep -v "^$"; then
        echo "  ✓ Genome downloaded ($(du -h ${ACCESSION}_${ASSEMBLY}_genomic.fna.gz | cut -f1))"
    else
        echo "  ✗ Failed to download genome"
        return 1
    fi

    # Download annotation
    echo "Downloading annotation GFF..."
    if curl -# -L -f --connect-timeout 30 --max-time 1800 \
        -o "${ACCESSION}_${ASSEMBLY}_genomic.gff.gz" \
        "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.gff.gz" 2>&1 | \
        grep -v "^$"; then
        echo "  ✓ Annotation downloaded ($(du -h ${ACCESSION}_${ASSEMBLY}_genomic.gff.gz | cut -f1))"
    else
        echo "  ⚠ Annotation download failed (continuing)"
    fi

    # Download CDS
    echo "Downloading CDS sequences..."
    if curl -# -L -f --connect-timeout 30 --max-time 1800 \
        -o "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna.gz" \
        "${URL}/${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna.gz" 2>&1 | \
        grep -v "^$"; then
        echo "  ✓ CDS downloaded ($(du -h ${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna.gz | cut -f1))"
    else
        echo "  ⚠ CDS download failed (continuing)"
    fi

    echo "Decompressing files..."
    gunzip -f *.gz 2>/dev/null || true

    echo "Moving to data directories..."
    if [ -f "${ACCESSION}_${ASSEMBLY}_genomic.fna" ]; then
        mv "${ACCESSION}_${ASSEMBLY}_genomic.fna" "../data/genomes/${SPECIES}.fa"
        echo "  ✓ Genome installed: data/genomes/${SPECIES}.fa"
    fi

    if [ -f "${ACCESSION}_${ASSEMBLY}_genomic.gff" ]; then
        mv "${ACCESSION}_${ASSEMBLY}_genomic.gff" "../data/annotations/${SPECIES}.gff3"
        echo "  ✓ Annotation installed: data/annotations/${SPECIES}.gff3"
    fi

    if [ -f "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" ]; then
        mv "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" "../data/cds/${SPECIES}.cds.fa"
        echo "  ✓ CDS installed: data/cds/${SPECIES}.cds.fa"
    fi

    echo "✓ $SPECIES complete"
    echo ""

    return 0
}

# Track success
SUCCESS=0
FAILED=0

# Download genomes
echo "==================================="
echo "Starting genome downloads"
echo "==================================="
echo ""

# 1. Dog (reference genome)
echo ">>> Download 1/6: Canis familiaris (Dog)"
if download_genome "Canis_familiaris" "ROS_Cfam_1.0" "GCF_011100685.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 2. Gray Wolf
echo ">>> Download 2/6: Canis lupus (Gray Wolf)"
if download_genome "Canis_lupus" "ASM2732751v1" "GCF_027327525.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 3. Red Fox
echo ">>> Download 3/6: Vulpes vulpes (Red Fox)"
if download_genome "Vulpes_vulpes" "VulVul2.2" "GCF_003160815.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 4. Arctic Fox
echo ">>> Download 4/6: Vulpes lagopus (Arctic Fox)"
if download_genome "Vulpes_lagopus" "ASM164880v2" "GCF_001648805.2"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 5. African Wild Dog
echo ">>> Download 5/6: Lycaon pictus (African Wild Dog)"
if download_genome "Lycaon_pictus" "UMICH_Lp_1.0" "GCF_023612875.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 6. Dhole
echo ">>> Download 6/6: Cuon alpinus (Dhole)"
if download_genome "Cuon_alpinus" "ASM2211383v1" "GCF_022113835.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# Clean up
cd ..
rm -rf tmp_downloads

echo ""
echo "========================================="
echo "Download Complete"
echo "========================================="
echo "Finished: $(date)"
echo ""

# Count downloaded files
n_genomes=$(ls data/genomes/*.fa 2>/dev/null | wc -l | tr -d ' ')
n_annot=$(ls data/annotations/*.gff3 2>/dev/null | wc -l | tr -d ' ')
n_cds=$(ls data/cds/*.cds.fa 2>/dev/null | wc -l | tr -d ' ')

echo "Summary:"
echo "  Successful downloads: $SUCCESS/6"
echo "  Failed downloads: $FAILED/6"
echo ""
echo "Files on disk:"
echo "  Genomes: $n_genomes"
echo "  Annotations: $n_annot"
echo "  CDS files: $n_cds"
echo ""

# Check file sizes
if [ $n_genomes -gt 0 ]; then
    echo "Genome sizes:"
    du -h data/genomes/*.fa 2>/dev/null | sort -h
    echo ""

    total_size=$(du -sh data/genomes/ | cut -f1)
    echo "Total genome data: $total_size"
    echo ""
fi

if [ $n_genomes -ge 4 ]; then
    echo "✓ SUCCESS: Minimum data requirements met ($n_genomes/4 genomes)"
    echo ""
    echo "Next steps:"
    echo "  1. Check status: Rscript scripts/data_download/check_data_status.R"
    echo "  2. Download ortholog table from Ensembl BioMart (see DATA_SOURCES.md)"
    echo "  3. Extract orthologs: python scripts/alignment/extract_cds.py"
elif [ $n_genomes -gt 0 ]; then
    echo "⚠ PARTIAL SUCCESS: Downloaded $n_genomes/4 genomes"
    echo "Some downloads may have failed. You can:"
    echo "  - Continue with available genomes"
    echo "  - Re-run this script to retry failed downloads"
    echo "  - Manually download missing genomes (see DATA_SOURCES.md)"
else
    echo "✗ FAILED: No genomes downloaded"
    echo "Check your internet connection and try again"
fi

echo ""
echo "Done!"
