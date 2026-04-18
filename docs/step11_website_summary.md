# Step 11: Portfolio Website Summary

> **Status: COMPLETE**

## What Was Built

A premium static website was created for the Spotify / Billboard analytics project under:

`D:/SpotifyBillboardProject/site/`

The site is designed as a polished portfolio artifact rather than a class-report dump.
It combines:

- premium dark product styling
- project storytelling
- copied analysis figures
- curated frontend helper data
- a client-side song profile explorer
- GitHub Pages deployment support

## Important Environment Constraint

The local environment did **not** provide a modern Node + npm toolchain.
The visible `node.exe` was an old Brackets-bundled Node 6 installation, and `npm` was not available on PATH.

Because of that, the strongest truthful version for this run was:

- a **static HTML / CSS / ES module site**
- no required build step
- direct GitHub Pages deployment of the `site/` folder

This is a deliberate engineering choice for reliability, not a downgrade in the product experience.

## What The Website Includes

- **Hero / landing**
  - project title
  - high-impact hook
  - premium metric cards
- **Project overview**
  - why the work matters
  - why the merge challenge strengthens the story
- **Visual pipeline**
  - from raw tables to robustness
- **Findings section**
  - EDA
  - hypothesis testing
  - PCA
  - logistic regression
  - enrichment
- **Model dashboard**
  - benchmark comparison
  - logistic vs richer models
- **Era drift experience**
  - feature trends
  - coefficient drift
  - moderated interpretation
- **Robustness section**
  - conservative vs enriched vs high-confidence tiers
- **Song profile explorer**
  - exact Step 5 logistic coefficients used for a relative chart-profile score
- **Methodology / limitations**
  - honest scope and caveats

## Real Project Outputs Used

The site uses actual saved project outputs, including:

- `D:/SpotifyBillboardProject/docs/final_project_report.md`
- `D:/SpotifyBillboardProject/docs/executive_summary.md`
- `D:/SpotifyBillboardProject/docs/step5_logistic_regression_summary.md`
- `D:/SpotifyBillboardProject/docs/step6_matching_enrichment_summary.md`
- `D:/SpotifyBillboardProject/docs/step7_era_drift_summary.md`
- `D:/SpotifyBillboardProject/docs/step8_benchmark_summary.md`
- `D:/SpotifyBillboardProject/docs/step10_robustness_summary.md`
- `D:/SpotifyBillboardProject/outputs/tables/logistic_model_summary.txt`
- `D:/SpotifyBillboardProject/outputs/tables/benchmark_model_comparison.csv`
- `D:/SpotifyBillboardProject/outputs/tables/robustness_summary.txt`
- `D:/SpotifyBillboardProject/outputs/tables/hypothesis_test_results.csv`
- `D:/SpotifyBillboardProject/outputs/tables/pca_explained_variance.csv`
- `D:/SpotifyBillboardProject/outputs/tables/pca_loadings.csv`

Selected figure files were copied into `site/assets/analysis/` so the frontend can deploy cleanly as a self-contained static site.

## Song Estimator Note

The song profile explorer uses the **exact published coefficients** from the baseline Step 5 logistic regression summary.

That means:

- it is **exact-model-based** with respect to the published saved coefficients
- it is **not** a perfectly calibrated commercial hit probability
- it should be read as a **relative chart-profile score**

## GitHub Pages Readiness

The site is GitHub Pages-ready in two ways:

1. it requires no backend and no build artifact generation
2. a Pages workflow was added at:
   `D:/SpotifyBillboardProject/.github/workflows/deploy-site.yml`

The workflow deploys the `site/` directory directly.

## What The Site Does Not Include

- No backend
- No live API
- No proprietary Spotify assets or branding
- No fake live model object
- No rerun of the analysis just for the UI

## Quality Intent

The site was designed to feel:

- cinematic
- premium
- music-product-inspired
- recruiter-ready
- professor-ready

The goal is that a viewer immediately sees:

- strong design taste
- strong frontend execution
- strong analytical storytelling
- strong methodological honesty
