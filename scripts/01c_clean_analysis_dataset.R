# =============================================================================
# 01c_clean_analysis_dataset.R
# Light cleaning/finalization pass on merged dataset
#
# INPUT  : data/processed/spotify_billboard_merged_full.csv  (never overwritten)
# OUTPUTS: data/processed/spotify_billboard_analysis_clean.csv
#          outputs/tables/cleaning_summary.txt
#          outputs/tables/cleaning_flagged_rows.csv  (only if flags found)
#          docs/step2b_cleaning_summary.md
# =============================================================================

setwd("D:/SpotifyBillboardProject")

# ── Guard: source file must exist ────────────────────────────────────────────
src_path <- "data/processed/spotify_billboard_merged_full.csv"
if (!file.exists(src_path)) {
  stop("Source file not found: ", src_path,
       "\nRun 01b_build_merged_dataset.R first.")
}

cat("Reading source file...\n")
df <- read.csv(src_path, stringsAsFactors = FALSE)
cat("Rows:", nrow(df), "  Cols:", ncol(df), "\n\n")

# Store original snapshot for comparison at the end
orig_rows <- nrow(df)
orig_cols <- ncol(df)


# =============================================================================
# STEP 1 — Convert explicit from character to binary integer
# =============================================================================
cat("--- Step 1: Convert 'explicit' to binary integer ---\n")

explicit_raw_vals <- sort(unique(df$explicit))
cat("Unique values in 'explicit' before conversion:", paste(explicit_raw_vals, collapse=", "), "\n")

# Robust: uppercase comparison handles "True"/"False"/"TRUE"/"FALSE" etc.
df$explicit <- as.integer(toupper(trimws(df$explicit)) == "TRUE")

cat("After conversion — unique values:", paste(sort(unique(df$explicit)), collapse=", "), "\n")
cat("  explicit=1 (True) :", sum(df$explicit == 1), "\n")
cat("  explicit=0 (False):", sum(df$explicit == 0), "\n\n")


# =============================================================================
# STEP 2 — Confirm binary columns are integer 0/1
# =============================================================================
cat("--- Step 2: Confirm binary columns ---\n")

binary_cols <- c("charted", "explicit", "mode")
binary_ok <- TRUE

for (col in binary_cols) {
  vals <- sort(unique(df[[col]]))
  is_ok <- is.integer(df[[col]]) && all(vals %in% c(0L, 1L))
  # If numeric but not integer, coerce
  if (is.numeric(df[[col]]) && all(vals %in% c(0, 1))) {
    df[[col]] <- as.integer(df[[col]])
    is_ok <- TRUE
  }
  status <- if (is_ok) "OK" else "PROBLEM"
  cat(sprintf("  %-10s class=%-10s unique={%s}  [%s]\n",
              col, class(df[[col]]), paste(vals, collapse=","), status))
  if (!is_ok) binary_ok <- FALSE
}
if (binary_ok) cat("  All binary columns confirmed.\n\n") else cat("  WARNING: binary column issue detected.\n\n")


# =============================================================================
# STEP 3 — Confirm audio feature columns are numeric
# =============================================================================
cat("--- Step 3: Confirm audio feature types ---\n")

audio_features <- c("danceability","energy","valence","tempo","loudness",
                    "acousticness","speechiness","instrumentalness","liveness")
type_ok <- TRUE

for (feat in audio_features) {
  cls <- class(df[[feat]])
  is_ok <- cls %in% c("numeric","integer")
  cat(sprintf("  %-20s class=%-10s [%s]\n", feat, cls, if (is_ok) "OK" else "PROBLEM"))
  if (!is_ok) type_ok <- FALSE
}
if (type_ok) cat("  All audio features are numeric.\n\n") else cat("  WARNING: non-numeric audio feature detected.\n\n")


# =============================================================================
# STEP 4 — Check for missing values
# =============================================================================
cat("--- Step 4: Missing value check ---\n")

na_counts <- colSums(is.na(df))
total_na  <- sum(na_counts)
cat("  Total missing cells:", total_na, "\n")

if (total_na > 0) {
  cat("  Columns with missing values:\n")
  print(na_counts[na_counts > 0])
} else {
  cat("  No missing values found.\n")
}
cat("\n")


# =============================================================================
# STEP 5 — Check for duplicate rows
# =============================================================================
cat("--- Step 5: Duplicate row check ---\n")

dup_count <- sum(duplicated(df))
cat("  Duplicate rows:", dup_count, "\n")
if (dup_count == 0) cat("  No duplicates.\n\n") else cat("  WARNING: duplicates found.\n\n")


# =============================================================================
# STEP 6 — Feature range validation
# =============================================================================
cat("--- Step 6: Feature range validation ---\n")

# Expected ranges:  [0,1] for 7 unit-scaled features; tempo > 0; loudness <= 5
range_rules <- list(
  danceability     = c(0, 1),
  energy           = c(0, 1),
  valence          = c(0, 1),
  acousticness     = c(0, 1),
  speechiness      = c(0, 1),
  instrumentalness = c(0, 1),
  liveness         = c(0, 1),
  tempo            = c(0, Inf),   # must be positive
  loudness         = c(-Inf, 5)   # must be <= 5 dB (values > 5 are impossible)
)

flag_list   <- list()
range_ok    <- TRUE

for (feat in names(range_rules)) {
  lo <- range_rules[[feat]][1]
  hi <- range_rules[[feat]][2]
  col_vals <- df[[feat]]

  bad_lo <- if (is.finite(lo)) which(col_vals < lo) else integer(0)
  bad_hi <- if (is.finite(hi)) which(col_vals > hi) else integer(0)
  bad    <- union(bad_lo, bad_hi)

  obs_min <- min(col_vals, na.rm=TRUE)
  obs_max <- max(col_vals, na.rm=TRUE)

  status <- if (length(bad) == 0) "OK" else paste("FLAG:", length(bad), "rows")
  cat(sprintf("  %-20s range [%.3f, %.3f]  obs=[%.4f, %.4f]  [%s]\n",
              feat, lo, hi, obs_min, obs_max, status))

  if (length(bad) > 0) {
    range_ok <- FALSE
    flag_list[[feat]] <- data.frame(
      row_index = bad,
      feature   = feat,
      value     = col_vals[bad],
      rule      = sprintf("[%.3f, %.3f]", lo, hi),
      stringsAsFactors = FALSE
    )
  }
}

if (range_ok) {
  cat("  All feature ranges within expected bounds.\n\n")
} else {
  cat("  WARNING: out-of-range values flagged (see cleaning_flagged_rows.csv).\n\n")
}


# =============================================================================
# STEP 7 — Save cleaned dataset
# =============================================================================
cat("--- Step 7: Save cleaned dataset ---\n")

out_path <- "data/processed/spotify_billboard_analysis_clean.csv"
write.csv(df, out_path, row.names=FALSE)
cat("  Saved:", out_path, "\n")
cat("  Rows:", nrow(df), "  Cols:", ncol(df), "\n\n")

# Verify source was NOT overwritten
src_size  <- file.info(src_path)$size
out_size  <- file.info(out_path)$size
cat(sprintf("  Source file size : %s bytes\n", format(src_size, big.mark=",")))
cat(sprintf("  Output file size : %s bytes\n", format(out_size, big.mark=",")))
if (identical(normalizePath(src_path), normalizePath(out_path))) {
  stop("CRITICAL: source and output are the same file — aborting.")
} else {
  cat("  Source file was NOT overwritten. (Paths are distinct.)\n\n")
}


# =============================================================================
# STEP 8 — Save flagged rows (only if any flags)
# =============================================================================
if (length(flag_list) > 0) {
  cat("--- Step 8: Save flagged rows ---\n")
  flags_df <- do.call(rbind, flag_list)
  rownames(flags_df) <- NULL
  flags_path <- "outputs/tables/cleaning_flagged_rows.csv"
  write.csv(flags_df, flags_path, row.names=FALSE)
  cat("  Flagged rows saved:", flags_path, "\n")
  cat("  Total flagged:", nrow(flags_df), "\n\n")
} else {
  cat("--- Step 8: No flagged rows — cleaning_flagged_rows.csv not written ---\n\n")
}


# =============================================================================
# STEP 9 — Build cleaning summary text
# =============================================================================
cat("--- Step 9: Save cleaning_summary.txt ---\n")

summary_lines <- c(
  "CLEANING SUMMARY",
  paste0("Generated: ", Sys.time()),
  "",
  "SOURCE FILE",
  paste0("  Path    : ", src_path),
  paste0("  Rows    : ", orig_rows),
  paste0("  Cols    : ", orig_cols),
  "",
  "OUTPUT FILE",
  paste0("  Path    : ", out_path),
  paste0("  Rows    : ", nrow(df)),
  paste0("  Cols    : ", ncol(df)),
  "",
  "CHANGES MADE",
  paste0("  1. explicit column: character ('True'/'False') -> integer (1/0)"),
  paste0("     explicit=1 : ", sum(df$explicit == 1)),
  paste0("     explicit=0 : ", sum(df$explicit == 0)),
  "",
  "CHECKS PERFORMED",
  paste0("  Missing values        : ", total_na),
  paste0("  Duplicate rows        : ", dup_count),
  paste0("  Binary columns OK     : ", binary_ok),
  paste0("  Audio feature types OK: ", type_ok),
  paste0("  Feature ranges OK     : ", range_ok),
  paste0("  Flagged rows          : ", if (length(flag_list)==0) 0 else sum(sapply(flag_list, nrow))),
  "",
  "CLASS BALANCE (unchanged)",
  paste0("  charted=1 : ", sum(df$charted==1), " (", round(mean(df$charted==1)*100, 2), "%)"),
  paste0("  charted=0 : ", sum(df$charted==0), " (", round(mean(df$charted==0)*100, 2), "%)")
)

dir.create("outputs/tables", recursive=TRUE, showWarnings=FALSE)
writeLines(summary_lines, "outputs/tables/cleaning_summary.txt")
cat("  Saved: outputs/tables/cleaning_summary.txt\n\n")


# =============================================================================
# STEP 10 — Write docs/step2b_cleaning_summary.md
# =============================================================================
cat("--- Step 10: Save step2b_cleaning_summary.md ---\n")

flagged_total <- if (length(flag_list)==0) 0 else sum(sapply(flag_list, nrow))

md_lines <- c(
  "# Step 2b: Data Cleaning",
  "",
  paste0("> **Status: COMPLETE — light cleaning pass on merged dataset**"),
  "",
  "---",
  "",
  "## Purpose",
  "",
  "This step performs a light finalization pass on `spotify_billboard_merged_full.csv`.",
  "It does **not** balance classes, remove outliers, or engineer features.",
  "The goal is to produce a clean, analysis-ready CSV with correct column types",
  "and documented range checks.",
  "",
  "---",
  "",
  "## Source vs Output",
  "",
  "| | File |",
  "|-|------|",
  "| **Source (unchanged)** | `data/processed/spotify_billboard_merged_full.csv` |",
  "| **Clean output** | `data/processed/spotify_billboard_analysis_clean.csv` |",
  "",
  "---",
  "",
  "## Changes Made",
  "",
  "| Column | Before | After | Why |",
  "|--------|--------|-------|-----|",
  "| `explicit` | character `\"True\"`/`\"False\"` | integer `1`/`0` | Must be numeric for modeling |",
  "",
  "All other columns were already in the correct type.",
  "**No rows were added or removed.**",
  "",
  "---",
  "",
  "## Checks Performed",
  "",
  "| Check | Result |",
  "|-------|--------|",
  paste0("| Missing values | ", total_na, " |"),
  paste0("| Duplicate rows | ", dup_count, " |"),
  paste0("| Binary columns (`charted`, `explicit`, `mode`) | ", if(binary_ok) "All 0/1 integer" else "PROBLEM — see summary", " |"),
  paste0("| Audio features numeric | ", if(type_ok) "All confirmed numeric" else "PROBLEM — see summary", " |"),
  paste0("| Feature ranges within bounds | ", if(range_ok) "All OK" else paste("Flagged rows:", flagged_total), " |"),
  "",
  "---",
  "",
  "## Final Dataset",
  "",
  paste0("**File:** `data/processed/spotify_billboard_analysis_clean.csv`"),
  "",
  "| Item | Value |",
  "|------|-------|",
  paste0("| Rows | ", nrow(df), " |"),
  paste0("| Columns | ", ncol(df), " |"),
  paste0("| Missing values | 0 |"),
  paste0("| charted=1 | ", sum(df$charted==1), " (", round(mean(df$charted==1)*100,2), "%) |"),
  paste0("| charted=0 | ", sum(df$charted==0), " (", round(mean(df$charted==0)*100,2), "%) |"),
  "",
  "---",
  "",
  "## Column Types (final)",
  "",
  "| Column | Type | Notes |",
  "|--------|------|-------|",
  "| `charted` | integer (0/1) | outcome variable |",
  "| `explicit` | integer (0/1) | converted from character |",
  "| `mode` | integer (0/1) | minor/major |",
  "| `danceability` | numeric | 0–1 |",
  "| `energy` | numeric | 0–1 |",
  "| `valence` | numeric | 0–1 |",
  "| `acousticness` | numeric | 0–1 |",
  "| `speechiness` | numeric | 0–1 |",
  "| `instrumentalness` | numeric | 0–1 |",
  "| `liveness` | numeric | 0–1 |",
  "| `tempo` | numeric | BPM (positive) |",
  "| `loudness` | numeric | dB (negative to ~0) |",
  "| `popularity` | integer | 0–100 |",
  "| `duration_ms` | numeric | milliseconds |",
  "| `time_signature` | integer | beats per bar |",
  "| `song_name` | character | metadata |",
  "| `artist` | character | metadata |",
  "| `album` | character | metadata |",
  "",
  "---",
  "",
  "## What Happens Next",
  "",
  "```",
  "[STEP 2b COMPLETE] Cleaning done.",
  "  -> data/processed/spotify_billboard_analysis_clean.csv is the analysis file",
  "",
  "[STEP 3 — NEXT] Hypothesis Testing",
  "  -> Compare charted vs non-charted on each audio feature",
  "  -> Two-sample tests (Wilcoxon / t-test) for each of 9 features",
  "```",
  "",
  paste0("*Cleaning run: ", Sys.time(), "*")
)

dir.create("docs", recursive=TRUE, showWarnings=FALSE)
writeLines(md_lines, "docs/step2b_cleaning_summary.md")
cat("  Saved: docs/step2b_cleaning_summary.md\n\n")


# =============================================================================
# FINAL REPORT
# =============================================================================
cat("=============================================================\n")
cat("CLEANING COMPLETE\n")
cat("=============================================================\n")
cat(sprintf("  Source (unchanged) : %s\n", src_path))
cat(sprintf("  Clean output       : %s\n", out_path))
cat(sprintf("  Rows               : %d (unchanged)\n", nrow(df)))
cat(sprintf("  Explicit converted : character -> integer\n"))
cat(sprintf("  Missing values     : %d\n", total_na))
cat(sprintf("  Duplicate rows     : %d\n", dup_count))
cat(sprintf("  Flagged rows       : %d\n", flagged_total))
cat("=============================================================\n")
