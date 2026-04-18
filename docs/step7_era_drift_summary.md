# Step 7: Era Drift Analysis - The Shifting Sound of Success

> Generated: 2026-04-18 13:59:15

## Research Question

Did the audio DNA of Billboard chart success change between 1999 and 2019?

## Which Model Was Used (and Why)

| Option | Status | Reason |
|--------|--------|--------|
| Era-specific charted vs non-charted logistic regression | Not possible | Non-charted songs have no year information in the dataset |
| **Within-chart top-10 prediction per era** | Used | Charted songs have years from the Billboard `Week` column |

**What the model answers:** Among songs that made the Billboard Hot 100, which audio features predicted whether a song reached the **top 10** (`Peak.position <= 10`), and how did that relationship change across eras?

## Era Definitions

- **1999-2002:** years 1999-2002
- **2003-2006:** years 2003-2006
- **2007-2010:** years 2007-2010
- **2011-2014:** years 2011-2014
- **2015-2019:** years 2015-2019

## Dataset Counts Per Era

| Era | Billboard Songs | Matched to Audio | In Model (valid peak) | Top-10 in Model |
|-----|-----------------|-----------------|----------------------|-----------------|
| 1999-2002 | 1035 | 712 | 709 | 147 |
| 2003-2006 | 1216 | 903 | 867 | 165 |
| 2007-2010 | 1519 | 1022 | 861 | 168 |
| 2011-2014 | 1441 | 783 | 643 | 123 |
| 2015-2019 | 2002 | 659 | 494 | 85 |

**Matching rate:** About 50-60% of Billboard songs have Spotify audio features. Songs absent from the Spotify catalog cannot be analyzed.

## Layer 1: How the Audio Profile Changed

Feature means for charted songs by era (see `era_feature_trends.png`):

| Feature | Drift Score (range/SD) | Trend |
|---------|------------------------|-------|
| speechiness | 0.609 | higher in 2015-2019 than 1999-2002 (Delta=+0.063) |
| energy | 0.549 | lower in 2015-2019 than 1999-2002 (Delta=-0.050) |
| loudness | 0.510 | lower in 2015-2019 than 1999-2002 (Delta=-0.152) |
| danceability | 0.464 | higher in 2015-2019 than 1999-2002 (Delta=+0.032) |
| valence | 0.426 | lower in 2015-2019 than 1999-2002 (Delta=-0.095) |
| tempo | 0.291 | higher in 2015-2019 than 1999-2002 (Delta=+4.364 BPM) |
| acousticness | 0.184 | higher in 2015-2019 than 1999-2002 (Delta=+0.019) |
| instrumentalness | 0.160 | relatively stable (Delta=-0.009) |
| liveness | 0.159 | relatively stable (Delta=-0.004) |

**Top 3 features that changed most:** speechiness, energy, loudness.

## Layer 2: How Predictive Power Changed

**Model:** Logistic regression predicting top-10 hit among charted songs. Features are globally standardized so coefficients are cross-era comparable.

See `era_coefficient_drift.png` for the visualization.

**Top 3 predictors with most coefficient drift:** danceability, valence, energy.

**Phase 2 conclusion:** **MODERATE EVIDENCE OF DRIFT - results are consistent with a shifting formula for success, but interpretation should be cautious.**

**Caution:** Later-era coverage is weaker, and **2015-2019 includes only 85 modeled top-10 songs**, so that era should be interpreted cautiously.

### Coefficient Drift Details

| Feature | Min Coef | Max Coef | Range | Direction |
|---------|---------:|---------:|------:|-----------|
| danceability | -0.021 | 0.615 | 0.636 | crossed zero |
| valence | -0.231 | 0.382 | 0.613 | crossed zero |
| energy | -0.598 | 0.012 | 0.610 | crossed zero |
| speechiness | -0.200 | 0.318 | 0.517 | crossed zero |
| loudness | -0.041 | 0.399 | 0.440 | crossed zero |
| liveness | -0.116 | 0.264 | 0.380 | crossed zero |
| instrumentalness | -0.274 | 0.090 | 0.364 | crossed zero |
| acousticness | -0.348 | -0.058 | 0.290 | consistently negative |
| tempo | -0.250 | -0.009 | 0.241 | consistently negative |

## Cautions and Limitations

- This is a **within-chart analysis only** - it does NOT compare charted vs. non-charted songs.
- Only about 50-60% of Billboard songs have Spotify audio features, so unmatched songs are excluded.
- Songs with missing peak position are excluded from the model.
- Era-specific models are based on hundreds of songs and are noisier in smaller eras.
- Later-era coverage is weaker, and 2015-2019 has relatively few modeled top-10 songs.
- Correlation does not imply causation: audio features may reflect industry trends, not causal drivers.

## Output Files

| File | Description |
|------|-------------|
| `outputs/tables/era_feature_means.csv` | Mean of each audio feature per era |
| `outputs/tables/era_counts.csv` | Song counts per era at each stage |
| `outputs/tables/era_model_coefficients.csv` | Full logistic regression results per era |
| `outputs/tables/era_drift_summary.txt` | Human-readable text summary |
| `outputs/figures/era_drift/era_feature_trends.png` | Feature mean trends (3x3 grid) |
| `outputs/figures/era_drift/era_coefficient_drift.png` | Coefficient drift across eras |
| `outputs/figures/era_drift/era_counts.png` | Song count bar chart per era |
| `outputs/figures/era_drift/era_pvalue_heatmap.png` | P-value significance heatmap |
