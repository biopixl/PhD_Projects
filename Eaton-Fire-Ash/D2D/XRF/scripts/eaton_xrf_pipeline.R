#!/usr/bin/env Rscript
# =============================================================================
# Eaton Fire WUI Ash — XRF Pb prediction pipeline (single file)
# =============================================================================
# Reads the Zenodo deposit and produces the manuscript figures and tables.
#
# Inputs (D2D/XRF/data/zenodo/):
#   EFA_XRF_Clay_Metadata.csv   PBP01–PBP04 calibration standards
#   EFA_XRF_Ash.csv             ash XRF measurements (intensities + FP)
#   EFA_ICPMS_PPM.csv           ICP-MS Pb reference for validation
#
# Outputs (D2D/XRF/results/ and figures/):
#   Table3_calibration_validation.csv   4-arm: clay calibration + ash matrix
#                                       correction + ICP-MS validation +
#                                       Bland-Altman bias and LOA
#   Table4_threshold_classification.csv 4 arms × 6 RSL thresholds × sens/spec/acc
#   Fig_calibration_4panel.{pdf,png}    PBP standards × 4 arms
#   Fig_validation_4panel.{pdf,png}     ash predicted vs ICP-MS, with thresholds
#   Fig_AgreementRatio_4panel.{pdf,png} XRF/ICP-MS ratio vs ICP-MS (log x)
#
# Methodology (configured below; see manuscript SI for derivation):
#   – Pellet-intensity:  Pb_Lb1_cps + Pb_Lb2_cps      (multi-predictor)
#   – Powder-intensity:  Pb_Lb1_cps + Pb_Lb3_cps      (multi-predictor)
#   – FP arms:           use the instrument's FP-derived Pb concentration
#   – Matrix correction: proportional regression Pb_icpms = m · Pb_clay_pred
#                        on paired ash, with Cook's distance > 4/n filtered
#                        and per-sample LOOCV slope.
#   – Thresholds:        80, 200, 320, 500, 800, 1000 ppm
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

ROOT       <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"
ZEN        <- file.path(ROOT, "data/zenodo")
RESULTS    <- file.path(ROOT, "results")
FIGURES    <- file.path(ROOT, "figures")
THRESHOLDS <- c(80, 200, 320, 500, 800, 1000)

dir.create(RESULTS, showWarnings = FALSE, recursive = TRUE)
dir.create(FIGURES, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# 0. Inputs
# -----------------------------------------------------------------------------

clay <- read_csv(file.path(ZEN, "EFA_XRF_Clay_Metadata.csv"),
                 show_col_types = FALSE) %>%
  rename(ID = 1)                                              # drop UTF-8 BOM
ash  <- read_csv(file.path(ZEN, "EFA_XRF_Ash.csv"),
                 show_col_types = FALSE) %>%
  rename(ID = 1) %>%
  select(-any_of(c("Pb_prediction", ""))) %>%                # we recompute it
  mutate(FP_value_ppm = Pb_FP_ppm)
icpms <- read_csv(file.path(ZEN, "EFA_ICPMS_PPM.csv"),
                  show_col_types = FALSE) %>%
  select(ID = EFA.ID, alq.type, Lat, Lon, Pb_icpms = Pb)

# Restrict the validation pipeline to IDs with all three measurements
# (ICP-MS + XRF pellet + XRF powder). Samples missing any one preparation are
# reported as opportunistic in the SI but not used to estimate calibration
# performance. The intersection includes one site (XPAH55) whose ICP-MS
# aliquot is labelled SOIL while its XRF pellet/powder were prepared from the
# co-located ash collection — both represent the same physical site and the
# same Pb concentration anchor at the low end of the calibration range.
pellet_ids    <- ash   %>% filter(method == "pellet") %>% pull(ID) %>% unique()
powder_ids    <- ash   %>% filter(method == "powder") %>% pull(ID) %>% unique()
fully_paired  <- Reduce(intersect, list(icpms$ID, pellet_ids, powder_ids))
ash           <- ash   %>% filter(ID %in% fully_paired)
icpms         <- icpms %>% filter(ID %in% fully_paired)

# Canonical 4 arms — ordered best-to-worst (pellet/powder intensity first,
# FP arms last) so all downstream tables and figures share a consistent order.
# The `label` column provides descriptive facet titles for figures.
arms <- tribble(
  ~arm,                ~method,  ~response_type, ~formula_rhs,                 ~label,
  "pellet_intensity",  "pellet", "Intensity",    "Pb_Lb1_cps + Pb_Lb2_cps",    "Pellet, Lβ1+Lβ2",

  "powder_intensity",  "powder", "Intensity",    "Pb_Lb1_cps + Pb_Lb3_cps",    "Powder, Lβ1+Lβ3",
  "pellet_FP",         "pellet", "FP",           "FP_value_ppm",               "Pellet, Fund. Param.",
  "powder_FP",         "powder", "FP",           "FP_value_ppm",               "Powder, Fund. Param."
)
# Named vector for facet labelling
arm_labels <- setNames(arms$label, arms$arm)

# -----------------------------------------------------------------------------
# 1. Helpers
# -----------------------------------------------------------------------------

# Proportional regression slope (no intercept): y = m · x
prop_slope <- function(x, y) sum(x * y, na.rm = TRUE) / sum(x * x, na.rm = TRUE)

# Cook's distance for proportional regression y = b·x.
cooks_d_prop <- function(x, y) {
  b   <- prop_slope(x, y)
  r   <- y - b * x
  h   <- x^2 / sum(x^2)
  s2  <- sum(r^2) / max(length(r) - 1, 1)
  (r^2 * h) / ((1 - h)^2 * s2)
}

# Wilson 95% confidence interval for a binomial proportion (k successes / n)
wilson_ci <- function(k, n, conf = 0.95) {
  if (is.na(n) || n == 0) return(c(lo = NA_real_, hi = NA_real_))
  z  <- qnorm(1 - (1 - conf) / 2)
  p  <- k / n
  d  <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / d
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  c(lo = max(0, ctr - hw), hi = min(1, ctr + hw))
}

# Threshold confusion matrix + sens/spec/acc + Wilson 95% CIs
class_metrics <- function(truth, pred, thr) {
  t <- truth > thr; p <- pred > thr
  TP <- sum(t & p, na.rm = TRUE);  TN <- sum(!t & !p, na.rm = TRUE)
  FP <- sum(!t & p, na.rm = TRUE); FN <- sum(t & !p, na.rm = TRUE)
  n_pos <- TP + FN; n_neg <- TN + FP; n_all <- TP + TN + FP + FN
  sens_ci <- wilson_ci(TP, n_pos)
  spec_ci <- wilson_ci(TN, n_neg)
  acc_ci  <- wilson_ci(TP + TN, n_all)
  list(TP = TP, TN = TN, FP = FP, FN = FN,
       n_pos = n_pos, n_neg = n_neg,
       sens = if (n_pos > 0) TP / n_pos else NA_real_,
       sens_lo = sens_ci["lo"], sens_hi = sens_ci["hi"],
       spec = if (n_neg > 0) TN / n_neg else NA_real_,
       spec_lo = spec_ci["lo"], spec_hi = spec_ci["hi"],
       acc  = (TP + TN) / max(n_all, 1),
       acc_lo = acc_ci["lo"], acc_hi = acc_ci["hi"])
}

# -----------------------------------------------------------------------------
# 2. Per-arm pipeline: calibrate → predict → matrix-correct (LOOCV) → validate
# -----------------------------------------------------------------------------

run_arm <- function(arm_row) {
  meth <- arm_row$method

  # Stage A — clay calibration on PBP standards
  clay_m  <- clay %>% filter(method == meth) %>% drop_na(Known_Pb_ppm)
  fmla    <- as.formula(paste("Known_Pb_ppm ~", arm_row$formula_rhs))
  cal_fit <- lm(fmla, data = clay_m)
  cal_R2  <- summary(cal_fit)$r.squared
  cal_RMSE <- sqrt(mean(residuals(cal_fit)^2))

  # Stage B — apply clay calibration to ash → naive matrix-naive prediction
  ash_m         <- ash %>% filter(method == meth)
  ash_m$Pb_clay <- predict(cal_fit, newdata = ash_m)

  # Pair with ICP-MS truth for matrix correction + validation. The clay
  # calibration's slight negative y-intercept can extrapolate to Pb_clay < 0
  # for ash samples below the PBP01 (100 ppm) calibration anchor. These
  # negative values are retained (not clipped) because: (1) they have

  # negligible impact on validation metrics, and (2) in proportional
  # regression samples with small |x| contribute minimal leverage.
  pair <- ash_m %>% inner_join(icpms %>% select(ID, Pb_icpms), by = "ID") %>%
    filter(!is.na(Pb_icpms), !is.na(Pb_clay))

  # Cook's D-filtered eligible set; then LOOCV slope per eligible row
  pair$cooks_D <- cooks_d_prop(pair$Pb_clay, pair$Pb_icpms)
  pair$elig    <- pair$cooks_D <= 4 / nrow(pair)
  full_slope <- prop_slope(pair$Pb_clay[pair$elig], pair$Pb_icpms[pair$elig])
  pair$slope <- full_slope
  for (i in which(pair$elig)) {
    others <- which(pair$elig); others <- others[others != i]
    pair$slope[i] <- prop_slope(pair$Pb_clay[others], pair$Pb_icpms[others])
  }
  pair$Pb_pred <- pair$Pb_clay * pair$slope

  # Stage C — validation metrics on the full paired set
  resid   <- pair$Pb_pred - pair$Pb_icpms
  ba_diff <- pair$Pb_icpms - pair$Pb_pred
  pearson <- cor(pair$Pb_pred, pair$Pb_icpms)
  rmse    <- sqrt(mean(resid^2))
  mae     <- mean(abs(resid))
  ba_bias <- mean(ba_diff); ba_sd <- sd(ba_diff)
  loa_lo  <- ba_bias - 1.96 * ba_sd
  loa_hi  <- ba_bias + 1.96 * ba_sd

  list(
    arm  = arm_row$arm,
    pair = pair %>% mutate(arm = arm_row$arm),
    clay = tibble(arm = arm_row$arm,
                  Series = clay_m$Series,
                  Known  = clay_m$Known_Pb_ppm,
                  Pred   = predict(cal_fit, newdata = clay_m)),
    summary = tibble(
      arm                 = arm_row$arm,
      method              = meth,
      response_type       = arm_row$response_type,
      response            = arm_row$formula_rhs,
      n_clay              = nrow(clay_m),
      cal_R2              = cal_R2,
      cal_RMSE_ppm        = cal_RMSE,
      n_excluded_outliers = sum(!pair$elig),
      matrix_slope        = full_slope,
      n_val               = nrow(pair),
      val_pearson_r       = pearson,
      val_R2              = pearson^2,
      val_RMSE_ppm        = rmse,
      val_MAE_ppm         = mae,
      BA_bias_ppm         = ba_bias,
      BA_LOA_lo_ppm       = loa_lo,
      BA_LOA_hi_ppm       = loa_hi,
      BA_LOA_range_ppm    = loa_hi - loa_lo
    )
  )
}

per_arm <- map(seq_len(nrow(arms)), ~ run_arm(arms[.x, ]))

# Stitch the per-arm results
summary_4arms <- map_dfr(per_arm, "summary")
clay_long     <- map_dfr(per_arm, "clay")
val_long      <- map_dfr(per_arm, "pair")

# -----------------------------------------------------------------------------
# 3. Threshold classification table (4 arms × 6 thresholds)
# -----------------------------------------------------------------------------

threshold_table <- map_dfr(THRESHOLDS, function(t) {
  val_long %>% group_by(arm) %>% group_modify(~ {
    m <- class_metrics(.x$Pb_icpms, .x$Pb_pred, t)
    tibble(threshold = t,
           TP = m$TP, FN = m$FN, FP = m$FP, TN = m$TN,
           n_pos = m$n_pos, n_neg = m$n_neg,
           sens = m$sens, sens_lo = m$sens_lo, sens_hi = m$sens_hi,
           spec = m$spec, spec_lo = m$spec_lo, spec_hi = m$spec_hi,
           acc  = m$acc,  acc_lo  = m$acc_lo,  acc_hi  = m$acc_hi)
  }) %>% ungroup()
}) %>% arrange(threshold, factor(arm, levels = arms$arm))

write_csv(summary_4arms,
          file.path(RESULTS, "Table3_calibration_validation.csv"))
write_csv(threshold_table,
          file.path(RESULTS, "Table4_threshold_classification.csv"))

# Cumulative per-arm classification across all 6 thresholds (pooled confusion
# matrix; one row per arm). Useful for a one-glance "how does each method
# classify across the regulatory range" summary alongside Table 3 / Table 4.
threshold_summary <- threshold_table %>%
  group_by(arm) %>%
  summarise(n_thresholds = n(),
            TP = sum(TP), FN = sum(FN), FP = sum(FP), TN = sum(TN),
            n_pos = sum(n_pos), n_neg = sum(n_neg),
            n_total = TP + FN + FP + TN,
            .groups = "drop") %>%
  rowwise() %>%
  mutate(sens = TP / n_pos,
         sens_lo = wilson_ci(TP, n_pos)["lo"],
         sens_hi = wilson_ci(TP, n_pos)["hi"],
         spec = TN / n_neg,
         spec_lo = wilson_ci(TN, n_neg)["lo"],
         spec_hi = wilson_ci(TN, n_neg)["hi"],
         acc  = (TP + TN) / n_total,
         acc_lo = wilson_ci(TP + TN, n_total)["lo"],
         acc_hi = wilson_ci(TP + TN, n_total)["hi"]) %>%
  ungroup() %>%
  arrange(factor(arm, levels = arms$arm))

write_csv(threshold_summary,
          file.path(RESULTS, "Table5_method_summary.csv"))

# -----------------------------------------------------------------------------
# 4. Figures (4 panels each)
# -----------------------------------------------------------------------------

# 4a. Calibration: known vs predicted Pb on PBP standards
fig_cal <- clay_long %>% mutate(arm = factor(arm, levels = arms$arm)) %>%
  ggplot(aes(Known, Pred, colour = Series)) +
  geom_abline(slope = 1, linetype = "dotted", colour = "grey50") +
  geom_smooth(method = "lm", se = FALSE, colour = "steelblue", linewidth = 0.6) +
  geom_point(size = 2.4) +
  facet_wrap(~ arm, ncol = 2, scales = "free", labeller = as_labeller(arm_labels)) +
  labs(x = "Known Pb in PBP clay (ppm)", y = "Calibrated Pb prediction (ppm)",
       title = "Stage A: clay calibration on PBP01–PBP04 standards") +
  theme_bw(base_size = 11)
ggsave(file.path(FIGURES, "Fig_calibration_4panel.pdf"), fig_cal, width = 11, height = 9)
ggsave(file.path(FIGURES, "Fig_calibration_4panel.png"), fig_cal, width = 11, height = 9, dpi = 300)

# Pellet vs powder colour palette used in Figs 4 and 5
prep_palette <- c(Pellet = "#7E3FA8", Powder = "#E07A1F")

# 4b. Validation: predicted vs ICP-MS (log-log). Coloured by preparation
# (pellet purple / powder orange); regulatory threshold reference lines
# omitted to keep the panel uncluttered (thresholds are reported in Table 4).
fig_val <- val_long %>%
  mutate(arm = factor(arm, levels = arms$arm),
         Preparation = ifelse(grepl("pellet", arm), "Pellet", "Powder")) %>%
  ggplot(aes(Pb_icpms, Pb_pred, colour = Preparation)) +
  geom_abline(slope = 1, linetype = "dotted", colour = "grey50") +
  geom_point(alpha = 0.85, size = 2) +
  scale_colour_manual(values = prep_palette) +
  scale_x_log10() + scale_y_log10() +
  facet_wrap(~ arm, ncol = 2, labeller = as_labeller(arm_labels)) +
  labs(x = "ICP-MS Pb (ppm, log)", y = "XRF-predicted Pb (ppm, log)",
       title = "Stage C: validation against ICP-MS gold standard") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(FIGURES, "Fig_validation_4panel.pdf"), fig_val, width = 11, height = 9)
ggsave(file.path(FIGURES, "Fig_validation_4panel.png"), fig_val, width = 11, height = 9, dpi = 300)

# 4c. Method-agreement ratio plot: XRF-predicted / ICP-MS vs ICP-MS (log x).
# Reference line at ratio = 1 (perfect agreement). Replaces the Bland-Altman
# difference-vs-mean plot for easier visual reading across the
# 14-18,528 ppm dynamic range. Below-calibration samples with negative Pb_pred
# will show negative ratios (1-2 samples per method).
fig_agr <- val_long %>%
  mutate(arm = factor(arm, levels = arms$arm),
         Preparation = ifelse(grepl("pellet", arm), "Pellet", "Powder"),
         ratio = Pb_pred / Pb_icpms) %>%
  ggplot(aes(Pb_icpms, ratio, colour = Preparation)) +
  geom_hline(yintercept = 1, linetype = "dotted", colour = "grey40") +
  geom_point(alpha = 0.85, size = 2) +
  scale_colour_manual(values = prep_palette) +
  scale_x_log10() +
  facet_wrap(~ arm, ncol = 2, scales = "free_y", labeller = as_labeller(arm_labels)) +
  labs(x = "ICP-MS Pb (ppm, log)",
       y = "XRF-predicted / ICP-MS (ratio)",
       title = "Method agreement: XRF/ICP-MS ratio vs ICP-MS reference") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(FIGURES, "Fig_AgreementRatio_4panel.pdf"), fig_agr, width = 11, height = 9)
ggsave(file.path(FIGURES, "Fig_AgreementRatio_4panel.png"), fig_agr, width = 11, height = 9, dpi = 300)

# -----------------------------------------------------------------------------
# 4d. Main text Figure 4: Pellet intensity 2-panel (scatter + Bland-Altman)
# -----------------------------------------------------------------------------

# Subset to pellet intensity only
pellet_val <- val_long %>% filter(arm == "pellet_intensity")

# Get Bland-Altman statistics for annotation
pellet_stats <- summary_4arms %>% filter(arm == "pellet_intensity")
ba_bias <- pellet_stats$BA_bias_ppm
ba_loa_lo <- pellet_stats$BA_LOA_lo_ppm
ba_loa_hi <- pellet_stats$BA_LOA_hi_ppm

# Panel a: XRF vs ICP-MS scatter (log-log)
p_scatter <- pellet_val %>%
  ggplot(aes(Pb_icpms, Pb_pred)) +
  geom_abline(slope = 1, linetype = "dashed", colour = "grey40", linewidth = 0.6) +
  geom_point(colour = "#7E3FA8", alpha = 0.85, size = 2.5) +
  scale_x_log10(labels = scales::comma) +
  scale_y_log10(labels = scales::comma) +
  labs(x = "ICP-MS Pb (ppm)", y = "XRF-predicted Pb (ppm)",
       tag = "a") +
  theme_bw(base_size = 11) +
  theme(plot.tag = element_text(face = "bold"))

# Panel b: Bland-Altman (difference vs mean) - full range with LOA labels
pellet_val <- pellet_val %>%
  mutate(ba_mean = (Pb_pred + Pb_icpms) / 2,
         ba_diff = Pb_pred - Pb_icpms)

# Calculate y-axis limits to include all points plus padding for labels
y_min <- min(c(pellet_val$ba_diff, ba_loa_lo)) - 100
y_max <- max(c(pellet_val$ba_diff, ba_loa_hi)) + 100

# Define zoom region for panel c (to draw inset box)
x_max_zoom <- 300
low_conc_data <- pellet_val %>% filter(ba_mean < x_max_zoom)
y_min_zoom <- min(low_conc_data$ba_diff) - 30
y_max_zoom <- max(low_conc_data$ba_diff) + 30

p_ba <- pellet_val %>%
  ggplot(aes(ba_mean, ba_diff)) +
  geom_hline(yintercept = 0, linetype = "solid", colour = "grey60", linewidth = 0.4) +
  geom_hline(yintercept = ba_bias, linetype = "dashed", colour = "steelblue", linewidth = 0.6) +
  geom_hline(yintercept = ba_loa_lo, linetype = "dotted", colour = "firebrick", linewidth = 0.6) +
  geom_hline(yintercept = ba_loa_hi, linetype = "dotted", colour = "firebrick", linewidth = 0.6) +
  geom_point(colour = "#7E3FA8", alpha = 0.85, size = 2.5) +
  # Inset box showing panel c region (drawn after points so it's on top)
  annotate("rect", xmin = 10, xmax = x_max_zoom,
           ymin = y_min_zoom, ymax = y_max_zoom,
           fill = NA, colour = "black", linetype = "dashed", linewidth = 0.7) +
  annotate("text", x = 150, y = y_max_zoom + 35, label = "c", fontface = "bold", size = 3) +
  scale_x_log10(labels = scales::comma) +
  scale_y_continuous(limits = c(y_min, y_max)) +
  annotate("text", x = max(pellet_val$ba_mean) * 0.12, y = ba_bias + 30,
           label = sprintf("Bias = %.0f ppm", ba_bias), hjust = 0, size = 2.8,
           colour = "steelblue") +
  annotate("text", x = max(pellet_val$ba_mean) * 0.12, y = ba_loa_hi + 30,
           label = sprintf("+1.96 SD = %.0f ppm", ba_loa_hi), hjust = 0, size = 2.8,
           colour = "firebrick") +
  annotate("text", x = max(pellet_val$ba_mean) * 0.12, y = ba_loa_lo - 30,
           label = sprintf("-1.96 SD = %.0f ppm", ba_loa_lo), hjust = 0, size = 2.8,
           colour = "firebrick") +
  labs(x = "Mean of XRF and ICP-MS (ppm)", y = "XRF − ICP-MS (ppm)",
       tag = "b") +
  theme_bw(base_size = 10) +
  theme(plot.tag = element_text(face = "bold"))

# Panel c: Bland-Altman zoomed to lower concentrations (<500 ppm mean)
# Y-axis zoomed to show actual spread of low-concentration samples

p_ba_zoom <- low_conc_data %>%
  ggplot(aes(ba_mean, ba_diff)) +
  geom_hline(yintercept = 0, linetype = "solid", colour = "grey60", linewidth = 0.4) +
  geom_hline(yintercept = ba_bias, linetype = "dashed", colour = "steelblue", linewidth = 0.6) +
  geom_point(colour = "#7E3FA8", alpha = 0.85, size = 2.5) +
  scale_x_continuous(labels = scales::comma, limits = c(0, x_max_zoom)) +
  scale_y_continuous(limits = c(y_min_zoom, y_max_zoom)) +
  labs(x = "Mean of XRF and ICP-MS (ppm)", y = "XRF − ICP-MS (ppm)",
       tag = "c") +
  theme_bw(base_size = 10) +
  theme(plot.tag = element_text(face = "bold"))

# Combine into 3-panel figure: a tall on left, b/c stacked on right
fig_pellet_3panel <- p_scatter + (p_ba / p_ba_zoom) + plot_layout(widths = c(1, 1))

ggsave(file.path(FIGURES, "Fig_validation_pellet_3panel.pdf"), fig_pellet_3panel, width = 10, height = 6)
ggsave(file.path(FIGURES, "Fig_validation_pellet_3panel.png"), fig_pellet_3panel, width = 10, height = 6, dpi = 300)

# Also copy to manuscript figures directory
MANUSCRIPT_FIGS <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs"
dir.create(MANUSCRIPT_FIGS, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(MANUSCRIPT_FIGS, "Fig_validation_pellet_3panel.png"), fig_pellet_3panel, width = 10, height = 6, dpi = 300)

# -----------------------------------------------------------------------------
# 5. Console summary
# -----------------------------------------------------------------------------

cat("=== Eaton Fire XRF pipeline complete ===\n\n")
cat("Calibration + validation summary (4 arms):\n")
print(summary_4arms %>% select(arm, n_val, cal_R2, cal_RMSE_ppm,
                               matrix_slope, val_pearson_r, val_RMSE_ppm,
                               BA_bias_ppm, BA_LOA_range_ppm) %>%
        mutate(across(where(is.numeric), ~ round(.x, 2))))
cat("\nThreshold classification at 320, 800, 1000 ppm (point + Wilson 95% CI):\n")
print(threshold_table %>%
        filter(threshold %in% c(320, 800, 1000)) %>%
        select(threshold, arm, TP, FN, FP, TN,
               sens, sens_lo, sens_hi, spec, spec_lo, spec_hi) %>%
        mutate(across(where(is.numeric), ~ round(.x, 2))))
cat("\nMethod summary (pooled across 6 thresholds, Wilson 95% CIs):\n")
print(threshold_summary %>%
        select(arm, TP, FN, FP, TN, sens, sens_lo, sens_hi,
               spec, spec_lo, spec_hi, acc) %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))))

cat("\nWritten:\n")
cat("  ", file.path(RESULTS, "Table3_calibration_validation.csv"), "\n")
cat("  ", file.path(RESULTS, "Table4_threshold_classification.csv"), "\n")
cat("  ", file.path(RESULTS, "Table5_method_summary.csv"), "\n")
cat("  ", file.path(FIGURES, "Fig_calibration_4panel.{pdf,png}"), "\n")
cat("  ", file.path(FIGURES, "Fig_validation_4panel.{pdf,png}"), "\n")
cat("  ", file.path(FIGURES, "Fig_AgreementRatio_4panel.{pdf,png}"), "\n")
cat("  ", file.path(FIGURES, "Fig_validation_pellet_2panel.{pdf,png}"), " [MAIN TEXT]\n")
cat("  ", file.path(MANUSCRIPT_FIGS, "Fig_validation_pellet_2panel.png"), "\n")
