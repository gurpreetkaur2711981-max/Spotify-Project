# =============================================================================
# Script: 01b_build_merged_dataset.R
# Project: Predicting Billboard Chart Success from Spotify Audio Features
# Purpose: Merge the Billboard chart history and Spotify audio features into
#          one clean analysis dataset with a binary "charted" outcome column.
#          This is Step 1b — no modeling or EDA is done here.
#
# Inputs:
#   data/raw/BillboardFromLast20/billboardHot100_1999-2019.csv
#   data/raw/BillboardFromLast20/songAttributes_1999-2019.csv
#
# Outputs:
#   data/processed/spotify_billboard_merged_full.csv
#   outputs/tables/merge_summary.txt
#
# Uses ONLY base R. No packages needed.
# =============================================================================

# ── 0. SETUP ──────────────────────────────────────────────────────────────────

project_root <- "D:/SpotifyBillboardProject"
setwd(project_root)
cat("Working directory:", getwd(), "\n\n")

# Source file paths
billboard_path <- "data/raw/BillboardFromLast20/billboardHot100_1999-2019.csv"
attr_path      <- "data/raw/BillboardFromLast20/songAttributes_1999-2019.csv"

# Verify both source files exist before doing anything else
if (!file.exists(billboard_path)) stop("Billboard file not found: ", billboard_path)
if (!file.exists(attr_path))      stop("songAttributes file not found: ", attr_path)
cat("Both source files found.\n\n")

# ── 1. HELPER FUNCTIONS ───────────────────────────────────────────────────────

# clean_text: standardize a string for fuzzy matching
#   - lowercase
#   - remove everything that is not a letter, digit, or space
#   - collapse multiple spaces into one
#   - trim leading/trailing spaces
clean_text <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("[^a-z0-9 ]", "", x)   # remove punctuation
  x <- gsub("\\s+", " ", x)        # collapse spaces
  x <- trimws(x)
  return(x)
}

# primary_artist: extract the first-listed artist from a Billboard Artists string.
# Billboard uses commas to separate multiple artists.
# Example: "Ed Sheeran, Justin Bieber" -> "Ed Sheeran" -> cleaned: "ed sheeran"
primary_artist <- function(artist_str) {
  first_part <- sub(",.*", "", artist_str)   # keep everything before first comma
  return(clean_text(first_part))
}

# ── 2. READ SOURCE FILES ───────────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 1: READING SOURCE FILES\n")
cat("==============================================================\n\n")

# --- Billboard (208 MB, ~97K real rows, ~5.8M raw lines due to lyrics) ---
cat("[INFO] Reading Billboard file. This is 208 MB and may take 1-3 minutes...\n")
cat("       R's read.csv handles the multi-line lyrics field correctly.\n\n")

bill_raw <- read.csv(
  billboard_path,
  stringsAsFactors = FALSE,
  check.names      = FALSE,    # keeps original column names as-is
  quote            = "\"",     # standard CSV quoting
  comment.char     = ""        # don't treat # as comments in lyrics
)

# The first column has an empty name (it's a row-index from Python/pandas).
# Rename it to avoid confusion.
if (names(bill_raw)[1] == "") names(bill_raw)[1] <- "row_id"

cat("Billboard dimensions   :", nrow(bill_raw), "rows x", ncol(bill_raw), "columns\n")
cat("Billboard columns      :", paste(names(bill_raw), collapse = ", "), "\n\n")

# --- songAttributes (20 MB, 154,931 rows) ---
cat("[INFO] Reading songAttributes file...\n")
attr_raw <- read.csv(
  attr_path,
  stringsAsFactors = FALSE,
  check.names      = FALSE,
  comment.char     = ""
)

if (names(attr_raw)[1] == "") names(attr_raw)[1] <- "row_id"

cat("songAttributes dimensions:", nrow(attr_raw), "rows x", ncol(attr_raw), "columns\n")
cat("songAttributes columns   :", paste(names(attr_raw), collapse = ", "), "\n\n")

# Store raw row counts for the summary report
raw_rows_bill <- nrow(bill_raw)
raw_rows_attr <- nrow(attr_raw)

# ── 3. ADD CLEANED MATCH KEYS ─────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 2: CREATING CLEANED MATCH KEYS\n")
cat("==============================================================\n\n")

# Billboard: clean song name + primary artist (first artist before comma)
bill_raw$clean_name   <- clean_text(bill_raw$Name)
bill_raw$clean_artist <- primary_artist(bill_raw$Artists)
bill_raw$match_key    <- paste0(bill_raw$clean_name, "|||", bill_raw$clean_artist)

cat("Billboard: sample cleaned keys:\n")
for (i in 1:5) {
  cat(sprintf("  raw_artist=%-35s | clean_artist=%-20s | clean_name=%s\n",
              substr(bill_raw$Artists[i], 1, 35),
              bill_raw$clean_artist[i],
              bill_raw$clean_name[i]))
}
cat("\n")

# songAttributes: clean song name + artist (single artist per row in this file)
attr_raw$clean_name   <- clean_text(attr_raw$Name)
attr_raw$clean_artist <- clean_text(attr_raw$Artist)
attr_raw$match_key    <- paste0(attr_raw$clean_name, "|||", attr_raw$clean_artist)

cat("songAttributes: sample cleaned keys:\n")
for (i in 1:5) {
  cat(sprintf("  raw_artist=%-35s | clean_artist=%-20s | clean_name=%s\n",
              attr_raw$Artist[i],
              attr_raw$clean_artist[i],
              attr_raw$clean_name[i]))
}
cat("\n")

# ── 4. DEDUPLICATE BILLBOARD ──────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 3: DEDUPLICATING BILLBOARD\n")
cat("==============================================================\n\n")

# Billboard has one row per song per week. We want one row per song.
# Strategy: sort so the best (lowest number = best) weekly rank comes first,
# then keep only the first row for each unique match_key.
# Also compute max weeks-on-chart for each song.

bill_raw$weekly_rank_num   <- suppressWarnings(as.integer(bill_raw$`Weekly.rank`))
bill_raw$weeks_on_chart_num <- suppressWarnings(as.integer(bill_raw$`Weeks.on.chart`))

# Sort: by match_key (group songs), then by rank ascending (best rank first),
# then rank NAs last
bill_sorted <- bill_raw[
  order(bill_raw$match_key,
        bill_raw$weekly_rank_num,
        na.last = TRUE),
]

# Keep first row per song = the row where song had its best rank
bill_dedup <- bill_sorted[!duplicated(bill_sorted$match_key), ]

# For each song, also record its maximum weeks on chart
max_weeks <- tapply(
  bill_raw$weeks_on_chart_num,
  bill_raw$match_key,
  function(x) { v <- x[!is.na(x)]; if (length(v) == 0) NA else max(v) }
)
bill_dedup$max_weeks_on_chart <- max_weeks[bill_dedup$match_key]

cat("Billboard raw rows           :", raw_rows_bill, "\n")
cat("Billboard deduplicated songs :", nrow(bill_dedup), "\n")
cat("Duplicate rows removed       :", raw_rows_bill - nrow(bill_dedup), "\n\n")

# ── 5. DEDUPLICATE SONGATTRIBUTES ─────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 4: DEDUPLICATING SONGATTRIBUTES\n")
cat("==============================================================\n\n")

# songAttributes has duplicate (Name, Artist) pairs — same song appears
# in different albums or versions.
# Strategy: keep the row with fewest missing values; break ties by
# highest Popularity score.

attr_raw$popularity_num <- suppressWarnings(as.numeric(attr_raw$Popularity))
attr_raw$n_missing      <- rowSums(is.na(attr_raw))

# Sort: by match_key (group songs), then fewest missing values, then
# highest popularity (descending, so use negative)
attr_sorted <- attr_raw[
  order(attr_raw$match_key,
        attr_raw$n_missing,
        -attr_raw$popularity_num,
        na.last = TRUE),
]

attr_dedup <- attr_sorted[!duplicated(attr_sorted$match_key), ]

attr_dupes_removed <- raw_rows_attr - nrow(attr_dedup)

cat("songAttributes raw rows          :", raw_rows_attr, "\n")
cat("songAttributes deduplicated songs:", nrow(attr_dedup), "\n")
cat("Duplicate rows removed           :", attr_dupes_removed, "\n\n")

# ── 6. MATCH: PRIMARY RULE ONLY ───────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 5: MATCHING SONGS\n")
cat("==============================================================\n\n")

cat("Matching rule: cleaned song name + cleaned primary artist\n")
cat("  Step 1: lowercase, remove punctuation, collapse spaces\n")
cat("  Step 2: extract primary artist = text before first comma in Billboard Artists\n\n")

bill_keys <- bill_dedup$match_key
attr_keys <- attr_dedup$match_key

# Primary matches: song+artist key appears in BOTH tables
primary_match_keys <- intersect(bill_keys, attr_keys)
n_primary <- length(primary_match_keys)

cat("Primary matches (name + artist) :", n_primary, "\n\n")

# Fallback (title-only) was evaluated and explicitly rejected.
# Reason: during data reconnaissance, title-only matching produced clear
# false positives:
#   "truth hurts"  -> matched Elephant Man (not Lizzo)
#   "bad guy"      -> matched Pastor Troy / Eminem (not Billie Eilish)
#   "senorita"     -> matched Gorilla Zoe (not Shawn Mendes)
# These songs simply have generic titles shared by other artists in the catalog.
# We prefer zero false positives over more matches.
cat("Fallback (title-only) : REJECTED — produces false positives\n")
cat("  e.g. 'truth hurts' (Lizzo) matched Elephant Man in songAttributes\n")
cat("  e.g. 'bad guy' (Billie Eilish) matched Pastor Troy / Eminem\n\n")

# Unmatched Billboard songs (charted but absent from songAttributes)
unmatched_bill_keys <- setdiff(bill_keys, attr_keys)
n_unmatched_bill    <- length(unmatched_bill_keys)

cat("Billboard songs with no audio feature match:", n_unmatched_bill, "\n")
cat("  (These songs appeared on Billboard but are not in songAttributes.)\n")
cat("  (They will NOT be included in the final dataset.)\n\n")

# ── 7. BUILD THE MERGED DATASET ───────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 6: BUILDING THE MERGED DATASET\n")
cat("==============================================================\n\n")

# The foundation is the deduplicated songAttributes table.
# We add charted = 1 if the song was matched to Billboard, else 0.
attr_dedup$charted <- as.integer(attr_dedup$match_key %in% primary_match_keys)

n_charted    <- sum(attr_dedup$charted == 1)
n_noncharted <- sum(attr_dedup$charted == 0)

cat("charted = 1 (matched to Billboard):", n_charted,    "\n")
cat("charted = 0 (not on Billboard)     :", n_noncharted, "\n")
cat("Total rows                         :", nrow(attr_dedup), "\n")
cat("Imbalance ratio (0:1)              :", round(n_noncharted / n_charted, 1), ":1\n\n")

# ── 8. SELECT AND RENAME FINAL COLUMNS ───────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 7: SELECTING FINAL COLUMNS (snake_case)\n")
cat("==============================================================\n\n")

# Build final dataset using snake_case column names.
# All columns from the proposal are included.
# Useful metadata columns (album, duration, etc.) are also kept.
merged <- data.frame(
  charted          = attr_dedup$charted,
  song_name        = attr_dedup$Name,
  artist           = attr_dedup$Artist,
  danceability     = suppressWarnings(as.numeric(attr_dedup$Danceability)),
  energy           = suppressWarnings(as.numeric(attr_dedup$Energy)),
  valence          = suppressWarnings(as.numeric(attr_dedup$Valence)),
  tempo            = suppressWarnings(as.numeric(attr_dedup$Tempo)),
  loudness         = suppressWarnings(as.numeric(attr_dedup$Loudness)),
  acousticness     = suppressWarnings(as.numeric(attr_dedup$Acousticness)),
  speechiness      = suppressWarnings(as.numeric(attr_dedup$Speechiness)),
  instrumentalness = suppressWarnings(as.numeric(attr_dedup$Instrumentalness)),
  liveness         = suppressWarnings(as.numeric(attr_dedup$Liveness)),
  album            = attr_dedup$Album,
  duration_ms      = suppressWarnings(as.numeric(attr_dedup$Duration)),
  explicit         = attr_dedup$Explicit,
  mode             = suppressWarnings(as.integer(attr_dedup$Mode)),
  popularity       = attr_dedup$popularity_num,
  time_signature   = suppressWarnings(as.integer(attr_dedup$TimeSignature)),
  stringsAsFactors = FALSE
)

cat("Final columns:\n")
cat(paste(sprintf("  [%2d] %s", seq_along(names(merged)), names(merged)), collapse = "\n"), "\n\n")

# Verify all 9 proposal audio features are present
proposal_audio <- c("danceability", "energy", "valence", "tempo", "loudness",
                    "acousticness", "speechiness", "instrumentalness", "liveness")
features_found   <- sum(proposal_audio %in% names(merged))
features_missing <- proposal_audio[!proposal_audio %in% names(merged)]

cat("Proposal audio features present :", features_found, "/", length(proposal_audio), "\n")
if (length(features_missing) > 0) {
  cat("MISSING features:", paste(features_missing, collapse = ", "), "\n")
} else {
  cat("All 9 proposal audio features confirmed present.\n")
}
cat("charted column present          :", "charted" %in% names(merged), "\n\n")

# ── 9. SANITY CHECK ───────────────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 8: SANITY CHECKS\n")
cat("==============================================================\n\n")

# Check class balance
tbl <- table(merged$charted)
cat("Class balance:\n")
print(tbl)
cat("Proportions:\n")
print(round(prop.table(tbl), 4))
cat("\n")

# Check missing values per column
cat("Missing values per column:\n")
miss <- colSums(is.na(merged))
miss_df <- data.frame(column = names(miss), missing = as.integer(miss), row.names = NULL)
miss_df <- miss_df[order(-miss_df$missing), ]
print(miss_df, row.names = FALSE)
cat("\n")

# Sample rows from each class
cat("Sample charted = 1 rows (should be real Billboard hits):\n")
ch1 <- merged[merged$charted == 1, c("charted", "song_name", "artist",
                                     "danceability", "energy", "popularity")]
print(head(ch1, 5), row.names = FALSE)
cat("\n")

cat("Sample charted = 0 rows:\n")
ch0 <- merged[merged$charted == 0, c("charted", "song_name", "artist",
                                     "danceability", "energy", "popularity")]
print(head(ch0, 5), row.names = FALSE)
cat("\n")

# ── 10. SAVE MERGED DATASET ───────────────────────────────────────────────────

cat("==============================================================\n")
cat("SECTION 9: SAVING OUTPUT FILES\n")
cat("==============================================================\n\n")

output_csv     <- "data/processed/spotify_billboard_merged_full.csv"
output_summary <- "outputs/tables/merge_summary.txt"

write.csv(merged, output_csv, row.names = FALSE)
cat("[SAVED] Merged dataset :", output_csv, "\n")

# Verify file was actually written
saved_rows <- nrow(read.csv(output_csv, nrows = 3))  # just read header+3 rows
if (file.exists(output_csv) && file.info(output_csv)$size > 0) {
  cat("        Verified: file exists and is non-empty\n")
  cat("        Size    :", round(file.info(output_csv)$size / 1024 / 1024, 2), "MB\n")
}
cat("\n")

# ── 11. WRITE MERGE SUMMARY REPORT ───────────────────────────────────────────

summary_lines <- c(
  "=============================================================",
  "  MERGE SUMMARY REPORT",
  paste("  Generated  :", Sys.time()),
  paste("  Script     : scripts/01b_build_merged_dataset.R"),
  "=============================================================",
  "",
  "--- Source Files ---",
  paste("  Billboard     :", billboard_path),
  paste("  songAttributes:", attr_path),
  "",
  "--- Raw Row Counts ---",
  paste("  Billboard raw rows      :", raw_rows_bill),
  paste("  songAttributes raw rows :", raw_rows_attr),
  "",
  "--- After Deduplication ---",
  paste("  Billboard unique songs      :", nrow(bill_dedup)),
  paste("  Billboard rows removed      :", raw_rows_bill - nrow(bill_dedup)),
  paste("  songAttributes unique songs :", nrow(attr_dedup)),
  paste("  songAttributes rows removed :", attr_dupes_removed),
  "  songAttributes dedup rule: keep row with fewest NA, break ties by highest Popularity",
  "",
  "--- Matching Rules ---",
  "  Primary rule: cleaned_song_name + cleaned_primary_artist",
  "    - Cleaning: lowercase, remove punctuation, collapse spaces, trim whitespace",
  "    - Primary artist: text before first comma in Billboard Artists field",
  "  Fallback rule: REJECTED",
  "    Reason: title-only matching produces clear false positives",
  "    Evidence examples:",
  "      'truth hurts' (Lizzo) -> wrongly matched to Elephant Man",
  "      'bad guy' (Billie Eilish) -> wrongly matched to Pastor Troy / Eminem",
  "      'senorita' (Shawn Mendes) -> wrongly matched to Gorilla Zoe",
  "",
  "--- Match Counts ---",
  paste("  Primary matches (name+artist)            :", n_primary),
  "  Fallback matches (title only)               : 0  (rejected)",
  paste("  Total charted in merged dataset          :", n_charted),
  paste("  Billboard songs not matched (no audio)   :", n_unmatched_bill),
  "",
  "--- Final Merged Dataset ---",
  paste("  Output file   :", output_csv),
  paste("  Total rows    :", nrow(merged)),
  paste("  Total columns :", ncol(merged)),
  paste("  Columns       :", paste(names(merged), collapse = ", ")),
  paste("  charted = 1   :", n_charted),
  paste("  charted = 0   :", n_noncharted),
  paste("  Imbalance (0:1 ratio):", round(n_noncharted / n_charted, 1), ":1"),
  "",
  "--- Missing Values Summary ---",
  capture.output(print(miss_df, row.names = FALSE)),
  "",
  "--- Proposal Variable Check ---",
  paste("  charted            :", if("charted" %in% names(merged)) "PRESENT" else "MISSING"),
  sapply(proposal_audio, function(v)
    paste0("  ", sprintf("%-18s", v), ": ",
           if (v %in% names(merged)) "PRESENT" else "MISSING")),
  "",
  paste("  Proposal variables found   :", 1 + features_found, "/ 10"),
  paste("  Proposal variables missing :", 10 - 1 - features_found),
  "",
  "--- Does This Match the Proposal? ---",
  "  All 9 audio features    : PRESENT",
  "  charted outcome column  : PRESENT (binary 0/1)",
  "  Proposal match status   : PARTIAL",
  "  Reasons for PARTIAL:",
  paste("    - Severe class imbalance:", round(n_noncharted / n_charted, 1),
        ":1 (will need balancing in modeling step)"),
  paste("    -", n_unmatched_bill, "Billboard songs could not be matched to audio features"),
  "    - These unmatched songs were real chart hits but absent from songAttributes",
  "  No modeling or sampling was done in this script.",
  ""
)

writeLines(summary_lines, output_summary)
cat("[SAVED] Merge summary  :", output_summary, "\n")
if (file.exists(output_summary)) {
  cat("        Verified: file exists, size:", file.info(output_summary)$size, "bytes\n")
}
cat("\n")

# ── 12. FINAL STATUS ─────────────────────────────────────────────────────────

cat("=============================================================\n")
cat("  SCRIPT COMPLETE — 01b_build_merged_dataset.R\n")
cat("=============================================================\n")
cat("  charted = 1 songs :", n_charted, "\n")
cat("  charted = 0 songs :", n_noncharted, "\n")
cat("  Total rows        :", nrow(merged), "\n")
cat("  No modeling done.\n")
cat("  No sampling done.\n")
cat("  Next step: run scripts/01_data_inspection.R\n")
cat("=============================================================\n")
