import {
  chartedMeans,
  featureControls,
  navItems,
  nonChartedMeans,
} from "./data/projectData.js";
import { renderApp } from "./components/sections.js";
import {
  buildProfileAssessment,
  CHARTED_PROFILE,
  DEFAULT_PROFILE,
  ESTIMATOR_AVAILABLE,
  NON_CHARTED_PROFILE,
} from "./utils/estimator.js";

const appRoot = document.querySelector("#app");

const renderSiteFallback = (message) => {
  appRoot.innerHTML = `
    <div class="site-shell">
      <main>
        <section class="section section--flush">
          <article class="glass-card reveal is-visible">
            <span class="eyebrow">Site Fallback</span>
            <h1>Signals of Success</h1>
            <p>${message}</p>
            <p>The rest of the repository and the static assets are still intact, but this page hit a runtime issue while rendering.</p>
          </article>
        </section>
      </main>
    </div>
  `;
};

try {
  appRoot.innerHTML = renderApp();
} catch (error) {
  console.error("Site render failed.", error);
  renderSiteFallback(
    "The page hit a runtime error while assembling the main view. A visible fallback has been rendered so the site no longer fails as a blank screen.",
  );
}

const updateBodyLoaded = () => {
  requestAnimationFrame(() => {
    document.body.classList.remove("is-loading");
  });
};

const setupScrollProgress = () => {
  const bar = document.querySelector("#page-progress-bar");
  const handleScroll = () => {
    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const progress = maxScroll > 0 ? window.scrollY / maxScroll : 0;
    bar.style.transform = `scaleX(${progress})`;
  };

  window.addEventListener("scroll", handleScroll, { passive: true });
  handleScroll();
};

const setupRevealAnimations = () => {
  const revealNodes = [...document.querySelectorAll(".reveal")];
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    {
      rootMargin: "0px 0px -12% 0px",
      threshold: 0.1,
    },
  );

  revealNodes.forEach((node) => {
    if (!node.classList.contains("is-visible")) {
      observer.observe(node);
    }
  });
};

const setupActiveNav = () => {
  const sections = navItems
    .map((item) => document.querySelector(item.href))
    .filter(Boolean);

  const links = [...document.querySelectorAll("[data-nav-link]")];

  const highlight = () => {
    let activeId = "#hero";

    sections.forEach((section) => {
      const rect = section.getBoundingClientRect();
      if (rect.top <= 140 && rect.bottom > 140) {
        activeId = `#${section.id}`;
      }
    });

    links.forEach((link) => {
      const isActive = link.getAttribute("href") === activeId;
      link.classList.toggle("is-active", isActive);
    });
  };

  window.addEventListener("scroll", highlight, { passive: true });
  highlight();
};

const getPresetProfile = (preset) => {
  if (preset === "charted") return CHARTED_PROFILE;
  if (preset === "noncharted") return NON_CHARTED_PROFILE;
  return DEFAULT_PROFILE;
};

const formatAverage = (key, value) => {
  if (key === "tempo") return `${Math.round(value)} BPM`;
  if (key === "loudness") return `${value.toFixed(1)} dB`;
  return value.toFixed(2);
};

const renderContributionItems = (items, fallbackText) => {
  if (!items.length) {
    return `<div class="contribution-card"><strong>${fallbackText}</strong></div>`;
  }

  return items
    .map(
      (item) => `
        <article class="contribution-card ${item.helps ? "is-help" : "is-watch"}">
          <header>
            <strong>${item.label}</strong>
            <span>${item.formattedValue}</span>
          </header>
          <p>${item.explanation}</p>
          <small>${item.closeness} · charted avg ${formatAverage(item.key, chartedMeans[item.key])}</small>
        </article>
      `,
    )
    .join("");
};

const renderEstimatorUnavailable = (message) => {
  const scoreValue = document.querySelector("#score-value");
  const scoreLabel = document.querySelector("#score-label");
  const scoreNote = document.querySelector("#score-note");
  const tailwindsList = document.querySelector("#tailwinds-list");
  const headwindsList = document.querySelector("#headwinds-list");
  const scoreOrb = document.querySelector("#score-orb");

  if (!scoreValue || !scoreLabel || !scoreNote || !tailwindsList || !headwindsList) {
    return;
  }

  scoreValue.textContent = "--";
  scoreLabel.textContent = "Estimator unavailable";
  scoreNote.textContent = message;

  if (scoreOrb) {
    scoreOrb.style.setProperty("--score-angle", "0deg");
  }

  tailwindsList.innerHTML =
    '<div class="contribution-card"><strong>Estimator data unavailable</strong><p>The page still loads, but the interactive score is disabled until the saved model metadata is restored.</p></div>';

  headwindsList.innerHTML =
    '<div class="contribution-card"><strong>Fallback mode active</strong><p>The rest of the site remains available so the project story and figures do not disappear behind a blank screen.</p></div>';

  [...document.querySelectorAll("[data-feature-input], [data-preset]")].forEach(
    (node) => {
      node.disabled = true;
    },
  );
};

const setupEstimator = () => {
  const inputs = [...document.querySelectorAll("[data-feature-input]")];
  const scoreValue = document.querySelector("#score-value");
  const scoreLabel = document.querySelector("#score-label");
  const scoreNote = document.querySelector("#score-note");
  const tailwindsList = document.querySelector("#tailwinds-list");
  const headwindsList = document.querySelector("#headwinds-list");
  const scoreOrb = document.querySelector("#score-orb");

  if (
    !inputs.length ||
    !scoreValue ||
    !scoreLabel ||
    !scoreNote ||
    !tailwindsList ||
    !headwindsList ||
    !scoreOrb
  ) {
    return;
  }

  if (!ESTIMATOR_AVAILABLE) {
    renderEstimatorUnavailable(
      "The saved baseline logistic model metadata could not be loaded, so the explorer is shown in a safe fallback state.",
    );
    return;
  }

  const getProfile = () =>
    Object.fromEntries(
      inputs.map((input) => [input.name, Number(input.value)]),
    );

  const syncReadouts = () => {
    inputs.forEach((input) => {
      const feature = featureControls.find((item) => item.key === input.name);
      const readout = document.querySelector(`#feature-value-${input.name}`);

      if (!feature || !readout) return;

      if (feature.key === "tempo") {
        readout.textContent = `${Math.round(Number(input.value))} BPM`;
      } else if (feature.key === "loudness") {
        readout.textContent = `${Number(input.value).toFixed(1)} dB`;
      } else {
        readout.textContent = Number(input.value).toFixed(2);
      }
    });
  };

  const updateEstimator = () => {
    syncReadouts();
    let assessment;

    try {
      assessment = buildProfileAssessment(getProfile());
    } catch (error) {
      console.error("Estimator update failed.", error);
      renderEstimatorUnavailable(
        "A runtime error interrupted the chart-profile estimator, so the explorer has been disabled instead of crashing the whole page.",
      );
      return;
    }

    scoreValue.textContent = assessment.displayScore.toFixed(1);
    scoreLabel.textContent = assessment.label;
    scoreNote.textContent = assessment.note;
    scoreOrb.style.setProperty("--score-angle", `${assessment.displayScore * 3.6}deg`);

    tailwindsList.innerHTML = renderContributionItems(
      assessment.tailwinds,
      "No strong tailwinds in the current profile.",
    );

    headwindsList.innerHTML = renderContributionItems(
      assessment.headwinds,
      "No major watchouts in the current profile.",
    );
  };

  const applyPreset = (preset) => {
    const profile = getPresetProfile(preset);
    inputs.forEach((input) => {
      input.value = profile[input.name];
    });
    updateEstimator();
  };

  inputs.forEach((input) => {
    input.addEventListener("input", updateEstimator);
  });

  [...document.querySelectorAll("[data-preset]")].forEach((button) => {
    button.addEventListener("click", () => {
      applyPreset(button.getAttribute("data-preset"));
    });
  });

  updateEstimator();
};

updateBodyLoaded();
setupScrollProgress();
setupRevealAnimations();
setupActiveNav();
setupEstimator();
