import {
  baselineLogisticCoefficients,
  chartedMeans,
  featureControls,
  nonChartedMeans,
} from "../data/projectData.js";

export const FEATURE_KEYS = featureControls.map((feature) => feature.key);

export const DEFAULT_PROFILE = Object.fromEntries(
  featureControls.map((feature) => [feature.key, feature.defaultValue]),
);

export const CHARTED_PROFILE = { ...chartedMeans };
export const NON_CHARTED_PROFILE = { ...nonChartedMeans };

const logistic = (value) => 1 / (1 + Math.exp(-value));

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const getMidpoint = (key) => (chartedMeans[key] + nonChartedMeans[key]) / 2;

const getCloserProfile = (key, value) => {
  const chartedDistance = Math.abs(value - chartedMeans[key]);
  const nonChartedDistance = Math.abs(value - nonChartedMeans[key]);

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
  const normalizedProfile = Object.fromEntries(
    FEATURE_KEYS.map((key) => {
      const control = featureControls.find((item) => item.key === key);
      return [key, clamp(Number(profile[key]), control.min, control.max)];
    }),
  );

  const logit =
    baselineLogisticCoefficients.intercept +
    FEATURE_KEYS.reduce(
      (sum, key) => sum + normalizedProfile[key] * baselineLogisticCoefficients[key],
      0,
    );

  const rawProbability = logistic(logit);
  const displayScore = clamp(rawProbability * 100, 0, 100);

  const contributions = FEATURE_KEYS.map((key) => {
    const midpoint = getMidpoint(key);
    const signedDrift = normalizedProfile[key] - midpoint;
    const signedImpact = signedDrift * baselineLogisticCoefficients[key];
    const helps = signedImpact >= 0;

    return {
      key,
      label: featureControls.find((item) => item.key === key).label,
      value: normalizedProfile[key],
      formattedValue: formatFeatureValue(key, normalizedProfile[key]),
      chartedAverage: chartedMeans[key],
      nonChartedAverage: nonChartedMeans[key],
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
