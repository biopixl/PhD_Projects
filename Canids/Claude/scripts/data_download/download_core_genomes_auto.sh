#!/bin/bash
# download_core_genomes_auto.sh
# Download high-priority Canidae genomes from NCBI (automated, no confirmation)

set -euo pipefail

echo "==================================="
echo "Canidae Genome Download Script"
echo "==================================="
echo ""
echo "Downloading 6 high-priority Canidae genomes from NCBI"
echo "Total download size: ~10-15 GB"
echo "Started: $(date)"
echo ""

# Check if directories exist
if [ ! -d "data/genomes" ] || [ ! -d "data/annotations" ] || [ ! -d "data/cds" ]; then
    echo "ERROR: Required directories not found"
    echo "Please run this script from the project root directory"
    exit 1
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

    echo "Downloading genome FASTA..."
    if wget -q --show-progress --timeout=300 --tries=3 \
        "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.fna.gz"; then
        echo "  ✓ Genome downloaded"
    else
        echo "  ✗ Failed to download genome"
        return 1
    fi

    echo "Downloading annotation GFF..."
    if wget -q --show-progress --timeout=300 --tries=3 \
        "${URL}/${ACCESSION}_${ASSEMBLY}_genomic.gff.gz"; then
        echo "  ✓ Annotation downloaded"
    else
        echo "  ⚠ Annotation download failed (continuing)"
    fi

    echo "Downloading CDS sequences..."
    if wget -q --show-progress --timeout=300 --tries=3 \
        "${URL}/${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna.gz"; then
        echo "  ✓ CDS downloaded"
    else
        echo "  ⚠ CDS download failed (continuing)"
    fi

    echo "Decompressing files..."
    gunzip -f *.gz 2>/dev/null || true

    echo "Moving to data directories..."
    [ -f "${ACCESSION}_${ASSEMBLY}_genomic.fna" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_genomic.fna" "../data/genomes/${SPECIES}.fa" && \
        echo "  ✓ Genome installed"

    [ -f "${ACCESSION}_${ASSEMBLY}_genomic.gff" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_genomic.gff" "../data/annotations/${SPECIES}.gff3" && \
        echo "  ✓ Annotation installed"

    [ -f "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" ] && \
        mv "${ACCESSION}_${ASSEMBLY}_cds_from_genomic.fna" "../data/cds/${SPECIES}.cds.fa" && \
        echo "  ✓ CDS installed"

    echo "✓ $SPECIES complete"
    echo ""

    return 0
}

# Track success
SUCCESS=0
FAILED=0

# Download genomes (ordered by priority/size)
echo "==================================="
echo "Starting genome downloads"
echo "==================================="
echo ""

# 1. Dog (reference genome) - ~2.4 GB
if download_genome "Canis_familiaris" "ROS_Cfam_1.0" "GCF_011100685.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 2. Gray Wolf - ~2.3 GB
if download_genome "Canis_lupus" "ASM2732751v1" "GCF_027327525.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 3. Red Fox - ~2.5 GB
if download_genome "Vulpes_vulpes" "VulVul2.2" "GCF_003160815.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 4. Arctic Fox - ~2.4 GB
if download_genome "Vulpes_lagopus" "ASM164880v2" "GCF_001648805.2"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 5. African Wild Dog - ~2.3 GB
if download_genome "Lycaon_pictus" "UMICH_Lp_1.0" "GCF_023612875.1"; then
    ((SUCCESS++))
else
    ((FAILED++))
fi

# 6. Dhole - ~2.2 GB
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
echo "  Successful: $SUCCESS"
echo "  Failed: $FAILED"
echo ""
echo "Files on disk:"
echo "  Genomes: $n_genomes"
echo "  Annotations: $n_annot"
echo "  CDS files: $n_cds"
echo ""

# Check file sizes
echo "Genome sizes:"
du -h data/genomes/*.fa 2>/dev/null | sort -h || echo "  No genomes found"
echo ""

if [ $n_genomes -ge 4 ]; then
    echo "✓ SUCCESS: Minimum data requirements met"
    echo ""
    echo "Next steps:"
    echo "  1. Download ortholog table from Ensembl BioMart"
    echo "  2. Extract orthologs: python scripts/alignment/extract_cds.py"
    echo "  3. Check status: Rscript scripts/data_download/check_data_status.R"
else
    echo "⚠ WARNING: Only $n_genomes genomes downloaded (minimum 4 needed)"
    echo "Some downloads may have failed. Check network connection."
fi

echo ""
echo "Done!"
