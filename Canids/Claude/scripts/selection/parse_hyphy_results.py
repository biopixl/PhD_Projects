#!/usr/bin/env python3
"""
parse_hyphy_results.py
Parse HyPhy JSON output from aBSREL, BUSTED, RELAX, etc.
"""

import argparse
import json
from pathlib import Path
import pandas as pd
import sys

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Parse HyPhy JSON results'
    )
    parser.add_argument(
        '--input',
        type=str,
        required=True,
        help='Directory containing HyPhy JSON output files'
    )
    parser.add_argument(
        '--output',
        type=str,
        required=True,
        help='Output CSV file for parsed results'
    )
    parser.add_argument(
        '--test',
        type=str,
        choices=['absrel', 'busted', 'relax', 'meme', 'fel'],
        required=True,
        help='Type of HyPhy test'
    )
    return parser.parse_args()

def parse_absrel(json_file):
    """Parse aBSREL output"""
    try:
        with open(json_file) as f:
            data = json.load(f)

        results = []

        # Branch-level results
        if 'branch attributes' in data:
            for branch_name, branch_data in data['branch attributes'].items():
                if 'tested' in data and data['tested'].get(branch_name, 0) > 0:
                    result = {
                        'branch': branch_name,
                        'pvalue': branch_data.get('Corrected P-value', 1.0),
                        'uncorrected_pvalue': branch_data.get('original name', {}).get('P-value', 1.0),
                        'omega': branch_data.get('Rate classes', {}).get('omega', 'NA')
                    }
                    results.append(result)

        # Get test result
        test_results = data.get('test results', {})
        overall_pvalue = test_results.get('p-value', 1.0)

        return {
            'gene': Path(json_file).stem,
            'pvalue': overall_pvalue,
            'n_branches_tested': len(results),
            'n_significant': sum(1 for r in results if r['pvalue'] < 0.05),
            'branch_results': results
        }

    except Exception as e:
        print(f"Error parsing {json_file}: {e}", file=sys.stderr)
        return None

def parse_busted(json_file):
    """Parse BUSTED output"""
    try:
        with open(json_file) as f:
            data = json.load(f)

        test_results = data.get('test results', {})

        return {
            'gene': Path(json_file).stem,
            'pvalue': test_results.get('p-value', 1.0),
            'LRT': test_results.get('LRT', 'NA'),
            'evidence_of_selection': test_results.get('p-value', 1.0) < 0.05,
            'background_omega': data.get('fits', {}).get('Unconstrained model', {}).get('Rate Distributions', {}).get('background', 'NA'),
            'test_omega': data.get('fits', {}).get('Unconstrained model', {}).get('Rate Distributions', {}).get('test', 'NA')
        }

    except Exception as e:
        print(f"Error parsing {json_file}: {e}", file=sys.stderr)
        return None

def parse_relax(json_file):
    """Parse RELAX output"""
    try:
        with open(json_file) as f:
            data = json.load(f)

        test_results = data.get('test results', {})

        k_value = test_results.get('relaxation or intensification parameter', 'NA')

        # Interpretation
        if k_value != 'NA':
            if k_value > 1:
                interpretation = 'intensified'
            elif k_value < 1:
                interpretation = 'relaxed'
            else:
                interpretation = 'neutral'
        else:
            interpretation = 'unknown'

        return {
            'gene': Path(json_file).stem,
            'pvalue': test_results.get('p-value', 1.0),
            'LRT': test_results.get('LRT', 'NA'),
            'k_value': k_value,
            'interpretation': interpretation,
            'significant': test_results.get('p-value', 1.0) < 0.05
        }

    except Exception as e:
        print(f"Error parsing {json_file}: {e}", file=sys.stderr)
        return None

def parse_meme(json_file):
    """Parse MEME output (site-level episodic selection)"""
    try:
        with open(json_file) as f:
            data = json.load(f)

        # Count sites under selection
        sites = data.get('MLE', {}).get('content', {})
        significant_sites = 0

        for site_data in sites.values():
            if isinstance(site_data, dict):
                pvalue = site_data.get('p-value', 1.0)
                if pvalue < 0.05:
                    significant_sites += 1

        return {
            'gene': Path(json_file).stem,
            'n_sites_tested': len(sites),
            'n_significant_sites': significant_sites,
            'proportion_selected': significant_sites / len(sites) if len(sites) > 0 else 0
        }

    except Exception as e:
        print(f"Error parsing {json_file}: {e}", file=sys.stderr)
        return None

def parse_fel(json_file):
    """Parse FEL output (site-level pervasive selection)"""
    try:
        with open(json_file) as f:
            data = json.load(f)

        mle_data = data.get('MLE', {}).get('content', {})

        positive_sites = 0
        negative_sites = 0

        for site_data in mle_data.values():
            if isinstance(site_data, dict):
                alpha = site_data.get('alpha', 0)
                beta = site_data.get('beta', 0)

                if beta > alpha and site_data.get('p-value', 1.0) < 0.05:
                    positive_sites += 1
                elif alpha > beta and site_data.get('p-value', 1.0) < 0.05:
                    negative_sites += 1

        return {
            'gene': Path(json_file).stem,
            'n_sites': len(mle_data),
            'positive_selection_sites': positive_sites,
            'negative_selection_sites': negative_sites
        }

    except Exception as e:
        print(f"Error parsing {json_file}: {e}", file=sys.stderr)
        return None

def main():
    args = parse_arguments()

    input_dir = Path(args.input)

    # Find JSON files
    json_files = list(input_dir.glob('*.json'))

    if not json_files:
        print(f"ERROR: No JSON files found in {input_dir}")
        sys.exit(1)

    print(f"Found {len(json_files)} JSON files")
    print(f"Test type: {args.test}")
    print()

    # Select parser based on test type
    parser_map = {
        'absrel': parse_absrel,
        'busted': parse_busted,
        'relax': parse_relax,
        'meme': parse_meme,
        'fel': parse_fel
    }

    parser_func = parser_map[args.test]

    # Parse all files
    results = []
    failed = 0

    for i, json_file in enumerate(json_files, 1):
        print(f"[{i}/{len(json_files)}] Parsing {json_file.name}...")

        result = parser_func(json_file)

        if result is not None:
            results.append(result)
        else:
            failed += 1

    # Convert to DataFrame
    if results:
        df = pd.DataFrame(results)

        # Save to CSV
        output_dir = Path(args.output).parent
        output_dir.mkdir(parents=True, exist_ok=True)

        df.to_csv(args.output, index=False)

        print()
        print("=== Summary ===")
        print(f"Successfully parsed: {len(results)}")
        print(f"Failed: {failed}")
        print(f"Output saved: {args.output}")

        # Print quick stats
        if 'pvalue' in df.columns:
            n_sig = (df['pvalue'] < 0.05).sum()
            print(f"\nSignificant results (p < 0.05): {n_sig} / {len(df)} ({100*n_sig/len(df):.1f}%)")

    else:
        print("ERROR: No results parsed successfully")
        sys.exit(1)

if __name__ == '__main__':
    main()
