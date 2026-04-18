# =============================================================================
# Script: 01_data_inspection.R
# Project: Predicting Billboard Chart Success from Spotify Audio Features
# Purpose: Full data audit of the merged analysis dataset (Step 1).
#          This script checks dimensions, types, missingness, duplicates,
#          class balance, and proposal variable coverage.
#          No modeling, no sampling, no balancing is done here.
#
# Dataset audited:
#   data/processed/spotify_billboard_merged_full.csv
#   (built by scripts/01b_build_merged_dataset.R)
#
# Outputs:
#   outputs/tables/data_audit_summary.txt
#   docs/step1_data_understanding.md   (updated with real values)
#
# Uses ONLY base R — no package installation required.
# Works with any R version 3.5+, including the R bundled with IBM SPSS.
# =============================================================================

# ── 0. SETUP ──────────────────────────────────────────────────────────────────

project_root <- "D:/SpotifyBillboardProject"
setwd(project_root)
cat("Working directory:", getwd(), "\n\n")

# The dataset path is EXPLICIT — this script must not silently inspect a
# different file. If the processed file does not exist, stop with a clear
# message instead of falling back to the raw folder.
dataset_path <- "data/processed/spotify_billboard_merged_full.csv"

if (!file.exists(dataset_path)) {
  stop(
    "\n\n",
    "==============================================================\n",
    " DATASET NOT FOUND:\n",
    "   ", dataset_path, "\n",
    "--------------------------------------------------------------\n",
    " Please run scripts/01b_build_merged_dataset.R first to\n",
    " create the merged analysis dataset.\n",
    "==============================================================\n"
  )
}

cat("=============================================================\n")
cat("  DATASET FILE :", basename(dataset_path), "\n")
cat("  FULL PATH    :", dataset_path, "\n")
cat("  SOURCE       : built by 01b_build_merged_dataset.R\n")
cat("=============================================================\n\n")

# ── 1. LOAD DATA ──────────────────────────────────────────────────────────────

df <- read.csv(dataset_path, stringsAsFactors = FALSE, check.names = FALSE)

# ── 2. PROPOSAL MISMATCH WARNING ─────────────────────────────────────────────

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# IMPORTANT: This dataset does NOT exactly match what the project proposal
# described. Read this section carefully before proceeding.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# The original proposal was written assuming a pre-built, balanced Kaggle
# dataset of approximately 18,454 rows (about 9,227 charted + 9,227 not
# charted songs). That balanced dataset does not exist locally.
#
# What we built instead (this file) comes from joining two raw source tables:
#   - billboardHot100_1999-2019.csv  (chart history)
#   - songAttributes_1999-2019.csv   (Spotify audio features)
#
# Key differences vs. the proposal's expected dataset:
#   1. SIZE: This file has 128,745 rows — roughly 7× larger.
#   2. IMBALANCE: The class ratio is approximately 34.6:1 (not balanced).
#      - charted = 1 : 3,618 songs  (2.81%)
#      - charted = 0 : 125,127 songs (97.19%)
#   3. CHARTED SONGS: Only 3,618 Billboard songs could be matched to audio
#      features. The other 3,595 Billboard songs (real chart hits like
#      "Old Town Road", "Bad Guy") are absent from songAttributes and were
#      therefore excluded.
#   4. CONSERVATIVE MATCHING: Matching was done on cleaned song name +
#      cleaned primary artist only. No risky title-only fallback was used
#      because it produced false positives.
#
# What this means for the project:
#   - The data IS usable for logistic regression and PCA.
#   - The IMBALANCE must be addressed before modeling (e.g., undersampling).
#   - The audio feature columns and outcome column are both present.
#   - The proposal's methodology still applies — only the scale differs.

cat("==============================================================\n")
cat("  !! PROPOSAL MISMATCH WARNING !!\n")
cat("==============================================================\n")
cat("  This dataset is NOT the balanced Kaggle dataset the proposal\n")
cat("  was written for. Key differences:\n")
cat("\n")
cat("  Expected (proposal):  ~18,454 rows, ~50/50 class balance\n")
cat("  Actual (this file) :  128,745 rows, 34.6:1 class imbalance\n")
cat("\n")
cat("  Why the difference:\n")
cat("  The raw Kaggle download was a set of source tables, not a\n")
cat("  pre-merged analysis file. We built this dataset by joining\n")
cat("  Billboard chart data + Spotify audio features conservatively.\n")
cat("  Only 3,618 of 7,213 Billboard songs matched to audio features.\n")
cat("\n")
cat("  This dataset IS suitable for the project's methods (EDA,\n")
cat("  hypothesis testing, PCA, logistic regression) — but the\n")
cat("  class imbalance must be addressed before modeling.\n")
cat("  No rebalancing has been done here. That is a future step.\n")
cat("==============================================================\n\n")

# ── 3. BASIC DIMENSIONS ───────────────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 1: BASIC DIMENSIONS\n")
cat("--------------------------------------------------------------\n")
cat("Rows    :", nrow(df), "\n")
cat("Columns :", ncol(df), "\n\n")

# ── 4. COLUMN NAMES ───────────────────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 2: COLUMN NAMES\n")
cat("--------------------------------------------------------------\n")
cat(paste(seq_along(names(df)), names(df), sep = ". ", collapse = "\n"), "\n\n")

# ── 5. DATA STRUCTURE ─────────────────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 3: DATA STRUCTURE (R-inferred types)\n")
cat("--------------------------------------------------------------\n")
str(df)
cat("\n")

# ── 6. MISSING VALUES ─────────────────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 4: MISSING VALUES PER COLUMN\n")
cat("--------------------------------------------------------------\n")

missing_counts <- colSums(is.na(df))
pct_missing    <- round(missing_counts / nrow(df) * 100, 2)
missing_df     <- data.frame(
  column        = names(missing_counts),
  missing_count = as.integer(missing_counts),
  pct_missing   = pct_missing,
  row.names     = NULL
)
missing_df <- missing_df[order(-missing_df$missing_count), ]
print(missing_df, row.names = FALSE)

total_missing_cells <- sum(missing_counts)
cat("\nTotal missing cells:", total_missing_cells, "\n\n")

# ── 7. DUPLICATE ROWS ─────────────────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 5: DUPLICATE ROWS\n")
cat("--------------------------------------------------------------\n")

n_dupes <- sum(duplicated(df))
cat("Duplicate rows:", n_dupes, "\n")
if (n_dupes > 0) {
  cat("[WARNING]", n_dupes, "exact duplicate rows found.\n")
  cat("         These should be removed before modeling.\n")
} else {
  cat("[OK] No duplicate rows.\n")
}
cat("\n")

# ── 8. OUTCOME VARIABLE — CLASS BALANCE ───────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 6: OUTCOME VARIABLE — CLASS BALANCE\n")
cat("--------------------------------------------------------------\n")

# The outcome column is known: "charted" (binary 0/1)
# We still do a proper check in case of unexpected column naming.
actual_cols_lower <- tolower(names(df))
outcome_candidates <- c("charted", "on_billboard", "billboard", "charted_hot100",
                        "hot100", "chart_week", "in_billboard", "hit",
                        "in_hot100", "billboard_hot100", "is_charted", "is_hit")
found_outcome <- intersect(outcome_candidates, actual_cols_lower)

if (length(found_outcome) == 0) {
  cat("[ERROR] No outcome variable found. Expected 'charted' column.\n")
  cat("        Columns present:", paste(names(df), collapse = ", "), "\n\n")
  outcome_col <- NULL
} else {
  outcome_col <- names(df)[actual_cols_lower == found_outcome[1]]
  cat("Outcome column     :", outcome_col, "\n")
  cat("Expected values    : 0 (not charted) or 1 (charted on Billboard)\n\n")

  outcome_vals <- df[[outcome_col]]
  tbl          <- table(outcome_vals, useNA = "ifany")

  cat("Value counts:\n")
  print(tbl)

  cat("\nProportions:\n")
  print(round(prop.table(tbl), 4))

  n_class0 <- sum(outcome_vals == 0, na.rm = TRUE)
  n_class1 <- sum(outcome_vals == 1, na.rm = TRUE)
  ratio    <- round(n_class0 / max(n_class1, 1), 1)

  cat("\n")
  cat("[NOTE] Class imbalance detected:", ratio, ":1 (not-charted : charted)\n")
  cat("       This imbalance must be addressed before logistic regression.\n")
  cat("       Balancing/sampling has NOT been done here — that is a future step.\n\n")
}

# ── 9. COLUMN TYPE CLASSIFICATION ─────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 7: COLUMN TYPE CLASSIFICATION\n")
cat("--------------------------------------------------------------\n")

classify_column <- function(col_name, col_data) {
  n_unique  <- length(unique(stats::na.omit(col_data)))
  col_class <- class(col_data)[1]

  if (col_class %in% c("numeric", "double", "integer")) {
    clean <- stats::na.omit(col_data)
    if (n_unique == 2 && all(clean %in% c(0, 1))) {
      return("binary (0/1)")
    } else if (n_unique <= 10) {
      return(paste0("numeric (low-cardinality, ", n_unique, " values)"))
    } else {
      return("numeric (continuous)")
    }
  } else if (col_class == "character") {
    if (n_unique <= 5) {
      return(paste0("categorical (", n_unique, " levels)"))
    } else if (n_unique > nrow(df) * 0.8) {
      return("text / ID (high cardinality)")
    } else {
      return(paste0("categorical/text (", n_unique, " unique values)"))
    }
  } else if (col_class == "logical") {
    return("binary (TRUE/FALSE)")
  } else if (col_class %in% c("Date", "POSIXct", "POSIXlt")) {
    return("date/datetime")
  } else {
    return(paste0("other (", col_class, ")"))
  }
}

type_df <- data.frame(
  column   = names(df),
  r_class  = sapply(df, function(x) class(x)[1]),
  n_unique = sapply(df, function(x) length(unique(stats::na.omit(x)))),
  inferred = mapply(classify_column, names(df), df),
  row.names = NULL,
  stringsAsFactors = FALSE
)

print(type_df, row.names = FALSE)
cat("\n")

# ── 10. PROPOSAL VARIABLE CHECK ───────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 8: PROPOSAL VARIABLE CHECK\n")
cat("--------------------------------------------------------------\n")

proposal_vars <- c(
  "charted",            # outcome variable
  "danceability",
  "energy",
  "valence",
  "tempo",
  "loudness",
  "acousticness",
  "speechiness",
  "instrumentalness",
  "liveness"
)

for (v in proposal_vars) {
  status <- if (v %in% actual_cols_lower) "[FOUND  ]" else "[MISSING]"
  actual <- if (v %in% actual_cols_lower) {
    paste0("-> actual column name: '", names(df)[actual_cols_lower == v], "'")
  } else {
    "-> NOT in dataset"
  }
  cat(sprintf("  %s  %-22s  %s\n", status, v, actual))
}

found_count        <- sum(proposal_vars %in% actual_cols_lower)
missing_count_prop <- length(proposal_vars) - found_count
cat(sprintf("\nSummary: %d/%d proposal variables found, %d missing.\n\n",
            found_count, length(proposal_vars), missing_count_prop))

# ── 11. EXTRA COLUMNS (beyond the proposal) ───────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 9: EXTRA COLUMNS (not mentioned in the proposal)\n")
cat("--------------------------------------------------------------\n")

extra_cols <- names(df)[!actual_cols_lower %in% tolower(proposal_vars)]
if (length(extra_cols) > 0) {
  cat("These columns are in the data but were NOT in the proposal:\n")
  for (ec in extra_cols) cat("  -", ec, "\n")
  cat("  These are optional metadata useful for EDA; not predictors.\n")
} else {
  cat("No extra columns.\n")
}
cat("\n")

# ── 12. NUMERIC SUMMARY STATISTICS ────────────────────────────────────────────

cat("--------------------------------------------------------------\n")
cat("SECTION 10: NUMERIC COLUMNS — SUMMARY STATISTICS\n")
cat("--------------------------------------------------------------\n")

numeric_cols <- names(df)[sapply(df, is.numeric)]
if (length(numeric_cols) > 0) {
  print(summary(df[, numeric_cols, drop = FALSE]))
} else {
  cat("No numeric columns detected.\n")
}
cat("\n")

# ── 13. BUILD AUDIT SUMMARY TEXT ─────────────────────────────────────────────

# (Also used by Section 14 to print and Section 15 to save)

mismatch_block <- c(
  "--- PROPOSAL MISMATCH WARNING ---",
  "  The original proposal was based on a pre-built balanced Kaggle dataset",
  "  (~18,454 rows, ~50/50 split). This merged dataset differs because:",
  "",
  "  Expected (proposal) : ~18,454 rows, balanced 50/50 classes",
  paste("  Actual (this file)  :", nrow(df), "rows,",
        round(sum(df$charted==0)/sum(df$charted==1), 1), ":1 class imbalance"),
  "",
  "  Root cause:",
  "  - The Kaggle download was a set of source tables, not a merged file.",
  "  - We joined Billboard chart history + Spotify audio features conservatively.",
  "  - Only songs present in BOTH tables (by cleaned name + primary artist)",
  "    were labeled charted=1.",
  paste("  - 3,618 of 7,213 Billboard songs matched to audio features."),
  "  - The other 3,595 charted songs are absent from songAttributes.",
  "",
  "  Impact on the project:",
  "  - All 9 proposal audio features are present.",
  "  - The binary charted outcome column is present.",
  "  - The imbalance MUST be corrected (undersampling/oversampling) before",
  "    logistic regression — that is a future step, not done here.",
  "  - EDA, hypothesis testing, and PCA can proceed on this full dataset."
)

outcome_block <- if (!is.null(outcome_col)) {
  tbl_txt <- capture.output(print(table(df[[outcome_col]], useNA = "ifany")))
  c(paste("Column     :", outcome_col),
    paste("charted=0  :", sum(df[[outcome_col]] == 0, na.rm = TRUE)),
    paste("charted=1  :", sum(df[[outcome_col]] == 1, na.rm = TRUE)),
    paste("Ratio (0:1):", round(sum(df[[outcome_col]]==0)/
                                max(sum(df[[outcome_col]]==1),1), 1), ":1"))
} else {
  "OUTCOME NOT FOUND"
}

audit_lines <- c(
  "=============================================================",
  "  DATA AUDIT SUMMARY",
  paste("  Generated :", Sys.time()),
  paste("  Dataset   :", dataset_path),
  "=============================================================",
  "",
  paste("Rows              :", nrow(df)),
  paste("Columns           :", ncol(df)),
  paste("Total missing     :", total_missing_cells),
  paste("Duplicate rows    :", n_dupes),
  "",
  mismatch_block,
  "",
  "--- Outcome Variable ---",
  outcome_block,
  "",
  "--- Proposal Variable Check ---",
  sapply(proposal_vars, function(v) {
    status <- if (v %in% actual_cols_lower) "FOUND  " else "MISSING"
    paste0("  [", status, "] ", v)
  }),
  paste("  Found  :", found_count, "/ ", length(proposal_vars)),
  paste("  Missing:", missing_count_prop),
  "",
  "--- Column Type Classification ---",
  capture.output(print(type_df, row.names = FALSE)),
  "",
  "--- Extra Columns (beyond proposal) ---",
  if (length(extra_cols) > 0) paste("  -", extra_cols) else "  None",
  "",
  "--- Missing Values by Column ---",
  capture.output(print(missing_df, row.names = FALSE)),
  ""
)

# ── 14. PRINT FULL AUDIT TO CONSOLE ──────────────────────────────────────────

cat("=============================================================\n")
cat("  DATA AUDIT SUMMARY\n")
cat("=============================================================\n")
cat(paste(audit_lines, collapse = "\n"), "\n")

# ── 15. SAVE AUDIT TO FILE ────────────────────────────────────────────────────

audit_out <- "outputs/tables/data_audit_summary.txt"
writeLines(audit_lines, audit_out)
cat("[SAVED] Audit summary:", audit_out, "\n")

# Verify it was written
if (file.exists(audit_out) && file.info(audit_out)$size > 0) {
  cat("        Verified: file exists,", file.info(audit_out)$size, "bytes\n")
}
cat("\n")

# ── 16. UPDATE step1_data_understanding.md ───────────────────────────────────

n_charted    <- sum(df$charted == 1, na.rm = TRUE)
n_noncharted <- sum(df$charted == 0, na.rm = TRUE)
ratio_str    <- paste0(round(n_noncharted / n_charted, 1), ":1")

# Build the markdown content with ACTUAL values (no placeholders)
md_lines <- c(
  "# Step 1: Data Understanding",
  "",
  "> **Status: COMPLETE — audit ran on merged dataset**",
  "",
  "---",
  "",
  "## What Is This Project About?",
  "",
  "We want to answer one question:",
  "",
  "> **Can we predict whether a song will appear on the Billboard Hot 100 chart",
  "> just by looking at its Spotify audio features?**",
  "",
  "---",
  "",
  "## Dataset Actually Used",
  "",
  paste("**File:**", "`data/processed/spotify_billboard_merged_full.csv`"),
  paste("**Built by:** `scripts/01b_build_merged_dataset.R`"),
  paste("**Source tables:** `billboardHot100_1999-2019.csv` +",
        "`songAttributes_1999-2019.csv`"),
  "",
  "---",
  "",
  "## Actual Dataset Facts (as of this audit)",
  "",
  paste("| Item | Value |"),
  paste("|------|-------|"),
  paste("| Rows | ", nrow(df), " |"),
  paste("| Columns | ", ncol(df), " |"),
  paste("| Missing values | ", total_missing_cells, " |"),
  paste("| Duplicate rows | ", n_dupes, " |"),
  paste("| charted = 1 (yes) | ", n_charted, " (", round(n_charted/nrow(df)*100,2), "%) |"),
  paste("| charted = 0 (no) | ", n_noncharted, " (", round(n_noncharted/nrow(df)*100,2), "%) |"),
  paste("| Class imbalance ratio | ", ratio_str, " |"),
  "",
  "---",
  "",
  "## Full Column List",
  "",
  paste(sapply(seq_along(names(df)), function(i) {
    paste0("| `", sprintf("%2d", i), "` | `", names(df)[i], "` |")
  }), collapse = "\n"),
  "",
  "---",
  "",
  "## Outcome Column",
  "",
  "- **Name:** `charted`",
  "- **Type:** Binary integer (0 or 1)",
  "- **Meaning:**",
  "  - `charted = 1` — song appeared on the Billboard Hot 100 AND has Spotify audio features",
  "  - `charted = 0` — song has audio features but did NOT chart on Billboard Hot 100",
  "",
  "---",
  "",
  "## Predictors Available",
  "",
  "All 9 audio features from the project proposal are present:",
  "",
  "| Feature | Column Name | Type |",
  "|---------|-------------|------|",
  "| Danceability | `danceability` | Numeric, 0–1 |",
  "| Energy | `energy` | Numeric, 0–1 |",
  "| Valence | `valence` | Numeric, 0–1 |",
  "| Tempo | `tempo` | Numeric, BPM |",
  "| Loudness | `loudness` | Numeric, dB |",
  "| Acousticness | `acousticness` | Numeric, 0–1 |",
  "| Speechiness | `speechiness` | Numeric, 0–1 |",
  "| Instrumentalness | `instrumentalness` | Numeric, 0–1 |",
  "| Liveness | `liveness` | Numeric, 0–1 |",
  "",
  "**Extra columns** (metadata, not predictors in the proposal):",
  "`song_name`, `artist`, `album`, `duration_ms`, `explicit`, `mode`,",
  "`popularity`, `time_signature`",
  "",
  "---",
  "",
  "## IMPORTANT: How This Dataset Differs from the Proposal",
  "",
  "The project proposal was likely written using a **pre-built, balanced Kaggle**",
  "**dataset** — approximately 18,454 rows with roughly equal numbers of charted",
  "and non-charted songs.",
  "",
  "**What we actually have is different:**",
  "",
  "| | Proposal Expected | Actual |",
  "|-|-------------------|--------|",
  "| Rows | ~18,454 | 128,745 |",
  "| Class balance | ~50/50 | 97.2% / 2.8% |",
  "| Imbalance ratio | ~1:1 | 34.6:1 |",
  "| Source | Single merged CSV | Built from two source tables |",
  "",
  "**Why the difference?**",
  "",
  "The Kaggle download (`BillboardFromLast20`) contained separate source tables,",
  "not a single merged analysis file. We joined them conservatively:",
  "",
  "- `songAttributes_1999-2019.csv` — 154,931 rows → 128,745 after deduplication",
  "- `billboardHot100_1999-2019.csv` — 97,225 rows → 7,213 unique charted songs",
  "- **Only 3,618 of 7,213 Billboard songs** could be matched to audio features",
  "  by cleaned song name + cleaned primary artist.",
  "- The remaining 3,595 Billboard songs (including major hits like 'Old Town Road'",
  "  by Lil Nas X, 'Bad Guy' by Billie Eilish) are **absent from songAttributes**.",
  "- No risky title-only fallback matching was used (it produced false positives).",
  "",
  "**What this means for the project:**",
  "",
  "- The dataset IS usable for all four methods: EDA, hypothesis testing, PCA,",
  "  and logistic regression.",
  "- The severe class imbalance **must be addressed** before modeling.",
  "  Typical approaches: random undersampling, SMOTE, or class-weighted logistic",
  "  regression. This will be done in a future step.",
  "- EDA and hypothesis testing can be run on the full imbalanced dataset.",
  "- This mismatch does not invalidate the project — it just means the scale",
  "  and balance are different from what the proposal assumed.",
  "",
  "---",
  "",
  "## Missing Values",
  "",
  paste0("**Total missing cells: ", total_missing_cells, "**"),
  "",
  "| Column | Missing Count | % Missing |",
  "|--------|--------------|-----------|",
  paste(apply(missing_df, 1, function(r) {
    paste0("| `", r["column"], "` | ", r["missing_count"], " | ", r["pct_missing"], "% |")
  }), collapse = "\n"),
  "",
  "---",
  "",
  "## What Happens Next",
  "",
  "```",
  "[STEP 1 COMPLETE] Data inspection done.",
  "  → data/processed/spotify_billboard_merged_full.csv audited",
  "  → outputs/tables/data_audit_summary.txt saved",
  "",
  "[STEP 2 — NEXT] Exploratory Data Analysis (EDA)",
  "  → scripts/02_eda.R",
  "  → histograms, boxplots, correlation plots of audio features",
  "",
  "[STEP 3] Hypothesis Testing",
  "  → compare charted vs non-charted on each audio feature",
  "",
  "[STEP 4] Principal Component Analysis (PCA)",
  "",
  "[STEP 5] Logistic Regression",
  "  → requires class balancing first",
  "```",
  "",
  paste("*Audit run:", format(Sys.time()), "*")
)

docs_out <- "docs/step1_data_understanding.md"
writeLines(md_lines, docs_out)
cat("[SAVED] Markdown doc:", docs_out, "\n")

if (file.exists(docs_out) && file.info(docs_out)$size > 0) {
  cat("        Verified: file exists,", file.info(docs_out)$size, "bytes\n")
}
cat("\n")

# ── 17. DONE ──────────────────────────────────────────────────────────────────

cat("=============================================================\n")
cat("  SCRIPT COMPLETE — 01_data_inspection.R\n")
cat("=============================================================\n")
cat("  Dataset audited :", dataset_path, "\n")
cat("  Rows            :", nrow(df), "\n")
cat("  Columns         :", ncol(df), "\n")
cat("  charted = 1     :", n_charted, "\n")
cat("  charted = 0     :", n_noncharted, "\n")
cat("  Missing values  :", total_missing_cells, "\n")
cat("  Duplicates      :", n_dupes, "\n")
cat("  No modeling done.\n")
cat("  No sampling or balancing done.\n")
cat("  Next step: scripts/02_eda.R\n")
cat("=============================================================\n")
