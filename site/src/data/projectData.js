export const siteMeta = {
  title: "Signals of Success",
  kicker: "Can you hear whether a song is likely to become a hit?",
  hook:
    "This project asks a simple question: if we only know how a song sounds on Spotify, can we tell whether it has the kind of profile that reaches the Billboard Hot 100?",
  subcopy:
    "To answer that, I connected Spotify audio features with Billboard hit history, built the dataset myself, compared hit songs with non-hit songs, tested broader sound patterns, built prediction models, and checked whether the conclusions still held up over time and across stricter versions of the data.",
};

export const navItems = [
  { label: "Overview", href: "#overview" },
  { label: "Data Story", href: "#pipeline" },
  { label: "Findings", href: "#findings" },
  { label: "Models", href: "#dashboard" },
  { label: "Era Story", href: "#era-drift" },
  { label: "Trust Check", href: "#robustness" },
  { label: "Explorer", href: "#explorer" },
  { label: "Why It Matters", href: "#methodology" },
];

export const heroMetrics = [
  {
    label: "Baseline hit-ranking score",
    value: "0.7281",
    detail: "How well the main model separated chart songs from non-chart songs",
  },
  {
    label: "Songs in the final study",
    value: "128,745",
    detail: "Spotify and Billboard records joined into one analysis dataset",
  },
  {
    label: "Confirmed chart songs after safer matching",
    value: "4,079",
    detail: "+461 more true chart songs recovered without risky shortcuts",
  },
  {
    label: "Sound patterns captured in 5 broad components",
    value: "80.5%",
    detail: "Most of the audio story could be summarized without losing the main signal",
  },
];

export const storyCards = [
  {
    eyebrow: "What was the problem?",
    title: "Can a song's sound hint at chart success?",
    text:
      "I wanted to test whether the way a song sounds - louder, more acoustic, more danceable, more instrumental, and so on - says anything useful about whether it reaches the Billboard Hot 100.",
  },
  {
    eyebrow: "Why should anyone care?",
    title: "Because music decisions are emotional and commercial at the same time.",
    text:
      "Artists, labels, marketers, and streaming platforms all care about what resonates. Data cannot write a hit song, but it can reveal patterns that help creative and business decisions.",
  },
  {
    eyebrow: "What data did I use?",
    title: "Spotify described the sound. Billboard recorded the outcome.",
    text:
      "Spotify gave the audio fingerprints of songs. Billboard showed which songs actually became hits. Putting those two worlds together was the foundation of the whole project.",
  },
  {
    eyebrow: "What made it hard?",
    title: "Those two worlds did not come neatly joined together.",
    text:
      "Before any model could be trusted, I had to clean names, match artists carefully, avoid bad links, and improve coverage without weakening the rules.",
  },
  {
    eyebrow: "What did I actually do?",
    title: "I built the dataset, tested patterns, and trained prediction models.",
    text:
      "I compared hit songs with non-hit songs, looked for broader sound patterns, built models to predict charting, tested stronger alternatives, and checked whether the story stayed stable across different versions of the data.",
  },
  {
    eyebrow: "Why is the project strong?",
    title: "The conclusions were challenged from several angles.",
    text:
      "This was not one lucky chart or one easy file. The project includes safer enrichment, benchmarking, era analysis, and robustness checks so the conclusions are supported from several directions.",
  },
];

export const pipelineSteps = [
  {
    phase: "Question",
    title: "Define the target",
    text:
      "The central prediction question was simple: can audio features help separate songs that charted from songs that did not?",
  },
  {
    phase: "Data",
    title: "Bring the sources together",
    text:
      "Spotify supplied song features. Billboard supplied real hit outcomes. I had to connect those records song by song.",
  },
  {
    phase: "Cleaning",
    title: "Make the records trustworthy",
    text:
      "Names, types, and binary fields were cleaned so the comparisons would not be distorted by formatting problems.",
  },
  {
    phase: "Comparison",
    title: "Compare hit songs with non-hit songs",
    text:
      "Before any machine learning, I checked whether chart songs and non-chart songs already looked different in meaningful ways.",
  },
  {
    phase: "Pattern Finding",
    title: "Reduce many features into broader sound patterns",
    text:
      "This helped answer whether several audio traits were really pointing to the same bigger story about how hit songs tend to sound.",
  },
  {
    phase: "Prediction",
    title: "Build a hit vs non-hit model",
    text:
      "I trained a simple model to see whether sound alone could meaningfully rank likely chart songs above non-chart songs.",
  },
  {
    phase: "Data Upgrade",
    title: "Recover more confirmed hit songs safely",
    text:
      "I improved matching carefully so the project used more true chart songs without relying on risky guesses or cross-artist matches.",
  },
  {
    phase: "Time Question",
    title: "Check whether the sound of success changed over time",
    text:
      "I tested whether the traits linked with success stayed stable from 1999 to 2019 or drifted as music trends changed.",
  },
  {
    phase: "Model Challenge",
    title: "See if more complex models really helped",
    text:
      "I compared the simple model with several stronger alternatives to see whether extra complexity actually improved performance.",
  },
  {
    phase: "Trust Check",
    title: "Test whether the story survived dataset changes",
    text:
      "I reran the main ideas across conservative, enriched, and high-confidence tiers so the conclusions would not depend on one convenient dataset.",
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
    title: "Hit songs tended to be louder.",
    text:
      "Across the dataset, charted songs were noticeably louder on average. Loudness turned out to be the clearest single difference between hits and non-hits.",
  },
  {
    title: "Hit songs were usually less acoustic and less instrumental.",
    text:
      "Songs that charted tended to be less acoustic, less instrumental, and less live-seeming. That same direction kept showing up across several parts of the project.",
  },
  {
    title: "Several smaller clues lined up in the same direction.",
    text:
      "Danceability, energy, and tempo also leaned toward chart success, which suggested there was enough signal to try a real prediction model.",
  },
];

export const hypothesisFeatures = [
  { feature: "loudness", diff: 2.1972, effect: 0.6599, direction: "positive" },
  { feature: "acousticness", diff: -0.1022, effect: -0.4008, direction: "negative" },
  { feature: "instrumentalness", diff: -0.055, effect: -0.3728, direction: "negative" },
  { feature: "liveness", diff: -0.0661, effect: -0.3427, direction: "negative" },
  { feature: "energy", diff: 0.0647, effect: 0.3178, direction: "positive" },
  { feature: "speechiness", diff: -0.0323, effect: -0.2473, direction: "negative" },
  { feature: "danceability", diff: 0.0336, effect: 0.2157, direction: "positive" },
  { feature: "tempo", diff: 3.734, effect: 0.1223, direction: "positive" },
  { feature: "valence", diff: 0.0233, effect: 0.101, direction: "positive" },
];

export const pcaSummary = {
  fivePcVariance: 0.805281,
  pc1Story:
    "When I compressed many audio features into a few bigger sound patterns, the strongest pattern separated loud, energetic songs from quieter, more acoustic ones.",
  pc2Story:
    "A second pattern was tied more closely to danceability, valence, and speechiness, which feels closer to vibe, delivery, and movement.",
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
    "Think of the AUC here as a ranking score. It tells us the model could meaningfully place real chart songs above non-chart songs, even though audio alone cannot explain everything.",
};

export const benchmarkModels = [
  {
    model: "Logistic Regression (Enriched)",
    rocAuc: 0.7242,
    prAuc: 0.0641,
    accuracy: 0.5825,
    precision: 0.0558,
    recall: 0.7685,
    note: "Best overall mix of performance, clarity, and explainability.",
  },
  {
    model: "LDA",
    rocAuc: 0.7228,
    prAuc: 0.0634,
    accuracy: 0.5483,
    precision: 0.0539,
    recall: 0.8054,
    note: "Very close to logistic, but not clearly better.",
  },
  {
    model: "Random Forest",
    rocAuc: 0.72,
    prAuc: 0.0651,
    accuracy: 0.6138,
    precision: 0.0566,
    recall: 0.7184,
    note: "Won one harder metric slightly, but not enough to replace the simpler baseline.",
  },
  {
    model: "kNN",
    rocAuc: 0.7063,
    prAuc: 0.0606,
    accuracy: 0.5223,
    precision: 0.0503,
    recall: 0.7906,
    note: "Added complexity without enough extra value.",
  },
  {
    model: "Decision Tree",
    rocAuc: 0.6687,
    prAuc: 0.0512,
    accuracy: 0.5008,
    precision: 0.0489,
    recall: 0.8038,
    note: "Easy to picture, but weaker overall.",
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
    "The evidence suggests the sound linked with success changed somewhat over time, but not so dramatically that we can claim the formula was completely rewritten.",
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
    "The time question had to be handled carefully because non-charted songs did not have trustworthy years attached to them in the saved data.",
    "Some traits linked with stronger chart performance moved over time, especially danceability, energy, and valence.",
    "Overall, the result points to moderate drift rather than a brand-new rulebook for success.",
  ],
};

export const robustness = {
  conclusion:
    "The core story held up across conservative, enriched, and high-confidence versions of the dataset.",
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
    "That matters because it shows the findings were not just artifacts of one convenient data build. Even when the dataset changed a little, the main direction of the story stayed the same.",
};

export const methodology = {
  audiences: ["Artists", "Labels", "A&R Teams", "Marketers", "Streaming Platforms"],
  audienceText:
    "Each group can use a project like this differently: creators can reflect on sound profile, labels can compare positioning, marketers can sharpen campaign language, and platforms can better understand the kinds of tracks that tend to break through.",
  meaning:
    "The big takeaway is that chart success is not completely random. Some audio patterns show up around successful songs often enough to be measured, compared, and modeled.",
  honesty:
    "Data can support music strategy, but it cannot replace creativity, timing, culture, or human judgment. These results are about association, not guaranteed causation.",
  limitation:
    "This project only sees audio features. It does not know anything about artist fame, release strategy, fan base, playlist support, marketing budget, or cultural moments.",
};

export const featureControls = [
  {
    key: "danceability",
    label: "Danceability",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.61,
    description: "How movement-friendly the track feels.",
  },
  {
    key: "energy",
    label: "Energy",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.7,
    description: "Perceived intensity and drive.",
  },
  {
    key: "valence",
    label: "Valence",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.52,
    description: "How positive or bright the mood feels.",
  },
  {
    key: "tempo",
    label: "Tempo",
    min: 60,
    max: 200,
    step: 1,
    defaultValue: 123,
    description: "Estimated beats per minute.",
  },
  {
    key: "loudness",
    label: "Loudness",
    min: -20,
    max: 0,
    step: 0.1,
    defaultValue: -5.8,
    description: "Overall loudness in decibels.",
  },
  {
    key: "acousticness",
    label: "Acousticness",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.16,
    description: "Confidence that the track is acoustic.",
  },
  {
    key: "speechiness",
    label: "Speechiness",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.09,
    description: "How speech-heavy the vocal delivery is.",
  },
  {
    key: "instrumentalness",
    label: "Instrumentalness",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.01,
    description: "Likelihood that the track lacks vocals.",
  },
  {
    key: "liveness",
    label: "Liveness",
    min: 0,
    max: 1,
    step: 0.01,
    defaultValue: 0.19,
    description: "How live or audience-present the track feels.",
  },
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
