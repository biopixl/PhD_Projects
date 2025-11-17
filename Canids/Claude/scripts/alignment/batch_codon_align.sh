#!/bin/bash
# batch_codon_align.sh
# Back-translate protein alignments to codon alignments using pal2nal

set -euo pipefail

# Default parameters
PROTEIN_ALN_DIR="alignments"
CDS_DIR="data/orthologs"
OUTPUT_DIR="codon_alignments"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --protein_aln)
            PROTEIN_ALN_DIR="$2"
            shift 2
            ;;
        --cds)
            CDS_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--protein_aln DIR] [--cds DIR] [--output DIR]"
            exit 1
            ;;
    esac
done

echo "Batch codon alignment with pal2nal"
echo "==================================="
echo "Protein alignments: $PROTEIN_ALN_DIR"
echo "CDS sequences: $CDS_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if pal2nal is installed
if ! command -v pal2nal.pl &> /dev/null; then
    echo "WARNING: pal2nal.pl not found in PATH"
    echo "Attempting to use system perl with pal2nal.pl..."
    # Try to find pal2nal in common locations
    if [ ! -f "/usr/local/bin/pal2nal.pl" ] && [ ! -f "$HOME/bin/pal2nal.pl" ]; then
        echo "ERROR: pal2nal.pl not found"
        echo "Please install pal2nal: http://www.bork.embl.de/pal2nal/"
        echo "Or use MACSE as an alternative (uncomment MACSE section below)"
        exit 1
    fi
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Find all protein alignment files
PROTEIN_ALNS=("$PROTEIN_ALN_DIR"/*/*.protein_aligned.fa)

if [ ${#PROTEIN_ALNS[@]} -eq 0 ]; then
    echo "ERROR: No protein_aligned.fa files found in $PROTEIN_ALN_DIR"
    exit 1
fi

echo "Found ${#PROTEIN_ALNS[@]} protein alignments to back-translate"
echo ""

# Counters
count=0
total=${#PROTEIN_ALNS[@]}
failed=0

for protein_aln in "${PROTEIN_ALNS[@]}"; do
    ((count++))

    # Extract gene name
    gene_name=$(basename "$(dirname "$protein_aln")")

    # Find corresponding CDS file
    cds_file="$CDS_DIR/$gene_name/${gene_name}.cds.fa"

    if [ ! -f "$cds_file" ]; then
        echo "[$count/$total] WARNING: CDS file not found for $gene_name"
        ((failed++))
        continue
    fi

    output_file="$OUTPUT_DIR/${gene_name}.codon.fa"

    # Skip if already exists
    if [ -f "$output_file" ]; then
        echo "[$count/$total] Skipping $gene_name (already aligned)"
        continue
    fi

    echo "[$count/$total] Back-translating $gene_name..."

    # Run pal2nal
    if ! pal2nal.pl "$protein_aln" "$cds_file" -output fasta \
         > "$output_file" 2> "${output_file}.log"; then
        echo "  WARNING: pal2nal failed for $gene_name"
        ((failed++))
        continue
    fi

    # Verify output
    if [ ! -s "$output_file" ]; then
        echo "  WARNING: Empty output for $gene_name"
        ((failed++))
        rm -f "$output_file"
        continue
    fi

    n_seqs=$(grep -c '^>' "$output_file" || true)
    echo "  Codon alignment: $n_seqs sequences"
done

echo ""
echo "=== Summary ==="
echo "Total processed: $count"
echo "Successful: $((count - failed))"
echo "Failed: $failed"
echo ""
echo "Codon alignments saved to: $OUTPUT_DIR"

# Alternative: MACSE (handles frameshifts better, but slower)
# Uncomment this section if you prefer MACSE over pal2nal
#
# if ! command -v macse &> /dev/null; then
#     echo "ERROR: MACSE not found"
#     exit 1
# fi
#
# for cds_file in "$CDS_DIR"/*/*.cds.fa; do
#     gene_name=$(basename "$(dirname "$cds_file")" | sed 's/.cds.fa//')
#     output="$OUTPUT_DIR/${gene_name}.codon.fa"
#
#     macse -prog alignSequences \
#           -seq "$cds_file" \
#           -out_NT "$output" \
#           -out_AA "${output%.fa}.protein.fa"
# done
