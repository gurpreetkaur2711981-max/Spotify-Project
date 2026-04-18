import {
  benchmarkModels,
  edaHighlights,
  enrichmentSummary,
  eraDrift,
  featureControls,
  figurePaths,
  heroMetrics,
  hypothesisFeatures,
  logisticModel,
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
            <span class="benchmark-row__chip">${model.model.includes("Logistic") ? "Best practical choice" : "Comparison model"}</span>
          </header>
          <div class="benchmark-row__metrics">
            <div>
              <span>Hit ranking (ROC-AUC)</span>
              <strong>${model.rocAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>Rare-hit focus (PR-AUC)</span>
              <strong>${model.prAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>Hit recall</span>
              <strong>${model.recall.toFixed(4)}</strong>
            </div>
          </div>
          <div class="dual-meter">
            <div>
              <span>Hit ranking</span>
              <div class="meter">
                <span style="width:${(model.rocAuc / maxRoc) * 100}%"></span>
              </div>
            </div>
            <div>
              <span>Rare-hit focus</span>
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
              <span>Hit ranking</span>
              <strong>${tier.rocAuc.toFixed(4)}</strong>
            </div>
            <div>
              <span>Rare-hit focus</span>
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

const renderLogisticSummary = () => {
  if (logisticModel && Number.isFinite(logisticModel.auc)) {
    return `Using only audio features, the baseline model could meaningfully separate songs that charted from songs that did not. Its hit-ranking score (AUC) was <strong>${logisticModel.auc.toFixed(4)}</strong>, which is strong enough to show that the sound of a song carries real signal even without marketing, fandom, or artist-fame information.`;
  }

  return "The saved baseline logistic summary is unavailable in the current site data, so this section explains the result safely instead of failing to render.";
};

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
              <span class="hero-panel__label">The human question</span>
              <strong>Can you hear whether a song is likely to become a hit?</strong>
              <p>This site answers that question by connecting Spotify sound features with Billboard hit history and then explaining the results in plain English.</p>
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
              <span class="hero-panel__label">Why this project stands out</span>
              <strong>It was not just a model. It was a full data story.</strong>
            </article>
          </div>
        </div>

        <div class="metrics-grid reveal is-visible">
          ${renderHeroMetrics()}
        </div>
      </section>

      <section class="section" id="overview">
        <div class="section-heading reveal">
          <span class="eyebrow">Start Here</span>
          <h2>What was I trying to predict, and why should anyone care?</h2>
          <p>
            At the center of the project is one practical question: can the sound of a song tell us anything about whether it reaches the Billboard Hot 100?
            That matters because artists, labels, marketers, and streaming platforms all want better signals about what resonates, even though creativity and culture still matter far beyond the data.
          </p>
        </div>
        <div class="story-grid">
          ${renderStoryCards()}
        </div>
      </section>

      <section class="section" id="pipeline">
        <div class="section-heading reveal">
          <span class="eyebrow">How I Built It</span>
          <h2>Spotify told me how songs sounded. Billboard told me which songs became hits.</h2>
          <p>
            Those two worlds did not arrive neatly connected. Before any chart, test, or model could be trusted, I had to build the dataset carefully and avoid bad matches.
          </p>
        </div>
        <div class="pipeline-grid">
          ${renderPipeline()}
        </div>
      </section>

      <section class="section" id="findings">
        <div class="section-heading reveal">
          <span class="eyebrow">What I Found</span>
          <h2>What did hit songs sound like, and what did the models learn?</h2>
          <p>
            Instead of dropping raw tables on the page, this section turns the project’s saved figures and summary outputs into a guided tour of the main evidence.
          </p>
        </div>

        <div class="findings-layout">
          <article class="glass-card findings-card findings-card--wide reveal">
            <header class="findings-card__header">
              <span class="eyebrow">First Look</span>
              <h3>Before any modeling, hit songs already sounded different.</h3>
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
              <span class="eyebrow">Trust Check</span>
              <h3>Those differences were not just random noise.</h3>
            </header>
            <p class="findings-card__lede">
              This step checked that the patterns were strong enough to take seriously, not just artifacts of a huge dataset.
            </p>
            <div class="effect-rows">
              ${renderHypothesisBars()}
            </div>
          </article>

          <article class="glass-card findings-card reveal">
            <header class="findings-card__header">
              <span class="eyebrow">Hidden Patterns</span>
              <h3>When the sound features were compressed, one big pattern stood out.</h3>
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
              <span class="eyebrow">Prediction</span>
              <h3>Could those sound clues actually help predict whether a song charts?</h3>
            </header>
            <p class="findings-card__lede">
              ${renderLogisticSummary()}
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
              <span class="eyebrow">Data Quality</span>
              <h3>A stronger dataset made the whole story more believable.</h3>
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
              Before trying fancier modeling, I first improved the set of confirmed chart songs so the project rested on a better foundation.
            </p>
          </article>
        </div>
      </section>

      <section class="section" id="dashboard">
        <div class="section-heading reveal">
          <span class="eyebrow">Simple vs Complex</span>
          <h2>Did a fancier model beat the simpler one?</h2>
          <p>
            I tested that directly. Think of ROC-AUC as a ranking score: higher means the model is better at placing real chart songs above non-chart songs. PR-AUC is stricter because actual chart songs are rare in the data.
          </p>
        </div>
        <div class="dashboard-grid">
          <div class="dashboard-grid__main">
            ${renderBenchmarkRows()}
          </div>
          <aside class="dashboard-grid__aside">
            <figure class="media-card reveal">
              <img src="${figurePaths.benchmarkAuc}" alt="Benchmark ROC-AUC comparison" />
              <figcaption>The more complex models stayed close to the simpler baseline instead of clearly beating it.</figcaption>
            </figure>
            <figure class="media-card reveal">
              <img src="${figurePaths.benchmarkPr}" alt="Benchmark precision recall curves" />
              <figcaption>One model edged ahead on a harder rare-hit metric, but not enough to outweigh the simplicity of logistic regression.</figcaption>
            </figure>
          </aside>
        </div>
      </section>

      <section class="section section--spotlight" id="era-drift">
        <div class="section-heading reveal">
          <span class="eyebrow">The Shifting Sound of Success</span>
          <h2>Did the sound of success stay the same from 1999 to 2019?</h2>
          <p>
            I also wanted to know whether the audio recipe linked with success stayed stable or changed as music trends changed.
          </p>
        </div>
        <div class="spotlight-grid">
          <div class="spotlight-copy glass-card reveal">
            <h3>Some parts of the formula moved over time.</h3>
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
          <span class="eyebrow">Trust Check</span>
          <h2>Would the story still hold if the dataset was built a little differently?</h2>
          <p>
            This is the defense against the “one arbitrary dataset” criticism. The project was rechecked across conservative, enriched, and high-confidence tiers.
          </p>
        </div>
        <div class="tier-grid">
          ${renderRobustnessCards()}
        </div>
        <div class="robustness-layout">
          <div class="glass-card reveal">
            <h3>Why this makes the project stronger</h3>
            <p>${robustness.conclusion}</p>
            <p>${robustness.note}</p>
            <ul class="detail-list">
              <li>The direction of the main findings stayed the same across all tiers.</li>
              <li>The main predictor signs stayed the same across all tiers.</li>
              <li>The broader sound-pattern story stayed the same too.</li>
            </ul>
          </div>
          <div class="robustness-media">
            <figure class="media-card reveal">
              <img src="${figurePaths.robustnessAuc}" alt="Robustness AUC comparison" />
              <figcaption>The hit-ranking score stayed in a tight band across dataset tiers.</figcaption>
            </figure>
            <figure class="media-card reveal">
              <img src="${figurePaths.robustnessEffects}" alt="Robustness effect size comparison" />
              <figcaption>The loudness, acousticness, and instrumentalness story remained intact across tiers.</figcaption>
            </figure>
          </div>
        </div>
      </section>

      <section class="section section--explorer" id="explorer">
        <div class="section-heading reveal">
          <span class="eyebrow">Try It Yourself</span>
          <h2>What kind of chart profile does a song like this create?</h2>
          <p>
            Move the sliders to see how a song's audio traits compare with the average charted and non-charted profile. This is a learning tool based on the saved model, not a promise that a song will become a hit.
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
              <p>This explorer uses the published baseline model to show relative chart fit. It is helpful for intuition, not for guaranteeing commercial success.</p>
            </div>
          </aside>
        </div>
      </section>

      <section class="section" id="methodology">
        <div class="section-heading reveal">
          <span class="eyebrow">Why It Matters</span>
          <h2>What does all of this mean in the real world?</h2>
          <p>
            The point is not that data can manufacture a hit. The point is that some parts of chart success are measurable and useful when they are paired with human judgment.
          </p>
        </div>
        <div class="method-grid">
          <article class="glass-card reveal">
            <h3>Who this can help</h3>
            <div class="chip-grid">
              ${methodology.audiences.map((group) => `<span class="chip">${group}</span>`).join("")}
            </div>
            <p>${methodology.audienceText}</p>
          </article>
          <article class="glass-card reveal">
            <h3>What the results mean</h3>
            <p>${methodology.meaning}</p>
            <p>${methodology.honesty}</p>
          </article>
          <article class="glass-card reveal">
            <h3>What the results do not mean</h3>
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
