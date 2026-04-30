#!/usr/bin/env python3
"""
Fill in xrf-powder-date and xrf-pellet-date columns in the user-prepared
EFA_sample_metadata.csv from the per-measurement xrf_sample_metadata.csv.

Match logic:
    1. Look up by the ID column directly against xrf_sample_metadata.csv
       EFA.ID (canonical Base_ID).
    2. If the row's ID has no match (e.g., user typo or alternate label),
       try the row's EFA.ID column, then EFA.ID.XRF and EFA.ID.ICPMS
       stripped to their Base_ID stem.
    3. For each (sample, method), collect every measurement date and
       deduplicate; if more than one date exists, list them semicolon-
       separated in chronological order.
    4. Samples with no XRF .prf data on file (typically ICP-MS-only soil
       or partial samples without retained .prf exports) get empty cells.
"""

import csv
import re
from collections import defaultdict
from pathlib import Path

REPO  = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
SRC_USER = REPO / "D2D/XRF/data/cleaned/EFA_sample_metadata.csv"
SRC_PER  = REPO / "D2D/XRF/data/cleaned/xrf_sample_metadata.csv"
DST_OUT  = REPO / "D2D/XRF/data/cleaned/EFA_sample_metadata.csv"   # in-place
DST_MAN  = REPO / "Manuscript/Data/EFA_sample_metadata.csv"

# Regex that strips operator suffixes from a sample identifier to recover
# the Base_ID stem (e.g., JPL68_bkB.S -> JPL68, GPS03_bkB.S.A -> GPS03).
SUFFIX_RE = re.compile(r"_b?k?[AB](\.[ALsS])?(\.[A])?(_\d+)?$")


def base_id(s):
    if not s or s == "NA":
        return None
    return SUFFIX_RE.sub("", s)


def load_per_measurement():
    """Build {Base_ID -> {'pellet': [date,...], 'powder': [date,...]}}."""
    by_id = defaultdict(lambda: {"pellet": [], "powder": []})
    with SRC_PER.open(newline="") as f:
        for r in csv.DictReader(f):
            eid = r["EFA.ID"]
            method = r["xrf_method"]
            date = r["xrf_date"]
            if not date:
                continue
            by_id[eid][method].append(date)
    # dedupe + sort each list
    for d in by_id.values():
        for m in ("pellet", "powder"):
            d[m] = sorted(set(d[m]))
    return by_id


def lookup_dates(row, per_meas):
    """Return (powder_date_str, pellet_date_str) for one row of the user
    metadata file by trying ID, then base-stem of EFA.ID / EFA.ID.XRF /
    EFA.ID.ICPMS in that order."""
    candidates = [row.get("ID")]
    for col in ("EFA.ID", "EFA.ID.XRF", "EFA.ID.ICPMS"):
        candidates.append(base_id(row.get(col, "")))
    for cand in candidates:
        if cand and cand in per_meas:
            d = per_meas[cand]
            return ("; ".join(d["powder"]),
                    "; ".join(d["pellet"]))
    return ("", "")


def main():
    per_meas = load_per_measurement()

    # User's file has a UTF-8 BOM (Excel artifact); read with utf-8-sig so
    # the first column key is "ID" rather than "﻿ID".
    with SRC_USER.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames
        rows = list(reader)

    # Ensure the two date columns exist (they already do per the user file).
    for c in ("xrf-powder-date", "xrf-pellet-date"):
        if c not in cols:
            cols.append(c)

    n_filled_pow = n_filled_pel = n_no_data = 0
    for row in rows:
        powder, pellet = lookup_dates(row, per_meas)
        row["xrf-powder-date"] = powder
        row["xrf-pellet-date"] = pellet
        if powder: n_filled_pow += 1
        if pellet: n_filled_pel += 1
        if not powder and not pellet: n_no_data += 1

    # Write back to D2D and copy to Manuscript/Data. Preserve the user's
    # UTF-8-with-BOM encoding so Excel reopens it identically.
    for dst in (DST_OUT, DST_MAN):
        with dst.open("w", newline="", encoding="utf-8-sig") as f:
            w = csv.DictWriter(f, fieldnames=cols)
            w.writeheader()
            w.writerows(rows)

    print(f"Wrote {DST_OUT.relative_to(REPO)} ({len(rows)} rows)")
    print(f"  rows with xrf-powder-date filled: {n_filled_pow}")
    print(f"  rows with xrf-pellet-date filled: {n_filled_pel}")
    print(f"  rows with neither (no .prf on file): {n_no_data}")
    print()
    print("Rows without any XRF date (likely ICP-MS-only or no .prf retained):")
    for row in rows:
        if not row["xrf-powder-date"] and not row["xrf-pellet-date"]:
            print(f"    {row['ID']:8s}  alq.type={row.get('alq.type','?'):5s}  "
                  f"EFA.ID.XRF={row.get('EFA.ID.XRF','')}")


if __name__ == "__main__":
    main()
