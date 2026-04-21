# =============================================================================
# Data visualization with ggplot2 using biological example data
# =============================================================================
# This script builds a small synthetic dataset (gene expression in a cell
# culture experiment) and demonstrates common ggplot2 layers. Each line or
# block is commented so you can map commands to what appears on the plot.

# -----------------------------------------------------------------------------
# 1. Load packages
# -----------------------------------------------------------------------------
# install.packages("ggplot2")  # Run once if ggplot2 is not installed yet.
library(ggplot2) # Loads ggplot2: the grammar-of-graphics plotting system for R.

# -----------------------------------------------------------------------------
# 2. Build a biological-style data frame
# -----------------------------------------------------------------------------
# We simulate a simple RNA-like experiment: three genes measured under two
# treatments (Control vs Drug) with three biological replicates each.
# Columns are typical of tidy data: one row per observation, clear variable names.

biological_df <- data.frame(
  gene = rep(c("BRCA1", "TP53", "EGFR"), each = 6), # Gene symbol: repeats each gene for 6 rows (2 treatments x 3 reps).
  treatment = rep(rep(c("Control", "Drug"), each = 3), times = 3), # Treatment arm: Control or Drug, 3 replicates per arm per gene.
  replicate = rep(c("Rep1", "Rep2", "Rep3"), times = 6), # Technical/biological replicate ID within each treatment block.
  expression_log2 = c( # Log2-transformed normalized counts (arbitrary units), plausible for RNA-seq style summaries.
    8.1, 8.3, 8.0, 9.5, 9.8, 9.6, # BRCA1: higher under Drug.
    7.2, 7.4, 7.1, 6.0, 5.9, 6.1, # TP53: lower under Drug.
    10.0, 10.2, 9.9, 10.5, 10.4, 10.6 # EGFR: modest increase under Drug.
  ),
  cell_viability_pct = c( # Parallel cell viability assay (%), same row order as expression_log2.
    95, 96, 94, 78, 76, 77,
    92, 93, 91, 88, 87, 89,
    98, 97, 99, 85, 86, 84
  )
)

# Reorder treatment as a factor so plots (especially lines) always go Control → Drug left to right.
biological_df$treatment <- factor(biological_df$treatment, levels = c("Control", "Drug"))

# str() shows structure: column types and a preview of values — useful sanity check.
str(biological_df)

# head() prints the first rows so you can read the table in the console.
head(biological_df)

# -----------------------------------------------------------------------------
# 3. Example A — Boxplot: distribution of expression by treatment, split by gene
# -----------------------------------------------------------------------------
# ggplot() initializes the plot and binds the data frame; aes() maps columns to visual roles.
p_box <- ggplot(biological_df, aes(x = treatment, y = expression_log2, fill = treatment)) +
  # geom_boxplot() draws boxes (median, quartiles) for each x level — good for comparing groups.
  geom_boxplot(outlier.shape = NA) + # Hide default outliers because we overlay raw points below.
  # geom_jitter() adds individual replicate points with small horizontal randomness so they do not overlap.
  geom_jitter(width = 0.15, alpha = 0.8, size = 2, color = "gray20") +
  # facet_wrap(~ gene) makes one small panel per gene so comparisons stay readable.
  facet_wrap(~ gene, scales = "free_y") + # free_y lets each gene use its own y-axis range if needed.
  labs( # labs() sets human-readable titles and axis labels.
    title = "Gene expression by treatment (synthetic data)",
    subtitle = "Boxes summarize replicates; points are individual measurements",
    x = "Treatment condition",
    y = "Log2 normalized expression",
    fill = "Treatment"
  ) +
  theme_bw() + # theme_bw() is a clean white background with gray grid lines.
  theme(legend.position = "bottom") # Move legend under the plot for a compact layout.

print(p_box) # print() forces display when sourcing the whole script in non-interactive runs.

# -----------------------------------------------------------------------------
# 4. Example B — Scatter: link expression to cell viability (hypothesis exploration)
# -----------------------------------------------------------------------------
p_scatter <- ggplot(biological_df, aes(x = expression_log2, y = cell_viability_pct, color = treatment, shape = treatment)) +
  # geom_point() draws one point per row; color and shape encode treatment within each gene panel.
  geom_point(size = 3) +
  # geom_smooth() fits a line per panel; here each facet is one gene so the trend is treatment-driven within that gene.
  geom_smooth(method = "lm", se = TRUE, linewidth = 0.6, alpha = 0.15) +
  facet_wrap(~ gene) + # One panel per gene keeps the x–y relationship interpretable.
  labs(
    title = "Expression vs cell viability (one panel per gene)",
    x = "Log2 expression",
    y = "Cell viability (%)",
    color = "Treatment",
    shape = "Treatment"
  ) +
  theme_minimal() # Minimal theme: few grid lines, emphasis on data.

print(p_scatter)

# -----------------------------------------------------------------------------
# 5. Example C — Bar chart with error bars: mean expression ± SD by gene and treatment
# -----------------------------------------------------------------------------
# dplyr-style aggregation in base R: tapply splits a vector by factors and applies a function.
mean_expr <- tapply(biological_df$expression_log2, list(biological_df$gene, biological_df$treatment), mean) # Mean per gene x treatment cell.
sd_expr <- tapply(biological_df$expression_log2, list(biological_df$gene, biological_df$treatment), sd) # SD of the three replicates in each cell.

summary_df <- data.frame( # Build a new small table ggplot can read row-by-row.
  gene = rep(rownames(mean_expr), ncol(mean_expr)), # Gene names repeated across treatment columns.
  treatment = rep(colnames(mean_expr), each = nrow(mean_expr)), # Treatment labels aligned with means.
  mean_expression = as.vector(mean_expr), # as.vector() stacks the matrix column-wise into one column.
  sd_expression = as.vector(sd_expr) # Same stacking order as mean_expression — required for matching rows.
)

p_bar <- ggplot(summary_df, aes(x = gene, y = mean_expression, fill = treatment)) +
  # geom_col() draws bar heights equal to y (use for pre-aggregated means); position = "dodge" places bars side by side.
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  # geom_errorbar() adds vertical error bars; ymin/ymax use mean ± sd for quick exploratory error display.
  geom_errorbar(
    aes(ymin = mean_expression - sd_expression, ymax = mean_expression + sd_expression),
    position = position_dodge(width = 0.8),
    width = 0.2
  ) +
  labs(
    title = "Mean expression ± SD across replicates",
    x = "Gene",
    y = "Mean log2 expression",
    fill = "Treatment"
  ) +
  theme_classic() # Classic theme: axes with L-shaped frame, no background grid.

print(p_bar)

# -----------------------------------------------------------------------------
# 6. Example D — Heatmap: mean expression as color in a gene × treatment grid
# -----------------------------------------------------------------------------
# Uses summary_df (means from section 5). geom_tile() draws rectangles; fill maps to numeric magnitude.
# Good for quick "heatmap" views of many genes in real RNA-seq summaries.
p_heat <- ggplot(summary_df, aes(x = treatment, y = gene, fill = mean_expression)) +
  geom_tile(color = "white", linewidth = 0.6) + # White grid lines separate tiles for readability.
  geom_text(aes(label = sprintf("%.2f", mean_expression)), color = "black", size = 3.5) + # Print mean inside each cell.
  scale_fill_gradient(low = "#f7fbff", high = "#08306b", name = "Mean\nlog2 expr.") + # Sequential blue gradient from light to dark.
  labs(
    title = "Mean expression heatmap (gene × treatment)",
    x = "Treatment",
    y = "Gene"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank(), aspect.ratio = NULL) # Remove default grid; tiles carry the structure.

print(p_heat)

# -----------------------------------------------------------------------------
# 7. Example E — Violin + box: shape of the distribution per gene (only 3 points per violin here)
# -----------------------------------------------------------------------------
# Note: violins need several points per group to be meaningful; this is didactic.
p_violin <- ggplot(biological_df, aes(x = gene, y = expression_log2, fill = treatment)) +
  # geom_violin() shows density estimate mirrored vertically — width encodes how common values are.
  geom_violin(position = position_dodge(width = 0.8), trim = FALSE, alpha = 0.4) +
  # geom_boxplot() overlaid at narrow width shows median and quartiles on top of the density.
  geom_boxplot(width = 0.15, position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.9) +
  labs(
    title = "Expression distribution by gene and treatment",
    x = "Gene",
    y = "Log2 expression",
    fill = "Treatment"
  ) +
  coord_flip() # coord_flip() swaps x and y — sometimes easier to read long gene names horizontally.

print(p_violin)

# -----------------------------------------------------------------------------
# 8. Example F — Histogram: frequency of expression values (faceted by gene)
# -----------------------------------------------------------------------------
# geom_histogram() bins the continuous x-axis and counts rows per bin; bins = sets bin count.
# facet_wrap(~ gene) repeats the histogram for each gene so shapes are comparable.
p_hist <- ggplot(biological_df, aes(x = expression_log2, fill = treatment)) +
  geom_histogram(bins = 8, color = "white", linewidth = 0.25, position = position_dodge(width = 0.8)) +
  facet_wrap(~ gene, scales = "free_y") + # free_y: each facet can use a different count scale on y.
  labs(
    title = "Histogram of log2 expression (few bins; small sample)",
    x = "Log2 expression",
    y = "Count",
    fill = "Treatment"
  ) +
  theme_bw()

print(p_hist)

# -----------------------------------------------------------------------------
# 9. Example G — Density: smoothed distribution of expression by treatment
# -----------------------------------------------------------------------------
# geom_density() estimates a smooth probability density along x; alpha makes overlapping fills visible.
p_density <- ggplot(biological_df, aes(x = expression_log2, fill = treatment)) +
  geom_density(alpha = 0.35, linewidth = 0.6, color = NA) + # color = NA removes outline so fills blend cleanly.
  facet_wrap(~ gene, scales = "free_y") + # Separate y scale per gene because peak heights differ.
  labs(
    title = "Kernel density of expression by treatment",
    x = "Log2 expression",
    y = "Density",
    fill = "Treatment"
  ) +
  theme_minimal()

print(p_density)

# -----------------------------------------------------------------------------
# 10. Example H — Paired lines: same replicate linked Control → Drug within each gene
# -----------------------------------------------------------------------------
# aes(group = paste(gene, replicate)) tells ggplot which points belong to one "subject" for geom_line().
# Useful in wet-lab plots to show paired designs (same culture split across conditions).
p_paired <- ggplot(biological_df, aes(x = treatment, y = expression_log2, group = interaction(gene, replicate), color = replicate)) +
  geom_line(linewidth = 0.8, alpha = 0.85) + # Lines connect the two treatment levels for each gene–replicate pair.
  geom_point(size = 2.5) + # Emphasize measured values at each x position.
  facet_wrap(~ gene) + # One panel per gene avoids crossing lines between genes.
  labs(
    title = "Paired expression (replicate tracks from Control to Drug)",
    x = "Treatment",
    y = "Log2 expression",
    color = "Replicate"
  ) +
  theme_bw() +
  theme(legend.position = "bottom")

print(p_paired)

# -----------------------------------------------------------------------------
# 11. Example I — Pointrange: mean ± SD as a point with vertical error bar (Cleveland-style summary)
# -----------------------------------------------------------------------------
# geom_pointrange() draws a central point with ymin–ymax whiskers; good for compact summary plots.
p_pointrange <- ggplot(summary_df, aes(x = gene, y = mean_expression, color = treatment, ymin = mean_expression - sd_expression, ymax = mean_expression + sd_expression, group = treatment)) +
  geom_pointrange(position = position_dodge(width = 0.35), size = 0.4, linewidth = 0.7) + # dodge separates the two treatments per gene.
  labs(
    title = "Mean expression with SD (pointrange)",
    x = "Gene",
    y = "Log2 expression",
    color = "Treatment"
  ) +
  theme_classic()

print(p_pointrange)

# -----------------------------------------------------------------------------
# 12. Example J — ECDF: empirical cumulative distribution of expression by treatment
# -----------------------------------------------------------------------------
# stat_ecdf() plots the proportion of observations ≤ x; useful to compare entire distributions without binning.
p_ecdf <- ggplot(biological_df, aes(x = expression_log2, color = treatment)) +
  stat_ecdf(linewidth = 0.9) + # One step curve per treatment within each facet.
  facet_wrap(~ gene) +
  labs(
    title = "Empirical cumulative distribution of expression",
    x = "Log2 expression",
    y = "ECDF (proportion <= x)",
    color = "Treatment"
  ) +
  theme_minimal()

print(p_ecdf)

# -----------------------------------------------------------------------------
# 13. Example K — Bubble chart: expression vs viability with point size = |log-fold change| vs control mean
# -----------------------------------------------------------------------------
# We add a simple derived size: absolute difference from the gene-wise control mean (didactic "effect size" proxy).
ctrl_mean_by_gene <- tapply(
  biological_df$expression_log2[biological_df$treatment == "Control"],
  biological_df$gene[biological_df$treatment == "Control"],
  mean
) # Vector of control means named by gene.
biological_df$abs_delta_vs_control <- abs( # Absolute deviation from control mean for each row's gene.
  biological_df$expression_log2 - ctrl_mean_by_gene[as.character(biological_df$gene)]
) + 0.12 # Small floor so Control points (delta 0) still render visibly with scale_size_area().

p_bubble <- ggplot(biological_df, aes(x = expression_log2, y = cell_viability_pct, size = abs_delta_vs_control, fill = treatment)) +
  geom_point(shape = 21, color = "gray30", alpha = 0.85) + # shape 21 = filled circle with border; fill maps to treatment.
  scale_size_area(max_size = 8, name = "|delta vs\ncontrol|") + # scale_size_area: area scales with squared size; small floor keeps Control points visible.
  facet_wrap(~ gene) +
  labs(
    title = "Expression vs viability (bubble size = deviation from control mean)",
    x = "Log2 expression",
    y = "Cell viability (%)",
    fill = "Treatment"
  ) +
  theme_bw() +
  theme(legend.position = "right")

print(p_bubble)

# -----------------------------------------------------------------------------
# 14. Save plots to disk (optional)
# -----------------------------------------------------------------------------
# ggsave() writes the last plot or an explicit plot object; dpi controls resolution for publications.
ggsave(
  filename = "biological_boxplot_example.png", # Output file name in the working directory.
  plot = p_box, # Explicit plot object — clearer than relying on "last plot".
  width = 8, # Width in inches (default unit).
  height = 5, # Height in inches.
  dpi = 300 # 300 dpi is a common print/publication target.
)

ggsave(
  filename = "biological_heatmap_example.png", # Second saved figure for reports or README figures.
  plot = p_heat,
  width = 6,
  height = 4,
  dpi = 300
)

# =============================================================================
# End of script
# =============================================================================
