export const siteMeta = {
  title: "Signals of Success",
  kicker: "Spotify audio features × Billboard chart outcomes",
  hook: "A premium analytics story about what makes a chart profile, what changed across eras, and why simpler models still won.",
  subcopy:
    "This project turned a messy multi-table Kaggle download into an end-to-end music analytics product: merge logic, safer enrichment, predictive modeling, era drift analysis, benchmarking, and robustness testing.",
};

export const navItems = [
  { label: "Overview", href: "#overview" },
  { label: "Pipeline", href: "#pipeline" },
  { label: "Findings", href: "#findings" },
  { label: "Models", href: "#dashboard" },
  { label: "Era Drift", href: "#era-drift" },
  { label: "Robustness", href: "#robustness" },
  { label: "Explorer", href: "#explorer" },
  { label: "Methodology", href: "#methodology" },
];

export const heroMetrics = [
  {
    label: "Validated Logistic AUC",
    value: "0.7281",
    detail: "Baseline model on untouched imbalanced test data",
  },
  {
    label: "Songs Analyzed",
    value: "128,745",
    detail: "Merged from Spotify attributes and Billboard history",
  },
  {
    label: "Charted Songs After Enrichment",
    value: "4,079",
    detail: "Recovered from safer multi-pass matching",
  },
  {
    label: "Variance Explained By 5 PCs",
    value: "80.5%",
    detail: "Audio space compresses cleanly without losing the main story",
  },
];

export const storyCards = [
  {
    eyebrow: "Research Question",
    title: "Can audio DNA predict chart outcomes?",
    text:
      "The project asks whether Spotify's audio features carry enough signal to distinguish songs that appeared on the Billboard Hot 100 from songs that did not.",
  },
  {
    eyebrow: "Why It Matters",
    title: "This became a product problem, not just a homework exercise.",
    text:
      "The raw Kaggle download was not a ready-made analysis table. The hard part became data integration, match safety, enrichment, benchmarking, and proving the results were not artifacts of one fragile construction choice.",
  },
  {
    eyebrow: "Real-World Strength",
    title: "The messy join is part of the story.",
    text:
      "Instead of hiding the merge challenge, the site treats it as a strength: conservative matching, enrichment, high-confidence sensitivity checks, and honest discussion of what the project can and cannot claim.",
  },
];

export const pipelineSteps = [
  {
    phase: "Raw Inputs",
    title: "Source Tables",
    text:
      "Two separate tables arrived from Kaggle: Billboard chart history and Spotify song attributes. Nothing was pre-joined.",
  },
  {
    phase: "Data Engineering",
    title: "Conservative Merge",
    text:
      "The first merged dataset used cleaned title plus primary artist exact matching to avoid false positives.",
  },
  {
    phase: "Quality Pass",
    title: "Light Cleaning",
    text:
      "Columns were typed safely, binary fields were normalized, and ranges were checked without deleting rows unnecessarily.",
  },
  {
    phase: "Insight Layer",
    title: "EDA + Hypothesis Tests",
    text:
      "Distribution shifts, effect sizes, and feature directionality were validated before any model was treated seriously.",
  },
  {
    phase: "Structure",
    title: "PCA",
    text:
      "Principal components tested whether the feature space had a compact underlying geometry aligned with chart success.",
  },
  {
    phase: "Prediction",
    title: "Logistic Baseline",
    text:
      "A class-balanced training subset and untouched test set produced the core interpretable model.",
  },
  {
    phase: "Matching Upgrade",
    title: "Safer Enrichment",
    text:
      "Normalization and tiny fuzzy recovery passes raised matched charted songs from 3,618 to 4,079 without resorting to risky cross-artist matching.",
  },
  {
    phase: "Temporal Layer",
    title: "Era Drift",
    text:
      "Because non-charted songs lacked trustworthy year labels, the project used a chart-only top-10-by-era fallback instead of inventing time information.",
  },
  {
    phase: "Model Defense",
    title: "Benchmark Suite",
    text:
      "The enriched dataset tested whether LDA, kNN, decision trees, and random forest could materially beat logistic regression.",
  },
  {
    phase: "Professor-Proof",
    title: "Robustness Tiers",
    text:
      "Conservative, enriched, and high-confidence tiers were compared to show the main story survives changes in dataset construction.",
  },
];

export const figurePaths = {
  classBalance: "./assets/analysis/eda/charted_class_balance.png",
  loudnessBox: "./assets/analysis/eda/boxplot_loudness_by_charted.png",
  acousticnessBox: "./assets/analysis/eda/boxplot_acousticness_by_charted.png",
  pcaVariance: "./assets/analysis/pca/pca_cumulative_variance.png",
  pcaLoadings: "./assets/analysis/pca/pca_loading_plot_pc1_pc2.png",
  pcaScatter: "./assets/analysis/pca/pca_pc1_vs_pc2_by_charted.png",
  logisticRoc: "./assets/analysis/logistic/logistic_roc_curve.png",
  logisticHist: "./assets/analysis/logistic/logistic_predicted_probability_histogram.png",
  benchmarkAuc: "./assets/analysis/benchmark/benchmark_auc_barplot.png",
  benchmarkPr: "./assets/analysis/benchmark/benchmark_pr_curves.png",
  eraTrend: "./assets/analysis/era_drift/era_feature_trends.png",
  eraCoefficient: "./assets/analysis/era_drift/era_coefficient_drift.png",
  eraCounts: "./assets/analysis/era_drift/era_counts.png",
  robustnessAuc: "./assets/analysis/robustness/robustness_auc_comparison.png",
  robustnessEffects: "./assets/analysis/robustness/robustness_effect_size_comparison.png",
  robustnessSigns: "./assets/analysis/robustness/robustness_coefficient_signs.png",
};

export const edaHighlights = [
  {
    title: "Loudness is the clearest separation signal.",
    text:
      "Charted songs are about 2.2 dB louder on average, and loudness carries the largest practical effect size in the original hypothesis test results.",
  },
  {
    title: "Acousticness, instrumentalness, and liveness move the other way.",
    text:
      "The charted profile is less acoustic, less instrumental, and less live-seeming. Those directions survive in the statistical tests, the logistic model, and the robustness study.",
  },
];

export const hypothesisFeatures = [
  { feature: "loudness", diff: 2.1972, effect: 0.6599, direction: "positive" },
  { feature: "acousticness", diff: -0.1022, effect: -0.4008, direction: "negative" },
  { feature: "instrumentalness", diff: -0.0550, effect: -0.3728, direction: "negative" },
  { feature: "liveness", diff: -0.0661, effect: -0.3427, direction: "negative" },
  { feature: "energy", diff: 0.0647, effect: 0.3178, direction: "positive" },
  { feature: "speechiness", diff: -0.0323, effect: -0.2473, direction: "negative" },
  { feature: "danceability", diff: 0.0336, effect: 0.2157, direction: "positive" },
  { feature: "tempo", diff: 3.7340, effect: 0.1223, direction: "positive" },
  { feature: "valence", diff: 0.0233, effect: 0.1010, direction: "positive" },
];

export const pcaSummary = {
  fivePcVariance: 0.805281,
  pc1Story:
    "PC1 contrasts louder, more energetic music against more acoustic tracks. It is the dominant structural axis in the feature space.",
  pc2Story:
    "PC2 is anchored by danceability, valence, and speechiness, adding a second dimension that feels closer to vibe, delivery, and movement.",
};

export const logisticModel = {
  auc: 0.7281,
  precision: 0.0499,
  recall: 0.7629,
  f1: 0.0938,
  specificity: 0.5809,
  confusion: {
    tp: 827,
    fp: 15731,
    fn: 257,
    tn: 21808,
  },
  note:
    "The model was trained on a balanced subset but judged on the original imbalanced test set, which is why the score is useful for ranking while the raw 0.50 threshold is not perfectly calibrated.",
};

export const benchmarkModels = [
  {
    model: "Logistic Regression (Enriched)",
    rocAuc: 0.7242,
    prAuc: 0.0641,
    accuracy: 0.5825,
    precision: 0.0558,
    recall: 0.7685,
    note: "Best overall balance of interpretability and ROC-AUC.",
  },
  {
    model: "LDA",
    rocAuc: 0.7228,
    prAuc: 0.0634,
    accuracy: 0.5483,
    precision: 0.0539,
    recall: 0.8054,
    note: "Close, but not better enough to change the story.",
  },
  {
    model: "Random Forest",
    rocAuc: 0.72,
    prAuc: 0.0651,
    accuracy: 0.6138,
    precision: 0.0566,
    recall: 0.7184,
    note: "Best PR-AUC, but not a material ROC-AUC improvement.",
  },
  {
    model: "kNN",
    rocAuc: 0.7063,
    prAuc: 0.0606,
    accuracy: 0.5223,
    precision: 0.0503,
    recall: 0.7906,
    note: "More complex deployment story without enough upside.",
  },
  {
    model: "Decision Tree",
    rocAuc: 0.6687,
    prAuc: 0.0512,
    accuracy: 0.5008,
    precision: 0.0489,
    recall: 0.8038,
    note: "Simpler visually, weaker statistically.",
  },
];

export const enrichmentSummary = {
  baselineCharted: 3618,
  enrichedCharted: 4079,
  recovered: 461,
  passes: [
    { label: "Pass 1 exact", value: 3618 },
    { label: "Pass 2 title normalization", value: 424 },
    { label: "Pass 3 artist normalization", value: 0 },
    { label: "Pass 4 tiny fuzzy recovery", value: 6 },
  ],
};

export const eraDrift = {
  conclusion:
    "The project now frames the result as moderate evidence of drift rather than proof of a completely rewritten success formula.",
  caution:
    "Later-era coverage is weaker, and the 2015-2019 era has relatively few modeled top-10 songs, so those coefficients need more caution.",
  counts: [
    { era: "1999-2002", matched: 712, top10: 147 },
    { era: "2003-2006", matched: 903, top10: 165 },
    { era: "2007-2010", matched: 1022, top10: 168 },
    { era: "2011-2014", matched: 783, top10: 123 },
    { era: "2015-2019", matched: 659, top10: 85 },
  ],
  takeaways: [
    "Chart-era modeling had to switch to a chart-only top-10 prediction problem because non-charted songs do not carry trustworthy years in the saved dataset.",
    "Feature means and era-specific coefficients suggest some change over time, especially in how danceability, energy, and valence relate to within-chart success.",
    "The interpretation is intentionally cautious, especially in the latest era.",
  ],
};

export const robustness = {
  conclusion:
    "The main conclusions were directionally robust across conservative, enriched, and high-confidence dataset tiers.",
  tiers: [
    {
      name: "Baseline Conservative",
      charted: 3618,
      classRatio: 34.5846,
      rocAuc: 0.7281,
      prAuc: 0.0577,
    },
    {
      name: "Full Enriched",
      charted: 4079,
      classRatio: 30.5629,
      rocAuc: 0.7242,
      prAuc: 0.0641,
    },
    {
      name: "High-Confidence Enriched",
      charted: 4073,
      classRatio: 30.6094,
      rocAuc: 0.7243,
      prAuc: 0.064,
    },
  ],
  note:
    "The high-confidence tier is only slightly narrower than full enrichment because the saved fuzzy Pass 4 auto-recovery affected just 6 rows. That still makes it a real sensitivity check, just not a dramatic reconstruction.",
};

export const methodology = {
  tools: ["R", "base R", "Welch t-tests", "PCA", "logistic regression", "random undersampling", "matching enrichment", "robustness tiers"],
  honesty:
    "This project makes association claims, not causal claims. It also documents selection bias from songs that never matched to Spotify attributes and the limitations of audio-only prediction.",
  limitation:
    "The estimator and classifiers only see audio features. They do not know about release timing, artist fame, marketing, label support, playlisting, or cultural context.",
};

export const featureControls = [
  { key: "danceability", label: "Danceability", min: 0, max: 1, step: 0.01, defaultValue: 0.61, description: "How movement-friendly the track feels." },
  { key: "energy", label: "Energy", min: 0, max: 1, step: 0.01, defaultValue: 0.7, description: "Perceived intensity and drive." },
  { key: "valence", label: "Valence", min: 0, max: 1, step: 0.01, defaultValue: 0.52, description: "How positive or bright the mood feels." },
  { key: "tempo", label: "Tempo", min: 60, max: 200, step: 1, defaultValue: 123, description: "Estimated beats per minute." },
  { key: "loudness", label: "Loudness", min: -20, max: 0, step: 0.1, defaultValue: -5.8, description: "Overall loudness in decibels." },
  { key: "acousticness", label: "Acousticness", min: 0, max: 1, step: 0.01, defaultValue: 0.16, description: "Confidence that the track is acoustic." },
  { key: "speechiness", label: "Speechiness", min: 0, max: 1, step: 0.01, defaultValue: 0.09, description: "How speech-heavy the vocal delivery is." },
  { key: "instrumentalness", label: "Instrumentalness", min: 0, max: 1, step: 0.01, defaultValue: 0.01, description: "Likelihood that the track lacks vocals." },
  { key: "liveness", label: "Liveness", min: 0, max: 1, step: 0.01, defaultValue: 0.19, description: "How live or audience-present the track feels." },
];

export const chartedMeans = {
  danceability: 0.612116,
  energy: 0.703996,
  valence: 0.521572,
  tempo: 122.896858,
  loudness: -5.845648,
  acousticness: 0.159915,
  speechiness: 0.09418,
  instrumentalness: 0.007945,
  liveness: 0.187026,
};

export const nonChartedMeans = {
  danceability: 0.578471,
  energy: 0.639298,
  valence: 0.498239,
  tempo: 119.162899,
  loudness: -8.042827,
  acousticness: 0.262076,
  speechiness: 0.126431,
  instrumentalness: 0.062957,
  liveness: 0.253145,
};

export const baselineLogisticCoefficients = {
  intercept: 2.918037,
  danceability: 1.193568,
  energy: -1.532425,
  valence: -0.560323,
  tempo: 0.003355,
  loudness: 0.284107,
  acousticness: -0.967987,
  speechiness: -1.85651,
  instrumentalness: -3.31686,
  liveness: -1.574536,
};
