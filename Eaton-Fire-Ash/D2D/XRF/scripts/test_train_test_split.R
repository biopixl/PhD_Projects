#!/usr/bin/env Rscript
# =============================================================================
# Compare matrix-correction validation strategies
# =============================================================================
# For each of the 4 canonical arms, evaluate three approaches to the
# ash-matrix correction step:
#
#   Strategy A — LOOCV (current default): refit slope leaving each sample out,
#                use that slope to correct that sample.
#   Strategy B — Single 67/33 holdout, repeated with N random seeds. Fit slope
#                on 2/3, evaluate on held-out 1/3. Stats reported as mean ± SD
#                across seeds.
#   Strategy C — 5-fold CV repeated with N random seeds.
#
# If B or C produces substantially lower RMSE than A, switch the headline
# pipeline to that strategy.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"
REPO <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D"
N_SEEDS <- 100
THRESHOLD_PPM <- 320  # representative regulatory threshold for sens/spec summary

ash_pred <- read_csv(file.path(ROOT, "data/validation/ash_predicted_Pb.csv"),
                     show_col_types = FALSE) %>%
  select(sample_id, method, arm, Pb_clay_pred)

icpms <- read_csv(file.path(REPO, "ICPMS/EFA_ICPMS_PPM.csv"),
                  show_col_types = FALSE) %>%
  select(sample_id = EFA.ID, Pb_icpms = Pb)

paired <- ash_pred %>%
  inner_join(icpms, by = "sample_id") %>%
  filter(!is.na(Pb_clay_pred), !is.na(Pb_icpms), Pb_clay_pred > 0)

prop_slope <- function(x, y) sum(x * y) / sum(x * x)

eval_metrics <- function(pred, truth, threshold = THRESHOLD_PPM) {
  resid   <- pred - truth
  ba_diff <- truth - pred
  TP <- sum(truth >  threshold & pred >  threshold)
  TN <- sum(truth <= threshold & pred <= threshold)
  FP <- sum(truth <= threshold & pred >  threshold)
  FN <- sum(truth >  threshold & pred <= threshold)
  list(
    n = length(pred),
    r = if (length(pred) > 1) cor(pred, truth) else NA_real_,
    RMSE = sqrt(mean(resid^2)),
    MAE  = mean(abs(resid)),
    bias = mean(resid),
    BA_bias = mean(ba_diff),
    BA_LOA_range = if (length(pred) > 1) 2 * 1.96 * sd(ba_diff) else NA_real_,
    sens = if (TP+FN>0) TP/(TP+FN) else NA_real_,
    spec = if (TN+FP>0) TN/(TN+FP) else NA_real_
  )
}

# -----------------------------------------------------------------------------
# Strategy A — LOOCV (deterministic, single-pass)
# -----------------------------------------------------------------------------
strategy_loocv <- function(d) {
  preds <- map_dbl(seq_len(nrow(d)), function(i) {
    s <- prop_slope(d$Pb_clay_pred[-i], d$Pb_icpms[-i])
    d$Pb_clay_pred[i] * s
  })
  eval_metrics(preds, d$Pb_icpms)
}

# -----------------------------------------------------------------------------
# Strategy B — single random 67/33 holdout, repeated
# -----------------------------------------------------------------------------
strategy_holdout <- function(d, frac = 1/3, n_seeds = N_SEEDS) {
  rs <- map_dfr(seq_len(n_seeds), function(seed) {
    set.seed(seed)
    n <- nrow(d); n_test <- max(round(n * frac), 5)
    test_idx <- sample.int(n, n_test)
    train <- d[-test_idx, ]; test <- d[test_idx, ]
    slope <- prop_slope(train$Pb_clay_pred, train$Pb_icpms)
    preds <- test$Pb_clay_pred * slope
    m <- eval_metrics(preds, test$Pb_icpms)
    as_tibble(m)
  })
  rs %>% summarise(across(everything(), list(mean = ~mean(.x, na.rm = TRUE),
                                              sd   = ~sd(.x, na.rm = TRUE)),
                          .names = "{.col}__{.fn}"))
}

# -----------------------------------------------------------------------------
# Strategy C — 5-fold CV, repeated
# -----------------------------------------------------------------------------
strategy_kfold <- function(d, k = 5, n_seeds = N_SEEDS) {
  rs <- map_dfr(seq_len(n_seeds), function(seed) {
    set.seed(seed)
    n <- nrow(d)
    folds <- sample(rep(seq_len(k), length.out = n))
    preds <- numeric(n)
    for (kk in seq_len(k)) {
      test_idx <- which(folds == kk)
      train <- d[-test_idx, ]
      slope <- prop_slope(train$Pb_clay_pred, train$Pb_icpms)
      preds[test_idx] <- d$Pb_clay_pred[test_idx] * slope
    }
    m <- eval_metrics(preds, d$Pb_icpms)
    as_tibble(m)
  })
  rs %>% summarise(across(everything(), list(mean = ~mean(.x, na.rm = TRUE),
                                              sd   = ~sd(.x, na.rm = TRUE)),
                          .names = "{.col}__{.fn}"))
}

# -----------------------------------------------------------------------------
# Run all strategies × 4 arms
# -----------------------------------------------------------------------------

results <- map_dfr(unique(paired$arm), function(a) {
  d <- paired %>% filter(arm == a)
  loo <- strategy_loocv(d)
  ho  <- strategy_holdout(d)
  kf  <- strategy_kfold(d)

  tibble(
    arm = a, n = nrow(d),
    LOOCV_RMSE   = loo$RMSE,   LOOCV_r        = loo$r,
    LOOCV_BA_bias = loo$BA_bias, LOOCV_BA_LOA_range = loo$BA_LOA_range,
    LOOCV_sens   = loo$sens,   LOOCV_spec     = loo$spec,
    Holdout_RMSE_mean = ho$RMSE__mean, Holdout_RMSE_sd = ho$RMSE__sd,
    Holdout_r_mean    = ho$r__mean,
    Holdout_BA_LOA_range_mean = ho$BA_LOA_range__mean,
    Holdout_sens_mean = ho$sens__mean,
    Kfold_RMSE_mean   = kf$RMSE__mean, Kfold_RMSE_sd    = kf$RMSE__sd,
    Kfold_r_mean      = kf$r__mean,
    Kfold_BA_LOA_range_mean = kf$BA_LOA_range__mean,
    Kfold_sens_mean   = kf$sens__mean
  )
})

write_csv(results,
          file.path(ROOT, "results/Table_validation_strategy_comparison.csv"))

cat("=== Validation strategy comparison ===\n")
cat("(", N_SEEDS, "random seeds for B and C)\n\n")
print(results %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))),
      n = Inf, width = 200)

cat("\nWritten:", file.path(ROOT, "results/Table_validation_strategy_comparison.csv"), "\n")
