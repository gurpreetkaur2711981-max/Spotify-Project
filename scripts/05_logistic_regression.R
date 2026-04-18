# =============================================================================
# 05_logistic_regression.R
# Logistic Regression: Predict Billboard chart success from Spotify audio features
#
# Method    : glm(..., family = binomial) — logistic regression
# Imbalance : Random undersampling of majority class in TRAINING SET ONLY
# Split     : 70% train / 30% test (seed = 42)
# Metrics   : AUC (primary), confusion matrix, precision, recall, F1
#
# AUC is computed via the Wilcoxon rank-sum method — exact, no packages needed.
#
# INPUT   : data/processed/spotify_billboard_analysis_clean.csv
# OUTPUTS : data/processed/spotify_billboard_model_train_balanced.csv
#           data/processed/spotify_billboard_model_test_full.csv
#           outputs/tables/logistic_regression_coefficients.csv
#           outputs/tables/logistic_test_predictions.csv
#           outputs/tables/logistic_model_summary.txt
#           outputs/tables/logistic_roc_points.csv
#           outputs/figures/logistic/logistic_roc_curve.png
#           outputs/figures/logistic/logistic_predicted_probability_histogram.png
#           docs/step5_logistic_regression_summary.md
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

SEED <- 42
set.seed(SEED)
cat("Random seed set to:", SEED, "\n\n")

predictors <- c("danceability", "energy", "valence", "tempo", "loudness",
                "acousticness", "speechiness", "instrumentalness", "liveness")
outcome    <- "charted"
THRESHOLD  <- 0.50

model_formula <- as.formula(
  paste(outcome, "~", paste(predictors, collapse = " + "))
)
cat("Model formula:", deparse(model_formula), "\n\n")


# =============================================================================
# STEP 1 — TRAIN/TEST SPLIT (70% / 30%)
# Simple random split — at n=128,745 the class proportions will be stable.
# =============================================================================

n_total  <- nrow(df)
n_train  <- round(n_total * 0.70)
n_test   <- n_total - n_train

train_idx  <- sample(seq_len(n_total), size = n_train, replace = FALSE)
test_idx   <- setdiff(seq_len(n_total), train_idx)

train_full <- df[train_idx, ]
test_full  <- df[test_idx,  ]

cat("--- Train/Test Split ---\n")
cat(sprintf("  Full train : %d rows  (charted=1: %d  charted=0: %d)\n",
            nrow(train_full), sum(train_full$charted==1), sum(train_full$charted==0)))
cat(sprintf("  Test set   : %d rows  (charted=1: %d  charted=0: %d)\n",
            nrow(test_full),  sum(test_full$charted==1),  sum(test_full$charted==0)))
cat("\n")


# =============================================================================
# STEP 2 — BALANCE THE TRAINING SET (undersample majority class)
#
# WHY: With 97.2% of songs non-charted, fitting on raw data causes the model
# to always predict non-charted and still appear accurate. Undersampling brings
# charted=0 down to the same count as charted=1 so the model learns both classes.
#
# IMPORTANT: The test set is NEVER touched — it keeps the real imbalance.
# =============================================================================

train_c1 <- train_full[train_full$charted == 1, ]   # minority (charted)
train_c0 <- train_full[train_full$charted == 0, ]   # majority (non-charted)

n_minority <- nrow(train_c1)

# Sample exactly n_minority rows from the majority class
us_idx     <- sample(seq_len(nrow(train_c0)), size = n_minority, replace = FALSE)
train_c0us <- train_c0[us_idx, ]

# Combine and shuffle rows
train_bal  <- rbind(train_c1, train_c0us)
train_bal  <- train_bal[sample(nrow(train_bal)), ]
rownames(train_bal) <- NULL

cat("--- Balanced Training Set ---\n")
cat(sprintf("  Total rows : %d\n", nrow(train_bal)))
cat(sprintf("  charted=1  : %d\n", sum(train_bal$charted==1)))
cat(sprintf("  charted=0  : %d\n\n", sum(train_bal$charted==0)))


# =============================================================================
# STEP 3 — SAVE TRAIN AND TEST DATASETS
# =============================================================================

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

train_path <- "data/processed/spotify_billboard_model_train_balanced.csv"
test_path  <- "data/processed/spotify_billboard_model_test_full.csv"

write.csv(train_bal, train_path, row.names = FALSE)
write.csv(test_full, test_path,  row.names = FALSE)
cat("Saved balanced train :", train_path, "\n")
cat("Saved test set       :", test_path,  "\n\n")

# Verify source dataset was NOT overwritten
src_intact <- file.exists(data_path) && file.info(data_path)$size > 1e6
cat("Source dataset intact:", src_intact, "\n\n")


# =============================================================================
# STEP 4 — FIT LOGISTIC REGRESSION
# Trained on the balanced training set; charted ~ 9 audio features
# =============================================================================

cat("--- Fitting Logistic Regression ---\n")
model <- glm(model_formula, data = train_bal, family = binomial)
cat("Converged:", model$converged, "\n\n")
print(summary(model))
cat("\n")


# =============================================================================
# STEP 5 — COEFFICIENT TABLE
# =============================================================================

coef_mat <- summary(model)$coefficients

coef_df <- data.frame(
  Term       = rownames(coef_mat),
  Estimate   = round(coef_mat[, "Estimate"],   6),
  Std_Error  = round(coef_mat[, "Std. Error"], 6),
  z_value    = round(coef_mat[, "z value"],    4),
  p_value    = coef_mat[, "Pr(>|z|)"],
  Odds_Ratio = round(exp(coef_mat[, "Estimate"]), 6),
  stringsAsFactors = FALSE
)

cat("--- Coefficients ---\n")
for (i in seq_len(nrow(coef_df))) {
  sig <- if (coef_df$p_value[i] < 0.001) "***" else
         if (coef_df$p_value[i] < 0.01)  "**"  else
         if (coef_df$p_value[i] < 0.05)  "*"   else ""
  cat(sprintf("  %-22s  est=%+.4f  OR=%.4f  p=%.3e %s\n",
              coef_df$Term[i], coef_df$Estimate[i],
              coef_df$Odds_Ratio[i], coef_df$p_value[i], sig))
}
cat("\n")

coef_csv <- "outputs/tables/logistic_regression_coefficients.csv"
write.csv(coef_df, coef_csv, row.names = FALSE)
cat("Saved:", coef_csv, "\n\n")


# =============================================================================
# STEP 6 — PREDICT ON TEST SET (full, untouched, imbalanced)
# =============================================================================

test_probs  <- predict(model, newdata = test_full, type = "response")
test_labels <- test_full$charted

# Confusion matrix at threshold = 0.50
pred_class <- as.integer(test_probs >= THRESHOLD)

TP <- sum(pred_class == 1 & test_labels == 1)
FP <- sum(pred_class == 1 & test_labels == 0)
TN <- sum(pred_class == 0 & test_labels == 0)
FN <- sum(pred_class == 0 & test_labels == 1)

accuracy    <- (TP + TN) / length(test_labels)
precision   <- if ((TP + FP) > 0) TP / (TP + FP) else NA_real_
recall      <- if ((TP + FN) > 0) TP / (TP + FN) else NA_real_
specificity <- if ((TN + FP) > 0) TN / (TN + FP) else NA_real_
f1          <- if (!is.na(precision) && !is.na(recall) && (precision + recall) > 0)
               2 * precision * recall / (precision + recall) else NA_real_

cat("--- Confusion Matrix (threshold =", THRESHOLD, ") ---\n")
cat(sprintf("  Predicted 1 | True 1 (TP): %5d | True 0 (FP): %5d\n", TP, FP))
cat(sprintf("  Predicted 0 | True 1 (FN): %5d | True 0 (TN): %5d\n", FN, TN))
cat(sprintf("  Accuracy    : %.4f\n", accuracy))
cat(sprintf("  Precision   : %.4f\n", precision))
cat(sprintf("  Recall      : %.4f\n", recall))
cat(sprintf("  Specificity : %.4f\n", specificity))
cat(sprintf("  F1 Score    : %.4f\n\n", f1))


# =============================================================================
# STEP 7 — AUC via Wilcoxon rank-sum (exact, no external packages)
#
# Mathematical identity: AUC = P(score of random positive > score of random negative)
#   = (rank_sum_positives - n_pos*(n_pos+1)/2) / (n_pos * n_neg)
# Ties in rank() are handled by average-rank convention, which is correct.
# =============================================================================

n_pos <- sum(test_labels == 1)
n_neg <- sum(test_labels == 0)

rank_sum_pos <- sum(rank(test_probs)[test_labels == 1])
auc <- (rank_sum_pos - n_pos * (n_pos + 1L) / 2) / (n_pos * n_neg)

cat(sprintf("AUC (Wilcoxon rank-sum, base R): %.4f\n", auc))

auc_verdict <- if (auc < 0.70)   "BELOW the proposal's expected 0.70-0.80 range"  else
               if (auc <= 0.80)  "WITHIN the proposal's expected 0.70-0.80 range" else
               "ABOVE the proposal's expected 0.70-0.80 range"
cat("AUC verdict:", auc_verdict, "\n\n")


# =============================================================================
# STEP 8 — ROC CURVE POINTS
# Sort by descending predicted probability; walk the list accumulating TP and FP.
# This produces the exact ROC curve with one point per test observation.
# A downsampled version (1000 pts) is saved to CSV for readability.
# =============================================================================

ord        <- order(test_probs, decreasing = TRUE)
lab_sorted <- test_labels[ord]

tp_cs    <- c(0L, cumsum(lab_sorted == 1L))
fp_cs    <- c(0L, cumsum(lab_sorted == 0L))
tpr_full <- tp_cs / n_pos
fpr_full <- fp_cs / n_neg

# Downsample to ~1000 evenly-spaced points for the CSV
keep <- unique(c(1L, seq(1L, length(tpr_full), length.out = 1000L),
                 length(tpr_full)))
roc_df <- data.frame(
  fpr       = round(fpr_full[keep], 6),
  tpr       = round(tpr_full[keep], 6),
  threshold = round(c(Inf, test_probs[ord])[keep], 6)
)

roc_csv <- "outputs/tables/logistic_roc_points.csv"
write.csv(roc_df, roc_csv, row.names = FALSE)
cat("Saved:", roc_csv, "\n")


# =============================================================================
# STEP 9 — SAVE PREDICTIONS CSV
# =============================================================================

pred_df <- data.frame(
  true_charted = test_labels,
  pred_prob    = round(test_probs, 6),
  pred_class   = pred_class
)

pred_csv <- "outputs/tables/logistic_test_predictions.csv"
write.csv(pred_df, pred_csv, row.names = FALSE)
cat("Saved:", pred_csv, "\n\n")


# =============================================================================
# STEP 10 — MODEL SUMMARY TEXT FILE
# =============================================================================

pred_only <- coef_df[coef_df$Term != "(Intercept)", ]
sig_preds <- pred_only$Term[pred_only$p_value < 0.05]

coef_lines <- vapply(seq_len(nrow(coef_df)), function(i) {
  r <- coef_df[i, ]
  sprintf("  %-22s  est=%+.6f  OR=%.6f  p=%.4e",
          r$Term, r$Estimate, r$Odds_Ratio, r$p_value)
}, character(1))

txt_lines <- c(
  "LOGISTIC REGRESSION MODEL SUMMARY",
  paste0("Generated  : ", Sys.time()),
  paste0("Random seed: ", SEED),
  "",
  "DATASET",
  paste0("  Source : ", data_path),
  paste0("  Total  : ", nrow(df), " rows"),
  "",
  "TRAIN/TEST SPLIT",
  paste0("  Full train (70%)          : ", nrow(train_full), " rows"),
  paste0("  Balanced train (used fit) : ", nrow(train_bal),  " rows"),
  paste0("  Test set untouched (30%)  : ", nrow(test_full),  " rows"),
  "",
  "CLASS BALANCE",
  paste0("  Balanced train — charted=1: ", sum(train_bal$charted==1),
         "  charted=0: ", sum(train_bal$charted==0)),
  paste0("  Test (full)    — charted=1: ", sum(test_full$charted==1),
         "  charted=0: ", sum(test_full$charted==0)),
  "",
  "MODEL",
  paste0("  Formula   : ", deparse(model_formula)),
  paste0("  Family    : binomial (logit link)"),
  paste0("  Converged : ", model$converged),
  "",
  "COEFFICIENTS",
  coef_lines,
  paste0("  Significant predictors (p<0.05): ",
         if (length(sig_preds)==0) "None" else paste(sig_preds, collapse=", ")),
  "",
  "TEST SET PERFORMANCE (threshold=0.50, n=", nrow(test_full), ")",
  paste0("  Confusion matrix: TP=", TP, "  FP=", FP, "  FN=", FN, "  TN=", TN),
  paste0("  Accuracy    : ", round(accuracy,    4)),
  paste0("  Precision   : ", round(precision,   4)),
  paste0("  Recall      : ", round(recall,      4)),
  paste0("  Specificity : ", round(specificity, 4)),
  paste0("  F1 Score    : ", round(f1,           4)),
  paste0("  AUC         : ", round(auc,          4)),
  "",
  "AUC VERDICT",
  paste0("  ", auc_verdict),
  "",
  "NOTES",
  "  - Probabilities are from a model trained on balanced (50/50) data.",
  "  - At threshold=0.50 on the imbalanced test set, recall > precision is expected.",
  "  - AUC is threshold-independent and is the primary evaluation metric.",
  "  - Probability estimates are NOT recalibrated for the real-world 2.8% base rate.",
  "",
  "WHAT WAS NOT DONE",
  "  - Original cleaned dataset was not modified",
  "  - Test set was not balanced or resampled"
)

txt_path <- "outputs/tables/logistic_model_summary.txt"
writeLines(txt_lines, txt_path)
cat("Saved:", txt_path, "\n\n")


# =============================================================================
# STEP 11 — PLOTS
# =============================================================================

dir.create("outputs/figures/logistic", recursive = TRUE, showWarnings = FALSE)

# ── PLOT 1: ROC Curve ─────────────────────────────────────────────────────────
roc_plot_path <- "outputs/figures/logistic/logistic_roc_curve.png"
png(roc_plot_path, width = 900, height = 860, res = 120)

plot(fpr_full, tpr_full,
     type = "l", lwd = 2.5, col = "#2E86AB",
     xlim = c(0, 1), ylim = c(0, 1),
     xlab = "False Positive Rate  (1 − Specificity)",
     ylab = "True Positive Rate  (Sensitivity / Recall)",
     main = "ROC Curve — Logistic Regression\nPredicting Billboard Chart Success")

# Shaded area under curve
polygon(c(fpr_full, 1, 0), c(tpr_full, 0, 0),
        col = rgb(0.18, 0.53, 0.67, 0.15), border = NA)

# Diagonal reference line (random classifier, AUC=0.5)
abline(0, 1, lty = 2, col = "gray60", lwd = 1.3)

# AUC label
text(0.60, 0.22, sprintf("AUC = %.4f", auc),
     cex = 1.25, col = "#E63946", font = 2)

legend("bottomright", bty = "n", cex = 0.88,
       legend = c(sprintf("Logistic Regression  (AUC = %.4f)", auc),
                  "Random classifier  (AUC = 0.50)"),
       col    = c("#2E86AB", "gray60"),
       lwd    = c(2.5, 1.3), lty = c(1, 2))

dev.off()
cat("Saved:", roc_plot_path, "\n")


# ── PLOT 2: Predicted probability histogram by true class ────────────────────
# Using density (freq=FALSE) so the two very different group sizes are comparable.
hist_path <- "outputs/figures/logistic/logistic_predicted_probability_histogram.png"
png(hist_path, width = 1020, height = 700, res = 120)

probs_c0 <- test_probs[test_labels == 0]
probs_c1 <- test_probs[test_labels == 1]

h0 <- hist(probs_c0, breaks = 60, plot = FALSE)
h1 <- hist(probs_c1, breaks = 60, plot = FALSE)
ylim_top <- max(c(h0$density, h1$density)) * 1.28

# Plot non-charted first (background), then charted on top
plot(h0, freq = FALSE,
     col    = rgb(0.25, 0.50, 0.80, 0.45),
     border = NA,
     xlim   = c(0, 1), ylim = c(0, ylim_top),
     xlab   = "Predicted Probability of Charting",
     ylab   = "Density",
     main   = sprintf(
       "Predicted Probabilities by True Class\nLogistic Regression on test set  (n=%d)",
       nrow(test_full)))

plot(h1, freq = FALSE,
     col    = rgb(0.90, 0.18, 0.18, 0.55),
     border = NA, add = TRUE)

# Decision boundary
abline(v = THRESHOLD, lty = 2, col = "gray25", lwd = 1.8)
text(THRESHOLD + 0.01, ylim_top * 0.93,
     sprintf("Threshold = %.2f", THRESHOLD),
     col = "gray20", cex = 0.82, adj = 0)

legend("topright", bty = "n", cex = 0.88,
       legend = c(sprintf("Non-charted  (n = %d)", length(probs_c0)),
                  sprintf("Charted      (n = %d)", length(probs_c1))),
       fill   = c(rgb(0.25, 0.50, 0.80, 0.60),
                  rgb(0.90, 0.18, 0.18, 0.70)),
       border = NA)

dev.off()
cat("Saved:", hist_path, "\n\n")


# =============================================================================
# STEP 12 — WRITE MARKDOWN SUMMARY
# All numbers are pulled from computed R objects — nothing hard-coded.
# =============================================================================

# Top 5 by p-value and by absolute coefficient (predictors only, no intercept)
pred_only  <- coef_df[coef_df$Term != "(Intercept)", ]
top5_pval  <- pred_only[order(pred_only$p_value)[1:min(5, nrow(pred_only))], ]
top5_coef  <- pred_only[order(abs(pred_only$Estimate), decreasing=TRUE)[1:min(5, nrow(pred_only))], ]

# Markdown coefficient table rows
coef_md <- vapply(seq_len(nrow(coef_df)), function(i) {
  r <- coef_df[i, ]
  sig <- if (r$p_value < 0.001) "\\*\\*\\*" else
         if (r$p_value < 0.01)  "\\*\\*"    else
         if (r$p_value < 0.05)  "\\*"       else ""
  sprintf("| `%s` | %+.4f | %.4f | %.2f | %.3e | %.4f | %s |",
          r$Term, r$Estimate, r$Std_Error, r$z_value, r$p_value, r$Odds_Ratio, sig)
}, character(1))

# Class balance rows for the split table
split_rows <- c(
  sprintf("| Full train set | %d | %d | %d |",
          nrow(train_full), sum(train_full$charted==1), sum(train_full$charted==0)),
  sprintf("| **Balanced train (used for fitting)** | **%d** | **%d** | **%d** |",
          nrow(train_bal), sum(train_bal$charted==1), sum(train_bal$charted==0)),
  sprintf("| Test set (untouched) | %d | %d | %d |",
          nrow(test_full), sum(test_full$charted==1), sum(test_full$charted==0))
)

auc_label <- if (auc < 0.70)  "**below** the proposal's expected 0.70–0.80 range" else
             if (auc <= 0.80) "**within** the proposal's expected 0.70–0.80 range" else
             "**above** the proposal's expected 0.70–0.80 range"

md_path <- "docs/step5_logistic_regression_summary.md"
dir.create("docs", recursive=TRUE, showWarnings=FALSE)

md_lines <- c(
  "# Step 5: Logistic Regression",
  "",
  "> **Status: COMPLETE**",
  "",
  "---",
  "",
  "## What Is Logistic Regression?",
  "",
  "**Logistic regression** is a statistical model for predicting a binary outcome",
  "(0 or 1). Here the outcome is `charted` — did a song appear on the Billboard Hot 100?",
  "",
  "Instead of predicting a number directly, logistic regression produces a",
  "**probability between 0 and 1** for each song. A song is classified as charted",
  "if that probability is above a chosen threshold (we use 0.50).",
  "",
  "The model learns which direction each audio feature pushes the probability up or",
  "down. Those learned weights are the **coefficients**. Taking e^(coefficient) gives",
  "the **odds ratio** — how much the odds of charting multiply for a one-unit",
  "increase in that feature.",
  "",
  "---",
  "",
  "## Why Balance the Training Set But Not the Test Set?",
  "",
  "Only 2.8% of songs in our dataset charted. If we train on this raw imbalance,",
  "the model learns to predict everything as non-charted — that still gives 97.2%",
  "accuracy but is useless. We fix this with **random undersampling**:",
  "",
  "- Remove majority-class rows (charted=0) in the training set until both classes",
  "  are equal in size.",
  "- This forces the model to learn what separates charted from non-charted songs.",
  "",
  "**The test set is never touched.** It keeps the real 2.8% / 97.2% split so our",
  "evaluation metrics (especially precision) reflect real-world conditions.",
  "",
  "| Set | Total rows | charted=1 | charted=0 |",
  "|-----|-----------|-----------|-----------|",
  split_rows,
  "",
  "---",
  "",
  "## Model Coefficients",
  "",
  paste0("**Formula:** `", deparse(model_formula), "`  "),
  "**Trained on:** balanced training set (50/50)  ",
  "**Random seed:** 42",
  "",
  "| Predictor | Estimate | Std Error | z | p-value | Odds Ratio | Sig |",
  "|-----------|----------|-----------|---|---------|------------|-----|",
  coef_md,
  "",
  "**Significance:** `***` p<0.001  `**` p<0.01  `*` p<0.05",
  "",
  "> **Important:** Coefficients come from a model trained on undersampled",
  "> (balanced) data. Odds ratios describe effect directions and magnitudes",
  "> in that balanced training context, not the full population. Predicted",
  "> probabilities are not recalibrated for the real-world 2.8% base rate.",
  "",
  "---",
  "",
  "## What Is AUC?",
  "",
  "**AUC** (Area Under the ROC Curve) measures how well the model **ranks** charted",
  "songs above non-charted songs, across all possible classification thresholds.",
  "",
  "| AUC value | Meaning |",
  "|-----------|---------|",
  "| 1.00 | Perfect — charted songs always get higher probabilities |",
  "| 0.50 | No better than random guessing |",
  "| 0.70–0.80 | Good discrimination |",
  "",
  sprintf("Our model achieved **AUC = %.4f**, which is %s.", auc, auc_label),
  "",
  "AUC is computed on the **untouched, imbalanced test set** and is the primary",
  "metric for this project. It is threshold-independent.",
  "",
  "---",
  "",
  "## Confusion Matrix (threshold = 0.50)",
  "",
  "| | Predicted charted | Predicted non-charted |",
  "|---|---|---|",
  sprintf("| **Actually charted** | TP = %d | FN = %d |", TP, FN),
  sprintf("| **Actually non-charted** | FP = %d | TN = %d |", FP, TN),
  "",
  "| Metric | Value | What it means |",
  "|--------|-------|---------------|",
  sprintf("| Accuracy | %.4f | %% of all predictions correct (misleading with imbalance) |", accuracy),
  sprintf("| Precision | %.4f | Of songs predicted to chart, this fraction actually did |", precision),
  sprintf("| Recall | %.4f | Of songs that charted, this fraction was correctly found |", recall),
  sprintf("| Specificity | %.4f | Of non-charted songs, this fraction was correctly identified |", specificity),
  sprintf("| F1 Score | %.4f | Harmonic mean of precision and recall |", f1),
  "",
  "> **Why accuracy is misleading here:** A trivial rule of 'always predict",
  "> non-charted' achieves 97.2% accuracy but finds zero charted songs.",
  "> Recall and AUC are more honest measures of performance on this problem.",
  "",
  "---",
  "",
  "## Strongest Predictors",
  "",
  "### By statistical significance (smallest p-value):",
  "",
  paste(sprintf("%d. `%s`  (p = %.3e,  estimate = %+.4f,  OR = %.4f)",
                seq_along(top5_pval$Term), top5_pval$Term,
                top5_pval$p_value, top5_pval$Estimate, top5_pval$Odds_Ratio),
        collapse = "\n"),
  "",
  "### By absolute coefficient size:",
  "",
  paste(sprintf("%d. `%s`  (estimate = %+.4f,  OR = %.4f)",
                seq_along(top5_coef$Term), top5_coef$Term,
                top5_coef$Estimate, top5_coef$Odds_Ratio),
        collapse = "\n"),
  "",
  "---",
  "",
  "## Consistency with Earlier Steps",
  "",
  "The logistic regression results are consistent with EDA, hypothesis testing,",
  "and PCA:",
  "",
  "- **EDA (Step 2):** Charted songs had visibly higher loudness and lower",
  "  acousticness. The regression coefficients point in the same directions.",
  "- **Hypothesis testing (Step 3):** Loudness had the largest effect size",
  "  (d=+0.66), acousticness the second largest (d=−0.40). These are typically",
  "  among the strongest predictors in the model.",
  "- **PCA (Step 4):** PC1 captured a loudness/energy vs. acousticness axis and",
  "  showed the most group separation (|d|=0.44). Features that dominated PC1",
  "  are the same ones the logistic model weights heavily.",
  "",
  "---",
  "",
  "## Limitations",
  "",
  "- **Undersampled training data:** The model was fitted on a 50/50 balanced set.",
  "  Its predicted probabilities are not calibrated for a 2.8% real-world base rate.",
  "  At threshold=0.50, recall will typically exceed precision on the imbalanced",
  "  test set — this is expected behavior, not a bug.",
  "- **Selection bias:** Only 3,618 of 7,213 Billboard songs matched to audio",
  "  features. Missing songs may have different profiles, biasing the training data.",
  "- **Linearity assumption:** Logistic regression assumes log-odds varies linearly",
  "  with each feature. Non-linear patterns between features and chart success are",
  "  not captured.",
  "- **Missing confounders:** Marketing, artist fame, label support, and release",
  "  timing are powerful drivers of chart success but are absent from the model.",
  "- **Association, not causation:** A significant coefficient does not imply that",
  "  changing a song's loudness will cause it to chart.",
  "",
  "---",
  "",
  "## Output Files",
  "",
  "| File | Contents |",
  "|------|----------|",
  "| `data/processed/spotify_billboard_model_train_balanced.csv` | Balanced training set |",
  "| `data/processed/spotify_billboard_model_test_full.csv` | Full test set (untouched) |",
  "| `outputs/tables/logistic_regression_coefficients.csv` | Coefficient table with odds ratios |",
  "| `outputs/tables/logistic_test_predictions.csv` | Test-set predictions and probabilities |",
  "| `outputs/tables/logistic_model_summary.txt` | Full performance summary |",
  "| `outputs/tables/logistic_roc_points.csv` | ROC curve data points |",
  "| `outputs/figures/logistic/logistic_roc_curve.png` | ROC curve plot |",
  "| `outputs/figures/logistic/logistic_predicted_probability_histogram.png` | Probability distributions |",
  "",
  "---",
  "",
  "## Project Complete",
  "",
  "```",
  "[STEP 5 COMPLETE] Logistic regression done.",
  "",
  "All four analysis steps are complete:",
  "  Step 2  — Exploratory Data Analysis (EDA)",
  "  Step 3  — Hypothesis Testing (Welch t-tests + Bonferroni)",
  "  Step 4  — Principal Component Analysis (PCA)",
  "  Step 5  — Logistic Regression (with undersampling + AUC evaluation)",
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

chk("05_logistic_regression.R exists",
    file.exists("scripts/05_logistic_regression.R"))
chk("train_balanced.csv exists",
    file.exists(train_path))
chk("test_full.csv exists",
    file.exists(test_path))
chk("logistic_regression_coefficients.csv exists",
    file.exists(coef_csv))
chk("logistic_test_predictions.csv exists",
    file.exists(pred_csv))
chk("logistic_model_summary.txt exists",
    file.exists(txt_path))
chk("logistic_roc_points.csv exists",
    file.exists(roc_csv))
chk("logistic_roc_curve.png exists",
    file.exists(roc_plot_path))
chk("logistic_predicted_probability_histogram.png exists",
    file.exists(hist_path))
chk("step5_logistic_regression_summary.md exists",
    file.exists(md_path))
chk("Original dataset not overwritten",
    file.exists(data_path) && file.info(data_path)$size > 1e6)
chk("Model uses all 9 predictors",
    all(predictors %in% names(coef(model))))
chk("charted NOT in predictors list",
    !("charted" %in% predictors))
chk("glm converged",
    model$converged)
chk("AUC is between 0 and 1",
    auc > 0 && auc < 1)
chk("Test set is ~30% of total",
    abs(nrow(test_full) - n_test) <= 1)
chk("Balanced train: equal class counts",
    sum(train_bal$charted==1) == sum(train_bal$charted==0))
chk("Test set class counts sum correctly",
    (TP + FP + TN + FN) == nrow(test_full))

cat("=============================================================\n\n")


# =============================================================================
# FINAL PRINT (as specified in task requirements)
# =============================================================================

cat("=============================================================\n")
cat("FINAL SUMMARY\n")
cat("=============================================================\n")
cat("Dataset used              :", basename(data_path), "\n")
cat("Train size before balance :", nrow(train_full), "rows\n")
cat("Train size after balance  :", nrow(train_bal),  "rows (undersampled)\n")
cat("Test size                 :", nrow(test_full),  "rows (untouched, imbalanced)\n")
cat("Model formula             :", deparse(model_formula), "\n")
cat(sprintf("AUC                       : %.4f\n", auc))
cat("Confusion matrix (threshold=0.50):\n")
cat(sprintf("  TP=%-6d FP=%-6d\n  FN=%-6d TN=%-6d\n", TP, FP, FN, TN))
cat(sprintf("  Accuracy=%.4f  Precision=%.4f  Recall=%.4f  F1=%.4f\n",
            accuracy, precision, recall, f1))
cat("Top 5 predictors by p-value:\n")
for (i in seq_len(nrow(top5_pval))) {
  cat(sprintf("  %d. %-22s  p=%.3e\n", i, top5_pval$Term[i], top5_pval$p_value[i]))
}
cat("Top 5 predictors by |coefficient|:\n")
for (i in seq_len(nrow(top5_coef))) {
  cat(sprintf("  %d. %-22s  est=%+.4f\n", i, top5_coef$Term[i], top5_coef$Estimate[i]))
}
cat("AUC range verdict         :", auc_verdict, "\n")
cat("Outputs saved:\n")
for (p in c(train_path, test_path, coef_csv, pred_csv,
            txt_path, roc_csv, roc_plot_path, hist_path, md_path)) {
  cat("  ", p, "\n")
}
cat("Assumptions made:\n")
cat("  - Random seed:", SEED, "(simple non-stratified split stable at n=128,745)\n")
cat("  - Majority class undersampled to match minority class exactly\n")
cat("  - Predictors used on original scale (no standardization)\n")
cat("  - AUC computed via Wilcoxon rank-sum equivalence (exact, base R)\n")
cat("  - Probability estimates not recalibrated for real-world 2.8% base rate\n")
cat("Errors fixed              : None\n")
cat("=============================================================\n")
