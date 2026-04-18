# Step 2: Exploratory Data Analysis (EDA)

> **Status: COMPLETE**

---

## What Is EDA?

Exploratory Data Analysis (EDA) means looking at your data through graphs
and summary statistics **before** doing any formal analysis. The goal is to
understand the shape of the data, spot patterns, and ask better questions.

EDA does NOT prove anything. It shows possibilities — things worth testing
formally in the next steps (hypothesis testing, PCA, logistic regression).

---

## Dataset Used

- **File:** `data/processed/spotify_billboard_merged_full.csv`
- **Rows:** 128,745 songs
- **Outcome column:** `charted` (0 = not on Billboard, 1 = on Billboard)
- **Features explored:** 9 Spotify audio features

---

## Why Class Imbalance Matters Visually

This dataset is heavily imbalanced:

| Class | Count | Share |
|-------|-------|-------|
| charted = 0 (not charted) | 125,127 | 97.2% |
| charted = 1 (charted)     |   3,618 |  2.8% |

When we draw a **boxplot by group**, the `charted=0` box is built from
125,127 songs, and `charted=1` from only 3,618. This means the boxes may
look tight and similar even if real differences exist — because the smaller
group's box can be influenced more by its own internal spread.

The **histograms** show the full distribution over all 128,745 songs. Since
97% of songs are non-charted, the histogram shape is dominated by that group.

---

## Plots Created

### 1. Class Balance Bar Chart
- File: `outputs/figures/eda/charted_class_balance.png`
- Shows how many songs are in each class. Confirms the 34.6:1 imbalance.

### 2. Histograms (9 total, one per feature)
- Files: `outputs/figures/eda/histogram_{feature}.png`
- Show the overall distribution of each audio feature across all songs.
- Dashed vertical lines mark the group means for charted vs. not charted.
- Helps you see: Is the feature skewed? Are there outliers? Where is the bulk?

### 3. Boxplots by Charted Group (9 total)
- Files: `outputs/figures/eda/boxplot_{feature}_by_charted.png`
- Compare the distribution of each feature between charted and non-charted songs.
- The box shows the middle 50% of values (IQR), the line shows the median,
  the diamond shows the mean.
- Extreme outliers are hidden (`outline=FALSE`) for readability.

### 4. Correlation Heatmap
- File: `outputs/figures/eda/audio_feature_correlation_heatmap.png`
- Shows how strongly each pair of audio features is related to each other.
- Blue = negative correlation, Red = positive correlation, White = no correlation.
- Numbers in each cell show the exact correlation coefficient (−1 to +1).

---

## What Each Feature Looks Like

| Feature | Charted Mean | Not-Charted Mean | Difference | Direction |
|---------|-------------|-----------------|------------|-----------|
| `danceability` | 0.612 | 0.578 | +0.034 | higher in charted |
| `energy` | 0.704 | 0.639 | +0.065 | higher in charted |
| `valence` | 0.522 | 0.498 | +0.023 | higher in charted |
| `tempo` | 122.897 | 119.163 | +3.734 | higher in charted |
| `loudness` | -5.846 | -8.043 | +2.197 | higher in charted |
| `acousticness` | 0.160 | 0.262 | -0.102 | lower in charted |
| `speechiness` | 0.094 | 0.126 | -0.032 | lower in charted |
| `instrumentalness` | 0.008 | 0.063 | -0.055 | lower in charted |
| `liveness` | 0.187 | 0.253 | -0.066 | lower in charted |

---

## Top 3 Most Visually Different Features

Based on the difference in group means (absolute value), these features
show the clearest visible separation between charted and non-charted songs:

1. **`tempo`** — charted songs have higher values (diff = +3.734)
2. **`loudness`** — charted songs have higher values (diff = +2.197)
3. **`acousticness`** — charted songs have lower values (diff = -0.102)

**What this suggests (visual observation only):**
- Charted songs tend to be **louder** (higher loudness in dB).
- Charted songs tend to be **less acoustic** (more produced/electronic sound).
- Charted songs tend to be **more energetic**.
- These patterns are visual only — formal hypothesis testing comes next.

---

## Correlation Among the 9 Features

| Pair | Correlation | Interpretation |
|------|-------------|----------------|
| `energy` × `loudness` | 0.754 | strong positive |
| `energy` × `acousticness` | -0.687 | strong negative |
| `loudness` × `acousticness` | -0.562 | strong negative |
| `danceability` × `valence` | 0.472 | moderate positive |
| `energy` × `valence` | 0.314 | moderate positive |
| `danceability` × `acousticness` | -0.233 | moderate negative |

**Key takeaways:**
- **Energy and Loudness** are strongly positively correlated (+0.75).
  Louder songs tend to also be more energetic — they capture a similar
  concept from two angles.
- **Energy and Acousticness** are strongly negatively correlated (−0.69).
  Acoustic songs tend to be quieter and less intense.
- Because of this overlap, PCA in Step 4 will help reduce redundancy
  among features before building the logistic regression model.

---

## Important Caution

> These are **visual observations only**. They are NOT statistical proof.
>
> A difference in group means could happen by chance, especially with an
> imbalanced dataset. The next step (hypothesis testing) will formally test
> whether these differences are statistically significant.

---

## Output Files

| Type | File |
|------|------|
| Bar chart | `outputs/figures/eda/charted_class_balance.png` |
| Histogram | `outputs/figures/eda/histogram_danceability.png` |
| Histogram | `outputs/figures/eda/histogram_energy.png` |
| Histogram | `outputs/figures/eda/histogram_valence.png` |
| Histogram | `outputs/figures/eda/histogram_tempo.png` |
| Histogram | `outputs/figures/eda/histogram_loudness.png` |
| Histogram | `outputs/figures/eda/histogram_acousticness.png` |
| Histogram | `outputs/figures/eda/histogram_speechiness.png` |
| Histogram | `outputs/figures/eda/histogram_instrumentalness.png` |
| Histogram | `outputs/figures/eda/histogram_liveness.png` |
| Boxplot | `outputs/figures/eda/boxplot_danceability_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_energy_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_valence_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_tempo_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_loudness_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_acousticness_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_speechiness_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_instrumentalness_by_charted.png` |
| Boxplot | `outputs/figures/eda/boxplot_liveness_by_charted.png` |
| Heatmap | `outputs/figures/eda/audio_feature_correlation_heatmap.png` |
| Correlation CSV | `outputs/tables/audio_feature_correlation_matrix.csv` |
| Group summary CSV | `outputs/tables/eda_group_summary_by_charted.csv` |

---

*EDA run: 2026-04-18 00:30:59 *
