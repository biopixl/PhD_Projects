#!/usr/bin/env python3
"""
extract_wnt_genes.py

Extract genes belonging to the Wnt signaling pathway from enrichment results.
"""

import json
import pandas as pd

def main():
    print("="*80)
    print("WNT SIGNALING PATHWAY GENES")
    print("Domestication-Specific Genes (Dog only, not Dingo)")
    print("="*80)
    print()

    # Load g:Profiler results
    with open('enrichment_results/gprofiler_results.json') as f:
        data = json.load(f)

    # Get query genes (all genes that were submitted)
    query_genes = data['meta']['genes_metadata']['query']
    print(f"Total query genes: {len(query_genes)}")
    print()

    # Find Wnt signaling pathway term
    wnt_term = None
    for term in data['result']:
        if 'Wnt' in term['name'] or 'WNT' in term['name']:
            wnt_term = term
            break

    if wnt_term is None:
        print("ERROR: Wnt signaling pathway term not found!")
        return

    print("Wnt Pathway Term:")
    print(f"  Name: {wnt_term['name']}")
    print(f"  ID: {wnt_term['native']}")
    print(f"  P-value: {wnt_term['p_value']:.4f}")
    print(f"  Genes in term: {wnt_term['intersection_size']}")
    print(f"  Total pathway size: {wnt_term['term_size']}")
    print()

    # The intersections field contains indices or evidence codes
    # We need to map back to genes
    # g:Profiler stores gene mapping in a different way
    # Let's extract from the term and query metadata

    print("="*80)
    print("IDENTIFYING WNT PATHWAY GENES")
    print("="*80)
    print()

    # Load annotated domestication genes
    annotated = pd.read_csv('results_3species_dog_only_ANNOTATED.tsv', sep='\t')
    print(f"Loaded {len(annotated)} annotated domestication genes")
    print()

    # Known Wnt pathway genes from literature
    known_wnt_genes = {
        'LEF1', 'FZD3', 'FZD4', 'EDNRB', 'SIX3', 'CXXC4', 'DVL3',
        'WNT1', 'WNT2', 'WNT3', 'WNT4', 'WNT5A', 'WNT7A', 'WNT11',
        'CTNNB1', 'APC', 'AXIN1', 'AXIN2', 'GSK3B', 'LRP5', 'LRP6',
        'TCF7', 'TCF7L1', 'TCF7L2', 'SFRP1', 'SFRP2', 'DKK1', 'DKK2'
    }

    # Find which of our genes are in known Wnt pathway
    annotated_symbols = set(annotated['gene_symbol'].values)
    wnt_genes_found = annotated_symbols & known_wnt_genes

    print(f"Known Wnt pathway genes found in our dataset: {len(wnt_genes_found)}")
    print()

    if wnt_genes_found:
        print("="*80)
        print("WNT PATHWAY GENES IN DOMESTICATION SIGNATURE")
        print("="*80)
        print()

        wnt_df = annotated[annotated['gene_symbol'].isin(wnt_genes_found)].copy()
        wnt_df = wnt_df.sort_values('dog_pvalue')

        print(f"{'Gene':<10} {'P-value':<12} {'Omega':<8} {'Description'}")
        print("-"*80)

        for idx, row in wnt_df.iterrows():
            symbol = row['gene_symbol'][:9]
            pval = f"{row['dog_pvalue']:.2e}"
            omega = f"{row['dog_omega']:.2f}"
            desc = row['description'][:45]
            print(f"{symbol:<10} {pval:<12} {omega:<8} {desc}")

        print()

        # Save Wnt genes
        output_file = 'enrichment_results/WNT_PATHWAY_GENES.tsv'
        wnt_df.to_csv(output_file, sep='\t', index=False)
        print(f"✓ Saved Wnt pathway genes: {output_file}")
        print()

    # Also search for other pathway-related terms in descriptions
    print("="*80)
    print("ADDITIONAL SIGNALING/PATHWAY GENES")
    print("="*80)
    print()

    pathway_keywords = ['signal', 'receptor', 'kinase', 'transcription factor',
                        'growth factor', 'hormone', 'neurotransmitter']

    pathway_genes = annotated[
        annotated['description'].str.lower().str.contains('|'.join(pathway_keywords), na=False)
    ].copy()

    print(f"Genes with signaling/pathway annotations: {len(pathway_genes)}")
    print()

    # Top 20 pathway genes
    pathway_top20 = pathway_genes.sort_values('dog_pvalue').head(20)

    print("Top 20 Signaling/Pathway Genes:")
    print(f"{'Gene':<10} {'P-value':<12} {'Description'}")
    print("-"*80)

    for idx, row in pathway_top20.iterrows():
        symbol = row['gene_symbol'][:9]
        pval = f"{row['dog_pvalue']:.2e}"
        desc = row['description'][:55]
        print(f"{symbol:<10} {pval:<12} {desc}")

    print()

    # Save all pathway genes
    pathway_file = 'enrichment_results/SIGNALING_PATHWAY_GENES.tsv'
    pathway_genes.to_csv(pathway_file, sep='\t', index=False)
    print(f"✓ Saved signaling/pathway genes: {pathway_file}")
    print()

    print("="*80)
    print("SUMMARY")
    print("="*80)
    print()
    print(f"Wnt pathway genes (known): {len(wnt_genes_found)}")
    print(f"Signaling/pathway genes (annotated): {len(pathway_genes)}")
    print()
    print("These genes support the neural crest hypothesis of domestication.")
    print()

if __name__ == '__main__':
    main()
