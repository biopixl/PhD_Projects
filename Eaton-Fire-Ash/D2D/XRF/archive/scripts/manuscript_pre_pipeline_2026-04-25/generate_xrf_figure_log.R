#!/usr/bin/env Rscript
# Generate XRF Calibration Figure - Log Scale Style
# Fixes: Bold Panel B title, add counts/sec to x-axis

library(tidyverse)
library(patchwork)

# Load data
df <- read_csv(

  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/harmonized_xrf_icpms_Lb_paired.csv",
  show_col_types = FALSE
)

# Calculate cumulative L-line intensity
df <- df %>%
  mutate(Pb_L_total = Pb_La1_cts + Pb_Lb1_cts + Pb_Lb2_cts)

# Fit models
model_fp <- lm(Pb_icpms ~ Pb_xrf_wt, data = df)
model_Llines <- lm(Pb_icpms ~ Pb_L_total, data = df)

# Add predictions and residuals
df <- df %>%
  mutate(
    Pb_pred_fp = predict(model_fp),
    Pb_pred_Llines = predict(model_Llines),
    Pb_resid_fp = Pb_icpms - Pb_pred_fp,
    Pb_resid_Llines = Pb_icpms - Pb_pred_Llines
  )

# Model stats
r2_fp <- round(summary(model_fp)$r.squared, 3)
r2_Llines <- round(summary(model_Llines)$r.squared, 3)
rmse_fp <- round(sqrt(mean(df$Pb_resid_fp^2)), 0)
rmse_Llines <- round(sqrt(mean(df$Pb_resid_Llines^2)), 0)

# Base theme
theme_base <- theme_bw(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    plot.tag = element_text(size = 16, face = "bold"),
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5)
  )

# Panel A: Fundamental Parameters
p1 <- ggplot(df, aes(x = Pb_xrf_wt * 10000, y = Pb_icpms)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 2.5, alpha = 0.8, color = "gray30") +
  geom_smooth(method = "lm", se = TRUE, color = "#2166AC", fill = "#92C5DE") +
  scale_x_log10(
    limits = c(50, 40000),
    breaks = c(100, 1000, 10000),
    labels = scales::comma
  ) +
  scale_y_log10(
    limits = c(10, 30000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  annotation_logticks() +
  labs(
    x = "XRF Pb (ppm, from m.f.%)",
    y = "ICP-MS Pb (ppm)",
    tag = "A",
    title = "Fundamental Parameters (m.f.%)"
  ) +
  theme_base +
  annotate("text", x = 2000, y = 15,
           label = paste0("R² = ", r2_fp, "\nRMSE = ", rmse_fp, " ppm"),
           size = 3.5, hjust = 0)

# Panel B: Cumulative L-lines - FIXED: bold title and counts/sec
p2 <- ggplot(df, aes(x = Pb_L_total, y = Pb_icpms)) +
  geom_point(size = 2.5, alpha = 0.8, color = "gray30") +
  geom_smooth(method = "lm", se = TRUE, color = "#D95F02", fill = "#FDB863") +
  scale_x_log10(
    limits = c(30, 30000),
    breaks = c(100, 1000, 10000),
    labels = scales::comma
  ) +
  scale_y_log10(
    limits = c(10, 30000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  annotation_logticks() +
  labs(
    x = expression(paste("Pb L-line intensity (L", alpha, " + L", beta, " counts/sec)")),
    y = "ICP-MS Pb (ppm)",
    tag = "B",
    title = expression(bold(paste("Cumulative L-lines (L", alpha, " + L", beta, ")")))
  ) +
  theme_base +
  annotate("text", x = 2000, y = 15,
           label = paste0("R² = ", r2_Llines, "\nRMSE = ", rmse_Llines, " ppm"),
           size = 3.5, hjust = 0)

# Panel C: Model Residuals
df_resid <- df %>%
  select(Base_ID, Pb_resid_fp, Pb_resid_Llines) %>%
  pivot_longer(
    cols = c(Pb_resid_fp, Pb_resid_Llines),
    names_to = "Model",
    values_to = "Residual"
  ) %>%
  mutate(
    Model = case_when(
      Model == "Pb_resid_fp" ~ "FP (m.f.%)",
      Model == "Pb_resid_Llines" ~ "L-lines"
    ),
    Model = factor(Model, levels = c("FP (m.f.%)", "L-lines"))
  )

p3 <- ggplot(df_resid, aes(x = Model, y = Residual, fill = Model, color = Model)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_boxplot(width = 0.6, alpha = 0.3, outlier.shape = NA) +
  geom_jitter(width = 0.15, size = 2, alpha = 0.7) +
  scale_fill_manual(values = c("FP (m.f.%)" = "#92C5DE", "L-lines" = "#FDB863")) +
  scale_color_manual(values = c("FP (m.f.%)" = "#2166AC", "L-lines" = "#D95F02")) +
  labs(
    x = "Calibration Model",
    y = "Residual (ppm)",
    tag = "C",
    title = "Model Residuals"
  ) +
  theme_base +
  theme(legend.position = "none")

# Combine
combined <- p1 + p2 + p3 + plot_layout(ncol = 3, widths = c(1, 1, 0.8))

# Save
ggsave(
 "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Fig_XRF_calibration_final.png",
  combined,
  width = 14,
  height = 5,
  dpi = 300,
  bg = "white"
)

ggsave(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Fig_XRF_calibration_final.pdf",
  combined,
  width = 14,
  height = 5
)

cat("Figure saved with bold Panel B title and counts/sec label\n")
