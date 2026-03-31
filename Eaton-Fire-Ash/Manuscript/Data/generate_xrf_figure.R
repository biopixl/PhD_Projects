#!/usr/bin/env Rscript
# Generate XRF Calibration Figure with Consistent Bold Panel Titles
# Fix for Panel B title not appearing bold

library(tidyverse)
library(patchwork)

# Load data
df <- read_csv(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/harmonized_xrf_icpms_Lb_paired.csv",
  show_col_types = FALSE
)

# Calculate cumulative L-line intensity (La1 + Lb1 + Lb2)
df <- df %>%
  mutate(Pb_L_total = Pb_La1_cts + Pb_Lb1_cts + Pb_Lb2_cts)

# Fit models
model_fp <- lm(Pb_icpms ~ Pb_xrf_wt, data = df)
model_Llines <- lm(Pb_icpms ~ Pb_L_total, data = df)

# Add predictions
df <- df %>%
  mutate(
    Pb_pred_fp = predict(model_fp),
    Pb_pred_Llines = predict(model_Llines),
    Pb_resid_fp = Pb_icpms - Pb_pred_fp,
    Pb_resid_Llines = Pb_icpms - Pb_pred_Llines
  )

# Model stats
r2_fp <- summary(model_fp)$r.squared
r2_Llines <- summary(model_Llines)$r.squared
rmse_fp <- sqrt(mean(df$Pb_resid_fp^2))
rmse_Llines <- sqrt(mean(df$Pb_resid_Llines^2))

# Define consistent theme - key fix: use explicit font settings
theme_pub <- theme_bw(base_size = 12, base_family = "") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    plot.tag = element_text(size = 16, face = "bold"),
    # Critical: Force bold title with explicit settings
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5,
                              margin = margin(b = 10))
  )

# Panel A: Fundamental Parameters (log-log)
p1 <- ggplot(df, aes(x = Pb_xrf_wt * 10000, y = Pb_icpms)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3, alpha = 0.7, color = "#2166AC") +
  geom_smooth(method = "lm", se = TRUE, color = "#B2182B", fill = "#FDDBC7") +
  scale_x_log10(
    limits = c(10, 50000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  scale_y_log10(
    limits = c(10, 50000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  annotation_logticks() +
  labs(
    x = "XRF Pb (ppm, from wt%)",
    y = "ICP-MS Pb (ppm)",
    tag = "A"
  ) +
  ggtitle("Fundamental Parameters") +
  theme_pub +
  annotate("text", x = 30, y = 20000,
           label = sprintf("R^2 == %.3f", r2_fp),
           parse = TRUE, size = 4, hjust = 0)

# Panel B: Cumulative L-lines (log-log)
# Key fix: Apply theme_pub THEN override title explicitly again
p2 <- ggplot(df, aes(x = Pb_L_total, y = Pb_icpms)) +
  geom_point(size = 3, alpha = 0.7, color = "#2166AC") +
  geom_smooth(method = "lm", se = TRUE, color = "#B2182B", fill = "#FDDBC7") +
  scale_x_log10(
    limits = c(10, 30000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  scale_y_log10(
    limits = c(10, 50000),
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  annotation_logticks() +
  labs(
    x = "XRF Pb L-line Intensity (counts)",
    y = "ICP-MS Pb (ppm)",
    tag = "B"
  ) +
  ggtitle("Cumulative L-lines") +
  theme_pub +
  # Explicit override to ensure bold
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5)) +
  annotate("text", x = 30, y = 20000,
           label = sprintf("R^2 == %.3f", r2_Llines),
           parse = TRUE, size = 4, hjust = 0)

# Panel C: Residual comparison
df_resid <- df %>%
  select(Base_ID, Pb_resid_fp, Pb_resid_Llines) %>%
  pivot_longer(
    cols = c(Pb_resid_fp, Pb_resid_Llines),
    names_to = "Model",
    values_to = "Residual"
  ) %>%
  mutate(
    Model = case_when(
      Model == "Pb_resid_fp" ~ "FP wt%",
      Model == "Pb_resid_Llines" ~ "L-lines"
    ),
    Model = factor(Model, levels = c("FP wt%", "L-lines"))
  )

p3 <- ggplot(df_resid, aes(x = Model, y = Residual, fill = Model)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_boxplot(width = 0.6, alpha = 0.8, outlier.shape = 21) +
  scale_fill_manual(values = c("FP wt%" = "#FDDBC7", "L-lines" = "#D1E5F0")) +
  labs(
    x = "Calibration Model",
    y = "Residual (ppm)",
    tag = "C"
  ) +
  ggtitle("Residual Distribution") +
  theme_pub +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5)
  )

# Combine panels
combined <- p1 + p2 + p3 + plot_layout(ncol = 3, widths = c(1, 1, 0.8))

# Save figure - use default device first
ggsave(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Fig_XRF_calibration_final.png",
  combined,
  width = 14,
  height = 5,
  dpi = 300,
  bg = "white"
)

# Also try saving as PDF (better font handling)
ggsave(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Fig_XRF_calibration_final.pdf",
  combined,
  width = 14,
  height = 5,
  device = pdf
)

cat("Figures saved:\n")
cat("  - Fig_XRF_calibration_final.png\n")
cat("  - Fig_XRF_calibration_final.pdf\n")
