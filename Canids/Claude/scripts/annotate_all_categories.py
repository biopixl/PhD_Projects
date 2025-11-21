#!/usr/bin/env python3
"""
annotate_all_categories.py

Annotate all selection categories:
- Dog only (domestication): 430 genes
- Dingo only (wild Canis): 3,210 genes
- Fox only: 3,662 genes
- Dog + Dingo (ancient Canis): 164 genes
- Dog + Fox: 245 genes
- Dingo + Fox: 603 genes
- All three: 117 genes
"""

import json
import pandas as pd
from pathlib import Path

def load_annotations():
    """Load gene annotations"""
    with open('data/gene_annotations.json', 'r') as f:
        return json.load(f)

def annotate_file(input_file, annotations):
    """Annotate a single results file"""
    print(f"\nProcessing: {input_file}")

    if not Path(input_file).exists():
        print(f"  SKIP: File not found")
        return None

    df = pd.read_csv(input_file, sep='\t')
    print(f"  Genes: {len(df):,}")

    # Add annotations
    symbols = []
    descriptions = []

    for idx, row in df.iterrows():
        gene_id = row['gene_id']

        if gene_id in annotations:
            ann = annotations[gene_id]
            symbols.append(ann.get('symbol', 'Unknown'))
            descriptions.append(ann.get('description', 'No description'))
        else:
            symbols.append('Unknown')
            descriptions.append('No description')

    df['gene_symbol'] = symbols
    df['description'] = descriptions

    # Save annotated version
    output_file = input_file.replace('.tsv', '_ANNOTATED.tsv')
    df.to_csv(output_file, sep='\t', index=False)
    print(f"  Saved: {output_file}")

    annotated_count = sum([s != 'Unknown' for s in symbols])
    print(f"  Annotated: {annotated_count} / {len(df)} ({annotated_count/len(df)*100:.1f}%)")

    return df

def main():
    print("=" * 80)
    print("ANNOTATING ALL SELECTION CATEGORIES")
    print("=" * 80)

    # Load annotations
    print("\nLoading gene annotations...")
    annotations = load_annotations()
    print(f"  Loaded {len(annotations):,} gene annotations")

    # Files to annotate
    files = {
        'Dog only (domestication)': 'results_3species_dog_only.tsv',
        'Dingo only (wild Canis)': 'results_3species_dingo_only.tsv',
        'Fox only': 'results_3species_fox_only.tsv',
        'Dog + Dingo': 'results_3species_dog_dingo.tsv',
        'Dog + Fox': 'results_3species_dog_fox.tsv',
        'Dingo + Fox': 'results_3species_dingo_fox.tsv',
        'All three lineages': 'results_3species_all_three.tsv',
    }

    # Annotate each category
    results = {}
    for category, filename in files.items():
        df = annotate_file(filename, annotations)
        if df is not None:
            results[category] = df

    # Summary table
    print("\n" + "=" * 80)
    print("ANNOTATION SUMMARY")
    print("=" * 80)
    print()
    print(f"{'Category':<30} {'Total Genes':<15} {'Annotated':<15} {'%':<10}")
    print("-" * 80)

    for category, df in results.items():
        total = len(df)
        annotated = len(df[df['gene_symbol'] != 'Unknown'])
        pct = annotated / total * 100
        print(f"{category:<30} {total:<15,} {annotated:<15,} {pct:<10.1f}")

    print()
    print("=" * 80)
    print("COMPLETE!")
    print("=" * 80)
    print()
    print("All annotated files saved with '_ANNOTATED.tsv' suffix")
    print()

if __name__ == '__main__':
    main()
