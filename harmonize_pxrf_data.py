#!/usr/bin/env python3
"""
pXRF Data Harmonization Script
Combines multiple CSV files from a directory into a single harmonized dataframe
"""

import pandas as pd
import os
from pathlib import Path
import sys

def harmonize_pxrf_data(directory_path, output_file='harmonized_pxrf_data.csv'):
    """
    Read all CSV files from directory and combine into one dataframe

    Args:
        directory_path: Path to directory containing CSV files
        output_file: Name of output file (default: harmonized_pxrf_data.csv)
    """

    # Convert to Path object
    data_dir = Path(directory_path)

    if not data_dir.exists():
        print(f"Error: Directory '{directory_path}' does not exist!")
        sys.exit(1)

    # Find all CSV files
    csv_files = list(data_dir.glob('*.csv'))

    if not csv_files:
        print(f"Error: No CSV files found in '{directory_path}'")
        sys.exit(1)

    print(f"Found {len(csv_files)} CSV files:")
    for f in csv_files:
        print(f"  - {f.name}")

    # Read and combine all CSV files
    dataframes = []

    for csv_file in csv_files:
        try:
            print(f"\nReading {csv_file.name}...")
            df = pd.read_csv(csv_file)

            # Add source file column to track origin
            df['source_file'] = csv_file.name

            print(f"  Shape: {df.shape}")
            print(f"  Columns: {list(df.columns)}")

            dataframes.append(df)

        except Exception as e:
            print(f"  Warning: Could not read {csv_file.name}: {e}")
            continue

    if not dataframes:
        print("Error: No CSV files could be read successfully!")
        sys.exit(1)

    # Combine all dataframes
    print("\n" + "="*60)
    print("Combining dataframes...")

    # Concatenate all dataframes
    combined_df = pd.concat(dataframes, ignore_index=True)

    print(f"\nCombined dataframe shape: {combined_df.shape}")
    print(f"Total rows: {len(combined_df)}")
    print(f"Total columns: {len(combined_df.columns)}")
    print(f"\nColumns in combined dataframe:")
    for col in combined_df.columns:
        print(f"  - {col}")

    # Save to output file
    output_path = data_dir / output_file
    combined_df.to_csv(output_path, index=False)

    print(f"\n" + "="*60)
    print(f"SUCCESS! Harmonized data saved to:")
    print(f"  {output_path}")
    print(f"\nSummary:")
    print(f"  - Input files: {len(csv_files)}")
    print(f"  - Total rows: {len(combined_df)}")
    print(f"  - Total columns: {len(combined_df.columns)}")

    # Show first few rows
    print(f"\nFirst 5 rows of combined data:")
    print(combined_df.head())

    return combined_df


if __name__ == "__main__":
    # Default path - user can modify this or pass as command line argument
    default_path = "/Users/isaac/Library/CloudStorage/Box-Box/2_academics/Projects/Fossil Spec/Museums"

    if len(sys.argv) > 1:
        directory_path = sys.argv[1]
    else:
        directory_path = default_path

    print("="*60)
    print("pXRF Data Harmonization Tool")
    print("="*60)
    print(f"\nProcessing directory: {directory_path}\n")

    harmonize_pxrf_data(directory_path)
