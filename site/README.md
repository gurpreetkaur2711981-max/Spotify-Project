# Signals of Success Website

Portfolio website for the Spotify / Billboard analytics project.

This site is intentionally built as a **static frontend** so it can deploy cleanly to **GitHub Pages** without a backend.

## Why This Site Is Static

The local environment for this project did not provide a modern Node + npm toolchain that could safely support a verified Vite / React build during this run.

Because of that, the site was implemented as:

- static HTML
- modular client-side ES modules
- custom CSS design system
- copied project figures and curated helper data

This keeps the site:

- GitHub Pages-ready
- easy to audit
- easy to deploy
- independent of a server

## Folder Structure

```text
site/
  index.html
  package.json
  README.md
  assets/
  src/
    main.js
    components/
    data/
    styles/
    utils/
```

## Install Steps

No package install is required for the deployed site itself.

If you only want to view or publish the site:

1. Clone the repository
2. Open the `site/` folder

## Local Run Steps

Option 1: Python static server

```bash
cd D:/SpotifyBillboardProject/site
python -m http.server 4173
```

Then open:

```text
http://localhost:4173
```

Option 2: Open `index.html` directly in a browser

This works for a quick view, but a local static server is better for consistent asset loading.

## Build Steps

No build step is required.

This site is already authored as deployable static files.

If you still want a placeholder package command:

```bash
cd D:/SpotifyBillboardProject/site
npm run build
```

That command only prints a message because the site does not need bundling.

## GitHub Pages Deployment

This repository includes a GitHub Actions workflow at:

```text
.github/workflows/deploy-site.yml
```

### Recommended deployment flow

1. Push the repository to GitHub
2. In the repository settings, enable GitHub Pages with **GitHub Actions**
3. Push to the default branch
4. The workflow will publish the contents of `site/`

### Important note

The workflow currently listens to pushes on `main`.
If your default branch is different, update the branch name in:

```text
.github/workflows/deploy-site.yml
```

## Base Path Notes

No special base path is required in the site code because:

- asset paths are relative
- the workflow deploys the `site/` folder contents directly as the Pages artifact

## What Powers The Song Success Estimator

The estimator uses the **exact published coefficients** from the validated Step 5 logistic regression summary:

- intercept and 9 feature coefficients come from the project's saved logistic output
- the result is shown as a **chart-profile score**
- it should be interpreted as a **relative profile estimate**

It is **not** a perfectly calibrated commercial hit probability because the original model was trained on a balanced subset and evaluated on an imbalanced test set.

## Data Sources Used In The Site

The site pulls from existing project outputs and copied figure assets, including:

- `docs/final_project_report.md`
- `docs/executive_summary.md`
- `docs/step5_logistic_regression_summary.md`
- `docs/step6_matching_enrichment_summary.md`
- `docs/step7_era_drift_summary.md`
- `docs/step8_benchmark_summary.md`
- `docs/step10_robustness_summary.md`
- `outputs/tables/logistic_model_summary.txt`
- `outputs/tables/benchmark_model_comparison.csv`
- `outputs/tables/robustness_summary.txt`
- `outputs/tables/hypothesis_test_results.csv`
- `outputs/tables/pca_explained_variance.csv`
- `outputs/tables/pca_loadings.csv`

## Design Direction

The visual system is original, but intentionally inspired by premium music-product UX:

- immersive dark canvas
- luminous green accent
- glassy panels
- high-contrast typography
- cinematic spacing
- product-style storytelling
