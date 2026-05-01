#!/usr/bin/env Rscript
# =============================================================================
# Pb-line sweep — empirical search over the 6 Pb L-lines in the Zenodo deposit
# =============================================================================
# For each preparation method (pellet, powder), fit candidate calibration
# models built from the six Pb L-lines included in EFA_XRF_Clay_Metadata.csv
# (Lα1, Lα2, Lβ1, Lβ2, Lβ3, Lβ4), apply each to ash, run the standard
# matrix-correction step (Cook's-D filtered, LOOCV slope), and validate
# against ICP-MS. The output table identifies the best response per arm.
#
# Inputs (from Zenodo deposit):
#   EFA_XRF_Clay_Metadata.csv  — calibration standards (6 Pb-line columns)
#   EFA_XRF_Ash.csv             — ash measurements (6 Pb-line columns)
#   EFA_ICPMS_PPM.csv           — ICP-MS Pb reference for validation
#
# Output:
#   results/Table_S3_pb_line_sweep.csv  — ranked candidates per method
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

ROOT    <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"
ZEN     <- file.path(ROOT, "data/zenodo")
RESULTS <- file.path(ROOT, "results")
dir.create(RESULTS, showWarnings = FALSE, recursive = TRUE)

clay <- read_csv(file.path(ZEN, "EFA_XRF_Clay_Metadata.csv"),
                 show_col_types = FALSE) %>% rename(ID = 1)
ash  <- read_csv(file.path(ZEN, "EFA_XRF_Ash.csv"),
                 show_col_types = FALSE) %>%
  rename(ID = 1) %>% select(-any_of(c("Pb_prediction", "")))
icpms <- read_csv(file.path(ZEN, "EFA_ICPMS_PPM.csv"),
                  show_col_types = FALSE) %>%
  select(ID = EFA.ID, Pb_icpms = Pb)

# Restrict to IDs with all three measurements (ICP-MS + pellet + powder)
# to keep the line-sweep validation set identical to the main-text pipeline.
pellet_ids   <- ash %>% filter(method == "pellet") %>% pull(ID) %>% unique()
powder_ids   <- ash %>% filter(method == "powder") %>% pull(ID) %>% unique()
fully_paired <- Reduce(intersect, list(icpms$ID, pellet_ids, powder_ids))
ash <- ash %>% filter(ID %in% fully_paired)

# Candidate response variables built from the 6 Pb L-lines in the deposit.
# Each entry has a label and an R formula RHS.
candidates <- tribble(
  ~label,                       ~rhs,                                       ~kind,
  "Pb_La1",                     "Pb_La1_cps",                                "single",
  "Pb_La2",                     "Pb_La2_cps",                                "single",
  "Pb_Lb1",                     "Pb_Lb1_cps",                                "single",
  "Pb_Lb2",                     "Pb_Lb2_cps",                                "single",
  "Pb_Lb3",                     "Pb_Lb3_cps",                                "single",
  "Pb_Lb4",                     "Pb_Lb4_cps",                                "single",
  "Pb_La1+Pb_La2 (sum)",        "I(Pb_La1_cps + Pb_La2_cps)",                "sum",
  "Pb_Lb1+Pb_Lb2 (sum)",        "I(Pb_Lb1_cps + Pb_Lb2_cps)",                "sum",
  "Pb_Lb1+Pb_Lb3 (sum)",        "I(Pb_Lb1_cps + Pb_Lb3_cps)",                "sum",
  "Pb_Lb1+Lb2+Lb3+Lb4 (sum)",   "I(Pb_Lb1_cps + Pb_Lb2_cps + Pb_Lb3_cps + Pb_Lb4_cps)", "sum",
  "Pb_Lb1, Pb_Lb2 (multi)",     "Pb_Lb1_cps + Pb_Lb2_cps",                   "multi",
  "Pb_Lb1, Pb_Lb3 (multi)",     "Pb_Lb1_cps + Pb_Lb3_cps",                   "multi"
)

prop_slope <- function(x, y) sum(x*y, na.rm = TRUE) / sum(x*x, na.rm = TRUE)

cooks_d_prop <- function(x, y) {
  b <- prop_slope(x, y); r <- y - b*x
  h <- x^2 / sum(x^2);  s2 <- sum(r^2) / max(length(r) - 1, 1)
  (r^2 * h) / ((1 - h)^2 * s2)
}

run_one <- function(meth, label, rhs, kind) {
  fmla <- as.formula(paste("Known_Pb_ppm ~", rhs))
  cal_m  <- clay %>% filter(method == meth) %>% drop_na(Known_Pb_ppm)
  cal_fit <- tryCatch(lm(fmla, data = cal_m), error = function(e) NULL)
  if (is.null(cal_fit)) return(NULL)
  cal_R2   <- summary(cal_fit)$r.squared
  cal_RMSE <- sqrt(mean(residuals(cal_fit)^2))

  ash_m <- ash %>% filter(method == meth)
  ash_m$Pb_clay <- predict(cal_fit, newdata = ash_m)

  pair <- ash_m %>% inner_join(icpms, by = "ID") %>%
    filter(!is.na(Pb_icpms), !is.na(Pb_clay), Pb_clay > 0)
  if (nrow(pair) < 5) return(NULL)

  pair$cooks_D <- cooks_d_prop(pair$Pb_clay, pair$Pb_icpms)
  pair$elig    <- pair$cooks_D <= 4 / nrow(pair)
  full_slope <- prop_slope(pair$Pb_clay[pair$elig], pair$Pb_icpms[pair$elig])
  pair$slope <- full_slope
  for (i in which(pair$elig)) {
    others <- which(pair$elig); others <- others[others != i]
    pair$slope[i] <- prop_slope(pair$Pb_clay[others], pair$Pb_icpms[others])
  }
  pair$Pb_pred <- pair$Pb_clay * pair$slope

  resid   <- pair$Pb_pred - pair$Pb_icpms
  ba_diff <- pair$Pb_icpms - pair$Pb_pred
  pearson <- cor(pair$Pb_pred, pair$Pb_icpms, use = "complete.obs")
  rmse    <- sqrt(mean(resid^2))
  ba_bias <- mean(ba_diff); ba_sd <- sd(ba_diff)

  tibble(
    method        = meth,
    response      = label,
    kind          = kind,
    n_clay        = nrow(cal_m),
    n_val         = nrow(pair),
    cal_R2        = cal_R2,
    cal_RMSE_ppm  = cal_RMSE,
    matrix_slope  = full_slope,
    val_pearson_r = pearson,
    val_RMSE_ppm  = rmse,
    BA_bias_ppm   = ba_bias,
    BA_LOA_range_ppm = 2 * 1.96 * ba_sd
  )
}

methods <- c("pellet", "powder")
ranked <- map_dfr(methods, function(m)
  pmap_dfr(candidates, function(label, rhs, kind) run_one(m, label, rhs, kind))
) %>% arrange(method, val_RMSE_ppm)

write_csv(ranked, file.path(RESULTS, "Table_S3_pb_line_sweep.csv"))

cat("=== Pb L-line sweep: 6 lines from the Zenodo deposit ===\n")
cat("(", nrow(ranked), "candidates; ranked per method by validation RMSE)\n\n")
print(ranked %>%
        select(method, response, kind, n_val, cal_R2, val_pearson_r,
               val_RMSE_ppm, BA_bias_ppm, BA_LOA_range_ppm) %>%
        mutate(across(where(is.numeric), ~ round(.x, 2))),
      n = Inf, width = 200)

cat("\n=== Best per method ===\n")
best <- ranked %>% group_by(method) %>% slice_min(val_RMSE_ppm, n = 1) %>% ungroup()
print(best %>%
        select(method, response, n_val, cal_R2, val_pearson_r,
               val_RMSE_ppm, BA_bias_ppm, BA_LOA_range_ppm) %>%
        mutate(across(where(is.numeric), ~ round(.x, 2))))

cat("\nWritten:", file.path(RESULTS, "Table_S3_pb_line_sweep.csv"), "\n")
