#!/usr/bin/env python3
"""
Fill empty prediction columns in the Zenodo deposit files from pipeline outputs.

  EFA_XRF_Ash.csv          Pb_prediction      <- ash_predicted_Pb.csv
                                                (intensity arm matched to method)

  EFA_XRF_Clay_Metadata.csv Pred_Pb_ppm       <- Table_LOOCV_predictions.csv
                            Error              (LOOCV intensity arm prediction
                                                and signed residual prediction-
                                                minus-known)

ID matching uses (ID, method) on the ash file and ID alone on the clay
metadata file, since clay rows already encode method in the sample ID.

Preserves the user-provided UTF-8 BOM and the original column order.
"""

import csv
from pathlib import Path

REPO   = Path("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash")
ZEN    = REPO / "D2D/XRF/data/zenodo"
ASH    = ZEN / "EFA_XRF_Ash.csv"
CLAY   = ZEN / "EFA_XRF_Clay_Metadata.csv"
ASH_PRED = REPO / "D2D/XRF/data/validation/ash_predicted_Pb.csv"
LOOCV    = REPO / "D2D/XRF/results/Table_LOOCV_predictions.csv"


# -----------------------------------------------------------------------------
# Build ash predictions: (ID, method) -> Pb_prediction (intensity arm)
# -----------------------------------------------------------------------------

def load_ash_intensity_predictions():
    preds = {}
    with ASH_PRED.open(newline="") as f:
        for r in csv.DictReader(f):
            arm = r["arm"]
            # Use the intensity arm matching the method (the recommended model)
            if arm in ("pellet_intensity", "powder_intensity"):
                method = r["method"]
                preds[(r["sample_id"], method)] = r["predicted_Pb_ppm"]
    return preds


def fill_ash():
    preds = load_ash_intensity_predictions()
    with ASH.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        rows = list(reader)
    header = rows[0]
    # Column "Pb_prediction" (might be 17th column based on header inspection).
    try:
        col_id = header.index("ID")
    except ValueError:
        col_id = 0  # first col anyway
    col_method = header.index("method")
    col_pred = header.index("Pb_prediction")

    n_filled = 0
    for r in rows[1:]:
        sid, meth = r[col_id], r[col_method]
        p = preds.get((sid, meth))
        if p:
            try:
                r[col_pred] = f"{float(p):.1f}"
            except ValueError:
                r[col_pred] = p
            n_filled += 1

    with ASH.open("w", newline="", encoding="utf-8-sig") as f:
        csv.writer(f).writerows(rows)

    print(f"EFA_XRF_Ash.csv: filled Pb_prediction for {n_filled} of {len(rows)-1} rows")


# -----------------------------------------------------------------------------
# Build clay LOOCV predictions: ID -> (Pred_Pb_ppm, residual)
# -----------------------------------------------------------------------------

def load_clay_intensity_predictions():
    """Use the intensity-arm LOOCV prediction for each PBP standard
    (the same arm carried into ash validation)."""
    preds = {}
    with LOOCV.open(newline="") as f:
        for r in csv.DictReader(f):
            arm = r["arm"]
            if arm in ("pellet_intensity", "powder_intensity"):
                preds[r["sample_id"]] = (r["pred"], r["residual"])
    return preds


def fill_clay():
    preds = load_clay_intensity_predictions()
    with CLAY.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        rows = list(reader)
    header = rows[0]
    col_id = header.index("ID")
    col_pred = header.index("Pred_Pb_ppm")
    col_err  = header.index("Error")

    n_filled = 0
    for r in rows[1:]:
        sid = r[col_id]
        if sid in preds:
            p, e = preds[sid]
            try:
                r[col_pred] = f"{float(p):.1f}"
                r[col_err]  = f"{float(e):.1f}"
            except ValueError:
                r[col_pred] = p; r[col_err] = e
            n_filled += 1

    with CLAY.open("w", newline="", encoding="utf-8-sig") as f:
        csv.writer(f).writerows(rows)

    print(f"EFA_XRF_Clay_Metadata.csv: filled Pred_Pb_ppm + Error "
          f"for {n_filled} of {len(rows)-1} rows")


def main():
    fill_ash()
    fill_clay()


if __name__ == "__main__":
    main()
