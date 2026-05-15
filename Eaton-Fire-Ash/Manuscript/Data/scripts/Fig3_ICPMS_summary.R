# Figure 3: ICP-MS metal concentrations and CV for 38 ash samples
# Two-panel figure: (a) concentrations, (b) coefficient of variation

library(tidyverse)
library(patchwork)

# Read ICP-MS data
icpms <- read.csv("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF/data/zenodo/EFA_ICPMS_PPM.csv")

# Filter to ash samples only (38 samples)
ash <- icpms %>% filter(alq.type == "ASH")
cat("Number of ash samples:", nrow(ash), "\n")

# Define elements of interest (toxic heavy metals + major elements for context)
toxic_metals <- c("Pb", "Zn", "Cu", "Co", "Ni", "Sb", "Cr", "Cd", "As", "V")
major_elements <- c("Ca", "Fe", "Al", "Ti", "Mg", "K", "Na", "Mn")

# Calculate summary statistics for each element
calc_stats <- function(data, elements) {
  stats <- data.frame(
    Element = character(),
    Mean = numeric(),
    Median = numeric(),
    Min = numeric(),
    Max = numeric(),
    CV = numeric(),
    stringsAsFactors = FALSE
  )

  for (elem in elements) {
    if (elem %in% names(data)) {
      vals <- data[[elem]]
      vals <- vals[!is.na(vals)]
      if (length(vals) > 0) {
        stats <- rbind(stats, data.frame(
          Element = elem,
          Mean = mean(vals),
          Median = median(vals),
          Min = min(vals),
          Max = max(vals),
          CV = sd(vals) / mean(vals) * 100
        ))
      }
    }
  }
  return(stats)
}

# Calculate stats for toxic metals
toxic_stats <- calc_stats(ash, toxic_metals)
toxic_stats$Type <- "Toxic Heavy Metals"

# Calculate stats for major elements
major_stats <- calc_stats(ash, major_elements)
major_stats$Type <- "Major Elements"

# Combine
all_stats <- rbind(toxic_stats, major_stats)

# Order by CV for toxic metals, then by concentration for major elements
toxic_stats <- toxic_stats %>% arrange(desc(CV))
major_stats <- major_stats %>% arrange(desc(Mean))

# Panel A: Concentration boxplots for toxic metals (ordered by CV)
toxic_long <- ash %>%
  select(EFA.ID, all_of(toxic_metals)) %>%
  pivot_longer(cols = -EFA.ID, names_to = "Element", values_to = "Concentration") %>%
  filter(!is.na(Concentration))

# Set element order by CV
toxic_long$Element <- factor(toxic_long$Element, levels = toxic_stats$Element)

# Color scale based on regulatory concern
element_colors <- c(
  "Pb" = "#E41A1C",   # Red - highest concern
  "Zn" = "#377EB8",   # Blue
  "Cu" = "#4DAF4A",   # Green
  "Co" = "#984EA3",   # Purple
  "Ni" = "#FF7F00",   # Orange
  "Sb" = "#FFFF33",   # Yellow
  "Cr" = "#A65628",   # Brown
  "Cd" = "#F781BF",   # Pink
  "As" = "#999999",   # Gray
  "V"  = "#66C2A5"    # Teal
)

# Panel A: Boxplot of concentrations
p_conc <- ggplot(toxic_long, aes(x = Element, y = Concentration, fill = Element)) +
  geom_boxplot(outlier.shape = 21, outlier.size = 2, alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  scale_y_log10(
    labels = scales::label_comma(),
    breaks = c(1, 10, 100, 1000, 10000)
  ) +
  scale_fill_manual(values = element_colors) +
  labs(
    x = NULL,
    y = "Concentration (ppm)",
    title = "(a) Metal concentrations in ash (n = 38)"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 11, face = "bold")
  ) +
  # Add reference lines for key thresholds
  geom_hline(yintercept = 200, linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = 0.7, y = 200, label = "EPA RSL (Pb)",
           hjust = 0, vjust = -0.5, size = 2.5, color = "red")

# Panel B: CV barplot
cv_data <- toxic_stats %>%
  mutate(Element = factor(Element, levels = Element))

p_cv <- ggplot(cv_data, aes(x = Element, y = CV, fill = Element)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = sprintf("%.0f%%", CV)),
            vjust = -0.3, size = 3) +
  scale_fill_manual(values = element_colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    x = NULL,
    y = "Coefficient of Variation (%)",
    title = "(b) Spatial heterogeneity"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 11, face = "bold")
  ) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray50", alpha = 0.5)

# Combine panels
combined <- p_conc + p_cv +
  plot_layout(ncol = 2, widths = c(1, 1))

# Save figure
ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.png",
       combined, width = 10, height = 5, dpi = 300, bg = "white")

ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.pdf",
       combined, width = 10, height = 5)

cat("\nFigure saved to:\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.png\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.pdf\n")

# Print summary statistics
cat("\n=== Summary Statistics for Toxic Metals ===\n")
print(toxic_stats %>% select(Element, Mean, Median, Min, Max, CV) %>%
        mutate(across(where(is.numeric), ~round(., 1))))
