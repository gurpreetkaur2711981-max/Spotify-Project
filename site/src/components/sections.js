import {
  benchmarkModels,
  edaHighlights,
  enrichmentSummary,
  eraDrift,
  featureControls,
  figurePaths,
  heroMetrics,
  hypothesisFeatures,
  methodology,
  navItems,
  pcaSummary,
  robustness,
  siteMeta,
  storyCards,
  pipelineSteps,
} from "../data/projectData.js";

const formatNumber = (value) => new Intl.NumberFormat("en-US").format(value);
const formatPercent = (value) => `${(value * 100).toFixed(1)}%`;

const renderNav = () =>
  navItems
    .map(
      (item) =>
        `<a class="topbar__link" href="${item.href}" data-nav-link>${item.label}</a>`,
    )
    .join("");

const renderHeroMetrics = () =>
  heroMetrics
    .map(
      (metric) => `
        <article class="metric-card">
          <span class="metric-card__label">${metric.label}</span>
          <strong class="metric-card__value">${metric.value}</strong>
          <p class="metric-card__detail">${metric.detail}</p>
        </article>
      `,
    )
    .join("");

const renderStoryCards = () =>
  storyCards
    .map(
      (card) => `
        <article class="glass-card story-card reveal">
          <span class="eyebrow">${card.eyebrow}</span>
          <h3>${card.title}</h3>
          <p>${card.text}</p>
        </article>
      `,
    )
    .join("");

const renderPipeline = () =>
  pipelineSteps
    .map(
      (step, index) => `
        <article class="pipeline-card reveal">
          <span class="pipeline-card__index">0${index + 1}</span>
          <span class="pipeline-card__phase">${step.phase}</span>
          <h3>${step.title}</h3>
          <p>${step.text}</p>
        </article>
      `,
    )
    .join("");

const renderHypothesisBars = () => {
  const maxEffect = Math.max(...hypothesisFeatures.map((item) => Math.abs(item.effect)));

  return hypothesisFeatures
    .map((item) => {
      const width = `${(Math.abs(item.effect) / maxEffect) * 100}%`;
      const barClass = item.effect >= 0 ? "is-positive" : "is-negative";

      return `
        <div class="effect-row">
          <div>
            <strong>${item.feature}</strong>
            <span>${item.direction === "positive" ? "Charted higher" : "Charted lower"}</span>
          </div>
          <div class="effect-row__bar">
            <span class="effect-row__fill ${barClass}" style="width:${width}"></span>
          </div>
          <strong>${item.effect.toFixed(3)}</strong>
        </div>
      `;
    })
    .join("");
};

const renderBenchmarkRows = () => {
  const maxRoc = Math.max(...benchmarkModels.map((item) => item.rocAuc));
  const maxPr = Math.max(...benchmarkModels.map((item) => item.prAuc));

  return benchmarkModels
    .map(
      (model) => `
        <article class="benchmark-row glass-card reveal">
          <header class="benchmark-row__header">
            <div>
              <h3>${model.model}</h3>
              <p>${model.note}</p>
            </div>
            <span class="benchmark-row__chip">${model.model.includes("Logistic") ? "Recommended practical baseline" : "Benchmark"}</span>
          </header>
          <div class="benchmark-row__metrics">
            <div>
              <span>ROC-AUC</span>
              <strong>${model.rocAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>PR-AUC</span>
              <strong>${model.prAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>Recall</span>
              <strong>${model.recall.toFixed(4)}</strong>
            </div>
          </div>
          <div class="dual-meter">
            <div>
              <span>ROC-AUC</span>
              <div class="meter">
                <span style="width:${(model.rocAuc / maxRoc) * 100}%"></span>
              </div>
            </div>
            <div>
              <span>PR-AUC</span>
              <div class="meter meter--secondary">
                <span style="width:${(model.prAuc / maxPr) * 100}%"></span>
              </div>
            </div>
          </div>
        </article>
      `,
    )
    .join("");
};

const renderRobustnessCards = () =>
  robustness.tiers
    .map(
      (tier) => `
        <article class="tier-card glass-card reveal">
          <span class="eyebrow">${tier.name}</span>
          <strong class="tier-card__count">${formatNumber(tier.charted)} charted songs</strong>
          <p>Class ratio: ${tier.classRatio.toFixed(1)} : 1</p>
          <div class="tier-card__stats">
            <div>
              <span>ROC-AUC</span>
              <strong>${tier.rocAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>PR-AUC</span>
              <strong>${tier.prAuc.toFixed(4)}</strong>
            </div>
          </div>
        </article>
      `,
    )
    .join("");

const renderSliders = () =>
  featureControls
    .map(
      (feature) => `
        <label class="slider-card" for="feature-${feature.key}">
          <div class="slider-card__header">
            <div>
              <span class="slider-card__label">${feature.label}</span>
              <span class="slider-card__description">${feature.description}</span>
            </div>
            <strong id="feature-value-${feature.key}" class="slider-card__value">${feature.defaultValue}</strong>
          </div>
          <input
            id="feature-${feature.key}"
            name="${feature.key}"
            type="range"
            min="${feature.min}"
            max="${feature.max}"
            step="${feature.step}"
            value="${feature.defaultValue}"
            data-feature-input
          />
        </label>
      `,
    )
    .join("");

export const renderApp = () => `
  <div class="site-shell">
    <div class="ambient ambient--one" aria-hidden="true"></div>
    <div class="ambient ambient--two" aria-hidden="true"></div>

    <header class="topbar">
      <a class="brand" href="#hero">
        <span class="brand__mark">S</span>
        <span class="brand__copy">
          <strong>${siteMeta.title}</strong>
          <span>Billboard analytics portfolio</span>
        </span>
      </a>
      <nav class="topbar__nav" aria-label="Primary">
        ${renderNav()}
      </nav>
    </header>

    <main>
      <section class="hero section section--flush" id="hero">
        <div class="hero__copy reveal is-visible">
          <span class="eyebrow">${siteMeta.kicker}</span>
          <h1>${siteMeta.title}</h1>
          <p class="hero__hook">${siteMeta.hook}</p>
          <p class="hero__subcopy">${siteMeta.subcopy}</p>
          <a class="button button--primary" href="#findings">Explore the findings</a>
        </div>

        <div class="hero__visual reveal is-visible">
          <div class="hero-deck">
            <article class="hero-panel hero-panel--primary">
              <span class="hero-panel__label">Core signal</span>
              <strong>Audio features alone can rank chart success meaningfully.</strong>
              <p>But the real story gets stronger when the pipeline, matching quality, benchmarks, and robustness work are all shown together.</p>
            </article>
            <article class="hero-panel hero-panel--vinyl">
              <div class="vinyl">
                <div class="vinyl__ring"></div>
                <div class="vinyl__ring vinyl__ring--inner"></div>
                <div class="vinyl__dot"></div>
              </div>
              <div class="hero-panel__signal">
                <span></span><span></span><span></span><span></span><span></span>
              </div>
            </article>
            <article class="hero-panel hero-panel--floating">
              <span class="hero-panel__label">Portfolio strength</span>
              <strong>Data engineering + statistics + storytelling + product UI</strong>
            </article>
          </div>
        </div>

        <div class="metrics-grid reveal is-visible">
          ${renderHeroMetrics()}
        </div>
      </section>

      <section class="section" id="overview">
        <div class="section-heading reveal">
          <span class="eyebrow">Project Story</span>
          <h2>From messy music tables to a premium analytics narrative.</h2>
          <p>
            The project started as a proposal about EDA, PCA, hypothesis testing, and logistic regression.
            In reality, it became a deeper product-grade analytics build because the source data had to be merged, defended, enriched, benchmarked, and stress-tested.
          </p>
        </div>
        <div class="story-grid">
          ${renderStoryCards()}
        </div>
      </section>

      <section class="section" id="pipeline">
        <div class="section-heading reveal">
          <span class="eyebrow">Data Pipeline</span>
          <h2>An analytics pipeline built for scrutiny, not just screenshots.</h2>
          <p>
            The site treats the workflow as a product system: source tables, merge safety, cleaning, modeling, enrichment, time sensitivity, benchmarking, and robustness.
          </p>
        </div>
        <div class="pipeline-grid">
          ${renderPipeline()}
        </div>
      </section>

      <section class="section" id="findings">
        <div class="section-heading reveal">
          <span class="eyebrow">Interactive Findings</span>
          <h2>The strongest signals, translated into human language.</h2>
          <p>
            Instead of dropping raw tables on the page, this section turns the project’s saved figures and summary outputs into a guided tour of the main evidence.
          </p>
        </div>

        <div class="findings-layout">
          <article class="glass-card findings-card findings-card--wide reveal">
            <header class="findings-card__header">
              <span class="eyebrow">EDA</span>
              <h3>Charted songs are louder, less acoustic, and more tightly produced.</h3>
            </header>
            <div class="findings-card__copy">
              ${edaHighlights
                .map(
                  (highlight) => `
                    <div class="finding-bullet">
                      <strong>${highlight.title}</strong>
                      <p>${highlight.text}</p>
                    </div>
                  `,
                )
                .join("")}
            </div>
            <div class="figure-grid figure-grid--two">
              <figure class="media-card">
                <img src="${figurePaths.loudnessBox}" alt="Loudness boxplot" />
                <figcaption>Loudness shows the clearest practical separation between charted and non-charted songs.</figcaption>
              </figure>
              <figure class="media-card">
                <img src="${figurePaths.acousticnessBox}" alt="Acousticness boxplot" />
                <figcaption>Acousticness moves in the opposite direction, reinforcing a more polished chart profile.</figcaption>
              </figure>
            </div>
          </article>

          <article class="glass-card findings-card reveal">
            <header class="findings-card__header">
              <span class="eyebrow">Hypothesis Testing</span>
              <h3>All nine features are significant. The differences are not equally important.</h3>
            </header>
            <p class="findings-card__lede">
              Big sample sizes can make everything significant. Effect size is what keeps the story honest.
            </p>
            <div class="effect-rows">
              ${renderHypothesisBars()}
            </div>
          </article>

          <article class="glass-card findings-card reveal">
            <header class="findings-card__header">
              <span class="eyebrow">PCA</span>
              <h3>Five components explain 80.5% of the audio feature space.</h3>
            </header>
            <p class="findings-card__lede">${pcaSummary.pc1Story}</p>
            <div class="figure-grid">
              <figure class="media-card">
                <img src="${figurePaths.pcaVariance}" alt="PCA cumulative variance" />
                <figcaption>Five principal components capture the majority of the structure.</figcaption>
              </figure>
            </div>
          </article>

          <article class="glass-card findings-card reveal">
            <header class="findings-card__header">
              <span class="eyebrow">Logistic Regression</span>
              <h3>The baseline model is still the project's clearest practical model.</h3>
            </header>
            <p class="findings-card__lede">
              AUC landed at <strong>${logisticModel.auc.toFixed(4)}</strong>, with high recall on the charted class and a very interpretable set of coefficients.
            </p>
            <div class="figure-grid">
              <figure class="media-card">
                <img src="${figurePaths.logisticRoc}" alt="Baseline logistic ROC curve" />
                <figcaption>The baseline model reaches strong ranking performance without giving up interpretability.</figcaption>
              </figure>
            </div>
          </article>

          <article class="glass-card findings-card reveal">
            <header class="findings-card__header">
              <span class="eyebrow">Enrichment</span>
              <h3>Data engineering improved the target class before any new model was tried.</h3>
            </header>
            <div class="stat-stack">
              <div>
                <span>Baseline charted</span>
                <strong>${formatNumber(enrichmentSummary.baselineCharted)}</strong>
              </div>
              <div>
                <span>After enrichment</span>
                <strong>${formatNumber(enrichmentSummary.enrichedCharted)}</strong>
              </div>
              <div>
                <span>Recovered safely</span>
                <strong>+${formatNumber(enrichmentSummary.recovered)}</strong>
              </div>
            </div>
            <p class="findings-card__lede">
              Most of the gain came from deterministic title normalization, not aggressive fuzzy matching. That makes the enrichment story stronger academically.
            </p>
          </article>
        </div>
      </section>

      <section class="section" id="dashboard">
        <div class="section-heading reveal">
          <span class="eyebrow">Model Results Dashboard</span>
          <h2>More models were tried. Logistic still stayed the best overall practical choice.</h2>
          <p>
            The benchmark suite tested whether more flexible algorithms could materially outperform the enriched logistic baseline. They did not.
          </p>
        </div>
        <div class="dashboard-grid">
          <div class="dashboard-grid__main">
            ${renderBenchmarkRows()}
          </div>
          <aside class="dashboard-grid__aside">
            <figure class="media-card reveal">
              <img src="${figurePaths.benchmarkAuc}" alt="Benchmark ROC-AUC comparison" />
              <figcaption>ROC-AUC stays clustered tightly around the enriched logistic baseline, with no meaningful winner over logistic.</figcaption>
            </figure>
            <figure class="media-card reveal">
              <img src="${figurePaths.benchmarkPr}" alt="Benchmark precision recall curves" />
              <figcaption>Random forest edges out PR-AUC, but not enough to justify the extra complexity as the project's main model.</figcaption>
            </figure>
          </aside>
        </div>
      </section>

      <section class="section section--spotlight" id="era-drift">
        <div class="section-heading reveal">
          <span class="eyebrow">The Shifting Sound of Success</span>
          <h2>Music-history storytelling with cautious statistics.</h2>
          <p>
            The time layer had to be built honestly: non-charted songs do not carry trustworthy years in the saved project files, so the model switches to chart-only top-10 prediction within each era.
          </p>
        </div>
        <div class="spotlight-grid">
          <div class="spotlight-copy glass-card reveal">
            <h3>Moderate evidence of drift, not overclaiming.</h3>
            <p>${eraDrift.conclusion}</p>
            <ul class="detail-list">
              ${eraDrift.takeaways.map((item) => `<li>${item}</li>`).join("")}
            </ul>
            <div class="era-counts">
              ${eraDrift.counts
                .map(
                  (item) => `
                    <div class="era-count">
                      <strong>${item.era}</strong>
                      <span>${item.matched} matched songs</span>
                      <span>${item.top10} top-10 songs in model</span>
                    </div>
                  `,
                )
                .join("")}
            </div>
            <p class="callout callout--soft">${eraDrift.caution}</p>
          </div>
          <div class="spotlight-media">
            <figure class="media-card reveal">
              <img src="${figurePaths.eraTrend}" alt="Era feature trends" />
              <figcaption>Feature means shift gradually across eras rather than snapping to a completely new formula.</figcaption>
            </figure>
            <figure class="media-card reveal">
              <img src="${figurePaths.eraCoefficient}" alt="Era coefficient drift" />
              <figcaption>Coefficient drift suggests some change in what helps a song convert chart presence into top-10 performance.</figcaption>
            </figure>
          </div>
        </div>
      </section>

      <section class="section" id="robustness">
        <div class="section-heading reveal">
          <span class="eyebrow">Professor-Proof Section</span>
          <h2>The conclusions survive stricter and broader dataset constructions.</h2>
          <p>
            This is the defense against the “one arbitrary dataset” criticism. The project was rechecked across conservative, enriched, and high-confidence tiers.
          </p>
        </div>
        <div class="tier-grid">
          ${renderRobustnessCards()}
        </div>
        <div class="robustness-layout">
          <div class="glass-card reveal">
            <h3>Main defense</h3>
            <p>${robustness.conclusion}</p>
            <p>${robustness.note}</p>
            <ul class="detail-list">
              <li>All 9 hypothesis-test directions stayed the same across tiers.</li>
              <li>All 9 logistic coefficient signs stayed the same across tiers.</li>
              <li>PCA interpretation stayed identical because the feature matrix stayed the same and only labels changed.</li>
            </ul>
          </div>
          <div class="robustness-media">
            <figure class="media-card reveal">
              <img src="${figurePaths.robustnessAuc}" alt="Robustness AUC comparison" />
              <figcaption>ROC-AUC stays in a tight band across dataset tiers.</figcaption>
            </figure>
            <figure class="media-card reveal">
              <img src="${figurePaths.robustnessEffects}" alt="Robustness effect size comparison" />
              <figcaption>The loudness / acousticness / instrumentalness story remains intact across tiers.</figcaption>
            </figure>
          </div>
        </div>
      </section>

      <section class="section section--explorer" id="explorer">
        <div class="section-heading reveal">
          <span class="eyebrow">Song Profile Explorer</span>
          <h2>Build a track profile and see how it scores against the baseline chart model.</h2>
          <p>
            This panel uses the exact published Step 5 logistic coefficients to create a chart-profile score.
            It is useful as a relative profile estimator, not as a calibrated hit probability.
          </p>
        </div>

        <div class="explorer-layout">
          <div class="explorer-controls glass-card reveal">
            <div class="preset-row">
              <button type="button" class="button button--ghost" data-preset="charted">Use charted average</button>
              <button type="button" class="button button--ghost" data-preset="noncharted">Use non-charted average</button>
              <button type="button" class="button button--ghost" data-preset="default">Reset</button>
            </div>
            <div class="sliders-grid">
              ${renderSliders()}
            </div>
          </div>

          <aside class="explorer-output glass-card reveal">
            <div class="score-orb" id="score-orb" style="--score-angle: 220deg;">
              <div class="score-orb__center">
                <span>Chart profile score</span>
                <strong id="score-value">0</strong>
              </div>
            </div>
            <div class="score-copy">
              <h3 id="score-label">Moderate chart profile</h3>
              <p id="score-note"></p>
            </div>

            <div class="contribution-block">
              <h4>Strongest tailwinds</h4>
              <div id="tailwinds-list" class="contribution-list"></div>
            </div>

            <div class="contribution-block">
              <h4>Main watchouts</h4>
              <div id="headwinds-list" class="contribution-list"></div>
            </div>

            <div class="disclaimer">
              <strong>Method note</strong>
              <p>This explorer uses exact published coefficients from the validated baseline logistic model. The score is a relative ranking signal, not a calibrated probability of commercial success.</p>
            </div>
          </aside>
        </div>
      </section>

      <section class="section" id="methodology">
        <div class="section-heading reveal">
          <span class="eyebrow">About / Methodology</span>
          <h2>Built like an analytics product, written with methodological honesty.</h2>
          <p>
            The website is designed to feel premium, but the analysis stays grounded in the real limits of the data and the saved project outputs.
          </p>
        </div>
        <div class="method-grid">
          <article class="glass-card reveal">
            <h3>Tools used</h3>
            <div class="chip-grid">
              ${methodology.tools.map((tool) => `<span class="chip">${tool}</span>`).join("")}
            </div>
          </article>
          <article class="glass-card reveal">
            <h3>Methodological honesty</h3>
            <p>${methodology.honesty}</p>
          </article>
          <article class="glass-card reveal">
            <h3>Limitation worth remembering</h3>
            <p>${methodology.limitation}</p>
          </article>
        </div>
      </section>
    </main>

    <footer class="footer">
      <div class="footer__inner">
        <div>
          <strong>${siteMeta.title}</strong>
          <p>Original Spotify-inspired product design for a static GitHub Pages portfolio site.</p>
        </div>
        <div>
          <span>Project credits</span>
          <p>Analytics project by Gurpreet Kaur. Website system assembled from real project outputs under <code>D:/SpotifyBillboardProject</code>.</p>
        </div>
        <div>
          <span>Data acknowledgment</span>
          <p>Kaggle source tables combining Billboard chart history and Spotify song attributes. No proprietary Spotify assets are used here.</p>
        </div>
      </div>
    </footer>
  </div>
`;
