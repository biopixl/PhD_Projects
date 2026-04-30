#!/usr/bin/env Rscript
# =============================================================================
# 05 — Bland-Altman figure (4-arm)
# =============================================================================
# BA stats are computed inside script 04 so they're part of the canonical
# validation_summary_4arms.csv. This script only renders the 4-panel B-A
# agreement figure using those precomputed stats and the per-row residuals
# already in validation_paired.csv.
#
# Inputs:
#   data/validation/validation_paired.csv         (per-row ba_diff, ba_mean)
#   data/validation/validation_summary_4arms.csv  (per-arm bias and LOA)
#
# Outputs:
#   figures/Fig_BlandAltman_4panel.{pdf,png}
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

paired  <- read_csv(file.path(ROOT, "data/validation/validation_paired.csv"),
                    show_col_types = FALSE)
summary <- read_csv(file.path(ROOT, "data/validation/validation_summary_4arms.csv"),
                    show_col_types = FALSE)

ba_panel <- function(arm_label) {
  d <- paired  %>% filter(arm == arm_label)
  s <- summary %>% filter(arm == arm_label)

  ggplot(d, aes(ba_mean, ba_diff)) +
    geom_hline(yintercept = 0, linetype = "dotted", colour = "grey40") +
    geom_hline(yintercept = s$BA_bias_ppm, colour = "steelblue", linewidth = 0.6) +
    geom_hline(yintercept = c(s$BA_LOA_lo_ppm, s$BA_LOA_hi_ppm),
               colour = "tomato", linetype = "dashed") +
    geom_point(alpha = 0.75) +
    labs(title = arm_label,
         subtitle = sprintf("n=%d, bias=%.0f ppm, LOA [%.0f, %.0f]",
                            s$n, s$BA_bias_ppm, s$BA_LOA_lo_ppm, s$BA_LOA_hi_ppm),
         x = "Mean of ICP-MS and XRF-predicted (ppm)",
         y = "ICP-MS − XRF-predicted (ppm)") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
}

fig <- wrap_plots(map(unique(summary$arm), ba_panel), ncol = 2) +
  plot_annotation(title = "Bland-Altman method agreement (XRF-predicted Pb vs ICP-MS)",
                  theme = theme(plot.title = element_text(face = "bold", size = 13)))

dir.create(file.path(ROOT, "figures"), showWarnings = FALSE)
ggsave(file.path(ROOT, "figures/Fig_BlandAltman_4panel.pdf"),
       fig, width = 11, height = 9)
ggsave(file.path(ROOT, "figures/Fig_BlandAltman_4panel.png"),
       fig, width = 11, height = 9, dpi = 300)

cat("=== 05 — Bland-Altman figure ===\n")
cat("BA stats live in validation_summary_4arms.csv (computed in script 04).\n")
cat("Written:\n")
cat("  ", file.path(ROOT, "figures/Fig_BlandAltman_4panel.{pdf,png}"), "\n")
