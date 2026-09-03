# =============================================================================
# GBM/HGG neurocognitive-endpoint registry analysis
# One script: cohort checks, models, diagnostics, tables, figures.
# No hard-coded estimates. Figures are drawn from fitted objects.
# =============================================================================

required_packages <- c(
  "logistf", "ggplot2", "dplyr", "tidyr", "patchwork", "pROC", "scales", "mgcv"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Install before running: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(logistf)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(patchwork)
  library(scales)
  library(mgcv)
  library(splines)
})

options(stringsAsFactors = FALSE, scipen = 999)
set.seed(20260827)

# ---- paths ------------------------------------------------------------------
file_args <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_args)) sub("^--file=", "", file_args[[1]]) else ""
script_path <- if (nzchar(script_path) && script_path != "-") {
  normalizePath(script_path)
} else {
  ""
}
project_candidates <- unique(c(
  if (nzchar(script_path)) dirname(script_path) else character(),
  normalizePath(getwd()),
  normalizePath(file.path(getwd(), "GBM_Global_Study"), mustWork = FALSE)
))
project_hits <- project_candidates[
  file.exists(file.path(project_candidates, "revised_outputs", "analysis_dataset.csv")) |
    file.exists(file.path(project_candidates, "GBM_RCT_GLOBAL_Matrix.xlsx"))
]
if (!length(project_hits)) {
  stop("Could not locate GBM_Global_Study from the script location or working directory.")
}
project_dir <- project_hits[[1]]
dataset_path <- file.path(project_dir, "revised_outputs", "analysis_dataset.csv")
matrix_path <- file.path(project_dir, "GBM_RCT_GLOBAL_Matrix.xlsx")
output_dir <- file.path(project_dir, "revised_outputs")
figure_dir <- file.path(output_dir, "figures")
table_dir <- file.path(output_dir, "tables")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

# ---- helpers ----------------------------------------------------------------
wilson_ci <- function(k, n, z = qnorm(0.975)) {
  p <- k / n
  den <- 1 + z^2 / n
  center <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(lower = max(0, center - half), upper = min(1, center + half))
}

format_p <- function(p) {
  ifelse(is.na(p), "", ifelse(p < 0.001, "<.001", sub("^0", "", sprintf("%.3f", p))))
}

format_pct <- function(k, n) {
  sprintf("%d (%.1f)", k, 100 * k / n)
}

e_value <- function(or) {
  if (is.na(or) || or <= 1) return(NA_real_)
  or + sqrt(or * (or - 1))
}

tidy_firth <- function(model) {
  data.frame(
    term = names(coef(model)),
    estimate = unname(coef(model)),
    OR = exp(unname(coef(model))),
    lower = exp(unname(model$ci.lower)),
    upper = exp(unname(model$ci.upper)),
    p = unname(model$prob),
    row.names = NULL
  )
}

overall_test <- function(model) {
  statistic <- 2 * unname(model$loglik["full"] - model$loglik["null"])
  data.frame(
    statistic = statistic,
    df = model$df,
    p = pchisq(statistic, df = model$df, lower.tail = FALSE)
  )
}

firth_lr_compare <- function(reduced, full, df_diff) {
  statistic <- 2 * unname(full$loglik["full"] - reduced$loglik["full"])
  data.frame(
    statistic = statistic,
    df = df_diff,
    p = pchisq(statistic, df = df_diff, lower.tail = FALSE)
  )
}

predict_logistf <- function(model, data) {
  X <- model.matrix(delete.response(terms(model)), data)
  beta <- coef(model)
  X <- X[, names(beta), drop = FALSE]
  as.numeric(plogis(drop(X %*% beta)))
}

cluster_robust_vcov <- function(model, cluster) {
  X <- model.matrix(model)
  mu <- fitted(model)
  w <- mu * (1 - mu)
  bread <- solve(crossprod(X, X * w))
  scores <- X * as.numeric(model$y - mu)
  cluster_scores <- rowsum(scores, cluster, reorder = FALSE)
  g <- nrow(cluster_scores)
  n <- nrow(X)
  p <- ncol(X)
  correction <- (g / (g - 1)) * ((n - 1) / (n - p))
  bread %*% crossprod(cluster_scores) %*% bread * correction
}

# Journal figures: classic axes, no in-plot titles, no clipped labels.
theme_journal <- function(base_size = 8) {
  theme_classic(base_size = base_size, base_family = "sans") %+replace%
    theme(
      axis.line = element_line(linewidth = 0.35, colour = "black"),
      axis.ticks = element_line(linewidth = 0.35, colour = "black"),
      axis.ticks.length = unit(2, "pt"),
      axis.title = element_text(size = base_size, colour = "black"),
      axis.text = element_text(size = base_size, colour = "black"),
      plot.tag = element_text(face = "bold", size = base_size + 2, hjust = 0, vjust = 1),
      plot.caption = element_text(size = base_size - 1, colour = "grey20", hjust = 0),
      legend.title = element_text(size = base_size),
      legend.text = element_text(size = base_size),
      legend.background = element_blank(),
      strip.background = element_blank(),
      strip.text = element_text(face = "bold", size = base_size, colour = "black"),
      plot.margin = margin(6, 10, 6, 6)
    )
}

save_figure <- function(plot, stem, width, height) {
  ggsave(
    file.path(figure_dir, paste0(stem, ".pdf")), plot = plot,
    width = width, height = height, units = "in", bg = "white"
  )
  ggsave(
    file.path(figure_dir, paste0(stem, ".png")), plot = plot,
    width = width, height = height, units = "in", dpi = 600, bg = "white"
  )
  ggsave(
    file.path(figure_dir, paste0(stem, ".tiff")), plot = plot,
    width = width, height = height, units = "in", dpi = 600,
    compression = "lzw", bg = "white"
  )
}

# ---- data -------------------------------------------------------------------
load_dataset <- function() {
  if (file.exists(matrix_path) && requireNamespace("readxl", quietly = TRUE)) {
    raw <- as.data.frame(readxl::read_excel(matrix_path, sheet = "Global_Matrix_N289"))
    return(raw |>
      filter(In_Primary_Set == "Yes") |>
      mutate(
        NCO = as.integer(NCO_Registered == "Yes"),
        HRQoL = case_when(
          HRQoL_Registered == "Yes" ~ 1L,
          HRQoL_Registered == "No" ~ 0L,
          TRUE ~ NA_integer_
        ),
        Year = as.numeric(Registration_Year),
        Phase_f = factor(Phase, levels = c("PHASE2", "PHASE2/PHASE3", "PHASE3")),
        Sponsor_f = factor(
          Sponsor_Class,
          levels = c("Industry", "Academic/Investigator-Initiated", "Government/Cooperative Group")
        ),
        Registry_f = factor(Registry_Source, levels = c("US", "International")),
        Year_c = Year - mean(Year, na.rm = TRUE),
        Radiation = as.integer(grepl("Radiation", Modality, fixed = TRUE)),
        Strict_GBM = as.integer(Strict_GBM_Only == "Yes"),
        Enrollment = suppressWarnings(as.numeric(Enrollment_N)),
        Enrollment = ifelse(Enrollment > 0, Enrollment, NA_real_),
        Pediatric_title = grepl(
          "pediatric|paediatric|children|child|adolescent",
          Brief_Title, ignore.case = TRUE
        ),
        NCO_strict = as.integer(
          NCO == 1 & trimws(tolower(NCO_Instruments)) != "domain named, tool unspecified"
        ),
        Completed = as.integer(Status == "COMPLETED"),
        Modality = Modality
      ))
  }

  if (!file.exists(dataset_path)) stop("Missing analysis dataset: ", dataset_path)
  raw <- read.csv(dataset_path, stringsAsFactors = FALSE)
  raw |>
    mutate(
      NCO = as.integer(NCO),
      HRQoL = ifelse(is.na(HRQoL), NA_integer_, as.integer(HRQoL)),
      Year = as.numeric(Year),
      Phase_f = factor(Phase, levels = c("PHASE2", "PHASE2/PHASE3", "PHASE3")),
      Sponsor_f = factor(
        Sponsor_Class,
        levels = c("Industry", "Academic/Investigator-Initiated", "Government/Cooperative Group")
      ),
      Registry_f = factor(Registry_Source, levels = c("US", "International")),
      Year_c = Year - mean(Year, na.rm = TRUE),
      Radiation = as.integer(Radiation),
      Strict_GBM = as.integer(Strict_GBM_Only == "Yes"),
      Enrollment = suppressWarnings(as.numeric(Enrollment)),
      Enrollment = ifelse(Enrollment > 0, Enrollment, NA_real_),
      Pediatric_title = as.logical(Pediatric_title),
      NCO_strict = as.integer(NCO_strict),
      Completed = as.integer(Status == "COMPLETED"),
      Modality = Modality
    )
}

d <- load_dataset()

modality_catalog <- c(
  "Radiation" = "Radiation",
  "Cytotoxic Chemotherapy" = "Cytotoxic chemotherapy",
  "Immunotherapy" = "Immunotherapy",
  "Targeted / Small Molecule" = "Targeted therapy",
  "Surgical" = "Surgery",
  "Tumor Treating Fields" = "Tumor-treating fields"
)
for (key in names(modality_catalog)) {
  d[[make.names(key)]] <- as.integer(grepl(key, d$Modality, fixed = TRUE))
}

stopifnot(
  nrow(d) == 289,
  sum(d$NCO) == 39,
  sum(d$NCO_strict) == 35,
  sum(d$HRQoL == 1, na.rm = TRUE) == 105,
  sum(is.na(d$HRQoL)) == 7
)

hrqol_data <- d |> filter(!is.na(HRQoL))
us <- d |> filter(Registry_Source == "US")

# ---- Table 1: one overall test per characteristic ---------------------------
nco_no <- d |> filter(NCO == 0)
nco_yes <- d |> filter(NCO == 1)

p_phase <- fisher.test(table(d$Phase_f, d$NCO))$p.value
p_sponsor <- fisher.test(table(d$Sponsor_f, d$NCO))$p.value
p_registry <- fisher.test(table(d$Registry_f, d$NCO))$p.value
p_gbm <- fisher.test(table(d$Strict_GBM, d$NCO))$p.value
p_radiation <- fisher.test(table(d$Radiation, d$NCO))$p.value
p_completed <- fisher.test(table(d$Completed, d$NCO))$p.value
p_pediatric <- fisher.test(table(d$Pediatric_title, d$NCO))$p.value
p_enroll <- wilcox.test(Enrollment ~ NCO, data = d, exact = FALSE)$p.value

fmt_enroll <- function(data) {
  x <- data$Enrollment[!is.na(data$Enrollment)]
  sprintf("%.0f [%.0f-%.0f]; n=%d", median(x), quantile(x, 0.25), quantile(x, 0.75), length(x))
}

add_rows <- function(label, variable, levels, p_value) {
  bind_rows(lapply(seq_along(levels), function(i) {
    lev <- levels[i]
    data.frame(
      Characteristic = if (i == 1) paste0(label, ": ", lev) else paste0("    ", lev),
      Overall = format_pct(sum(d[[variable]] == lev), nrow(d)),
      `NCO absent` = format_pct(sum(nco_no[[variable]] == lev), nrow(nco_no)),
      `NCO registered` = format_pct(sum(nco_yes[[variable]] == lev), nrow(nco_yes)),
      `P value` = if (i == 1) format_p(p_value) else "",
      check.names = FALSE
    )
  }))
}

table1 <- bind_rows(
  add_rows("Phase", "Phase_f", c("PHASE2", "PHASE2/PHASE3", "PHASE3"), p_phase),
  add_rows(
    "Sponsor", "Sponsor_f",
    c("Industry", "Academic/Investigator-Initiated", "Government/Cooperative Group"),
    p_sponsor
  ),
  add_rows("Registry", "Registry_f", c("US", "International"), p_registry),
  data.frame(
    Characteristic = "Strict glioblastoma population",
    Overall = format_pct(sum(d$Strict_GBM == 1), nrow(d)),
    `NCO absent` = format_pct(sum(nco_no$Strict_GBM == 1), nrow(nco_no)),
    `NCO registered` = format_pct(sum(nco_yes$Strict_GBM == 1), nrow(nco_yes)),
    `P value` = format_p(p_gbm),
    check.names = FALSE
  ),
  data.frame(
    Characteristic = "Radiation-containing intervention",
    Overall = format_pct(sum(d$Radiation == 1), nrow(d)),
    `NCO absent` = format_pct(sum(nco_no$Radiation == 1), nrow(nco_no)),
    `NCO registered` = format_pct(sum(nco_yes$Radiation == 1), nrow(nco_yes)),
    `P value` = format_p(p_radiation),
    check.names = FALSE
  ),
  data.frame(
    Characteristic = "Completed trial",
    Overall = format_pct(sum(d$Completed == 1), nrow(d)),
    `NCO absent` = format_pct(sum(nco_no$Completed == 1), nrow(nco_no)),
    `NCO registered` = format_pct(sum(nco_yes$Completed == 1), nrow(nco_yes)),
    `P value` = format_p(p_completed),
    check.names = FALSE
  ),
  data.frame(
    Characteristic = "Pediatric wording in title",
    Overall = format_pct(sum(d$Pediatric_title), nrow(d)),
    `NCO absent` = format_pct(sum(nco_no$Pediatric_title), nrow(nco_no)),
    `NCO registered` = format_pct(sum(nco_yes$Pediatric_title), nrow(nco_yes)),
    `P value` = format_p(p_pediatric),
    check.names = FALSE
  ),
  data.frame(
    Characteristic = "Planned enrollment, median [IQR]",
    Overall = fmt_enroll(d),
    `NCO absent` = fmt_enroll(nco_no),
    `NCO registered` = fmt_enroll(nco_yes),
    `P value` = format_p(p_enroll),
    check.names = FALSE
  )
)
# Readable phase/sponsor labels
table1$Characteristic <- gsub("PHASE2/PHASE3", "II/III", table1$Characteristic)
table1$Characteristic <- gsub("PHASE2", "II", table1$Characteristic)
table1$Characteristic <- gsub("PHASE3", "III", table1$Characteristic)
table1$Characteristic <- gsub("Academic/Investigator-Initiated", "Academic/investigator", table1$Characteristic)
table1$Characteristic <- gsub("Government/Cooperative Group", "Government/cooperative", table1$Characteristic)
table1$Characteristic <- gsub("Registry: US", "Registry: ClinicalTrials.gov", table1$Characteristic)
write.csv(table1, file.path(table_dir, "table1_characteristics.csv"), row.names = FALSE)

# ---- Primary models ---------------------------------------------------------
main_formula <- NCO ~ Phase_f + Sponsor_f + Year_c + Radiation + Registry_f
nco_model <- logistf(main_formula, data = d)
nco_terms <- tidy_firth(nco_model)
nco_overall <- overall_test(nco_model)

hrqol_model <- logistf(
  HRQoL ~ Phase_f + Sponsor_f + Year_c + Radiation + Registry_f,
  data = hrqol_data
)
hrqol_terms <- tidy_firth(hrqol_model)
hrqol_overall <- overall_test(hrqol_model)

write.csv(nco_terms, file.path(table_dir, "model_nco_firth.csv"), row.names = FALSE)
write.csv(hrqol_terms, file.path(table_dir, "model_hrqol_firth.csv"), row.names = FALSE)

term_labels <- c(
  "Phase_fPHASE2/PHASE3" = "Phase II/III vs II",
  "Phase_fPHASE3" = "Phase III vs II",
  "Sponsor_fAcademic/Investigator-Initiated" = "Academic/investigator vs industry",
  "Sponsor_fGovernment/Cooperative Group" = "Government/cooperative vs industry",
  "Year_c" = "Registration year, per year",
  "Radiation" = "Radiation-containing intervention",
  "Registry_fInternational" = "International-only vs ClinicalTrials.gov"
)

model_for_table <- function(x, outcome_label) {
  x |>
    filter(term != "(Intercept)") |>
    transmute(
      Predictor = unname(term_labels[term]),
      Outcome = outcome_label,
      `Odds ratio` = sprintf("%.2f", OR),
      `95% CI` = sprintf("%.2f-%.2f", lower, upper),
      P = format_p(p)
    )
}
table2 <- bind_rows(
  model_for_table(nco_terms, "Objective NCO (N=289; 39 events)"),
  model_for_table(hrqol_terms, "HRQoL, complete case (N=282; 105 events)")
)
write.csv(table2, file.path(table_dir, "table2_adjusted_models.csv"), row.names = FALSE)

# Nested penalized LR: does sponsorship add information beyond the other covariates?
reduced_nco <- logistf(NCO ~ Phase_f + Year_c + Radiation + Registry_f, data = d)
nested_sponsor <- firth_lr_compare(reduced_nco, nco_model, df_diff = 2)
write.csv(
  nested_sponsor |> mutate(comparison = "Sponsor added to phase+year+radiation+registry"),
  file.path(table_dir, "nested_likelihood_ratio.csv"),
  row.names = FALSE
)

# Apparent discrimination / calibration
nco_pred <- nco_model$predict
nco_auc <- as.numeric(pROC::auc(d$NCO, nco_pred))
nco_brier <- mean((d$NCO - nco_pred)^2)

# Optimism-corrected AUC (Harrell bootstrap; Firth without profile CI for speed)
B <- 400
optimism <- vapply(seq_len(B), function(i) {
  idx <- sample.int(nrow(d), replace = TRUE)
  boot_fit <- try(
    logistf(main_formula, data = d[idx, ], pl = FALSE, dataout = FALSE),
    silent = TRUE
  )
  if (inherits(boot_fit, "try-error")) return(NA_real_)
  p_boot <- predict_logistf(boot_fit, d[idx, ])
  p_orig <- predict_logistf(boot_fit, d)
  if (length(unique(d$NCO[idx])) < 2) return(NA_real_)
  auc_boot <- as.numeric(pROC::auc(d$NCO[idx], p_boot, quiet = TRUE))
  auc_orig <- as.numeric(pROC::auc(d$NCO, p_orig, quiet = TRUE))
  auc_boot - auc_orig
}, numeric(1))
optimism <- optimism[is.finite(optimism)]
auc_corrected <- nco_auc - mean(optimism)
write.csv(
  data.frame(
    apparent_auc = nco_auc,
    mean_optimism = mean(optimism),
    optimism_corrected_auc = auc_corrected,
    brier = nco_brier,
    bootstrap_replicates = length(optimism)
  ),
  file.path(table_dir, "bootstrap_performance.csv"),
  row.names = FALSE
)

# Marginally standardized sponsor probabilities
marginal_probability <- function(model, data, sponsor_level) {
  nd <- data
  nd$Sponsor_f <- factor(sponsor_level, levels = levels(data$Sponsor_f))
  X <- model.matrix(delete.response(terms(model)), nd)
  X <- X[, names(coef(model)), drop = FALSE]
  eta <- drop(X %*% coef(model))
  pr <- plogis(eta)
  gradient <- colMeans(X * as.numeric(pr * (1 - pr)))
  se <- sqrt(drop(t(gradient) %*% model$var %*% gradient))
  data.frame(
    Sponsor = sponsor_level,
    probability = mean(pr),
    lower = max(0, mean(pr) - 1.96 * se),
    upper = min(1, mean(pr) + 1.96 * se)
  )
}
adjusted_probabilities <- bind_rows(lapply(levels(d$Sponsor_f), function(x) {
  marginal_probability(nco_model, d, x)
}))
write.csv(
  adjusted_probabilities,
  file.path(table_dir, "adjusted_sponsor_probabilities.csv"),
  row.names = FALSE
)

# ---- Sensitivity -----------------------------------------------------------
extract_key_terms <- function(model, label, n, events) {
  tidy_firth(model) |>
    filter(grepl("Sponsor_f|Year_c|Radiation", term)) |>
    mutate(analysis = label, N = n, events = events, .before = 1)
}
fit_sensitivity <- function(data, outcome, label,
                            include_registry = TRUE, include_enrollment = FALSE) {
  rhs <- c("Phase_f", "Sponsor_f", "Year_c", "Radiation")
  if (include_registry && length(unique(data$Registry_f)) > 1) {
    rhs <- c(rhs, "Registry_f")
  }
  if (include_enrollment) rhs <- c(rhs, "log2_enrollment")
  f <- as.formula(paste(outcome, "~", paste(rhs, collapse = " + ")))
  extract_key_terms(logistf(f, data = data), label, nrow(data), sum(data[[outcome]], na.rm = TRUE))
}
enrollment_data <- d |> filter(!is.na(Enrollment)) |> mutate(log2_enrollment = log2(Enrollment))
sensitivity_results <- bind_rows(
  fit_sensitivity(d, "NCO", "Primary definition"),
  fit_sensitivity(d, "NCO_strict", "Instrument-confirmed NCO"),
  fit_sensitivity(filter(d, Strict_GBM == 1), "NCO", "Strict glioblastoma"),
  fit_sensitivity(filter(d, !Pediatric_title), "NCO", "Excluding pediatric-title trials"),
  fit_sensitivity(filter(d, Registry_Source == "US"), "NCO", "ClinicalTrials.gov only",
                  include_registry = FALSE),
  fit_sensitivity(enrollment_data, "NCO", "Adjusted for log2 enrollment",
                  include_enrollment = TRUE)
)
write.csv(sensitivity_results, file.path(table_dir, "sensitivity_models.csv"), row.names = FALSE)

# ---- Paired domain interaction ---------------------------------------------
long_data <- bind_rows(
  hrqol_data |> mutate(Outcome = factor("HRQoL", levels = c("HRQoL", "NCO")), Registered = HRQoL),
  hrqol_data |> mutate(Outcome = factor("NCO", levels = c("HRQoL", "NCO")), Registered = NCO)
)
interaction_model <- glm(
  Registered ~ Outcome * Sponsor_f + Phase_f + Year_c + Radiation + Registry_f,
  family = binomial(), data = long_data
)
interaction_vcov <- cluster_robust_vcov(interaction_model, long_data$NCT)
interaction_coef <- coef(interaction_model)
interaction_se <- sqrt(diag(interaction_vcov))
interaction_table <- data.frame(
  term = names(interaction_coef),
  OR = exp(interaction_coef),
  lower = exp(interaction_coef - 1.96 * interaction_se),
  upper = exp(interaction_coef + 1.96 * interaction_se),
  p = 2 * pnorm(abs(interaction_coef / interaction_se), lower.tail = FALSE),
  row.names = NULL
)
interaction_idx <- grep("OutcomeNCO:Sponsor_f", names(interaction_coef), fixed = TRUE)
interaction_beta <- interaction_coef[interaction_idx]
interaction_cov <- interaction_vcov[interaction_idx, interaction_idx, drop = FALSE]
interaction_wald <- drop(t(interaction_beta) %*% solve(interaction_cov, interaction_beta))
interaction_joint <- data.frame(
  statistic = interaction_wald,
  df = length(interaction_idx),
  p = pchisq(interaction_wald, df = length(interaction_idx), lower.tail = FALSE)
)
write.csv(interaction_table, file.path(table_dir, "domain_by_sponsor_interaction.csv"), row.names = FALSE)
write.csv(interaction_joint, file.path(table_dir, "domain_by_sponsor_joint_test.csv"), row.names = FALSE)

# ---- Discordance ------------------------------------------------------------
nco_ci <- wilson_ci(sum(d$NCO), nrow(d))
hrqol_ci <- wilson_ci(sum(hrqol_data$HRQoL), nrow(hrqol_data))
mcnemar_matrix <- table(
  factor(hrqol_data$NCO, levels = 0:1),
  factor(hrqol_data$HRQoL, levels = 0:1)
)
mcnemar_result <- mcnemar.test(mcnemar_matrix, correct = FALSE)

# Bootstrap CI for the HRQoL minus NCO prevalence difference
diff_boot <- replicate(2000, {
  idx <- sample.int(nrow(hrqol_data), replace = TRUE)
  mean(hrqol_data$HRQoL[idx]) - mean(hrqol_data$NCO[idx])
})
prevalence_diff <- data.frame(
  estimate = mean(hrqol_data$HRQoL) - mean(hrqol_data$NCO),
  lower = quantile(diff_boot, 0.025),
  upper = quantile(diff_boot, 0.975)
)
write.csv(prevalence_diff, file.path(table_dir, "prevalence_difference_bootstrap.csv"), row.names = FALSE)

discordance_counts <- hrqol_data |>
  mutate(
    cell = case_when(
      NCO == 0 & HRQoL == 0 ~ "Neither registered",
      NCO == 0 & HRQoL == 1 ~ "HRQoL only",
      NCO == 1 & HRQoL == 0 ~ "NCO only",
      TRUE ~ "Both registered"
    )
  ) |>
  count(cell, name = "n") |>
  mutate(
    cell = factor(cell, levels = c("Neither registered", "HRQoL only", "NCO only", "Both registered")),
    percent = 100 * n / sum(n)
  ) |>
  arrange(cell)
table3 <- discordance_counts |>
  transmute(
    `Registration pattern` = as.character(cell),
    `Trials, n (%)` = sprintf("%d (%.1f)", n, percent),
    `Among complete cases (N=282)` = sprintf("%d/%d", n, sum(n))
  )
write.csv(
  cbind(table3, data.frame(`McNemar P` = c(format_p(mcnemar_result$p.value), rep("", 3)))),
  file.path(table_dir, "table3_discordance.csv"),
  row.names = FALSE
)

# ---- Modality --------------------------------------------------------------
modality_long <- bind_rows(lapply(names(modality_catalog), function(key) {
  col <- make.names(key)
  subset <- d |> filter(.data[[col]] == 1)
  k <- sum(subset$NCO)
  n <- nrow(subset)
  ci <- wilson_ci(k, n)
  data.frame(
    Modality = modality_catalog[[key]],
    Trials = n,
    `NCO registered` = k,
    percent = 100 * k / n,
    lower = 100 * ci[["lower"]],
    upper = 100 * ci[["upper"]],
    `Percent (95% CI)` = sprintf("%.1f (%.1f-%.1f)", 100 * k / n, 100 * ci["lower"], 100 * ci["upper"]),
    check.names = FALSE
  )
})) |>
  arrange(percent)
write.csv(
  modality_long |> select(Modality, Trials, `NCO registered`, `Percent (95% CI)`),
  file.path(table_dir, "table4_modality_prevalence.csv"),
  row.names = FALSE
)

# ---- Temporal: post-2010 slope + GAM on US trials --------------------------
us_post2010 <- us |> filter(Year >= 2010) |> mutate(Year_post2010 = Year - 2010)
post2010_term <- tidy_firth(logistf(NCO ~ Year_post2010, data = us_post2010)) |>
  filter(term == "Year_post2010")
write.csv(post2010_term, file.path(table_dir, "post2010_temporal_slope.csv"), row.names = FALSE)

gam_year <- gam(NCO ~ s(Year, k = 6), family = binomial(), data = us, method = "REML")
year_grid <- data.frame(Year = seq(min(us$Year), max(us$Year), by = 0.25))
gam_pred <- predict(gam_year, year_grid, type = "link", se.fit = TRUE)
year_grid$fit <- plogis(gam_pred$fit)
year_grid$lower <- plogis(gam_pred$fit - 1.96 * gam_pred$se.fit)
year_grid$upper <- plogis(gam_pred$fit + 1.96 * gam_pred$se.fit)
annual <- us |>
  group_by(Year) |>
  summarise(k = sum(NCO), n = n(), percent = 100 * k / n, .groups = "drop")

# Industry vs non-industry 5-year rolling, windows with n>=12 only
us <- us |> mutate(Industry = if_else(Sponsor_f == "Industry", "Industry", "Non-industry"))
years <- seq(min(us$Year), max(us$Year))
rolling <- bind_rows(lapply(c("Industry", "Non-industry"), function(grp) {
  bind_rows(lapply(years, function(y) {
    window <- us |> filter(Industry == grp, Year >= y - 2, Year <= y + 2)
    n <- nrow(window)
    if (n < 12) {
      return(data.frame(Year = y, Group = grp, n = n, percent = NA_real_,
                        lower = NA_real_, upper = NA_real_))
    }
    k <- sum(window$NCO)
    ci <- wilson_ci(k, n)
    data.frame(
      Year = y, Group = grp, n = n, percent = 100 * k / n,
      lower = 100 * ci[["lower"]], upper = 100 * ci[["upper"]]
    )
  }))
}))

# ---- Instruments / ICCTF core ----------------------------------------------
nco_pos <- d |> filter(NCO == 1)
instrument_flags <- nco_pos |>
  transmute(
    NCT,
    MMSE = grepl("mmse|mini-mental|mini mental", NCO_Instruments, ignore.case = TRUE),
    MoCA = grepl("moca|montreal cognitive", NCO_Instruments, ignore.case = TRUE),
    `HVLT-R` = grepl("hvlt|hopkins verbal", NCO_Instruments, ignore.case = TRUE),
    `Trail Making Test` = grepl("trail making|trail-making|tmt", NCO_Instruments, ignore.case = TRUE),
    COWAT = grepl("controlled oral word|cowat|verbal fluency", NCO_Instruments, ignore.case = TRUE),
    `Wechsler/WISC` = grepl("wechsler|wisc", NCO_Instruments, ignore.case = TRUE),
    `Symbol/digit tests` = grepl("symbol digit|digit symbol|digit span", NCO_Instruments, ignore.case = TRUE),
    Stroop = grepl("stroop", NCO_Instruments, ignore.case = TRUE),
    `Finger tapping` = grepl("finger tapping", NCO_Instruments, ignore.case = TRUE),
    `Named domain only` = trimws(tolower(NCO_Instruments)) == "domain named, tool unspecified"
  )
icctf <- instrument_flags |>
  mutate(
    icctf_any = `HVLT-R` | `Trail Making Test` | COWAT,
    icctf_core = `HVLT-R` & `Trail Making Test` & COWAT,
    mmse_or_moca_only = (MMSE | MoCA) & !icctf_any & !`Named domain only`
  )
icctf_summary <- data.frame(
  metric = c(
    "NCO-positive trials",
    "Any ICCTF core test (HVLT-R, TMT, or COWAT)",
    "Full ICCTF core battery (all three)",
    "MMSE or MoCA without an ICCTF core test",
    "Named domain only"
  ),
  n = c(
    nrow(icctf),
    sum(icctf$icctf_any),
    sum(icctf$icctf_core),
    sum(icctf$mmse_or_moca_only),
    sum(icctf$`Named domain only`)
  )
)
write.csv(icctf_summary, file.path(table_dir, "table_icctf_battery.csv"), row.names = FALSE)

instrument_counts <- instrument_flags |>
  pivot_longer(-NCT, names_to = "Instrument", values_to = "present") |>
  filter(present) |>
  count(Instrument, sort = TRUE) |>
  mutate(
    icctf = Instrument %in% c("HVLT-R", "Trail Making Test", "COWAT"),
    Instrument = factor(Instrument, levels = rev(Instrument))
  )

# E-values
evalue_table <- nco_terms |>
  filter(term %in% c(
    "Sponsor_fAcademic/Investigator-Initiated",
    "Sponsor_fGovernment/Cooperative Group",
    "Year_c",
    "Radiation"
  )) |>
  mutate(
    Predictor = unname(term_labels[term]),
    `E-value (point)` = sprintf("%.2f", vapply(OR, e_value, numeric(1))),
    `E-value (CI bound)` = sprintf("%.2f", vapply(lower, e_value, numeric(1)))
  ) |>
  select(Predictor, `Odds ratio` = OR, `95% CI lower` = lower, `E-value (point)`, `E-value (CI bound)`)
write.csv(evalue_table, file.path(table_dir, "table5_evalues.csv"), row.names = FALSE)

source(file.path(project_dir, "gbm_figures.R"))

# ---- numerical record ------------------------------------------------------
sink(file.path(output_dir, "analysis_summary.txt"))
cat("GBM/HGG neurocognitive-endpoint registry analysis\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n\n")
cat("Analytic cohort:", nrow(d), "trials\n")
cat("Objective NCO:", sum(d$NCO), "/", nrow(d), sprintf("(%.1f%%)\n", 100 * mean(d$NCO)))
cat("HRQoL complete case:", sum(hrqol_data$HRQoL), "/", nrow(hrqol_data),
    sprintf("(%.1f%%)\n", 100 * mean(hrqol_data$HRQoL)))
cat("McNemar P:", format.pval(mcnemar_result$p.value), "\n")
cat("Prevalence difference (HRQoL-NCO):", round(100 * prevalence_diff$estimate, 1),
    "pp; bootstrap 95% CI", round(100 * prevalence_diff$lower, 1), "to",
    round(100 * prevalence_diff$upper, 1), "\n")
cat("Sponsor x domain interaction Wald P:", interaction_joint$p, "\n")
cat("Nested LR adding sponsor: chi2=", nested_sponsor$statistic,
    " df=2 p=", nested_sponsor$p, "\n", sep = "")
cat("Apparent AUC:", nco_auc, " optimism-corrected AUC:", auc_corrected,
    " Brier:", nco_brier, "\n")
cat("ICCTF any/core/MMSE-only:", sum(icctf$icctf_any), "/", sum(icctf$icctf_core),
    "/", sum(icctf$mmse_or_moca_only), " of ", nrow(icctf), "\n", sep = "")
cat("\nPrimary NCO Firth model\n")
print(nco_terms, row.names = FALSE)
cat("Overall LR:", nco_overall$statistic, "df", nco_overall$df, "p", nco_overall$p, "\n")
cat("\nTable 1 overall tests\n")
print(data.frame(
  variable = c("Phase", "Sponsor", "Registry", "Strict GBM", "Radiation",
               "Completed", "Pediatric", "Enrollment"),
  p = c(p_phase, p_sponsor, p_registry, p_gbm, p_radiation,
        p_completed, p_pediatric, p_enroll)
), row.names = FALSE)
cat("\nSession information\n")
print(sessionInfo())
sink()

cat("Analysis complete. Outputs written to:\n", normalizePath(output_dir), "\n", sep = "")
