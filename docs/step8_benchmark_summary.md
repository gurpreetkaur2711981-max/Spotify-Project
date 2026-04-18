# Step 8: Benchmark Suite Beyond Logistic Regression

> **Status: COMPLETE**

## Why use the enriched dataset here?

Phase 3 uses the enriched merged dataset because Step 6 recovered more confirmed charted songs.
That gives the modeling stage more positive examples than the older baseline file.
The older logistic model is still the reference point, but it is **not** reused for new training in this step.

## What changed versus the old baseline?

- Old baseline logistic dataset: `D:/SpotifyBillboardProject/data/processed/spotify_billboard_analysis_clean.csv`
- New Phase 3 source dataset: `D:/SpotifyBillboardProject/data/processed/spotify_billboard_merged_enriched_full.csv`
- Old baseline AUC: **0.7281**
- Enriched dataset charted songs: **4079** instead of **3618**

## Why balance only the training set?

The training set is balanced by random undersampling so the models are forced to learn both classes.
The test set stays untouched and imbalanced because that is the honest real-world evaluation setting.
If we balanced the test set too, the reported metrics would look better than real deployment conditions.

## What do ROC-AUC and PR-AUC mean?

- **ROC-AUC** measures how well a model ranks charted songs above non-charted songs across all thresholds.
- **PR-AUC** focuses more directly on positive-class retrieval, which matters here because charted songs are rare.

## Data and Split

- Random seed: **42**
- Clean enriched dataset rows: **128745**
- Train size before balancing: **90122**
- Train size after balancing: **5722**
- Test size: **38623**

## Models benchmarked

- Models run: Logistic Regression (Enriched), LDA, Random Forest, kNN, Decision Tree
- XGBoost skipped: xgboost not available.

## Benchmark results

| Model | ROC-AUC | PR-AUC | Accuracy | Precision | Recall | Specificity | F1 | Brier |
|------|--------:|-------:|---------:|----------:|-------:|------------:|---:|------:|
| Logistic Regression (Enriched) | 0.7242 | 0.0641 | 0.5825 | 0.0558 | 0.7685 | 0.5764 | 0.1040 | 0.2204 |
| LDA | 0.7228 | 0.0634 | 0.5483 | 0.0539 | 0.8054 | 0.5399 | 0.1011 | 0.2305 |
| Random Forest | 0.7200 | 0.0651 | 0.6138 | 0.0566 | 0.7184 | 0.6103 | 0.1050 | 0.2188 |
| kNN | 0.7063 | 0.0606 | 0.5223 | 0.0503 | 0.7906 | 0.5136 | 0.0945 | 0.2493 |
| Decision Tree | 0.6687 | 0.0512 | 0.5008 | 0.0489 | 0.8038 | 0.4909 | 0.0922 | 0.2287 |

## Plain-language interpretation

The enriched-data logistic model did not improve over the old baseline (0.7281 to 0.7242).
No benchmark model beat the enriched logistic baseline on ROC-AUC.
The best ROC-AUC model was **Logistic Regression (Enriched)** at **0.7242**.
The best PR-AUC result was **Random Forest (0.0651)** at **0.0651**.

In simple terms: logistic regression remains the easiest model to explain, but Phase 3 checks whether that simplicity leaves meaningful predictive performance on the table.
If a more flexible model only wins by a tiny margin, the extra complexity may not be worth it.

## Calibration caution

Brier scores are reported as a rough probability-error metric, but no recalibration step was applied.
Because the models were trained on balanced data and tested on the real imbalanced data, raw predicted probabilities should be interpreted cautiously.

## Major limitations

- The evaluation still depends only on the 9 audio features, so major non-audio drivers of chart success remain missing.
- The train/test split is random, not a time split, so this benchmark measures general discrimination rather than future-era forecasting.
- Some optional models were skipped if their packages were unavailable in the current environment.
- These models describe statistical association, not musical causation.

## Files created in Phase 3

- `data/processed/spotify_billboard_analysis_enriched_clean.csv`
- `data/processed/enriched_model_train_balanced.csv`
- `data/processed/enriched_model_test_full.csv`
- `outputs/tables/benchmark_model_comparison.csv`
- `outputs/tables/benchmark_model_notes.txt`
- `outputs/tables/benchmark_test_predictions_sample.csv`
- `outputs/tables/benchmark_roc_curves.csv`
- `outputs/tables/benchmark_pr_curves.csv`
- `outputs/figures/benchmark/benchmark_roc_curves.png`
- `outputs/figures/benchmark/benchmark_pr_curves.png`
- `outputs/figures/benchmark/benchmark_auc_barplot.png`
- `outputs/figures/benchmark/benchmark_prauc_barplot.png`

*Benchmark run: 2026-04-18 14:32:36*
