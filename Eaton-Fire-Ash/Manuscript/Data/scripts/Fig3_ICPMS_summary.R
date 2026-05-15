# Figure 3: ICP-MS metal concentrations and CV for 38 ash samples
# Two-panel figure: (a) concentrations ranked by median, (b) CV same order
# Color by pyrogenic vs geogenic origin

library(tidyverse)
library(patchwork)

# Read ICP-MS data
icpms <- read.csv("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF/data/zenodo/EFA_ICPMS_PPM.csv")

# Filter to ash samples only (38 samples)
ash <- icpms %>% filter(alq.type == "ASH")
cat("Number of ash samples:", nrow(ash), "\n")

# Define elements with classification
# Pyrogenic: derived from combustion of built-environment materials (high CV)
# Geogenic: reflect regional geological substrate (low CV)
element_info <- tribble(
  ~Element, ~Type,
  "Pb", "Pyrogenic",
  "Zn", "Pyrogenic",
  "Cu", "Pyrogenic",
  "Co", "Pyrogenic",
  "Ni", "Pyrogenic",
  "Sb", "Pyrogenic",
  "Cr", "Geogenic",
  "Cd", "Pyrogenic",
  "As", "Geogenic",
  "V",  "Geogenic",
  "Fe", "Geogenic",
  "Al", "Geogenic",
  "Ti", "Geogenic",
  "Mn", "Geogenic",
  "Ca", "Geogenic",
  "Mg", "Geogenic",
  "K",  "Geogenic",
  "Na", "Geogenic",
  "Ba", "Geogenic",
  "Sr", "Geogenic"
)

# Select elements to display (top metals by interest)
elements_to_plot <- c("Ca", "Fe", "Al", "Zn", "Mn", "Ti", "Pb", "Cu",
                      "Ba", "V", "Cr", "Co", "Ni", "As", "Sb", "Cd")

# Calculate summary statistics
calc_stats <- function(data, elements) {
  stats <- map_dfr(elements, function(elem) {
    if (elem %in% names(data)) {
      vals <- data[[elem]]
      vals <- vals[!is.na(vals)]
      if (length(vals) > 0) {
        tibble(
          Element = elem,
          Mean = mean(vals),
          Median = median(vals),
          Min = min(vals),
          Max = max(vals),
          SD = sd(vals),
          CV = sd(vals) / mean(vals) * 100
        )
      }
    }
  })
  return(stats)
}

# Calculate stats
stats <- calc_stats(ash, elements_to_plot) %>%
  left_join(element_info, by = "Element") %>%
  arrange(desc(Median))

# Set element order by median concentration (descending)
element_order <- stats$Element

# Prepare long-format data for plotting
plot_data <- ash %>%
  select(EFA.ID, all_of(elements_to_plot)) %>%
  pivot_longer(cols = -EFA.ID, names_to = "Element", values_to = "Concentration") %>%
  filter(!is.na(Concentration)) %>%
  left_join(element_info, by = "Element") %>%
  mutate(Element = factor(Element, levels = element_order))

# CV data for panel B
cv_data <- stats %>%
  mutate(Element = factor(Element, levels = element_order))

# Color palette
type_colors <- c(
  "Pyrogenic" = "#E41A1C",  # Red
  "Geogenic" = "#377EB8"    # Blue
)

# Panel A: Concentration boxplots (top panel)
p_conc <- ggplot(plot_data, aes(x = Element, y = Concentration, fill = Type)) +
  geom_boxplot(outlier.shape = 21, outlier.size = 1.5, alpha = 0.7) +
  scale_y_log10(
    labels = scales::label_comma(),
    breaks = c(0.1, 1, 10, 100, 1000, 10000, 100000),
    limits = c(0.1, 500000)
  ) +
  scale_fill_manual(values = type_colors, name = "Origin") +
  labs(
    x = NULL,
    y = "Concentration (ppm)",
    tag = "a"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.margin = margin(0, 0, 0, 0),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.tag = element_text(face = "bold", size = 12),
    plot.margin = margin(5, 10, 0, 10)
  )

# Panel B: CV barplot (bottom panel, same x-axis order)
p_cv <- ggplot(cv_data, aes(x = Element, y = CV, fill = Type)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  scale_fill_manual(values = type_colors, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), limits = c(0, 500)) +
  labs(
    x = "Element (ranked by median concentration)",
    y = "CV (%)",
    tag = "b"
  ) +
  theme_bw(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    panel.grid.minor = element_blank(),
    plot.tag = element_text(face = "bold", size = 12),
    plot.margin = margin(0, 10, 5, 10)
  ) +
  annotate("text", x = 15.5, y = 100, label = "CV = 100%",
           hjust = 1, vjust = -0.3, size = 3, color = "gray40")

# Combine panels vertically
combined <- p_conc / p_cv +
  plot_layout(heights = c(1.2, 1))

# Save figure
ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.png",
       combined, width = 8, height = 7, dpi = 300, bg = "white")

ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.pdf",
       combined, width = 8, height = 7)

cat("\nFigure saved to:\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.png\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.pdf\n")

# Print summary statistics
cat("\n=== Summary Statistics (ranked by median) ===\n")
print(stats %>%
        select(Element, Type, Median, Mean, CV) %>%
        mutate(across(where(is.numeric), ~round(., 1))))
