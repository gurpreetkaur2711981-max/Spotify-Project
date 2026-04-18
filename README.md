# Spotify Billboard Signals of Success

Portfolio-grade analytics project and public website exploring whether Spotify audio features can help explain Billboard Hot 100 chart success.

This repository is the public-facing version of a larger local analytics workspace. It keeps the real analysis scripts, final writeups, selected outputs, and the deployed website while excluding local-only state files and bulky datasets that are not a good fit for a standard GitHub repo.

## What This Project Does

The project starts from a messy real-world data integration problem rather than a ready-made analysis table. Two source tables had to be inspected, merged, cleaned, enriched, modeled, benchmarked, and stress-tested:

- Spotify audio features for songs
- Billboard Hot 100 chart history from 1999 to 2019

From there, the project builds an end-to-end workflow:

1. data inspection and merge construction
2. cleaning and feature preparation
3. exploratory data analysis
4. hypothesis testing
5. PCA
6. logistic regression
7. safer chart-match enrichment
8. era-drift analysis
9. benchmark modeling beyond logistic regression
10. robustness analysis across dataset tiers
11. static portfolio website for GitHub Pages

## Verified Headline Results

- Baseline logistic regression on the conservative cleaned dataset reached **ROC-AUC = 0.7281**.
- Phase 1 enrichment increased matched charted songs from **3,618** to **4,079** for a net gain of **461** recovered charted songs.
- Phase 3 benchmarking found that **no tested model materially beat logistic regression on ROC-AUC**. Random Forest posted the best PR-AUC, but the gain was small.
- Phase 10 robustness checks found the main conclusions were **directionally robust** across conservative, enriched, and high-confidence dataset tiers.
- Phase 2 era drift showed **moderate evidence of drift**, with later-era coverage weaker and interpreted cautiously.

## Website

The public site lives in [site/](site/) and is designed to deploy directly to GitHub Pages as a static artifact.

Public deployment support is defined in:

- [deploy-site.yml](.github/workflows/deploy-site.yml)

The site is intentionally static:

- no backend
- no required build step
- GitHub Pages-friendly
- built from curated project figures and helper data

### Local preview

```bash
cd D:/SpotifyBillboardProject/site
python -m http.server 4173
```

Then open `http://localhost:4173`.

## Repo Structure

```text
.github/                 GitHub Pages workflow
docs/                    reports, summaries, and public project notes
outputs/                 selected tables and figures used in the project story
scripts/                 R analysis pipeline
site/                    static portfolio website
data/README.md           note about omitted large local datasets
README.md                public project overview
```

## Important Data Note

Large raw and processed CSV files are **not versioned in this public repo**.

That choice is for repo hygiene and GitHub practicality, not to hide work:

- the largest raw Billboard CSV is over 200 MB
- the public repo still includes the real scripts, writeups, figures, and summary tables
- the deployed site remains self-contained because it uses copied assets inside `site/`

See [data/README.md](data/README.md) and [docs/public_repo_curation_plan.md](docs/public_repo_curation_plan.md) for the curation rationale.

## Public Deliverables

- [Final project report](docs/final_project_report.md)
- [Executive summary](docs/executive_summary.md)
- [Step 6 matching enrichment summary](docs/step6_matching_enrichment_summary.md)
- [Step 7 era drift summary](docs/step7_era_drift_summary.md)
- [Step 8 benchmark summary](docs/step8_benchmark_summary.md)
- [Step 10 robustness summary](docs/step10_robustness_summary.md)
- [Step 11 website summary](docs/step11_website_summary.md)

## GitHub Pages Note

This repo includes a Pages workflow that deploys the contents of `site/` from the `main` branch.

If you publish this repository to GitHub and enable GitHub Pages with **GitHub Actions**, the workflow should deploy the site automatically on pushes that touch:

- `site/**`
- `.github/workflows/deploy-site.yml`

## Local Run Notes

- R scripts use explicit Windows paths rooted at `D:/SpotifyBillboardProject`.
- The website can be previewed with Python's built-in static server.
- No server-side runtime is required for the website.

## License

No license file has been added yet.
If you want to allow reuse beyond standard GitHub visibility, add an explicit license before publishing.
