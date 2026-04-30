#!/usr/bin/env Rscript
# =============================================================================
# 01 — Build calibration table from cleaned XRF data
# =============================================================================
# Purpose: produce one publication-ready row per PBP standard × prep method,
# carrying Known_Pb_ppm and every candidate response variable the calibration
# sweep needs (FP-derived ppm + each clean Pb Lβ line intensity).
#
# Inputs (from data/cleaned/):
#   - xrf_concentrations.csv  (FP-derived element concentrations, long)
#   - xrf_intensities.csv     (per-line Pb intensities, long)
#
# Output:
#   - data/calibration/PBP_calibration_table.csv
#
# Replaces the hand-curated PBP_calibration_detailed.csv (which had a copy
# error in PBP04_pellet_A and only carried Pb_Lα1 intensity).
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

# Known Pb concentration of each PBP clay calibration series.
PBP_KNOWN_PPM <- c(PBP01 = 100, PBP02 = 500, PBP03 = 1000, PBP04 = 0)

elements <- read_csv(file.path(ROOT, "data/cleaned/xrf_concentrations.csv"),
                     show_col_types = FALSE, na = "NA")
pb_lines <- read_csv(file.path(ROOT, "data/cleaned/xrf_intensities.csv"),
                     show_col_types = FALSE, na = "NA")

# FP-derived Pb concentration per PBP sample×method, in ppm.
# unit can be "%" or "ppm"; convert "%" -> ppm. Also normalize "wt_%" -> "%".
fp <- elements %>%
  filter(str_starts(sample_id, "PBP"), element == "Pb") %>%
  mutate(
    unit = if_else(unit == "wt_%", "%", unit),
    FP_value_ppm = case_when(
      unit == "%"   ~ value * 1e4,
      unit == "ppm" ~ value,
      TRUE          ~ NA_real_
    ),
    FP_value_err_ppm = case_when(
      unit == "%"   ~ value_err * 1e4,
      unit == "ppm" ~ value_err,
      TRUE          ~ NA_real_
    )
  ) %>%
  select(sample_id, method, FP_value_ppm, FP_value_err_ppm)

# Pivot Pb line intensities to wide. Keep Lα1 for reference (excluded from
# fitting due to As Kα interference at 10.543 keV) plus the four clean Lβ
# lines used as calibration response candidates.
intensities <- pb_lines %>%
  filter(str_starts(sample_id, "PBP"),
         line_symbol %in% c("Pb_La1", "Pb_Lb1", "Pb_Lb2", "Pb_Lb3", "Pb_Lb4")) %>%
  select(sample_id, method, line_symbol, intensity_cps, intensity_err_cps) %>%
  pivot_wider(
    names_from  = line_symbol,
    values_from = c(intensity_cps, intensity_err_cps),
    names_glue  = "{line_symbol}_{.value}"
  ) %>%
  rename_with(~ str_replace(.x, "_intensity_cps$",     "_cps")) %>%
  rename_with(~ str_replace(.x, "_intensity_err_cps$", "_err"))

# Series label and known concentration come from the sample_id stem.
calibration_table <- fp %>%
  full_join(intensities, by = c("sample_id", "method")) %>%
  mutate(
    Series       = str_extract(sample_id, "^PBP\\d+"),
    Known_Pb_ppm = PBP_KNOWN_PPM[Series]
  ) %>%
  select(sample_id, method, Series, Known_Pb_ppm,
         FP_value_ppm, FP_value_err_ppm,
         Pb_La1_cps, Pb_La1_err,
         Pb_Lb1_cps, Pb_Lb1_err,
         Pb_Lb2_cps, Pb_Lb2_err,
         Pb_Lb3_cps, Pb_Lb3_err,
         Pb_Lb4_cps, Pb_Lb4_err) %>%
  arrange(method, Series, sample_id)

out_path <- file.path(ROOT, "data/calibration/PBP_calibration_table.csv")
write_csv(calibration_table, out_path)

cat("=== 01 — PBP calibration table ===\n")
cat("Rows:", nrow(calibration_table), "\n")
cat("Per method:\n")
print(count(calibration_table, method))
cat("Per series × method:\n")
print(count(calibration_table, Series, method))

# Surface any rows missing the canonical responses so the next stage knows
# which standards drop out of which model.
missing_summary <- calibration_table %>%
  mutate(across(c(FP_value_ppm, Pb_Lb1_cps, Pb_Lb2_cps, Pb_Lb3_cps, Pb_Lb4_cps),
                is.na, .names = "miss_{.col}")) %>%
  filter(if_any(starts_with("miss_"))) %>%
  select(sample_id, method, Series, Known_Pb_ppm,
         FP_value_ppm, Pb_Lb1_cps, Pb_Lb2_cps, Pb_Lb3_cps, Pb_Lb4_cps)

if (nrow(missing_summary)) {
  cat("\nStandards with at least one missing response (drop from that arm):\n")
  print(missing_summary)
} else {
  cat("\nAll standards complete on every response.\n")
}

cat("\nWritten:", out_path, "\n")
