# Figure 3: ICP-MS metal concentrations and CV for 38 ash samples
# Two-panel figure: (a) concentrations ranked by median, (b) CV same order
# Color by element origin with consistent logic:
# - Geogenic (blue): major elements >10,000 ppm median
# - Pyrogenic (red): high CV metals from built environment
# - Hybrid (red/blue stripe): Ca, Mg - major elements with pyrogenic variability
# - Other (gray): all other elements

library(tidyverse)
library(patchwork)
library(ggpattern)

# Read ICP-MS data
icpms <- read.csv("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF/data/zenodo/EFA_ICPMS_PPM.csv")

# Filter to ash samples only (38 samples)
ash <- icpms %>% filter(alq.type == "ASH")
cat("Number of ash samples:", nrow(ash), "\n")

# Elements to plot
elements_to_plot <- c("Ca", "Fe", "Al", "K", "Na", "Mg", "Zn", "Mn", "Ti",
                      "Pb", "Cu", "Ba", "V", "Cr", "Co", "Ni", "As", "Sb", "Cd")

# Calculate summary statistics first to determine thresholds
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

stats <- calc_stats(ash, elements_to_plot)

# Define classification based on consistent logic:
# - Geogenic: major elements with median >10,000 ppm (excluding Ca, Mg which are hybrid)
# - Pyrogenic: high CV metals from anthropogenic sources
# - Hybrid: Ca, Mg (major geogenic + pyrogenic variability)
# - Other: everything else (below threshold or intermediate)
element_info <- tribble(
  ~Element, ~Type,
  # Geogenic: major elements >10,000 ppm median
  "Al", "Geogenic",
  "Fe", "Geogenic",
  "K",  "Geogenic",
  "Na", "Geogenic",
  # Pyrogenic: high CV metals from built environment
  "Pb", "Pyrogenic",
  "Zn", "Pyrogenic",
  "Cu", "Pyrogenic",
  "Co", "Pyrogenic",
  "Ni", "Pyrogenic",
  "Sb", "Pyrogenic",
  # Hybrid: major elements (>10k) with high CV from building materials
  "Ca", "Hybrid",
  "Mg", "Hybrid",
  # Other: below 10k threshold or intermediate CV
  "Ti", "Other",
  "Mn", "Other",
  "Ba", "Other",
  "V",  "Other",
  "Cr", "Other",
  "As", "Other",
  "Cd", "Other"
)

# Join stats with classification
stats <- stats %>%
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
  mutate(Element = factor(Element, levels = element_order),
         Type = factor(Type, levels = c("Pyrogenic", "Geogenic", "Hybrid", "Other")))

# CV data for panel B
cv_data <- stats %>%
  mutate(Element = factor(Element, levels = element_order),
         Type = factor(Type, levels = c("Pyrogenic", "Geogenic", "Hybrid", "Other")))

# Color palette
type_colors <- c(
  "Pyrogenic" = "#E41A1C",
  "Geogenic" = "#377EB8",
  "Hybrid" = "#377EB8",
  "Other" = "gray60"
)

# Pattern colors for hybrid (red stripes on blue background)
pattern_colors <- c(
  "Pyrogenic" = NA,
  "Geogenic" = NA,
  "Hybrid" = "#E41A1C",
  "Other" = NA
)

# Panel A: Concentration boxplots (top panel)
p_conc <- ggplot(plot_data, aes(x = Element, y = Concentration, fill = Type)) +
  geom_boxplot_pattern(
    aes(pattern = Type, pattern_fill = Type),
    outlier.shape = 21,
    outlier.size = 1.5,
    alpha = 0.7,
    pattern_colour = NA,
    pattern_density = 0.4,
    pattern_spacing = 0.015,
    pattern_angle = 45
  ) +
  scale_pattern_manual(
    values = c("Pyrogenic" = "none", "Geogenic" = "none",
               "Hybrid" = "stripe", "Other" = "none"),
    guide = "none"
  ) +
  scale_pattern_fill_manual(
    values = c("Pyrogenic" = NA, "Geogenic" = NA,
               "Hybrid" = "#E41A1C", "Other" = NA),
    guide = "none"
  ) +
  scale_y_log10(
    labels = scales::label_comma(),
    breaks = c(0.1, 1, 10, 100, 1000, 10000, 100000),
    limits = c(0.1, 500000)
  ) +
  scale_fill_manual(
    values = type_colors,
    name = NULL,
    breaks = c("Pyrogenic", "Geogenic"),
    labels = c("Pyrogenic (CV>100%)", "Geogenic (conc.>10,000ppm)")
  ) +
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
  geom_col_pattern(
    aes(pattern = Type, pattern_fill = Type),
    alpha = 0.8,
    width = 0.7,
    pattern_colour = NA,
    pattern_density = 0.4,
    pattern_spacing = 0.015,
    pattern_angle = 45
  ) +
  scale_pattern_manual(
    values = c("Pyrogenic" = "none", "Geogenic" = "none",
               "Hybrid" = "stripe", "Other" = "none"),
    guide = "none"
  ) +
  scale_pattern_fill_manual(
    values = c("Pyrogenic" = NA, "Geogenic" = NA,
               "Hybrid" = "#E41A1C", "Other" = NA),
    guide = "none"
  ) +
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
  annotate("text", x = 0.5, y = 100, label = "CV = 100%",
           hjust = 0, vjust = -0.3, size = 3, color = "gray40")

# Combine panels vertically
combined <- p_conc / p_cv +
  plot_layout(heights = c(1.2, 1))

# Save figure
ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.png",
       combined, width = 9, height = 7, dpi = 300, bg = "white")

ggsave("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/final-figs/Fig-3-icpms.pdf",
       combined, width = 9, height = 7)

cat("\nFigure saved to:\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.png\n")
cat("  - Manuscript/Data/final-figs/Fig-3-icpms.pdf\n")

# Print summary statistics
cat("\n=== Summary Statistics (ranked by median) ===\n")
print(stats %>%
        select(Element, Type, Median, CV) %>%
        mutate(across(where(is.numeric), ~round(., 1))))

cat("\n=== Classification Logic ===\n")
cat("Geogenic (blue): Major elements with median >10,000 ppm\n")
cat("  -> Al (43,046), Fe (38,324), K (19,578), Na (14,333)\n")
cat("Pyrogenic (red): High CV metals from built environment combustion\n")
cat("  -> Pb (459%), Zn (288%), Cu (281%), Co (150%), Ni (143%), Sb (133%)\n")
cat("Hybrid (blue + red stripes): Major elements with pyrogenic variability\n")
cat("  -> Ca (34,114 ppm, 115% CV), Mg (11,878 ppm, 126% CV)\n")
cat("Other (gray): Below threshold or intermediate\n")
cat("  -> Ti, Mn, Ba, V, Cr, As, Cd\n")
