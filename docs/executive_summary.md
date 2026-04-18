# Executive Summary
## Predicting Billboard Hot 100 Chart Success from Spotify Audio Features

---

**Project Goal:** Determine whether Spotify audio features (loudness, danceability, energy, acousticness, etc.) can statistically distinguish songs that appeared on the Billboard Hot 100 chart (1999–2019) from songs that did not, and build a logistic regression classifier to quantify predictive performance.

---

**Dataset Used:** A merged dataset of 128,745 songs built from two Kaggle source tables (`billboardHot100_1999-2019.csv` + `songAttributes_1999-2019.csv`). The dataset is heavily imbalanced: only 3,618 songs (2.81%) are charted, with a 34.6:1 class ratio. This differs from the project proposal, which assumed a pre-balanced ~18,454-row dataset; the discrepancy arose from how the source tables were joined and is documented transparently throughout the project.

---

**Top 3 Findings:**

1. **Loudness is the strongest predictor.** Charted songs are on average 2.2 dB louder (Cohen's d = +0.660, large effect) and loudness has the most significant coefficient in logistic regression (p = 2.75e-54). Charted songs are more produced, louder, and less acoustic.

2. **All nine audio features are statistically significant, but effect sizes vary widely.** After Bonferroni correction, every feature showed a real difference between charted and non-charted songs. However, practical effect sizes ranged from large (loudness) to small (valence, tempo), reflecting that statistical significance at n = 128,745 does not always mean practical importance.

3. **Five principal components explain 80.5% of audio feature variance.** PCA revealed that PC1 — an axis contrasting loud/energetic music against acoustic/quiet music — shows moderate group separation (Cohen's d = 0.438), confirming that the audio feature space carries real structure aligned with chart success.

---

**Headline Model Result:** Logistic regression trained on a class-balanced subset achieved **AUC = 0.7281** on an untouched, real-world-imbalanced test set — within the project proposal's expected range of 0.70–0.80. The model correctly identified 76.3% of charted songs (recall = 0.763), at the cost of a high false-positive rate due to the 34.6:1 imbalance in the test set.

---

**One-Sentence Limitation:** The dataset excludes ~3,595 Billboard-charted songs that could not be matched to audio features (including major hits), and omits non-audio drivers of chart success such as artist fame, label support, and marketing.

---

**One-Sentence Conclusion:** Spotify audio features — particularly loudness, instrumentalness, and liveness — carry statistically significant and practically meaningful associations with Billboard chart success, and a logistic regression model using these features achieves good discriminative performance (AUC = 0.73), though audio features alone cannot fully account for the complex, multi-factor nature of commercial chart success.

---

*Full report: `docs/final_project_report.md`*  
*Date: 2026-04-18*
