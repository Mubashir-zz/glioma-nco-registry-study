# Objective neurocognitive endpoints in randomized glioma trials

[![reproduce analysis](https://github.com/Mubashir-zz/glioma-nco-registry-study/actions/workflows/reproduce.yml/badge.svg)](https://github.com/Mubashir-zz/glioma-nco-registry-study/actions/workflows/reproduce.yml)

This repository contains the retained trial-level data, reproducible R analysis, publication figures and tables, and manuscript builder for a cross-sectional registry analysis of objective neurocognitive outcome (NCO) registration in randomized phase II, II/III, and III glioblastoma or high-grade glioma therapeutic trials.

The current manuscript is under review at **Supportive Care in Cancer**. It lists Mubashir Ahmad Khan, Jacob S. Young, and Weitao Man as authors. The committed manuscript builder and JCE cover-letter draft predate that submission and are retained only as development history; they must not be treated as the submitted manuscript.

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
Rscript gbm_analysis_revised.R        # regenerates every table and figure
python3 build_revised_manuscript.py   # rebuilds revised_submission/MANUSCRIPT.docx
```

Rebuild the manuscript before submitting. An earlier committed `.docx` had drifted
from this script and was missing a figure cross-reference and two citations.

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
- `build_revised_manuscript.py`: deterministic Word-manuscript builder.
- `revised_outputs/analysis_summary.txt`: numerical results and R session information.
- `revised_outputs/tables/`: machine-generated CSV tables, including sensitivity and interaction analyses.
- `revised_outputs/figures/`: publication figures in PDF, PNG, and 600-dpi TIFF formats.
- `revised_submission/`: historical pre-submission build artifacts; these are not the version currently under review.

Superseded scripts and figure sets remain available through git history. The
analysis dataset, scripts, machine-generated tables, and figures are the
reproducibility record. The journal-facing manuscript and correspondence in
`revised_submission/` are historical drafts and are not current submission files.

## Cohort provenance and limitations

Records were identified from ClinicalTrials.gov and international trial registries and reconciled using registry and sponsor-protocol identifiers. The reproducible project begins with the retained 316-record adjudication matrix: 289 primary trials, 20 supportive/nontherapeutic exclusions, 6 population exclusions, and 1 adjudicated exclusion. Source-level records rejected during the original international searches were not retained, so the project cannot reproduce a full historical flow from every initial search hit. Screening and abstraction were performed by one investigator without independent duplicate review. These limitations are stated in the manuscript and should not be removed.

## Authorship and assisted revision

Mubashir Ahmad Khan is the first author and lead analyst. He developed the study with scientific supervision, performed the original searches, screening, adjudication, data collection and R analysis, and prepared the reproducible research files. The current manuscript lists Mubashir Ahmad Khan, Jacob S. Young, and Weitao Man as authors. Exact contribution statements belong to the submitted manuscript and are not reconstructed here. AI tools were used for coding assistance and statistical verification under author review; they did not perform screening or adjudication.

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
- [cognitive-outcome-classifier-api](https://github.com/Mubashir-zz/cognitive-outcome-classifier-api) — the documented serving prototype and deployment evaluation
