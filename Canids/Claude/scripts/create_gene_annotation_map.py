#!/usr/bin/env python3
"""
Create gene annotation map from Ensembl CDS files
"""

from Bio import SeqIO
import json
import gzip
from pathlib import Path

def parse_ensembl_header(description):
    """Extract gene symbol and description from Ensembl header"""
    info = {}

    if 'gene:' in description:
        gene_id = description.split('gene:')[1].split()[0].split('.')[0]
        info['gene_id'] = gene_id

    if 'gene_symbol:' in description:
        symbol = description.split('gene_symbol:')[1].split()[0]
        info['symbol'] = symbol

    if 'description:' in description:
        desc = description.split('description:')[1].split('[Source')[0].strip()
        info['description'] = desc

    if 'transcript:' in description:
        transcript_id = description.split('transcript:')[1].split()[0].split('.')[0]
        info['transcript_id'] = transcript_id

    return info

def main():
    # Parse dog CDS
    print("Parsing Canis familiaris CDS...")
    dog_cds = Path('data/cds/Canis_familiaris.cds.fa')

    gene_map = {}

    with open(dog_cds, 'r') as handle:
        for record in SeqIO.parse(handle, 'fasta'):
            info = parse_ensembl_header(record.description)

            if 'gene_id' in info:
                gene_id = info['gene_id']

                # Create gene name as used in directories
                gene_name = f"Gene_{gene_id.split('G')[-1]}"

                if gene_name not in gene_map:
                    gene_map[gene_name] = {
                        'gene_id': gene_id,
                        'symbol': info.get('symbol', 'Unknown'),
                        'description': info.get('description', 'No description'),
                        'transcripts': []
                    }

                if 'transcript_id' in info:
                    gene_map[gene_name]['transcripts'].append(info['transcript_id'])

    print(f"Mapped {len(gene_map)} genes")

    # Save to JSON
    output_file = 'data/gene_annotations.json'
    with open(output_file, 'w') as f:
        json.dump(gene_map, f, indent=2)

    print(f"Saved annotations to: {output_file}")

    # Show sample
    print("\nSample annotations:")
    for gene_name in list(gene_map.keys())[:5]:
        info = gene_map[gene_name]
        print(f"  {gene_name}: {info['symbol']} - {info['description'][:50]}")

if __name__ == '__main__':
    main()
