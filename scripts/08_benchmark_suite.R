# =============================================================================
# 08_benchmark_suite.R
# Phase 3: Benchmark suite beyond logistic regression
#
# Purpose:
#   - Build a cleaned enriched analysis dataset from the enriched merged file
#   - Create a fresh 70/30 train-test split
#   - Balance the training set only by random undersampling
#   - Benchmark multiple model families on the SAME untouched test set
#
# Notes:
#   - Uses base R where practical
#   - Never overwrites older master datasets
#   - Skips optional models honestly if packages are unavailable
# =============================================================================

setwd("D:/SpotifyBillboardProject")

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
src_path <- "data/processed/spotify_billboard_merged_enriched_full.csv"
clean_path <- "data/processed/spotify_billboard_analysis_enriched_clean.csv"
train_path <- "data/processed/enriched_model_train_balanced.csv"
test_path <- "data/processed/enriched_model_test_full.csv"

clean_log_path <- "outputs/tables/enriched_cleaning_summary.txt"
comparison_csv <- "outputs/tables/benchmark_model_comparison.csv"
notes_txt <- "outputs/tables/benchmark_model_notes.txt"
pred_sample_csv <- "outputs/tables/benchmark_test_predictions_sample.csv"
roc_csv <- "outputs/tables/benchmark_roc_curves.csv"
pr_csv <- "outputs/tables/benchmark_pr_curves.csv"

fig_dir <- "outputs/figures/benchmark"
roc_png <- file.path(fig_dir, "benchmark_roc_curves.png")
pr_png <- file.path(fig_dir, "benchmark_pr_curves.png")
auc_png <- file.path(fig_dir, "benchmark_auc_barplot.png")
prauc_png <- file.path(fig_dir, "benchmark_prauc_barplot.png")

summary_md <- "docs/step8_benchmark_summary.md"
old_summary_txt <- "outputs/tables/logistic_model_summary.txt"

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("docs", recursive = TRUE, showWarnings = FALSE)

if (!file.exists(src_path)) {
  stop("Source file not found: ", src_path)
}

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
safe_div <- function(num, den) {
  if (is.na(den) || den == 0) return(NA_real_)
  num / den
}

calc_auc <- function(labels, scores) {
  labels <- as.integer(labels)
  ok <- !(is.na(labels) | is.na(scores))
  labels <- labels[ok]
  scores <- scores[ok]
  n_pos <- sum(labels == 1L)
  n_neg <- sum(labels == 0L)
  if (n_pos == 0L || n_neg == 0L) return(NA_real_)
  rank_sum_pos <- sum(rank(scores)[labels == 1L])
  (rank_sum_pos - n_pos * (n_pos + 1L) / 2) / (n_pos * n_neg)
}

calc_pr_auc <- function(labels, scores) {
  labels <- as.integer(labels)
  ok <- !(is.na(labels) | is.na(scores))
  labels <- labels[ok]
  scores <- scores[ok]
  n_pos <- sum(labels == 1L)
  if (n_pos == 0L) return(NA_real_)

  ord <- order(scores, decreasing = TRUE)
  lab_sorted <- labels[ord]

  tp <- cumsum(lab_sorted == 1L)
  fp <- cumsum(lab_sorted == 0L)

  recall <- tp / n_pos
  precision <- tp / (tp + fp)

  recall <- c(0, recall)
  precision <- c(1, precision)

  sum((recall[-1] - recall[-length(recall)]) * precision[-1])
}

make_roc_curve <- function(labels, scores, model_name) {
  labels <- as.integer(labels)
  ord <- order(scores, decreasing = TRUE)
  lab_sorted <- labels[ord]
  n_pos <- sum(labels == 1L)
  n_neg <- sum(labels == 0L)

  tp_cs <- c(0L, cumsum(lab_sorted == 1L))
  fp_cs <- c(0L, cumsum(lab_sorted == 0L))

  data.frame(
    model = model_name,
    fpr = fp_cs / n_neg,
    tpr = tp_cs / n_pos,
    threshold = c(Inf, scores[ord]),
    stringsAsFactors = FALSE
  )
}

make_pr_curve <- function(labels, scores, model_name) {
  labels <- as.integer(labels)
  ord <- order(scores, decreasing = TRUE)
  lab_sorted <- labels[ord]
  n_pos <- sum(labels == 1L)

  tp <- cumsum(lab_sorted == 1L)
  fp <- cumsum(lab_sorted == 0L)

  recall <- tp / n_pos
  precision <- tp / (tp + fp)

  data.frame(
    model = model_name,
    recall = c(0, recall),
    precision = c(1, precision),
    threshold = c(Inf, scores[ord]),
    stringsAsFactors = FALSE
  )
}

evaluate_model <- function(model_name, truth, prob = NULL, pred_class = NULL, threshold = 0.50) {
  truth <- as.integer(truth)

  if (!is.null(prob)) {
    pred_class <- as.integer(prob >= threshold)
  } else if (is.null(pred_class)) {
    stop("Need either probabilities or predicted classes.")
  }

  TP <- sum(pred_class == 1L & truth == 1L)
  FP <- sum(pred_class == 1L & truth == 0L)
  TN <- sum(pred_class == 0L & truth == 0L)
  FN <- sum(pred_class == 0L & truth == 1L)

  accuracy <- safe_div(TP + TN, length(truth))
  precision <- safe_div(TP, TP + FP)
  recall <- safe_div(TP, TP + FN)
  specificity <- safe_div(TN, TN + FP)
  f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA_real_ else
    2 * precision * recall / (precision + recall)

  roc_auc <- if (!is.null(prob)) calc_auc(truth, prob) else NA_real_
  pr_auc <- if (!is.null(prob)) calc_pr_auc(truth, prob) else NA_real_
  brier <- if (!is.null(prob)) mean((prob - truth)^2) else NA_real_

  list(
    summary = data.frame(
      model = model_name,
      threshold = threshold,
      roc_auc = roc_auc,
      pr_auc = pr_auc,
      accuracy = accuracy,
      precision = precision,
      recall = recall,
      specificity = specificity,
      f1 = f1,
      brier = brier,
      tp = TP,
      fp = FP,
      tn = TN,
      fn = FN,
      probability_available = !is.null(prob),
      stringsAsFactors = FALSE
    ),
    prob = prob,
    pred_class = pred_class
  )
}

scale_from_train <- function(train_mat, new_mat) {
  mu <- colMeans(train_mat)
  sdv <- apply(train_mat, 2, sd)
  sdv[sdv == 0] <- 1
  list(
    train = scale(train_mat, center = mu, scale = sdv),
    new = scale(new_mat, center = mu, scale = sdv),
    mean = mu,
    sd = sdv
  )
}

top_metric_text <- function(df, metric) {
  ok <- !is.na(df[[metric]])
  if (!any(ok)) return("Not available")
  best <- df[ok, ][order(df[ok, metric], decreasing = TRUE), ][1, ]
  sprintf("%s (%.4f)", best$model, best[[metric]])
}

parse_old_auc <- function(path) {
  if (!file.exists(path)) return(NA_real_)
  x <- readLines(path, warn = FALSE)
  hit <- grep("^\\s*AUC\\s*:", x, value = TRUE)
  if (length(hit) == 0) return(NA_real_)
  as.numeric(sub(".*:\\s*", "", hit[1]))
}

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

# -----------------------------------------------------------------------------
# SECTION 1: Read and lightly clean enriched dataset
# -----------------------------------------------------------------------------
cat("Reading enriched source dataset...\n")
df <- read.csv(src_path, stringsAsFactors = FALSE)
orig_rows <- nrow(df)
orig_cols <- ncol(df)

expected_cols <- c(
  "charted", "song_name", "artist", "danceability", "energy", "valence",
  "tempo", "loudness", "acousticness", "speechiness", "instrumentalness",
  "liveness", "album", "duration_ms", "explicit", "mode", "popularity",
  "time_signature"
)

missing_cols <- setdiff(expected_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing expected columns: ", paste(missing_cols, collapse = ", "))
}

# Preserve the original 18-column structure and current snake_case names.
df <- df[, expected_cols]

# Convert explicit to 0/1 integer if needed.
explicit_before <- sort(unique(df$explicit))
df$explicit <- as.integer(toupper(trimws(as.character(df$explicit))) == "TRUE")

# Confirm binary columns are integer 0/1.
binary_cols <- c("charted", "explicit", "mode")
for (col in binary_cols) {
  vals <- sort(unique(df[[col]]))
  if (is.numeric(df[[col]]) && all(vals %in% c(0, 1))) {
    df[[col]] <- as.integer(df[[col]])
  }
}

audio_features <- c(
  "danceability", "energy", "valence", "tempo", "loudness",
  "acousticness", "speechiness", "instrumentalness", "liveness"
)

for (feat in audio_features) {
  df[[feat]] <- as.numeric(df[[feat]])
}

df$duration_ms <- as.numeric(df$duration_ms)
df$popularity <- as.integer(df$popularity)
df$time_signature <- as.integer(df$time_signature)

na_counts <- colSums(is.na(df))
total_na <- sum(na_counts)
dup_count <- sum(duplicated(df))

range_rules <- list(
  danceability = c(0, 1),
  energy = c(0, 1),
  valence = c(0, 1),
  acousticness = c(0, 1),
  speechiness = c(0, 1),
  instrumentalness = c(0, 1),
  liveness = c(0, 1),
  tempo = c(0, Inf),
  loudness = c(-Inf, 5)
)

flag_list <- list()
for (feat in names(range_rules)) {
  lo <- range_rules[[feat]][1]
  hi <- range_rules[[feat]][2]
  x <- df[[feat]]
  bad_lo <- if (is.finite(lo)) which(x < lo) else integer(0)
  bad_hi <- if (is.finite(hi)) which(x > hi) else integer(0)
  bad <- union(bad_lo, bad_hi)
  if (length(bad) > 0) {
    flag_list[[feat]] <- data.frame(
      row_index = bad,
      feature = feat,
      value = x[bad],
      stringsAsFactors = FALSE
    )
  }
}
flagged_total <- if (length(flag_list) == 0) 0L else sum(vapply(flag_list, nrow, integer(1)))

write.csv(df, clean_path, row.names = FALSE)

clean_lines <- c(
  "ENRICHED CLEANING SUMMARY",
  paste0("Generated: ", Sys.time()),
  "",
  "SOURCE FILE",
  paste0("  Path    : ", src_path),
  paste0("  Rows    : ", orig_rows),
  paste0("  Cols    : ", orig_cols),
  "",
  "OUTPUT FILE",
  paste0("  Path    : ", clean_path),
  paste0("  Rows    : ", nrow(df)),
  paste0("  Cols    : ", ncol(df)),
  "",
  "CLEANING ACTIONS",
  paste0("  explicit unique values before: ", paste(explicit_before, collapse = ", ")),
  paste0("  explicit converted to integer 0/1: yes"),
  paste0("  charted integer 0/1 confirmed   : ", all(sort(unique(df$charted)) %in% c(0L, 1L))),
  paste0("  mode integer 0/1 confirmed      : ", all(sort(unique(df$mode)) %in% c(0L, 1L))),
  "",
  "CHECKS",
  paste0("  Missing values total : ", total_na),
  paste0("  Duplicate rows       : ", dup_count),
  paste0("  Flagged range values : ", flagged_total),
  "",
  "CLASS BALANCE (UNCHANGED)",
  paste0("  charted=1 : ", sum(df$charted == 1L)),
  paste0("  charted=0 : ", sum(df$charted == 0L)),
  paste0("  ratio 0:1 : ", round(sum(df$charted == 0L) / sum(df$charted == 1L), 1), ":1"),
  "",
  "NOTE",
  "  No rows were removed and no class balancing was applied in this cleaning step."
)
writeLines(clean_lines, clean_log_path)

# -----------------------------------------------------------------------------
# SECTION 2: Train/test split and balanced training set
# -----------------------------------------------------------------------------
SEED <- 42
set.seed(SEED)

n_total <- nrow(df)
n_train <- round(n_total * 0.70)

train_idx <- sample(seq_len(n_total), size = n_train, replace = FALSE)
test_idx <- setdiff(seq_len(n_total), train_idx)

train_full <- df[train_idx, ]
test_full <- df[test_idx, ]

train_c1 <- train_full[train_full$charted == 1L, ]
train_c0 <- train_full[train_full$charted == 0L, ]
n_minority <- nrow(train_c1)

us_idx <- sample(seq_len(nrow(train_c0)), size = n_minority, replace = FALSE)
train_c0us <- train_c0[us_idx, ]

train_bal <- rbind(train_c1, train_c0us)
train_bal <- train_bal[sample(seq_len(nrow(train_bal))), ]
rownames(train_bal) <- NULL

write.csv(train_bal, train_path, row.names = FALSE)
write.csv(test_full, test_path, row.names = FALSE)

predictors <- audio_features
threshold <- 0.50

train_x <- train_bal[, predictors]
test_x <- test_full[, predictors]
test_y <- as.integer(test_full$charted)

# -----------------------------------------------------------------------------
# SECTION 3: Package availability
# -----------------------------------------------------------------------------
pkg_status <- c(
  MASS = requireNamespace("MASS", quietly = TRUE),
  class = requireNamespace("class", quietly = TRUE),
  rpart = requireNamespace("rpart", quietly = TRUE),
  randomForest = requireNamespace("randomForest", quietly = TRUE),
  ranger = requireNamespace("ranger", quietly = TRUE),
  xgboost = requireNamespace("xgboost", quietly = TRUE)
)

model_results <- list()
roc_list <- list()
pr_list <- list()
model_notes <- character(0)
skipped_models <- character(0)

# -----------------------------------------------------------------------------
# SECTION 4: Logistic regression
# -----------------------------------------------------------------------------
cat("Running logistic regression...\n")
glm_formula <- as.formula(
  paste("charted ~", paste(predictors, collapse = " + "))
)
glm_fit <- glm(glm_formula, data = train_bal, family = binomial)
glm_prob <- as.numeric(predict(glm_fit, newdata = test_full, type = "response"))
glm_eval <- evaluate_model("Logistic Regression (Enriched)", test_y, prob = glm_prob, threshold = threshold)
model_results[["Logistic Regression (Enriched)"]] <- glm_eval
roc_list[["Logistic Regression (Enriched)"]] <- make_roc_curve(test_y, glm_prob, "Logistic Regression (Enriched)")
pr_list[["Logistic Regression (Enriched)"]] <- make_pr_curve(test_y, glm_prob, "Logistic Regression (Enriched)")
model_notes <- c(model_notes, "Logistic Regression (Enriched): glm binomial on balanced training set.")

# -----------------------------------------------------------------------------
# SECTION 5: LDA
# -----------------------------------------------------------------------------
if (pkg_status["MASS"]) {
  cat("Running LDA...\n")
  lda_fit <- MASS::lda(glm_formula, data = train_bal)
  lda_pred <- predict(lda_fit, newdata = test_full)
  lda_prob <- as.numeric(lda_pred$posterior[, "1"])
  lda_eval <- evaluate_model("LDA", test_y, prob = lda_prob, threshold = threshold)
  model_results[["LDA"]] <- lda_eval
  roc_list[["LDA"]] <- make_roc_curve(test_y, lda_prob, "LDA")
  pr_list[["LDA"]] <- make_pr_curve(test_y, lda_prob, "LDA")
  model_notes <- c(model_notes, "LDA: MASS::lda on balanced training set.")
} else {
  skipped_models <- c(skipped_models, "LDA skipped: MASS not available.")
}

# -----------------------------------------------------------------------------
# SECTION 6: kNN with small internal validation grid
# -----------------------------------------------------------------------------
if (pkg_status["class"]) {
  cat("Running kNN...\n")
  set.seed(SEED + 1L)
  valid_size <- max(1L, round(nrow(train_bal) * 0.20))
  valid_idx <- sample(seq_len(nrow(train_bal)), size = valid_size, replace = FALSE)
  inner_valid <- train_bal[valid_idx, ]
  inner_train <- train_bal[-valid_idx, ]

  inner_scaled <- scale_from_train(as.matrix(inner_train[, predictors]), as.matrix(inner_valid[, predictors]))
  inner_train_y <- factor(inner_train$charted, levels = c(0, 1))
  inner_valid_y <- as.integer(inner_valid$charted)

  k_grid <- c(5, 11, 21, 31)
  k_grid <- k_grid[k_grid < nrow(inner_train)]
  if (length(k_grid) == 0) k_grid <- 5

  knn_tune <- data.frame(k = integer(0), auc = numeric(0), stringsAsFactors = FALSE)
  for (k in k_grid) {
    pred_k <- class::knn(
      train = inner_scaled$train,
      test = inner_scaled$new,
      cl = inner_train_y,
      k = k,
      prob = TRUE
    )
    vote_prob <- attr(pred_k, "prob")
    prob_pos <- ifelse(pred_k == "1", vote_prob, 1 - vote_prob)
    knn_tune <- rbind(
      knn_tune,
      data.frame(k = k, auc = calc_auc(inner_valid_y, prob_pos), stringsAsFactors = FALSE)
    )
  }

  best_k <- knn_tune$k[order(knn_tune$auc, -knn_tune$k, decreasing = TRUE)][1]
  best_auc <- knn_tune$auc[match(best_k, knn_tune$k)]

  full_scaled <- scale_from_train(as.matrix(train_x), as.matrix(test_x))
  train_y_factor <- factor(train_bal$charted, levels = c(0, 1))

  knn_pred <- class::knn(
    train = full_scaled$train,
    test = full_scaled$new,
    cl = train_y_factor,
    k = best_k,
    prob = TRUE
  )
  knn_vote_prob <- attr(knn_pred, "prob")
  knn_prob <- ifelse(knn_pred == "1", knn_vote_prob, 1 - knn_vote_prob)

  knn_eval <- evaluate_model("kNN", test_y, prob = as.numeric(knn_prob), threshold = threshold)
  model_results[["kNN"]] <- knn_eval
  roc_list[["kNN"]] <- make_roc_curve(test_y, knn_prob, "kNN")
  pr_list[["kNN"]] <- make_pr_curve(test_y, knn_prob, "kNN")
  model_notes <- c(
    model_notes,
    sprintf("kNN: standardized on training-set statistics only; k grid=%s; chosen k=%d by validation AUC=%.4f.",
            paste(k_grid, collapse = ","), best_k, best_auc)
  )
} else {
  skipped_models <- c(skipped_models, "kNN skipped: class package not available.")
}

# -----------------------------------------------------------------------------
# SECTION 7: Decision tree
# -----------------------------------------------------------------------------
if (pkg_status["rpart"]) {
  cat("Running decision tree...\n")
  tree_fit <- rpart::rpart(
    glm_formula,
    data = train_bal,
    method = "class",
    control = rpart::rpart.control(cp = 0.01, minsplit = 20, maxdepth = 10)
  )
  tree_prob <- as.numeric(predict(tree_fit, newdata = test_full, type = "prob")[, "1"])
  tree_eval <- evaluate_model("Decision Tree", test_y, prob = tree_prob, threshold = threshold)
  model_results[["Decision Tree"]] <- tree_eval
  roc_list[["Decision Tree"]] <- make_roc_curve(test_y, tree_prob, "Decision Tree")
  pr_list[["Decision Tree"]] <- make_pr_curve(test_y, tree_prob, "Decision Tree")
  model_notes <- c(model_notes, "Decision Tree: rpart classification tree with cp=0.01, minsplit=20, maxdepth=10.")
} else {
  skipped_models <- c(skipped_models, "Decision Tree skipped: rpart not available.")
}

# -----------------------------------------------------------------------------
# SECTION 8: Random forest (prefer randomForest, else ranger)
# -----------------------------------------------------------------------------
if (pkg_status["randomForest"]) {
  cat("Running random forest...\n")
  rf_fit <- randomForest::randomForest(
    x = train_x,
    y = factor(train_bal$charted, levels = c(0, 1)),
    ntree = 500,
    mtry = max(1L, floor(sqrt(length(predictors))))
  )
  rf_prob <- as.numeric(predict(rf_fit, newdata = test_x, type = "prob")[, "1"])
  rf_eval <- evaluate_model("Random Forest", test_y, prob = rf_prob, threshold = threshold)
  model_results[["Random Forest"]] <- rf_eval
  roc_list[["Random Forest"]] <- make_roc_curve(test_y, rf_prob, "Random Forest")
  pr_list[["Random Forest"]] <- make_pr_curve(test_y, rf_prob, "Random Forest")
  model_notes <- c(model_notes, "Random Forest: randomForest package with ntree=500 and sqrt(p) mtry.")
} else if (pkg_status["ranger"]) {
  cat("Running random forest via ranger...\n")
  ranger_fit <- ranger::ranger(
    glm_formula,
    data = train_bal,
    probability = TRUE,
    num.trees = 500,
    mtry = max(1L, floor(sqrt(length(predictors)))),
    seed = SEED
  )
  ranger_prob <- as.numeric(predict(ranger_fit, data = test_full)$predictions[, "1"])
  ranger_eval <- evaluate_model("Random Forest", test_y, prob = ranger_prob, threshold = threshold)
  model_results[["Random Forest"]] <- ranger_eval
  roc_list[["Random Forest"]] <- make_roc_curve(test_y, ranger_prob, "Random Forest")
  pr_list[["Random Forest"]] <- make_pr_curve(test_y, ranger_prob, "Random Forest")
  model_notes <- c(model_notes, "Random Forest: ranger probability forest with 500 trees.")
} else {
  skipped_models <- c(skipped_models, "Random Forest skipped: neither randomForest nor ranger was available.")
}

# -----------------------------------------------------------------------------
# SECTION 9: XGBoost (optional)
# -----------------------------------------------------------------------------
if (pkg_status["xgboost"]) {
  cat("Running XGBoost...\n")
  dtrain <- xgboost::xgb.DMatrix(data = as.matrix(train_x), label = train_bal$charted)
  dtest <- xgboost::xgb.DMatrix(data = as.matrix(test_x), label = test_y)

  xgb_fit <- xgboost::xgb.train(
    params = list(
      objective = "binary:logistic",
      eval_metric = "auc",
      eta = 0.05,
      max_depth = 4,
      subsample = 0.8,
      colsample_bytree = 0.8
    ),
    data = dtrain,
    nrounds = 200,
    verbose = 0
  )
  xgb_prob <- as.numeric(predict(xgb_fit, newdata = dtest))
  xgb_eval <- evaluate_model("XGBoost", test_y, prob = xgb_prob, threshold = threshold)
  model_results[["XGBoost"]] <- xgb_eval
  roc_list[["XGBoost"]] <- make_roc_curve(test_y, xgb_prob, "XGBoost")
  pr_list[["XGBoost"]] <- make_pr_curve(test_y, xgb_prob, "XGBoost")
  model_notes <- c(model_notes, "XGBoost: modest untuned binary logistic booster (nrounds=200, max_depth=4, eta=0.05).")
} else {
  skipped_models <- c(skipped_models, "XGBoost skipped: xgboost not available.")
}

# -----------------------------------------------------------------------------
# SECTION 10: Collect outputs
# -----------------------------------------------------------------------------
summary_df <- do.call(rbind, lapply(model_results, function(x) x$summary))
summary_df <- summary_df[order(summary_df$roc_auc, decreasing = TRUE), ]
rownames(summary_df) <- NULL
write.csv(summary_df, comparison_csv, row.names = FALSE)

roc_df <- do.call(rbind, roc_list)
pr_df <- do.call(rbind, pr_list)
rownames(roc_df) <- NULL
rownames(pr_df) <- NULL
write.csv(roc_df, roc_csv, row.names = FALSE)
write.csv(pr_df, pr_csv, row.names = FALSE)

pred_out <- test_full[, c("song_name", "artist", "charted")]
names(pred_out)[3] <- "true_charted"
for (nm in names(model_results)) {
  safe_nm <- gsub("[^A-Za-z0-9]+", "_", tolower(nm))
  pred_out[[paste0("prob_", safe_nm)]] <- round(model_results[[nm]]$prob, 6)
  pred_out[[paste0("pred_", safe_nm)]] <- model_results[[nm]]$pred_class
}
set.seed(SEED + 2L)
sample_n <- min(250L, nrow(pred_out))
sample_idx <- sort(sample(seq_len(nrow(pred_out)), size = sample_n, replace = FALSE))
write.csv(pred_out[sample_idx, ], pred_sample_csv, row.names = FALSE)

old_logistic_auc <- parse_old_auc(old_summary_txt)
new_logistic_auc <- summary_df$roc_auc[match("Logistic Regression (Enriched)", summary_df$model)]
best_row <- summary_df[1, ]

notes_lines <- c(
  "BENCHMARK MODEL NOTES",
  paste0("Generated: ", Sys.time()),
  "",
  "FILES USED",
  paste0("  Source enriched dataset : ", src_path),
  paste0("  Old baseline summary    : ", old_summary_txt),
  paste0("  Clean enriched output   : ", clean_path),
  paste0("  Balanced train output   : ", train_path),
  paste0("  Full test output        : ", test_path),
  "",
  "PACKAGE AVAILABILITY",
  paste0("  MASS         : ", pkg_status["MASS"]),
  paste0("  class        : ", pkg_status["class"]),
  paste0("  rpart        : ", pkg_status["rpart"]),
  paste0("  randomForest : ", pkg_status["randomForest"]),
  paste0("  ranger       : ", pkg_status["ranger"]),
  paste0("  xgboost      : ", pkg_status["xgboost"]),
  "",
  "DATASET AND SPLIT",
  paste0("  Seed                 : ", SEED),
  paste0("  Clean enriched rows  : ", nrow(df)),
  paste0("  Full train rows      : ", nrow(train_full)),
  paste0("  Balanced train rows  : ", nrow(train_bal)),
  paste0("  Test rows            : ", nrow(test_full)),
  paste0("  Train full charted=1 : ", sum(train_full$charted == 1L)),
  paste0("  Train full charted=0 : ", sum(train_full$charted == 0L)),
  paste0("  Train bal charted=1  : ", sum(train_bal$charted == 1L)),
  paste0("  Train bal charted=0  : ", sum(train_bal$charted == 0L)),
  paste0("  Test charted=1       : ", sum(test_full$charted == 1L)),
  paste0("  Test charted=0       : ", sum(test_full$charted == 0L)),
  "",
  "MODELS RUN",
  paste0("  ", paste(summary_df$model, collapse = ", ")),
  "",
  "MODEL-SPECIFIC NOTES",
  paste0("  - ", model_notes),
  "",
  "SKIPPED MODELS",
  if (length(skipped_models) == 0) "  None" else paste0("  - ", skipped_models),
  "",
  "HEADLINE COMPARISON",
  paste0("  Old logistic baseline AUC        : ", fmt4(old_logistic_auc)),
  paste0("  New enriched logistic AUC        : ", fmt4(new_logistic_auc)),
  paste0("  Best ROC-AUC model               : ", top_metric_text(summary_df, "roc_auc")),
  paste0("  Best PR-AUC model                : ", top_metric_text(summary_df, "pr_auc")),
  "",
  "CALIBRATION CAUTION",
  "  Brier scores are reported, but no recalibration step was applied.",
  "  Because training was balanced and the test set kept the real class imbalance,",
  "  raw 0.50-threshold probabilities should not be treated as perfectly calibrated."
)
writeLines(notes_lines, notes_txt)

# -----------------------------------------------------------------------------
# SECTION 11: Plots
# -----------------------------------------------------------------------------
plot_colors <- c(
  "#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02"
)
names(plot_colors) <- summary_df$model

png(roc_png, width = 1100, height = 850, res = 120)
plot(c(0, 1), c(0, 1), type = "n",
     xlab = "False Positive Rate",
     ylab = "True Positive Rate",
     main = "Benchmark ROC Curves on Shared Test Set")
abline(0, 1, lty = 2, col = "gray65")
for (i in seq_len(nrow(summary_df))) {
  m <- summary_df$model[i]
  d <- roc_df[roc_df$model == m, ]
  lines(d$fpr, d$tpr, lwd = 2.4, col = plot_colors[m])
}
legend("bottomright", legend = paste0(summary_df$model, " (AUC=", fmt4(summary_df$roc_auc), ")"),
       col = plot_colors[summary_df$model], lwd = 2.4, bty = "n", cex = 0.9)
dev.off()

png(pr_png, width = 1100, height = 850, res = 120)
plot(c(0, 1), c(0, 1), type = "n",
     xlab = "Recall",
     ylab = "Precision",
     main = "Benchmark Precision-Recall Curves on Shared Test Set",
     ylim = c(0, 1))
for (i in seq_len(nrow(summary_df))) {
  m <- summary_df$model[i]
  d <- pr_df[pr_df$model == m, ]
  lines(d$recall, d$precision, lwd = 2.4, col = plot_colors[m])
}
legend("topright", legend = paste0(summary_df$model, " (PR-AUC=", fmt4(summary_df$pr_auc), ")"),
       col = plot_colors[summary_df$model], lwd = 2.4, bty = "n", cex = 0.9)
dev.off()

auc_ord <- order(summary_df$roc_auc, decreasing = TRUE)
png(auc_png, width = 1000, height = 760, res = 120)
bp <- barplot(summary_df$roc_auc[auc_ord],
              names.arg = summary_df$model[auc_ord],
              las = 2,
              col = plot_colors[summary_df$model[auc_ord]],
              ylim = c(0, max(summary_df$roc_auc, na.rm = TRUE) * 1.15),
              ylab = "ROC-AUC",
              main = "Benchmark ROC-AUC Comparison")
text(bp, summary_df$roc_auc[auc_ord], labels = fmt4(summary_df$roc_auc[auc_ord]), pos = 3, cex = 0.9)
dev.off()

prauc_ord <- order(summary_df$pr_auc, decreasing = TRUE)
png(prauc_png, width = 1000, height = 760, res = 120)
bp2 <- barplot(summary_df$pr_auc[prauc_ord],
               names.arg = summary_df$model[prauc_ord],
               las = 2,
               col = plot_colors[summary_df$model[prauc_ord]],
               ylim = c(0, max(summary_df$pr_auc, na.rm = TRUE) * 1.15),
               ylab = "PR-AUC",
               main = "Benchmark PR-AUC Comparison")
text(bp2, summary_df$pr_auc[prauc_ord], labels = fmt4(summary_df$pr_auc[prauc_ord]), pos = 3, cex = 0.9)
dev.off()

# -----------------------------------------------------------------------------
# SECTION 12: Markdown summary
# -----------------------------------------------------------------------------
best_model_name <- best_row$model
best_model_auc <- best_row$roc_auc
best_model_prauc <- best_row$pr_auc

old_vs_new_text <- if (is.na(old_logistic_auc) || is.na(new_logistic_auc)) {
  "The old-vs-new logistic AUC comparison could not be fully parsed from the prior summary file."
} else if (new_logistic_auc > old_logistic_auc) {
  sprintf("The enriched-data logistic model improved over the old baseline (%.4f to %.4f).",
          old_logistic_auc, new_logistic_auc)
} else if (new_logistic_auc < old_logistic_auc) {
  sprintf("The enriched-data logistic model did not improve over the old baseline (%.4f to %.4f).",
          old_logistic_auc, new_logistic_auc)
} else {
  sprintf("The enriched-data logistic model matched the old baseline exactly at %.4f.", new_logistic_auc)
}

best_vs_logit_text <- if (is.na(best_model_auc) || is.na(new_logistic_auc)) {
  "The best-model vs enriched-logistic AUC gap could not be summarized cleanly."
} else {
  gap <- best_model_auc - new_logistic_auc
  if (best_model_name == "Logistic Regression (Enriched)") {
    "No benchmark model beat the enriched logistic baseline on ROC-AUC."
  } else if (gap >= 0.03) {
    sprintf("%s materially beat enriched logistic on ROC-AUC (%.4f vs %.4f).",
            best_model_name, best_model_auc, new_logistic_auc)
  } else if (gap > 0) {
    sprintf("%s beat enriched logistic, but only modestly, on ROC-AUC (%.4f vs %.4f).",
            best_model_name, best_model_auc, new_logistic_auc)
  } else {
    sprintf("%s did not beat enriched logistic on ROC-AUC after all.", best_model_name)
  }
}

md_lines <- c(
  "# Step 8: Benchmark Suite Beyond Logistic Regression",
  "",
  "> **Status: COMPLETE**",
  "",
  "## Why use the enriched dataset here?",
  "",
  "Phase 3 uses the enriched merged dataset because Step 6 recovered more confirmed charted songs.",
  "That gives the modeling stage more positive examples than the older baseline file.",
  "The older logistic model is still the reference point, but it is **not** reused for new training in this step.",
  "",
  "## What changed versus the old baseline?",
  "",
  sprintf("- Old baseline logistic dataset: `D:/SpotifyBillboardProject/data/processed/spotify_billboard_analysis_clean.csv`"),
  sprintf("- New Phase 3 source dataset: `D:/SpotifyBillboardProject/data/processed/spotify_billboard_merged_enriched_full.csv`"),
  sprintf("- Old baseline AUC: **%.4f**", old_logistic_auc),
  sprintf("- Enriched dataset charted songs: **%d** instead of **3618**", sum(df$charted == 1L)),
  "",
  "## Why balance only the training set?",
  "",
  "The training set is balanced by random undersampling so the models are forced to learn both classes.",
  "The test set stays untouched and imbalanced because that is the honest real-world evaluation setting.",
  "If we balanced the test set too, the reported metrics would look better than real deployment conditions.",
  "",
  "## What do ROC-AUC and PR-AUC mean?",
  "",
  "- **ROC-AUC** measures how well a model ranks charted songs above non-charted songs across all thresholds.",
  "- **PR-AUC** focuses more directly on positive-class retrieval, which matters here because charted songs are rare.",
  "",
  "## Data and Split",
  "",
  sprintf("- Random seed: **%d**", SEED),
  sprintf("- Clean enriched dataset rows: **%d**", nrow(df)),
  sprintf("- Train size before balancing: **%d**", nrow(train_full)),
  sprintf("- Train size after balancing: **%d**", nrow(train_bal)),
  sprintf("- Test size: **%d**", nrow(test_full)),
  "",
  "## Models benchmarked",
  "",
  paste0("- Models run: ", paste(summary_df$model, collapse = ", ")),
  if (length(skipped_models) == 0) "- Skipped models: none" else paste0("- ", skipped_models),
  "",
  "## Benchmark results",
  "",
  "| Model | ROC-AUC | PR-AUC | Accuracy | Precision | Recall | Specificity | F1 | Brier |",
  "|------|--------:|-------:|---------:|----------:|-------:|------------:|---:|------:|",
  apply(summary_df, 1, function(r) {
    paste0("| ", r[["model"]], " | ", fmt4(as.numeric(r[["roc_auc"]])),
           " | ", fmt4(as.numeric(r[["pr_auc"]])),
           " | ", fmt4(as.numeric(r[["accuracy"]])),
           " | ", fmt4(as.numeric(r[["precision"]])),
           " | ", fmt4(as.numeric(r[["recall"]])),
           " | ", fmt4(as.numeric(r[["specificity"]])),
           " | ", fmt4(as.numeric(r[["f1"]])),
           " | ", fmt4(as.numeric(r[["brier"]])), " |")
  }),
  "",
  "## Plain-language interpretation",
  "",
  old_vs_new_text,
  best_vs_logit_text,
  sprintf("The best ROC-AUC model was **%s** at **%.4f**.", best_model_name, best_model_auc),
  sprintf("The best PR-AUC result was **%s** at **%.4f**.", top_metric_text(summary_df, "pr_auc"), max(summary_df$pr_auc, na.rm = TRUE)),
  "",
  "In simple terms: logistic regression remains the easiest model to explain, but Phase 3 checks whether that simplicity leaves meaningful predictive performance on the table.",
  "If a more flexible model only wins by a tiny margin, the extra complexity may not be worth it.",
  "",
  "## Calibration caution",
  "",
  "Brier scores are reported as a rough probability-error metric, but no recalibration step was applied.",
  "Because the models were trained on balanced data and tested on the real imbalanced data, raw predicted probabilities should be interpreted cautiously.",
  "",
  "## Major limitations",
  "",
  "- The evaluation still depends only on the 9 audio features, so major non-audio drivers of chart success remain missing.",
  "- The train/test split is random, not a time split, so this benchmark measures general discrimination rather than future-era forecasting.",
  "- Some optional models were skipped if their packages were unavailable in the current environment.",
  "- These models describe statistical association, not musical causation.",
  "",
  "## Files created in Phase 3",
  "",
  sprintf("- `%s`", clean_path),
  sprintf("- `%s`", train_path),
  sprintf("- `%s`", test_path),
  sprintf("- `%s`", comparison_csv),
  sprintf("- `%s`", notes_txt),
  sprintf("- `%s`", pred_sample_csv),
  sprintf("- `%s`", roc_csv),
  sprintf("- `%s`", pr_csv),
  sprintf("- `%s`", roc_png),
  sprintf("- `%s`", pr_png),
  sprintf("- `%s`", auc_png),
  sprintf("- `%s`", prauc_png),
  "",
  paste0("*Benchmark run: ", Sys.time(), "*")
)
writeLines(md_lines, summary_md)

# -----------------------------------------------------------------------------
# SECTION 13: Self-check
# -----------------------------------------------------------------------------
check_paths <- c(
  clean_path,
  train_path,
  test_path,
  comparison_csv,
  notes_txt,
  pred_sample_csv,
  roc_csv,
  pr_csv,
  roc_png,
  pr_png,
  auc_png,
  prauc_png,
  summary_md
)

exists_check <- vapply(check_paths, file.exists, logical(1))

cat("============================================================\n")
cat("PHASE 3 BENCHMARK SUITE COMPLETE\n")
cat("============================================================\n")
cat("Source used                :", src_path, "\n")
cat("Random seed                :", SEED, "\n")
cat("Clean enriched rows        :", nrow(df), "\n")
cat("Train rows before balance  :", nrow(train_full), "\n")
cat("Train rows after balance   :", nrow(train_bal), "\n")
cat("Test rows                  :", nrow(test_full), "\n")
cat("Models run                 :", paste(summary_df$model, collapse = ", "), "\n")
cat("Models skipped             :", if (length(skipped_models) == 0) "None" else paste(skipped_models, collapse = " | "), "\n")
cat("Old logistic baseline AUC  :", fmt4(old_logistic_auc), "\n")
cat("New enriched logistic AUC  :", fmt4(new_logistic_auc), "\n")
cat("Best ROC-AUC model         :", top_metric_text(summary_df, "roc_auc"), "\n")
cat("Best PR-AUC model          :", top_metric_text(summary_df, "pr_auc"), "\n")
cat("All requested outputs exist:", all(exists_check), "\n")
cat("============================================================\n")
