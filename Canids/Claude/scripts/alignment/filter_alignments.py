#!/usr/bin/env python3
"""
filter_alignments.py
Filter and trim codon alignments for quality control
"""

import argparse
import os
from pathlib import Path
from Bio import AlignIO
from Bio.Align import MultipleSeqAlignment
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq
import numpy as np

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Filter codon alignments for quality'
    )
    parser.add_argument(
        '--input',
        type=str,
        required=True,
        help='Directory containing codon alignments'
    )
    parser.add_argument(
        '--output',
        type=str,
        required=True,
        help='Output directory for filtered alignments'
    )
    parser.add_argument(
        '--max_gap_fraction',
        type=float,
        default=0.5,
        help='Maximum fraction of gaps allowed per sequence (default: 0.5)'
    )
    parser.add_argument(
        '--min_species',
        type=int,
        default=4,
        help='Minimum number of species required (default: 4)'
    )
    parser.add_argument(
        '--trim_edges',
        action='store_true',
        help='Trim poorly aligned edges using automated trimming'
    )
    parser.add_argument(
        '--min_alignment_length',
        type=int,
        default=150,
        help='Minimum alignment length in bp after trimming (default: 150)'
    )
    return parser.parse_args()

def calculate_gap_fraction(sequence):
    """Calculate fraction of gaps in a sequence"""
    gaps = sequence.count('-') + sequence.count('N')
    return gaps / len(sequence) if len(sequence) > 0 else 1.0

def trim_alignment_edges(alignment, gap_threshold=0.8):
    """
    Trim poorly aligned edges where >gap_threshold positions are gaps
    """
    alignment_array = np.array([list(str(rec.seq)) for rec in alignment])

    # Calculate gap fraction per column
    n_seqs = len(alignment)
    gap_fractions = np.array([
        np.sum((alignment_array[:, i] == '-') | (alignment_array[:, i] == 'N')) / n_seqs
        for i in range(alignment_array.shape[1])
    ])

    # Find first and last positions with acceptable gap content
    good_positions = np.where(gap_fractions < gap_threshold)[0]

    if len(good_positions) == 0:
        return None  # Entire alignment is too gappy

    start = good_positions[0]
    end = good_positions[-1] + 1

    # Trim alignment
    trimmed_records = []
    for record in alignment:
        trimmed_seq = record.seq[start:end]
        trimmed_records.append(
            SeqRecord(trimmed_seq, id=record.id, description=record.description)
        )

    return MultipleSeqAlignment(trimmed_records)

def filter_alignment(alignment, max_gap_fraction, min_species):
    """
    Filter sequences with too many gaps
    """
    filtered_records = []

    for record in alignment:
        gap_frac = calculate_gap_fraction(str(record.seq))

        if gap_frac <= max_gap_fraction:
            filtered_records.append(record)
        else:
            print(f"  Removing {record.id} (gap fraction: {gap_frac:.2f})")

    if len(filtered_records) < min_species:
        return None

    return MultipleSeqAlignment(filtered_records)

def validate_codon_alignment(alignment):
    """
    Check if alignment is valid (length divisible by 3, no stop codons except at end)
    """
    aln_length = alignment.get_alignment_length()

    # Check divisible by 3
    if aln_length % 3 != 0:
        print(f"  WARNING: Alignment length {aln_length} not divisible by 3")
        return False

    # Check for internal stop codons
    for record in alignment:
        seq_str = str(record.seq).replace('-', '')
        if len(seq_str) % 3 != 0:
            continue

        try:
            protein = Seq(seq_str).translate(to_stop=False)
            if '*' in str(protein)[:-1]:  # Stop codons except at end
                print(f"  WARNING: Internal stop codon in {record.id}")
                return False
        except Exception as e:
            print(f"  WARNING: Translation error in {record.id}: {e}")
            return False

    return True

def process_alignment_file(input_file, output_dir, args):
    """
    Process a single alignment file
    """
    gene_name = input_file.stem.replace('.codon', '')

    try:
        alignment = AlignIO.read(input_file, 'fasta')
    except Exception as e:
        print(f"  ERROR reading {gene_name}: {e}")
        return False

    original_length = alignment.get_alignment_length()
    original_n_seqs = len(alignment)

    print(f"  Original: {original_n_seqs} sequences, {original_length} bp")

    # Step 1: Trim edges if requested
    if args.trim_edges:
        alignment = trim_alignment_edges(alignment)
        if alignment is None:
            print(f"  FILTERED: Too gappy after edge trimming")
            return False
        print(f"  After trimming: {alignment.get_alignment_length()} bp")

    # Step 2: Filter gappy sequences
    alignment = filter_alignment(alignment, args.max_gap_fraction, args.min_species)
    if alignment is None:
        print(f"  FILTERED: Too few sequences after gap filtering")
        return False

    # Step 3: Check minimum length
    if alignment.get_alignment_length() < args.min_alignment_length:
        print(f"  FILTERED: Alignment too short ({alignment.get_alignment_length()} bp)")
        return False

    # Step 4: Validate codon alignment
    if not validate_codon_alignment(alignment):
        print(f"  FILTERED: Invalid codon alignment")
        return False

    # Save filtered alignment
    output_file = output_dir / f"{gene_name}.filtered.fa"
    AlignIO.write(alignment, output_file, 'fasta')

    final_length = alignment.get_alignment_length()
    final_n_seqs = len(alignment)

    print(f"  Final: {final_n_seqs} sequences, {final_length} bp")
    print(f"  Saved: {output_file}")

    return True

def main():
    args = parse_arguments()

    input_dir = Path(args.input)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find all codon alignment files
    alignment_files = list(input_dir.glob('*.codon.fa')) + \
                     list(input_dir.glob('*.fa'))

    if not alignment_files:
        print(f"ERROR: No alignment files found in {input_dir}")
        return

    print(f"Found {len(alignment_files)} alignments to filter")
    print(f"Parameters:")
    print(f"  Max gap fraction: {args.max_gap_fraction}")
    print(f"  Min species: {args.min_species}")
    print(f"  Min length: {args.min_alignment_length} bp")
    print(f"  Trim edges: {args.trim_edges}")
    print()

    passed = 0
    failed = 0

    for i, aln_file in enumerate(alignment_files, 1):
        print(f"[{i}/{len(alignment_files)}] Processing {aln_file.stem}")

        if process_alignment_file(aln_file, output_dir, args):
            passed += 1
        else:
            failed += 1

        print()

    print("=== Summary ===")
    print(f"Passed filter: {passed}")
    print(f"Failed filter: {failed}")
    print(f"Output directory: {output_dir}")

if __name__ == '__main__':
    main()
