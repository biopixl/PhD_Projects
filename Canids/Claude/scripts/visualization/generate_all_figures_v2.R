#!/usr/bin/env Rscript
# Comprehensive figure generation following scientific visualization best practices
# Addresses: outlier filtering, proper scaling, clear legends, publication quality

library(ggplot2)
library(dplyr)
library(patchwork)
library(ggrepel)
library(viridis)
library(cowplot)

# Load and clean data
raw <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv")

# CRITICAL: Filter computational artifacts (omega > 5 unrealistic)
data <- raw %>%
  filter(dog_omega <= 5, !is.na(dog_omega), !is.infinite(dog_omega)) %>%
  mutate(
    log10p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue)),
    gene_label = ifelse(is.na(gene_symbol) | gene_symbol == "", 
                       paste0("G", substr(gene_id, 12, 16)), gene_symbol)
  )

cat(sprintf("Filtered: %d -> %d genes (removed %d outliers)\n", 
            nrow(raw), nrow(data), nrow(raw)-nrow(data)))

# Publication theme
theme_pub <- function() theme_classic(base_size = 14) + theme(
  plot.title = element_text(face="bold", size=16),
  axis.title = element_text(face="bold"),
  panel.border = element_rect(fill=NA, color="black", linewidth=1),
  panel.grid.major = element_line(color="grey92", linewidth=0.3)
)

dir.create("manuscript/figures", showWarnings=FALSE, recursive=TRUE)

# FIGURE: Selection Strength Manhattan-style plot
top20 <- data %>% arrange(dog_pvalue) %>% head(20)

fig_manhattan <- ggplot(data, aes(x=dog_omega, y=log10p)) +
  geom_point(aes(color=log10p), size=2.5, alpha=0.6) +
  scale_color_viridis_c(option="plasma", name="-log10(p)") +
  geom_hline(yintercept=-log10(2.93e-6), linetype="dashed", 
             color="red", linewidth=1) +
  geom_text_repel(data=top20, aes(label=gene_label), 
                  size=3, fontface="italic", max.overlaps=15) +
  labs(title="Genome-Wide Selection Analysis",
       x=expression(bold(omega*" (dN/dS)")),
       y=expression(bold("-log"[10]*"(p-value)"))) +
  theme_pub()

ggsave("manuscript/figures/SelectionManhattan.png", fig_manhattan, 
       width=12, height=8, dpi=600)

cat("✓ Generated SelectionManhattan.png\n")
