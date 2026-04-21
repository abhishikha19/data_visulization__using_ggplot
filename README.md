# Data visualization with ggplot2 (biological example)

This repository contains a **fully commented R script** that builds a small **synthetic biological dataset** (gene expression and cell viability) and produces several **ggplot2** figures. It is intended for learning, teaching, or as a template you can copy into your own analyses.

## What you will find here

| File | Purpose |
|------|---------|
| `biological_ggplot2_visualization.R` | Main script: creates the data frame, runs exploratory checks, and builds multiple plots with inline explanations |

The script does **not** read external CSV files. All numbers are defined inside the script so anyone can run it without downloading data.

## Requirements

- **R** (4.0 or newer recommended)
- **ggplot2** R package

Install ggplot2 once from R:

```r
install.packages("ggplot2")
```

## The example dataset (biology context)

The script defines a data frame similar to what you might see after a simple **cell culture / gene expression** experiment:

- **`gene`**: Symbols for three genes (`BRCA1`, `TP53`, `EGFR`).
- **`treatment`**: Two conditions (`Control`, `Drug`), stored as an **ordered factor** (`Control` then `Drug`) so axes and paired-line plots read naturally left to right.
- **`replicate`**: Three replicate labels per gene and treatment (`Rep1`–`Rep3`).
- **`expression_log2`**: Log2-scale expression values (synthetic, RNA-seq–style units).
- **`cell_viability_pct`**: Cell viability percentages measured in parallel.

Each row is one measurement. The layout follows **tidy data** ideas: one observation per row, variables in columns.

Later in the script, a **derived column** is added for the bubble example: absolute deviation of each row’s expression from that gene’s **Control** mean (plus a tiny display floor so control points stay visible).

## Plot types demonstrated

The R file labels examples **A–K** in order. Here is what each one shows:

| Example | Plot type | What it illustrates |
|--------|-----------|---------------------|
| **A** | Boxplot + jitter + facets | Expression by treatment, one panel per gene; jitter shows individual replicates. |
| **B** | Scatter + linear smooth + facets | Expression vs cell viability, one panel per gene. |
| **C** | Bar chart + error bars | Mean expression ± SD per gene and treatment (`tapply` in base R, then `ggplot`). |
| **D** | Heatmap (`geom_tile`) | Mean expression as fill in a gene × treatment grid (uses the same summary table as C). |
| **E** | Violin + boxplot (+ `coord_flip`) | Distribution-shaped view by gene and treatment (few points per group; mainly didactic). |
| **F** | Histogram (`geom_histogram`) | Binned expression counts, dodged by treatment, faceted by gene. |
| **G** | Density (`geom_density`) | Smoothed expression distributions by treatment, faceted by gene. |
| **H** | Paired lines | Same replicate linked **Control → Drug** within each gene (paired experimental design). |
| **I** | Pointrange (`geom_pointrange`) | Compact mean ± SD summary, dodged by treatment. |
| **J** | ECDF (`stat_ecdf`) | Empirical cumulative distribution of expression by treatment, faceted by gene. |
| **K** | Bubble chart | Expression vs viability; point size reflects deviation from control mean; faceted by gene. |

The script ends by saving **two** figures with **`ggsave()`** (300 dpi PNGs); all other figures are still **printed** when you run the script so they appear in RStudio or in `Rplots.pdf` when using `Rscript`.

## How to run the script

### Option A: RStudio

1. Open `biological_ggplot2_visualization.R` in RStudio.
2. Install ggplot2 if needed (see Requirements).
3. Run the whole file (**Source** or **Ctrl/Cmd + Shift + S**).

### Option B: Command line

From the repository folder:

```bash
Rscript biological_ggplot2_visualization.R
```

## Output files

When you run the script, you may get:

- **`biological_boxplot_example.png`** — Example **A** (boxplot), written by `ggsave()`.
- **`biological_heatmap_example.png`** — Example **D** (heatmap), written by `ggsave()`.
- **`Rplots.pdf`** — On some setups, R creates this when many plots are printed under `Rscript`. You can delete it if you do not need it, or list `Rplots.pdf` in `.gitignore` so it is not pushed to GitHub.


## Learning notes

- Open the `.R` file and read the comments **above and beside** each major command; section headers mark **Examples A–K** so you can jump to a plot type you care about.
- To adapt the script to **your** experiment, replace the synthetic `data.frame()` with `read.csv()` (or similar) pointing to your own tidy table, then adjust column names inside `aes()`.
- Examples **C**, **D**, and **I** share the same aggregated **`summary_df`** (means and SDs); change the aggregation once if you switch to real data with more replicates.
