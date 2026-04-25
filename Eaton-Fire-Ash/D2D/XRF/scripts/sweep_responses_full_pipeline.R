#!/usr/bin/env Rscript
# =============================================================================
# Sweep — full pipeline (clay cal → ash-matrix correction → validation)
# =============================================================================
# Runs the entire prediction pipeline for each candidate intensity response
# and ranks by VALIDATION performance against ICP-MS, not by calibration R².
# Includes Pb_Lα1 (the traditional canonical line) so we can test whether the
# As Kα interference cost outweighs the SNR advantage over Pb_Lβ.
#
# Outputs:
#   results/response_sweep_validation.csv  (full ranked table)
#
# Not part of run_all.R — this is exploratory; once a winner is locked in,
# update scripts 02–07 to use it.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"
REPO <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D"
THRESHOLDS_PPM <- c(80, 200, 320, 500, 800, 1000)

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

cal      <- read_csv(file.path(ROOT, "data/calibration/PBP_calibration_table.csv"),
                     show_col_types = FALSE)
elements <- read_csv(file.path(ROOT, "data/cleaned/XRF_elements_clean.csv"),
                     show_col_types = FALSE)
pb_lines <- read_csv(file.path(ROOT, "data/cleaned/XRF-Pb_clean.csv"),
                     show_col_types = FALSE)
icpms    <- read_csv(file.path(REPO, "ICPMS/EFA_ICPMS_PPM.csv"),
                     show_col_types = FALSE) %>%
  select(sample_id = EFA.ID, Pb_icpms = Pb)

# Ash response wide table — pull Pb_La1, Pb_La2 and the four Pb_Lβ lines.
ash_intens <- pb_lines %>%
  filter(!str_starts(sample_id, "PBP"),
         line_symbol %in% c("Pb_La1", "Pb_La2",
                            "Pb_Lb1", "Pb_Lb2", "Pb_Lb3", "Pb_Lb4")) %>%
  group_by(sample_id, method, line_symbol) %>%
  summarise(cts_per_s = mean(cts_per_s, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = line_symbol, values_from = cts_per_s,
              names_glue = "{line_symbol}_cps")

ash_fp <- elements %>%
  filter(!str_starts(sample_id, "PBP"), element == "Pb") %>%
  mutate(unit = if_else(unit == "wt_%", "%", unit),
         FP_value_ppm = case_when(unit == "%"   ~ value * 1e4,
                                  unit == "ppm" ~ value, TRUE ~ NA_real_)) %>%
  group_by(sample_id, method) %>%
  summarise(FP_value_ppm = mean(FP_value_ppm, na.rm = TRUE), .groups = "drop")

ash <- ash_fp %>% full_join(ash_intens, by = c("sample_id", "method"))

# -----------------------------------------------------------------------------
# Candidate responses (re-includes Pb_Lα1 family even though it overlaps As Kα,
# so we can empirically test whether the interference cost outweighs the SNR
# advantage from Lα being the most intense Pb line).
# -----------------------------------------------------------------------------

candidates <- tribble(
  ~label,                    ~rhs,                                       ~kind,
  "FP_concentration",         "I(FP_value_ppm)",                          "FP",
  "Pb_La1",                   "I(Pb_La1_cps)",                            "single",
  "Pb_La2",                   "I(Pb_La2_cps)",                            "single",
  "Pb_La1+La2",               "I(Pb_La1_cps + Pb_La2_cps)",               "sum",
  "Pb_Lb1",                   "I(Pb_Lb1_cps)",                            "single",
  "Pb_Lb2",                   "I(Pb_Lb2_cps)",                            "single",
  "Pb_Lb3",                   "I(Pb_Lb3_cps)",                            "single",
  "Pb_Lb4",                   "I(Pb_Lb4_cps)",                            "single",
  "Pb_Lb1+Lb2",               "I(Pb_Lb1_cps + Pb_Lb2_cps)",               "sum",
  "Pb_Lb1+Lb3",               "I(Pb_Lb1_cps + Pb_Lb3_cps)",               "sum",
  "Pb_Lb1+Lb2+Lb3+Lb4",       "I(Pb_Lb1_cps + Pb_Lb2_cps + Pb_Lb3_cps + Pb_Lb4_cps)", "sum",
  "Pb_Lb1,Lb2 (multi)",       "Pb_Lb1_cps + Pb_Lb2_cps",                  "multi",
  "Pb_Lb1,Lb3 (multi)",       "Pb_Lb1_cps + Pb_Lb3_cps",                  "multi"
)

# -----------------------------------------------------------------------------
# One configuration end-to-end
# -----------------------------------------------------------------------------

prop_slope <- function(x, y) sum(x * y, na.rm = TRUE) / sum(x * x, na.rm = TRUE)

run_one <- function(method_label, label, rhs, kind) {
  cal_m <- cal %>% filter(method == method_label)
  ash_m <- ash %>% filter(method == method_label)

  fmla <- as.formula(paste("Known_Pb_ppm ~", rhs))

  # Stage A — clay calibration
  clay_fit <- tryCatch(lm(fmla, data = cal_m), error = function(e) NULL)
  if (is.null(clay_fit)) return(NULL)
  cal_R2  <- summary(clay_fit)$r.squared
  cal_RMSE <- sqrt(mean(residuals(clay_fit)^2))

  # Apply clay calibration to ash → Pb_clay_pred
  ash_m$Pb_clay_pred <- predict(clay_fit, newdata = ash_m)

  # Join ICP-MS for matrix correction + validation
  pair <- ash_m %>% inner_join(icpms, by = "sample_id") %>%
    filter(!is.na(Pb_clay_pred), !is.na(Pb_icpms), Pb_clay_pred > 0)
  if (nrow(pair) < 5) return(NULL)

  # Stage B — matrix correction, LOOCV slope per sample
  loo_slope <- map_dbl(seq_len(nrow(pair)), function(i) {
    di <- pair[-i, ]
    prop_slope(di$Pb_clay_pred, di$Pb_icpms)
  })
  full_slope <- prop_slope(pair$Pb_clay_pred, pair$Pb_icpms)
  pair$matrix_slope <- loo_slope
  pair$predicted_Pb_ppm <- pair$Pb_clay_pred * pair$matrix_slope

  # Stage C — validation stats: correlation, Bland-Altman, threshold classification
  resid    <- pair$predicted_Pb_ppm - pair$Pb_icpms
  ba_diff  <- pair$Pb_icpms - pair$predicted_Pb_ppm  # ICP-MS minus XRF
  ba_mean  <- (pair$Pb_icpms + pair$predicted_Pb_ppm) / 2
  cls <- function(t, p) {
    TP <- sum(t & p); TN <- sum(!t & !p); FP <- sum(!t & p); FN <- sum(t & !p)
    list(sens = if (TP+FN>0) TP/(TP+FN) else NA_real_,
         spec = if (TN+FP>0) TN/(TN+FP) else NA_real_,
         acc  = (TP+TN)/max(TP+TN+FP+FN,1))
  }
  thr_metrics <- map_dfc(THRESHOLDS_PPM, function(t) {
    m <- cls(pair$Pb_icpms > t, pair$predicted_Pb_ppm > t)
    tibble(!!paste0("sens_", t) := m$sens,
           !!paste0("spec_", t) := m$spec,
           !!paste0("acc_",  t) := m$acc)
  })

  base <- tibble(
    method            = method_label,
    response          = label,
    kind              = kind,
    n_paired          = nrow(pair),
    cal_R2            = cal_R2,
    cal_RMSE          = cal_RMSE,
    matrix_slope_full = full_slope,
    matrix_slope_loo_sd = sd(loo_slope),
    val_pearson_r     = cor(pair$predicted_Pb_ppm, pair$Pb_icpms, use = "complete.obs"),
    val_R2            = val_pearson_r^2,
    val_RMSE          = sqrt(mean(resid^2)),
    val_MAE           = mean(abs(resid)),
    val_bias          = mean(resid),
    BA_bias_ppm       = mean(ba_diff),
    BA_LOA_lo_ppm     = mean(ba_diff) - 1.96 * sd(ba_diff),
    BA_LOA_hi_ppm     = mean(ba_diff) + 1.96 * sd(ba_diff),
    BA_LOA_range_ppm  = 2 * 1.96 * sd(ba_diff)
  )
  bind_cols(base, thr_metrics)
}

methods_to_test <- c("pellet", "powder")

sweep_results <- map_dfr(methods_to_test, function(meth) {
  pmap_dfr(candidates, function(label, rhs, kind)
    run_one(meth, label, rhs, kind))
})

# -----------------------------------------------------------------------------
# Rank
# -----------------------------------------------------------------------------

ranked <- sweep_results %>% arrange(method, val_RMSE)

write_csv(ranked, file.path(ROOT, "results/response_sweep_validation.csv"))

cat("=== Full-pipeline response sweep (ranked by val_RMSE) ===\n")
cat("[R²/RMSE summarised — full BA + per-threshold metrics in CSV]\n")
print(ranked %>%
        select(method, response, kind, n_paired, cal_R2, val_pearson_r,
               val_RMSE, val_MAE, BA_bias_ppm, BA_LOA_range_ppm,
               sens_320, sens_500, sens_1000) %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      n = Inf, width = 200)

cat("\n=== Best per method (lowest val_RMSE) — with BA stats ===\n")
best <- ranked %>% group_by(method) %>% slice_min(val_RMSE, n = 1) %>% ungroup()
print(best %>%
        select(method, response, n_paired, cal_R2, val_pearson_r,
               val_RMSE, val_MAE, BA_bias_ppm, BA_LOA_lo_ppm, BA_LOA_hi_ppm,
               BA_LOA_range_ppm) %>%
        mutate(across(where(is.numeric), ~ round(.x, 1))),
      width = 200)

cat("\nWritten:", file.path(ROOT, "results/response_sweep_validation.csv"), "\n")
