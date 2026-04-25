#!/usr/bin/env python3
"""
Clean and publish XRF concentrations and intensities tables.

Source files (raw instrument exports, hand-concatenated, dirty):
    D2D/XRF/data/raw/2_XRF-concentrations-raw.csv
    D2D/XRF/data/raw/3_XRF-intensities-raw.csv

Outputs (D2D/XRF/data/cleaned/):
    xrf_concentrations.csv         long format, every (sample, method, element)
    xrf_concentrations_wide.csv    one row per (sample, method); element columns
    xrf_intensities.csv            long format, every (sample, method, Pb line)
    xrf_intensities_wide.csv       one row per (sample, method); line columns

Cleaning steps applied:
    1. Drop spurious header rows interleaved by hand-concatenated exports.
    2. Drop empty rows.
    3. Normalize Pb line symbols to ASCII underscore form (Pb_La1, ...).
    4. Drop the single Pb-Leta row not in the canonical 8-line schema.
    5. Replace "—" placeholders with empty cells; turn "0,—" into NA pair.
    6. Restore PBP clay-standard IDs to PBPxx_<method>_<rep> form for the
       calibration registry join.
    7. Use "NA" string for every missing cell across all output files.
    8. Convert wt% values to ppm in the wide concentration table so XRF and
       (future) ICPMS wide tables share a common ppm-only column schema.

Schema harmonization note (forward-compatible with ICP-MS):
    - sample_id        joins ICPMS Base_ID (rename ICPMS EFA.ID -> sample_id
                       when its cleanup is done).
    - method           "pellet" / "powder" for XRF; reserved for "icpms" or
                       "icpms_<digestion>" when ICPMS data is brought in.
    - element          element symbol; matches ICPMS column headers.
    - value, value_err in same units (ppm or %); the unit column is explicit.
    - For wide outputs, every value column carries its unit suffix
      (_value_ppm / _err_ppm) so concatenation across instruments is
      unambiguous.

Run from anywhere; paths are absolute.
"""

import csv
import re
from collections import defaultdict
from pathlib import Path

REPO = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
SRC_CONC = REPO / "D2D/XRF/data/raw/2_XRF-concentrations-raw.csv"
SRC_INT  = REPO / "D2D/XRF/data/raw/3_XRF-intensities-raw.csv"

CLEANED = REPO / "D2D/XRF/data/cleaned"
DST_CONC_LONG = CLEANED / "xrf_concentrations.csv"
DST_CONC_WIDE = CLEANED / "xrf_concentrations_wide.csv"
DST_INT_LONG  = CLEANED / "xrf_intensities.csv"
DST_INT_WIDE  = CLEANED / "xrf_intensities_wide.csv"

# Long-format column schemas — common keys (sample_id, method) align with the
# planned ICPMS cleanup so wide pivots can be cross-joined on the same axis.
CONC_LONG_HEADER = ["sample_id", "method", "element",
                    "intensity_cps", "intensity_err_cps",
                    "value", "unit", "value_err"]
INT_LONG_HEADER  = ["sample_id", "method", "line_symbol", "energy_keV",
                    "intensity_cps", "intensity_err_cps"]

CANONICAL_PB_LINES = ["Pb_La1", "Pb_La2", "Pb_Lb1", "Pb_Lb2",
                      "Pb_Lb3", "Pb_Lb4", "Pb_Lg1", "Pb_Ll"]

LINE_SYMBOL_MAP = {
    "Pb-La1": "Pb_La1", "Pb-La2": "Pb_La2",
    "Pb-Lb1": "Pb_Lb1", "Pb-Lb2": "Pb_Lb2",
    "Pb-Lb3": "Pb_Lb3", "Pb-Lb4": "Pb_Lb4",
    "Pb-Lg1": "Pb_Lg1", "Pb-Ll":  "Pb_Ll",
    "Pb Lα1": "Pb_La1", "Pb Lα2": "Pb_La2",
    "Pb Lβ1": "Pb_Lb1", "Pb Lβ2": "Pb_Lb2",
    "Pb Lβ3": "Pb_Lb3", "Pb Lβ4": "Pb_Lb4",
    "Pb Lγ1": "Pb_Lg1", "Pb Ll":  "Pb_Ll",
}

SPURIOUS_FIRST_FIELDS = {"sample_id", "Sample", ""}

PBP_PELLET_RE = re.compile(r"^(PBP0\d)_([ABCD])$")
PBP_POWDER_RE = re.compile(r"^(PBP0\d)_([123])$")


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

def restore_pbp_id(sample_id, method):
    """Re-add the method infix to PBP standard IDs so the calibration registry
    join (PBPxx_pellet_A / PBPxx_powder_1) keeps working."""
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


def write_csv_with_na(path, header, rows):
    """Write CSV replacing every empty / None cell with the literal string NA."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in rows:
            w.writerow(["NA" if (c is None or str(c).strip() == "") else c for c in r])


def to_ppm(value_str, unit_str):
    """Convert a long-format (value, unit) pair to a ppm float, or None."""
    if value_str is None or value_str == "" or value_str == "NA":
        return None
    try:
        v = float(value_str)
    except ValueError:
        return None
    u = (unit_str or "").strip().lower().replace("wt_", "")
    if u == "%":
        return v * 1e4
    if u == "ppm":
        return v
    return None


def _mean(values):
    nums = [v for v in values if v is not None]
    return sum(nums) / len(nums) if nums else None


def _maybe_float(s):
    if s in (None, "", "NA"):
        return None
    try:
        return float(s)
    except ValueError:
        return None


def _fmt(x):
    """Format a numeric back to a compact string; None -> ''."""
    if x is None:
        return ""
    if x == int(x):
        return str(int(x))
    return f"{x:g}"


def deduplicate_concentrations(rows):
    """Aggregate replicate measurements per (sample_id, method, element).
    Byte-identical replicates collapse to one row; differing replicates are
    averaged numerically, with the first row's unit retained."""
    grouped = defaultdict(list)
    for r in rows:
        grouped[(r[0], r[1], r[2])].append(r)
    out, n_byte_dup, n_avg = [], 0, 0
    for key, group in grouped.items():
        if len(group) == 1:
            out.append(group[0]); continue
        if len({tuple(g) for g in group}) == 1:
            out.append(group[0]); n_byte_dup += len(group) - 1; continue
        sid, method, elem = key
        icps_avg = _mean([_maybe_float(g[3]) for g in group])
        ierr_avg = _mean([_maybe_float(g[4]) for g in group])
        val_avg  = _mean([_maybe_float(g[5]) for g in group])
        verr_avg = _mean([_maybe_float(g[7]) for g in group])
        out.append([sid, method, elem,
                    _fmt(icps_avg), _fmt(ierr_avg),
                    _fmt(val_avg), group[0][6], _fmt(verr_avg)])
        n_avg += 1
    return out, n_byte_dup, n_avg


def deduplicate_intensities(rows):
    """Aggregate replicate Pb-line measurements per (sample_id, method,
    line_symbol). Same logic as concentrations."""
    grouped = defaultdict(list)
    for r in rows:
        grouped[(r[0], r[1], r[2])].append(r)
    out, n_byte_dup, n_avg = [], 0, 0
    for key, group in grouped.items():
        if len(group) == 1:
            out.append(group[0]); continue
        if len({tuple(g) for g in group}) == 1:
            out.append(group[0]); n_byte_dup += len(group) - 1; continue
        sid, method, line = key
        cps_avg = _mean([_maybe_float(g[4]) for g in group])
        err_avg = _mean([_maybe_float(g[5]) for g in group])
        out.append([sid, method, line, group[0][3],
                    _fmt(cps_avg), _fmt(err_avg)])
        n_avg += 1
    return out, n_byte_dup, n_avg


# -----------------------------------------------------------------------------
# Stage 1 — clean the long-format concentration table
# -----------------------------------------------------------------------------

def clean_concentrations_long():
    stats = dict(kept=0, dropped_header=0, dropped_blank=0,
                 fixed_emdash=0, pbp_renamed=0, normalized_unit=0)
    with SRC_CONC.open(newline="", encoding="utf-8") as f:
        rows_in = list(csv.reader(f))

    cleaned = []
    for row in rows_in:
        if not row or is_blank_row(row):
            stats["dropped_blank"] += 1
            continue
        if row[0] in SPURIOUS_FIRST_FIELDS:
            stats["dropped_header"] += 1
            continue
        # pad/trim to 8 columns
        if len(row) < 8:
            row = row + [""] * (8 - len(row))
        elif len(row) > 8:
            row = row[:8]
        # restore PBP method infix (sample_id, method)
        new_id = restore_pbp_id(row[0], row[1])
        if new_id != row[0]:
            row[0] = new_id
            stats["pbp_renamed"] += 1
        # em-dash placeholder fixes for intensity (col 3) and intensity_err (col 4)
        if row[3] == "0" and row[4] == "—":
            row[3] = ""; row[4] = ""; stats["fixed_emdash"] += 1
        elif row[4] == "—":
            row[4] = ""; stats["fixed_emdash"] += 1
        elif row[3] == "—":
            row[3] = ""; stats["fixed_emdash"] += 1
        # normalize unit "wt_%" -> "%"
        if row[6] == "wt_%":
            row[6] = "%"; stats["normalized_unit"] += 1
        cleaned.append(row)
        stats["kept"] += 1

    # Deduplicate replicate (sample_id, method, element) rows by averaging.
    cleaned, n_byte_dup, n_avg = deduplicate_concentrations(cleaned)
    stats["dedup_byte_identical"] = n_byte_dup
    stats["dedup_averaged"] = n_avg
    stats["kept"] = len(cleaned)

    # sort deterministically: sample_id, method, element
    cleaned.sort(key=lambda r: (r[0], r[1], r[2]))

    write_csv_with_na(DST_CONC_LONG, CONC_LONG_HEADER, cleaned)
    return cleaned, stats


# -----------------------------------------------------------------------------
# Stage 2 — clean the long-format intensity table
# -----------------------------------------------------------------------------

def clean_intensities_long():
    stats = dict(kept=0, dropped_header=0, dropped_blank=0,
                 dropped_leta=0, renamed=0, pbp_renamed=0)
    with SRC_INT.open(newline="", encoding="utf-8") as f:
        rows_in = list(csv.reader(f))

    cleaned = []
    for row in rows_in:
        if not row or is_blank_row(row):
            stats["dropped_blank"] += 1
            continue
        if row[0] in SPURIOUS_FIRST_FIELDS:
            stats["dropped_header"] += 1
            continue
        if len(row) < 6:
            row = row + [""] * (6 - len(row))
        elif len(row) > 6:
            row = row[:6]
        new_id = restore_pbp_id(row[0], row[1])
        if new_id != row[0]:
            row[0] = new_id
            stats["pbp_renamed"] += 1
        line_symbol = row[2]
        if line_symbol in CANONICAL_PB_LINES:
            pass
        elif line_symbol in LINE_SYMBOL_MAP:
            row[2] = LINE_SYMBOL_MAP[line_symbol]
            stats["renamed"] += 1
        elif line_symbol in ("Pb-Leta", "Pb_Leta"):
            stats["dropped_leta"] += 1
            continue
        else:
            print(f"WARN: unmapped line_symbol {line_symbol!r} in row {row}")
        cleaned.append(row)
        stats["kept"] += 1

    cleaned, n_byte_dup, n_avg = deduplicate_intensities(cleaned)
    stats["dedup_byte_identical"] = n_byte_dup
    stats["dedup_averaged"] = n_avg
    stats["kept"] = len(cleaned)

    cleaned.sort(key=lambda r: (r[0], r[1],
                                CANONICAL_PB_LINES.index(r[2]) if r[2] in CANONICAL_PB_LINES else 99))

    write_csv_with_na(DST_INT_LONG, INT_LONG_HEADER, cleaned)
    return cleaned, stats


# -----------------------------------------------------------------------------
# Stage 3 — pivot to wide concentrations (every value in ppm, NA for missing)
# -----------------------------------------------------------------------------

def write_concentrations_wide(rows):
    elements = sorted({r[2] for r in rows})
    keys = sorted({(r[0], r[1]) for r in rows})

    # index: (sample_id, method, element) -> (value_ppm, value_err_ppm)
    idx = {}
    for r in rows:
        sid, method, elem, _icps, _ierr, value, unit, value_err = r
        v_ppm   = to_ppm(value,     unit)
        err_ppm = to_ppm(value_err, unit)
        idx[(sid, method, elem)] = (v_ppm, err_ppm)

    header = ["sample_id", "method"]
    for el in elements:
        header += [f"{el}_value_ppm", f"{el}_err_ppm"]

    out_rows = []
    for sid, method in keys:
        row = [sid, method]
        for el in elements:
            v_ppm, err_ppm = idx.get((sid, method, el), (None, None))
            row.append("" if v_ppm   is None else f"{v_ppm:g}")
            row.append("" if err_ppm is None else f"{err_ppm:g}")
        out_rows.append(row)

    write_csv_with_na(DST_CONC_WIDE, header, out_rows)
    return len(out_rows), len(elements)


# -----------------------------------------------------------------------------
# Stage 4 — pivot to wide intensities (one row per sample×method)
# -----------------------------------------------------------------------------

def write_intensities_wide(rows):
    keys = sorted({(r[0], r[1]) for r in rows})
    energy_lookup = {}        # line_symbol -> energy_keV (first seen)
    idx = {}                  # (sid, method, line) -> (cps, err_cps)
    for r in rows:
        sid, method, line_symbol, energy_keV, intensity_cps, intensity_err_cps = r
        if line_symbol not in energy_lookup and energy_keV not in ("", None):
            energy_lookup[line_symbol] = energy_keV
        idx[(sid, method, line_symbol)] = (intensity_cps, intensity_err_cps)

    header = ["sample_id", "method"]
    for ln in CANONICAL_PB_LINES:
        header += [f"{ln}_cps", f"{ln}_err_cps"]

    out_rows = []
    for sid, method in keys:
        row = [sid, method]
        for ln in CANONICAL_PB_LINES:
            cps, err = idx.get((sid, method, ln), ("", ""))
            row.append(cps if cps not in ("", None) else "")
            row.append(err if err not in ("", None) else "")
        out_rows.append(row)

    write_csv_with_na(DST_INT_WIDE, header, out_rows)
    return len(out_rows), len(CANONICAL_PB_LINES)


# -----------------------------------------------------------------------------
# Reporting
# -----------------------------------------------------------------------------

def report_long(label, dst, rows, stats):
    samples = sorted({r[0] for r in rows})
    pairs   = sorted({(r[0], r[1]) for r in rows})
    n_pellet = sum(1 for s, m in pairs if m == "pellet")
    n_powder = sum(1 for s, m in pairs if m == "powder")
    print(f"\n[{label}] -> {dst.relative_to(REPO)}")
    print(f"  rows kept:       {stats['kept']}")
    for k, v in stats.items():
        if k != "kept":
            print(f"  {k:18s} {v}")
    print(f"  unique samples:  {len(samples)}")
    print(f"  sample×method:   {len(pairs)} (pellet={n_pellet}, powder={n_powder})")


def main():
    print("=== xrf_concentrations / xrf_intensities cleanup ===")
    conc_rows, conc_stats = clean_concentrations_long()
    int_rows,  int_stats  = clean_intensities_long()

    n_conc_wide, n_elements = write_concentrations_wide(conc_rows)
    n_int_wide,  n_lines    = write_intensities_wide(int_rows)

    report_long("concentrations long",  DST_CONC_LONG, conc_rows, conc_stats)
    report_long("intensities long",     DST_INT_LONG,  int_rows,  int_stats)
    print(f"\n[concentrations wide] -> {DST_CONC_WIDE.relative_to(REPO)}")
    print(f"  rows: {n_conc_wide}    elements: {n_elements}    "
          f"columns: {2 + 2*n_elements}")
    print(f"[intensities wide]    -> {DST_INT_WIDE.relative_to(REPO)}")
    print(f"  rows: {n_int_wide}    lines: {n_lines}    "
          f"columns: {2 + 2*n_lines}")


if __name__ == "__main__":
    main()
