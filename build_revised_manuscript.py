from __future__ import annotations

import csv
import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parent
OUTPUTS = ROOT / "revised_outputs"
FIGURES = OUTPUTS / "figures"
TABLES = OUTPUTS / "tables"
SUBMISSION = ROOT / "revised_submission"
SUBMISSION.mkdir(exist_ok=True)

# Journal of Clinical Epidemiology, Original Article. JCE heads the abstract
# Objective / Study Design and Setting / Results / Conclusion, requires a
# "What is new?" box after it, and calls the section Methods.
OUT = SUBMISSION / "MANUSCRIPT.docx"
MANUSCRIPT_TYPE = "Original Article"
ABSTRACT_LABELS = {"Purpose": "Objective", "Methods": "Study Design and Setting"}
METHODS_HEADING = "Methods"


TITLE = (
    "Objective Neurocognitive Endpoints in Randomized Glioblastoma and "
    "High-Grade Glioma Trials: A Cross-Sectional Registry Analysis"
)
RUNNING_TITLE = "Neurocognitive endpoints in glioma trials"
AUTHOR = "Mubashir Ahmad Khan, MBBS"


ABSTRACT = [
    (
        "Purpose",
        "Objective cognitive function is clinically important in glioblastoma, but its position in randomized trial endpoint frameworks is uncertain. We quantified registration of objective neurocognitive outcomes (NCOs), compared it with health-related quality of life (HRQoL), and examined associated trial characteristics across therapeutic modalities."
    ),
    (
        "Methods",
        "We analyzed 289 randomized phase II, II/III, and III therapeutic trials enrolling glioblastoma or high-grade glioma. An NCO required a recognized neuropsychological instrument or a named cognitive domain. Wilson intervals, paired discordance testing, Firth penalized logistic regression, modality-stratified prevalence, a clustered outcome-domain interaction model, E-values, and era-stratified temporal analysis were used."
    ),
    (
        "Results",
        "Among 289 trials, 39 registered an NCO (13.5%; 95% CI, 10.0%-17.9%), including 2 as primary. HRQoL was registered in 105 of 282 complete cases (37.2%; 95% CI, 31.8%-43.0%). Seventy trials registered HRQoL without an NCO and 4 registered an NCO without HRQoL (McNemar P<.001). NCO registration was 19.5% in radiation-containing trials and 6.9% in immunotherapy trials. Academic sponsorship (OR, 2.94; P=.010) and government/cooperative sponsorship (OR, 3.55; P=.030) were associated with NCO registration, but the sponsor-by-domain interaction was not significant (P=.389). Post-2010 registration did not improve (OR, 0.99/year; P=.876)."
    ),
    (
        "Conclusion",
        "Objective cognition was registered less often than HRQoL, was rarely prioritized, and showed modality-specific shortfalls. Adjusted sponsor associations were exploratory and not demonstrably cognition-specific. Standardized registration audits and feasibility-tested cognitive batteries should be evaluated prospectively."
    ),
]

KEY_POINTS = [
    "Objective cognition was registered in 13.5% of trials; HRQoL in 37.2%.",
    "Seventy trials registered HRQoL without an NCO; only 4 did the reverse.",
    "Post-2010 registration did not improve; immunotherapy trials showed the lowest rates.",
]

IMPORTANCE = (
    "This registry audit quantifies a persistent endpoint-selection gap in randomized glioblastoma and high-grade glioma trials. "
    "Unlike prior systematic reviews that evaluated reporting quality after cognition had already been chosen as an outcome, "
    "this study measures whether objective cognition is registered at all and compares it directly with HRQoL within the same trials. "
    "The paired discordance analysis shows that HRQoL-only registration is far more common than NCO-only registration. "
    "Modality-stratified estimates reveal lower NCO registration among immunotherapy trials than among radiation-containing trials. "
    "Adjusted sponsor associations should not be interpreted as cognition-specific because academic sponsorship was also associated with HRQoL registration."
)


WHATS_NEW = [
    (
        "Key findings",
        [
            "Among 289 randomized phase II, II/III, and III glioblastoma or high-grade glioma trials, an objective neurocognitive outcome was registered in 13.5% (95% CI, 10.0%-17.9%) and health-related quality of life in 37.2% (95% CI, 31.8%-43.0%).",
            "Within the same trials, 70 registered HRQoL without objective cognition and 4 did the reverse (McNemar P<.001); only 2 trials designated cognition a primary endpoint.",
            "Registration did not improve after 2010 (odds ratio, 0.99 per year; 95% CI, 0.93-1.07).",
        ],
    ),
    (
        "What this adds to what was known",
        [
            "Earlier reviews assessed how well cognition was reported once a trial had already elected to measure it. This study estimates whether it is elected at all, and compares it against a second patient-centered domain within the same registrations, so the contrast is internal to each trial rather than across separate literatures.",
            "Because no international-only record registered an objective neurocognitive outcome, ordinary logistic regression separated completely and returned an uninterpretable estimate; Firth penalized likelihood recovered estimable associations across all covariates.",
            "A prespecified sponsor-by-outcome-domain interaction (P=.389) shows that the sponsor association was not demonstrably specific to cognition, which a single-outcome model would have obscured.",
        ],
    ),
    (
        "What is the implication and what should change now",
        [
            "Endpoint audits of trial registries should report paired within-trial discordance rather than two independent domain prevalences, because the paired contrast identifies whether a domain is being displaced rather than simply measured less often.",
            "A domain-specific claim about sponsorship, funding, or design should be supported by a formal interaction test against a comparator domain before it is described as specific.",
            "Where a stratum contributes no events, penalized-likelihood estimation should be prespecified rather than adopted after separation is observed.",
        ],
    ),
]


INTRODUCTION = [
    "Cognitive impairment is a frequent and functionally consequential feature of glioblastoma and may reflect tumor burden, treatment effects, comorbidity, or their interaction (1). Objective cognitive change can also provide information that is not captured by survival, radiographic response, performance status, or symptom reporting. For patients living with a brain tumor, preservation of memory, attention, processing speed, language, and executive function may be central to maintaining independence.",
    "Nevertheless, objective cognition has not been consistently integrated into brain-tumor trials. A systematic review of randomized brain-tumor trials found substantial limitations in neurocognitive reporting among studies that had already selected a cognitive outcome (2). Parallel work documented incomplete reporting of patient-reported outcomes (3). These studies addressed reporting after an outcome had entered a protocol or publication; they did not quantify nonselection of objective cognition across the broader randomized therapeutic landscape or compare objective cognition with HRQoL within the same trial registrations.",
    "Objective neuropsychological performance and self-reported HRQoL are related but noninterchangeable constructs. International recommendations support harmonized cognitive measurement in cancer research (9), and neuro-oncology investigators have described the value of standardized batteries in clinical trials (10). Conversely, instruments such as the EORTC QLQ-C30 and QLQ-BN20 measure patient-reported function and symptoms (14,15), while performance-status and neurological examination scales do not constitute objective cognitive testing (13). A trial may therefore assess HRQoL appropriately while leaving objective cognition unmeasured.",
    "We examined the registration of objective NCOs in a retained cohort of randomized phase II/III therapeutic trials enrolling patients with glioblastoma or malignant high-grade glioma across all major therapeutic modalities. The primary objectives were to estimate NCO registration, quantify paired NCO-HRQoL discordance within trials, and assess associations with prespecified trial characteristics. Secondary objectives were to estimate modality-stratified registration, test a stricter instrument-confirmed NCO definition, compare NCO and HRQoL association patterns formally, summarize E-values for key adjusted associations, and evaluate whether NCO registration changed after 2010."
]


METHODS = [
    (
        "Study design and reporting",
        "This cross-sectional registry study used the trial record as the unit of analysis. Reporting was guided by STROBE principles (5). Because only publicly available trial-registration information was analyzed and no participant-level data were obtained, institutional review board review and informed consent were not required."
    ),
    (
        "Data sources and cohort derivation",
        "Trial records had been identified from ClinicalTrials.gov and international trial registries through July 2026 and reconciled using registry identifiers and sponsor-protocol numbers. The retained adjudication matrix contained 316 candidate records: 289 were assigned to the primary analytic cohort, 20 supportive or nontherapeutic records were excluded, 6 records were excluded for population eligibility, and 1 record was excluded after adjudication. The primary cohort comprised 275 ClinicalTrials.gov records and 14 international-only records. Source-level records rejected during the initial international searches were not retained; consequently, the reproducible cohort flow begins with the 316-record adjudication matrix rather than all historical search hits."
    ),
    (
        "Eligibility criteria",
        "Eligible records described randomized, interventional phase II, phase II/III, or phase III therapeutic trials enrolling glioblastoma or malignant high-grade glioma. Therapeutic modalities included surgery, radiation, cytotoxic chemotherapy, targeted or small-molecule treatment, tumor-treating fields, immunotherapy, and combinations (8,16,17). No age restriction was applied in the primary cohort. Nonrandomized, phase 0/I, observational, diagnostic, supportive-care-only, low-grade-glioma-only, brain-metastasis-only, and pan-cancer records without a distinct randomized glioma cohort were excluded. Trials enrolling mixed high-grade glioma were retained and flagged; a strict-glioblastoma sensitivity analysis was prespecified."
    ),
    (
        "Outcome definitions",
        "The primary NCO definition required registration of a recognized objective neuropsychological instrument (for example, the Mini-Mental State Examination, Montreal Cognitive Assessment, Hopkins Verbal Learning Test-Revised, Trail Making Test, or Controlled Oral Word Association Test) or a named cognitive domain described in an objective assessment context. Performance-status scales, the Neurologic Assessment in Neuro-Oncology scale, and subjective cognitive items embedded in HRQoL instruments were not counted as objective NCOs (13-15). Because four NCO-positive records named a cognitive domain without identifying an instrument, an instrument-confirmed sensitivity definition reclassified those records as NCO-negative. NCO designation was categorized as primary, secondary, or exploratory."
    ),
    (
        "HRQoL and trial characteristics",
        "HRQoL registration required a validated patient-reported HRQoL or symptom instrument, including the EORTC QLQ-C30/BN20, FACT-Br, MDASI-BT, EQ-5D, or PROMIS. Seven international records lacked sufficient information for HRQoL classification and were coded as missing rather than negative. Extracted characteristics included phase, registration year, sponsor class, intervention modality, registry source, trial status, planned enrollment, strict-glioblastoma population, and outcome designation. Sponsorship was classified as industry, academic/investigator-initiated, or government/cooperative group. Radiation-containing interventions were identified from the modality field."
    ),
    (
        "Statistical analysis",
        "Proportions are reported with Wilson 95% confidence intervals. Table 1 comparisons used one overall test per characteristic (Fisher exact tests for categorical variables; Wilcoxon rank-sum for planned enrollment). Within-trial NCO-HRQoL discordance was evaluated with an uncorrected McNemar test among complete cases; the absolute prevalence difference was given a bootstrap 95% confidence interval (2000 resamples). The primary multivariable model included phase, sponsor class, centered registration year, radiation-containing intervention, and registry source. Because none of the 14 international-only records registered an NCO, ordinary logistic regression exhibited separation; associations were therefore estimated with Firth penalized-likelihood logistic regression, profile penalized-likelihood confidence intervals, and penalized likelihood-ratio P values (18,19). A nested penalized likelihood-ratio test evaluated whether sponsor class added information beyond the other covariates. Apparent discrimination was summarized with the area under the receiver-operating-characteristic curve and Brier score; optimism-corrected AUC was obtained by Harrell bootstrap (400 replicates). Sponsor-specific adjusted probabilities were estimated by marginal standardization."
    ),
    (
        "Comparative, modality, and sensitivity analyses",
        "The same Firth model was fitted for HRQoL among complete cases. To test rather than assume that sponsorship operated differently for NCO and HRQoL, the two outcomes were stacked within trial and analyzed with a logistic model containing outcome-domain-by-sponsor interactions and trial-clustered robust covariance; the joint two-degree-of-freedom interaction was the prespecified specificity test. Modality-stratified NCO prevalence was estimated for trials containing radiation, cytotoxic chemotherapy, immunotherapy, targeted therapy, surgery, or tumor-treating fields; trials could contribute to more than one modality stratum. Among NCO-positive trials, registered instruments were mapped to the International Cognition and Cancer Task Force (ICCTF) core of HVLT-R, Trail Making Test, and COWAT (9). E-values were calculated for primary NCO associations. Temporal analysis was restricted to ClinicalTrials.gov records: a binomial GAM described the overall time trend, a Firth model estimated the post-2010 annual slope, and centered 5-year rolling percentages compared industry with non-industry trials in windows with at least 12 records. Sensitivity analyses used the instrument-confirmed NCO definition, restricted the cohort to strict glioblastoma, excluded four pediatric-title records, restricted to ClinicalTrials.gov, and adjusted for log2 planned enrollment. These analyses were treated as exploratory; no multiplicity-adjusted confirmatory claims were made. Two-sided P<.05 was used. Analyses were performed in R version 4.3.2."
    ),
    (
        "Reproducibility",
        "A single top-to-bottom R script reads the retained source matrix, verifies cohort counts and agreement with the legacy analytic CSV, fits every reported model, and regenerates all tables and figures without hard-coded estimates. The script records package versions and session information and stops if expected cohort counts or classifications change. During revision, OpenAI Codex was used for language editing, coding assistance, statistical verification, and figure formatting. The author reran the complete analysis, checked all reported values against machine-generated outputs, and retained responsibility for every scientific and analytic decision."
    ),
]


RESULTS = [
    (
        "Cohort characteristics",
        "The retained adjudication matrix contained 316 records; 27 were excluded and 289 randomized therapeutic trials formed the primary cohort. The cohort included 180 phase II, 18 phase II/III, and 91 phase III trials. Sponsors were academic/investigator-initiated for 145 trials, industry for 101, and government/cooperative group for 43. Two hundred thirty-nine trials (82.7%) enrolled a strict glioblastoma population, 123 (42.6%) contained a radiation intervention, and 14 (4.8%) were international-only records. Positive planned enrollment was available for 261 trials; the median was 118 participants (IQR, 60-204). NCO-positive trials had higher planned enrollment (median, 158; IQR, 94-299; P=.022) (Table 1)."
    ),
    (
        "Registration and prioritization of cognition",
        "An objective NCO was registered in 39 of 289 trials (13.5%; 95% CI, 10.0%-17.9%). Only 2 of these 39 trials designated cognition as a primary endpoint. Among NCO-positive trials, 13 (33%) registered any ICCTF core test, 6 (15%) registered the full HVLT-R/TMT/COWAT battery, and 18 (46%) registered MMSE or MoCA without an ICCTF core test (Figure 5; Supplementary Figure S1). Under the instrument-confirmed definition, 35 of 289 trials (12.1%) remained NCO-positive."
    ),
    (
        "Paired discordance with HRQoL",
        "HRQoL was registered in 105 of 282 trials with complete classification (37.2%; 95% CI, 31.8%-43.0%). The absolute prevalence difference versus NCO was 23.4 percentage points (bootstrap 95% CI, 18.4-28.7). Among complete cases, 173 trials registered neither domain, 70 registered HRQoL without an NCO, 4 registered an NCO without HRQoL, and 35 registered both (Figure 1). The within-trial asymmetry was substantial (McNemar P<.001)."
    ),
    (
        "Modality-stratified registration",
        "NCO registration varied across intervention categories. Among trials containing the relevant modality, registration was 19.5% (24/123) for radiation, 14.9% (13/87) for targeted therapy, 12.2% (22/180) for cytotoxic chemotherapy, 6.9% (4/58) for immunotherapy, and 5.6% (3/54) for surgery. Tumor-treating fields had the highest point estimate but was based on 9 trials (2/9; 22.2%) (Figure 2)."
    ),
    (
        "Adjusted associations with NCO registration",
        "The primary Firth model was significant overall (penalized likelihood-ratio chi-square=20.66 on 7 df; P=.004). Adding sponsor class improved fit relative to a model containing only phase, year, radiation, and registry source (nested penalized LR chi-square=11.20 on 2 df; P=.004). Relative to industry sponsorship, academic/investigator-initiated sponsorship was associated with greater NCO registration (OR, 2.94; 95% CI, 1.28-7.53; P=.010), as was government/cooperative-group sponsorship (OR, 3.55; 95% CI, 1.14-11.22; P=.030). Later registration year (OR, 1.05 per year; 95% CI, 1.00-1.11; P=.031) and radiation-containing intervention (OR, 2.25; 95% CI, 1.13-4.63; P=.022) were also associated with NCO registration (Table 2; Figure 3A). Apparent AUC was 0.73 and optimism-corrected AUC was 0.69; the Brier score was 0.107. Marginally adjusted NCO probabilities were 7.3% for industry, 18.0% for academic/investigator, and 20.7% for government/cooperative sponsorship (Figure 3B)."
    ),
    (
        "Comparator and temporal analyses",
        "The corresponding HRQoL model was also significant overall (likelihood-ratio chi-square=17.25 on 7 df; P=.016). Academic/investigator sponsorship (OR, 1.76; 95% CI, 1.02-3.10; P=.043), phase III (OR, 1.79; 95% CI, 1.03-3.13; P=.040), and later registration year (OR, 1.05; 95% CI, 1.01-1.08; P=.011) were associated with HRQoL registration. The joint sponsor-by-outcome-domain interaction was not significant (Wald chi-square=1.89 on 2 df; P=.389). A binomial GAM on ClinicalTrials.gov records showed an early rise and a post-2010 plateau; the post-2010 Firth slope was null (OR, 0.99/year; 95% CI, 0.93-1.07; P=.876). Five-year rolling percentages remained lower for industry than for non-industry trials after 2015 (Figure 4)."
    ),
    (
        "Sensitivity analyses",
        "Academic/investigator sponsorship remained associated with NCO registration in all prespecified sensitivity analyses (Supplementary Figure S2). Government/cooperative sponsorship remained associated in the strict-glioblastoma, pediatric-title-excluded, ClinicalTrials.gov-only, and enrollment-adjusted analyses, but not under the instrument-confirmed definition (OR, 3.08; 95% CI, 0.86-10.84; P=.083). Radiation was attenuated in the strict-glioblastoma (P=.082) and enrollment-adjusted (P=.078) models. These changes indicate that the direction of several associations was consistent, but their statistical stability depended on outcome definition and analytic subset."
    ),
]


DISCUSSION = [
    "In this retained cohort of 289 randomized therapeutic glioblastoma and high-grade glioma trials, objective cognition was registered in approximately one in seven trials and was designated as primary in only two. HRQoL was registered nearly three times as often among trials with complete classification. The paired discordance analysis showed that HRQoL-only registration was far more common than NCO-only registration, indicating that trials often capture patient-reported function without registering objective cognitive performance. Post-2010 analyses showed no sustained improvement. Together, these findings identify a persistent endpoint-selection gap rather than merely a reporting-quality problem.",
    "The distinction between outcome domains is clinically important. HRQoL instruments capture patients' perceptions of symptoms and function and should remain central to trial evaluation. Objective cognitive tests address a different construct and can provide standardized performance data in domains such as learning, processing speed, and executive function (9,10). Performance-status scales and structured neurological examinations likewise serve important purposes but do not replace neuropsychological assessment (13). The present analysis therefore does not argue for substituting cognition for HRQoL; it supports considering both when the intervention or disease is plausibly relevant to cognitive function.",
    "Modality-stratified estimates suggest that the endpoint gap is not uniform across the therapeutic landscape. NCO registration was lower among immunotherapy and surgical trials than among radiation-containing trials, complementing prior descriptions of heterogeneous endpoint operationalization in glioblastoma immunotherapy trials (4). This pattern may reflect trial-design conventions, perceived feasibility, or the historical integration of cognitive testing into chemoradiation protocols (12), but the registry data alone cannot distinguish these explanations. The modality findings nonetheless identify where future endpoint-harmonization efforts may have the greatest leverage.",
    "Sponsorship was associated with NCO registration after adjustment, with higher estimated probabilities in academic/investigator and government/cooperative trials than in industry trials. This association should not be interpreted causally or as cognition-specific. Trial size, disease setting, intervention type, network infrastructure, assessment burden, registration practices, and unmeasured design priorities may confound or mediate the observed relationship. HRQoL registration was also associated with academic/investigator sponsorship, and the formal sponsor-by-domain interaction was not significant. The available data therefore do not establish that industry sponsorship selectively suppresses cognition relative to HRQoL; explanations involving commercial strategy remain hypotheses rather than results.",
    "The temporal findings sharpen the implementation problem. The all-year linear term was modestly positive, but the GAM and the post-2010 slope were consistent with an early increase followed by a prolonged plateau. Rolling estimates suggested that the later plateau was more pronounced among industry-sponsored trials, although those rolling windows remain descriptive. Because only 39 NCO events were available, highly parameterized temporal models would risk overfitting.",
    "Among the minority of trials that did register cognition, the instruments often were not those recommended for cancer trials. MMSE or MoCA without an ICCTF core test was more common than the full HVLT-R, Trail Making, and COWAT battery. That distinction matters: screening tools designed for dementia detection are not interchangeable with a core neuropsychological battery intended to detect treatment-related cognitive change (9,10).",
    "Trial protocols could be asked to justify inclusion or exclusion of objective cognition using an outcome-domain framework consistent with CONSORT-Outcomes principles (7). A brief ICCTF-based core battery, centralized training, and assessment schedules aligned with imaging visits are candidate remedies, but they should be tested for feasibility and data completeness before being treated as standards (6,11).",
    "This study has strengths: explicit separation of objective cognition from HRQoL and neurological/performance scales, trial-level paired comparison, modality stratification, Firth estimation for separation, direct testing of outcome-domain specificity, E-value reporting, multiple outcome-definition and population sensitivities, and a data-derived reproducibility pipeline. The analysis also has important limitations. It evaluates current retained registry fields rather than outcomes actually administered or reported. Registry entries can be retrospective or modified; original versions and record histories were not available. Source-level records excluded during the initial international searches were not retained, so the full historical search and deduplication process cannot be reproduced from the present project. Screening and abstraction were performed by one investigator without independent second-reviewer validation. Seven HRQoL classifications were missing, 50 trials included mixed high-grade glioma, four titles explicitly referenced pediatric populations, and four NCO-positive records lacked a named instrument. Sponsor class was broad, and potentially important confounders such as newly diagnosed versus recurrent disease, cooperative-network participation, prospective registration, and detailed assessment timing were unavailable. Finally, 39 NCO events limited model complexity and precision; all multivariable and sensitivity associations should be considered exploratory.",
    "Future work should preserve complete source-level search exports, retrieve registry version histories, use independent duplicate screening, validate registry fields against trial protocols, and prospectively evaluate whether protocol-level cognitive endpoints translate into analyzable longitudinal data. Linking registration to protocols, statistical analysis plans, publications, and data-completeness reporting would also distinguish endpoint intention from implementation."
]

CONCLUSION = (
    "Objective cognition was infrequently registered and rarely prioritized in randomized glioblastoma and high-grade glioma trials, with HRQoL-only registration far more common than NCO-only registration and no evidence of improvement after 2010. Modality-stratified estimates highlight particular shortfalls among immunotherapy trials. Trial sponsorship and other design features were associated with registration, but the associations were exploratory and not demonstrably cognition-specific. Transparent outcome-domain justification, reproducible registration audits, and feasibility-tested standardized cognitive assessment should be evaluated as strategies to close this measurement gap."
)


REFERENCES = [
    "Ghadimi K, Abbas I, Karandish A, et al. Cognitive decline in glioblastoma patients with different treatment modalities and insights on untreated cases. Curr Oncol. 2025;32(3):152.",
    "Habets EJJ, Taphoorn MJB, Klein M, et al. The level of reporting of neurocognitive outcomes in randomised controlled trials of brain tumour patients: a systematic review. Eur J Cancer. 2018;100:104-125.",
    "Dirven L, Taphoorn MJB, Reijneveld JC, et al. The level of patient-reported outcome reporting in randomised controlled trials of brain tumour patients: a systematic review. Eur J Cancer. 2014;50(14):2432-2448.",
    "Schonfeld E, Choi J, Tran A, et al. The landscape of immune checkpoint inhibitor clinical trials in glioblastoma: a systematic review. Neurooncol Adv. 2024;6(1):vdae174.",
    "von Elm E, Altman DG, Egger M, et al; STROBE Initiative. The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement. Lancet. 2007;370(9596):1453-1457.",
    "Proctor E, Silmere H, Raghavan R, et al. Outcomes for implementation research: conceptual distinctions, measurement challenges, and research agenda. Adm Policy Ment Health. 2011;38(2):65-76.",
    "Butcher NJ, Monsour A, Mew EJ, et al. Guidelines for reporting outcomes in trial reports: the CONSORT-Outcomes 2022 extension. JAMA. 2022;328(22):2252-2264.",
    "Stupp R, Mason WP, van den Bent MJ, et al. Radiotherapy plus concomitant and adjuvant temozolomide for glioblastoma. N Engl J Med. 2005;352(10):987-996.",
    "Wefel JS, Vardy J, Ahles T, Schagen SB. International Cognition and Cancer Task Force recommendations to harmonise studies of cognitive function in patients with cancer. Lancet Oncol. 2011;12(7):703-708.",
    "Meyers CA, Brown PD. Role and relevance of neurocognitive assessment in clinical trials of patients with CNS tumors. J Clin Oncol. 2006;24(8):1305-1309.",
    "Gehring K, Sitskoorn MM, Aaronson NK, Taphoorn MJB. Interventions for cognitive deficits in adults with brain tumours. Lancet Neurol. 2008;7(6):548-560.",
    "Armstrong TS, Wefel JS, Wang M, et al. Net clinical benefit analysis of Radiation Therapy Oncology Group 0525. J Clin Oncol. 2013;31(32):4076-4084.",
    "Nayak L, DeAngelis LM, Brandes AA, et al. The Neurologic Assessment in Neuro-Oncology (NANO) scale. Neuro Oncol. 2017;19(5):625-635.",
    "Aaronson NK, Ahmedzai S, Bergman B, et al. The European Organization for Research and Treatment of Cancer QLQ-C30. J Natl Cancer Inst. 1993;85(5):365-376.",
    "Taphoorn MJB, Claassens L, Aaronson NK, et al. An international validation study of the EORTC QLQ-BN20. Eur J Cancer. 2010;46(6):1033-1040.",
    "Wen PY, Weller M, Lee EQ, et al. Glioblastoma in adults: a Society for Neuro-Oncology and European Association of Neuro-Oncology consensus review. Neuro Oncol. 2020;22(8):1073-1113.",
    "Weller M, van den Bent M, Preusser M, et al. European Association of Neuro-Oncology guidelines on the diagnosis and treatment of diffuse gliomas of adulthood. Nat Rev Clin Oncol. 2021;18(3):170-186.",
    "Firth D. Bias reduction of maximum likelihood estimates. Biometrika. 1993;80(1):27-38.",
    "Heinze G, Schemper M. A solution to the problem of separation in logistic regression. Stat Med. 2002;21(16):2409-2419.",
]


FIGURE_CAPTIONS = [
    (
        "Figure 1",
        "Paired registration of objective neurocognitive outcomes (NCOs) and health-related quality of life (HRQoL) among 282 complete-case trials. (A) Counts stacked by NCO status within HRQoL status. (B) Discordant pairs used in the McNemar test (70 versus 4; P<.001). The absolute prevalence difference, HRQoL minus NCO, was 23.4 percentage points (bootstrap 95% CI, 18.4-28.7).",
        "Stacked bars show 173 trials with neither endpoint, 4 with NCO only, 70 with HRQoL only, and 35 with both. The discordant-pair panel contrasts 70 HRQoL-only trials with 4 NCO-only trials."
    ),
    (
        "Figure 2",
        "Modality-stratified registration of objective NCOs, ordered by stratum size. Squares are Wilson point estimates; bars are 95% CIs. The dashed line is the cohort prevalence (13.5%). Trials may belong to more than one modality. Tumor-treating fields is based on 9 trials.",
        "Radiation-containing trials register cognition more often than immunotherapy or surgical trials. Tumor-treating fields has a high point estimate but a very wide confidence interval."
    ),
    (
        "Figure 3",
        "Adjusted associations with objective NCO registration. (A) Firth odds ratios with profile penalized-likelihood 95% CIs; the international-only term is omitted from the plotted scale because 0 of 14 events produces complete separation. (B) Marginally standardized NCO probabilities by sponsor class.",
        "Academic and government or cooperative sponsorship have odds ratios above one relative to industry. Adjusted probabilities are 7.3% for industry, 18.0% for academic or investigator, and 20.7% for government or cooperative sponsorship."
    ),
    (
        "Figure 4",
        "Temporal pattern among 275 ClinicalTrials.gov trials. (A) Annual trial volume. (B) Observed yearly percentages for years with at least 5 trials and a binomial GAM smooth with 95% interval; the dotted line marks 2010. (C) Centered 5-year rolling NCO percentages for industry versus non-industry trials; windows with fewer than 12 trials are omitted. The post-2010 Firth slope was OR 0.99 per year (95% CI, 0.93-1.07; P=.876).",
        "Registration rose before 2010 and then plateaued. After 2015, rolling industry estimates remain lower than non-industry estimates."
    ),
    (
        "Figure 5",
        "Endpoint prevalence and instrument quality. (A) Wilson 95% CIs for NCO (N=289) and HRQoL (N=282 complete cases). (B) Among 39 NCO-positive trials, registration of any ICCTF core test, the full HVLT-R/TMT/COWAT battery, MMSE or MoCA without a core test, or a named domain only.",
        "HRQoL is registered far more often than objective cognition. Among trials that did register cognition, MMSE or MoCA without an ICCTF core test was more common than the full recommended battery."
    ),
]

SUPPLEMENT_CAPTIONS = [
    (
        "Supplementary Figure S1",
        "Registered objective neurocognitive instruments among 39 NCO-positive trials after within-trial synonym mapping. Navy bars are ICCTF core tests (HVLT-R, Trail Making Test, COWAT). A trial can contribute to more than one instrument.",
        "MMSE is the most common instrument. ICCTF core tests appear less often than MMSE."
    ),
    (
        "Supplementary Figure S2",
        "Sensitivity of the academic-versus-industry odds ratio for NCO registration across prespecified analytic variants. Squares are Firth odds ratios; bars are profile penalized-likelihood 95% CIs.",
        "The academic sponsor association remains above one in every sensitivity analysis."
    ),
]


def word_count(text: str) -> int:
    return len(re.findall(r"\b[\w'-]+\b", text))


abstract_words = sum(word_count(label) + word_count(text) for label, text in ABSTRACT)
importance_words = word_count(IMPORTANCE)
body_texts = INTRODUCTION + [text for _, text in METHODS] + [text for _, text in RESULTS] + DISCUSSION + [CONCLUSION]
body_words = sum(word_count(x) for x in body_texts)
assert abstract_words <= 250, abstract_words
assert importance_words <= 150, importance_words
assert len(KEY_POINTS) in (2, 3)
assert sum(len(x) for x in KEY_POINTS) <= 260
assert all(len(x) <= 85 for x in KEY_POINTS)
assert len(TITLE) <= 160
assert len(RUNNING_TITLE) <= 50
assert body_words <= 5500


def set_cell_border(cell, **kwargs):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_borders = tc_pr.first_child_found_in("w:tcBorders")
    if tc_borders is None:
        tc_borders = OxmlElement("w:tcBorders")
        tc_pr.append(tc_borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        if edge in kwargs:
            tag = "w:" + edge
            element = tc_borders.find(qn(tag))
            if element is None:
                element = OxmlElement(tag)
                tc_borders.append(element)
            for key, value in kwargs[edge].items():
                element.set(qn("w:" + key), str(value))


def clear_table_borders(table):
    for row in table.rows:
        for cell in row.cells:
            no_border = {"val": "nil"}
            set_cell_border(
                cell, top=no_border, bottom=no_border,
                left=no_border, right=no_border, insideH=no_border, insideV=no_border
            )


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_cell_margins(cell, top=70, start=85, bottom=70, end=85):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for name, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn("w:" + name))
        if node is None:
            node = OxmlElement("w:" + name)
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_run_font(run, name="Times New Roman", size=11, bold=None, italic=None):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


def set_alt_text(inline_shape, description):
    doc_pr = inline_shape._inline.docPr
    doc_pr.set("descr", description)
    doc_pr.set("title", description.split(".")[0][:100])


def add_page_field(paragraph):
    run = paragraph.add_run()
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = " PAGE "
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.append(fld_char1)
    run._r.append(instr_text)
    run._r.append(fld_char2)
    set_run_font(run, size=9)


doc = Document()
section = doc.sections[0]
section.top_margin = Inches(0.85)
section.bottom_margin = Inches(0.8)
section.left_margin = Inches(0.9)
section.right_margin = Inches(0.9)

styles = doc.styles
normal = styles["Normal"]
normal.font.name = "Times New Roman"
normal._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
normal.font.size = Pt(11)
normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.DOUBLE
normal.paragraph_format.space_after = Pt(0)

for style_name, size, before, after in (
    ("Heading 1", 13, 12, 4),
    ("Heading 2", 11, 8, 2),
):
    style = styles[style_name]
    style.font.name = "Times New Roman"
    style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    style.font.size = Pt(size)
    style.font.bold = True
    style.font.color.rgb = RGBColor(0, 0, 0)
    style.paragraph_format.space_before = Pt(before)
    style.paragraph_format.space_after = Pt(after)
    style.paragraph_format.keep_with_next = True

if "Table Text" not in styles:
    table_style = styles.add_style("Table Text", WD_STYLE_TYPE.PARAGRAPH)
else:
    table_style = styles["Table Text"]
table_style.font.name = "Times New Roman"
table_style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
table_style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
table_style.font.size = Pt(8.5)
table_style.paragraph_format.line_spacing = 1.0
table_style.paragraph_format.space_after = Pt(0)

footer = section.footer.paragraphs[0]
footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
add_page_field(footer)


def add_heading(text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.add_run(text)
    return p


def add_text(text, bold_label=None, italic=False, alignment=None, keep=False):
    text = re.sub(r"\(((?:\d+\s*[-,]\s*)*\d+)\)", r"[\1]", text)
    p = doc.add_paragraph()
    if alignment is not None:
        p.alignment = alignment
    if keep:
        p.paragraph_format.keep_with_next = True
    if bold_label:
        r = p.add_run(bold_label)
        set_run_font(r, bold=True)
        r = p.add_run(text)
        set_run_font(r)
    else:
        r = p.add_run(text)
        set_run_font(r, italic=italic)
    return p


# Title page
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.space_after = Pt(18)
r = p.add_run(TITLE)
set_run_font(r, size=16, bold=True)

add_text(AUTHOR, alignment=WD_ALIGN_PARAGRAPH.CENTER)
add_text("Independent Researcher", alignment=WD_ALIGN_PARAGRAPH.CENTER)
p = add_text("[CITY, COUNTRY]", alignment=WD_ALIGN_PARAGRAPH.CENTER)
for r in p.runs:
    r.font.highlight_color = 7

doc.add_paragraph()
add_text(f"Running title: {RUNNING_TITLE}")
add_text(f"Manuscript type: {MANUSCRIPT_TYPE}")
add_text(f"Abstract word count: {abstract_words}")
add_text(f"Main-text word count: {body_words}")
add_text("Main tables: 2")
add_text("Main figures: 5")
add_text("Supplementary tables: 3")
add_text("Supplementary figures: 2")
add_text(f"References: {len(REFERENCES)}")

doc.add_paragraph()
add_text("Corresponding author: Mubashir Ahmad Khan, MBBS")
add_text("Email: khanmubashirahmad@gmail.com")
p = add_text("[POSTAL ADDRESS AND TELEPHONE]")
for r in p.runs:
    r.font.highlight_color = 7

doc.add_page_break()

# Abstract and required front matter
add_heading("Abstract")
for label, text in ABSTRACT:
    add_text(text, bold_label=f"{ABSTRACT_LABELS.get(label, label)}. ")

p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.5
r = p.add_run("Keywords: ")
set_run_font(r, bold=True)
r = p.add_run("glioblastoma; high-grade glioma; neurocognition; clinical trials; outcomes")
set_run_font(r)

# JCE requires a "What is new?" box immediately after the abstract.
add_heading("What is new?")
for section, bullets in WHATS_NEW:
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_after = Pt(2)
    set_run_font(p.add_run(section), bold=True)
    for bullet in bullets:
        b = doc.add_paragraph(style="List Bullet")
        b.paragraph_format.line_spacing = 1.5
        b.paragraph_format.space_after = Pt(2)
        set_run_font(b.add_run(bullet))
doc.add_paragraph()

# Main text
add_heading("Introduction")
for paragraph in INTRODUCTION:
    add_text(paragraph)

add_heading(METHODS_HEADING)
for heading, paragraph in METHODS:
    add_heading(heading, level=2)
    add_text(paragraph)

add_heading("Results")
for heading, paragraph in RESULTS:
    add_heading(heading, level=2)
    add_text(paragraph)

add_heading("Discussion")
for paragraph in DISCUSSION:
    add_text(paragraph)

add_heading("Conclusion")
add_text(CONCLUSION)

add_heading("Acknowledgments")
add_text("None.")

# References
add_heading("References")
for idx, reference in enumerate(REFERENCES, 1):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Inches(-0.25)
    p.paragraph_format.left_indent = Inches(0.25)
    p.paragraph_format.line_spacing = 1.0
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run(f"{idx}. {reference}")
    set_run_font(r, size=9)

# Statements and declarations required by Journal of Clinical Epidemiology
add_heading("Statements and Declarations")
add_heading("Funding", level=2)
add_text("The author declares that no funds, grants, or other support were received during the preparation of this manuscript.")
add_heading("Competing Interests", level=2)
add_text("The author has no relevant financial or non-financial interests to disclose.")
add_heading("Author Contributions", level=2)
add_text("Mubashir Ahmad Khan: conceptualization, methodology, investigation, data curation, formal analysis, visualization, writing-original draft, writing-review and editing, and final accountability for the work.")
add_heading("Data Availability", level=2)
add_text("The retained trial-level matrix, analysis dataset, complete R script, machine-generated tables, and figure files are publicly available at https://github.com/Mubashir-zz/glioma-nco-registry-study. Code is released under the MIT Licence and trial-level data under CC BY 4.0. No participant-level data were used.")
add_heading("Ethics Approval", level=2)
add_text("This study analyzed publicly available trial-registration records and did not involve human participants or identifiable participant-level data. Institutional review board approval and informed consent were not required.")
add_heading("Use of Generative AI and AI-Assisted Technologies", level=2)
add_text("During revision, OpenAI Codex was used for language editing, coding assistance, statistical verification, and figure formatting. The author reviewed the source data, reran the complete analysis, verified the reported values, and takes full responsibility for the manuscript and all analytic decisions.")

# Figure captions and required alt text
add_heading("Figure Captions")
for label, caption, alt_text in FIGURE_CAPTIONS:
    p = doc.add_paragraph()
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.DOUBLE
    r = p.add_run(f"{label}. ")
    set_run_font(r, bold=True)
    r = p.add_run(caption)
    set_run_font(r)
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.DOUBLE
    r = p.add_run("Alt text: ")
    set_run_font(r, italic=True)
    r = p.add_run(alt_text)
    set_run_font(r)

add_heading("Supplementary Figure Captions")
for label, caption, alt_text in SUPPLEMENT_CAPTIONS:
    p = doc.add_paragraph()
    p.paragraph_format.keep_with_next = True
    r = p.add_run(f"{label}. ")
    set_run_font(r, bold=True)
    r = p.add_run(caption)
    set_run_font(r)
    p = doc.add_paragraph()
    r = p.add_run("Alt text: ")
    set_run_font(r, italic=True)
    r = p.add_run(alt_text)
    set_run_font(r)


def load_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def add_table_title(title):
    doc.add_page_break()
    p = doc.add_paragraph()
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.space_after = Pt(5)
    r = p.add_run(title)
    set_run_font(r, size=11, bold=True)


def style_table(table, widths, numeric_cols=()):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    clear_table_borders(table)
    for row_idx, row in enumerate(table.rows):
        for col_idx, cell in enumerate(row.cells):
            cell.width = widths[col_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_margins(cell)
            for p in cell.paragraphs:
                p.style = styles["Table Text"]
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER if col_idx in numeric_cols else WD_ALIGN_PARAGRAPH.LEFT
                for run in p.runs:
                    set_run_font(run, size=8.5, bold=(row_idx == 0))
    set_repeat_table_header(table.rows[0])
    thin = {"val": "single", "sz": "6", "color": "000000"}
    for cell in table.rows[0].cells:
        set_cell_border(cell, top=thin, bottom=thin)
    for cell in table.rows[-1].cells:
        set_cell_border(cell, bottom=thin)


# Table 1
table1_rows = load_csv(TABLES / "table1_characteristics.csv")
add_table_title("Table 1. Characteristics of the Primary Analytic Cohort")
table = doc.add_table(rows=1, cols=5)
headers = ["Characteristic", "Overall\n(N=289)", "NCO absent\n(n=250)", "NCO registered\n(n=39)", "P value"]
for i, header in enumerate(headers):
    table.rows[0].cells[i].text = header
for row in table1_rows:
    cells = table.add_row().cells
    cells[0].text = row["Characteristic"]
    cells[1].text = row["Overall"]
    cells[2].text = row["NCO absent"]
    cells[3].text = row["NCO registered"]
    cells[4].text = row["P value"]
style_table(table, [Inches(2.55), Inches(0.95), Inches(0.95), Inches(1.05), Inches(0.65)], numeric_cols=(1, 2, 3, 4))
p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.0
r = p.add_run("Values are n (%) unless otherwise indicated. P values are overall tests for each characteristic (Fisher exact for categorical variables; Wilcoxon rank-sum for planned enrollment), not row-wise dummy tests. IQR, interquartile range; NCO, neurocognitive outcome.")
set_run_font(r, size=8.5)

# Table 2
table2_rows = load_csv(TABLES / "table2_adjusted_models.csv")
add_table_title("Table 2. Adjusted Firth Models for Objective NCO and HRQoL Registration")
table = doc.add_table(rows=1, cols=4)
for i, header in enumerate(["Outcome and predictor", "Odds ratio", "95% CI", "P"]):
    table.rows[0].cells[i].text = header
current_outcome = None
for row in table2_rows:
    if row["Outcome"] != current_outcome:
        section_row = table.add_row().cells
        section_row[0].merge(section_row[3])
        section_row[0].text = row["Outcome"]
        for run in section_row[0].paragraphs[0].runs:
            set_run_font(run, size=8.5, bold=True)
        current_outcome = row["Outcome"]
    cells = table.add_row().cells
    cells[0].text = row["Predictor"]
    cells[1].text = row["Odds ratio"]
    cells[2].text = row["95% CI"]
    cells[3].text = row["P"]
style_table(table, [Inches(3.65), Inches(0.85), Inches(1.20), Inches(0.65)], numeric_cols=(1, 2, 3))
p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.0
r = p.add_run("Reference categories are phase II, industry sponsor, no radiation-containing intervention, and ClinicalTrials.gov. NCO model: N=289, 39 events; overall penalized likelihood-ratio chi-square=20.66 on 7 df, P=.004. HRQoL complete-case model: N=282, 105 events; overall chi-square=17.25 on 7 df, P=.016. CI, confidence interval; HRQoL, health-related quality of life; NCO, neurocognitive outcome.")
set_run_font(r, size=8.5)

# Supplementary Table S1
table3_rows = load_csv(TABLES / "table3_discordance.csv")
add_table_title("Supplementary Table S1. Paired Registration of Objective NCOs and HRQoL")
table = doc.add_table(rows=1, cols=3)
for i, header in enumerate(["Registration pattern", "Trials, n (%)", "Complete-case fraction"]):
    table.rows[0].cells[i].text = header
for row in table3_rows:
    cells = table.add_row().cells
    cells[0].text = row["Registration pattern"]
    cells[1].text = row["Trials, n (%)"]
    cells[2].text = row["Among complete cases (N=282)"]
style_table(table, [Inches(2.35), Inches(1.35), Inches(1.55)], numeric_cols=(1, 2))
p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.0
r = p.add_run("Complete-case analysis includes 282 trials with nonmissing classification for both domains. McNemar test for within-trial discordance, P<.001. HRQoL, health-related quality of life; NCO, neurocognitive outcome.")
set_run_font(r, size=8.5)

# Supplementary Table S2
table4_rows = load_csv(TABLES / "table4_modality_prevalence.csv")
add_table_title("Supplementary Table S2. Modality-Stratified Registration of Objective NCOs")
table = doc.add_table(rows=1, cols=4)
for i, header in enumerate(["Modality stratum", "Trials, n", "NCO registered, n", "Percent (95% CI)"]):
    table.rows[0].cells[i].text = header
for row in table4_rows:
    cells = table.add_row().cells
    cells[0].text = row["Modality"]
    cells[1].text = str(row["Trials"])
    cells[2].text = str(row["NCO registered"])
    cells[3].text = row["Percent (95% CI)"]
style_table(table, [Inches(2.35), Inches(0.85), Inches(1.15), Inches(1.35)], numeric_cols=(1, 2, 3))
p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.0
r = p.add_run("Trials could contribute to more than one modality stratum. Percentages use Wilson 95% confidence intervals. NCO, neurocognitive outcome.")
set_run_font(r, size=8.5)

# Supplementary Table S3
table5_rows = load_csv(TABLES / "table5_evalues.csv")
add_table_title("Supplementary Table S3. E-values for Selected Adjusted NCO Associations")
table = doc.add_table(rows=1, cols=5)
for i, header in enumerate(["Predictor", "Odds ratio", "Lower 95% CI", "Point E-value", "CI-bound E-value"]):
    table.rows[0].cells[i].text = header
for row in table5_rows:
    cells = table.add_row().cells
    cells[0].text = row["Predictor"]
    cells[1].text = f'{float(row["Odds ratio"]):.2f}'
    cells[2].text = f'{float(row["95% CI lower"]):.2f}'
    cells[3].text = row["E-value (point)"]
    cells[4].text = row["E-value (CI bound)"]
style_table(table, [Inches(2.45), Inches(0.75), Inches(0.85), Inches(0.85), Inches(0.95)], numeric_cols=(1, 2, 3, 4))
p = doc.add_paragraph()
p.paragraph_format.line_spacing = 1.0
r = p.add_run("E-values quantify the minimum strength of association, on the risk-ratio scale, that an unmeasured confounder would need with both exposure and outcome to explain away the observed association. Because the observed outcome was uncommon, odds ratios were used as risk-ratio approximations. These analyses are exploratory. CI, confidence interval; NCO, neurocognitive outcome.")
set_run_font(r, size=8.5)


# Main figures, each on a separate page.
figure_files = [
    ("Figure 1", FIGURES / "Figure1_discordance_mosaic.png", FIGURE_CAPTIONS[0][2], Inches(6.55)),
    ("Figure 2", FIGURES / "Figure2_modality_prevalence.png", FIGURE_CAPTIONS[1][2], Inches(6.55)),
    ("Figure 3", FIGURES / "Figure3_adjusted_associations.png", FIGURE_CAPTIONS[2][2], Inches(6.55)),
    ("Figure 4", FIGURES / "Figure4_temporal_by_sponsor.png", FIGURE_CAPTIONS[3][2], Inches(6.55)),
    ("Figure 5", FIGURES / "Figure5_endpoint_summary.png", FIGURE_CAPTIONS[4][2], Inches(6.55)),
]
for label, path, alt_text, width in figure_files:
    if not path.exists():
        raise FileNotFoundError(path)
    doc.add_page_break()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next = False
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(label)
    set_run_font(r, size=11, bold=True)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    shape = p.add_run().add_picture(str(path), width=width)
    set_alt_text(shape, alt_text)

# Supplementary figures, each on a separate page.
supplementary_figure_files = [
    ("Supplementary Figure S1", FIGURES / "FigureS1_instruments.png", SUPPLEMENT_CAPTIONS[0][2], Inches(6.35)),
    ("Supplementary Figure S2", FIGURES / "FigureS2_sensitivity_academic.png", SUPPLEMENT_CAPTIONS[1][2], Inches(6.35)),
]
for label, path, alt_text, width in supplementary_figure_files:
    if not path.exists():
        raise FileNotFoundError(path)
    doc.add_page_break()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next = False
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(label)
    set_run_font(r, size=11, bold=True)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    shape = p.add_run().add_picture(str(path), width=width)
    set_alt_text(shape, alt_text)


# Document core metadata
doc.core_properties.title = TITLE
doc.core_properties.author = AUTHOR
doc.core_properties.subject = "Cross-sectional registry analysis of neurocognitive endpoints in randomized glioma trials"
doc.core_properties.keywords = "glioblastoma, high-grade glioma, neurocognition, clinical trials, outcomes"
doc.core_properties.comments = "Revised manuscript prepared for author review; highlighted contact placeholders must be completed before submission."

doc.save(OUT)
print(f"Wrote {OUT}")
print(f"Abstract words: {abstract_words}")
print(f"Importance words: {importance_words}")
print(f"Main-text words: {body_words}")
