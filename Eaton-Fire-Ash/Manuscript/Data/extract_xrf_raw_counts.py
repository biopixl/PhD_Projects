#!/usr/bin/env python3
"""
Extract raw XRF counts (intensities) from KETEK EXPERT .RSP binary spectrum files.

This script decodes the proprietary .RSP binary format and extracts:
1. Full spectrum data (channel counts)
2. Peak intensities for specific emission lines
3. Integrated counts for each element

Binary format (decoded):
- Bytes 0-211: Header with calibration info
- Bytes 212-12495: Spectrum 1 (46 kV) - each channel is 4 bytes
- Bytes 12496-12571: Header 2 with 17kV calibration
- Bytes 12572-end: Spectrum 2 (17 kV)

NOTE: Two byte ordering variants exist:
- Type A (6-28_* samples): counts in bytes 1-2 as LE16
- Type B (other samples): counts in bytes 2-3 as LE16
The script auto-detects which format to use.

Author: Claude Code
Date: April 2026
"""

import os
import re
import struct
import numpy as np
import pandas as pd
from pathlib import Path
from glob import glob
from scipy.signal import find_peaks

# Base directory for XRF data
XRF_BASE = "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Ashes-EDXRF/EXPERT_ENG/WrkExpert/W187U/WORK/Aguilar_Isaac"

# Energy calibration parameters (derived from Fe Kα and Pb Lα peaks)
ENERGY_OFFSET = 0.7291  # keV
ENERGY_GAIN = 0.01885   # keV per channel

# Element emission line energies (keV) - from calibration file
ELEMENT_LINES = {
    # Light elements (K-lines)
    'Na': {'Ka': 1.041, 'Kb': 1.072},
    'Mg': {'Ka': 1.253, 'Kb': 1.303},
    'Al': {'Ka': 1.486, 'Kb': 1.559},
    'Si': {'Ka': 1.740, 'Kb': 1.838},
    'P':  {'Ka': 2.013, 'Kb': 2.142},
    'S':  {'Ka': 2.307, 'Kb': 2.470},
    'Cl': {'Ka': 2.622, 'Kb': 2.819},
    'K':  {'Ka': 3.313, 'Kb': 3.607},
    'Ca': {'Ka': 3.691, 'Kb': 4.038},
    'Ti': {'Ka': 4.510, 'Kb': 4.964},
    'V':  {'Ka': 4.952, 'Kb': 5.463},
    'Cr': {'Ka': 5.414, 'Kb': 5.988},
    'Mn': {'Ka': 5.898, 'Kb': 6.537},
    'Fe': {'Ka': 6.403, 'Kb': 7.111},
    'Co': {'Ka': 6.930, 'Kb': 7.709},
    'Ni': {'Ka': 7.478, 'Kb': 8.331},
    'Cu': {'Ka': 8.047, 'Kb': 8.980},
    'Zn': {'Ka': 8.638, 'Kb': 9.660},
    'Ga': {'Ka': 9.251, 'Kb': 10.368},
    'As': {'Ka': 10.543, 'Kb': 11.863},
    'Se': {'Ka': 11.222, 'Kb': 12.652},
    'Br': {'Ka': 11.924, 'Kb': 13.475},
    'Rb': {'Ka': 13.395, 'Kb': 15.201},
    'Sr': {'Ka': 14.165, 'Kb': 16.106},
    'Y':  {'Ka': 14.960, 'Kb': 17.037},
    'Zr': {'Ka': 15.775, 'Kb': 17.998},
    'Mo': {'Ka': 17.479, 'Kb': 20.002},
    'Ag': {'Ka': 22.163, 'Kb': 25.517},
    'Cd': {'Ka': 23.173, 'Kb': 26.712},
    'Sn': {'Ka': 25.271, 'Kb': 29.190},
    'Sb': {'Ka': 26.359, 'Kb': 30.486},
    'Ba': {'Ka': 32.193, 'Kb': 37.410},

    # Heavy elements (L-lines)
    'W':  {'La': 8.397, 'Lb': 10.198},
    'Au': {'La': 9.712, 'Lb': 11.919},
    'Hg': {'La': 9.988, 'Lb': 12.285},
    'Tl': {'La': 10.268, 'Lb': 12.657},
    'Pb': {'La': 10.550, 'Lb': 12.614},  # Using Lβ2 for better separation
    'Bi': {'La': 10.838, 'Lb': 13.424},
    'Th': {'La': 12.968, 'Lb': 16.296},
    'U':  {'La': 13.614, 'Lb': 17.163},
}


def energy_to_channel(energy_keV):
    """Convert energy (keV) to channel number."""
    return int((energy_keV - ENERGY_OFFSET) / ENERGY_GAIN)


def channel_to_energy(channel):
    """Convert channel number to energy (keV)."""
    return ENERGY_OFFSET + ENERGY_GAIN * channel


def detect_byte_order(raw_data, start_offset=212, end_offset=12496):
    """
    Auto-detect byte ordering in RSP file.

    Three variants exist:
    - Type A: counts in bytes 1-2 as LE16 (offset=1)
    - Type B: counts in bytes 2-3 as LE16 (offset=2)
    - Type C: counts in bytes 0-1 as LE16 (offset=0)

    Returns byte offset (0, 1, or 2) for count extraction.
    """
    # Try all three methods and compare totals
    sums = {}
    for offset in [0, 1, 2]:
        total = 0
        for i in range(start_offset, min(end_offset, len(raw_data) - 3), 4):
            total += struct.unpack('<H', raw_data[i+offset:i+offset+2])[0]
        sums[offset] = total

    # The correct offset will give the highest reasonable total
    # Correct reads typically give 100K to 100M counts
    # Pick the offset that gives highest total in reasonable range
    best_offset = max(sums.keys(), key=lambda x: sums[x] if sums[x] < 500_000_000 else 0)

    return best_offset


def extract_spectrum(raw_data, start_offset, end_offset, byte_offset=None):
    """
    Extract spectrum counts from RSP binary data.

    Format: Each channel is 4 bytes.
    - byte_offset=1: counts in bytes 1-2 as LE16 (Type A files)
    - byte_offset=2: counts in bytes 2-3 as LE16 (Type B files)

    If byte_offset is None, auto-detect.
    """
    if byte_offset is None:
        byte_offset = detect_byte_order(raw_data, start_offset, end_offset)

    spectrum = []
    for i in range(start_offset, min(end_offset, len(raw_data) - 3), 4):
        count = struct.unpack('<H', raw_data[i+byte_offset:i+byte_offset+2])[0]
        spectrum.append(count)
    return np.array(spectrum), byte_offset


def parse_rsp_file(filepath):
    """
    Parse an RSP binary file and extract spectrum data and element intensities.

    Returns a dict with:
    - spectrum1: numpy array of counts (46 kV conditions)
    - spectrum2: numpy array of counts (17 kV conditions)
    - element_counts: dict of element -> {'Ka': counts, 'Kb': counts} or {'La': counts, 'Lb': counts}
    """
    result = {
        'filepath': filepath,
        'sample_name': Path(filepath).stem,
        'spectrum1': None,
        'spectrum2': None,
        'element_counts': {}
    }

    try:
        with open(filepath, 'rb') as f:
            raw = f.read()

        result['file_size'] = len(raw)

        # Extract spectrum 1 (46 kV) - bytes 212 to 12496
        spec1_start = 212
        spec1_end = min(12496, len(raw))
        if spec1_end > spec1_start:
            result['spectrum1'], byte_offset = extract_spectrum(raw, spec1_start, spec1_end)
            result['total_counts_46kV'] = int(sum(result['spectrum1']))
            result['byte_offset'] = byte_offset  # Track which format was used

        # Extract spectrum 2 (17 kV) - bytes ~12572 to end
        # Use same byte offset as spectrum 1
        spec2_start = 12572
        spec2_end = len(raw)
        if spec2_end > spec2_start:
            result['spectrum2'], _ = extract_spectrum(raw, spec2_start, spec2_end, byte_offset)
            result['total_counts_17kV'] = int(sum(result['spectrum2']))

        # Get live time from corresponding .prf file if available
        prf_path = filepath.replace('.RSP', '.prf')
        live_time = 60.0  # Default
        if os.path.exists(prf_path):
            try:
                with open(prf_path, 'r', encoding='iso-8859-1') as f:
                    prf_content = f.read()
                time_match = re.search(r'Live time:\s*([\d.]+)\s*s', prf_content)
                if time_match:
                    live_time = float(time_match.group(1))
            except:
                pass
        result['live_time'] = live_time

        # Extract element intensities from spectrum 1 (46 kV covers most elements)
        if result['spectrum1'] is not None:
            spectrum = result['spectrum1']
            for element, lines in ELEMENT_LINES.items():
                element_counts = {}
                for line_name, energy in lines.items():
                    channel = energy_to_channel(energy)
                    # Peak value (single channel)
                    if 0 <= channel < len(spectrum):
                        peak_cts = int(spectrum[channel])
                    else:
                        peak_cts = 0

                    # Background estimate (50 channels below peak)
                    bkg_ch = max(0, channel - 50)
                    bkg_region = spectrum[max(0, bkg_ch-5):min(len(spectrum), bkg_ch+5)]
                    bkg_per_ch = np.mean(bkg_region) if len(bkg_region) > 0 else 0

                    # Net peak counts and cps
                    net_cts = max(0, peak_cts - bkg_per_ch)
                    peak_cps = peak_cts / live_time
                    net_cps = net_cts / live_time

                    element_counts[f'{line_name}_cts'] = peak_cts
                    element_counts[f'{line_name}_cps'] = round(peak_cps, 2)
                    element_counts[f'{line_name}_net_cps'] = round(net_cps, 2)
                result['element_counts'][element] = element_counts

    except Exception as e:
        result['error'] = str(e)

    return result


def find_ash_rsp_files():
    """Find all ash sample RSP files."""
    rsp_files = []

    # Search in ash_pellets subdirectory
    patterns = [
        os.path.join(XRF_BASE, "ash_pellets", "**", "*.RSP"),
        os.path.join(XRF_BASE, "**", "*JPL*.RSP"),
        os.path.join(XRF_BASE, "**", "*XPAH*.RSP"),
        os.path.join(XRF_BASE, "**", "*GPS*.RSP"),
        os.path.join(XRF_BASE, "**", "*ash*.RSP"),
    ]

    for pattern in patterns:
        rsp_files.extend(glob(pattern, recursive=True))

    # Remove duplicates while preserving order
    seen = set()
    unique_files = []
    for f in rsp_files:
        if f not in seen:
            seen.add(f)
            unique_files.append(f)

    return unique_files


def extract_all_raw_counts():
    """
    Extract raw counts for all elements from all ash sample RSP files.
    Returns a DataFrame with sample info and element intensities.
    """
    rsp_files = find_ash_rsp_files()
    print(f"Found {len(rsp_files)} ash sample .RSP files")

    all_data = []

    for rsp_file in rsp_files:
        data = parse_rsp_file(rsp_file)

        if 'error' in data:
            print(f"  Error parsing {data['sample_name']}: {data['error']}")
            continue

        byte_offset = data.get('byte_offset', 1)
        format_map = {0: 'C', 1: 'A', 2: 'B'}
        row = {
            'sample': data['sample_name'],
            'filepath': data['filepath'],
            'byte_format': format_map.get(byte_offset, '?'),
            'live_time': data.get('live_time', 60.0),
            'total_counts_46kV': data.get('total_counts_46kV', 0),
            'total_counts_17kV': data.get('total_counts_17kV', 0),
        }

        # Add element counts (now includes cts, cps, and net_cps for each line)
        for element, lines in data['element_counts'].items():
            for metric_name, value in lines.items():
                col_name = f"{element}_{metric_name}"
                row[col_name] = value

        all_data.append(row)

    df = pd.DataFrame(all_data)
    return df


def main():
    print("=" * 60)
    print("XRF Raw Counts Extractor (KETEK EXPERT .RSP format)")
    print("=" * 60)

    # Test on one file first
    test_file = glob(os.path.join(XRF_BASE, "ash_pellets", "**", "*JPL51*.RSP"), recursive=True)
    if test_file:
        print(f"\n1. Testing on: {Path(test_file[0]).name}")
        result = parse_rsp_file(test_file[0])
        print(f"   Spectrum 1 channels: {len(result['spectrum1'])}")
        print(f"   Total counts (46kV): {result['total_counts_46kV']:,}")
        print(f"   Live time: {result['live_time']:.1f}s")
        print(f"   Pb Lα: {result['element_counts']['Pb']['La_cts']:,} cts, {result['element_counts']['Pb']['La_cps']:.1f} cps")
        print(f"   Fe Kα: {result['element_counts']['Fe']['Ka_cts']:,} cts, {result['element_counts']['Fe']['Ka_cps']:.1f} cps")

    # Extract all samples
    print("\n2. Extracting raw counts from all ash samples...")
    df = extract_all_raw_counts()

    # Save to CSV
    output_path = "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/xrf_raw_counts_all.csv"
    df.to_csv(output_path, index=False)
    print(f"\n   Saved {len(df)} samples to: {output_path}")

    # Show summary
    cts_cols = [c for c in df.columns if c.endswith('_cts')]
    cps_cols = [c for c in df.columns if c.endswith('_cps')]
    print(f"   Metrics extracted: {len(cts_cols)} peak counts + {len(cps_cols)} cps values")

    # Show Pb intensity range
    if 'Pb_La_cps' in df.columns:
        pb_cps = df['Pb_La_cps']
        print(f"\n   Pb Lα peak cps range: {pb_cps.min():.1f} to {pb_cps.max():.1f}")
        print(f"   Pb Lα peak cps mean: {pb_cps.mean():.1f}")
    if 'Pb_La_net_cps' in df.columns:
        pb_net = df['Pb_La_net_cps']
        print(f"   Pb Lα net cps range: {pb_net.min():.1f} to {pb_net.max():.1f}")

    print("\n" + "=" * 60)


if __name__ == '__main__':
    main()
