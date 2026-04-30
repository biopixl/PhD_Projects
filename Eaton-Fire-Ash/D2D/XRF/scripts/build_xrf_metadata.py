#!/usr/bin/env python3
"""
Build the per-XRF-measurement metadata table for the publication data deposit.

Walk every .prf file under ash_pellets/ and ash-powders/, extract the
in-file Comment and measurement date, and resolve the canonical EFA.ID by
matching against the curated Base_ID list in sample_id_harmonization.csv.
Rows whose Comment cannot be resolved to a Base_ID in the publication set
are written to a separate "unmatched" file for review.

Output columns (matches the spec):
    EFA.ID            canonical sample identifier (= Base_ID)
    xrf_date          measurement date (YYYY-MM-DD)
    longitude         decimal degrees
    latitude          decimal degrees
    xrf_sample_id     instrument-side sample identifier (the .prf Comment
                      string, or the .prf filename stem if no Comment)

Plus three audit columns kept by default for traceability:
    xrf_method        "pellet" / "powder"
    xrf_subfolder     measurement subfolder (e.g., "6-25_pellets")
    xrf_filename      the .prf filename

Usage:
    python3 D2D/XRF/scripts/build_xrf_metadata.py
    -> writes D2D/XRF/data/cleaned/xrf_sample_metadata.csv
              D2D/XRF/data/cleaned/xrf_sample_metadata_unmatched.csv
"""

import csv
import re
from pathlib import Path

REPO  = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
PRF_ROOT = REPO / "Ashes-EDXRF/EXPERT_ENG/WrkExpert/W187U/WORK/Aguilar_Isaac"
ICPMS = REPO / "D2D/ICPMS/EFA_ICPMS_PPM.csv"
HARMO = REPO / "D2D/XRF/data/cleaned/sample_id_harmonization.csv"
DST_OK   = REPO / "D2D/XRF/data/cleaned/xrf_sample_metadata.csv"
DST_MISS = REPO / "D2D/XRF/data/cleaned/xrf_sample_metadata_unmatched.csv"

ASH_PELLET_DIR = PRF_ROOT / "ash_pellets"
ASH_POWDER_DIR = PRF_ROOT / "ash-powders"

# .prf date appears as either:
#   Completed measurement data. DD-MM-YYYY[HH:MM:SS AM/PM]    (newer)
#   File "<name>". DD-MM-YYYY[HH:MM:SS AM/PM]                 (older)
DATE_RE    = re.compile(
    r"(?:Completed measurement data\.|File\s+\"[^\"]*\"\.)\s*"
    r"(\d{1,2})-(\d{1,2})-(\d{4})"
)
COMMENT_RE = re.compile(r"^\s*Comment:(.+)$", re.MULTILINE)

# Prefix patterns the operator added to filenames or comments
PREFIX_PATTERNS = [
    r"^ash[-_]pellets?_\d{1,2}[-_]?[A-Za-z]+_",   # "ash-pellets_15-July_..."
    r"^ash[-_]pellet_",                           # "ash-pellet_..." / "ash_pellet_..."
    r"^ash[-_]pellets_",
    r"^\d{1,2}[-_]?[A-Za-z]+_ash_pellets_",       # "14_July_ash_pellets_..."
    r"^\d{1,2}-\d{1,2}_",                         # "6-25_..."
    r"^\d{1,2}-[A-Za-z]+_",                       # "11-July_..."
]

# Suffix patterns operator used to label aliquots/replicates/preps
SUFFIX_PATTERNS = [
    r"_bkB\.S\.A$", r"_bkB\.S$", r"_bkB\.L$", r"_bkB$",
    r"_bkA\.S$",    r"_bkA\.L$", r"_bkA\.LH$", r"_bkA\.LL$",
    r"_bkA\.s$",    r"_bkA$",
    r"_B\.S_\d+$", r"_A\.S_\d+$",
    r"_\d+$",                # trailing replicate flag like _1 _2 _3
    r"\.S$", r"\.L$", r"\.s$",
]


def parse_prf(path: Path):
    try:
        text = path.read_text(encoding="iso-8859-1", errors="ignore")
    except Exception:
        return None, None
    m = DATE_RE.search(text)
    date = f"{m.group(3)}-{int(m.group(2)):02d}-{int(m.group(1)):02d}" if m else ""
    c = COMMENT_RE.search(text)
    comment = c.group(1).strip() if c else path.stem
    return comment, date


def normalize_candidates(raw):
    """Generate candidate canonical IDs by stripping prefix/suffix patterns
    iteratively, yielding each intermediate form."""
    candidates = [raw]
    for _ in range(5):                                     # iterate to a fixed point
        s = candidates[-1]
        for pat in PREFIX_PATTERNS + SUFFIX_PATTERNS:
            new = re.sub(pat, "", s)
            if new != s:
                s = new
        if s == candidates[-1]:
            break
        candidates.append(s)
    return candidates


def resolve_to_base_id(raw, base_ids):
    """Return the matching Base_ID or None."""
    for cand in normalize_candidates(raw):
        if cand in base_ids:
            return cand
    return None


def load_locations():
    """Build {EFA.ID -> (lat, lon)} preferring the ICP-MS file (which has
    higher-precision coordinates) and falling back to the harmonization
    sheet for samples not assayed by ICP-MS."""
    locs = {}
    with HARMO.open(newline="") as f:
        for r in csv.DictReader(f):
            if r.get("Lat") and r.get("Lon"):
                locs[r["Base_ID"]] = (r["Lat"], r["Lon"])
    with ICPMS.open(newline="") as f:
        for r in csv.DictReader(f):
            if r.get("Lat") and r.get("Lon"):
                locs[r["EFA.ID"]] = (r["Lat"], r["Lon"])
    return locs


def load_base_ids():
    """Set of canonical Base_IDs from the harmonization sheet."""
    base_ids = set()
    with HARMO.open(newline="") as f:
        for r in csv.DictReader(f):
            base_ids.add(r["Base_ID"])
    return base_ids


def walk_method(folder: Path, method: str):
    if not folder.exists():
        return
    for prf in sorted(folder.rglob("*.prf")):
        xrf_sample_id, xrf_date = parse_prf(prf)
        if xrf_sample_id is None:
            continue
        rel = prf.relative_to(folder)
        subfolder = rel.parent.as_posix() if rel.parent != Path(".") else ""
        yield {
            "xrf_sample_id": xrf_sample_id,
            "xrf_date":      xrf_date,
            "xrf_method":    method,
            "xrf_subfolder": subfolder,
            "xrf_filename":  prf.name,
        }


def main():
    base_ids = load_base_ids()
    locs     = load_locations()

    matched, unmatched = [], []
    for rec in list(walk_method(ASH_PELLET_DIR, "pellet")) + \
               list(walk_method(ASH_POWDER_DIR, "powder")):
        eid = resolve_to_base_id(rec["xrf_sample_id"], base_ids)
        if eid is None:
            # Also try the filename stem (sometimes the in-file Comment has
            # the long operator-typed name but the filename is closer to canonical).
            eid = resolve_to_base_id(Path(rec["xrf_filename"]).stem, base_ids)
        if eid is None:
            unmatched.append(rec)
            continue
        lat, lon = locs.get(eid, ("", ""))
        rec["EFA.ID"]    = eid
        rec["latitude"]  = lat
        rec["longitude"] = lon
        matched.append(rec)

    # Sort by date, then EFA.ID, then method
    matched.sort(key=lambda r: (r["xrf_date"] or "0000-00-00",
                                r["EFA.ID"], r["xrf_method"]))

    cols = ["EFA.ID", "xrf_date", "longitude", "latitude",
            "xrf_sample_id", "xrf_method", "xrf_subfolder", "xrf_filename"]

    with DST_OK.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in matched:
            w.writerow({c: r.get(c, "") for c in cols})

    miss_cols = ["xrf_sample_id", "xrf_method", "xrf_subfolder",
                 "xrf_filename", "xrf_date"]
    with DST_MISS.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=miss_cols)
        w.writeheader()
        for r in unmatched:
            w.writerow({c: r.get(c, "") for c in miss_cols})

    n_pellet = sum(1 for r in matched if r["xrf_method"] == "pellet")
    n_powder = sum(1 for r in matched if r["xrf_method"] == "powder")
    n_with_loc = sum(1 for r in matched if r["latitude"])
    print(f"Wrote {DST_OK.relative_to(REPO)}")
    print(f"  matched rows:           {len(matched)}  (pellet={n_pellet}, powder={n_powder})")
    print(f"  unique EFA.IDs:         {len({r['EFA.ID'] for r in matched})}")
    print(f"  rows with lat/lon:      {n_with_loc}")
    print(f"  rows with parsed date:  {sum(1 for r in matched if r['xrf_date'])}")
    print()
    print(f"Wrote {DST_MISS.relative_to(REPO)}")
    print(f"  unmatched rows: {len(unmatched)} (likely dev/test runs or non-publication samples)")


if __name__ == "__main__":
    main()
