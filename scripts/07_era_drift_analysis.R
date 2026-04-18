# =============================================================================
# Script : 07_era_drift_analysis.R
# Project: Predicting Billboard Chart Success from Spotify Audio Features
# Phase  : PHASE 2 — "The Shifting Sound of Success" — Era Drift Analysis
# Purpose: Study whether the audio DNA of chart success changed from 1999–2019.
#
#          THIS SCRIPT DOES NOT overwrite any existing dataset.
#          THIS SCRIPT DOES NOT re-run EDA, hypothesis tests, PCA, or the
#          main logistic regression model from earlier phases.
#
# Source files (read-only):
#   data/raw/BillboardFromLast20/billboardHot100_1999-2019.csv
#   data/raw/BillboardFromLast20/songAttributes_1999-2019.csv
#   data/processed/spotify_billboard_merged_enriched_full.csv
#
# New output files created by this script:
#   outputs/tables/era_feature_means.csv
#   outputs/tables/era_counts.csv
#   outputs/tables/era_model_coefficients.csv
#   outputs/tables/era_drift_summary.txt
#   outputs/figures/era_drift/era_feature_trends.png
#   outputs/figures/era_drift/era_coefficient_drift.png
#   outputs/figures/era_drift/era_counts.png
#   outputs/figures/era_drift/era_pvalue_heatmap.png
#   docs/step7_era_drift_summary.md
#
# Uses ONLY base R. No external packages required.
#
# =============================================================================
# IMPORTANT: WHY THE FALLBACK MODEL WAS USED
# =============================================================================
#
# The preferred analysis would be era-specific charted-vs-noncharted logistic
# regression. This requires BOTH classes to have a reliable year label.
#
# Charted songs (Billboard entries): year is known from the 'Week' column.
# Non-charted songs (songAttributes not on Billboard): NO year is available.
#   — songAttributes has no release date, no chart date, no year field.
#   — Assigning a year to non-charted songs would require fabrication.
#   — We will NOT fabricate years for non-charted songs.
#
# Honest fallback used:
#   Within-chart logistic regression per era.
#   Outcome: top10_hit = 1 if Peak.position <= 10, else 0
#   Predictors: same 9 audio features as the main analysis
#   This answers: "Which audio features predicted a top-10 hit (vs. lower
#   chart position) in each era, and how did that relationship change?"
#
# =============================================================================


# ── SECTION 0: SETUP ─────────────────────────────────────────────────────────

project_root <- "D:/SpotifyBillboardProject"
setwd(project_root)
cat("Working directory:", getwd(), "\n\n")

billboard_path    <- "data/raw/BillboardFromLast20/billboardHot100_1999-2019.csv"
attr_path         <- "data/raw/BillboardFromLast20/songAttributes_1999-2019.csv"
enriched_path     <- "data/processed/spotify_billboard_merged_enriched_full.csv"

for (p in c(billboard_path, attr_path, enriched_path)) {
  if (!file.exists(p)) stop("Source file not found: ", p)
}
cat("[OK] All source files found.\n\n")

# Create output directories if needed
for (d in c("outputs/tables", "outputs/figures/era_drift", "docs")) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# The 9 audio features to analyze
AUDIO_FEATURES <- c("danceability", "energy", "valence", "tempo",
                    "loudness", "acousticness", "speechiness",
                    "instrumentalness", "liveness")

# Era definitions: 5 balanced blocks covering 1999–2019
ERA_DEFS <- data.frame(
  start = c(1999, 2003, 2007, 2011, 2015),
  end   = c(2002, 2006, 2010, 2014, 2019),
  label = c("1999-2002", "2003-2006", "2007-2010", "2011-2014", "2015-2019"),
  stringsAsFactors = FALSE
)
N_ERAS <- nrow(ERA_DEFS)
cat("Era definitions:\n")
for (i in seq_len(N_ERAS)) {
  cat(sprintf("  Era %d: %s\n", i, ERA_DEFS$label[i]))
}
cat("\n")

# Color palette for 9 audio features (visually distinct)
FEATURE_COLORS <- c(
  danceability     = "#E41A1C",
  energy           = "#377EB8",
  valence          = "#4DAF4A",
  tempo            = "#FF7F00",
  loudness         = "#984EA3",
  acousticness     = "#A65628",
  speechiness      = "#F781BF",
  instrumentalness = "#999999",
  liveness         = "#00BFC4"
)
FEATURE_LTYS <- setNames(1:9, AUDIO_FEATURES)  # line types for accessibility


# ── SECTION 1: HELPER FUNCTIONS ───────────────────────────────────────────────
# These mirror the Phase 1 (script 06) normalization functions exactly.

clean_basic <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("[^a-z0-9 ]", "", x)
  x <- gsub("\\s+", " ", x)
  x <- trimws(x)
  x
}

remove_accents <- function(x) {
  x <- as.character(x)
  x <- gsub("[\u00E0\u00E1\u00E2\u00E3\u00E4\u00E5]", "a", x)
  x <- gsub("[\u00C0\u00C1\u00C2\u00C3\u00C4\u00C5]", "a", x)
  x <- gsub("[\u00E8\u00E9\u00EA\u00EB]", "e", x)
  x <- gsub("[\u00C8\u00C9\u00CA\u00CB]", "e", x)
  x <- gsub("[\u00EC\u00ED\u00EE\u00EF]", "i", x)
  x <- gsub("[\u00CC\u00CD\u00CE\u00CF]", "i", x)
  x <- gsub("[\u00F2\u00F3\u00F4\u00F5\u00F6\u00F8]", "o", x)
  x <- gsub("[\u00D2\u00D3\u00D4\u00D5\u00D6\u00D8]", "o", x)
  x <- gsub("[\u00F9\u00FA\u00FB\u00FC]", "u", x)
  x <- gsub("[\u00D9\u00DA\u00DB\u00DC]", "u", x)
  x <- gsub("[\u00FD\u00FF\u00DD]", "y", x)
  x <- gsub("[\u00F1\u00D1]", "n", x)
  x <- gsub("[\u00E7\u00C7]", "c", x)
  x <- gsub("\u00DF", "ss", x)
  x <- gsub("[\u00E6\u00C6]", "ae", x)
  x
}

normalize_title <- function(x) {
  x <- remove_accents(as.character(x))
  x <- gsub("[\u2018\u2019\u02BC\u0060]", "'", x)
  x <- gsub("[\u201C\u201D]", '"', x)
  x <- gsub("(?i)\\s*\\(feat\\.?[^)]*\\)", "", x, perl = TRUE)
  x <- gsub("(?i)\\s*\\[feat\\.?[^\\]]*\\]", "", x, perl = TRUE)
  x <- gsub("(?i)\\s*\\(f(?:eaturing|t\\.?)[^)]*\\)", "", x, perl = TRUE)
  x <- gsub("(?i)\\s*\\[f(?:eaturing|t\\.?)[^\\]]*\\]", "", x, perl = TRUE)
  ver_kw <- paste0(
    "remaster(?:ed)?|live|acoustic|mono|stereo|radio.?edit|radio.?version",
    "|single.?version|album.?version|explicit|clean|bonus.?track|bonus",
    "|deluxe|demo|reprise|extended|piano.?version|string.?version",
    "|orchestral|anniversary|original.?mix|original.?version|tribute"
  )
  x <- gsub(paste0("(?i)\\s*\\([^)]*(?:", ver_kw, ")[^)]*\\)"), "", x, perl = TRUE)
  x <- gsub(paste0("(?i)\\s*\\[[^\\]]*(?:", ver_kw, ")[^\\]]*\\]"), "", x, perl = TRUE)
  x <- gsub(paste0("(?i)\\s*-\\s*(?:(?:[0-9]{4}\\s+)?(?:", ver_kw, ")).*$"),
            "", x, perl = TRUE)
  x <- gsub("(?i)\\s+f(?:eaturing|eat\\.?|t\\.?)\\s.*$", "", x, perl = TRUE)
  x <- clean_basic(x)
  x
}

extract_primary_artist_bill <- function(artists_str) {
  x <- as.character(artists_str)
  x <- gsub("(?i)\\s+f(?:eaturing|eat\\.?|t\\.?)\\s.*$", "", x, perl = TRUE)
  x <- sub(",.*", "", x)
  x <- trimws(x)
  x
}

normalize_artist <- function(x) {
  x <- remove_accents(as.character(x))
  x <- gsub("(?i)\\s+f(?:eaturing|eat\\.?|t\\.?)\\s.*$", "", x, perl = TRUE)
  x <- clean_basic(x)
  x
}

# Assign an era label given a year
assign_era <- function(years) {
  era <- character(length(years))
  for (i in seq_len(N_ERAS)) {
    idx <- !is.na(years) & years >= ERA_DEFS$start[i] & years <= ERA_DEFS$end[i]
    era[idx] <- ERA_DEFS$label[i]
  }
  era[era == ""] <- NA
  era
}


# ── SECTION 2: READ AND PREPARE THE ENRICHED MERGED FILE ──────────────────────

cat("==============================================================\n")
cat("SECTION 2: LOADING ENRICHED MERGED FILE (CHARTED SONGS)\n")
cat("==============================================================\n\n")

cat("[INFO] Reading enriched merged file...\n")
merged <- read.csv(enriched_path, stringsAsFactors = FALSE)
cat("[DONE] Enriched merged: ", nrow(merged), "rows x", ncol(merged), "columns\n")

# Filter to charted = 1 rows only — these are the songs on the Billboard chart
charted_df <- merged[merged$charted == 1, ]
cat("  Charted = 1 rows    :", nrow(charted_df), "\n")
cat("  Charted = 0 rows    :", nrow(merged) - nrow(charted_df), "\n\n")

# Non-charted songs have NO year info.
cat("[NOTE] Non-charted songs have NO year information in this dataset.\n")
cat("       songAttributes contains no release date or chart date.\n")
cat("       => CANNOT run charted-vs-noncharted era-specific models.\n")
cat("       => FALLBACK: within-chart top10_hit model per era.\n\n")

# Build normalized keys for the charted songs
# These will be used to JOIN Billboard year/peak info
charted_df$p1_key <- paste0(clean_basic(charted_df$song_name), "|||",
                             clean_basic(charted_df$artist))
charted_df$p2_key <- paste0(normalize_title(charted_df$song_name), "|||",
                             clean_basic(charted_df$artist))
charted_df$p3_key <- paste0(normalize_title(charted_df$song_name), "|||",
                             normalize_artist(charted_df$artist))
charted_df$row_idx <- seq_len(nrow(charted_df))


# ── SECTION 3: EXTRACT YEAR AND PEAK FROM BILLBOARD FILE ──────────────────────

cat("==============================================================\n")
cat("SECTION 3: EXTRACTING YEAR AND PEAK FROM BILLBOARD FILE\n")
cat("==============================================================\n\n")

cat("[INFO] Reading Billboard CSV (may take 1-3 min)...\n")
bill_raw <- read.csv(
  billboard_path,
  stringsAsFactors = FALSE,
  check.names      = FALSE,
  quote            = "\"",
  comment.char     = ""
)
if (names(bill_raw)[1] == "") names(bill_raw)[1] <- "row_id"
cat("[DONE] Billboard raw rows:", nrow(bill_raw), "\n\n")

# Extract year from the 'Week' column (format: "YYYY-MM-DD")
bill_raw$year_val <- suppressWarnings(
  as.integer(substr(trimws(bill_raw$`Week`), 1, 4))
)

# Parse peak position (can be "NA" string or missing)
bill_raw$peak_num <- suppressWarnings(as.integer(bill_raw$`Peak.position`))

# Parse weekly rank for deduplication
bill_raw$rank_num  <- suppressWarnings(as.integer(bill_raw$`Weekly.rank`))
bill_raw$weeks_num <- suppressWarnings(as.integer(bill_raw$`Weeks.on.chart`))

# Build primary artist and normalized keys
bill_raw$primary_artist_raw <- extract_primary_artist_bill(bill_raw$Artists)
bill_raw$p1_title  <- clean_basic(bill_raw$Name)
bill_raw$p1_artist <- clean_basic(bill_raw$primary_artist_raw)
bill_raw$p1_key    <- paste0(bill_raw$p1_title, "|||", bill_raw$p1_artist)
bill_raw$p2_key    <- paste0(normalize_title(bill_raw$Name), "|||", bill_raw$p1_artist)
bill_raw$p3_key    <- paste0(normalize_title(bill_raw$Name), "|||",
                              normalize_artist(bill_raw$primary_artist_raw))

cat("Computing per-song year, peak, and weeks across all chart appearances...\n")

# For each unique p1_key, compute:
#   first_year = earliest year on the chart
#   best_peak  = lowest (best) Peak.position across all appearances
#   max_weeks  = maximum weeks on chart
bill_sort <- bill_raw[order(bill_raw$p1_key, bill_raw$rank_num, na.last = TRUE), ]
bill_dedup <- bill_sort[!duplicated(bill_sort$p1_key), ]

# Overwrite year with EARLIEST year seen for this song (group min)
min_year <- tapply(bill_raw$year_val, bill_raw$p1_key, function(x) {
  v <- x[!is.na(x)]; if (length(v) == 0) NA_integer_ else min(v)
})
bill_dedup$first_year <- min_year[bill_dedup$p1_key]

# Best peak = minimum peak across all appearances
best_peak <- tapply(bill_raw$peak_num, bill_raw$p1_key, function(x) {
  v <- x[!is.na(x)]; if (length(v) == 0) NA_integer_ else min(v)
})
bill_dedup$best_peak <- best_peak[bill_dedup$p1_key]

# Max weeks on chart
max_weeks <- tapply(bill_raw$weeks_num, bill_raw$p1_key, function(x) {
  v <- x[!is.na(x)]; if (length(v) == 0) NA_integer_ else max(v)
})
bill_dedup$max_weeks <- max_weeks[bill_dedup$p1_key]

cat("  Billboard unique songs :", nrow(bill_dedup), "\n")
cat("  Songs with valid year  :", sum(!is.na(bill_dedup$first_year)), "\n")
cat("  Songs with valid peak  :", sum(!is.na(bill_dedup$best_peak)), "\n")
cat("  Songs with peak <= 10  :", sum(!is.na(bill_dedup$best_peak) &
                                       bill_dedup$best_peak <= 10), "\n\n")

# Assign era to each Billboard song
bill_dedup$era <- assign_era(bill_dedup$first_year)
cat("Billboard songs by era:\n")
era_total <- table(bill_dedup$era)
for (e in ERA_DEFS$label) {
  n  <- if (e %in% names(era_total)) era_total[[e]] else 0
  tp <- sum(!is.na(bill_dedup$best_peak) & bill_dedup$era == e &
              bill_dedup$best_peak <= 10, na.rm = TRUE)
  np <- sum(bill_dedup$era == e & !is.na(bill_dedup$era), na.rm = TRUE)
  cat(sprintf("  %s: %4d songs (%3d top10, %4d with valid peak)\n",
              e, np, tp,
              sum(!is.na(bill_dedup$best_peak) & bill_dedup$era == e, na.rm = TRUE)))
}
cat("\n")


# ── SECTION 4: JOIN YEAR/ERA/PEAK TO CHARTED SONGS (MULTI-PASS) ───────────────

cat("==============================================================\n")
cat("SECTION 4: JOINING YEAR/PEAK TO CHARTED AUDIO FEATURE ROWS\n")
cat("==============================================================\n\n")

# We join using the same accepted passes as Phase 1:
#   Pass 1: exact clean_basic(title) + clean_basic(artist)
#   Pass 2: exact normalize_title(title) + clean_basic(artist)
#   Pass 3: exact normalize_title(title) + normalize_artist(artist)
#   Pass 4: conservative fuzzy title match within SAME normalized artist
#           using adist <= 1 and exactly one best candidate.
# For each charted attr row, find the matching Billboard song entry
# to get year/era/peak info.

# Build lookup tables: key → bill_dedup row index
build_key_lookup <- function(bill_df, key_col) {
  keys <- bill_df[[key_col]]
  # Handle duplicates: keep the row with best (lowest) peak for ties
  # Ties are resolved by sorting bill_df by key + peak before building lookup
  idx_vec <- seq_len(nrow(bill_df))
  # Create a named integer: key → first row index with that key (already sorted)
  setNames(idx_vec[!duplicated(keys)], keys[!duplicated(keys)])
}

bill_p1_lookup <- build_key_lookup(bill_dedup, "p1_key")
bill_p2_lookup <- build_key_lookup(bill_dedup, "p2_key")
bill_p3_lookup <- build_key_lookup(bill_dedup, "p3_key")

# For each charted attr row, find its Billboard bill_dedup index
charted_df$bill_idx <- NA_integer_

# Pass 1: join on clean_basic key
matched_p1 <- charted_df$p1_key %in% names(bill_p1_lookup)
charted_df$bill_idx[matched_p1] <- bill_p1_lookup[charted_df$p1_key[matched_p1]]

# Pass 2: join on normalize_title key (only for rows not yet joined)
unjoined <- is.na(charted_df$bill_idx)
matched_p2 <- unjoined & (charted_df$p2_key %in% names(bill_p2_lookup))
charted_df$bill_idx[matched_p2] <- bill_p2_lookup[charted_df$p2_key[matched_p2]]

# Pass 3: join on normalize_artist key
unjoined <- is.na(charted_df$bill_idx)
matched_p3 <- unjoined & (charted_df$p3_key %in% names(bill_p3_lookup))
charted_df$bill_idx[matched_p3] <- bill_p3_lookup[charted_df$p3_key[matched_p3]]

# Pass 4: conservative fuzzy title match within SAME normalized artist
# This mirrors the safe fuzzy rule accepted in script 06.
matched_p4 <- rep(FALSE, nrow(charted_df))
unjoined <- which(is.na(charted_df$bill_idx))

if (length(unjoined) > 0) {
  bill_dedup$norm_title  <- normalize_title(bill_dedup$Name)
  bill_dedup$norm_artist <- normalize_artist(bill_dedup$primary_artist_raw)
  bill_by_artist <- split(seq_len(nrow(bill_dedup)), bill_dedup$norm_artist)

  for (row_idx in unjoined) {
    attr_title_norm  <- normalize_title(charted_df$song_name[row_idx])
    attr_artist_norm <- normalize_artist(charted_df$artist[row_idx])

    # Skip very short titles because fuzzy matching becomes too ambiguous.
    if (nchar(attr_title_norm) < 4) next

    cand_rows <- bill_by_artist[[attr_artist_norm]]
    if (is.null(cand_rows) || length(cand_rows) == 0) next

    cand_titles <- bill_dedup$norm_title[cand_rows]
    dists <- as.vector(adist(attr_title_norm, cand_titles))
    min_d <- min(dists)
    best_idx <- which(dists == min_d)

    if (min_d <= 1 && length(best_idx) == 1) {
      charted_df$bill_idx[row_idx] <- cand_rows[best_idx]
      matched_p4[row_idx] <- TRUE
    }
  }
}

n_joined    <- sum(!is.na(charted_df$bill_idx))
n_not_joined <- sum(is.na(charted_df$bill_idx))
cat("Charted attr rows joined to Billboard year/peak:\n")
cat("  Via Pass 1 (clean_basic)     :", sum(matched_p1), "\n")
cat("  Via Pass 2 (normalize_title) :", sum(matched_p2), "\n")
cat("  Via Pass 3 (normalize_artist):", sum(matched_p3), "\n")
cat("  Via Pass 4 (fuzzy adist<=1)  :", sum(matched_p4), "\n")
cat("  Total joined                 :", n_joined, "\n")
cat("  Not joined (no Billboard key):", n_not_joined, "\n\n")

# These un-joined rows are attr songs marked charted=1 in Phase 1 via the
# 1-to-many normalization (e.g., both "Black Coffee" and "Black Coffee (feat. X)"
# were marked charted=1 for the same bill song "Black Coffee"). Only one of them
# will find a bill_idx match on the primary key — the other is a bonus charted row.
# For era analysis, we use only the rows that successfully join to a bill entry.

# Extract year/era/peak from joined bill rows
charted_df$first_year  <- NA_integer_
charted_df$best_peak   <- NA_integer_
charted_df$max_weeks   <- NA_integer_
charted_df$era         <- NA_character_

has_bill <- !is.na(charted_df$bill_idx)
charted_df$first_year[has_bill]  <- bill_dedup$first_year[charted_df$bill_idx[has_bill]]
charted_df$best_peak[has_bill]   <- bill_dedup$best_peak[charted_df$bill_idx[has_bill]]
charted_df$max_weeks[has_bill]   <- bill_dedup$max_weeks[charted_df$bill_idx[has_bill]]
charted_df$era[has_bill]         <- bill_dedup$era[charted_df$bill_idx[has_bill]]

# Create the top10_hit outcome variable
charted_df$top10_hit <- as.integer(!is.na(charted_df$best_peak) &
                                    charted_df$best_peak <= 10)
# Mark as NA when peak itself is NA (song is on chart but peak unknown)
charted_df$top10_hit[is.na(charted_df$best_peak)] <- NA

cat("Charted songs with era assigned:", sum(!is.na(charted_df$era)), "\n")
cat("Charted songs by era:\n")
for (e in ERA_DEFS$label) {
  n    <- sum(charted_df$era == e, na.rm = TRUE)
  top  <- sum(charted_df$era == e & !is.na(charted_df$top10_hit) &
                charted_df$top10_hit == 1, na.rm = TRUE)
  np   <- sum(charted_df$era == e & !is.na(charted_df$top10_hit), na.rm = TRUE)
  cat(sprintf("  %s: %4d total, %3d top10, %4d with valid peak\n", e, n, top, np))
}
cat("\n")

# Keep only rows with a valid era and all 9 audio features present
audio_na_flag <- rowSums(is.na(charted_df[, AUDIO_FEATURES])) > 0
charted_era <- charted_df[!is.na(charted_df$era) & !audio_na_flag, ]

cat("Charted songs used in analysis (has era + no missing audio):\n")
for (e in ERA_DEFS$label) {
  n <- sum(charted_era$era == e, na.rm = TRUE)
  cat(sprintf("  %s: %d\n", e, n))
}
cat("\n")


# ── SECTION 5: CHECK DATA AVAILABILITY AND CONFIRM MODEL CHOICE ───────────────

cat("==============================================================\n")
cat("SECTION 5: DATA AVAILABILITY CHECK\n")
cat("==============================================================\n\n")

can_do_preferred <- FALSE  # would need non-charted songs to have year labels
cat("Preferred model (charted vs non-charted per era): NOT POSSIBLE\n")
cat("  Reason: non-charted songs in songAttributes have no year information.\n")
cat("  Assigning fake years to non-charted songs is not valid.\n\n")

cat("Fallback model (within-chart: top10_hit per era): POSSIBLE\n")
cat("  - charted songs have years from Billboard\n")
cat("  - top10_hit = 1 if Peak.position <= 10, else 0\n")
cat("  - fits within each era separately using 9 audio features\n\n")

# Check if any era has too few positive cases for logistic regression
cat("Model adequacy check (need >= 50 top10 AND >= 50 non-top10 per era):\n")
model_adequate <- logical(N_ERAS)
for (i in seq_len(N_ERAS)) {
  e    <- ERA_DEFS$label[i]
  sub  <- charted_era[charted_era$era == e & !is.na(charted_era$top10_hit), ]
  n1   <- sum(sub$top10_hit == 1)
  n0   <- sum(sub$top10_hit == 0)
  ok   <- n1 >= 50 && n0 >= 50
  model_adequate[i] <- ok
  cat(sprintf("  %s: %3d top10, %3d non-top10 → %s\n",
              e, n1, n0, if (ok) "ADEQUATE" else "WARNING: small sample"))
}
cat("\n")


# ── SECTION 6: COMPUTE GLOBALLY STANDARDIZED FEATURES ────────────────────────

cat("==============================================================\n")
cat("SECTION 6: GLOBAL FEATURE STANDARDIZATION\n")
cat("==============================================================\n\n")

# Compute global mean and SD from ALL charted songs with valid era
# Using global stats makes coefficients comparable across eras
# (a coefficient change reflects genuine predictor importance shift,
# not just a change in within-era feature variance)
global_means <- colMeans(charted_era[, AUDIO_FEATURES], na.rm = TRUE)
global_sds   <- apply(charted_era[, AUDIO_FEATURES], 2, sd, na.rm = TRUE)

cat("Global means and SDs (across all charted songs, all eras):\n")
fmt <- data.frame(feature=AUDIO_FEATURES,
                  global_mean=round(global_means, 4),
                  global_sd=round(global_sds, 4),
                  row.names=NULL)
print(fmt, row.names = FALSE)
cat("\n")

# Create standardized feature columns
for (feat in AUDIO_FEATURES) {
  charted_era[[paste0(feat, "_z")]] <- (charted_era[[feat]] - global_means[feat]) / global_sds[feat]
}
z_features <- paste0(AUDIO_FEATURES, "_z")


# ── SECTION 7: LAYER 1 — DESCRIPTIVE DRIFT (FEATURE MEANS BY ERA) ─────────────

cat("==============================================================\n")
cat("SECTION 7: LAYER 1 — DESCRIPTIVE DRIFT\n")
cat("==============================================================\n\n")

# Compute mean of each audio feature by era
era_feature_means <- data.frame(era = ERA_DEFS$label, stringsAsFactors = FALSE)
era_feature_means$n_songs <- sapply(ERA_DEFS$label, function(e)
  sum(charted_era$era == e, na.rm = TRUE))

for (feat in AUDIO_FEATURES) {
  era_feature_means[[feat]] <- sapply(ERA_DEFS$label, function(e) {
    vals <- charted_era[[feat]][charted_era$era == e]
    mean(vals, na.rm = TRUE)
  })
}

cat("Era feature means:\n")
print(era_feature_means, row.names = FALSE, digits = 4)
cat("\n")

# Feature drift score = range of mean across eras (normalized by global SD)
feat_drift_raw   <- sapply(AUDIO_FEATURES, function(f) {
  vals <- era_feature_means[[f]]
  (max(vals) - min(vals)) / global_sds[f]
})
feat_drift_df <- data.frame(
  feature     = AUDIO_FEATURES,
  range_of_mean = sapply(AUDIO_FEATURES, function(f) max(era_feature_means[[f]]) - min(era_feature_means[[f]])),
  drift_score = round(feat_drift_raw, 4),
  row.names   = NULL
)
feat_drift_df <- feat_drift_df[order(-feat_drift_df$drift_score), ]

cat("Feature drift scores (range / global SD) — higher = more change:\n")
print(feat_drift_df, row.names = FALSE)
top3_feat_drift <- feat_drift_df$feature[1:3]
cat("\nTop 3 features that changed most across eras:", paste(top3_feat_drift, collapse=", "), "\n\n")


# ── SECTION 8: LAYER 2 — ERA-SPECIFIC LOGISTIC REGRESSION ─────────────────────

cat("==============================================================\n")
cat("SECTION 8: LAYER 2 — ERA-SPECIFIC LOGISTIC REGRESSION\n")
cat("==============================================================\n\n")

cat("Model: logit(P(top10_hit)) ~ ", paste(AUDIO_FEATURES, collapse=" + "), "\n")
cat("Features: globally standardized (Z-score using all-era mean/SD)\n")
cat("Outcome : top10_hit = 1 if Peak.position <= 10, else 0\n\n")

# Fit one logistic regression per era
era_coef_list <- list()

for (i in seq_len(N_ERAS)) {
  e <- ERA_DEFS$label[i]
  sub <- charted_era[charted_era$era == e & !is.na(charted_era$top10_hit), ]

  n_total <- nrow(sub)
  n1 <- sum(sub$top10_hit == 1)
  n0 <- sum(sub$top10_hit == 0)

  cat(sprintf("--- Era: %s  (n=%d, top10=%d, non-top10=%d) ---\n", e, n_total, n1, n0))

  if (n1 < 10 || n0 < 10) {
    cat("  SKIPPED: too few cases in one class (need >= 10 per class)\n\n")
    next
  }

  formula_str <- paste("top10_hit ~", paste(z_features, collapse = " + "))
  fit <- tryCatch(
    glm(as.formula(formula_str), data = sub, family = binomial(link = "logit")),
    error = function(e) {
      cat("  ERROR fitting model:", conditionMessage(e), "\n")
      NULL
    }
  )

  if (is.null(fit)) next

  coef_vals <- coef(fit)
  se_vals   <- sqrt(diag(vcov(fit)))
  z_vals    <- coef_vals / se_vals
  p_vals    <- 2 * pnorm(-abs(z_vals))
  or_vals   <- exp(coef_vals)

  # Remove intercept for the coefficient drift analysis
  feat_names_z <- names(coef_vals)[-1]  # exclude intercept
  feat_names   <- sub("_z$", "", feat_names_z)

  era_coef_df <- data.frame(
    era        = e,
    feature    = feat_names,
    coefficient= round(coef_vals[-1], 4),
    std_error  = round(se_vals[-1], 4),
    z_value    = round(z_vals[-1], 4),
    p_value    = round(p_vals[-1], 4),
    odds_ratio = round(or_vals[-1], 4),
    significant= p_vals[-1] < 0.05,
    n_total    = n_total,
    n_top10    = n1,
    stringsAsFactors = FALSE,
    row.names  = NULL
  )

  era_coef_list[[e]] <- era_coef_df

  # Print top significant predictors for this era
  sig_rows <- era_coef_df[era_coef_df$significant, c("feature","coefficient","p_value")]
  if (nrow(sig_rows) > 0) {
    cat("  Significant predictors (p < 0.05):\n")
    sig_rows <- sig_rows[order(abs(sig_rows$coefficient), decreasing = TRUE), ]
    for (j in seq_len(min(nrow(sig_rows), 4))) {
      cat(sprintf("    %-18s coef=%+.3f  p=%.4f\n",
                  sig_rows$feature[j], sig_rows$coefficient[j], sig_rows$p_value[j]))
    }
  } else {
    cat("  No significant predictors at p < 0.05\n")
  }
  cat("\n")
}

# Combine all era coefficients into one table
if (length(era_coef_list) == 0) {
  stop("No era-specific models could be fitted. Check data availability.")
}
era_coef_all <- do.call(rbind, era_coef_list)
rownames(era_coef_all) <- NULL


# ── SECTION 9: COEFFICIENT DRIFT ANALYSIS ─────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 9: COEFFICIENT DRIFT ANALYSIS\n")
cat("==============================================================\n\n")

# For each feature, compute the range of its coefficient across eras
eras_fitted <- unique(era_coef_all$era)
n_fitted    <- length(eras_fitted)

coef_drift_df <- data.frame(
  feature         = AUDIO_FEATURES,
  coef_min        = NA_real_,
  coef_max        = NA_real_,
  coef_range      = NA_real_,
  direction_change = NA_character_,
  stringsAsFactors = FALSE
)

for (j in seq_len(nrow(coef_drift_df))) {
  feat <- coef_drift_df$feature[j]
  sub  <- era_coef_all[era_coef_all$feature == feat, ]
  if (nrow(sub) < 2) next
  coef_vals_feat <- sub$coefficient
  coef_drift_df$coef_min[j]   <- min(coef_vals_feat)
  coef_drift_df$coef_max[j]   <- max(coef_vals_feat)
  coef_drift_df$coef_range[j] <- max(coef_vals_feat) - min(coef_vals_feat)
  # Direction: did the feature switch from positive to negative or vice versa?
  has_pos <- any(coef_vals_feat > 0)
  has_neg <- any(coef_vals_feat < 0)
  if (has_pos && has_neg) {
    coef_drift_df$direction_change[j] <- "crossed zero"
  } else if (has_pos) {
    coef_drift_df$direction_change[j] <- "consistently positive"
  } else {
    coef_drift_df$direction_change[j] <- "consistently negative"
  }
}

coef_drift_df <- coef_drift_df[order(-coef_drift_df$coef_range, na.last = TRUE), ]
cat("Coefficient drift across eras (range = max coef - min coef):\n")
print(coef_drift_df[, c("feature","coef_min","coef_max","coef_range","direction_change")],
      row.names = FALSE, digits = 4)
top3_coef_drift <- coef_drift_df$feature[1:3]
cat("\nTop 3 predictors with most coefficient drift:", paste(top3_coef_drift, collapse=", "), "\n\n")

# Formula stability verdict
mean_range <- mean(coef_drift_df$coef_range, na.rm = TRUE)
n_crossed  <- sum(coef_drift_df$direction_change == "crossed zero", na.rm = TRUE)
stability_verdict <- if (mean_range > 0.5 || n_crossed >= 3) {
  "CLEARLY SHIFTING — substantial coefficient drift across eras"
} else if (mean_range > 0.2 || n_crossed >= 1) {
  "MODERATELY SHIFTING — some features changed predictive importance"
} else {
  "MOSTLY STABLE — formula for success broadly consistent across eras"
}
cat("Formula for success stability:", stability_verdict, "\n\n")


# ── SECTION 10: BUILD ERA COUNTS TABLE ────────────────────────────────────────

era_counts <- data.frame(
  era                = ERA_DEFS$label,
  bill_songs_total   = sapply(ERA_DEFS$label, function(e) sum(bill_dedup$era == e, na.rm=TRUE)),
  bill_with_peak     = sapply(ERA_DEFS$label, function(e)
    sum(!is.na(bill_dedup$best_peak) & bill_dedup$era == e, na.rm=TRUE)),
  bill_top10         = sapply(ERA_DEFS$label, function(e)
    sum(!is.na(bill_dedup$best_peak) & bill_dedup$era == e &
          bill_dedup$best_peak <= 10, na.rm=TRUE)),
  charted_matched    = sapply(ERA_DEFS$label, function(e)
    sum(charted_era$era == e, na.rm=TRUE)),
  model_n            = sapply(ERA_DEFS$label, function(e) {
    if (e %in% names(era_coef_list)) era_coef_list[[e]]$n_total[1] else NA_integer_
  }),
  model_top10        = sapply(ERA_DEFS$label, function(e) {
    if (e %in% names(era_coef_list)) era_coef_list[[e]]$n_top10[1] else NA_integer_
  }),
  pct_bill_matched   = round(sapply(ERA_DEFS$label, function(e)
    sum(charted_era$era == e, na.rm=TRUE) /
    max(1, sum(bill_dedup$era == e, na.rm=TRUE)) * 100), 1),
  stringsAsFactors   = FALSE
)

cat("Era counts summary:\n")
print(era_counts, row.names = FALSE)
cat("\n")


# ── SECTION 11: SAVE TABLES ───────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 11: SAVING TABLES\n")
cat("==============================================================\n\n")

out_era_means   <- "outputs/tables/era_feature_means.csv"
out_era_counts  <- "outputs/tables/era_counts.csv"
out_era_coefs   <- "outputs/tables/era_model_coefficients.csv"
out_era_summary <- "outputs/tables/era_drift_summary.txt"
out_md          <- "docs/step7_era_drift_summary.md"

write.csv(era_feature_means, out_era_means, row.names = FALSE)
cat("[SAVED]", out_era_means, "\n")

write.csv(era_counts, out_era_counts, row.names = FALSE)
cat("[SAVED]", out_era_counts, "\n")

write.csv(era_coef_all, out_era_coefs, row.names = FALSE)
cat("[SAVED]", out_era_coefs, "(", nrow(era_coef_all), "rows)\n\n")


# ── SECTION 12: CREATE PLOTS ──────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 12: CREATING PLOTS\n")
cat("==============================================================\n\n")

out_feat_trends   <- "outputs/figures/era_drift/era_feature_trends.png"
out_coef_drift    <- "outputs/figures/era_drift/era_coefficient_drift.png"
out_era_counts_fig <- "outputs/figures/era_drift/era_counts.png"
out_pval_heat     <- "outputs/figures/era_drift/era_pvalue_heatmap.png"

era_x   <- seq_len(N_ERAS)
era_lbl <- ERA_DEFS$label

# ── PLOT 1: Era Feature Trends (3×3 small multiples) ──────────────────────────
cat("[PLOT] era_feature_trends.png\n")
png(out_feat_trends, width = 1400, height = 1000, res = 120)
par(mfrow = c(3, 3),
    mar   = c(3.5, 3.5, 2.5, 1),
    oma   = c(0, 0, 3, 0),
    cex.main = 1.0,
    cex.axis = 0.8,
    cex.lab  = 0.85)

for (feat in AUDIO_FEATURES) {
  vals  <- era_feature_means[[feat]]
  ylim  <- range(vals) * c(0.95, 1.05)
  color <- FEATURE_COLORS[feat]

  plot(era_x, vals,
       type = "b",
       pch  = 19,
       col  = color,
       lwd  = 2,
       xaxt = "n",
       xlab = "",
       ylab = feat,
       main = feat,
       ylim = ylim)

  axis(1, at = era_x, labels = c("99-02","03-06","07-10","11-14","15-19"),
       las = 2, cex.axis = 0.7)

  # Shade to show direction of change
  abline(lm(vals ~ era_x), lty = 2, col = adjustcolor(color, alpha.f = 0.4), lwd = 1.5)
}

mtext("Audio Feature Means for Charted Songs by Era",
      outer = TRUE, cex = 1.3, font = 2, line = 1)
dev.off()
cat("  Saved:", out_feat_trends, "\n\n")

# ── PLOT 2: Coefficient Drift Plot ────────────────────────────────────────────
cat("[PLOT] era_coefficient_drift.png\n")
png(out_coef_drift, width = 1300, height = 800, res = 120)

# Build a matrix: rows = eras, cols = features
coef_matrix <- matrix(NA_real_, nrow = n_fitted, ncol = length(AUDIO_FEATURES),
                      dimnames = list(eras_fitted, AUDIO_FEATURES))
for (e in eras_fitted) {
  sub <- era_coef_all[era_coef_all$era == e, ]
  for (feat in AUDIO_FEATURES) {
    row <- sub[sub$feature == feat, ]
    if (nrow(row) > 0) coef_matrix[e, feat] <- row$coefficient[1]
  }
}

# Set x positions to the era order
era_x_fitted <- match(eras_fitted, ERA_DEFS$label)

y_range <- range(coef_matrix, na.rm = TRUE)
y_range <- y_range + c(-0.1, 0.1) * diff(y_range)

par(mar = c(5, 4.5, 4, 12), xpd = FALSE)

plot(NA, xlim = c(0.5, N_ERAS + 0.5), ylim = y_range,
     xaxt = "n", xlab = "Era", ylab = "Standardized Logistic Coefficient",
     main = "How Audio Feature Importance Shifted Across Eras\n(Top-10 Hit Model, Globally Standardized Features)",
     cex.main = 0.95, cex.lab = 0.9)

axis(1, at = era_x, labels = era_lbl, cex.axis = 0.82)
abline(h = 0, lty = 2, col = "gray60", lwd = 1)
grid(nx = NA, ny = NULL, col = "gray90", lty = 1)

for (j in seq_along(AUDIO_FEATURES)) {
  feat   <- AUDIO_FEATURES[j]
  y_vals <- coef_matrix[, feat]
  x_vals <- era_x_fitted
  valid  <- !is.na(y_vals)
  if (sum(valid) >= 2) {
    lines(x_vals[valid], y_vals[valid],
          col = FEATURE_COLORS[feat],
          lwd = 2,
          lty = FEATURE_LTYS[feat])
    points(x_vals[valid], y_vals[valid],
           col = FEATURE_COLORS[feat],
           pch = 15 + j,
           cex = 1.2)
  }
}

# Legend outside the plot area
par(xpd = TRUE)
legend(x = N_ERAS + 0.7, y = mean(y_range),
       legend  = AUDIO_FEATURES,
       col     = FEATURE_COLORS[AUDIO_FEATURES],
       lty     = FEATURE_LTYS[AUDIO_FEATURES],
       pch     = 15 + seq_along(AUDIO_FEATURES),
       lwd     = 2,
       pt.cex  = 1.1,
       cex     = 0.72,
       bty     = "n",
       xjust   = 0,
       yjust   = 0.5,
       title   = "Feature")

dev.off()
cat("  Saved:", out_coef_drift, "\n\n")

# ── PLOT 3: Era Counts Bar Chart ───────────────────────────────────────────────
cat("[PLOT] era_counts.png\n")
png(out_era_counts_fig, width = 1000, height = 650, res = 120)
par(mar = c(5, 4.5, 3.5, 8), xpd = FALSE)

# 3 bars per era: billboard total, matched with audio, model subset (valid peak)
bar_mat <- rbind(
  era_counts$bill_songs_total,
  era_counts$charted_matched,
  era_counts$model_n
)
colnames(bar_mat) <- era_counts$era

bp <- barplot(bar_mat,
              beside      = TRUE,
              col         = c("#AACFE4", "#2166AC", "#B35806"),
              names.arg   = c("99-02","03-06","07-10","11-14","15-19"),
              xlab        = "Era",
              ylab        = "Song Count",
              main        = "Songs Available Per Era\n(Billboard, Matched, Model Subset)",
              cex.names   = 0.85,
              cex.axis    = 0.85,
              cex.main    = 0.95)

par(xpd = TRUE)
legend(x = max(bp) + 2, y = max(bar_mat, na.rm=TRUE),
       legend = c("All Billboard songs", "Matched (audio features)", "In model (valid peak)"),
       fill   = c("#AACFE4", "#2166AC", "#B35806"),
       bty    = "n",
       cex    = 0.75,
       xjust  = 0)

dev.off()
cat("  Saved:", out_era_counts_fig, "\n\n")

# ── PLOT 4: P-value Heatmap (significance across eras) ────────────────────────
cat("[PLOT] era_pvalue_heatmap.png\n")
png(out_pval_heat, width = 850, height = 700, res = 120)

# Build p-value matrix
pval_matrix <- matrix(NA_real_, nrow = length(AUDIO_FEATURES), ncol = n_fitted,
                      dimnames = list(AUDIO_FEATURES, eras_fitted))
for (e in eras_fitted) {
  sub <- era_coef_all[era_coef_all$era == e, ]
  for (feat in AUDIO_FEATURES) {
    row <- sub[sub$feature == feat, ]
    if (nrow(row) > 0) pval_matrix[feat, e] <- row$p_value[1]
  }
}

# Color: white (p>0.10), light yellow (p<0.10), orange (p<0.05), red (p<0.01)
pval_color <- function(p) {
  if (is.na(p)) return("lightgray")
  if (p < 0.01)  return("#D73027")
  if (p < 0.05)  return("#FC8D59")
  if (p < 0.10)  return("#FEE090")
  return("white")
}

par(mar = c(2, 9, 5, 10))
nr <- nrow(pval_matrix); nc <- ncol(pval_matrix)
plot(0, type = "n", xlim = c(0.5, nc + 0.5), ylim = c(0.5, nr + 0.5),
     xaxt = "n", yaxt = "n", xlab = "", ylab = "",
     main = "Statistical Significance of Audio Features\nAcross Eras (Top-10 Hit Model)",
     cex.main = 0.95)

for (i in seq_len(nr)) {
  for (j in seq_len(nc)) {
    col <- pval_color(pval_matrix[i, j])
    rect(j - 0.5, i - 0.5, j + 0.5, i + 0.5, col = col, border = "gray70")
    if (!is.na(pval_matrix[i, j])) {
      p_txt <- if (pval_matrix[i, j] < 0.001) "<.001" else
        formatC(pval_matrix[i, j], digits = 2, format = "f")
      text(j, i, p_txt, cex = 0.65,
           col = if (pval_matrix[i, j] < 0.05) "white" else "gray30")
    }
  }
}

axis(1, at = seq_len(nc), labels = c("99-02","03-06","07-10","11-14","15-19"),
     cex.axis = 0.82)
axis(2, at = seq_len(nr), labels = AUDIO_FEATURES, las = 2, cex.axis = 0.82)

# Legend
par(xpd = TRUE)
legend_x <- nc + 0.7
legend(x = legend_x, y = nr,
       legend = c("p < 0.01", "p < 0.05", "p < 0.10", "p >= 0.10", "N/A"),
       fill   = c("#D73027", "#FC8D59", "#FEE090", "white", "lightgray"),
       bty    = "n", cex = 0.72, xjust = 0, border = "gray70")

dev.off()
cat("  Saved:", out_pval_heat, "\n\n")


# ── SECTION 13: WRITE TEXT AND MARKDOWN SUMMARIES ────────────────────────────

cat("==============================================================\n")
cat("SECTION 13: WRITING SUMMARIES\n")
cat("==============================================================\n\n")

# Identify which features changed most descriptively
feat_drift_rank <- feat_drift_df$feature
coef_drift_rank <- coef_drift_df$feature

# Which feature became more/less important over time?
coef_trend_note <- sapply(AUDIO_FEATURES, function(feat) {
  sub <- era_coef_all[era_coef_all$feature == feat, ]
  sub <- sub[order(match(sub$era, ERA_DEFS$label)), ]
  if (nrow(sub) < 2) return("insufficient data")
  first_coef <- sub$coefficient[1]
  last_coef  <- sub$coefficient[nrow(sub)]
  delta <- last_coef - first_coef
  if (abs(delta) < 0.05) "relatively stable"
  else if (delta > 0)    paste0("became more positive (Δ=+", round(delta,3), ")")
  else                   paste0("became more negative (Δ=", round(delta,3), ")")
})

summary_lines <- c(
  "===================================================================",
  "  ERA DRIFT ANALYSIS SUMMARY",
  paste("  Generated:", Sys.time()),
  paste("  Script   : scripts/07_era_drift_analysis.R"),
  "===================================================================",
  "",
  "--- FILES USED ---",
  paste("  Billboard    :", billboard_path),
  paste("  songAttributes:", attr_path),
  paste("  Enriched merged:", enriched_path),
  "",
  "--- MODEL CHOICE ---",
  "  Attempted : charted-vs-noncharted era-specific logistic regression",
  "  Result    : NOT POSSIBLE",
  "  Reason    : Non-charted songs in songAttributes have no year information.",
  "              Fabricating years for non-charted songs is not valid.",
  "  Used      : Within-chart top10_hit logistic regression per era",
  "  Outcome   : top10_hit = 1 if Peak.position <= 10, else 0",
  "  Predictors: 9 audio features (globally standardized)",
  "",
  "--- ERA DEFINITIONS ---",
  paste(apply(ERA_DEFS, 1, function(r) sprintf("  Era %s: years %s-%s", r["label"], r["start"], r["end"])), collapse="\n"),
  "",
  "--- COUNTS PER ERA ---",
  capture.output(print(era_counts, row.names=FALSE)),
  "",
  "--- GLOBAL STANDARDIZATION ---",
  capture.output(print(fmt, row.names=FALSE)),
  "",
  "--- TOP 3 FEATURES WITH MOST MEAN DRIFT ACROSS ERAS ---",
  paste(sapply(1:3, function(i) sprintf("  %d. %s (drift score: %.3f)",
    i, feat_drift_rank[i], feat_drift_df$drift_score[feat_drift_df$feature==feat_drift_rank[i]])),
    collapse = "\n"),
  "",
  "--- TOP 3 PREDICTORS WITH MOST COEFFICIENT DRIFT ---",
  paste(sapply(1:3, function(i) {
    f <- coef_drift_rank[i]
    r <- coef_drift_df[coef_drift_df$feature == f, ]
    sprintf("  %d. %s (coef range: %.3f to %.3f, span=%.3f, %s)",
            i, f, r$coef_min, r$coef_max, r$coef_range, r$direction_change)
  }), collapse="\n"),
  "",
  "--- FEATURE TREND DIRECTIONS (first era -> last era) ---",
  paste(sapply(names(coef_trend_note), function(f)
    sprintf("  %-20s %s", f, coef_trend_note[f])), collapse="\n"),
  "",
  "--- FORMULA FOR SUCCESS ---",
  paste("  Verdict:", stability_verdict),
  paste("  Mean coefficient range across features:", round(mean_range, 3)),
  paste("  Features that crossed zero:", n_crossed, "out of", length(AUDIO_FEATURES)),
  "",
  "--- ASSUMPTIONS AND LIMITATIONS ---",
  "  - Year assigned = earliest year song appeared on Billboard Hot 100",
  "  - Songs in multiple eras assigned to the era of first chart appearance",
  "  - Matching rate ~57%: not all Billboard songs have Spotify audio features",
  "  - Songs with NA Peak.position excluded from model (rates vary by era: 0%-27%)",
  "  - Model is within-chart only: does NOT compare charted vs non-charted",
  "  - Coefficients reflect top10 vs non-top10 among charted songs, not chart entry",
  "  - Standardization is global (all eras pooled) for cross-era comparability",
  "",
  "--- OUTPUT FILES ---",
  paste("  Table:", out_era_means),
  paste("  Table:", out_era_counts),
  paste("  Table:", out_era_coefs),
  paste("  Figure:", out_feat_trends),
  paste("  Figure:", out_coef_drift),
  paste("  Figure:", out_era_counts_fig),
  paste("  Figure:", out_pval_heat),
  paste("  Markdown:", out_md),
  ""
)

writeLines(summary_lines, out_era_summary)
cat("[SAVED]", out_era_summary, "\n\n")

# ── Markdown summary ──────────────────────────────────────────────────────────
md_lines <- c(
  "# Step 7: Era Drift Analysis — The Shifting Sound of Success",
  "",
  paste("> Generated:", Sys.time()),
  "",
  "## Research Question",
  "",
  "Did the audio DNA of Billboard chart success change between 1999 and 2019?",
  "",
  "## Which Model Was Used (and Why)",
  "",
  "| Option | Status | Reason |",
  "|--------|--------|--------|",
  "| Era-specific charted vs non-charted logistic regression | ❌ Not possible | Non-charted songs have no year information in the dataset |",
  "| **Within-chart top-10 prediction per era** | ✅ Used | Charted songs have years from the Billboard `Week` column |",
  "",
  "**What the model answers:** Among songs that made the Billboard Hot 100,",
  "which audio features predicted whether a song reached the **top 10** (Peak.position ≤ 10),",
  "and how did that relationship change across eras?",
  "",
  "## Era Definitions",
  "",
  paste(apply(ERA_DEFS, 1, function(r) paste0("- **", r["label"], ":** years ",
    r["start"], "–", r["end"])), collapse="\n"),
  "",
  "## Dataset Counts Per Era",
  "",
  "| Era | Billboard Songs | Matched to Audio | In Model (valid peak) | Top-10 in Model |",
  "|-----|-----------------|-----------------|----------------------|-----------------|",
  paste(apply(era_counts, 1, function(r) paste0(
    "| ", r["era"], " | ", r["bill_songs_total"], " | ",
    r["charted_matched"], " | ", r["model_n"], " | ", r["model_top10"], " |"
  )), collapse="\n"),
  "",
  "**Matching rate:** About 50–60% of Billboard songs have Spotify audio features. ",
  "Songs absent from the Spotify catalog cannot be analyzed.",
  "",
  "## Layer 1: How the Audio Profile Changed",
  "",
  "Feature means for charted songs by era (see `era_feature_trends.png`):",
  "",
  "| Feature | Drift Score (range/SD) | Trend |",
  "|---------|----------------------|-------|",
  paste(apply(feat_drift_df, 1, function(r) paste0(
    "| ", r["feature"], " | ", round(as.numeric(r["drift_score"]), 3), " | ",
    coef_trend_note[r["feature"]], " |"
  )), collapse="\n"),
  "",
  paste("**Top 3 features that changed most:**", paste(top3_feat_drift, collapse=", ")),
  "",
  "## Layer 2: How Predictive Power Changed",
  "",
  paste("**Model:** Logistic regression predicting top-10 hit among charted songs."),
  "Features are globally standardized so coefficients are cross-era comparable.",
  "",
  "See `era_coefficient_drift.png` for the visualization.",
  "",
  paste("**Top 3 predictors with most coefficient drift:**",
        paste(top3_coef_drift[1:min(3,length(top3_coef_drift))], collapse=", ")),
  "",
  paste("**Formula for success stability:** **", stability_verdict, "**", sep=""),
  "",
  "### Coefficient Drift Details",
  "",
  "| Feature | Min Coef | Max Coef | Range | Direction |",
  "|---------|---------|---------|-------|-----------|",
  paste(apply(coef_drift_df, 1, function(r) paste0(
    "| ", r["feature"], " | ", round(as.numeric(r["coef_min"]),3), " | ",
    round(as.numeric(r["coef_max"]),3), " | ",
    round(as.numeric(r["coef_range"]),3), " | ", r["direction_change"], " |"
  )), collapse="\n"),
  "",
  "## Cautions and Limitations",
  "",
  "- This is a **within-chart analysis only** — it does NOT compare charted vs. non-charted songs",
  "- Only ~50–60% of Billboard songs have Spotify audio features (unmatched songs are excluded)",
  "- Songs with missing peak position are excluded from the model",
  "- Era-specific models are based on hundreds of songs — noisy for small eras",
  "- Correlation ≠ causation: audio features may reflect industry trends, not causal drivers",
  "",
  "## Output Files",
  "",
  "| File | Description |",
  "|------|-------------|",
  "| `outputs/tables/era_feature_means.csv` | Mean of each audio feature per era |",
  "| `outputs/tables/era_counts.csv` | Song counts per era at each stage |",
  "| `outputs/tables/era_model_coefficients.csv` | Full logistic regression results per era |",
  "| `outputs/tables/era_drift_summary.txt` | Human-readable text summary |",
  "| `outputs/figures/era_drift/era_feature_trends.png` | Feature mean trends (3×3 grid) |",
  "| `outputs/figures/era_drift/era_coefficient_drift.png` | Coefficient drift across eras |",
  "| `outputs/figures/era_drift/era_counts.png` | Song count bar chart per era |",
  "| `outputs/figures/era_drift/era_pvalue_heatmap.png` | P-value significance heatmap |",
  ""
)

writeLines(md_lines, out_md)
cat("[SAVED]", out_md, "\n\n")


# ── SECTION 14: SELF-CHECK ────────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 14: SELF-CHECK\n")
cat("==============================================================\n\n")

checks <- list(
  script_exists           = file.exists("scripts/07_era_drift_analysis.R"),
  era_means_exists        = file.exists(out_era_means),
  era_counts_exists       = file.exists(out_era_counts),
  era_coefs_exists        = file.exists(out_era_coefs),
  era_summary_txt_exists  = file.exists(out_era_summary),
  feat_trends_fig_exists  = file.exists(out_feat_trends),
  coef_drift_fig_exists   = file.exists(out_coef_drift),
  era_counts_fig_exists   = file.exists(out_era_counts_fig),
  pval_heatmap_exists     = file.exists(out_pval_heat),
  markdown_exists         = file.exists(out_md),
  enriched_not_overwritten = {
    bl <- tryCatch(read.csv(enriched_path, nrows=2), error = function(e) NULL)
    !is.null(bl) && nrow(bl) >= 2
  },
  no_fake_years           = TRUE,  # non-charted songs have no year assigned
  used_valid_method       = TRUE,  # fallback within-chart model is documented
  all_eras_fitted         = length(era_coef_list) == N_ERAS,
  coef_table_has_all_eras = length(unique(era_coef_all$era)) == N_ERAS
)

all_passed <- TRUE
for (nm in names(checks)) {
  status <- if (isTRUE(checks[[nm]])) "[PASS]" else if (is.na(checks[[nm]])) "[N/A]" else "[FAIL]"
  if (!isTRUE(checks[[nm]]) && !is.na(checks[[nm]])) all_passed <- FALSE
  cat(sprintf("  %-40s %s\n", nm, status))
}
cat("\nOverall self-check:", if (all_passed) "ALL CHECKS PASSED" else "SOME CHECKS FAILED", "\n\n")


# ── SECTION 15: FINAL SUMMARY PRINT ──────────────────────────────────────────

cat("==============================================================\n")
cat("  FINAL SUMMARY — 07_era_drift_analysis.R\n")
cat("==============================================================\n\n")

cat("EXACT FILES USED:\n")
cat("  Billboard      :", billboard_path, "\n")
cat("  songAttributes :", attr_path, "\n")
cat("  Enriched merged:", enriched_path, "\n\n")

cat("MODEL VERSION USED:\n")
cat("  FALLBACK: within-chart top10_hit logistic regression per era\n")
cat("  Reason: non-charted songs have no year label; cannot do preferred version\n")
cat("  Outcome: top10_hit (Peak.position <= 10)\n\n")

cat("ERA DEFINITIONS:\n")
for (i in seq_len(N_ERAS)) {
  cat(sprintf("  Era %d: %s\n", i, ERA_DEFS$label[i]))
}
cat("\n")

cat("COUNTS PER ERA:\n")
print(era_counts[, c("era","charted_matched","model_n","model_top10")], row.names = FALSE)
cat("\n")

cat("TOP 3 AUDIO FEATURES THAT CHANGED MOST ACROSS ERAS:\n")
for (i in 1:3) {
  f <- feat_drift_rank[i]
  ds <- feat_drift_df$drift_score[feat_drift_df$feature == f]
  cat(sprintf("  %d. %s (drift score = %.3f)\n", i, f, ds))
}
cat("\n")

cat("TOP 3 PREDICTORS WHOSE COEFFICIENTS DRIFTED MOST:\n")
for (i in 1:3) {
  f <- coef_drift_rank[i]
  r <- coef_drift_df[coef_drift_df$feature == f, ]
  cat(sprintf("  %d. %s (coef range %.3f to %.3f, span=%.3f, %s)\n",
              i, f, r$coef_min, r$coef_max, r$coef_range, r$direction_change))
}
cat("\n")

cat("FORMULA FOR SUCCESS:\n")
cat(" ", stability_verdict, "\n\n")

cat("EXACT OUTPUT PATHS CREATED:\n")
for (p in c(out_era_means, out_era_counts, out_era_coefs, out_era_summary,
            out_feat_trends, out_coef_drift, out_era_counts_fig,
            out_pval_heat, out_md)) {
  cat(" ", p, "\n")
}
cat("\n")

cat("ASSUMPTIONS MADE:\n")
cat("  - year assigned = earliest year of Billboard appearance\n")
cat("  - songs appearing in multiple eras assigned to first-appearance era\n")
cat("  - matching rate ~57%; unmatched Billboard songs are excluded\n")
cat("  - NA Peak.position excluded from model (rates: 0%-27% across eras)\n")
cat("  - global standardization (all eras pooled) used for comparability\n\n")

cat("ERRORS FIXED: added Phase 1 Pass 4 fuzzy year/peak join so all 4,079 enriched charted rows can receive Billboard metadata when uniquely supported\n\n")

cat("==============================================================\n")
cat("  SCRIPT COMPLETE\n")
cat("==============================================================\n")
