#!/usr/bin/env python3
"""
enrichment_analysis.py

Perform GO and KEGG enrichment analysis on domestication genes.

This script prepares gene lists for enrichment analysis using:
1. PANTHER online tool (recommended for dog genes)
2. g:Profiler API
3. Output formatted for publication tables

For full enrichment, recommend using clusterProfiler in R or PANTHER web interface.
"""

import pandas as pd
import json
import requests
import time
from pathlib import Path

def load_domestication_genes(annotated_file='results_3species_dog_only_ANNOTATED.tsv'):
    """Load the 430 domestication genes with annotations"""
    print(f"Loading domestication genes from: {annotated_file}")

    df = pd.read_csv(annotated_file, sep='\t')
    print(f"  Loaded {len(df)} genes")

    # Filter to annotated genes (have symbols)
    annotated = df[df['gene_symbol'] != 'Unknown'].copy()
    print(f"  Annotated with symbols: {len(annotated)}")

    return df, annotated

def prepare_gene_lists(annotated_df, output_dir='enrichment_input'):
    """
    Prepare gene lists in different formats for enrichment tools
    """
    Path(output_dir).mkdir(exist_ok=True)

    print(f"\nPreparing gene lists in {output_dir}/")

    # 1. Gene symbols only (for PANTHER, g:Profiler)
    symbols = annotated_df['gene_symbol'].tolist()
    symbol_file = f"{output_dir}/domestication_genes_SYMBOLS.txt"
    with open(symbol_file, 'w') as f:
        f.write('\n'.join(symbols))
    print(f"  Gene symbols: {symbol_file} ({len(symbols)} genes)")

    # 2. Gene IDs (for Ensembl-based tools)
    gene_ids = annotated_df['gene_id'].tolist()
    id_file = f"{output_dir}/domestication_genes_IDS.txt"
    with open(id_file, 'w') as f:
        f.write('\n'.join(gene_ids))
    print(f"  Gene IDs: {id_file} ({len(gene_ids)} genes)")

    # 3. Combined table (symbol + ID + p-value)
    combined_file = f"{output_dir}/domestication_genes_COMBINED.tsv"
    annotated_df[['gene_symbol', 'gene_id', 'dog_pvalue', 'description']].to_csv(
        combined_file, sep='\t', index=False
    )
    print(f"  Combined table: {combined_file}")

    return symbol_file, id_file, combined_file

def run_gprofiler_enrichment(gene_list, organism='cfamiliaris'):
    """
    Run enrichment using g:Profiler API

    organism options:
    - 'cfamiliaris' = Dog
    - 'hsapiens' = Human (for comparative analysis)
    """
    print(f"\nRunning g:Profiler enrichment...")
    print(f"  Organism: {organism}")
    print(f"  Genes: {len(gene_list)}")

    # g:Profiler API endpoint
    url = "https://biit.cs.ut.ee/gprofiler/api/gost/profile/"

    # Prepare request
    payload = {
        'organism': organism,
        'query': gene_list,
        'sources': ['GO:BP', 'GO:MF', 'GO:CC', 'KEGG', 'REAC'],
        'user_threshold': 0.05,
        'significance_threshold_method': 'fdr',
        'background': []
    }

    try:
        print("  Sending request to g:Profiler...")
        response = requests.post(url, json=payload, timeout=60)

        if response.status_code == 200:
            result = response.json()
            print("  ✓ Success!")
            return result
        else:
            print(f"  ✗ Error: HTTP {response.status_code}")
            return None

    except Exception as e:
        print(f"  ✗ Error: {e}")
        return None

def parse_gprofiler_results(result, output_file='enrichment_results_gprofiler.tsv'):
    """Parse and save g:Profiler results"""

    if not result or 'result' not in result:
        print("No results to parse")
        return None

    results_list = result['result']

    if not results_list:
        print("No significant enrichments found")
        return None

    print(f"\nParsing g:Profiler results...")
    print(f"  Total enriched terms: {len(results_list)}")

    # Convert to DataFrame
    enrichment_data = []

    for term in results_list:
        enrichment_data.append({
            'source': term.get('source', ''),
            'term_id': term.get('native', ''),
            'term_name': term.get('name', ''),
            'p_value': term.get('p_value', 1.0),
            'fdr': term.get('p_value', 1.0),  # g:Profiler returns adjusted p-value
            'intersection_size': term.get('intersection_size', 0),
            'term_size': term.get('term_size', 0),
            'query_size': term.get('query_size', 0),
            'intersection_genes': ','.join(term.get('intersections', [[]])[0])
        })

    df = pd.DataFrame(enrichment_data)

    # Sort by p-value
    df = df.sort_values('p_value')

    # Save
    df.to_csv(output_file, sep='\t', index=False)
    print(f"  Saved to: {output_file}")

    # Summary by source
    print("\nEnrichment summary by source:")
    for source in df['source'].unique():
        count = len(df[df['source'] == source])
        print(f"  {source}: {count} terms")

    return df

def create_enrichment_summary(enrichment_df, top_n=20):
    """Create publication-ready summary tables"""

    if enrichment_df is None or len(enrichment_df) == 0:
        print("\nNo enrichments to summarize")
        return

    print(f"\n{'='*80}")
    print("TOP ENRICHED TERMS (Publication Table)")
    print('='*80)
    print()

    # Top 20 overall
    print(f"{'Source':<10} {'Term ID':<15} {'Term Name':<40} {'P-value':<12} {'Genes':<8}")
    print('-'*90)

    for idx, row in enrichment_df.head(top_n).iterrows():
        source = row['source'][:9]
        term_id = row['term_id'][:14]
        term_name = row['term_name'][:39]
        pval = f"{row['p_value']:.2e}"
        genes = row['intersection_size']

        print(f"{source:<10} {term_id:<15} {term_name:<40} {pval:<12} {genes:<8}")

    print()

    # Save category-specific tables
    for source in ['GO:BP', 'GO:MF', 'GO:CC', 'KEGG']:
        source_df = enrichment_df[enrichment_df['source'] == source]

        if len(source_df) > 0:
            output_file = f'enrichment_{source.replace(":", "_")}_top20.tsv'
            source_df.head(20).to_csv(output_file, sep='\t', index=False)
            print(f"Saved {source}: {output_file} ({len(source_df)} total terms)")

def main():
    print("="*80)
    print("GO/KEGG ENRICHMENT ANALYSIS - DOMESTICATION GENES")
    print("="*80)
    print()

    # Load genes
    full_df, annotated_df = load_domestication_genes()

    # Prepare gene lists
    symbol_file, id_file, combined_file = prepare_gene_lists(annotated_df)

    # Get gene symbols for enrichment
    gene_symbols = annotated_df['gene_symbol'].tolist()

    print("\n" + "="*80)
    print("ENRICHMENT ANALYSIS OPTIONS")
    print("="*80)
    print()
    print("Option 1: PANTHER (Recommended for dog genes)")
    print("  Website: http://pantherdb.org/")
    print("  Steps:")
    print("    1. Upload file: enrichment_input/domestication_genes_SYMBOLS.txt")
    print("    2. Select organism: Dog (Canis lupus familiaris)")
    print("    3. Select analysis: Statistical overrepresentation test")
    print("    4. Select annotation: GO biological process, KEGG pathways")
    print("    5. Download results")
    print()

    print("Option 2: g:Profiler (Automated via API)")
    print("  Will attempt automated enrichment...")

    # Try g:Profiler with dog
    print("\nAttempting g:Profiler with Canis familiaris...")
    result_dog = run_gprofiler_enrichment(gene_symbols[:50], organism='cfamiliaris')  # Test with first 50

    if result_dog:
        df_dog = parse_gprofiler_results(result_dog, 'enrichment_results_dog_gprofiler.tsv')
        if df_dog is not None:
            create_enrichment_summary(df_dog)
    else:
        print("  Dog enrichment not available via g:Profiler")
        print("  Trying with human orthologs for reference...")

        # Try with human as reference
        result_human = run_gprofiler_enrichment(gene_symbols[:50], organism='hsapiens')
        if result_human:
            df_human = parse_gprofiler_results(result_human, 'enrichment_results_human_gprofiler.tsv')
            if df_human is not None:
                print("\n  NOTE: These are human enrichments for reference")
                create_enrichment_summary(df_human)

    print("\n" + "="*80)
    print("MANUAL ENRICHMENT INSTRUCTIONS")
    print("="*80)
    print()
    print("For publication-quality enrichment, use PANTHER:")
    print()
    print("1. Go to http://pantherdb.org/")
    print("2. Upload: enrichment_input/domestication_genes_SYMBOLS.txt")
    print("3. Select 'Canis lupus familiaris' as organism")
    print("4. Run 'Statistical overrepresentation test'")
    print("5. Select these annotations:")
    print("   - GO biological process complete")
    print("   - GO molecular function complete")
    print("   - GO cellular component complete")
    print("   - PANTHER Pathways")
    print("   - Reactome pathways")
    print("6. Use Benjamini-Hochberg FDR correction")
    print("7. Download results as TSV")
    print("8. Save as: enrichment_results_PANTHER.tsv")
    print()

    print("="*80)
    print("EXPECTED ENRICHMENTS (Based on Domestication Syndrome)")
    print("="*80)
    print()
    print("Biological Process (GO:BP):")
    print("  • Nervous system development")
    print("  • Behavior and social cognition")
    print("  • Neurotransmitter signaling")
    print("  • Stress response pathways")
    print("  • Metabolic processes")
    print()
    print("Molecular Function (GO:MF):")
    print("  • Receptor binding")
    print("  • Signal transduction")
    print("  • Transcription factor activity")
    print()
    print("Pathways (KEGG/Reactome):")
    print("  • Insulin signaling")
    print("  • MAPK signaling")
    print("  • Neuroactive ligand-receptor interaction")
    print("  • Melanogenesis (coat color)")
    print()

    print("="*80)
    print("FILES CREATED")
    print("="*80)
    print()
    print(f"Gene lists for enrichment tools:")
    print(f"  • {symbol_file}")
    print(f"  • {id_file}")
    print(f"  • {combined_file}")
    print()
    print("Use these files with PANTHER, g:Profiler, or DAVID")
    print()

    print("="*80)
    print("NEXT STEPS")
    print("="*80)
    print()
    print("1. Run PANTHER enrichment (recommended)")
    print("2. Save results as enrichment_results_PANTHER.tsv")
    print("3. Create enrichment figures for manuscript")
    print("4. Add top 10-20 terms to Results section")
    print("5. Include full table in Supplementary")
    print()

if __name__ == '__main__':
    main()
