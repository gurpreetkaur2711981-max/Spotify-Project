# Public Repo Curation Plan

## Goal

Prepare `D:/SpotifyBillboardProject` for a clean public GitHub repository and GitHub Pages deployment.

This is **professional curation, not concealment**.
The public repo should keep the real project deliverables, analysis code, and portfolio website while excluding local-only working state, internal tool traces, and bulky artifacts that do not improve the public story.

## A. Keep In Public Repo

These files and folders directly support the portfolio, the analysis narrative, or the GitHub Pages site:

- `D:/SpotifyBillboardProject/site/`
  - complete static portfolio website
  - copied figure assets used by the deployed site
  - site README and package metadata
- `D:/SpotifyBillboardProject/.github/workflows/deploy-site.yml`
  - GitHub Pages deployment workflow
- `D:/SpotifyBillboardProject/scripts/`
  - core project analysis scripts:
    - `01_data_inspection.R`
    - `01b_build_merged_dataset.R`
    - `01c_clean_analysis_dataset.R`
    - `02_eda.R`
    - `03_hypothesis_testing.R`
    - `04_pca.R`
    - `05_logistic_regression.R`
    - `06_enrich_matching_and_rebuild_dataset.R`
    - `07_era_drift_analysis.R`
    - `08_benchmark_suite.R`
    - `09_robustness_across_dataset_tiers.R`
- `D:/SpotifyBillboardProject/docs/`
  - public-facing summaries and final deliverables:
    - `final_project_report.md`
    - `executive_summary.md`
    - `step1_data_understanding.md`
    - `step2_eda_summary.md`
    - `step2b_cleaning_summary.md`
    - `step3_hypothesis_testing_summary.md`
    - `step4_pca_summary.md`
    - `step5_logistic_regression_summary.md`
    - `step6_matching_enrichment_summary.md`
    - `step7_era_drift_summary.md`
    - `step8_benchmark_summary.md`
    - `step10_robustness_summary.md`
    - `step11_website_summary.md`
    - `public_repo_curation_plan.md`
- `D:/SpotifyBillboardProject/outputs/figures/`
  - final visual outputs used in the website and project story
- Selected compact summary files under `D:/SpotifyBillboardProject/outputs/tables/`
  - `audio_feature_correlation_matrix.csv`
  - `benchmark_model_comparison.csv`
  - `benchmark_model_notes.txt`
  - `benchmark_test_predictions_sample.csv`
  - `cleaning_summary.txt`
  - `data_audit_summary.txt`
  - `eda_group_summary_by_charted.csv`
  - `enriched_cleaning_summary.txt`
  - `enriched_vs_baseline_comparison.csv`
  - `era_counts.csv`
  - `era_drift_summary.txt`
  - `era_feature_means.csv`
  - `era_model_coefficients.csv`
  - `hypothesis_test_results.csv`
  - `hypothesis_test_summary.txt`
  - `logistic_model_summary.txt`
  - `logistic_regression_coefficients.csv`
  - `matching_enrichment_summary.txt`
  - `matching_pass_breakdown.csv`
  - `merge_summary.txt`
  - `pca_explained_variance.csv`
  - `pca_loadings.csv`
  - `recovered_charted_matches.csv`
  - `robustness_coefficient_signs.csv`
  - `robustness_dataset_tier_comparison.csv`
  - `robustness_hypothesis_direction_comparison.csv`
  - `robustness_logistic_comparison.csv`
  - `robustness_pca_comparison.csv`
  - `robustness_summary.txt`
- `D:/SpotifyBillboardProject/README.md`
  - top-level public project overview
- `D:/SpotifyBillboardProject/.gitignore`
  - public-repo hygiene rules
- `D:/SpotifyBillboardProject/data/README.md`
  - note explaining why large local data files are not versioned in the public repo

## B. Exclude From Public Repo

These files are local-only, machine-generated, oversized for a clean public repo, or not meaningful as portfolio deliverables:

- Local IDE and editor state
  - `D:/SpotifyBillboardProject/.Rproj.user/`
  - `D:/SpotifyBillboardProject/.Rhistory`
  - `D:/SpotifyBillboardProject/SpotifyBillboardProject.Rproj`
- Internal Codex state notes and planning traces
  - `D:/SpotifyBillboardProject/docs/codex_project_state.md`
  - `D:/SpotifyBillboardProject/docs/codex_phase3_state.md`
  - `D:/SpotifyBillboardProject/docs/codex_phase_robustness_state.md`
  - `D:/SpotifyBillboardProject/docs/codex_phase_web_state.md`
  - `D:/SpotifyBillboardProject/docs/superpowers/`
- Internal audit and patch logs
  - `D:/SpotifyBillboardProject/outputs/tables/phase2_audit_report.txt`
  - `D:/SpotifyBillboardProject/outputs/tables/phase2_interpretation_patch_log.txt`
  - `D:/SpotifyBillboardProject/outputs/tables/phase3_output_audit.txt`
  - `D:/SpotifyBillboardProject/outputs/tables/project_file_manifest.txt`
- Heavy intermediary artifacts that do not add much value in the public repo
  - `D:/SpotifyBillboardProject/outputs/tables/benchmark_roc_curves.csv`
  - `D:/SpotifyBillboardProject/outputs/tables/benchmark_pr_curves.csv`
  - `D:/SpotifyBillboardProject/outputs/tables/logistic_test_predictions.csv`
  - `D:/SpotifyBillboardProject/outputs/tables/logistic_roc_points.csv`
  - `D:/SpotifyBillboardProject/outputs/tables/pca_scores_pc1_pc2.csv`
  - `D:/SpotifyBillboardProject/outputs/tables/manual_review_candidates.csv`
- Large local datasets kept outside version control
  - all files under `D:/SpotifyBillboardProject/data/raw/`
  - all files under `D:/SpotifyBillboardProject/data/processed/`

Why exclude the data files from the public repo:

- the largest raw Billboard file is over 200 MB and unsuitable for a normal GitHub repository
- the site already deploys from curated figures and helper assets under `site/`
- the public repo remains cleaner when it emphasizes analysis code, conclusions, and portfolio outputs rather than shipping large local CSVs

## C. Review Manually

These items are not needed for the first public release, but could be revisited later if you want a more reproducible or data-heavy companion release:

- whether to publish large raw and processed CSVs in a separate data release, cloud bucket, or Git LFS workflow
- whether to publish heavy curve-point CSVs (`benchmark_roc_curves.csv`, `benchmark_pr_curves.csv`) in a later reproducibility package
- whether to keep the RStudio project file in a collaborator branch for local convenience

## Curation Principle

The public repo should show the real work:

- the analysis pipeline
- the final report and summaries
- the benchmark and robustness conclusions
- the portfolio website

The excluded files are operational leftovers, oversized local data, or internal machine-generated notes.
Nothing is being removed to disguise how the project was made.
