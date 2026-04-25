#!/usr/bin/env Rscript
# =============================================================================
# Pipeline orchestrator — runs the full XRF calibration → validation pipeline.
#
# Order:
#   00_clean_xrf_raw_to_d2d.py   (Python; promotes Manuscript raw → D2D cleaned)
#   01_build_calibration_table.R (PBP standards table)
#   02_fit_calibrations.R        (sweep + 4-arm canonical models)
#   03_apply_to_ash.R            (predict Pb in ash for 4 arms)
#   04_validate_vs_icpms.R       (ash predictions vs ICP-MS)
#   05_bland_altman.R            (method-agreement, 4 panels)
#   06_cross_validation.R        (LOOCV on PBP standards)
#   07_figures_tables.R          (manuscript figures + Tables 3/4)
#
# 00 is run separately when manuscript raw exports refresh; the other steps
# regenerate cleanly from the cleaned/ directory each time.
# =============================================================================

SCRIPTS_DIR <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF/scripts"

steps <- c(
  "01_build_calibration_table.R",
  "02_fit_calibrations.R",
  "03_apply_to_ash.R",
  "04_validate_vs_icpms.R",
  "05_bland_altman.R",
  "06_cross_validation.R",
  "07_figures_tables.R"
)

for (s in steps) {
  cat("\n", strrep("=", 78), "\n", sep = "")
  cat("RUN: ", s, "\n", sep = "")
  cat(strrep("=", 78), "\n", sep = "")
  # local = new.env() isolates each step so its top-level constants
  # (notably ROOT) don't leak into the next.
  source(file.path(SCRIPTS_DIR, s), echo = FALSE, local = new.env())
}

cat("\n", strrep("=", 78), "\n", sep = "")
cat("Pipeline complete.\n")
cat(strrep("=", 78), "\n", sep = "")
