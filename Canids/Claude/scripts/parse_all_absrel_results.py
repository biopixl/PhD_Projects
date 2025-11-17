#!/usr/bin/env python3
"""
Parse all aBSREL results and identify genes under positive selection
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

def parse_log_file(log_path):
    """Parse HyPhy log file for selection results"""
    with open(log_path, 'r') as f:
        content = f.read()

    result = {
        'gene': Path(log_path).stem,
        'significant': False,
        'omega': None,
        'pvalue': None,
        'sites': None
    }

    # Check for significant selection
    if 'p-value =  0.00000' in content or 'p-value = 0.00000' in content:
        result['significant'] = True

        # Extract omega value
        omega_match = re.search(r'\|\s+Vulpes_vulpes\s+\|\s+\d+\s+\|\s+([\d.>]+)\s+\(', content)
        if omega_match:
            result['omega'] = omega_match.group(1)

        # Extract sites under selection
        sites_match = re.search(r'Sites @ EBF>=100 \|\s+(\d+)', content)
        if sites_match:
            result['sites'] = int(sites_match.group(1))

        # Extract p-value
        pvalue_match = re.search(r'p-value =\s+([\d.]+)', content)
        if pvalue_match:
            result['pvalue'] = float(pvalue_match.group(1))

    return result

def load_gene_annotations():
    """Load gene annotations from JSON file"""
    annotation_file = Path('data/gene_annotations.json')

    if not annotation_file.exists():
        print("Warning: Gene annotation file not found. Run create_gene_annotation_map.py first.")
        return {}

    with open(annotation_file, 'r') as f:
        return json.load(f)

def get_gene_info(gene_name, gene_annotations):
    """Get gene symbol and description from annotation map"""
    if gene_name in gene_annotations:
        info = gene_annotations[gene_name]
        return info.get('symbol', 'Unknown'), info.get('description', 'No description')

    return 'Unknown', 'No description'

def main():
    # Directories
    logs_dir = Path('logs/hyphy/absrel')

    print("=== aBSREL Results Summary ===\n")

    # Load gene annotations
    print("Loading gene annotations...")
    gene_annotations = load_gene_annotations()
    print(f"Loaded annotations for {len(gene_annotations)} genes\n")

    # Find all log files
    log_files = list(logs_dir.glob('*.log'))
    print(f"Total log files found: {len(log_files)}")

    if len(log_files) == 0:
        print("No log files found. Analysis may still be running.")
        return

    # Parse all logs
    print("Parsing results...\n")
    all_results = []
    selected_genes = []

    for log_file in log_files:
        result = parse_log_file(log_file)
        all_results.append(result)

        if result['significant']:
            # Get gene annotation
            symbol, description = get_gene_info(result['gene'], gene_annotations)

            result['symbol'] = symbol
            result['description'] = description
            selected_genes.append(result)

    # Summary statistics
    total_analyzed = len(all_results)
    total_selected = len(selected_genes)
    percent_selected = (total_selected / total_analyzed * 100) if total_analyzed > 0 else 0

    print(f"Total genes analyzed: {total_analyzed}")
    print(f"Genes under positive selection: {total_selected} ({percent_selected:.1f}%)")
    print()

    # Sort by omega value (descending)
    selected_genes.sort(key=lambda x: float(x['omega'].replace('>', '')) if x['omega'] and x['omega'].replace('>', '').replace('.', '').isdigit() else 0, reverse=True)

    # Print selected genes
    if selected_genes:
        print("=" * 100)
        print(f"{'Gene ID':<20} {'Symbol':<15} {'Omega (dN/dS)':<15} {'Sites':<10} {'Description':<40}")
        print("=" * 100)

        for gene in selected_genes:
            gene_id = gene['gene']
            symbol = gene['symbol'] or 'Unknown'
            omega = gene['omega'] or 'N/A'
            sites = str(gene['sites']) if gene['sites'] else 'N/A'
            desc = (gene['description'] or 'No description')[:40]

            print(f"{gene_id:<20} {symbol:<15} {omega:<15} {sites:<10} {desc:<40}")

    # Save detailed results to file
    output_file = 'results_summary.tsv'
    with open(output_file, 'w') as f:
        f.write("Gene_ID\tGene_Symbol\tOmega\tSites\tP_value\tDescription\n")
        for gene in selected_genes:
            f.write(f"{gene['gene']}\t")
            f.write(f"{gene['symbol'] or 'Unknown'}\t")
            f.write(f"{gene['omega'] or 'NA'}\t")
            f.write(f"{gene['sites'] or 'NA'}\t")
            f.write(f"{gene['pvalue'] or 'NA'}\t")
            f.write(f"{gene['description'] or 'No description'}\n")

    print()
    print(f"Detailed results saved to: {output_file}")

    # Functional category analysis
    print("\n=== Functional Categories (Top Keywords) ===")
    keywords = defaultdict(int)
    for gene in selected_genes:
        if gene['description']:
            words = gene['description'].lower().split()
            for word in words:
                if len(word) > 4 and word.isalpha():  # Skip short words and non-alpha
                    keywords[word] += 1

    top_keywords = sorted(keywords.items(), key=lambda x: x[1], reverse=True)[:10]
    for keyword, count in top_keywords:
        print(f"  {keyword}: {count}")

if __name__ == '__main__':
    main()
