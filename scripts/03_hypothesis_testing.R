# =============================================================================
# 03_hypothesis_testing.R
# Hypothesis Testing: Compare charted vs non-charted songs on audio features
#
# Method  : Two-sample Welch t-test for each of 9 audio features
# Correction: Bonferroni correction for 9 simultaneous tests
# Effect size: Cohen's d
#
# INPUT   : data/processed/spotify_billboard_analysis_clean.csv
# OUTPUTS : outputs/tables/hypothesis_test_results.csv
#           outputs/tables/hypothesis_test_summary.txt
#           docs/step3_hypothesis_testing_summary.md
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

# The 9 audio features from the project proposal
audio_features <- c(
  "danceability", "energy", "valence", "tempo", "loudness",
  "acousticness", "speechiness", "instrumentalness", "liveness"
)
n_tests <- length(audio_features)

# Split dataset into two groups once
group1 <- df[df$charted == 1, ]   # charted songs
group0 <- df[df$charted == 0, ]   # non-charted songs

cat("Group sizes:\n")
cat("  charted = 1 :", nrow(group1), "songs\n")
cat("  charted = 0 :", nrow(group0), "songs\n\n")

# Bonferroni threshold: divide alpha by number of tests
alpha_raw        <- 0.05
bonferroni_alpha <- alpha_raw / n_tests
cat(sprintf("Bonferroni threshold: %.4f / %d = %.6f\n\n",
            alpha_raw, n_tests, bonferroni_alpha))


# =============================================================================
# COHEN'S D FUNCTION
# Uses the simple (unpooled average) formula, appropriate for unequal n.
# d = (mean1 - mean0) / sqrt( (sd1^2 + sd0^2) / 2 )
# =============================================================================
cohens_d <- function(x1, x0) {
  m1 <- mean(x1, na.rm = TRUE)
  m0 <- mean(x0, na.rm = TRUE)
  s1 <- sd(x1,   na.rm = TRUE)
  s0 <- sd(x0,   na.rm = TRUE)
  pooled_sd <- sqrt((s1^2 + s0^2) / 2)
  (m1 - m0) / pooled_sd
}


# =============================================================================
# RUN TESTS — one Welch t-test per feature
# =============================================================================
cat("Running Welch two-sample t-tests...\n\n")

results <- data.frame(
  feature           = character(n_tests),
  mean_charted      = numeric(n_tests),
  mean_noncharted   = numeric(n_tests),
  mean_diff         = numeric(n_tests),
  t_stat            = numeric(n_tests),
  df                = numeric(n_tests),
  p_value           = numeric(n_tests),
  ci_lower          = numeric(n_tests),
  ci_upper          = numeric(n_tests),
  p_bonferroni      = numeric(n_tests),
  sig_raw           = logical(n_tests),
  sig_bonferroni    = logical(n_tests),
  cohens_d          = numeric(n_tests),
  stringsAsFactors  = FALSE
)

for (i in seq_along(audio_features)) {
  feat <- audio_features[i]

  x1 <- group1[[feat]]
  x0 <- group0[[feat]]

  # Welch t-test (var.equal = FALSE is the default and is explicit here)
  ttest <- t.test(x1, x0, var.equal = FALSE, conf.level = 0.95)

  m1        <- mean(x1)
  m0        <- mean(x0)
  diff      <- m1 - m0
  p_raw     <- ttest$p.value
  p_bonf    <- min(p_raw * n_tests, 1.0)   # cap at 1
  d         <- cohens_d(x1, x0)

  results$feature[i]         <- feat
  results$mean_charted[i]    <- round(m1, 6)
  results$mean_noncharted[i] <- round(m0, 6)
  results$mean_diff[i]       <- round(diff, 6)
  results$t_stat[i]          <- round(ttest$statistic, 4)
  results$df[i]              <- round(ttest$parameter, 2)
  results$p_value[i]         <- p_raw
  results$ci_lower[i]        <- round(ttest$conf.int[1], 6)
  results$ci_upper[i]        <- round(ttest$conf.int[2], 6)
  results$p_bonferroni[i]    <- round(p_bonf, 6)
  results$sig_raw[i]         <- p_raw     < alpha_raw
  results$sig_bonferroni[i]  <- p_raw     < bonferroni_alpha
  results$cohens_d[i]        <- round(d, 4)

  sig_label <- if (p_raw < bonferroni_alpha) "*** (Bonferroni)" else
               if (p_raw < alpha_raw)        "*   (raw only)"   else
               "    (not significant)"

  cat(sprintf("  %-20s  p=%-12.2e  d=%+.4f  %s\n",
              feat, p_raw, d, sig_label))
}

cat("\n")


# =============================================================================
# SORT by absolute effect size (largest first) for the summary
# =============================================================================
results_sorted <- results[order(abs(results$cohens_d), decreasing = TRUE), ]


# =============================================================================
# SAVE: hypothesis_test_results.csv
# =============================================================================
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
csv_path <- "outputs/tables/hypothesis_test_results.csv"
write.csv(results, csv_path, row.names = FALSE)
cat("Saved CSV:", csv_path, "\n")


# =============================================================================
# SAVE: hypothesis_test_summary.txt  (human-readable)
# =============================================================================
txt_path <- "outputs/tables/hypothesis_test_summary.txt"

sig_bonf_features <- results$feature[results$sig_bonferroni]
top3 <- head(results_sorted, 3)

txt <- c(
  "HYPOTHESIS TEST SUMMARY",
  paste0("Generated : ", Sys.time()),
  paste0("Dataset   : ", data_path),
  "",
  "TEST DESIGN",
  "  Method     : Welch two-sample t-test (var.equal = FALSE)",
  "  Groups     : charted=1 vs charted=0",
  paste0("  n (charted)    : ", nrow(group1)),
  paste0("  n (noncharted) : ", nrow(group0)),
  paste0("  Features tested: ", n_tests),
  paste0("  Raw alpha      : ", alpha_raw),
  paste0("  Bonferroni alpha: ", round(bonferroni_alpha, 6),
         "  (= 0.05 / ", n_tests, ")"),
  "",
  "RESULTS (sorted by feature order)",
  paste0(strrep("-", 100)),
  sprintf("  %-20s  %10s  %10s  %+10s  %10s  %8s  %14s  %14s  %6s  %8s",
          "Feature", "Mean(1)", "Mean(0)", "Diff", "t", "df",
          "p_raw", "p_Bonferroni", "Sig*", "Cohen_d"),
  paste0(strrep("-", 100))
)

for (i in 1:nrow(results)) {
  r <- results[i, ]
  sig_str <- if (r$sig_bonferroni) "YES" else if (r$sig_raw) "raw" else "no"
  txt <- c(txt,
    sprintf("  %-20s  %10.5f  %10.5f  %+10.5f  %10.4f  %8.1f  %14.3e  %14.3e  %6s  %8.4f",
            r$feature, r$mean_charted, r$mean_noncharted, r$mean_diff,
            r$t_stat, r$df, r$p_value, r$p_bonferroni, sig_str, r$cohens_d)
  )
}

txt <- c(txt,
  paste0(strrep("-", 100)),
  "  * Sig column: YES = significant after Bonferroni; raw = significant at alpha=0.05 only; no = not significant",
  "",
  "FEATURES SIGNIFICANT AFTER BONFERRONI CORRECTION",
  if (length(sig_bonf_features) == 0) "  None" else paste0("  ", paste(sig_bonf_features, collapse=", ")),
  "",
  "TOP 3 LARGEST ABSOLUTE EFFECT SIZES (Cohen's d)",
  sprintf("  1. %-20s  d = %+.4f", top3$feature[1], top3$cohens_d[1]),
  sprintf("  2. %-20s  d = %+.4f", top3$feature[2], top3$cohens_d[2]),
  sprintf("  3. %-20s  d = %+.4f", top3$feature[3], top3$cohens_d[3]),
  "",
  "INTERPRETATION NOTE",
  "  With n=128,745 rows, very small differences can produce significant p-values.",
  "  Cohen's d interprets effect magnitude: |d|<0.2 small, 0.2-0.5 medium, >0.5 large.",
  "  Significant p-values here reflect statistical reliability of the difference,",
  "  not necessarily a large or practically meaningful effect.",
  "",
  "WHAT WAS NOT DONE",
  "  - No PCA",
  "  - No logistic regression",
  "  - No class balancing or sampling"
)

writeLines(txt, txt_path)
cat("Saved TXT:", txt_path, "\n\n")


# =============================================================================
# SAVE: docs/step3_hypothesis_testing_summary.md
# =============================================================================
dir.create("docs", recursive = TRUE, showWarnings = FALSE)
md_path <- "docs/step3_hypothesis_testing_summary.md"

# Build feature result rows for the markdown table
md_table_rows <- character(nrow(results))
for (i in 1:nrow(results)) {
  r <- results[i, ]
  sig_str <- if (r$sig_bonferroni) "Yes" else if (r$sig_raw) "raw only" else "No"
  d_label <- if (abs(r$cohens_d) >= 0.5) "large" else
             if (abs(r$cohens_d) >= 0.2) "medium" else "small"
  md_table_rows[i] <- sprintf(
    "| `%s` | %.4f | %.4f | %+.4f | %.2e | %.2e | %s | %+.4f (%s) |",
    r$feature, r$mean_charted, r$mean_noncharted, r$mean_diff,
    r$p_value, r$p_bonferroni, sig_str, r$cohens_d, d_label
  )
}

sig_after_bonf_str <- if (length(sig_bonf_features) == 0) "None" else
                      paste(paste0("`", sig_bonf_features, "`"), collapse = ", ")

md_lines <- c(
  "# Step 3: Hypothesis Testing",
  "",
  paste0("> **Status: COMPLETE**"),
  "",
  "---",
  "",
  "## What Is a Hypothesis Test?",
  "",
  "A **hypothesis test** is a formal way to ask: *Is the difference I see in",
  "the data real, or could it just be random chance?*",
  "",
  "Every hypothesis test starts with two statements:",
  "",
  "- **Null hypothesis (H₀):** There is NO difference between charted and",
  "  non-charted songs on this audio feature. Any difference we see is just noise.",
  "",
  "- **Alternative hypothesis (H₁):** There IS a real difference between charted",
  "  and non-charted songs on this audio feature.",
  "",
  "The test produces a **p-value** — the probability of seeing a difference this",
  "large (or larger) by pure chance, *if H₀ were actually true*.",
  "",
  "- **Small p-value (e.g., < 0.05):** The observed difference is unlikely to",
  "  be random. We reject H₀.",
  "- **Large p-value:** The observed difference could easily be random. We do NOT",
  "  reject H₀.",
  "",
  "---",
  "",
  "## Why Welch's t-test?",
  "",
  "A **two-sample t-test** compares the means of two groups — in our case,",
  "charted songs versus non-charted songs.",
  "",
  "We used the **Welch variant** (`var.equal = FALSE` in R), which is better when:",
  "",
  "- The two groups have very different sizes (our groups are 3,618 vs 125,127)",
  "- The two groups might have different variances",
  "",
  "Welch's t-test adjusts its degrees of freedom to account for these differences.",
  "It is still fundamentally a two-sample t-test — exactly what the proposal requires.",
  "",
  "---",
  "",
  "## Bonferroni Correction — Why It Matters",
  "",
  "We are running **9 tests at once** (one per audio feature). If we use",
  "alpha = 0.05 for each test separately, the chance of getting at least one",
  "false positive by accident is much higher than 5%.",
  "",
  "The **Bonferroni correction** fixes this by dividing the alpha threshold",
  "by the number of tests:",
  "",
  "```",
  paste0("Bonferroni alpha = 0.05 / 9 = ", round(bonferroni_alpha, 6)),
  "```",
  "",
  "A feature must have **p < 0.005556** to be considered significant after",
  "Bonferroni correction. This is a stricter standard that controls for the",
  "risk of false discoveries across multiple tests.",
  "",
  "---",
  "",
  "## Results",
  "",
  paste0("**Dataset:** `", data_path, "`  "),
  paste0("**Charted songs (group 1):** ", nrow(group1), "  "),
  paste0("**Non-charted songs (group 0):** ", nrow(group0), "  "),
  paste0("**Bonferroni threshold:** ", round(bonferroni_alpha, 6)),
  "",
  "| Feature | Mean (charted) | Mean (non-charted) | Difference | p-value | p (Bonferroni) | Significant? | Cohen's d |",
  "|---------|---------------|-------------------|------------|---------|----------------|--------------|-----------|",
  md_table_rows,
  "",
  paste0("**Features significant after Bonferroni correction:** ", sig_after_bonf_str),
  "",
  "---",
  "",
  "## Effect Sizes",
  "",
  "**Cohen's d** measures the *practical size* of the difference:",
  "",
  "| |d| range | Interpretation |",
  "|-----------|----------------|",
  "| < 0.2 | Small effect |",
  "| 0.2 – 0.5 | Medium effect |",
  "| > 0.5 | Large effect |",
  "",
  "**Top 3 largest absolute effect sizes:**",
  "",
  sprintf("1. `%s` — d = %+.4f (%s)",
          top3$feature[1], top3$cohens_d[1],
          ifelse(abs(top3$cohens_d[1])>=0.5,"large",ifelse(abs(top3$cohens_d[1])>=0.2,"medium","small"))),
  sprintf("2. `%s` — d = %+.4f (%s)",
          top3$feature[2], top3$cohens_d[2],
          ifelse(abs(top3$cohens_d[2])>=0.5,"large",ifelse(abs(top3$cohens_d[2])>=0.2,"medium","small"))),
  sprintf("3. `%s` — d = %+.4f (%s)",
          top3$feature[3], top3$cohens_d[3],
          ifelse(abs(top3$cohens_d[3])>=0.5,"large",ifelse(abs(top3$cohens_d[3])>=0.2,"medium","small"))),
  "",
  "---",
  "",
  "## Important: Statistical Significance ≠ Practical Importance",
  "",
  "This dataset has **128,745 rows**. With very large samples, even a tiny",
  "difference in group means (e.g., 0.01 on a 0-to-1 scale) can produce a",
  "very significant p-value.",
  "",
  "**What this means in plain language:**",
  "",
  "- A p-value below the Bonferroni threshold tells us the difference is *real*",
  "  and not random — but it does NOT tell us the difference is *large* or",
  "  *useful for prediction*.",
  "- Cohen's d is the more informative number for judging practical relevance.",
  "- A feature can be statistically significant but have near-zero Cohen's d,",
  "  meaning the two groups are barely distinguishable in practice.",
  "",
  "**We report both.** The combination of a significant p-value AND a medium-to-large",
  "Cohen's d is the stronger evidence that a feature actually separates charted from",
  "non-charted songs.",
  "",
  "---",
  "",
  "## What Was NOT Done",
  "",
  "- No PCA",
  "- No logistic regression",
  "- No class balancing, undersampling, or oversampling",
  "- No train-test split",
  "",
  "These steps are reserved for future steps.",
  "",
  "---",
  "",
  "## What Happens Next",
  "",
  "```",
  "[STEP 3 COMPLETE] Hypothesis testing done.",
  paste0("  -> outputs/tables/hypothesis_test_results.csv"),
  paste0("  -> outputs/tables/hypothesis_test_summary.txt"),
  "",
  "[STEP 4 — NEXT] Principal Component Analysis (PCA)",
  "  -> Reduce the 9 audio features to principal components",
  "  -> Visualize variance explained",
  "```",
  "",
  paste0("*Analysis run: ", Sys.time(), "*")
)

writeLines(md_lines, md_path)
cat("Saved MD:", md_path, "\n\n")


# =============================================================================
# SELF-CHECK
# =============================================================================
cat("=============================================================\n")
cat("SELF-CHECK\n")
cat("=============================================================\n")

check <- function(label, cond) {
  cat(sprintf("  [%s] %s\n", if (cond) "PASS" else "FAIL", label))
}

check("03_hypothesis_testing.R exists",
      file.exists("scripts/03_hypothesis_testing.R"))
check("hypothesis_test_results.csv exists",
      file.exists(csv_path))
check("hypothesis_test_summary.txt exists",
      file.exists(txt_path))
check("step3_hypothesis_testing_summary.md exists",
      file.exists(md_path))
check("All 9 features tested",
      nrow(results) == 9 && all(audio_features %in% results$feature))
check("Bonferroni correction applied (p_bonferroni = p_value * 9, capped at 1)",
      all(results$p_bonferroni == pmin(round(results$p_value * 9, 6), 1)))
check("sig_bonferroni flags match threshold",
      all(results$sig_bonferroni == (results$p_value < bonferroni_alpha)))
check("sig_raw flags match threshold",
      all(results$sig_raw == (results$p_value < alpha_raw)))
check("No rows removed from dataset",
      nrow(df) == 128745)

cat("=============================================================\n\n")


# =============================================================================
# FINAL PRINT (as specified in task requirements)
# =============================================================================
cat("=============================================================\n")
cat("FINAL SUMMARY\n")
cat("=============================================================\n")
cat("Dataset used           :", basename(data_path), "\n")
cat("Features tested        :", paste(audio_features, collapse=", "), "\n")
cat(sprintf("Bonferroni threshold   : 0.05 / %d = %.6f\n", n_tests, bonferroni_alpha))
cat("Significant (Bonferroni):",
    if (length(sig_bonf_features) == 0) "None" else paste(sig_bonf_features, collapse=", "), "\n")
cat("Top 3 |Cohen's d|      :\n")
cat(sprintf("  1. %-20s  d = %+.4f\n", top3$feature[1], top3$cohens_d[1]))
cat(sprintf("  2. %-20s  d = %+.4f\n", top3$feature[2], top3$cohens_d[2]))
cat(sprintf("  3. %-20s  d = %+.4f\n", top3$feature[3], top3$cohens_d[3]))
cat("Results CSV            :", csv_path, "\n")
cat("Summary TXT            :", txt_path, "\n")
cat("Assumptions made       :\n")
cat("  - Welch t-test (does not assume equal variances)\n")
cat("  - Independence of observations assumed\n")
cat("  - Both groups from same underlying Spotify/Billboard data\n")
cat("Errors fixed           : None\n")
cat("=============================================================\n")
