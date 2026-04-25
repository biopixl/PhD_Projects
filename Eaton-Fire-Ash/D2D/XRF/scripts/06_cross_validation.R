#!/usr/bin/env Rscript
# =============================================================================
# 06 — Leave-one-out cross-validation on calibration standards
# =============================================================================
# Honest assessment of prediction error on unseen samples by refitting each
# calibration arm with one standard held out at a time, then predicting that
# left-out point. Reports CV-RMSE per arm, vs. in-sample RMSE.
#
# CV is run on the PBP standards (the calibration data), not on ash. LOOCV on
# ash would only validate the ash-side regression of the previous (circular)
# pipeline; LOOCV on PBPs validates the actual calibration's generalization.
#
# Inputs:
#   data/calibration/PBP_calibration_table.csv
#   data/calibration/calibration_models_4arms.csv
#
# Outputs:
#   results/Table_CV_summary.csv
#   results/Table_LOOCV_predictions.csv
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

cal  <- read_csv(file.path(ROOT, "data/calibration/PBP_calibration_table.csv"),
                 show_col_types = FALSE)
arms <- read_csv(file.path(ROOT, "data/calibration/calibration_models_4arms.csv"),
                 show_col_types = FALSE)

loocv_one_arm <- function(arm_row, cal_data) {
  m       <- arm_row$method
  fmla    <- as.formula(paste("Known_Pb_ppm ~", arm_row$formula_rhs))
  cal_m   <- cal_data %>% filter(method == m) %>%
    drop_na(any_of(c("FP_value_ppm", "Pb_Lb1_cps", "Pb_Lb2_cps",
                     "Pb_Lb3_cps", "Pb_Lb4_cps", "Known_Pb_ppm")))

  preds <- map_dfr(seq_len(nrow(cal_m)), function(i) {
    fit_loo  <- lm(fmla, data = cal_m[-i, ])
    pred_loo <- predict(fit_loo, newdata = cal_m[i, , drop = FALSE])
    tibble(sample_id = cal_m$sample_id[i],
           Series    = cal_m$Series[i],
           Known     = cal_m$Known_Pb_ppm[i],
           pred      = as.numeric(pred_loo))
  }) %>% mutate(arm = arm_row$arm, method = m, .before = 1)
  preds
}

loocv <- map_dfr(seq_len(nrow(arms)), ~ loocv_one_arm(arms[.x, ], cal))
loocv <- loocv %>%
  mutate(residual = pred - Known,
         abs_resid = abs(residual))

write_csv(loocv, file.path(ROOT, "results/Table_LOOCV_predictions.csv"))

cv_summary <- loocv %>% group_by(arm, method) %>%
  summarise(n          = n(),
            CV_RMSE    = sqrt(mean(residual^2, na.rm = TRUE)),
            CV_MAE     = mean(abs_resid, na.rm = TRUE),
            CV_bias    = mean(residual, na.rm = TRUE),
            .groups = "drop") %>%
  left_join(arms %>% select(arm, in_sample_RMSE = RMSE_ppm,
                             in_sample_R2 = r_squared),
            by = "arm") %>%
  mutate(RMSE_inflation = CV_RMSE / in_sample_RMSE) %>%
  select(arm, method, n,
         in_sample_R2, in_sample_RMSE, CV_RMSE, CV_MAE, CV_bias,
         RMSE_inflation) %>%
  arrange(method, arm)

write_csv(cv_summary, file.path(ROOT, "results/Table_CV_summary.csv"))

cat("=== 06 — LOOCV summary on PBP standards ===\n")
print(cv_summary %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      n = Inf)
cat("\nWritten:\n")
cat("  ", file.path(ROOT, "results/Table_LOOCV_predictions.csv"), "\n")
cat("  ", file.path(ROOT, "results/Table_CV_summary.csv"), "\n")
