import {
  baselineLogisticCoefficients,
  chartedMeans,
  featureControls,
  nonChartedMeans,
} from "../data/projectData.js";

const safeFeatureControls = Array.isArray(featureControls) ? featureControls : [];
const safeChartedMeans =
  chartedMeans && typeof chartedMeans === "object" ? chartedMeans : {};
const safeNonChartedMeans =
  nonChartedMeans && typeof nonChartedMeans === "object" ? nonChartedMeans : {};
const safeCoefficients =
  baselineLogisticCoefficients && typeof baselineLogisticCoefficients === "object"
    ? baselineLogisticCoefficients
    : {};

export const FEATURE_KEYS = safeFeatureControls.map((feature) => feature.key);

export const DEFAULT_PROFILE = Object.fromEntries(
  safeFeatureControls.map((feature) => [feature.key, feature.defaultValue]),
);

export const CHARTED_PROFILE = { ...safeChartedMeans };
export const NON_CHARTED_PROFILE = { ...safeNonChartedMeans };

export const ESTIMATOR_AVAILABLE =
  FEATURE_KEYS.length > 0 &&
  typeof safeCoefficients.intercept === "number" &&
  FEATURE_KEYS.every(
    (key) =>
      typeof safeCoefficients[key] === "number" &&
      typeof safeChartedMeans[key] === "number" &&
      typeof safeNonChartedMeans[key] === "number",
  );

const logistic = (value) => 1 / (1 + Math.exp(-value));

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const getMidpoint = (key) =>
  (safeChartedMeans[key] + safeNonChartedMeans[key]) / 2;

const getCloserProfile = (key, value) => {
  const chartedDistance = Math.abs(value - safeChartedMeans[key]);
  const nonChartedDistance = Math.abs(value - safeNonChartedMeans[key]);

  if (Math.abs(chartedDistance - nonChartedDistance) < 1e-8) {
    return "Balanced between charted and non-charted averages";
  }

  return chartedDistance < nonChartedDistance
    ? "Closer to charted average"
    : "Closer to non-charted average";
};

const interpretScore = (score) => {
  if (score >= 60) return "Relatively strong chart profile";
  if (score >= 40) return "Moderate chart profile";
  return "Low chart profile";
};

const formatFeatureValue = (key, value) => {
  if (key === "tempo") return `${Math.round(value)} BPM`;
  if (key === "loudness") return `${value.toFixed(1)} dB`;
  return value.toFixed(2);
};

export const buildProfileAssessment = (profile) => {
  if (!ESTIMATOR_AVAILABLE) {
    return {
      normalizedProfile: { ...DEFAULT_PROFILE },
      logit: null,
      rawProbability: null,
      displayScore: 0,
      label: "Estimator unavailable",
      contributions: [],
      tailwinds: [],
      headwinds: [],
      note:
        "The baseline logistic model metadata is unavailable in the published site data, so the interactive score is temporarily disabled while the rest of the page stays available.",
    };
  }

  const normalizedProfile = Object.fromEntries(
    FEATURE_KEYS.map((key) => {
      const control = safeFeatureControls.find((item) => item.key === key);
      return [key, clamp(Number(profile[key]), control.min, control.max)];
    }),
  );

  const logit =
    safeCoefficients.intercept +
    FEATURE_KEYS.reduce(
      (sum, key) => sum + normalizedProfile[key] * safeCoefficients[key],
      0,
    );

  const rawProbability = logistic(logit);
  const displayScore = clamp(rawProbability * 100, 0, 100);

  const contributions = FEATURE_KEYS.map((key) => {
    const midpoint = getMidpoint(key);
    const signedDrift = normalizedProfile[key] - midpoint;
    const signedImpact = signedDrift * safeCoefficients[key];
    const helps = signedImpact >= 0;

    return {
      key,
      label: safeFeatureControls.find((item) => item.key === key).label,
      value: normalizedProfile[key],
      formattedValue: formatFeatureValue(key, normalizedProfile[key]),
      chartedAverage: safeChartedMeans[key],
      nonChartedAverage: safeNonChartedMeans[key],
      midpoint,
      signedImpact,
      helps,
      explanation: helps
        ? "This setting leans toward the charted side of the baseline model."
        : "This setting leans away from the charted side of the baseline model.",
      closeness: getCloserProfile(key, normalizedProfile[key]),
    };
  }).sort((a, b) => Math.abs(b.signedImpact) - Math.abs(a.signedImpact));

  const tailwinds = contributions.filter((item) => item.helps).slice(0, 3);
  const headwinds = contributions.filter((item) => !item.helps).slice(0, 3);

  return {
    normalizedProfile,
    logit,
    rawProbability,
    displayScore,
    label: interpretScore(displayScore),
    contributions,
    tailwinds,
    headwinds,
    note:
      "This score uses the published Step 5 logistic coefficients exactly, but the original model was trained on a balanced subset, so treat it as a relative chart-profile score rather than a calibrated hit probability.",
  };
};
