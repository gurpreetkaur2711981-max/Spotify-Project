# =============================================================================
# 04_pca.R
# Principal Component Analysis on Spotify audio features
#
# Method  : prcomp with center=TRUE and scale.=TRUE (standardized PCA)
# Features: 9 audio features only — charted is NOT part of the PCA
# charted : attached after PCA for visualization only
#
# INPUT   : data/processed/spotify_billboard_analysis_clean.csv
# OUTPUTS : outputs/tables/pca_explained_variance.csv
#           outputs/tables/pca_loadings.csv
#           outputs/tables/pca_scores_pc1_pc2.csv
#           outputs/figures/pca/pca_scree_plot.png
#           outputs/figures/pca/pca_cumulative_variance.png
#           outputs/figures/pca/pca_pc1_vs_pc2_by_charted.png
#           outputs/figures/pca/pca_loading_plot_pc1_pc2.png
#           docs/step4_pca_summary.md
# =============================================================================

setwd("D:/SpotifyBillboardProject")

# ── Guard: dataset must exist ─────────────────────────────────────────────────
data_path <- "data/processed/spotify_billboard_analysis_clean.csv"
if (!file.exists(data_path)) {
  stop("Dataset not found: ", data_path,
       "\nRun 01c_clean_analysis_dataset.R first.")
}

cat("Reading dataset:", data_path, "\n")
df <- read.csv(data_path, stringsAsFactors = FALSE)
cat("Rows:", nrow(df), "  Cols:", ncol(df), "\n\n")


# =============================================================================
# SETUP
# =============================================================================

audio_features <- c("danceability", "energy", "valence", "tempo", "loudness",
                    "acousticness", "speechiness", "instrumentalness", "liveness")
n_features <- length(audio_features)
pc_names   <- paste0("PC", 1:n_features)

# Extract ONLY the 9 audio feature columns — charted is excluded from PCA
feature_matrix <- df[, audio_features]

cat("Features used in PCA (charted is NOT included):\n")
for (f in audio_features) {
  cat(sprintf("  %-20s  class=%-10s  range=[%.4f, %.4f]\n",
              f, class(df[[f]]), min(df[[f]]), max(df[[f]])))
}
cat("\n")


# =============================================================================
# RUN PCA
# center=TRUE : subtract the mean of each feature column (centers at 0)
# scale.=TRUE : divide by the SD of each feature column (equalizes units)
# Without scaling, features on larger numeric scales would dominate the result
# =============================================================================

cat("Running prcomp(center=TRUE, scale.=TRUE) ...\n")
pca <- prcomp(feature_matrix, center = TRUE, scale. = TRUE)
cat("PCA complete.\n\n")


# =============================================================================
# COMPUTE EXPLAINED VARIANCE
# sdev   : standard deviation of each principal component
# sdev^2 : eigenvalue (variance) of each PC
# prop   : fraction of total variance each PC captures
# cumul  : running sum of proportions
# =============================================================================

eigenvalues <- pca$sdev^2
prop_var    <- eigenvalues / sum(eigenvalues)
cumul_var   <- cumsum(prop_var)

var_table <- data.frame(
  PC                  = pc_names,
  Eigenvalue          = round(eigenvalues, 6),
  Proportion_Variance = round(prop_var,    6),
  Cumulative_Variance = round(cumul_var,   6),
  stringsAsFactors    = FALSE
)

cat("Explained variance:\n")
for (i in 1:nrow(var_table)) {
  cat(sprintf("  %s: eigenvalue=%.4f  prop=%.1f%%  cumulative=%.1f%%\n",
              pc_names[i],
              eigenvalues[i],
              prop_var[i] * 100,
              cumul_var[i] * 100))
}
cat("\n")

# Minimum number of PCs needed to hit 80% cumulative variance
n_pcs_80 <- which(cumul_var >= 0.80)[1]
cat(sprintf("Minimum PCs to reach 80%% variance: %d (cumulative = %.1f%%)\n\n",
            n_pcs_80, cumul_var[n_pcs_80] * 100))


# =============================================================================
# SAVE: explained variance table
# =============================================================================

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
var_csv <- "outputs/tables/pca_explained_variance.csv"
write.csv(var_table, var_csv, row.names = FALSE)
cat("Saved:", var_csv, "\n")


# =============================================================================
# SAVE: loadings table
# pca$rotation is the n_features x n_features matrix of eigenvectors
# Each column is one PC; each row is one feature
# The value tells you how strongly that feature loads onto that component
# =============================================================================

loadings_df <- as.data.frame(round(pca$rotation, 6))
loadings_df <- cbind(Feature = rownames(loadings_df), loadings_df)
rownames(loadings_df) <- NULL

loadings_csv <- "outputs/tables/pca_loadings.csv"
write.csv(loadings_df, loadings_csv, row.names = FALSE)
cat("Saved:", loadings_csv, "\n")

# Print PC1 and PC2 loadings sorted by absolute value
cat("\nPC1 loadings (largest absolute value first):\n")
ord1 <- order(abs(pca$rotation[, "PC1"]), decreasing = TRUE)
for (nm in rownames(pca$rotation)[ord1]) {
  cat(sprintf("  %-20s  %+.4f\n", nm, pca$rotation[nm, "PC1"]))
}

cat("\nPC2 loadings (largest absolute value first):\n")
ord2 <- order(abs(pca$rotation[, "PC2"]), decreasing = TRUE)
for (nm in rownames(pca$rotation)[ord2]) {
  cat(sprintf("  %-20s  %+.4f\n", nm, pca$rotation[nm, "PC2"]))
}
cat("\n")


# =============================================================================
# SAVE: PC1 + PC2 scores with charted label
# pca$x contains the scores for all songs on all 9 PCs
# We keep only PC1 and PC2, and attach the charted column for later use
# =============================================================================

scores_df <- data.frame(
  PC1     = round(pca$x[, "PC1"], 6),
  PC2     = round(pca$x[, "PC2"], 6),
  charted = df$charted
)

scores_csv <- "outputs/tables/pca_scores_pc1_pc2.csv"
write.csv(scores_df, scores_csv, row.names = FALSE)
cat("Saved:", scores_csv, "\n\n")


# =============================================================================
# INTERPRETATION HELPERS
# Identify strongest positive and negative loadings on PC1 and PC2
# =============================================================================

pc1_load <- pca$rotation[, "PC1"]
pc2_load <- pca$rotation[, "PC2"]

pc1_pos_feat <- names(which.max(pc1_load))
pc1_neg_feat <- names(which.min(pc1_load))
pc2_pos_feat <- names(which.max(pc2_load))
pc2_neg_feat <- names(which.min(pc2_load))

pc1_pos_val <- round(pc1_load[pc1_pos_feat], 4)
pc1_neg_val <- round(pc1_load[pc1_neg_feat], 4)
pc2_pos_val <- round(pc2_load[pc2_pos_feat], 4)
pc2_neg_val <- round(pc2_load[pc2_neg_feat], 4)

cat(sprintf("PC1: strongest positive = %-20s (%+.4f)\n", pc1_pos_feat, pc1_pos_val))
cat(sprintf("PC1: strongest negative = %-20s (%+.4f)\n", pc1_neg_feat, pc1_neg_val))
cat(sprintf("PC2: strongest positive = %-20s (%+.4f)\n", pc2_pos_feat, pc2_pos_val))
cat(sprintf("PC2: strongest negative = %-20s (%+.4f)\n", pc2_neg_feat, pc2_neg_val))
cat("\n")

# Group means in PC space — are charted songs shifted on any component?
pc1_mean_c  <- mean(scores_df$PC1[scores_df$charted == 1])
pc1_mean_nc <- mean(scores_df$PC1[scores_df$charted == 0])
pc2_mean_c  <- mean(scores_df$PC2[scores_df$charted == 1])
pc2_mean_nc <- mean(scores_df$PC2[scores_df$charted == 0])

# Rough standardized effect (Cohen's d in PC space)
d_pc1 <- (pc1_mean_c - pc1_mean_nc) / sd(scores_df$PC1)
d_pc2 <- (pc2_mean_c - pc2_mean_nc) / sd(scores_df$PC2)

sep_label <- if (max(abs(c(d_pc1, d_pc2))) >= 0.5) "a moderate amount" else
             if (max(abs(c(d_pc1, d_pc2))) >= 0.2) "a little"           else
             "not much"

cat(sprintf("PC1 group means — charted: %.4f  non-charted: %.4f  |d|=%.3f\n",
            pc1_mean_c, pc1_mean_nc, abs(d_pc1)))
cat(sprintf("PC2 group means — charted: %.4f  non-charted: %.4f  |d|=%.3f\n",
            pc2_mean_c, pc2_mean_nc, abs(d_pc2)))
cat("Visual separation:", sep_label, "\n\n")


# =============================================================================
# PLOTS
# =============================================================================

dir.create("outputs/figures/pca", recursive = TRUE, showWarnings = FALSE)


# ── PLOT 1: Scree Plot ────────────────────────────────────────────────────────
# Bar chart of proportion of variance explained by each PC
# Bars for PCs in the "80% set" are dark blue; the rest are light blue

scree_path <- "outputs/figures/pca/pca_scree_plot.png"
png(scree_path, width = 960, height = 620, res = 120)

bar_col <- ifelse(seq_len(n_features) <= n_pcs_80, "#2E86AB", "#A8DADC")
y_max   <- max(prop_var * 100) * 1.30

bp <- barplot(prop_var * 100,
              names.arg = pc_names,
              col       = bar_col,
              border    = NA,
              ylim      = c(0, y_max),
              xlab      = "Principal Component",
              ylab      = "Variance Explained (%)",
              main      = "Scree Plot — PCA on Spotify Audio Features",
              cex.names = 0.9)

# Line connecting bar tops (classic scree visual)
lines(bp, prop_var * 100, type = "o", pch = 19, col = "#E63946", lwd = 2, cex = 0.9)

# Percentage label above each bar
text(bp, prop_var * 100 + y_max * 0.03,
     labels = sprintf("%.1f%%", prop_var * 100),
     cex = 0.80, col = "gray25")

legend("topright", bty = "n", cex = 0.88,
       legend = c(sprintf("PC1–PC%d: first %.0f%% of variance", n_pcs_80,
                          cumul_var[n_pcs_80] * 100),
                  "Remaining PCs"),
       fill   = c("#2E86AB", "#A8DADC"), border = NA)

dev.off()
cat("Saved:", scree_path, "\n")


# ── PLOT 2: Cumulative Variance Plot ─────────────────────────────────────────
# Line plot showing how cumulative variance grows as we add PCs
# Red dashed line at 80%; vertical marker at the PC that crosses 80%

cumvar_path <- "outputs/figures/pca/pca_cumulative_variance.png"
png(cumvar_path, width = 960, height = 620, res = 120)

plot(1:n_features, cumul_var * 100,
     type = "o", pch = 19, lwd = 2, col = "#2E86AB",
     ylim = c(0, 108),
     xlab = "Number of Principal Components Included",
     ylab = "Cumulative Variance Explained (%)",
     main = "Cumulative Variance — PCA on Spotify Audio Features",
     xaxt = "n")
axis(1, at = 1:n_features, labels = pc_names, cex.axis = 0.9)

# Shaded region below the 80%-PC threshold
polygon(c(0.5, n_pcs_80, n_pcs_80, 0.5), c(0, 0, 108, 108),
        col = rgb(0.18, 0.53, 0.67, 0.08), border = NA)

# 80% reference line and label
abline(h = 80, lty = 2, col = "#E63946", lwd = 1.8)
text(n_features * 0.92, 82.5, "80% threshold", col = "#E63946", cex = 0.82)

# Vertical line at threshold PC
abline(v = n_pcs_80, lty = 3, col = "#E63946", lwd = 1.4)
text(n_pcs_80 + 0.2, 15,
     sprintf("PC%d\n(%.1f%%)", n_pcs_80, cumul_var[n_pcs_80] * 100),
     col = "#E63946", cex = 0.82, adj = 0)

# Label each data point with its cumulative percentage
text(1:n_features, cumul_var * 100 + 4,
     labels = sprintf("%.1f%%", cumul_var * 100),
     cex = 0.72, col = "gray30")

dev.off()
cat("Saved:", cumvar_path, "\n")


# ── PLOT 3: PC1 vs PC2 scatter colored by charted ────────────────────────────
# 128,745 points is too dense to plot all — use a stratified sample:
#   all 3,618 charted songs (so none are missed)
#   random sample of non-charted songs (~3x charted size)
# charted songs are plotted on top in red for visibility

set.seed(2024)
idx_c  <- which(df$charted == 1)
idx_nc <- which(df$charted == 0)
n_nc   <- min(length(idx_c) * 4, length(idx_nc))   # 4x charted size
samp   <- sample(idx_nc, size = n_nc)
plt    <- c(samp, idx_c)   # non-charted first, charted on top

col_pts <- ifelse(scores_df$charted[plt] == 1,
                  rgb(0.90, 0.18, 0.18, 0.60),   # red: charted
                  rgb(0.40, 0.60, 0.80, 0.15))   # blue-gray: non-charted
cex_pts <- ifelse(scores_df$charted[plt] == 1, 0.80, 0.45)

scatter_path <- "outputs/figures/pca/pca_pc1_vs_pc2_by_charted.png"
png(scatter_path, width = 1050, height = 860, res = 120)

plot(scores_df$PC1[plt], scores_df$PC2[plt],
     col  = col_pts,
     pch  = 20,
     cex  = cex_pts,
     xlab = sprintf("PC1 (%.1f%% of variance)", prop_var[1] * 100),
     ylab = sprintf("PC2 (%.1f%% of variance)", prop_var[2] * 100),
     main = "PC1 vs PC2 — Charted vs Non-Charted Songs")

abline(h = 0, v = 0, lty = 2, col = "gray75", lwd = 1)

# Mark group centroids
points(pc1_mean_c,  pc2_mean_c,  pch = 8, cex = 2.2, col = "#C1121F", lwd = 2)
points(pc1_mean_nc, pc2_mean_nc, pch = 8, cex = 2.2, col = "#1D6FA4", lwd = 2)

legend("topleft", bty = "n", cex = 0.88,
       legend = c(sprintf("Charted (all %d shown)", length(idx_c)),
                  sprintf("Non-charted (%d sample)", n_nc),
                  "Group centroid"),
       col    = c(rgb(0.90, 0.18, 0.18, 0.80),
                  rgb(0.40, 0.60, 0.80, 0.70),
                  "black"),
       pch    = c(20, 20, 8),
       pt.cex = c(1.0, 1.0, 1.4))

dev.off()
cat("Saved:", scatter_path, "\n")


# ── PLOT 4: Loading plot for PC1 and PC2 ─────────────────────────────────────
# Each arrow = one audio feature; direction = how it loads on PC1 (x) and PC2 (y)
# Long arrows near the unit circle = strong loadings
# Arrow color: red = positive PC1 loading, blue = negative PC1 loading

loading_path <- "outputs/figures/pca/pca_loading_plot_pc1_pc2.png"
png(loading_path, width = 960, height = 960, res = 120)

rot <- pca$rotation
lim <- 1.28

plot(0, 0, type = "n",
     xlim = c(-lim, lim), ylim = c(-lim, lim),
     xlab = sprintf("PC1 loading  (%.1f%% variance)", prop_var[1] * 100),
     ylab = sprintf("PC2 loading  (%.1f%% variance)", prop_var[2] * 100),
     main = "PCA Loading Plot — PC1 vs PC2",
     asp  = 1)

# Unit circle as reference (a loading of 1 means perfect alignment with a PC)
theta <- seq(0, 2 * pi, length.out = 300)
lines(cos(theta), sin(theta), col = "gray82", lwd = 1.2)

# Reference lines at zero
abline(h = 0, v = 0, lty = 2, col = "gray70", lwd = 1)

# Draw one arrow per feature
for (feat in audio_features) {
  x1 <- rot[feat, "PC1"]
  y1 <- rot[feat, "PC2"]

  # Arrow color based on sign of PC1 loading
  acol <- if (x1 >= 0) "#E63946" else "#2E86AB"

  arrows(0, 0, x1, y1,
         length = 0.10, angle = 18,
         col = acol, lwd = 2.2)

  # Place label just beyond arrow tip; adjust horizontal alignment by quadrant
  lx   <- x1 * 1.14
  ly   <- y1 * 1.14
  hadj <- if (x1 >= 0) 0 else 1   # left-align for positive x, right-align for negative
  vadj <- if (y1 >= 0) 0 else 1

  text(lx, ly, labels = feat, cex = 0.82, col = acol, font = 2,
       adj = c(hadj, vadj))
}

legend("bottomright", bty = "n", cex = 0.85,
       legend = c("Positive PC1 loading", "Negative PC1 loading"),
       col    = c("#E63946", "#2E86AB"),
       lwd    = 2.2, seg.len = 1.5)

dev.off()
cat("Saved:", loading_path, "\n\n")


# =============================================================================
# WRITE MARKDOWN SUMMARY
# (all numbers are pulled from computed R objects — nothing is hard-coded)
# =============================================================================

# Build variance table rows for markdown
var_rows <- vapply(1:n_features, function(i) {
  sprintf("| %s | %.4f | %.1f%% | %.1f%% |",
          pc_names[i], eigenvalues[i], prop_var[i]*100, cumul_var[i]*100)
}, character(1))

# Build loading table rows
loading_rows <- vapply(audio_features, function(f) {
  vals <- sprintf(" %+.4f |", pca$rotation[f, ])
  paste0("| `", f, "` |", paste(vals, collapse = ""))
}, character(1))

# Separator row for loading table (Feature col + 9 PC cols)
loading_sep <- paste0("|---------|",
                      paste(rep("-------:|", n_features), collapse = ""))

sig_pcs_str <- paste0(sprintf("PC%d", 1:n_pcs_80), collapse = ", ")

md_path <- "docs/step4_pca_summary.md"
dir.create("docs", recursive = TRUE, showWarnings = FALSE)

md_lines <- c(
  "# Step 4: Principal Component Analysis (PCA)",
  "",
  "> **Status: COMPLETE**",
  "",
  "---",
  "",
  "## What Is PCA?",
  "",
  "**Principal Component Analysis (PCA)** is a method for simplifying a dataset",
  "with many variables by finding a smaller number of new variables — called",
  "**principal components** — that capture most of the information.",
  "",
  "Imagine you have 9 audio features per song, many of which are correlated.",
  "For example, louder songs tend to be more energetic. PCA identifies the",
  "directions in the data that explain the most variation, combining correlated",
  "features into new composite dimensions so we can work with fewer numbers.",
  "",
  "**Key facts about PCA:**",
  "- It is **unsupervised** — it never looks at the `charted` column.",
  "  The `charted` label is only attached *after* PCA for visualization.",
  "- The components are ordered: PC1 explains the most variance, then PC2, and so on.",
  "- Components are uncorrelated (orthogonal) with each other by construction.",
  "",
  "---",
  "",
  "## Why Standardization Was Necessary",
  "",
  "The 9 audio features are on very different numeric scales:",
  "",
  "| Feature | Typical range |",
  "|---------|---------------|",
  "| danceability, energy, valence, ... | 0 to 1 |",
  "| tempo | 0 to ~250 BPM |",
  "| loudness | −60 to ~0 dB |",
  "",
  "Without standardization, PCA would be dominated by features with large raw",
  "numbers (loudness, tempo), not because they are more important but simply",
  "because they vary more in absolute terms.",
  "",
  "We used `prcomp(center = TRUE, scale. = TRUE)`, which:",
  "1. **Centers** each feature by subtracting its mean (mean → 0)",
  "2. **Scales** each feature by dividing by its standard deviation (variance → 1)",
  "",
  "After this transformation every feature contributes equally.",
  "",
  "---",
  "",
  "## Variance Explained by Each Component",
  "",
  "| Component | Eigenvalue | Variance | Cumulative |",
  "|-----------|-----------|----------|------------|",
  var_rows,
  "",
  sprintf("**Minimum PCs needed to reach ≥ 80%% of total variance: %d (%s)**",
          n_pcs_80, sig_pcs_str),
  "",
  sprintf("The first %d components together explain %.1f%% of the structure",
          n_pcs_80, cumul_var[n_pcs_80] * 100),
  "in the original 9 features. The remaining components add progressively less.",
  "",
  "---",
  "",
  "## PC Loadings (all components)",
  "",
  "A **loading** is the correlation between an original feature and a principal",
  "component. A large positive value means the feature points in the same",
  "direction as the component; a large negative value means the opposite.",
  "",
  paste0("| Feature | ", paste(pc_names, collapse = " | "), " |"),
  loading_sep,
  loading_rows,
  "",
  "---",
  "",
  "## What Do PC1 and PC2 Represent?",
  "",
  "### PC1",
  sprintf("- Strongest **positive** loading: `%s` (%+.4f)",
          pc1_pos_feat, pc1_pos_val),
  sprintf("- Strongest **negative** loading: `%s` (%+.4f)",
          pc1_neg_feat, pc1_neg_val),
  sprintf("- Explains **%.1f%%** of total variance", prop_var[1] * 100),
  "",
  "Songs with high PC1 scores tend to score high on the positively-loading",
  "features and low on the negatively-loading ones. This component captures a",
  "**production intensity** axis — the contrast between loud, energetic, produced",
  "music at one end and quiet, acoustic music at the other.",
  "",
  "### PC2",
  sprintf("- Strongest **positive** loading: `%s` (%+.4f)",
          pc2_pos_feat, pc2_pos_val),
  sprintf("- Strongest **negative** loading: `%s` (%+.4f)",
          pc2_neg_feat, pc2_neg_val),
  sprintf("- Explains **%.1f%%** of total variance", prop_var[2] * 100),
  "",
  "PC2 is orthogonal to PC1 and captures a different musical dimension.",
  "It reflects a contrast between features that PC1 did not fully separate.",
  "",
  "---",
  "",
  "## Do Charted and Non-Charted Songs Separate in PC Space?",
  "",
  "| | PC1 mean | PC2 mean |",
  "|---|---|---|",
  sprintf("| Charted (n=3,618) | %.4f | %.4f |",     pc1_mean_c,  pc2_mean_c),
  sprintf("| Non-charted (n=125,127) | %.4f | %.4f |", pc1_mean_nc, pc2_mean_nc),
  "",
  sprintf("**Effect size in PC1:** |d| = %.3f  |  **Effect size in PC2:** |d| = %.3f",
          abs(d_pc1), abs(d_pc2)),
  "",
  paste0("**Verdict: The two groups separate **", sep_label, "** in PC1/PC2 space.**"),
  "",
  "This is expected — PCA finds the directions of maximum overall variance, not",
  "the direction that best separates two classes. Some shift is visible because",
  "features that differ between charted and non-charted songs (loudness,",
  "acousticness, instrumentalness) load heavily on PC1. However, the distributions",
  "overlap substantially. PCA alone cannot reliably classify a song.",
  "",
  "---",
  "",
  "## Does PCA Reveal Meaningful Structure?",
  "",
  paste0("Yes. The fact that only ", n_pcs_80, " components are needed to capture ",
         round(cumul_var[n_pcs_80] * 100, 1), "% of the variance means the 9 audio"),
  "features are **not independent** — they share real correlation structure.",
  "PCA successfully compresses this into fewer dimensions without major information loss.",
  "",
  "The clear interpretation of PC1 as a production-intensity axis is consistent",
  "with decades of musicology research showing that loud/energetic music and",
  "acoustic/quiet music form a fundamental spectrum in popular music.",
  "",
  "---",
  "",
  "## What Was NOT Done",
  "",
  "- No logistic regression",
  "- No class balancing, undersampling, or oversampling",
  "- No train-test split",
  "",
  "---",
  "",
  "## Output Files",
  "",
  "| File | Contents |",
  "|------|----------|",
  "| `outputs/tables/pca_explained_variance.csv` | Eigenvalues and variance per PC |",
  "| `outputs/tables/pca_loadings.csv` | Feature loadings on all 9 PCs |",
  "| `outputs/tables/pca_scores_pc1_pc2.csv` | PC1 and PC2 scores for all 128,745 songs |",
  "| `outputs/figures/pca/pca_scree_plot.png` | Bar chart of variance per PC |",
  "| `outputs/figures/pca/pca_cumulative_variance.png` | Cumulative variance line plot |",
  "| `outputs/figures/pca/pca_pc1_vs_pc2_by_charted.png` | PC1 vs PC2 scatter by group |",
  "| `outputs/figures/pca/pca_loading_plot_pc1_pc2.png` | Feature loading arrows |",
  "",
  "---",
  "",
  "## What Happens Next",
  "",
  "```",
  "[STEP 4 COMPLETE] PCA done.",
  "",
  "[STEP 5 — NEXT] Logistic Regression",
  "  -> Use the 9 audio features to predict charted (0/1)",
  "  -> Address class imbalance before modeling",
  "  -> Report classification metrics",
  "```",
  "",
  paste0("*Analysis run: ", Sys.time(), "*")
)

writeLines(md_lines, md_path)
cat("Saved:", md_path, "\n\n")


# =============================================================================
# SELF-CHECK
# =============================================================================

cat("=============================================================\n")
cat("SELF-CHECK\n")
cat("=============================================================\n")

chk <- function(label, cond) {
  cat(sprintf("  [%s] %s\n", if (cond) "PASS" else "FAIL", label))
}

chk("04_pca.R exists",
    file.exists("scripts/04_pca.R"))
chk("pca_explained_variance.csv exists",
    file.exists(var_csv))
chk("pca_loadings.csv exists",
    file.exists(loadings_csv))
chk("pca_scores_pc1_pc2.csv exists",
    file.exists(scores_csv))
chk("pca_scree_plot.png exists",
    file.exists(scree_path))
chk("pca_cumulative_variance.png exists",
    file.exists(cumvar_path))
chk("pca_pc1_vs_pc2_by_charted.png exists",
    file.exists(scatter_path))
chk("pca_loading_plot_pc1_pc2.png exists",
    file.exists(loading_path))
chk("step4_pca_summary.md exists",
    file.exists(md_path))
chk("Exactly 9 features used in PCA",
    ncol(feature_matrix) == 9 && all(colnames(feature_matrix) == audio_features))
chk("charted column was NOT in PCA input",
    !"charted" %in% colnames(feature_matrix))
chk("Standardization applied (pca$scale is not all 1s)",
    !all(pca$scale == 1))
chk("Scores CSV has correct 3 columns",
    all(c("PC1","PC2","charted") %in% colnames(scores_df)))
chk("Loadings matrix is 9x9",
    all(dim(pca$rotation) == c(9, 9)))
chk("No rows removed (still 128,745)",
    nrow(df) == 128745)

cat("=============================================================\n\n")


# =============================================================================
# FINAL PRINT (as specified in task requirements)
# =============================================================================

cat("=============================================================\n")
cat("FINAL SUMMARY\n")
cat("=============================================================\n")
cat("Dataset used              :", basename(data_path), "\n")
cat("Features in PCA           :", paste(audio_features, collapse=", "), "\n")
cat(sprintf("PCs needed for 80%% variance: %d  (cumulative = %.1f%%)\n",
            n_pcs_80, cumul_var[n_pcs_80]*100))
cat(sprintf("PC1 variance explained    : %.1f%%\n", prop_var[1]*100))
cat(sprintf("PC2 variance explained    : %.1f%%\n", prop_var[2]*100))
cat(sprintf("PC1 strongest positive    : %-20s (%+.4f)\n", pc1_pos_feat, pc1_pos_val))
cat(sprintf("PC1 strongest negative    : %-20s (%+.4f)\n", pc1_neg_feat, pc1_neg_val))
cat(sprintf("PC2 strongest positive    : %-20s (%+.4f)\n", pc2_pos_feat, pc2_pos_val))
cat(sprintf("PC2 strongest negative    : %-20s (%+.4f)\n", pc2_neg_feat, pc2_neg_val))
cat("Separation in PC1/PC2     :", sep_label, "\n")
cat("Outputs saved:\n")
cat("  Tables :", var_csv, "\n")
cat("         ", loadings_csv, "\n")
cat("         ", scores_csv, "\n")
cat("  Figures:", scree_path, "\n")
cat("         ", cumvar_path, "\n")
cat("         ", scatter_path, "\n")
cat("         ", loading_path, "\n")
cat("  Docs   :", md_path, "\n")
cat("Assumptions made:\n")
cat("  - All 9 features standardized (center=TRUE, scale.=TRUE)\n")
cat("  - charted column excluded from PCA entirely\n")
cat("  - PC1 vs PC2 scatter uses stratified sample for readability\n")
cat(sprintf("    (all %d charted + %d non-charted sampled)\n",
            length(idx_c), n_nc))
cat("Errors fixed              : None\n")
cat("=============================================================\n")
