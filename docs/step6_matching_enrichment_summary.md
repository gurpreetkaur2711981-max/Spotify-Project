# Step 6: Matching Enrichment Summary

> Generated: 2026-04-18 13:15:09

## What is this step?

We improved how Spotify songs are linked to Billboard chart songs.
The original script only matched songs if the title and artist name were
an EXACT match after basic cleaning. This step adds smarter matching rules
to recover more songs that were missed.

## Baseline (before this step)

| Item | Count |
|------|-------|
| Billboard chart songs (unique) | 7213 |
| Songs matched to Spotify audio features | 3618 |
| Songs NOT matched | 3595 |
| Total rows in merged dataset | 128745 |
| Class ratio (non-charted : charted) | ~35 : 1 |

## Matching Passes

We matched songs in 4 passes, from strictest to most lenient:

### Pass 1 (Baseline)
- **Rule:** Exact match on cleaned title + cleaned primary artist
- **Cleaning:** lowercase everything, remove punctuation, collapse spaces
- **Result:** 3618 matched songs

### Pass 2 (Better title normalization)
- **Improvement:** Strip version tags from titles before matching
- **What gets stripped:** `(feat. X)`, `(Live)`, `(Remaster)`, `- Acoustic Version`, etc.
- **Example:** `Black Coffee (feat. Merry Clayton)` → `black coffee`
- **New songs recovered:** 424

### Pass 3 (Better artist normalization)
- **Improvement:** Remove accents and clean up artist name more carefully
- **New songs recovered:** 0

### Pass 4 (Fuzzy title matching)
- **Rule:** Allow at most 1 character difference in title (same artist only)
- **Safety:** Only accepted if exactly one best match and artist is identical
- **Example:** catches a single typo or encoding difference
- **New songs recovered:** 6

### Pass 5 (Manual review only — not auto-accepted)
- 2246 candidates flagged for human inspection
- These were NOT added to the dataset automatically

## Results

| Item | Baseline | After Enrichment |
|------|---------|-----------------|
| Charted songs | 3618 | **4079** |
| Additional recovered | — | **461** |
| Non-charted songs | 125127 | 124666 |
| Total rows | 128745 | 128745 |
| Class ratio (0:1) | ~35:1 | ~31:1 |

## Is the dataset still imbalanced?

**Yes, still heavily imbalanced.** The class ratio is approximately 31:1 (non-charted to charted). Balancing techniques (oversampling, undersampling, or class weights) will still be needed in the modeling step.

## Safety check

- No existing master datasets were overwritten
- No modeling, EDA, hypothesis tests, or PCA was done
- All accepted matches required the same normalized artist (never cross-artist)
- The following risky rules were deliberately **rejected**:
  - Title-only matching (known false positives in this catalog)
  - Fuzzy matching across different artists

## Output Files

| File | Description |
|------|-------------|
| `data/processed/spotify_billboard_merged_enriched_full.csv` | New enriched merged dataset |
| `outputs/tables/recovered_charted_matches.csv` | All newly recovered matches |
| `outputs/tables/matching_pass_breakdown.csv` | Count per matching pass |
| `outputs/tables/manual_review_candidates.csv` | Plausible but unconfirmed candidates |
| `outputs/tables/matching_enrichment_summary.txt` | Full text report |
| `outputs/tables/enriched_vs_baseline_comparison.csv` | Side-by-side comparison |

