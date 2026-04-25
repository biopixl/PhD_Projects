#!/usr/bin/env python3
"""
Promote manuscript raw XRF tables into D2D cleaned files.

Source:
    Manuscript/Data/2_XRF-concentrations-raw.csv  -> D2D/XRF/data/cleaned/XRF_elements_clean.csv
    Manuscript/Data/3_XRF-intensities-raw.csv     -> D2D/XRF/data/cleaned/XRF-Pb_clean.csv

Cleaning steps:
    1. Drop spurious header rows interleaved by hand-concatenated exports
    2. Drop empty rows (",,,,,...")
    3. Normalize Pb line symbols to ASCII underscore form (Pb_La1, Pb_Lb1, ...)
    4. Drop the single Pb-Leta row (not in the canonical 8-line downstream schema)
    5. Replace "0,—" placeholders for missing intensities with empty cells

Run from anywhere; paths are absolute.
"""

import csv
import re
import shutil
from pathlib import Path

REPO = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
SRC_ELEMENTS = REPO / "Manuscript/Data/2_XRF-concentrations-raw.csv"
SRC_PB = REPO / "Manuscript/Data/3_XRF-intensities-raw.csv"
DST_ELEMENTS = REPO / "D2D/XRF/data/cleaned/XRF_elements_clean.csv"
DST_PB = REPO / "D2D/XRF/data/cleaned/XRF-Pb_clean.csv"

ELEMENTS_HEADER = ["sample_id", "method", "element", "int_cts_s", "int_err",
                   "value", "unit", "value_err"]
PB_HEADER = ["sample_id", "method", "line_symbol", "energy_keV", "cts_per_s", "error"]

# Canonical 8-line schema expected by xrf_icpms_regression_framework.R
CANONICAL_PB_LINES = {"Pb_La1", "Pb_La2", "Pb_Lb1", "Pb_Lb2",
                      "Pb_Lb3", "Pb_Lb4", "Pb_Lg1", "Pb_Ll"}

# Map every variant seen in raw to canonical underscore form.
LINE_SYMBOL_MAP = {
    # hyphen variants
    "Pb-La1": "Pb_La1", "Pb-La2": "Pb_La2",
    "Pb-Lb1": "Pb_Lb1", "Pb-Lb2": "Pb_Lb2",
    "Pb-Lb3": "Pb_Lb3", "Pb-Lb4": "Pb_Lb4",
    "Pb-Lg1": "Pb_Lg1", "Pb-Ll": "Pb_Ll",
    # Greek/space variants
    "Pb Lα1": "Pb_La1", "Pb Lα2": "Pb_La2",
    "Pb Lβ1": "Pb_Lb1", "Pb Lβ2": "Pb_Lb2",
    "Pb Lβ3": "Pb_Lb3", "Pb Lβ4": "Pb_Lb4",
    "Pb Lγ1": "Pb_Lg1", "Pb Ll": "Pb_Ll",
}

SPURIOUS_FIRST_FIELDS = {"sample_id", "Sample", ""}

# PBP clay calibration standards live in
# D2D/XRF/data/calibration/PBP_calibration_detailed.csv keyed by IDs that embed
# the method (e.g. PBP01_pellet_A, PBP01_powder_1). The manuscript raw exports
# strip the infix; restore it here so the calibration join keeps working.
PBP_PELLET_RE = re.compile(r"^(PBP0\d)_([ABCD])$")
PBP_POWDER_RE = re.compile(r"^(PBP0\d)_([123])$")


def restore_pbp_id(sample_id, method):
    if method == "pellet":
        m = PBP_PELLET_RE.match(sample_id)
        if m:
            return f"{m.group(1)}_pellet_{m.group(2)}"
    elif method == "powder":
        m = PBP_POWDER_RE.match(sample_id)
        if m:
            return f"{m.group(1)}_powder_{m.group(2)}"
    return sample_id


def is_blank_row(row):
    return all((c is None or c.strip() == "") for c in row)


def clean_elements():
    kept, dropped_header, dropped_blank, fixed_emdash, pbp_renamed = 0, 0, 0, 0, 0
    with SRC_ELEMENTS.open(newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        rows = list(reader)

    out_rows = [ELEMENTS_HEADER]
    for row in rows:
        if not row or is_blank_row(row):
            dropped_blank += 1
            continue
        if row[0] in SPURIOUS_FIRST_FIELDS:
            dropped_header += 1
            continue
        # pad/trim to 8 cols
        if len(row) < 8:
            row = row + [""] * (8 - len(row))
        elif len(row) > 8:
            row = row[:8]
        new_id = restore_pbp_id(row[0], row[1])
        if new_id != row[0]:
            row[0] = new_id
            pbp_renamed += 1
        # em-dash is the source's missing-value marker; clear it from
        # int_cts_s and int_err. When int_cts_s == "0" alongside, drop both
        # (the "0" is a placeholder, not a real intensity reading).
        if row[3] == "0" and row[4] == "—":
            row[3] = ""
            row[4] = ""
            fixed_emdash += 1
        elif row[4] == "—":
            row[4] = ""
            fixed_emdash += 1
        elif row[3] == "—":
            row[3] = ""
            fixed_emdash += 1
        out_rows.append(row)
        kept += 1

    DST_ELEMENTS.parent.mkdir(parents=True, exist_ok=True)
    with DST_ELEMENTS.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(out_rows)

    return {
        "kept": kept,
        "dropped_header": dropped_header,
        "dropped_blank": dropped_blank,
        "fixed_emdash": fixed_emdash,
        "pbp_renamed": pbp_renamed,
    }


def clean_pb():
    kept, dropped_header, dropped_blank, dropped_leta, renamed, pbp_renamed = 0, 0, 0, 0, 0, 0
    with SRC_PB.open(newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        rows = list(reader)

    out_rows = [PB_HEADER]
    for row in rows:
        if not row or is_blank_row(row):
            dropped_blank += 1
            continue
        if row[0] in SPURIOUS_FIRST_FIELDS:
            dropped_header += 1
            continue
        if len(row) < 6:
            row = row + [""] * (6 - len(row))
        elif len(row) > 6:
            row = row[:6]
        new_id = restore_pbp_id(row[0], row[1])
        if new_id != row[0]:
            row[0] = new_id
            pbp_renamed += 1
        line_symbol = row[2]
        # canonical line stays
        if line_symbol in CANONICAL_PB_LINES:
            pass
        elif line_symbol in LINE_SYMBOL_MAP:
            row[2] = LINE_SYMBOL_MAP[line_symbol]
            renamed += 1
        elif line_symbol in ("Pb-Leta", "Pb_Leta"):
            dropped_leta += 1
            continue
        else:
            # unknown line symbol — surface it
            print(f"WARN: unmapped line_symbol {line_symbol!r} in row {row}")
        out_rows.append(row)
        kept += 1

    DST_PB.parent.mkdir(parents=True, exist_ok=True)
    with DST_PB.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(out_rows)

    return {
        "kept": kept,
        "dropped_header": dropped_header,
        "dropped_blank": dropped_blank,
        "dropped_leta": dropped_leta,
        "renamed": renamed,
        "pbp_renamed": pbp_renamed,
    }


def summary(label, dst, stats):
    with dst.open() as f:
        body = list(csv.reader(f))[1:]
    samples = sorted({r[0] for r in body})
    pairs = sorted({(r[0], r[1]) for r in body})
    n_pellet = sum(1 for s, m in pairs if m == "pellet")
    n_powder = sum(1 for s, m in pairs if m == "powder")
    print(f"\n[{label}] -> {dst.relative_to(REPO)}")
    print(f"  rows kept:       {stats['kept']}")
    for k, v in stats.items():
        if k != "kept":
            print(f"  {k:16s} {v}")
    print(f"  unique samples:  {len(samples)}")
    print(f"  sample×method:   {len(pairs)} (pellet={n_pellet}, powder={n_powder})")


def main():
    e = clean_elements()
    p = clean_pb()
    summary("elements", DST_ELEMENTS, e)
    summary("Pb intensities", DST_PB, p)


if __name__ == "__main__":
    main()
