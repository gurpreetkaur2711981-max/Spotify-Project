# Step 10: Robustness Across Dataset Tiers

> **Status: COMPLETE**

## Why was this robustness analysis done?

This step tests whether the project's main findings depend too heavily on one specific dataset-construction choice.
That matters academically because a fair criticism of matching-based projects is:

> "These results are just from one arbitrary dataset construction."

The goal here is to answer that criticism with a transparent sensitivity check.

## What do the three tiers mean?

- **Tier 1: Baseline Conservative** = `D:/SpotifyBillboardProject/data/processed/spotify_billboard_analysis_clean.csv`
  This is the original exact/pass-1 matching dataset.
- **Tier 2: Full Enriched** = `D:/SpotifyBillboardProject/data/processed/spotify_billboard_analysis_enriched_clean.csv`
  This is the broader Step 6 dataset after all accepted enrichment passes.
- **Tier 3: High-Confidence Enriched (Passes 1-3 only)** = `D:/SpotifyBillboardProject/data/processed/spotify_billboard_analysis_high_confidence_clean.csv`
  This removes only the saved Pass 4 fuzzy-title recoveries and keeps the deterministic passes.

## Dataset structure by tier

| Tier | Total rows | Charted | Non-charted | Class ratio (0:1) |
|------|-----------:|--------:|------------:|------------------:|
| Tier 1: Baseline Conservative | 128745 | 3618 | 125127 | 34.5846 |
| Tier 2: Full Enriched | 128745 | 4079 | 124666 | 30.5629 |
| Tier 3: High-Confidence Enriched (Passes 1-3 only) | 128745 | 4073 | 124672 | 30.6094 |

## What changed across tiers?

- The conservative tier contains 3,618 charted songs.
- The high-confidence enriched tier contains 4,073 charted songs.
- The full enriched tier contains 4,079 charted songs.
- The only difference between the high-confidence and full enriched tiers is the 6 saved fuzzy Pass 4 recoveries.

## What stayed the same?

The mean-difference directions for all 9 audio features stayed the same across the three tiers.
The main logistic-regression predictor directions also survived across all three tiers.
PCA interpretation was stable, and in fact identical, because PCA uses only the audio features while the three tiers differ only in chart labels. PC1 still looked like an energy/loudness vs acousticness axis, and PC2 kept a similar danceability/valence/speechiness interpretation.
Logistic ROC-AUC stayed in a fairly narrow band across tiers: Tier 1: Baseline Conservative = 0.7281; Tier 2: Full Enriched = 0.7242; Tier 3: High-Confidence Enriched (Passes 1-3 only) = 0.7243.
PR-AUC also stayed in a similar range: Tier 1: Baseline Conservative = 0.0577; Tier 2: Full Enriched = 0.0641; Tier 3: High-Confidence Enriched (Passes 1-3 only) = 0.0640.

## Simple interpretation

The main conclusions were directionally robust across conservative, enriched, and high-confidence dataset tiers.

In practical terms, the main project story did **not** disappear when the dataset definition changed from conservative to broader matching, and it also did **not** depend only on the 6 least-strict fuzzy recoveries.

## Does the main predictor story survive?

The core direction remains that charted songs tend to be louder and less acoustic, less instrumental, and less live-seeming than non-charted songs.
That is exactly the kind of directional stability we want from a robustness check.

## Does logistic performance stay stable?

Yes, within a modest range. The AUC values do move somewhat across tiers, but they stay in the same general mid-0.7 region rather than collapsing.
That means the predictive signal is not just a one-tier artifact.

## Why does this strengthen the project academically?

Because it shows the findings are not resting on one fragile matching decision.
Instead, the main conclusions survive across a conservative dataset, a broader enriched dataset, and a stricter high-confidence version of the enriched dataset.

## Important caution

The high-confidence tier is only slightly narrower than the full enriched tier, because the saved fuzzy Pass 4 step added just 6 rows.
So this robustness analysis is real and useful, but it is still bounded by what the saved project files make reconstructable.

*Robustness run: 2026-04-18 15:26:20*
