#!/usr/bin/env python3
"""
extract_cds.py
Extract orthologous CDS sequences from genome annotations based on Ensembl Compara output
"""

import argparse
import os
import sys
from pathlib import Path
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import pandas as pd
from collections import defaultdict

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Extract orthologous CDS sequences for phylogenomic analysis'
    )
    parser.add_argument(
        '--orthologs',
        type=str,
        required=True,
        help='Ortholog table from Ensembl Compara (TSV format)'
    )
    parser.add_argument(
        '--cds_dir',
        type=str,
        required=True,
        help='Directory containing CDS FASTA files (Species_name.cds.fa)'
    )
    parser.add_argument(
        '--out',
        type=str,
        default='data/orthologs/',
        help='Output directory for ortholog groups'
    )
    parser.add_argument(
        '--min_species',
        type=int,
        default=4,
        help='Minimum number of species required per ortholog group'
    )
    parser.add_argument(
        '--id_col',
        type=str,
        default='transcript_id',
        help='Column name for transcript/gene IDs'
    )
    parser.add_argument(
        '--species_col',
        type=str,
        default='species',
        help='Column name for species'
    )
    parser.add_argument(
        '--gene_col',
        type=str,
        default='gene_name',
        help='Column name for gene name/symbol'
    )
    return parser.parse_args()

def load_cds_sequences(cds_dir):
    """Load all CDS sequences into memory indexed by transcript ID"""
    cds_db = defaultdict(dict)

    cds_files = list(Path(cds_dir).glob('*.cds.fa')) + \
                list(Path(cds_dir).glob('*.cds.fasta')) + \
                list(Path(cds_dir).glob('*.fa'))

    if not cds_files:
        print(f"ERROR: No CDS files found in {cds_dir}")
        print("Expected naming: Species_name.cds.fa")
        sys.exit(1)

    print(f"Loading CDS sequences from {len(cds_files)} files...")

    for cds_file in cds_files:
        # Extract species name from filename
        species = cds_file.stem.replace('.cds', '')

        print(f"  Loading {species}...")
        count = 0

        for record in SeqIO.parse(cds_file, 'fasta'):
            # Store by transcript ID
            # Handle different ID formats (Ensembl, NCBI, etc.)
            transcript_id = record.id.split('.')[0]  # Remove version numbers
            cds_db[species][transcript_id] = record
            count += 1

        print(f"    Loaded {count} sequences")

    return cds_db

def extract_orthologs(ortholog_table, cds_db, args):
    """Extract orthologous sequences and organize by gene family"""

    print(f"\nReading ortholog table: {args.orthologs}")
    df = pd.read_csv(ortholog_table, sep='\t')

    print(f"Ortholog table shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")

    # Check required columns
    required_cols = [args.id_col, args.species_col, args.gene_col]
    missing_cols = [col for col in required_cols if col not in df.columns]

    if missing_cols:
        print(f"\nERROR: Missing required columns: {missing_cols}")
        print(f"Available columns: {list(df.columns)}")
        print("\nPlease specify correct column names using --id_col, --species_col, --gene_col")
        sys.exit(1)

    # Group by gene name
    gene_groups = df.groupby(args.gene_col)

    print(f"\nFound {len(gene_groups)} ortholog groups")

    extracted = 0
    skipped_few_species = 0
    skipped_missing_seqs = 0

    for gene_name, group in gene_groups:
        if pd.isna(gene_name) or gene_name == '':
            continue

        # Check minimum species coverage
        n_species = group[args.species_col].nunique()
        if n_species < args.min_species:
            skipped_few_species += 1
            continue

        # Create output directory for this gene
        gene_dir = Path(args.out) / gene_name
        gene_dir.mkdir(parents=True, exist_ok=True)

        # Extract sequences
        sequences = []
        for _, row in group.iterrows():
            species = row[args.species_col]
            transcript_id = str(row[args.id_col]).split('.')[0]

            # Try to find sequence
            if species in cds_db and transcript_id in cds_db[species]:
                seq_record = cds_db[species][transcript_id]

                # Rename for clarity
                new_id = f"{species}"
                new_record = SeqRecord(
                    seq_record.seq,
                    id=new_id,
                    description=f"{gene_name} | {transcript_id}"
                )
                sequences.append(new_record)
            else:
                print(f"  Warning: Could not find {transcript_id} for {species} in {gene_name}")

        # Only save if we have enough sequences
        if len(sequences) >= args.min_species:
            # Save CDS sequences
            cds_output = gene_dir / f"{gene_name}.cds.fa"
            SeqIO.write(sequences, cds_output, 'fasta')

            # Also translate to protein for alignment
            protein_seqs = []
            for seq_rec in sequences:
                try:
                    # Translate CDS
                    protein_seq = seq_rec.seq.translate(to_stop=True)
                    protein_rec = SeqRecord(
                        protein_seq,
                        id=seq_rec.id,
                        description=seq_rec.description
                    )
                    protein_seqs.append(protein_rec)
                except Exception as e:
                    print(f"  Warning: Could not translate {seq_rec.id} in {gene_name}: {e}")

            if len(protein_seqs) >= args.min_species:
                protein_output = gene_dir / f"{gene_name}.protein.fa"
                SeqIO.write(protein_seqs, protein_output, 'fasta')
                extracted += 1

                if extracted % 100 == 0:
                    print(f"  Extracted {extracted} ortholog groups...")
            else:
                skipped_missing_seqs += 1
        else:
            skipped_missing_seqs += 1

    print(f"\n=== Summary ===")
    print(f"Successfully extracted: {extracted} ortholog groups")
    print(f"Skipped (too few species): {skipped_few_species}")
    print(f"Skipped (missing sequences): {skipped_missing_seqs}")
    print(f"\nOutput directory: {args.out}")

def main():
    args = parse_arguments()

    # Load all CDS sequences
    cds_db = load_cds_sequences(args.cds_dir)

    # Extract orthologs
    extract_orthologs(args.orthologs, cds_db, args)

    print("\nDone!")

if __name__ == '__main__':
    main()
