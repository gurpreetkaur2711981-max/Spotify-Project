# Step 1: Data Understanding

> **Status: COMPLETE — audit ran on merged dataset**

---

## What Is This Project About?

We want to answer one question:

> **Can we predict whether a song will appear on the Billboard Hot 100 chart
> just by looking at its Spotify audio features?**

---

## Dataset Actually Used

**File:** `data/processed/spotify_billboard_merged_full.csv`
**Built by:** `scripts/01b_build_merged_dataset.R`
**Source tables:** `billboardHot100_1999-2019.csv` + `songAttributes_1999-2019.csv`

---

## Actual Dataset Facts (as of this audit)

| Item | Value |
|------|-------|
| Rows |  128745  |
| Columns |  18  |
| Missing values |  0  |
| Duplicate rows |  0  |
| charted = 1 (yes) |  3618  ( 2.81 %) |
| charted = 0 (no) |  125127  ( 97.19 %) |
| Class imbalance ratio |  34.6:1  |

---

## Full Column List

| ` 1` | `charted` |
| ` 2` | `song_name` |
| ` 3` | `artist` |
| ` 4` | `danceability` |
| ` 5` | `energy` |
| ` 6` | `valence` |
| ` 7` | `tempo` |
| ` 8` | `loudness` |
| ` 9` | `acousticness` |
| `10` | `speechiness` |
| `11` | `instrumentalness` |
| `12` | `liveness` |
| `13` | `album` |
| `14` | `duration_ms` |
| `15` | `explicit` |
| `16` | `mode` |
| `17` | `popularity` |
| `18` | `time_signature` |

---

## Outcome Column

- **Name:** `charted`
- **Type:** Binary integer (0 or 1)
- **Meaning:**
  - `charted = 1` — song appeared on the Billboard Hot 100 AND has Spotify audio features
  - `charted = 0` — song has audio features but did NOT chart on Billboard Hot 100

---

## Predictors Available

All 9 audio features from the project proposal are present:

| Feature | Column Name | Type |
|---------|-------------|------|
| Danceability | `danceability` | Numeric, 0–1 |
| Energy | `energy` | Numeric, 0–1 |
| Valence | `valence` | Numeric, 0–1 |
| Tempo | `tempo` | Numeric, BPM |
| Loudness | `loudness` | Numeric, dB |
| Acousticness | `acousticness` | Numeric, 0–1 |
| Speechiness | `speechiness` | Numeric, 0–1 |
| Instrumentalness | `instrumentalness` | Numeric, 0–1 |
| Liveness | `liveness` | Numeric, 0–1 |

**Extra columns** (metadata, not predictors in the proposal):
`song_name`, `artist`, `album`, `duration_ms`, `explicit`, `mode`,
`popularity`, `time_signature`

---

## IMPORTANT: How This Dataset Differs from the Proposal

The project proposal was likely written using a **pre-built, balanced Kaggle**
**dataset** — approximately 18,454 rows with roughly equal numbers of charted
and non-charted songs.

**What we actually have is different:**

| | Proposal Expected | Actual |
|-|-------------------|--------|
| Rows | ~18,454 | 128,745 |
| Class balance | ~50/50 | 97.2% / 2.8% |
| Imbalance ratio | ~1:1 | 34.6:1 |
| Source | Single merged CSV | Built from two source tables |

**Why the difference?**

The Kaggle download (`BillboardFromLast20`) contained separate source tables,
not a single merged analysis file. We joined them conservatively:

- `songAttributes_1999-2019.csv` — 154,931 rows → 128,745 after deduplication
- `billboardHot100_1999-2019.csv` — 97,225 rows → 7,213 unique charted songs
- **Only 3,618 of 7,213 Billboard songs** could be matched to audio features
  by cleaned song name + cleaned primary artist.
- The remaining 3,595 Billboard songs (including major hits like 'Old Town Road'
  by Lil Nas X, 'Bad Guy' by Billie Eilish) are **absent from songAttributes**.
- No risky title-only fallback matching was used (it produced false positives).

**What this means for the project:**

- The dataset IS usable for all four methods: EDA, hypothesis testing, PCA,
  and logistic regression.
- The severe class imbalance **must be addressed** before modeling.
  Typical approaches: random undersampling, SMOTE, or class-weighted logistic
  regression. This will be done in a future step.
- EDA and hypothesis testing can be run on the full imbalanced dataset.
- This mismatch does not invalidate the project — it just means the scale
  and balance are different from what the proposal assumed.

---

## Missing Values

**Total missing cells: 0**

| Column | Missing Count | % Missing |
|--------|--------------|-----------|
| `charted` | 0 | 0% |
| `song_name` | 0 | 0% |
| `artist` | 0 | 0% |
| `danceability` | 0 | 0% |
| `energy` | 0 | 0% |
| `valence` | 0 | 0% |
| `tempo` | 0 | 0% |
| `loudness` | 0 | 0% |
| `acousticness` | 0 | 0% |
| `speechiness` | 0 | 0% |
| `instrumentalness` | 0 | 0% |
| `liveness` | 0 | 0% |
| `album` | 0 | 0% |
| `duration_ms` | 0 | 0% |
| `explicit` | 0 | 0% |
| `mode` | 0 | 0% |
| `popularity` | 0 | 0% |
| `time_signature` | 0 | 0% |

---

## What Happens Next

```
[STEP 1 COMPLETE] Data inspection done.
  → data/processed/spotify_billboard_merged_full.csv audited
  → outputs/tables/data_audit_summary.txt saved

[STEP 2 — NEXT] Exploratory Data Analysis (EDA)
  → scripts/02_eda.R
  → histograms, boxplots, correlation plots of audio features

[STEP 3] Hypothesis Testing
  → compare charted vs non-charted on each audio feature

[STEP 4] Principal Component Analysis (PCA)

[STEP 5] Logistic Regression
  → requires class balancing first
```

*Audit run: 2026-04-18 00:21:21 *
