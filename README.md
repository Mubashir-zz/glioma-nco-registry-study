# Objective neurocognitive endpoints in randomized glioma trials

This repository contains the retained trial-level data, reproducible R analysis, publication figures and tables, and manuscript builder for a cross-sectional registry analysis of objective neurocognitive outcome (NCO) registration in randomized phase II, II/III, and III glioblastoma or high-grade glioma therapeutic trials.

The current submission package is formatted for the **Journal of Neuro-Oncology** as an Original Clinical Study. The journal is a close subject-matter fit, permits documented LLM assistance, and offers a subscription publication route without an article-processing charge.

## Study at a glance

- Primary analytic cohort: 289 randomized therapeutic trials.
- Objective NCO registered: 39/289 (13.5%; Wilson 95% CI, 10.0%-17.9%).
- Instrument-confirmed NCO sensitivity definition: 35/289 (12.1%).
- HRQoL registered: 105/282 complete classifications (37.2%; 95% CI, 31.8%-43.0%); 7 classifications were missing.
- Paired discordance: 70 HRQoL-only versus 4 NCO-only trials (uncorrected McNemar P<.001).
- Primary Firth model: academic/investigator sponsorship OR 2.94 (95% CI, 1.28-7.53); government/cooperative sponsorship OR 3.55 (1.14-11.22); radiation-containing intervention OR 2.25 (1.13-4.63).
- Direct sponsor-by-outcome-domain interaction: P=.389, so the sponsor association was not demonstrably specific to cognition.
- Post-2010 ClinicalTrials.gov slope: OR 0.99 per year (95% CI, 0.93-1.07; P=.876).

These are observational, trial-level associations and are not causal effects.

## Reproducible workflow

R 4.3.2 was used for the verified run. Install these packages before running:

```r
install.packages(c("readxl", "logistf", "ggplot2", "dplyr", "tidyr", "patchwork", "pROC"))
```

From this directory, run:

```bash
Rscript gbm_analysis_revised.R
python3 build_revised_manuscript.py
```

The R script can also be invoked from the parent workspace:

```bash
Rscript GBM_Global_Study/gbm_analysis_revised.R
```

The analysis script does not install packages, contains integrity assertions for the core cohort and outcomes, and regenerates all estimates, tables, and figures from the retained data. It uses the Excel matrix when `readxl` is available and otherwise uses the verified analysis CSV.

## Authoritative files

- `GBM_RCT_GLOBAL_Matrix.xlsx`: retained 316-record adjudication matrix; 289 records are in the primary cohort.
- `revised_outputs/analysis_dataset.csv`: analysis-ready trial-level data.
- `gbm_analysis_revised.R`: single analysis and visualization pipeline.
- `gbm_figures.R`: figure definitions, sourced by the analysis script.
- `revised_outputs/analysis_summary.txt`: numerical results and R session information.
- `revised_outputs/tables/`: machine-generated CSV tables, including sensitivity and interaction analyses.
- `revised_outputs/figures/`: publication figures in PDF, PNG, and 600-dpi TIFF formats.
- `build_revised_manuscript.py`: deterministic Word-manuscript builder.
- `revised_submission/GBM_Journal_of_Neuro_Oncology_Revised.docx`: current revised manuscript for author review.

The older `gbm_analysis.R`, `fig2_forest.R`, and `fig3_temporal.R` files are retained only for provenance. They duplicate logic or contain hard-coded values and must not be used for the submitted results. Older figures and manuscript files in the project root are likewise superseded by `revised_outputs/` and `revised_submission/`.

## Cohort provenance and limitations

Records were identified from ClinicalTrials.gov and international trial registries and reconciled using registry and sponsor-protocol identifiers. The reproducible project begins with the retained 316-record adjudication matrix: 289 primary trials, 20 supportive/nontherapeutic exclusions, 6 population exclusions, and 1 adjudicated exclusion. Source-level records rejected during the original international searches were not retained, so the project cannot reproduce a full historical flow from every initial search hit. Screening and abstraction were performed by one investigator without independent duplicate review. These limitations are stated in the manuscript and should not be removed.

## Authorship and assisted revision

Mubashir Ahmad Khan conceived the study, performed the original searches, screening, adjudication, and data collection, and retains responsibility for scientific interpretation and the final submitted work. Ai used for coding assistance, statistical verification. This assistance does not qualify for authorship, but it should be disclosed accurately under the target journal's policy. The manuscript contains a concise disclosure for author review.

## Verified reproduction

Re-run from a clean checkout on R 4.3.2 (3 September 2026):

```bash
Rscript gbm_analysis_revised.R
```

All 17 tables in `revised_outputs/tables/` and `revised_outputs/analysis_summary.txt`
reproduce byte-identically to the committed outputs — including the primary Firth
model (academic sponsorship OR 2.94, 95% CI 1.28–7.53) and the discordance test.
The script asserts the cohort size and event count before estimating anything, so
a silent data change fails the run rather than producing quietly different numbers.

## Licence

Code is MIT. Trial-level data is CC BY 4.0 — see `DATA_LICENSE.md`. No
patient-level data is included; every record is a public trial registration.

## Related work

- [neurocognitive-outcome-classifier](https://github.com/Mubashir-zz/neurocognitive-outcome-classifier) — extending this question across CNS, breast, lung and head & neck with a hand-labelled 1,888-trial gold standard
- [cognitive-outcome-classifier-api](https://github.com/Mubashir-zz/cognitive-outcome-classifier-api) — the deployed classifier that scales the screening step
