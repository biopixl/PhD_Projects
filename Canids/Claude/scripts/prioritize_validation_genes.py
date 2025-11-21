#!/usr/bin/env python3
"""
prioritize_validation_genes.py

Systematically prioritize genes for functional validation based on:
- Selection strength
- Biological relevance to domestication
- Functional tractability
- Literature support
"""

import pandas as pd
import numpy as np

def main():
    print("="*80)
    print("GENE PRIORITIZATION FOR FUNCTIONAL VALIDATION")
    print("="*80)
    print()

    # Load annotated domestication genes
    df = pd.read_csv('results_3species_dog_only_ANNOTATED.tsv', sep='\t')
    print(f"Total domestication genes: {len(df)}")
    print()

    # Filter to annotated genes only
    annotated = df[df['gene_symbol'] != 'Unknown'].copy()
    print(f"Annotated genes: {len(annotated)}")
    print()

    # Define biological relevance categories
    # Higher score = more relevant to domestication phenotypes

    domestication_categories = {
        # Behavior & Neurotransmission (highest priority)
        'behavior': [
            'HTR2B', 'GABRA3', 'HCRTR1', 'GNAQ', 'GNAS', 'RGS4',
            'SLC6A4', 'MAOA', 'COMT', 'DRD4', 'OXTR'
        ],

        # Neural development & Wnt signaling
        'neural_wnt': [
            'LEF1', 'FZD3', 'FZD4', 'DVL3', 'SIX3', 'CXXC4', 'EDNRB',
            'WNT', 'NOTCH', 'SHH', 'BMP', 'FOXP2'
        ],

        # Morphology & Development
        'morphology': [
            'RUNX2', 'SOX9', 'PAX3', 'MSX1', 'DLX', 'HOX',
            'FGFR2', 'BMP', 'IGF1', 'GHR'
        ],

        # Stress response & HPA axis
        'stress': [
            'CRHR1', 'CRHR2', 'NR3C1', 'NR3C2', 'POMC', 'AVP',
            'CRH', 'ACTH', 'FKBP5'
        ],

        # Coat color & pigmentation
        'pigmentation': [
            'MC1R', 'ASIP', 'TYR', 'TYRP1', 'DCT', 'MLPH',
            'PMEL', 'SLC45A2', 'KIT', 'MITF', 'PAX3', 'SOX10', 'EDNRB'
        ],

        # Metabolism & Diet
        'metabolism': [
            'AMY2B', 'MGAM', 'SGLT1', 'LIPC', 'APOA2',
            'IGF1', 'IGFBP', 'GHR', 'LEPR'
        ],

        # Reproduction & Domestication timing
        'reproduction': [
            'GNRH', 'KISS1', 'ESR1', 'ESR2', 'AR',
            'LH', 'FSH', 'AMH'
        ],

        # Signaling pathways
        'signaling': [
            'MAPK', 'ERK', 'AKT', 'mTOR', 'PI3K',
            'JAK', 'STAT', 'SMAD', 'receptor', 'kinase'
        ]
    }

    # Score each gene
    scores = []

    for idx, row in annotated.iterrows():
        gene_symbol = row['gene_symbol']
        description = str(row['description']).lower()
        p_value = row['dog_pvalue']
        omega = row['dog_omega']

        # 1. Selection Strength Score (0-5)
        if p_value == 0:
            selection_score = 5.0
        elif p_value < 1e-15:
            selection_score = 5.0
        elif p_value < 1e-10:
            selection_score = 4.5
        elif p_value < 1e-5:
            selection_score = 4.0
        elif p_value < 1e-3:
            selection_score = 3.0
        else:
            selection_score = 2.0

        # Adjust by omega
        if omega > 0.8:
            selection_score += 0.5
        elif omega > 0.5:
            selection_score += 0.25
        selection_score = min(selection_score, 5.0)

        # 2. Biological Relevance Score (0-5)
        relevance_score = 0

        # Check if gene is in known domestication categories
        for category, genes in domestication_categories.items():
            for dom_gene in genes:
                if dom_gene.lower() in gene_symbol.lower() or dom_gene.lower() in description:
                    if category in ['behavior', 'neural_wnt']:
                        relevance_score += 2.0
                    elif category in ['morphology', 'stress', 'pigmentation']:
                        relevance_score += 1.5
                    else:
                        relevance_score += 1.0
                    break

        # Additional keywords in description
        behavior_keywords = ['neurotransmitter', 'synapse', 'neural', 'brain', 'behavior']
        morphology_keywords = ['craniofacial', 'skeleton', 'cartilage', 'bone', 'development']
        signaling_keywords = ['receptor', 'signal', 'kinase', 'transcription factor']

        for keyword in behavior_keywords:
            if keyword in description:
                relevance_score += 1.0
                break

        for keyword in morphology_keywords:
            if keyword in description:
                relevance_score += 0.5
                break

        for keyword in signaling_keywords:
            if keyword in description:
                relevance_score += 0.25

        relevance_score = min(relevance_score, 5.0)

        # 3. Functional Tractability Score (0-5)
        # Receptors, kinases, transcription factors = easier to assay
        tractability_score = 3.0  # baseline

        if any(x in description for x in ['receptor', 'kinase', 'transcription factor']):
            tractability_score += 1.5
        if any(x in description for x in ['enzyme', 'binding', 'activity']):
            tractability_score += 1.0
        if 'membrane' in description:
            tractability_score += 0.5
        if any(x in description for x in ['nuclear', 'mitochondrial']):
            tractability_score -= 0.5

        tractability_score = min(max(tractability_score, 1.0), 5.0)

        # 4. Literature Support (approximation based on description specificity)
        # More specific descriptions = better characterized
        literature_score = 3.0  # baseline

        if len(description) > 50:  # Detailed description
            literature_score += 1.0
        if any(x in description for x in ['receptor', 'factor', 'enzyme']):
            literature_score += 0.5
        if description == 'no description':
            literature_score = 1.0

        literature_score = min(literature_score, 5.0)

        # Calculate total score
        total_score = (selection_score + relevance_score +
                      tractability_score + literature_score)

        # Assign tier
        if total_score >= 16:
            tier = 1
        elif total_score >= 13:
            tier = 2
        else:
            tier = 3

        scores.append({
            'gene_id': row['gene_id'],
            'gene_symbol': gene_symbol,
            'description': row['description'],
            'p_value': p_value,
            'omega': omega,
            'selection_score': round(selection_score, 2),
            'relevance_score': round(relevance_score, 2),
            'tractability_score': round(tractability_score, 2),
            'literature_score': round(literature_score, 2),
            'total_score': round(total_score, 2),
            'tier': tier
        })

    # Create dataframe and sort
    scored_df = pd.DataFrame(scores)
    scored_df = scored_df.sort_values('total_score', ascending=False)

    # Save results
    output_file = 'enrichment_results/GENE_PRIORITIZATION_FOR_VALIDATION.tsv'
    scored_df.to_csv(output_file, sep='\t', index=False)
    print(f"✓ Saved prioritization results: {output_file}")
    print()

    # Summary statistics
    print("="*80)
    print("PRIORITIZATION SUMMARY")
    print("="*80)
    print()

    tier1 = scored_df[scored_df['tier'] == 1]
    tier2 = scored_df[scored_df['tier'] == 2]
    tier3 = scored_df[scored_df['tier'] == 3]

    print(f"Tier 1 (Priority: IMMEDIATE): {len(tier1)} genes")
    print(f"Tier 2 (Priority: FOLLOW-UP): {len(tier2)} genes")
    print(f"Tier 3 (Priority: EXPLORATORY): {len(tier3)} genes")
    print()

    # Top 20 genes
    print("="*80)
    print("TOP 20 GENES FOR VALIDATION")
    print("="*80)
    print()

    top20 = scored_df.head(20)

    print(f"{'Rank':<5} {'Gene':<10} {'Total':<6} {'Sel':<5} {'Rel':<5} {'Tract':<5} {'Lit':<5} {'Description'}")
    print("-"*80)

    for rank, (idx, row) in enumerate(top20.iterrows(), 1):
        gene = row['gene_symbol'][:9]
        total = f"{row['total_score']:.1f}"
        sel = f"{row['selection_score']:.1f}"
        rel = f"{row['relevance_score']:.1f}"
        tract = f"{row['tractability_score']:.1f}"
        lit = f"{row['literature_score']:.1f}"
        desc = row['description'][:35]

        print(f"{rank:<5} {gene:<10} {total:<6} {sel:<5} {rel:<5} {tract:<5} {lit:<5} {desc}")

    print()

    # Category breakdown
    print("="*80)
    print("TIER 1 GENES BY CATEGORY")
    print("="*80)
    print()

    # Categorize Tier 1 genes
    tier1_categories = {
        'Wnt/Neural': [],
        'Behavior/Neurotransmitter': [],
        'Morphology/Development': [],
        'Signaling': [],
        'Other': []
    }

    for idx, row in tier1.iterrows():
        gene = row['gene_symbol']
        desc = str(row['description']).lower()

        if any(x in gene.upper() for x in ['LEF1', 'FZD', 'DVL', 'WNT', 'EDNRB', 'SIX']):
            tier1_categories['Wnt/Neural'].append(gene)
        elif any(x in gene.upper() for x in ['HTR', 'GABA', 'SLC6', 'HCRTR', 'GNAQ']):
            tier1_categories['Behavior/Neurotransmitter'].append(gene)
        elif any(x in gene.upper() or x in desc for x in ['fgfr', 'bmp', 'sox', 'hox', 'runx']):
            tier1_categories['Morphology/Development'].append(gene)
        elif any(x in desc for x in ['receptor', 'kinase', 'signal']):
            tier1_categories['Signaling'].append(gene)
        else:
            tier1_categories['Other'].append(gene)

    for category, genes in tier1_categories.items():
        if genes:
            print(f"{category}: {len(genes)} genes")
            print(f"  {', '.join(genes[:10])}")
            if len(genes) > 10:
                print(f"  ... and {len(genes)-10} more")
            print()

    # Export Tier 1 genes for validation
    tier1_file = 'enrichment_results/TIER1_VALIDATION_GENES.tsv'
    tier1.to_csv(tier1_file, sep='\t', index=False)
    print(f"✓ Saved Tier 1 genes: {tier1_file}")
    print()

    print("="*80)
    print("PRIORITIZATION COMPLETE!")
    print("="*80)
    print()
    print("Next steps:")
    print("  1. Review Top 20 genes for immediate validation")
    print("  2. Focus on Wnt/Neural and Behavior categories")
    print("  3. Begin sequence analysis for Tier 1 genes")
    print("  4. Plan expression studies for top candidates")
    print()

if __name__ == '__main__':
    main()
