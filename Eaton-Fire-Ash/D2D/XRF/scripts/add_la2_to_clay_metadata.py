#!/usr/bin/env python3
"""
Augment EFA_XRF_Clay_Metadata.csv with Pb_La2_cps and Pb_La2_err columns
joined from the cleaned long-format intensity table. This makes the
Zenodo Clay_Metadata file self-contained for the 6-line sweep
(La1-2 + Lb1-4) reported in the SI.

Run once after a fresh Zenodo deposit, then check in the result.
"""

import csv
from pathlib import Path

REPO  = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
CLAY  = REPO / "D2D/XRF/data/zenodo/EFA_XRF_Clay_Metadata.csv"
LONG  = REPO / "D2D/XRF/data/cleaned/xrf_intensities.csv"
MAN   = REPO / "Manuscript/Data/EFA_XRF_Clay_Metadata.csv"

# Build {sample_id -> (cps, err)} for Pb_La2 from the cleaned data
la2 = {}
with LONG.open(newline="") as f:
    for r in csv.DictReader(f):
        if r["line_symbol"] == "Pb_La2" and r["sample_id"].startswith("PBP"):
            la2[r["sample_id"]] = (r["intensity_cps"], r["intensity_err_cps"])

# Read existing Clay_Metadata, splice La2 columns after Pb_La1_err
with CLAY.open(newline="", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    rows = list(reader)

header = rows[0]
# Insert "Pb_La2_cps" and "Pb_La2_err" right after "Pb_La1_err" (col index 7)
try:
    insert_at = header.index("Pb_La1_err") + 1
except ValueError:
    insert_at = header.index("Pb_Lb1_cps")  # fall back to before Lb1

new_header = header[:insert_at] + ["Pb_La2_cps", "Pb_La2_err"] + header[insert_at:]

new_rows = [new_header]
for row in rows[1:]:
    sid = row[0]
    cps, err = la2.get(sid, ("", ""))
    new_rows.append(row[:insert_at] + [cps, err] + row[insert_at:])

# Write back to D2D and mirror to Manuscript/Data
for dst in (CLAY, MAN):
    with dst.open("w", newline="", encoding="utf-8-sig") as f:
        csv.writer(f).writerows(new_rows)

n_filled = sum(1 for r in new_rows[1:] if r[insert_at])
print(f"Wrote {CLAY.relative_to(REPO)}")
print(f"  La2 columns inserted at position {insert_at + 1} (after Pb_La1_err)")
print(f"  Filled values: {n_filled} of {len(new_rows) - 1} rows")
