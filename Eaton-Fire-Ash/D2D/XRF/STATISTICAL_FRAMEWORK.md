# Statistical Framework: XRF Pb Prediction Pipeline

A walkthrough of the three-stage statistical workflow used to predict Pb in
Eaton Fire ash from benchtop XRF measurements, calibrated against ICP-MS
ground truth. Pipeline source: [eaton_xrf_pipeline.R](scripts/eaton_xrf_pipeline.R).

```
   ┌──────────┐   Stage A    ┌──────────┐   Stage B     ┌──────────┐   Stage C
   │  PBP     │──────────────▶│  ash      │──────────────▶│  ash      │─────────▶
   │  clay    │  fit a + b·X  │  Pb_clay  │  fit m·X      │  Pb_pred  │  metrics
   │  XRF     │  (linear lm)  │  predict  │  (proportional│  predict  │  + CIs
   │ (n=11/12)│               │  on ash   │   LOOCV w/    │  on ICP-MS│
   └──────────┘               └──────────┘   Cook's D)    └──────────┘
                              clay → ash    matrix bias    method agreement
                              transfer       correction     + threshold classification
```

The pipeline runs four arms in parallel:

| Method | Response variable | Use |
|---|---|---|
| pellet_intensity | Pb Lβ₁ + Lβ₂ multi-predictor | recommended primary screening |
| powder_intensity | Pb Lβ₁ + Lβ₃ multi-predictor | field-portable alternative |
| pellet_FP | instrument FP-derived ppm | comparison baseline |
| powder_FP | instrument FP-derived ppm | comparison baseline |

---

## Stage A — Clay calibration on PBP01–PBP04 standards

**Goal.** Convert a raw XRF response (counts/s on the chosen Pb L-line, or the
instrument's FP-derived ppm) into a first-pass Pb prediction in ppm units,
anchored to four kaolinite-clay standards spiked at 0, 100, 500, and 1000 ppm
Pb (3 replicate preparations each, except powder PBP04_1 excluded → n=11 for
powder calibrations, n=12 for pellet).

**Model.** Ordinary least-squares linear regression:

```
Pb_known = a + b · response   (lm in R)
```

**Diagnostics.**
- **Cal R²** — fraction of variance in known Pb explained by the response.
  All four arms exceed 0.91; intensity arms reach 0.99+.
- **Cal RMSE** — root-mean-square error on the calibration set itself
  (in-sample residuals).
- **LOOCV RMSE** — leave-one-out cross-validated RMSE: predict each PBP point
  from the remaining 10 or 11. Larger than cal RMSE because each fit has 1
  fewer point. Powder-intensity inflates from 98 to 361 ppm because the
  multi-predictor fit at n=11 is sensitive to leaving a single anchor out.

**Code.** [eaton_xrf_pipeline.R:103-108](scripts/eaton_xrf_pipeline.R#L103-L108) inside `run_arm()`.

---

## Stage B — Ash matrix correction (clay → ash transfer)

**Goal.** The clay calibration is anchored to a kaolinite matrix; ash has
different mass-attenuation properties and matrix elements. Stage A applied
to ash gives a biased prediction `Pb_clay`. Stage B fits a single
multiplicative factor that absorbs this systematic clay-to-ash bias.

**Model — proportional regression (no intercept).**

```
Pb_ICP-MS  =  m · Pb_clay        slope:  m̂ = Σ(x·y) / Σ(x²)
```

No intercept because Stage A already produced output in ppm units; any
remaining systematic offset is multiplicative (a function of the mass-
attenuation ratio between ash and clay), not additive. An intercept would
let the regression absorb noise that should not exist.

**Three robustness layers wrap this fit:**

### B.1 — Floor clipping (handle below-calibration extrapolation)

The linear Stage A regression has a slightly negative y-intercept; for ash
samples whose XRF response sits below PBP01 (the 100 ppm anchor), the
extrapolation crosses zero. Negative predicted Pb is physically impossible
and breaks the proportional fit. **Solution:** clip `Pb_clay = max(Pb_clay, 0)`
before fitting Stage B. Affected samples (e.g. XPAH58 at ICP-MS Pb = 14 ppm)
become predicted-zero rows; they contribute ratio = 0 to validation but do
not distort the slope (their leverage in proportional regression is x²/Σx² = 0).

Code: [eaton_xrf_pipeline.R:131-133](scripts/eaton_xrf_pipeline.R#L131-L133).

### B.2 — Cook's distance outlier filter (D > 4/n)

For each ash sample we compute Cook's D under the proportional model:

```
D_i  =  (r_i² · h_i)  /  ( (1 − h_i)² · σ̂² )
        with  h_i = x_i² / Σx²    leverage
              r_i = y_i − m̂·x_i  residual
              σ̂² = Σr² / (n − 1)  scale
```

Samples with D > 4/n (the conventional threshold) are excluded from slope
fitting only; they still appear in validation. **Why this matters:** sample
XPAH28 (ICP-MS Pb = 18,528 ppm — an order of magnitude above the next-highest
sample) has Cook's D between 360 and 600 across the four arms versus typical
D < 1. Without this filter, XPAH28 alone determines the slope; with it, two
or three samples are excluded per arm and the slope reflects the bulk of the
data.

Code: [eaton_xrf_pipeline.R:78-84, 137-138](scripts/eaton_xrf_pipeline.R#L78-L84).

### B.3 — Per-sample LOOCV slope

For each *eligible* (non-excluded) sample, we refit the slope leaving that
sample out of the fit but predicting it from the held-out slope. This avoids
in-sample optimism without sacrificing the small (n=33) validation set.

```
for i in eligible:
    others <- eligible \ {i}
    m_LOOCV[i]  <-  Σ(x_j·y_j) / Σ(x_j²)   for j in others
    Pb_pred[i]  <-  m_LOOCV[i] · Pb_clay[i]
```

Code: [eaton_xrf_pipeline.R:139-144](scripts/eaton_xrf_pipeline.R#L139-L144).

---

## Stage C — Validation against ICP-MS

Two complementary frameworks: **continuous-metric** (treats Pb as a quantity
to estimate) and **categorical** (treats Pb as a binary classification
relative to a regulatory threshold).

### C.1 — Continuous metrics (Table 3)

For each arm, on the 33 paired ash samples:

| Metric | Formula | Interprets |
|---|---|---|
| Pearson *r* | corr(Pb_pred, Pb_ICP-MS) | linear association strength |
| RMSE | √mean((Pb_pred − Pb_ICP-MS)²) | typical prediction error magnitude |
| MAE | mean(\|Pb_pred − Pb_ICP-MS\|) | median-like error (less sensitive to XPAH28) |
| BA bias | mean(Pb_ICP-MS − Pb_pred) | systematic over/under-prediction |
| BA 95% LOA | bias ± 1.96·SD(diff) | range that contains 95% of differences |
| LOA range | LOA_hi − LOA_lo | width of the agreement band |

The Bland–Altman framework¹ assesses *method interchangeability* — would XRF
substitute for ICP-MS in a clinical/regulatory decision? A small bias and a
narrow LOA range say yes; a wide LOA range says the methods cannot be used
interchangeably even if their correlation is high. **Pellet-intensity** has
the smallest LOA range (601 ppm), an order of magnitude tighter than the
FP arms (>6700 ppm).

Code: [eaton_xrf_pipeline.R:148-158](scripts/eaton_xrf_pipeline.R#L148-L158).

### C.2 — Threshold classification (Table 4)

For each combination of (arm × regulatory threshold), build the 2×2
confusion matrix:

```
                    Pb_pred > T    Pb_pred ≤ T
   Pb_ICP-MS > T  │     TP      │     FN     │   ← n_+ (positives)
   Pb_ICP-MS ≤ T  │     FP      │     TN     │   ← n_- (negatives)
```

From the confusion matrix:

```
sensitivity  =  TP / n_+      (true-positive rate; fraction of contaminated
                              samples correctly flagged)
specificity  =  TN / n_-      (true-negative rate; fraction of clean
                              samples correctly cleared)
accuracy     =  (TP+TN) / n   (overall correct fraction)
```

The six thresholds span the regulatory framework: 80 (DTSC residential),
200 (EPA RSL), 320 (CHHSL industrial), 500 (DTSC industrial), 800 (EPA
industrial), 1000 ppm (California TTLC).

#### Wilson 95% binomial confidence intervals

For a proportion `p̂ = k/n` (e.g., sensitivity), Wilson² gives:

```
                  p̂ + z²/(2n)  ±  z·√( p̂(1-p̂)/n  +  z²/(4n²) )
   CI_Wilson  =  ─────────────────────────────────────────────────
                              1 + z²/n
                                                      with z = 1.96
```

**Why Wilson, not normal-approximation Wald?** With n = 33 and only 2–11
positives at the higher thresholds, the Wald CI `p̂ ± 1.96·√(p̂(1-p̂)/n)`
collapses to zero width when `p̂ = 1.00` (no uncertainty reported, which is
nonsense) and underestimates uncertainty for extreme proportions in general.
Wilson handles small n and `p̂ → 0` or `→ 1` correctly; it never gives
zero-width CIs and stays bounded in [0, 1].

For `p̂ = 1.00` with n = 6 (sensitivity at 320 ppm): Wilson gives
`[0.61, 1.00]`, honestly reflecting that only 6 above-threshold samples
were observed and a ~40% chance some real sample-population sensitivity
below 1 would still produce 6/6 in a draw of 6.

Code: [eaton_xrf_pipeline.R:88-97, 100-117](scripts/eaton_xrf_pipeline.R#L88-L117).

### C.3 — Pooled cumulative summary (Table 5)

For each arm, sum the confusion-matrix counts across all six thresholds:

```
TP_pool  =  Σ_t  TP_arm,t        (across t ∈ {80, 200, 320, 500, 800, 1000})
n_+_pool =  Σ_t  n_+_t  =  34    sample-threshold pairs above threshold
n_-_pool =  Σ_t  n_-_t  =  164   sample-threshold pairs below threshold
```

This treats each sample-threshold pair as one independent classification
test (33 × 6 = 198 tests per arm) and yields a single sens/spec/acc per
method with much narrower Wilson CIs (n_+ = 34 instead of 2–11). The
pooled metric is the cleanest one-glance summary for comparing methods
across the regulatory range.

**Caveat.** Sample-threshold pairs are not strictly independent — a sample's
classification at 80 ppm is correlated with its classification at 200 ppm
because both depend on the same underlying Pb_pred. The pooled CIs are
therefore *anti-conservative* (slightly tighter than they should be); but
since the rank-ordering of methods is robust to this, the pooled summary is
useful for relative comparison even if the absolute CIs are an
over-confident.

Code: [eaton_xrf_pipeline.R:240-261](scripts/eaton_xrf_pipeline.R#L240-L261).

---

## Why these choices, in one sentence each

- **Two-stage calibration (clay → ash) instead of fitting ash directly.**
  Pulling the in-sample fit on ash would be circular; clay anchors give an
  independent calibration with known truth.
- **Proportional regression for Stage B.** Stage A already produces ppm units;
  the residual bias is multiplicative (matrix attenuation), not additive.
- **LOOCV instead of holdout.** Holdout estimates are seed-dependent because
  XPAH28's leverage dominates whichever partition contains it.
- **Cook's D > 4/n filter.** Standard convention; also empirically captures
  the two known leverage points (XPAH28, JPL73) without dropping legitimate
  high-Pb samples.
- **Floor-clipping at 0 instead of dropping.** Keeps the validation set at
  n=33 across all arms, which makes Tables 3, 4, 5 comparable; the alternative
  (drop below-calibration samples) is what we used previously and it created
  arm-dependent n_val values that confused readers.
- **Wilson 95% CI instead of Wald.** Wald is unreliable for n < 30 and for
  `p̂ → 0` or `→ 1`; Wilson is well-behaved at the boundaries.
- **Bland–Altman alongside Pearson r.** A high Pearson r does not imply
  method-interchangeability; the FP arms have r > 0.98 but LOA ranges of
  ~7000 ppm, which is unusable for screening.
- **Six regulatory thresholds, not one.** Different jurisdictions use
  different cut-offs; reporting at all six lets each reader find their
  jurisdiction's number.

## References

1. Bland JM, Altman DG. *Statistical methods for assessing agreement between
   two methods of clinical measurement.* Lancet. 1986;1(8476):307–10.
2. Wilson EB. *Probable inference, the law of succession, and statistical
   inference.* J Am Stat Assoc. 1927;22:209–212.
3. Cook RD. *Detection of influential observation in linear regression.*
   Technometrics. 1977;19(1):15–18.
