# =============================================================================
# Script: 02_eda.R
# Project: Predicting Billboard Chart Success from Spotify Audio Features
# Purpose: Exploratory Data Analysis (EDA) on the merged dataset.
#          This is Step 2 — visual exploration only.
#          No hypothesis testing, no PCA, no modeling, no sampling.
#
# Dataset used (explicit — no fallback to other files):
#   data/processed/spotify_billboard_merged_full.csv
#
# Outputs:
#   outputs/figures/eda/charted_class_balance.png
#   outputs/figures/eda/histogram_{feature}.png          (9 files)
#   outputs/figures/eda/boxplot_{feature}_by_charted.png (9 files)
#   outputs/figures/eda/audio_feature_correlation_heatmap.png
#   outputs/tables/audio_feature_correlation_matrix.csv
#   outputs/tables/eda_group_summary_by_charted.csv
#   docs/step2_eda_summary.md
#
# Uses ONLY base R — no packages needed.
# =============================================================================

# ── 0. SETUP ──────────────────────────────────────────────────────────────────

project_root <- "D:/SpotifyBillboardProject"
setwd(project_root)
cat("Working directory:", getwd(), "\n\n")

# Explicit dataset path — this script must not silently inspect another file
dataset_path <- "data/processed/spotify_billboard_merged_full.csv"

if (!file.exists(dataset_path)) {
  stop(
    "Dataset not found: ", dataset_path, "\n",
    "Please run 01b_build_merged_dataset.R and 01_data_inspection.R first.\n"
  )
}

# Create output folders if they don't exist
dir.create("outputs/figures/eda", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",       recursive = TRUE, showWarnings = FALSE)
dir.create("docs",                  recursive = TRUE, showWarnings = FALSE)

# The 9 audio features from the project proposal
audio_features <- c("danceability", "energy", "valence", "tempo",
                    "loudness",     "acousticness", "speechiness",
                    "instrumentalness", "liveness")

# Human-readable labels for plots (capitalize, remove underscores)
feature_labels <- c("Danceability", "Energy", "Valence", "Tempo",
                    "Loudness (dB)", "Acousticness", "Speechiness",
                    "Instrumentalness", "Liveness")

# Default graphics settings for all plots
PLOT_W     <- 800    # PNG width in pixels
PLOT_H     <- 600    # PNG height in pixels
PLOT_BG    <- "white"
COL_0      <- "#5B9BD5"    # blue for charted = 0 (not charted)
COL_1      <- "#ED7D31"    # orange for charted = 1 (charted)
COL_HIST   <- "#7EB6D9"    # blue-grey for overall histograms

cat("=============================================================\n")
cat("  EDA SCRIPT START\n")
cat("  Dataset:", dataset_path, "\n")
cat("=============================================================\n\n")

# ── 1. LOAD DATA ──────────────────────────────────────────────────────────────

cat("Loading dataset...\n")
df <- read.csv(dataset_path, stringsAsFactors = FALSE, check.names = FALSE)

cat("Loaded:", nrow(df), "rows x", ncol(df), "columns\n")
cat("charted=0:", sum(df$charted == 0), " | charted=1:", sum(df$charted == 1), "\n\n")

# Split into two groups for easy comparisons
df0 <- df[df$charted == 0, ]   # not charted
df1 <- df[df$charted == 1, ]   # charted

# ── 2A. OUTCOME DISTRIBUTION — CLASS BALANCE BAR PLOT ─────────────────────────

cat("Plotting: class balance bar chart...\n")

out_path <- "outputs/figures/eda/charted_class_balance.png"
png(out_path, width = PLOT_W, height = PLOT_H, bg = PLOT_BG)

# Counts and labels for the bar plot
tbl       <- table(df$charted)
bar_names <- c("Not Charted (0)\nn = 125,127", "Charted (1)\nn = 3,618")
bar_cols  <- c(COL_0, COL_1)

# Draw the bar plot
bp <- barplot(
  tbl,
  names.arg = bar_names,
  col       = bar_cols,
  border    = "white",
  ylim      = c(0, max(tbl) * 1.15),
  main      = "Class Balance: charted vs. not charted",
  ylab      = "Number of Songs",
  cex.names = 1.0,
  cex.main  = 1.2
)

# Add count labels on top of bars
text(bp, tbl + max(tbl) * 0.02,
     labels = format(as.integer(tbl), big.mark = ","),
     cex = 1.1, font = 2)

# Add proportion labels inside bars
props <- round(prop.table(tbl) * 100, 1)
text(bp, tbl / 2,
     labels = paste0(props, "%"),
     cex = 1.1, col = "white", font = 2)

# Add a note about imbalance
mtext("NOTE: Severe class imbalance — 34.6:1 ratio (not charted : charted)",
      side = 1, line = 3, cex = 0.85, col = "firebrick")

dev.off()
cat("  Saved:", out_path, "\n")

# ── 2B. HISTOGRAMS AND BOXPLOTS FOR EACH AUDIO FEATURE ────────────────────────

cat("\nPlotting histograms and boxplots for all 9 audio features...\n")

for (i in seq_along(audio_features)) {

  feat  <- audio_features[i]
  label <- feature_labels[i]

  # Pull the numeric column
  all_vals <- df[[feat]]
  vals0    <- df0[[feat]]
  vals1    <- df1[[feat]]

  # ------------------------------------------------------------------
  # HISTOGRAM: overall distribution across all songs
  # ------------------------------------------------------------------
  hist_path <- paste0("outputs/figures/eda/histogram_", feat, ".png")
  png(hist_path, width = PLOT_W, height = PLOT_H, bg = PLOT_BG)

  hist(
    all_vals,
    breaks  = 40,
    col     = COL_HIST,
    border  = "white",
    main    = paste("Distribution of", label, "(all 128,745 songs)"),
    xlab    = label,
    ylab    = "Number of Songs",
    cex.main = 1.1
  )

  # Vertical lines for group means
  abline(v = mean(vals0, na.rm = TRUE), col = COL_0, lwd = 2, lty = 2)
  abline(v = mean(vals1, na.rm = TRUE), col = COL_1, lwd = 2, lty = 2)

  legend("topright",
         legend = c(
           paste0("Mean (not charted): ", round(mean(vals0, na.rm=TRUE), 3)),
           paste0("Mean (charted):     ", round(mean(vals1, na.rm=TRUE), 3))
         ),
         col    = c(COL_0, COL_1),
         lty    = 2, lwd = 2,
         bty    = "n", cex = 0.9)

  dev.off()
  cat("  Saved:", hist_path, "\n")

  # ------------------------------------------------------------------
  # BOXPLOT: distribution by charted group (0 vs 1)
  # ------------------------------------------------------------------
  box_path <- paste0("outputs/figures/eda/boxplot_", feat, "_by_charted.png")
  png(box_path, width = PLOT_W, height = PLOT_H, bg = PLOT_BG)

  # Compute a common y-axis range using the 1st–99th percentile of all values
  # (avoids extreme outliers collapsing the chart)
  y_lo <- quantile(all_vals, 0.005, na.rm = TRUE)
  y_hi <- quantile(all_vals, 0.995, na.rm = TRUE)
  y_pad <- (y_hi - y_lo) * 0.10
  ylims <- c(y_lo - y_pad, y_hi + y_pad)

  boxplot(
    list(`Not Charted\n(0)` = vals0,
         `Charted\n(1)`     = vals1),
    col     = c(COL_0, COL_1),
    border  = c("#2E6BA8", "#C05A10"),
    outline = FALSE,        # hide extreme outliers for readability
    ylim    = ylims,
    main    = paste(label, "— by Charted Group"),
    ylab    = label,
    xlab    = "charted",
    cex.main = 1.1,
    notch   = FALSE
  )

  # Add group mean as a red diamond
  points(1, mean(vals0, na.rm = TRUE), pch = 23, bg = "red", cex = 1.3)
  points(2, mean(vals1, na.rm = TRUE), pch = 23, bg = "red", cex = 1.3)

  # Add sample size below x-axis labels
  mtext(paste0("n = ", format(length(vals0), big.mark=",")),
        at = 1, side = 1, line = 2.5, cex = 0.8)
  mtext(paste0("n = ", format(length(vals1), big.mark=",")),
        at = 2, side = 1, line = 2.5, cex = 0.8)

  # Note: extreme outliers suppressed (outline = FALSE)
  mtext("Red diamond = group mean | Extreme outliers hidden for readability",
        side = 1, line = 4, cex = 0.75, col = "grey40")

  dev.off()
  cat("  Saved:", box_path, "\n")
}

# ── 2C. CORRELATION MATRIX ────────────────────────────────────────────────────

cat("\nComputing correlation matrix...\n")

cor_mat <- cor(df[, audio_features], use = "complete.obs")

# Save as CSV
cor_csv_path <- "outputs/tables/audio_feature_correlation_matrix.csv"
write.csv(round(cor_mat, 4), cor_csv_path)
cat("  Saved:", cor_csv_path, "\n")

# ------------------------------------------------------------------
# CORRELATION HEATMAP (base R image + text annotations)
# ------------------------------------------------------------------
heatmap_path <- "outputs/figures/eda/audio_feature_correlation_heatmap.png"
png(heatmap_path, width = 900, height = 820, bg = PLOT_BG)

n    <- nrow(cor_mat)
flab <- c("Dance.", "Energy", "Valence", "Tempo", "Loudness",
          "Acoustic.", "Speech.", "Instrm.", "Livness")  # short axis labels
pal  <- colorRampPalette(c("#2166AC", "#F7F7F7", "#B2182B"))(200)

# Margins: bottom, left, top, right
par(mar = c(7, 7.5, 4.5, 4))

# image(x, y, z): x goes left→right, y goes bottom→top, z[i,j] at (x=i, y=j)
# To display row 1 of cor_mat at the TOP, reverse row order then transpose:
#   z[i,j] = cor_mat[n+1-j, i]
z <- t(cor_mat[n:1, ])

image(1:n, 1:n, z,
      col  = pal,
      zlim = c(-1, 1),
      xaxt = "n", yaxt = "n",
      main = "Correlation Matrix — 9 Spotify Audio Features",
      xlab = "", ylab = "")

# x-axis: feature names (columns of cor_mat = features 1..n left to right)
axis(1, at = 1:n, labels = flab, las = 2, cex.axis = 0.85, tick = FALSE)

# y-axis: reversed feature names (row 1 = top = y=n; row n = bottom = y=1)
axis(2, at = 1:n, labels = rev(flab), las = 2, cex.axis = 0.85, tick = FALSE)

# Correlation value text at each cell
# At image position (x=i, y=j) the value is z[i,j] = cor_mat[n+1-j, i]
for (i in 1:n) {
  for (j in 1:n) {
    r_val    <- cor_mat[n + 1L - j, i]
    txt_col  <- if (abs(r_val) > 0.45) "white" else "grey20"
    text(i, j, sprintf("%.2f", r_val), cex = 0.78, col = txt_col)
  }
}

# Grid lines to separate cells
abline(h = seq(0.5, n + 0.5), col = "grey70", lwd = 0.6)
abline(v = seq(0.5, n + 0.5), col = "grey70", lwd = 0.6)

# Color scale legend on the right
par(new = TRUE, mar = c(7, 7.5, 4.5, 1.5))
legend_vals <- seq(-1, 1, length.out = 200)
legend_mat  <- matrix(legend_vals, nrow = 1)
image(1, seq(-1, 1, length.out = 200), legend_mat,
      col = pal, axes = FALSE, xlab = "", ylab = "")
axis(4, at = c(-1, -0.5, 0, 0.5, 1), las = 1, cex.axis = 0.75)
box()

dev.off()
cat("  Saved:", heatmap_path, "\n")

# ── 2D. GROUP SUMMARY TABLE ───────────────────────────────────────────────────

cat("\nBuilding group summary table...\n")

# For each audio feature, compute summary stats by charted group
summary_rows <- list()

for (feat in audio_features) {
  v0 <- df0[[feat]]
  v1 <- df1[[feat]]

  for (grp in c(0, 1)) {
    v <- if (grp == 0) v0 else v1
    summary_rows[[length(summary_rows) + 1]] <- data.frame(
      feature  = feat,
      charted  = grp,
      n        = length(v),
      mean     = round(mean(v, na.rm = TRUE), 5),
      median   = round(median(v, na.rm = TRUE), 5),
      sd       = round(sd(v, na.rm = TRUE), 5),
      min      = round(min(v, na.rm = TRUE), 5),
      max      = round(max(v, na.rm = TRUE), 5),
      stringsAsFactors = FALSE
    )
  }
}

summary_df <- do.call(rbind, summary_rows)

group_summary_path <- "outputs/tables/eda_group_summary_by_charted.csv"
write.csv(summary_df, group_summary_path, row.names = FALSE)
cat("  Saved:", group_summary_path, "\n")

# Print to console too
cat("\n--- Group means (charted=0 vs charted=1, difference) ---\n")
for (feat in audio_features) {
  m0   <- summary_df$mean[summary_df$feature == feat & summary_df$charted == 0]
  m1   <- summary_df$mean[summary_df$feature == feat & summary_df$charted == 1]
  diff <- m1 - m0
  cat(sprintf("  %-18s  mean0=%7.4f  mean1=%7.4f  diff=%+.4f\n",
              feat, m0, m1, diff))
}
cat("\n")

# ── 3. WRITE MARKDOWN SUMMARY ─────────────────────────────────────────────────

cat("Writing EDA markdown summary...\n")

# Identify top 3 features with biggest mean difference (by absolute value)
diffs <- sapply(audio_features, function(f) {
  m0 <- mean(df0[[f]], na.rm = TRUE)
  m1 <- mean(df1[[f]], na.rm = TRUE)
  abs(m1 - m0)
})
top3_features <- names(sort(diffs, decreasing = TRUE))[1:3]

# Top 3 pairwise correlations (upper triangle, by absolute value)
upper_pairs <- list()
for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    if (j > i) {
      upper_pairs[[length(upper_pairs)+1]] <-
        list(f1=audio_features[i], f2=audio_features[j],
             r=cor_mat[i, j], absr=abs(cor_mat[i, j]))
    }
  }
}
upper_pairs <- upper_pairs[order(sapply(upper_pairs, `[[`, "absr"), decreasing=TRUE)]

md_lines <- c(
  "# Step 2: Exploratory Data Analysis (EDA)",
  "",
  "> **Status: COMPLETE**",
  "",
  "---",
  "",
  "## What Is EDA?",
  "",
  "Exploratory Data Analysis (EDA) means looking at your data through graphs",
  "and summary statistics **before** doing any formal analysis. The goal is to",
  "understand the shape of the data, spot patterns, and ask better questions.",
  "",
  "EDA does NOT prove anything. It shows possibilities — things worth testing",
  "formally in the next steps (hypothesis testing, PCA, logistic regression).",
  "",
  "---",
  "",
  "## Dataset Used",
  "",
  paste("- **File:** `data/processed/spotify_billboard_merged_full.csv`"),
  paste("- **Rows:** 128,745 songs"),
  paste("- **Outcome column:** `charted` (0 = not on Billboard, 1 = on Billboard)"),
  paste("- **Features explored:** 9 Spotify audio features"),
  "",
  "---",
  "",
  "## Why Class Imbalance Matters Visually",
  "",
  "This dataset is heavily imbalanced:",
  "",
  "| Class | Count | Share |",
  "|-------|-------|-------|",
  "| charted = 0 (not charted) | 125,127 | 97.2% |",
  "| charted = 1 (charted)     |   3,618 |  2.8% |",
  "",
  "When we draw a **boxplot by group**, the `charted=0` box is built from",
  "125,127 songs, and `charted=1` from only 3,618. This means the boxes may",
  "look tight and similar even if real differences exist — because the smaller",
  "group's box can be influenced more by its own internal spread.",
  "",
  "The **histograms** show the full distribution over all 128,745 songs. Since",
  "97% of songs are non-charted, the histogram shape is dominated by that group.",
  "",
  "---",
  "",
  "## Plots Created",
  "",
  "### 1. Class Balance Bar Chart",
  "- File: `outputs/figures/eda/charted_class_balance.png`",
  "- Shows how many songs are in each class. Confirms the 34.6:1 imbalance.",
  "",
  "### 2. Histograms (9 total, one per feature)",
  "- Files: `outputs/figures/eda/histogram_{feature}.png`",
  "- Show the overall distribution of each audio feature across all songs.",
  "- Dashed vertical lines mark the group means for charted vs. not charted.",
  "- Helps you see: Is the feature skewed? Are there outliers? Where is the bulk?",
  "",
  "### 3. Boxplots by Charted Group (9 total)",
  "- Files: `outputs/figures/eda/boxplot_{feature}_by_charted.png`",
  "- Compare the distribution of each feature between charted and non-charted songs.",
  "- The box shows the middle 50% of values (IQR), the line shows the median,",
  "  the diamond shows the mean.",
  "- Extreme outliers are hidden (`outline=FALSE`) for readability.",
  "",
  "### 4. Correlation Heatmap",
  "- File: `outputs/figures/eda/audio_feature_correlation_heatmap.png`",
  "- Shows how strongly each pair of audio features is related to each other.",
  "- Blue = negative correlation, Red = positive correlation, White = no correlation.",
  "- Numbers in each cell show the exact correlation coefficient (−1 to +1).",
  "",
  "---",
  "",
  "## What Each Feature Looks Like",
  "",
  "| Feature | Charted Mean | Not-Charted Mean | Difference | Direction |",
  "|---------|-------------|-----------------|------------|-----------|",
  paste(sapply(audio_features, function(f) {
    m0   <- mean(df0[[f]], na.rm=TRUE)
    m1   <- mean(df1[[f]], na.rm=TRUE)
    diff <- m1 - m0
    dir  <- if (diff > 0) "higher in charted" else "lower in charted"
    sprintf("| `%s` | %.3f | %.3f | %+.3f | %s |",
            f, m1, m0, diff, dir)
  }), collapse="\n"),
  "",
  "---",
  "",
  paste0("## Top 3 Most Visually Different Features"),
  "",
  "Based on the difference in group means (absolute value), these features",
  "show the clearest visible separation between charted and non-charted songs:",
  "",
  paste(sapply(seq_along(top3_features), function(k) {
    f    <- top3_features[k]
    m0   <- mean(df0[[f]], na.rm=TRUE)
    m1   <- mean(df1[[f]], na.rm=TRUE)
    diff <- m1 - m0
    dir  <- if (diff > 0) "higher" else "lower"
    sprintf("%d. **`%s`** — charted songs have %s values (diff = %+.3f)",
            k, f, dir, diff)
  }), collapse="\n"),
  "",
  "**What this suggests (visual observation only):**",
  "- Charted songs tend to be **louder** (higher loudness in dB).",
  "- Charted songs tend to be **less acoustic** (more produced/electronic sound).",
  "- Charted songs tend to be **more energetic**.",
  "- These patterns are visual only — formal hypothesis testing comes next.",
  "",
  "---",
  "",
  "## Correlation Among the 9 Features",
  "",
  "| Pair | Correlation | Interpretation |",
  "|------|-------------|----------------|",
  paste(sapply(upper_pairs[1:6], function(p) {
    interp <- if (p$r > 0.5)       "strong positive"
              else if (p$r > 0.2)  "moderate positive"
              else if (p$r < -0.5) "strong negative"
              else if (p$r < -0.2) "moderate negative"
              else                  "weak"
    sprintf("| `%s` × `%s` | %.3f | %s |", p$f1, p$f2, p$r, interp)
  }), collapse="\n"),
  "",
  "**Key takeaways:**",
  "- **Energy and Loudness** are strongly positively correlated (+0.75).",
  "  Louder songs tend to also be more energetic — they capture a similar",
  "  concept from two angles.",
  "- **Energy and Acousticness** are strongly negatively correlated (−0.69).",
  "  Acoustic songs tend to be quieter and less intense.",
  "- Because of this overlap, PCA in Step 4 will help reduce redundancy",
  "  among features before building the logistic regression model.",
  "",
  "---",
  "",
  "## Important Caution",
  "",
  "> These are **visual observations only**. They are NOT statistical proof.",
  ">",
  "> A difference in group means could happen by chance, especially with an",
  "> imbalanced dataset. The next step (hypothesis testing) will formally test",
  "> whether these differences are statistically significant.",
  "",
  "---",
  "",
  "## Output Files",
  "",
  "| Type | File |",
  "|------|------|",
  "| Bar chart | `outputs/figures/eda/charted_class_balance.png` |",
  paste(sapply(audio_features, function(f)
    sprintf("| Histogram | `outputs/figures/eda/histogram_%s.png` |", f)),
    collapse="\n"),
  paste(sapply(audio_features, function(f)
    sprintf("| Boxplot | `outputs/figures/eda/boxplot_%s_by_charted.png` |", f)),
    collapse="\n"),
  "| Heatmap | `outputs/figures/eda/audio_feature_correlation_heatmap.png` |",
  "| Correlation CSV | `outputs/tables/audio_feature_correlation_matrix.csv` |",
  "| Group summary CSV | `outputs/tables/eda_group_summary_by_charted.csv` |",
  "",
  "---",
  "",
  paste("*EDA run:", format(Sys.time()), "*")
)

docs_path <- "docs/step2_eda_summary.md"
writeLines(md_lines, docs_path)
cat("  Saved:", docs_path, "\n\n")

# ── 4. FINAL REPORT TO CONSOLE ────────────────────────────────────────────────

cat("=============================================================\n")
cat("  EDA COMPLETE — 02_eda.R\n")
cat("=============================================================\n")
cat("  Dataset        :", dataset_path, "\n")
cat("  Rows           :", nrow(df), "\n")
cat("  Features       :", length(audio_features), "\n")
cat("  Plots created  :", 1 + 2*length(audio_features) + 1, "(total)\n")
cat("  Tables created : 2 (correlation matrix + group summary)\n")
cat("  No hypothesis testing done.\n")
cat("  No PCA done.\n")
cat("  No modeling done.\n")
cat("  No sampling or balancing done.\n")
cat("  Next step: scripts/03_hypothesis_testing.R\n")
cat("=============================================================\n")

# List all created plot files for verification
cat("\nPlot files created:\n")
created_plots <- list.files("outputs/figures/eda", full.names = TRUE)
for (p in created_plots) cat(" ", p, "\n")
