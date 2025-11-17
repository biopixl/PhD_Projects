#!/bin/bash
# Monitor progress of phylogenomics analysis

TOTAL_GENES=18008

echo "=== Canidae Phylogenomics Analysis Progress ==="
echo "Started: $(date)"
echo ""

# Count completed aBSREL analyses
completed=$(ls hyphy_results/absrel/*.json 2>/dev/null | wc -l | tr -d ' ')
percent=$(echo "scale=2; ($completed / $TOTAL_GENES) * 100" | bc)

echo "Completed: $completed / $TOTAL_GENES genes ($percent%)"
echo ""

# Count alignments
prot_aligns=$(ls alignments/*/*.protein_aligned.fa 2>/dev/null | wc -l | tr -d ' ')
codon_aligns=$(ls codon_alignments/*.codon.fa 2>/dev/null | wc -l | tr -d ' ')

echo "Protein alignments: $prot_aligns"
echo "Codon alignments: $codon_aligns"
echo ""

# Estimate time remaining
if [ "$completed" -gt 0 ]; then
    # Get time since start from log
    if [ -f "logs/snakemake_fullscale_"*.log ]; then
        latest_log=$(ls -t logs/snakemake_fullscale_*.log | head -1)
        start_time=$(stat -f%B "$latest_log" 2>/dev/null || stat -c%Y "$latest_log" 2>/dev/null)
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        rate=$(echo "scale=4; $completed / $elapsed" | bc)
        remaining_genes=$((TOTAL_GENES - completed))
        eta_seconds=$(echo "scale=0; $remaining_genes / $rate" | bc)
        eta_hours=$(echo "scale=1; $eta_seconds / 3600" | bc)

        echo "Elapsed time: $((elapsed / 3600))h $((elapsed % 3600 / 60))m"
        echo "Processing rate: $(echo "scale=2; $rate * 3600" | bc) genes/hour"
        echo "Estimated time remaining: ${eta_hours} hours"
    fi
fi

echo ""
echo "Recent log activity:"
tail -20 "$latest_log" 2>/dev/null || echo "  (no log found)"
