# Step 3: Hypothesis Testing

> **Status: COMPLETE**

---

## What Is a Hypothesis Test?

A **hypothesis test** is a formal way to ask: *Is the difference I see in
the data real, or could it just be random chance?*

Every hypothesis test starts with two statements:

- **Null hypothesis (H₀):** There is NO difference between charted and
  non-charted songs on this audio feature. Any difference we see is just noise.

- **Alternative hypothesis (H₁):** There IS a real difference between charted
  and non-charted songs on this audio feature.

The test produces a **p-value** — the probability of seeing a difference this
large (or larger) by pure chance, *if H₀ were actually true*.

- **Small p-value (e.g., < 0.05):** The observed difference is unlikely to
  be random. We reject H₀.
- **Large p-value:** The observed difference could easily be random. We do NOT
  reject H₀.

---

## Why Welch's t-test?

A **two-sample t-test** compares the means of two groups — in our case,
charted songs versus non-charted songs.

We used the **Welch variant** (`var.equal = FALSE` in R), which is better when:

- The two groups have very different sizes (our groups are 3,618 vs 125,127)
- The two groups might have different variances

Welch's t-test adjusts its degrees of freedom to account for these differences.
It is still fundamentally a two-sample t-test — exactly what the proposal requires.

---

## Bonferroni Correction — Why It Matters

We are running **9 tests at once** (one per audio feature). If we use
alpha = 0.05 for each test separately, the chance of getting at least one
false positive by accident is much higher than 5%.

The **Bonferroni correction** fixes this by dividing the alpha threshold
by the number of tests:

```
Bonferroni alpha = 0.05 / 9 = 0.005556
```

A feature must have **p < 0.005556** to be considered significant after
Bonferroni correction. This is a stricter standard that controls for the
risk of false discoveries across multiple tests.

---

## Results

**Dataset:** `data/processed/spotify_billboard_analysis_clean.csv`  
**Charted songs (group 1):** 3618  
**Non-charted songs (group 0):** 125127  
**Bonferroni threshold:** 0.005556

| Feature | Mean (charted) | Mean (non-charted) | Difference | p-value | p (Bonferroni) | Significant? | Cohen's d |
|---------|---------------|-------------------|------------|---------|----------------|--------------|-----------|
| `danceability` | 0.6121 | 0.5785 | +0.0336 | 7.87e-43 | 0.00e+00 | Yes | +0.2157 (medium) |
| `energy` | 0.7040 | 0.6393 | +0.0647 | 4.15e-103 | 0.00e+00 | Yes | +0.3178 (medium) |
| `valence` | 0.5216 | 0.4982 | +0.0233 | 5.80e-10 | 0.00e+00 | Yes | +0.1010 (small) |
| `tempo` | 122.8969 | 119.1629 | +3.7340 | 2.12e-13 | 0.00e+00 | Yes | +0.1223 (small) |
| `loudness` | -5.8456 | -8.0428 | +2.1972 | 0.00e+00 | 0.00e+00 | Yes | +0.6599 (large) |
| `acousticness` | 0.1599 | 0.2621 | -0.1022 | 3.08e-173 | 0.00e+00 | Yes | -0.4008 (medium) |
| `speechiness` | 0.0942 | 0.1264 | -0.0323 | 6.30e-76 | 0.00e+00 | Yes | -0.2473 (medium) |
| `instrumentalness` | 0.0079 | 0.0630 | -0.0550 | 0.00e+00 | 0.00e+00 | Yes | -0.3728 (medium) |
| `liveness` | 0.1870 | 0.2531 | -0.0661 | 3.80e-140 | 0.00e+00 | Yes | -0.3427 (medium) |

**Features significant after Bonferroni correction:** `danceability`, `energy`, `valence`, `tempo`, `loudness`, `acousticness`, `speechiness`, `instrumentalness`, `liveness`

---

## Effect Sizes

**Cohen's d** measures the *practical size* of the difference:

| |d| range | Interpretation |
|-----------|----------------|
| < 0.2 | Small effect |
| 0.2 – 0.5 | Medium effect |
| > 0.5 | Large effect |

**Top 3 largest absolute effect sizes:**

1. `loudness` — d = +0.6599 (large)
2. `acousticness` — d = -0.4008 (medium)
3. `instrumentalness` — d = -0.3728 (medium)

---

## Important: Statistical Significance ≠ Practical Importance

This dataset has **128,745 rows**. With very large samples, even a tiny
difference in group means (e.g., 0.01 on a 0-to-1 scale) can produce a
very significant p-value.

**What this means in plain language:**

- A p-value below the Bonferroni threshold tells us the difference is *real*
  and not random — but it does NOT tell us the difference is *large* or
  *useful for prediction*.
- Cohen's d is the more informative number for judging practical relevance.
- A feature can be statistically significant but have near-zero Cohen's d,
  meaning the two groups are barely distinguishable in practice.

**We report both.** The combination of a significant p-value AND a medium-to-large
Cohen's d is the stronger evidence that a feature actually separates charted from
non-charted songs.

---

## What Was NOT Done

- No PCA
- No logistic regression
- No class balancing, undersampling, or oversampling
- No train-test split

These steps are reserved for future steps.

---

## What Happens Next

```
[STEP 3 COMPLETE] Hypothesis testing done.
  -> outputs/tables/hypothesis_test_results.csv
  -> outputs/tables/hypothesis_test_summary.txt

[STEP 4 — NEXT] Principal Component Analysis (PCA)
  -> Reduce the 9 audio features to principal components
  -> Visualize variance explained
```

*Analysis run: 2026-04-18 00:42:10*
