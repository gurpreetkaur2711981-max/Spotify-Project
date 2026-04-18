# Step 2b: Data Cleaning

> **Status: COMPLETE — light cleaning pass on merged dataset**

---

## Purpose

This step performs a light finalization pass on `spotify_billboard_merged_full.csv`.
It does **not** balance classes, remove outliers, or engineer features.
The goal is to produce a clean, analysis-ready CSV with correct column types
and documented range checks.

---

## Source vs Output

| | File |
|-|------|
| **Source (unchanged)** | `data/processed/spotify_billboard_merged_full.csv` |
| **Clean output** | `data/processed/spotify_billboard_analysis_clean.csv` |

---

## Changes Made

| Column | Before | After | Why |
|--------|--------|-------|-----|
| `explicit` | character `"True"`/`"False"` | integer `1`/`0` | Must be numeric for modeling |

All other columns were already in the correct type.
**No rows were added or removed.**

---

## Checks Performed

| Check | Result |
|-------|--------|
| Missing values | 0 |
| Duplicate rows | 0 |
| Binary columns (`charted`, `explicit`, `mode`) | All 0/1 integer |
| Audio features numeric | All confirmed numeric |
| Feature ranges within bounds | All OK |

---

## Final Dataset

**File:** `data/processed/spotify_billboard_analysis_clean.csv`

| Item | Value |
|------|-------|
| Rows | 128745 |
| Columns | 18 |
| Missing values | 0 |
| charted=1 | 3618 (2.81%) |
| charted=0 | 125127 (97.19%) |

---

## Column Types (final)

| Column | Type | Notes |
|--------|------|-------|
| `charted` | integer (0/1) | outcome variable |
| `explicit` | integer (0/1) | converted from character |
| `mode` | integer (0/1) | minor/major |
| `danceability` | numeric | 0–1 |
| `energy` | numeric | 0–1 |
| `valence` | numeric | 0–1 |
| `acousticness` | numeric | 0–1 |
| `speechiness` | numeric | 0–1 |
| `instrumentalness` | numeric | 0–1 |
| `liveness` | numeric | 0–1 |
| `tempo` | numeric | BPM (positive) |
| `loudness` | numeric | dB (negative to ~0) |
| `popularity` | integer | 0–100 |
| `duration_ms` | numeric | milliseconds |
| `time_signature` | integer | beats per bar |
| `song_name` | character | metadata |
| `artist` | character | metadata |
| `album` | character | metadata |

---

## What Happens Next

```
[STEP 2b COMPLETE] Cleaning done.
  -> data/processed/spotify_billboard_analysis_clean.csv is the analysis file

[STEP 3 — NEXT] Hypothesis Testing
  -> Compare charted vs non-charted on each audio feature
  -> Two-sample tests (Wilcoxon / t-test) for each of 9 features
```

*Cleaning run: 2026-04-18 00:38:22*
