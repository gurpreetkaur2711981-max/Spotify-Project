# Step 5: Logistic Regression

> **Status: COMPLETE**

---

## What Is Logistic Regression?

**Logistic regression** is a statistical model for predicting a binary outcome
(0 or 1). Here the outcome is `charted` — did a song appear on the Billboard Hot 100?

Instead of predicting a number directly, logistic regression produces a
**probability between 0 and 1** for each song. A song is classified as charted
if that probability is above a chosen threshold (we use 0.50).

The model learns which direction each audio feature pushes the probability up or
down. Those learned weights are the **coefficients**. Taking e^(coefficient) gives
the **odds ratio** — how much the odds of charting multiply for a one-unit
increase in that feature.

---

## Why Balance the Training Set But Not the Test Set?

Only 2.8% of songs in our dataset charted. If we train on this raw imbalance,
the model learns to predict everything as non-charted — that still gives 97.2%
accuracy but is useless. We fix this with **random undersampling**:

- Remove majority-class rows (charted=0) in the training set until both classes
  are equal in size.
- This forces the model to learn what separates charted from non-charted songs.

**The test set is never touched.** It keeps the real 2.8% / 97.2% split so our
evaluation metrics (especially precision) reflect real-world conditions.

| Set | Total rows | charted=1 | charted=0 |
|-----|-----------|-----------|-----------|
| Full train set | 90122 | 2534 | 87588 |
| **Balanced train (used for fitting)** | **5068** | **2534** | **2534** |
| Test set (untouched) | 38623 | 1084 | 37539 |

---

## Model Coefficients

**Formula:** `charted ~ danceability + energy + valence + tempo + loudness + `  
**Formula:** `    acousticness + speechiness + instrumentalness + liveness`  
**Trained on:** balanced training set (50/50)  
**Random seed:** 42

| Predictor | Estimate | Std Error | z | p-value | Odds Ratio | Sig |
|-----------|----------|-----------|---|---------|------------|-----|
| `(Intercept)` | +2.9180 | 0.3676 | 7.94 | 2.050e-15 | 18.5049 | \*\*\* |
| `danceability` | +1.1936 | 0.2514 | 4.75 | 2.051e-06 | 3.2988 | \*\*\* |
| `energy` | -1.5324 | 0.3006 | -5.10 | 3.443e-07 | 0.2160 | \*\*\* |
| `valence` | -0.5603 | 0.1700 | -3.30 | 9.781e-04 | 0.5710 | \*\*\* |
| `tempo` | +0.0034 | 0.0011 | 3.18 | 1.479e-03 | 1.0034 | \*\* |
| `loudness` | +0.2841 | 0.0183 | 15.51 | 2.750e-54 | 1.3286 | \*\*\* |
| `acousticness` | -0.9680 | 0.1726 | -5.61 | 2.032e-08 | 0.3798 | \*\*\* |
| `speechiness` | -1.8565 | 0.2897 | -6.41 | 1.473e-10 | 0.1562 | \*\*\* |
| `instrumentalness` | -3.3169 | 0.3915 | -8.47 | 2.416e-17 | 0.0363 | \*\*\* |
| `liveness` | -1.5745 | 0.1842 | -8.55 | 1.237e-17 | 0.2071 | \*\*\* |

**Significance:** `***` p<0.001  `**` p<0.01  `*` p<0.05

> **Important:** Coefficients come from a model trained on undersampled
> (balanced) data. Odds ratios describe effect directions and magnitudes
> in that balanced training context, not the full population. Predicted
> probabilities are not recalibrated for the real-world 2.8% base rate.

---

## What Is AUC?

**AUC** (Area Under the ROC Curve) measures how well the model **ranks** charted
songs above non-charted songs, across all possible classification thresholds.

| AUC value | Meaning |
|-----------|---------|
| 1.00 | Perfect — charted songs always get higher probabilities |
| 0.50 | No better than random guessing |
| 0.70–0.80 | Good discrimination |

Our model achieved **AUC = 0.7281**, which is **within** the proposal's expected 0.70–0.80 range.

AUC is computed on the **untouched, imbalanced test set** and is the primary
metric for this project. It is threshold-independent.

---

## Confusion Matrix (threshold = 0.50)

| | Predicted charted | Predicted non-charted |
|---|---|---|
| **Actually charted** | TP = 827 | FN = 257 |
| **Actually non-charted** | FP = 15731 | TN = 21808 |

| Metric | Value | What it means |
|--------|-------|---------------|
| Accuracy | 0.5860 | % of all predictions correct (misleading with imbalance) |
| Precision | 0.0499 | Of songs predicted to chart, this fraction actually did |
| Recall | 0.7629 | Of songs that charted, this fraction was correctly found |
| Specificity | 0.5809 | Of non-charted songs, this fraction was correctly identified |
| F1 Score | 0.0938 | Harmonic mean of precision and recall |

> **Why accuracy is misleading here:** A trivial rule of 'always predict
> non-charted' achieves 97.2% accuracy but finds zero charted songs.
> Recall and AUC are more honest measures of performance on this problem.

---

## Strongest Predictors

### By statistical significance (smallest p-value):

1. `loudness`  (p = 2.750e-54,  estimate = +0.2841,  OR = 1.3286)
2. `liveness`  (p = 1.237e-17,  estimate = -1.5745,  OR = 0.2071)
3. `instrumentalness`  (p = 2.416e-17,  estimate = -3.3169,  OR = 0.0363)
4. `speechiness`  (p = 1.473e-10,  estimate = -1.8565,  OR = 0.1562)
5. `acousticness`  (p = 2.032e-08,  estimate = -0.9680,  OR = 0.3798)

### By absolute coefficient size:

1. `instrumentalness`  (estimate = -3.3169,  OR = 0.0363)
2. `speechiness`  (estimate = -1.8565,  OR = 0.1562)
3. `liveness`  (estimate = -1.5745,  OR = 0.2071)
4. `energy`  (estimate = -1.5324,  OR = 0.2160)
5. `danceability`  (estimate = +1.1936,  OR = 3.2988)

---

## Consistency with Earlier Steps

The logistic regression results are consistent with EDA, hypothesis testing,
and PCA:

- **EDA (Step 2):** Charted songs had visibly higher loudness and lower
  acousticness. The regression coefficients point in the same directions.
- **Hypothesis testing (Step 3):** Loudness had the largest effect size
  (d=+0.66), acousticness the second largest (d=−0.40). These are typically
  among the strongest predictors in the model.
- **PCA (Step 4):** PC1 captured a loudness/energy vs. acousticness axis and
  showed the most group separation (|d|=0.44). Features that dominated PC1
  are the same ones the logistic model weights heavily.

---

## Limitations

- **Undersampled training data:** The model was fitted on a 50/50 balanced set.
  Its predicted probabilities are not calibrated for a 2.8% real-world base rate.
  At threshold=0.50, recall will typically exceed precision on the imbalanced
  test set — this is expected behavior, not a bug.
- **Selection bias:** Only 3,618 of 7,213 Billboard songs matched to audio
  features. Missing songs may have different profiles, biasing the training data.
- **Linearity assumption:** Logistic regression assumes log-odds varies linearly
  with each feature. Non-linear patterns between features and chart success are
  not captured.
- **Missing confounders:** Marketing, artist fame, label support, and release
  timing are powerful drivers of chart success but are absent from the model.
- **Association, not causation:** A significant coefficient does not imply that
  changing a song's loudness will cause it to chart.

---

## Output Files

| File | Contents |
|------|----------|
| `data/processed/spotify_billboard_model_train_balanced.csv` | Balanced training set |
| `data/processed/spotify_billboard_model_test_full.csv` | Full test set (untouched) |
| `outputs/tables/logistic_regression_coefficients.csv` | Coefficient table with odds ratios |
| `outputs/tables/logistic_test_predictions.csv` | Test-set predictions and probabilities |
| `outputs/tables/logistic_model_summary.txt` | Full performance summary |
| `outputs/tables/logistic_roc_points.csv` | ROC curve data points |
| `outputs/figures/logistic/logistic_roc_curve.png` | ROC curve plot |
| `outputs/figures/logistic/logistic_predicted_probability_histogram.png` | Probability distributions |

---

## Project Complete

```
[STEP 5 COMPLETE] Logistic regression done.

All four analysis steps are complete:
  Step 2  — Exploratory Data Analysis (EDA)
  Step 3  — Hypothesis Testing (Welch t-tests + Bonferroni)
  Step 4  — Principal Component Analysis (PCA)
  Step 5  — Logistic Regression (with undersampling + AUC evaluation)
```

*Analysis run: 2026-04-18 12:40:50*
