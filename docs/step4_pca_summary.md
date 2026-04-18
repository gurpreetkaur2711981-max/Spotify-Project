# Step 4: Principal Component Analysis (PCA)

> **Status: COMPLETE**

---

## What Is PCA?

**Principal Component Analysis (PCA)** is a method for simplifying a dataset
with many variables by finding a smaller number of new variables — called
**principal components** — that capture most of the information.

Imagine you have 9 audio features per song, many of which are correlated.
For example, louder songs tend to be more energetic. PCA identifies the
directions in the data that explain the most variation, combining correlated
features into new composite dimensions so we can work with fewer numbers.

**Key facts about PCA:**
- It is **unsupervised** — it never looks at the `charted` column.
  The `charted` label is only attached *after* PCA for visualization.
- The components are ordered: PC1 explains the most variance, then PC2, and so on.
- Components are uncorrelated (orthogonal) with each other by construction.

---

## Why Standardization Was Necessary

The 9 audio features are on very different numeric scales:

| Feature | Typical range |
|---------|---------------|
| danceability, energy, valence, ... | 0 to 1 |
| tempo | 0 to ~250 BPM |
| loudness | −60 to ~0 dB |

Without standardization, PCA would be dominated by features with large raw
numbers (loudness, tempo), not because they are more important but simply
because they vary more in absolute terms.

We used `prcomp(center = TRUE, scale. = TRUE)`, which:
1. **Centers** each feature by subtracting its mean (mean → 0)
2. **Scales** each feature by dividing by its standard deviation (variance → 1)

After this transformation every feature contributes equally.

---

## Variance Explained by Each Component

| Component | Eigenvalue | Variance | Cumulative |
|-----------|-----------|----------|------------|
| PC1 | 2.6367 | 29.3% | 29.3% |
| PC2 | 1.5229 | 16.9% | 46.2% |
| PC3 | 1.1954 | 13.3% | 59.5% |
| PC4 | 0.9616 | 10.7% | 70.2% |
| PC5 | 0.9308 | 10.3% | 80.5% |
| PC6 | 0.7202 | 8.0% | 88.5% |
| PC7 | 0.4933 | 5.5% | 94.0% |
| PC8 | 0.3859 | 4.3% | 98.3% |
| PC9 | 0.1530 | 1.7% | 100.0% |

**Minimum PCs needed to reach ≥ 80% of total variance: 5 (PC1, PC2, PC3, PC4, PC5)**

The first 5 components together explain 80.5% of the structure
in the original 9 features. The remaining components add progressively less.

---

## PC Loadings (all components)

A **loading** is the correlation between an original feature and a principal
component. A large positive value means the feature points in the same
direction as the component; a large negative value means the opposite.

| Feature | PC1 | PC2 | PC3 | PC4 | PC5 | PC6 | PC7 | PC8 | PC9 |
|---------|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|
| `danceability` | -0.2614 | +0.5503 | -0.2664 | +0.1930 | -0.0178 | -0.0435 | +0.6353 | +0.2898 | +0.1753 |
| `energy` | -0.5412 | -0.2120 | +0.1335 | +0.0987 | -0.1041 | -0.0064 | -0.2540 | +0.0706 | +0.7445 |
| `valence` | -0.3163 | +0.4486 | -0.0498 | +0.0858 | +0.2122 | -0.5962 | -0.4356 | -0.2369 | -0.2063 |
| `tempo` | -0.1598 | -0.2669 | -0.0168 | -0.0754 | +0.9267 | +0.0457 | +0.1800 | +0.0629 | +0.0062 |
| `loudness` | -0.5105 | -0.1863 | -0.0196 | -0.2220 | -0.1771 | +0.0661 | -0.1167 | +0.5870 | -0.5109 |
| `acousticness` | +0.4871 | +0.1814 | +0.0643 | -0.1593 | +0.1436 | -0.2588 | -0.2797 | +0.6780 | +0.2735 |
| `speechiness` | -0.0491 | +0.4477 | +0.4810 | +0.2879 | +0.1673 | +0.6137 | -0.2528 | +0.0711 | -0.0969 |
| `instrumentalness` | +0.1125 | -0.3105 | -0.1953 | +0.8788 | +0.0090 | -0.1101 | -0.0941 | +0.2006 | -0.1390 |
| `liveness` | -0.0145 | -0.1237 | +0.7965 | +0.1008 | -0.0704 | -0.4248 | +0.3809 | +0.0375 | -0.0891 |

---

## What Do PC1 and PC2 Represent?

### PC1
- Strongest **positive** loading: `acousticness` (+0.4871)
- Strongest **negative** loading: `energy` (-0.5412)
- Explains **29.3%** of total variance

Songs with high PC1 scores tend to score high on the positively-loading
features and low on the negatively-loading ones. This component captures a
**production intensity** axis — the contrast between loud, energetic, produced
music at one end and quiet, acoustic music at the other.

### PC2
- Strongest **positive** loading: `danceability` (+0.5503)
- Strongest **negative** loading: `instrumentalness` (-0.3105)
- Explains **16.9%** of total variance

PC2 is orthogonal to PC1 and captures a different musical dimension.
It reflects a contrast between features that PC1 did not fully separate.

---

## Do Charted and Non-Charted Songs Separate in PC Space?

| | PC1 mean | PC2 mean |
|---|---|---|
| Charted (n=3,618) | -0.6909 | -0.0681 |
| Non-charted (n=125,127) | 0.0200 | 0.0020 |

**Effect size in PC1:** |d| = 0.438  |  **Effect size in PC2:** |d| = 0.057

**Verdict: The two groups separate **a little** in PC1/PC2 space.**

This is expected — PCA finds the directions of maximum overall variance, not
the direction that best separates two classes. Some shift is visible because
features that differ between charted and non-charted songs (loudness,
acousticness, instrumentalness) load heavily on PC1. However, the distributions
overlap substantially. PCA alone cannot reliably classify a song.

---

## Does PCA Reveal Meaningful Structure?

Yes. The fact that only 5 components are needed to capture 80.5% of the variance means the 9 audio
features are **not independent** — they share real correlation structure.
PCA successfully compresses this into fewer dimensions without major information loss.

The clear interpretation of PC1 as a production-intensity axis is consistent
with decades of musicology research showing that loud/energetic music and
acoustic/quiet music form a fundamental spectrum in popular music.

---

## What Was NOT Done

- No logistic regression
- No class balancing, undersampling, or oversampling
- No train-test split

---

## Output Files

| File | Contents |
|------|----------|
| `outputs/tables/pca_explained_variance.csv` | Eigenvalues and variance per PC |
| `outputs/tables/pca_loadings.csv` | Feature loadings on all 9 PCs |
| `outputs/tables/pca_scores_pc1_pc2.csv` | PC1 and PC2 scores for all 128,745 songs |
| `outputs/figures/pca/pca_scree_plot.png` | Bar chart of variance per PC |
| `outputs/figures/pca/pca_cumulative_variance.png` | Cumulative variance line plot |
| `outputs/figures/pca/pca_pc1_vs_pc2_by_charted.png` | PC1 vs PC2 scatter by group |
| `outputs/figures/pca/pca_loading_plot_pc1_pc2.png` | Feature loading arrows |

---

## What Happens Next

```
[STEP 4 COMPLETE] PCA done.

[STEP 5 — NEXT] Logistic Regression
  -> Use the 9 audio features to predict charted (0/1)
  -> Address class imbalance before modeling
  -> Report classification metrics
```

*Analysis run: 2026-04-18 12:32:36*
