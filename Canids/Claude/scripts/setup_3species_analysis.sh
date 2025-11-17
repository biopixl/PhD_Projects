#!/bin/bash
# Setup script for 3-species phylogenomic analysis
# Run after Dingo CDS download completes

echo "=== 3-Species Analysis Setup ==="
echo "Species: Dog, Dingo, Red fox"
echo ""

# Check if Dingo CDS exists
if [ ! -f data/cds/Canis_lupus_dingo.cds.fa ]; then
    echo "ERROR: Dingo CDS file not found!"
    echo "Checking download status..."
    ls -lh data/cds/Canis_lupus_dingo.cds.fa* 2>/dev/null || echo "  No Dingo files found"
    exit 1
fi

echo "✓ Dingo CDS found"
echo ""

# Count sequences
echo "Counting CDS sequences:"
echo "  Dog:     $(grep -c '^>' data/cds/Canis_familiaris.cds.fa)"
echo "  Dingo:   $(grep -c '^>' data/cds/Canis_lupus_dingo.cds.fa)"
echo "  Red fox: $(grep -c '^>' data/cds/Vulpes_vulpes.cds.fa)"
echo ""

# Create output directories
echo "Creating 3-species output directories..."
mkdir -p data/orthologs_3species
mkdir -p alignments_3species
mkdir -p codon_alignments_3species
mkdir -p hyphy_results_3species/absrel
mkdir -p logs_3species/hyphy/absrel
mkdir -p logs_3species/mafft
mkdir -p logs_3species/pal2nal
echo "✓ Directories created"
echo ""

# Extract 3-species orthologs
echo "Extracting 3-species orthologs..."
echo "This will take ~2 hours for all orthologs"
echo ""

source ~/miniforge3/bin/activate canid_phylogenomics

python3 scripts/alignment/extract_cds_biomart.py \
    --orthologs data/orthologs/ensembl_compara_table.tsv \
    --cds_dir data/cds \
    --out data/orthologs_3species \
    --min_species 3 \
    2>&1 | tee logs_3species/ortholog_extraction_3species.log

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "  1. Review extracted orthologs in data/orthologs_3species/"
echo "  2. Run Snakemake with 3-species configuration"
echo ""
