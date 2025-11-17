#!/usr/bin/env python3
"""
extract_cds_biomart.py
Extract orthologous CDS sequences from BioMart ortholog table

This version is specifically designed for Ensembl BioMart output format
"""

import argparse
import os
import sys
from pathlib import Path
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
import pandas as pd
from collections import defaultdict

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Extract orthologous CDS from BioMart table'
    )
    parser.add_argument(
        '--orthologs',
        type=str,
        required=True,
        help='BioMart ortholog table (TSV format)'
    )
    parser.add_argument(
        '--cds_dir',
        type=str,
        required=True,
        help='Directory containing CDS FASTA files'
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
        default=2,
        help='Minimum number of species required per ortholog group'
    )
    return parser.parse_args()

def load_cds_sequences(cds_dir):
    """Load all CDS sequences into memory indexed by various ID formats"""
    cds_db = defaultdict(dict)

    cds_files = list(Path(cds_dir).glob('*.cds.fa')) + \
                list(Path(cds_dir).glob('*.fa'))

    if not cds_files:
        print(f"ERROR: No CDS files found in {cds_dir}")
        sys.exit(1)

    print(f"Loading CDS sequences from {len(cds_files)} files...")

    for cds_file in cds_files:
        # Extract species name from filename
        species = cds_file.stem.replace('.cds', '')

        print(f"  Loading {species}...")
        count = 0

        for record in SeqIO.parse(cds_file, 'fasta'):
            # Store by multiple ID formats
            # NCBI: lcl|NC_051806.1_cds_XP_038283495.1_1
            # Ensembl: ENSCAFT00000000001.1
            full_id = record.id
            base_id = record.id.split('.')[0]  # Remove version

            # Store multiple ways for flexible matching
            cds_db[species][full_id] = record
            cds_db[species][base_id] = record

            # If it's an NCBI ID, also store the protein ID part
            if '|' in record.id:
                parts = record.id.split('|')
                for part in parts:
                    if part.startswith('XP_') or part.startswith('NP_'):
                        cds_db[species][part.split('.')[0]] = record

            # For Ensembl: parse gene ID from description
            # Header format: >ENSCAFT00845000002.1 cds ... gene:ENSCAFG00845000001.1 ...
            if 'gene:' in record.description:
                gene_field = record.description.split('gene:')[1].split()[0]
                gene_id = gene_field.split('.')[0]  # Remove version
                cds_db[species][gene_id] = record
                cds_db[species][gene_field] = record  # Also store with version

            # For Ensembl: convert transcript IDs to potential protein IDs
            # ENSCAFT (transcript) might map to ENSCAFP (protein)
            # ENSVVUT (transcript) might map to ENSVVUP (protein)
            if 'T00' in base_id:
                protein_id = base_id.replace('T00', 'P00')
                cds_db[species][protein_id] = record

            count += 1

        print(f"    Loaded {count} sequences")

    return cds_db

def extract_orthologs_biomart(biomart_table, cds_db, args):
    """Extract orthologous sequences from BioMart format"""

    print(f"\nReading BioMart ortholog table: {args.orthologs}")
    df = pd.read_csv(biomart_table, sep='\t', low_memory=False)

    print(f"Table shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")

    # Column names from actual BioMart download
    dog_gene_col = 'Gene stable ID'
    dog_transcript_col = 'Transcript stable ID'
    dog_protein_col = 'Query protein or transcript ID'  # Column 15 or 19
    redfox_gene_col = 'Red fox gene stable ID'  # Use gene ID for matching
    redfox_protein_col = 'Red fox protein or transcript stable ID'
    dingo_gene_col = 'Dingo gene stable ID'
    dingo_protein_col = 'Dingo protein or transcript stable ID'

    # Group by dog gene
    gene_groups = df.groupby(dog_gene_col)
    print(f"\nFound {len(gene_groups)} gene groups")

    extracted = 0
    skipped_few_species = 0
    skipped_missing_seqs = 0

    for gene_id, group in gene_groups:
        if pd.isna(gene_id) or gene_id == '':
            continue

        # Use gene ID for naming - use full numeric ID to avoid collisions
        gene_name = f"Gene_{gene_id.split('G')[-1]}"

        # Collect sequences for this gene
        sequences = []
        species_found = set()

        # Get dog sequence - try different ID columns
        dog_ids_to_try = []

        # Try Query protein ID (most specific)
        if dog_protein_col in group.columns:
            dog_ids_to_try.extend(group[dog_protein_col].dropna().unique())

        # Try Transcript ID
        if dog_transcript_col in group.columns:
            dog_ids_to_try.extend(group[dog_transcript_col].dropna().unique())

        # Try Gene ID
        dog_ids_to_try.append(gene_id)

        # Try to find dog sequence
        for seq_id in dog_ids_to_try:
            if pd.isna(seq_id) or seq_id == '':
                continue

            seq_id_clean = str(seq_id).split('.')[0]

            if 'Canis_familiaris' in cds_db and seq_id_clean in cds_db['Canis_familiaris']:
                record = cds_db['Canis_familiaris'][seq_id_clean]
                new_record = SeqRecord(
                    record.seq,
                    id="Canis_familiaris",
                    description=f"{gene_name} | {seq_id}"
                )
                sequences.append(new_record)
                species_found.add('Canis_familiaris')
                break

        # Get Red fox ortholog
        # Try gene ID first (most reliable), then protein ID
        redfox_ids_to_try = []

        if redfox_gene_col in group.columns:
            redfox_ids_to_try.extend(group[redfox_gene_col].dropna().unique())

        if redfox_protein_col in group.columns:
            redfox_ids_to_try.extend(group[redfox_protein_col].dropna().unique())

        for ortholog_id in redfox_ids_to_try:
            if pd.isna(ortholog_id) or ortholog_id == '':
                continue

            ortholog_id_clean = str(ortholog_id).split('.')[0]

            if 'Vulpes_vulpes' in cds_db and ortholog_id_clean in cds_db['Vulpes_vulpes']:
                record = cds_db['Vulpes_vulpes'][ortholog_id_clean]
                new_record = SeqRecord(
                    record.seq,
                    id="Vulpes_vulpes",
                    description=f"{gene_name} | {ortholog_id}"
                )
                sequences.append(new_record)
                species_found.add('Vulpes_vulpes')
                break

        # Get Dingo ortholog (maps to Canis_familiaris CDS)
        if dingo_protein_col in group.columns:
            ortholog_ids = group[dingo_protein_col].dropna().unique()

            for ortholog_id in ortholog_ids:
                if pd.isna(ortholog_id) or ortholog_id == '':
                    continue

                ortholog_id_clean = str(ortholog_id).split('.')[0]

                # Dingo uses Canis_familiaris genome, so look there
                if 'Canis_familiaris' in cds_db and ortholog_id_clean in cds_db['Canis_familiaris']:
                    # Only add if we don't already have a dog sequence
                    if 'Canis_familiaris' not in species_found:
                        record = cds_db['Canis_familiaris'][ortholog_id_clean]
                        new_record = SeqRecord(
                            record.seq,
                            id="Canis_familiaris",
                            description=f"{gene_name} | {ortholog_id} (Dingo)"
                        )
                        sequences.append(new_record)
                        species_found.add('Canis_familiaris')
                    break

        # Only save if we have minimum species
        if len(sequences) >= args.min_species:
            # Create output directory
            gene_dir = Path(args.out) / gene_name
            gene_dir.mkdir(parents=True, exist_ok=True)

            # Save CDS sequences
            cds_output = gene_dir / f"{gene_name}.cds.fa"
            SeqIO.write(sequences, cds_output, 'fasta')

            # Translate to protein
            protein_seqs = []
            for seq_rec in sequences:
                try:
                    protein_seq = seq_rec.seq.translate(to_stop=True)
                    protein_rec = SeqRecord(
                        protein_seq,
                        id=seq_rec.id,
                        description=seq_rec.description
                    )
                    protein_seqs.append(protein_rec)
                except Exception as e:
                    print(f"  Warning: Could not translate {seq_rec.id}: {e}")

            if len(protein_seqs) >= args.min_species:
                protein_output = gene_dir / f"{gene_name}.protein.fa"
                SeqIO.write(protein_seqs, protein_output, 'fasta')
                extracted += 1

                if extracted % 100 == 0:
                    print(f"  Extracted {extracted} ortholog groups...")
            else:
                skipped_missing_seqs += 1
        else:
            if len(sequences) > 0:
                skipped_few_species += 1
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

    print(f"\nAvailable species in CDS database:")
    for species in cds_db.keys():
        print(f"  - {species}: {len(cds_db[species])} sequences")

    # Extract orthologs
    extract_orthologs_biomart(args.orthologs, cds_db, args)

    print("\nDone!")

if __name__ == '__main__':
    main()
