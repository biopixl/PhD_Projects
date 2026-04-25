#!/usr/bin/env Rscript
# =============================================================================
# 07 — Manuscript figures and tables (4-arm)
# =============================================================================
# Final publication figures and the headline 4-arm comparison table.
#
# Inputs:
#   data/calibration/PBP_calibration_table.csv
#   data/calibration/calibration_models_4arms.csv
#   data/calibration/calibration_sweep_full.csv
#   data/validation/validation_paired.csv
#   data/validation/validation_summary_4arms.csv
#   results/Table_CV_summary.csv
#
# Outputs:
#   figures/Fig_calibration_4panel.{pdf,png}    (PBP fit per arm)
#   figures/Fig_validation_4panel.{pdf,png}     (XRF predicted vs ICP-MS truth)
#   results/Table3_4arm_calibration.csv         (manuscript Table 3)
#   results/Table4_threshold_classification.csv (manuscript Table 4)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

cal      <- read_csv(file.path(ROOT, "data/calibration/PBP_calibration_table.csv"),
                     show_col_types = FALSE)
arms     <- read_csv(file.path(ROOT, "data/calibration/calibration_models_4arms.csv"),
                     show_col_types = FALSE)
validate <- read_csv(file.path(ROOT, "data/validation/validation_paired.csv"),
                     show_col_types = FALSE)
val_sum  <- read_csv(file.path(ROOT, "data/validation/validation_summary_4arms.csv"),
                     show_col_types = FALSE)
val_thr  <- read_csv(file.path(ROOT, "data/validation/validation_thresholds_long.csv"),
                     show_col_types = FALSE)
cv_sum   <- read_csv(file.path(ROOT, "results/Table_CV_summary.csv"),
                     show_col_types = FALSE)

THRESHOLDS_PPM <- sort(unique(val_thr$threshold))

dir.create(file.path(ROOT, "figures"), showWarnings = FALSE)
dir.create(file.path(ROOT, "results"), showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Calibration figure: PBP standards × 4 arms
# -----------------------------------------------------------------------------

cal_panel <- function(arm_row) {
  m      <- arm_row$method
  cal_m  <- cal %>% filter(method == m)
  fmla   <- as.formula(paste("Known_Pb_ppm ~", arm_row$formula_rhs))
  fit    <- lm(fmla, data = cal_m)
  cal_m$pred <- predict(fit, newdata = cal_m)

  ggplot(cal_m, aes(Known_Pb_ppm, pred)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dotted", colour = "grey50") +
    geom_smooth(method = "lm", se = FALSE, colour = "steelblue", linewidth = 0.6) +
    geom_point(aes(colour = Series), size = 2.4) +
    labs(title = arm_row$arm,
         subtitle = sprintf("response = %s\nR² = %.3f, RMSE = %.1f ppm, n = %d",
                            arm_row$response, arm_row$r_squared, arm_row$RMSE_ppm,
                            arm_row$n),
         x = "Known Pb in PBP clay (ppm)", y = "Calibrated Pb prediction (ppm)",
         colour = "PBP series") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
}

cal_fig <- wrap_plots(map(seq_len(nrow(arms)), ~ cal_panel(arms[.x, ])),
                      ncol = 2) +
  plot_annotation(title = "Calibration: PBP clay standards (4 arms)",
                  theme = theme(plot.title = element_text(face = "bold", size = 13)))

ggsave(file.path(ROOT, "figures/Fig_calibration_4panel.pdf"),
       cal_fig, width = 11, height = 9)
ggsave(file.path(ROOT, "figures/Fig_calibration_4panel.png"),
       cal_fig, width = 11, height = 9, dpi = 300)

# -----------------------------------------------------------------------------
# Validation figure: predicted vs ICP-MS, 4 panels
# -----------------------------------------------------------------------------

val_panel <- function(arm_label) {
  d  <- validate %>% filter(arm == arm_label)
  s  <- val_sum  %>% filter(arm == arm_label)
  # Show all 6 regulatory thresholds as guide lines.
  ggplot(d, aes(Pb_icpms, predicted_Pb_ppm)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dotted", colour = "grey50") +
    geom_vline(xintercept = THRESHOLDS_PPM, colour = "tomato",
               linetype = "dashed", alpha = 0.4) +
    geom_hline(yintercept = THRESHOLDS_PPM, colour = "tomato",
               linetype = "dashed", alpha = 0.4) +
    geom_point(alpha = 0.75) +
    scale_x_log10() + scale_y_log10() +
    labs(title = arm_label,
         subtitle = sprintf(
           "r = %.3f, RMSE = %.0f ppm | BA bias = %.0f ppm, LOA [%.0f, %.0f] | n = %d",
           s$pearson_r, s$RMSE_ppm, s$BA_bias_ppm,
           s$BA_LOA_lo_ppm, s$BA_LOA_hi_ppm, s$n),
         x = "ICP-MS Pb (ppm, log)",
         y = "XRF-predicted Pb (ppm, log)") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 9))
}

val_fig <- wrap_plots(map(arms$arm, val_panel), ncol = 2) +
  plot_annotation(title = "Validation: XRF-predicted vs ICP-MS measured Pb",
                  theme = theme(plot.title = element_text(face = "bold", size = 13)))

ggsave(file.path(ROOT, "figures/Fig_validation_4panel.pdf"),
       val_fig, width = 11, height = 9)
ggsave(file.path(ROOT, "figures/Fig_validation_4panel.png"),
       val_fig, width = 11, height = 9, dpi = 300)

# -----------------------------------------------------------------------------
# Table 3: 4-arm calibration
# -----------------------------------------------------------------------------

table3 <- arms %>%
  left_join(cv_sum %>% select(arm, CV_RMSE, RMSE_inflation), by = "arm") %>%
  left_join(val_sum %>% select(arm, val_n = n,
                                val_r = pearson_r, val_RMSE = RMSE_ppm,
                                val_MAE = MAE_ppm,
                                BA_bias_ppm, BA_LOA_lo_ppm, BA_LOA_hi_ppm,
                                BA_LOA_range, BA_geom_ratio),
            by = "arm") %>%
  transmute(
    Arm = arm,
    Preparation = method,
    `Response type` = response_type,
    Response = response,
    n_cal = n,
    `Cal R²`         = round(r_squared, 3),
    `Cal RMSE (ppm)` = round(RMSE_ppm, 1),
    `LOOCV RMSE`     = round(CV_RMSE, 1),
    n_val            = val_n,
    `Val r`          = round(val_r, 3),
    `Val RMSE (ppm)` = round(val_RMSE, 0),
    `Val MAE (ppm)`  = round(val_MAE, 1),
    `BA bias (ppm)`  = round(BA_bias_ppm, 0),
    `BA LOA lo`      = round(BA_LOA_lo_ppm, 0),
    `BA LOA hi`      = round(BA_LOA_hi_ppm, 0),
    `BA LOA range`   = round(BA_LOA_range, 0),
    `BA geom ratio`  = round(BA_geom_ratio, 3)
  )
write_csv(table3, file.path(ROOT, "results/Table3_4arm_calibration.csv"))

# -----------------------------------------------------------------------------
# Table 4 — threshold classification at 80, 200, 320, 500, 800, 1000 ppm.
# Long format keeps the wide ICP-MS×prediction confusion compact while still
# letting the manuscript pick a presentation slice (e.g., wide for one prep
# method × 6 thresholds, or all 4 arms at one threshold).
# -----------------------------------------------------------------------------

table4_long <- val_thr %>%
  transmute(Arm = arm, Preparation = method,
            Threshold_ppm = threshold,
            Sensitivity = round(sens, 2),
            Specificity = round(spec, 2),
            Accuracy    = round(acc, 2)) %>%
  arrange(Preparation, Arm, Threshold_ppm)
write_csv(table4_long, file.path(ROOT, "results/Table4_threshold_classification.csv"))

# Also write a wide variant (one row per arm, columns sens_T/spec_T/acc_T per T)
# for compact presentation in the paper.
table4_wide <- val_sum %>%
  select(arm, method, n,
         starts_with("sens_"), starts_with("spec_"), starts_with("acc_")) %>%
  arrange(method, arm)
write_csv(table4_wide, file.path(ROOT, "results/Table4_threshold_classification_wide.csv"))

cat("=== 07 — Figures and tables ===\n")
cat("Tables:\n")
cat("  ", file.path(ROOT, "results/Table3_4arm_calibration.csv"), "\n")
cat("  ", file.path(ROOT, "results/Table4_threshold_classification.csv"), "(long)\n")
cat("  ", file.path(ROOT, "results/Table4_threshold_classification_wide.csv"), "(wide)\n")
cat("Figures:\n")
cat("  ", file.path(ROOT, "figures/Fig_calibration_4panel.{pdf,png}"), "\n")
cat("  ", file.path(ROOT, "figures/Fig_validation_4panel.{pdf,png}"), "\n")

cat("\n--- Table 3 (4-arm calibration with R² + RMSE + Bland-Altman) ---\n")
print(table3, n = Inf, width = 200)
cat("\n--- Table 4 (threshold classification, long) ---\n")
print(table4_long, n = Inf)
