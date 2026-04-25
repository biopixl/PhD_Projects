#!/usr/bin/env python3
"""
Parse KETEK EXPERT XRF data files (.prf and .RSP)
Extract element concentrations and raw spectrum data
"""

import os
import re
import struct
import pandas as pd
from pathlib import Path
from glob import glob

# Base directory for XRF data
XRF_BASE = "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Ashes-EDXRF/EXPERT_ENG/WrkExpert/W187U/WORK/Aguilar_Isaac"

def parse_prf_file(filepath):
    """
    Parse a .prf file to extract element concentrations.
    Returns a dict with sample info and element data.
    """
    data = {
        'filepath': filepath,
        'sample_name': Path(filepath).stem,
        'elements': {}
    }

    try:
        with open(filepath, 'r', encoding='iso-8859-1') as f:
            content = f.read()

        # Extract comment/sample ID if present
        comment_match = re.search(r'Comment:(.+)', content)
        if comment_match:
            data['comment'] = comment_match.group(1).strip()

        # Extract measurement conditions
        time_match = re.search(r'Time\|Live time:\s*([\d.]+)\s*\|\s*([\d.]+)\s*s', content)
        if time_match:
            data['meas_time'] = float(time_match.group(1))
            data['live_time'] = float(time_match.group(2))

        # Parse element results section
        # Match patterns like: "12Mg      1.040±0.139" or "82Pb      ppm 265±8"
        element_pattern = r'(\d+)([A-Za-z]+)\s+(ppm\s+)?([\d.]+)[±�]([\d.]+)'

        for match in re.finditer(element_pattern, content):
            atomic_num = int(match.group(1))
            element_sym = match.group(2)
            is_ppm = match.group(3) is not None
            value = float(match.group(4))
            error = float(match.group(5))

            # Convert to consistent units (mass fraction %)
            if is_ppm:
                value_pct = value / 10000  # ppm to %
                error_pct = error / 10000
            else:
                value_pct = value
                error_pct = error

            data['elements'][element_sym] = {
                'Z': atomic_num,
                'value_pct': value_pct,
                'value_ppm': value if is_ppm else value * 10000,
                'error': error_pct,
                'unit': 'ppm' if is_ppm else '%'
            }

    except Exception as e:
        print(f"Error parsing {filepath}: {e}")

    return data


def parse_rsp_header(filepath):
    """
    Attempt to parse .RSP binary spectrum file header.
    Extract calibration info and spectrum dimensions.
    """
    info = {'filepath': filepath}

    try:
        with open(filepath, 'rb') as f:
            raw = f.read(2000)  # Read header portion

        # Look for calibration file references
        cal_matches = re.findall(rb'W187U\\Calibr\\([^\\]+\.cal)', raw)
        if cal_matches:
            info['calibration_files'] = [m.decode('ascii', errors='ignore') for m in cal_matches]

        # The spectrum data appears to follow the header
        # KETEK EXPERT typically uses 2048 or 4096 channels
        # Each channel is typically a 4-byte integer or 2-byte integer

        info['file_size'] = os.path.getsize(filepath)

    except Exception as e:
        info['error'] = str(e)

    return info


def parse_rsp_spectrum(filepath):
    """
    Parse .RSP binary file to extract spectrum data.
    This is a reverse-engineered format - may need adjustment.
    """
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()

        # Find the start of spectrum data
        # The file appears to have two spectra (46kV and 17kV conditions)
        # Look for patterns that might indicate start of spectrum

        file_size = len(raw)

        # Typical spectrum file structure:
        # - Header with calibration info
        # - Spectrum 1 (e.g., 2048 channels x 4 bytes = 8192 bytes)
        # - Spectrum 2 (similar)

        # Try to find reasonable spectrum boundaries
        # The numbers in the visible portion suggest 16-bit or 32-bit integers

        result = {
            'filepath': filepath,
            'file_size': file_size,
            'spectra': []
        }

        # Attempt to extract 16-bit integer arrays
        # Skip initial header (first ~100 bytes seem to be metadata)
        header_size = 100
        data_portion = raw[header_size:]

        # Try reading as unsigned 16-bit integers
        n_channels = len(data_portion) // 2
        if n_channels > 0:
            channels = struct.unpack(f'<{n_channels}H', data_portion[:n_channels*2])
            result['channel_data_16bit'] = list(channels[:2048])  # First 2048 channels

        return result

    except Exception as e:
        return {'error': str(e)}


def find_ash_samples():
    """Find all ash pellet sample files."""
    prf_files = glob(os.path.join(XRF_BASE, "**/*.prf"), recursive=True)

    # Filter for ash pellet samples
    ash_files = [f for f in prf_files if 'ash' in f.lower() or 'JPL' in f or 'XPAH' in f or 'GPS' in f]

    return ash_files


def extract_all_fp_concentrations():
    """
    Extract FP concentrations from all ash sample .prf files.
    Returns a DataFrame with all elements.
    """
    prf_files = find_ash_samples()
    print(f"Found {len(prf_files)} ash sample .prf files")

    all_data = []
    all_elements = set()

    for prf_file in prf_files:
        data = parse_prf_file(prf_file)
        all_elements.update(data['elements'].keys())
        all_data.append(data)

    # Create DataFrame
    rows = []
    for data in all_data:
        row = {
            'sample': data['sample_name'],
            'filepath': data['filepath']
        }
        if 'comment' in data:
            row['comment'] = data['comment']

        for elem, values in data['elements'].items():
            row[f'{elem}_pct'] = values['value_pct']
            row[f'{elem}_ppm'] = values['value_ppm']
            row[f'{elem}_err'] = values['error']

        rows.append(row)

    df = pd.DataFrame(rows)
    return df


if __name__ == '__main__':
    print("="*60)
    print("KETEK EXPERT XRF Data Parser")
    print("="*60)

    # Parse all .prf files for FP concentrations
    print("\n1. Extracting FP concentrations from .prf files...")
    df = extract_all_fp_concentrations()

    # Save to CSV
    output_path = "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/xrf_fp_concentrations_all.csv"
    df.to_csv(output_path, index=False)
    print(f"   Saved {len(df)} samples to: {output_path}")

    # Show sample of elements found
    elem_cols = [c for c in df.columns if c.endswith('_ppm')]
    print(f"   Elements found: {len(elem_cols)}")
    print(f"   Elements: {', '.join(sorted([c.replace('_ppm','') for c in elem_cols]))}")

    # Try parsing an RSP file to understand format
    print("\n2. Analyzing .RSP binary format...")
    sample_rsp = glob(os.path.join(XRF_BASE, "**/*JPL51*.RSP"), recursive=True)
    if sample_rsp:
        rsp_info = parse_rsp_header(sample_rsp[0])
        print(f"   Sample RSP file: {sample_rsp[0]}")
        print(f"   File size: {rsp_info.get('file_size', 'N/A')} bytes")
        if 'calibration_files' in rsp_info:
            print(f"   Calibration files: {rsp_info['calibration_files']}")

    print("\n" + "="*60)
    print("NOTE: Raw counts (intensities) are in binary .RSP files")
    print("To extract raw counts, you need to either:")
    print("  1. Run KETEK EXPERT software via Wine or Windows VM")
    print("  2. Reverse-engineer the .RSP binary format")
    print("="*60)
