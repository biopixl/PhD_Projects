#!/bin/bash
# batch_align_protein.sh
# Run MAFFT on all protein sequences

set -euo pipefail

# Default parameters
INPUT_DIR="data/orthologs"
OUTPUT_DIR="alignments"
THREADS=4
MAFFT_STRATEGY="auto"  # or "linsi" for higher accuracy

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --strategy)
            MAFFT_STRATEGY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--input DIR] [--output DIR] [--threads N] [--strategy auto|linsi]"
            exit 1
            ;;
    esac
done

echo "Batch protein alignment with MAFFT"
echo "=================================="
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Threads: $THREADS"
echo "Strategy: $MAFFT_STRATEGY"
echo ""

# Check if MAFFT is installed
if ! command -v mafft &> /dev/null; then
    echo "ERROR: mafft not found in PATH"
    echo "Please install MAFFT: conda install -c bioconda mafft"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Find all protein FASTA files
PROTEIN_FILES=("$INPUT_DIR"/*/*.protein.fa)

if [ ${#PROTEIN_FILES[@]} -eq 0 ]; then
    echo "ERROR: No protein.fa files found in $INPUT_DIR"
    exit 1
fi

echo "Found ${#PROTEIN_FILES[@]} protein files to align"
echo ""

# Counter for progress
count=0
total=${#PROTEIN_FILES[@]}
failed=0

# Process each file
for protein_file in "${PROTEIN_FILES[@]}"; do
    ((count++))

    # Extract gene name from path
    gene_name=$(basename "$(dirname "$protein_file")")

    # Create output directory for this gene
    gene_output_dir="$OUTPUT_DIR/$gene_name"
    mkdir -p "$gene_output_dir"

    output_file="$gene_output_dir/${gene_name}.protein_aligned.fa"

    # Skip if already exists
    if [ -f "$output_file" ]; then
        echo "[$count/$total] Skipping $gene_name (already aligned)"
        continue
    fi

    echo "[$count/$total] Aligning $gene_name..."

    # Run MAFFT
    if [ "$MAFFT_STRATEGY" = "linsi" ]; then
        # High accuracy, slower
        if ! mafft --localpair --maxiterate 1000 --thread "$THREADS" \
             "$protein_file" > "$output_file" 2> "${output_file}.log"; then
            echo "  WARNING: MAFFT failed for $gene_name"
            ((failed++))
            continue
        fi
    else
        # Auto strategy - MAFFT chooses best method
        if ! mafft --auto --thread "$THREADS" \
             "$protein_file" > "$output_file" 2> "${output_file}.log"; then
            echo "  WARNING: MAFFT failed for $gene_name"
            ((failed++))
            continue
        fi
    fi

    echo "  Aligned sequences: $(grep -c '^>' "$output_file")"
done

echo ""
echo "=== Summary ==="
echo "Total processed: $count"
echo "Successful: $((count - failed))"
echo "Failed: $failed"
echo ""
echo "Alignments saved to: $OUTPUT_DIR"
