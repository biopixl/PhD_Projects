#!/usr/bin/env python3
"""
Categorize genes under positive selection into functional groups
"""

import pandas as pd
from collections import defaultdict

# Functional category keywords
CATEGORIES = {
    'Transcription & Gene Regulation': [
        'transcription', 'zinc finger', 'znf', 'homeobox', 'pou', 'creb',
        'tata', 'taf', 'sox', 'phd finger', 'chromatin', 'histone', 'hdac'
    ],
    'Metabolism & Energy': [
        'kinase', 'metabolic', 'glyco', 'reductase', 'oxidase', 'synthase',
        'dehydrogenase', 'transferase', 'phosphatase', 'insulin', 'glucose'
    ],
    'Protein Processing & Degradation': [
        'proteasome', 'ubiquitin', 'protease', 'peptidase', 'chaperone',
        'f-box', 'fbxl', 'sumo', 'deubiquitinase'
    ],
    'RNA Processing & Translation': [
        'ribosom', 'rna ', 'mrna', 'rrna', 'splicing', 'spliceosome',
        'translation', 'lsm', 'rbm', 'deadbox', 'ddx'
    ],
    'Neural & Synaptic': [
        'neural', 'neuron', 'synap', 'neuro', 'brain', 'calcium channel',
        'neurotransmitter', 'ncam', 'receptor'
    ],
    'Signal Transduction': [
        'signal', 'g protein', 'gnb', 'gtp', 'ras', 'kinase', 'phosphatase',
        'receptor', 'ligand', 'chemokine', 'cytokine'
    ],
    'Cell Cycle & Division': [
        'cell cycle', 'cyclin', 'mitotic', 'kinetochore', 'centrosome',
        'centriole', 'spindle', 'cep', 'nek'
    ],
    'Immune System': [
        'immune', 'antigen', 'antibody', 'lymphocyte', 'mhc', 'hla',
        'interferon', 'interleukin', 'cd164', 'ly9'
    ],
    'Mitochondrial': [
        'mitochondrial', 'mtch', 'mrpl', 'mecr', 'cox'
    ],
    'Sensory & Receptor': [
        'taste', 'olfact', 'opsin', 'rhodopsin', 'receptor', 'gpcr',
        'odorant', 'vomeronasal'
    ],
    'Membrane & Transport': [
        'membrane', 'transport', 'solute carrier', 'slc', 'channel',
        'transporter', 'tram', 'syntaxin'
    ],
    'Cytoskeleton & Motility': [
        'actin', 'tubulin', 'myosin', 'dynein', 'kinesin', 'motor protein',
        'cilium', 'flagell', 'ift'
    ],
    'DNA Repair & Maintenance': [
        'dna repair', 'rad', 'excision', 'telomere', 'chromosome',
        'nucleotide excision', 'mismatch repair'
    ]
}

def categorize_gene(symbol, description):
    """Assign gene to functional categories"""
    categories = []
    text = f"{symbol} {description}".lower()

    for category, keywords in CATEGORIES.items():
        for keyword in keywords:
            if keyword in text:
                categories.append(category)
                break

    if not categories:
        categories.append('Other/Unknown')

    return categories

def main():
    # Read results
    df = pd.read_csv('results_summary.tsv', sep='\t')

    print("=" * 80)
    print("FUNCTIONAL CATEGORIZATION OF GENES UNDER POSITIVE SELECTION")
    print("=" * 80)
    print()

    # Categorize all genes
    gene_categories = defaultdict(list)

    for _, row in df.iterrows():
        symbol = row['Gene_Symbol']
        description = row['Description']
        omega = row['Omega']

        categories = categorize_gene(symbol, description)

        for category in categories:
            gene_categories[category].append({
                'gene_id': row['Gene_ID'],
                'symbol': symbol,
                'omega': omega,
                'description': description
            })

    # Sort categories by number of genes
    sorted_categories = sorted(gene_categories.items(), key=lambda x: len(x[1]), reverse=True)

    print(f"Total genes under selection: {len(df)}")
    print(f"Genes with annotations: {len(df[df['Gene_Symbol'] != 'Unknown'])}")
    print()

    print("=" * 80)
    print("FUNCTIONAL CATEGORIES (Ranked by Number of Genes)")
    print("=" * 80)
    print()

    for category, genes in sorted_categories:
        print(f"\n### {category} ({len(genes)} genes)")
        print("-" * 80)

        # Show top 10 genes in each category
        for i, gene in enumerate(genes[:10], 1):
            symbol = gene['symbol'] if gene['symbol'] != 'Unknown' else gene['gene_id']
            omega_str = str(gene['omega'])[:10]
            desc = gene['description'][:50] if gene['description'] != 'No description' else ''

            print(f"  {i:2}. {symbol:15} (ω={omega_str:10}) {desc}")

        if len(genes) > 10:
            print(f"     ... and {len(genes) - 10} more")

    # Summary statistics
    print("\n" + "=" * 80)
    print("CATEGORY SUMMARY")
    print("=" * 80)
    print()

    category_counts = {cat: len(genes) for cat, genes in gene_categories.items()}
    total_categorized = sum(category_counts.values())

    for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
        pct = (count / len(df)) * 100
        print(f"  {category:40} {count:4} genes ({pct:5.1f}%)")

    print()
    print(f"Note: Some genes may belong to multiple categories")
    print(f"Total category assignments: {total_categorized}")
    print(f"Average categories per gene: {total_categorized / len(df):.2f}")

if __name__ == '__main__':
    main()
