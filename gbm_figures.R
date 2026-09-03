# Publication figures. Sourced from gbm_analysis_revised.R after all objects exist.
# No in-plot titles or captions; those belong in the manuscript.

col_navy <- "#1B4F72"
col_accent <- "#C0392B"

# ---- Figure 1: paired composition + McNemar discordant pairs ----------------
n_h0 <- sum(hrqol_data$HRQoL == 0)
n_h1 <- sum(hrqol_data$HRQoL == 1)
stack <- data.frame(
  hrqol = factor(
    c(
      rep(sprintf("HRQoL not registered\n(n = %d)", n_h0), 2),
      rep(sprintf("HRQoL registered\n(n = %d)", n_h1), 2)
    ),
    levels = c(
      sprintf("HRQoL not registered\n(n = %d)", n_h0),
      sprintf("HRQoL registered\n(n = %d)", n_h1)
    )
  ),
  nco = factor(
    c("NCO not registered", "NCO registered", "NCO not registered", "NCO registered"),
    levels = c("NCO not registered", "NCO registered")
  ),
  n = c(
    sum(hrqol_data$NCO == 0 & hrqol_data$HRQoL == 0),
    sum(hrqol_data$NCO == 1 & hrqol_data$HRQoL == 0),
    sum(hrqol_data$NCO == 0 & hrqol_data$HRQoL == 1),
    sum(hrqol_data$NCO == 1 & hrqol_data$HRQoL == 1)
  )
)
stack <- stack |>
  group_by(hrqol) |>
  mutate(pct = 100 * n / sum(n), ymid = cumsum(pct) - pct / 2) |>
  ungroup()

p1a <- ggplot(stack, aes(hrqol, n, fill = nco)) +
  geom_col(width = 0.62, colour = "white", linewidth = 0.4,
           position = position_stack(reverse = TRUE)) +
  geom_text(
    data = stack |> filter(n >= 10),
    aes(label = n),
    position = position_stack(vjust = 0.5, reverse = TRUE),
    colour = "white", size = 3, fontface = "bold", show.legend = FALSE
  ) +
  scale_fill_manual(
    values = c("NCO not registered" = "#7F8C8D", "NCO registered" = col_navy),
    name = NULL
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.04)), breaks = seq(0, 180, 40)) +
  labs(x = NULL, y = "Trials (n)") +
  theme_journal(8) +
  theme(legend.position = "bottom", legend.margin = margin(t = 1))

discord <- data.frame(
  pair = factor(
    c("HRQoL without NCO", "NCO without HRQoL"),
    levels = c("HRQoL without NCO", "NCO without HRQoL")
  ),
  n = c(
    sum(hrqol_data$NCO == 0 & hrqol_data$HRQoL == 1),
    sum(hrqol_data$NCO == 1 & hrqol_data$HRQoL == 0)
  )
)
p1b <- ggplot(discord, aes(n, pair, fill = pair)) +
  geom_col(width = 0.55, colour = NA) +
  geom_text(aes(label = n, x = n + 3), hjust = 0, size = 3, fontface = "bold") +
  scale_fill_manual(values = c("HRQoL without NCO" = "#85C1E9", "NCO without HRQoL" = col_accent), guide = "none") +
  scale_x_continuous(limits = c(0, 90), expand = expansion(mult = c(0, 0.02)), breaks = c(0, 25, 50, 75)) +
  labs(x = "Discordant trials (n)", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

fig1 <- p1a + p1b +
  plot_layout(widths = c(1.15, 1)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 10))

# ---- Figure 2: modality forest, ordered by sample size ----------------------
mod_plot <- modality_long |>
  arrange(Trials) |>
  mutate(
    y_num = seq_len(n()),
    lab = sprintf("%d/%d", `NCO registered`, Trials),
    ci_lab = sprintf("%.1f (%.1f-%.1f)", percent, lower, upper)
  )
overall_pct <- 100 * mean(d$NCO)

p2_forest <- ggplot(mod_plot, aes(percent, y_num)) +
  geom_vline(xintercept = overall_pct, linetype = "22", linewidth = 0.35, colour = "grey45") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.18, linewidth = 0.45, colour = col_navy) +
  geom_point(size = 2.2, shape = 15, colour = col_navy) +
  scale_x_continuous(limits = c(0, 60), breaks = seq(0, 60, 10), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(breaks = mod_plot$y_num, labels = mod_plot$Modality, expand = expansion(add = 0.6)) +
  labs(x = "Trials registering an objective NCO (%)", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

p2_n <- ggplot(mod_plot, aes(x = 0, y = y_num)) +
  geom_text(aes(label = lab), hjust = 0, size = 2.7) +
  scale_y_continuous(breaks = mod_plot$y_num, expand = expansion(add = 0.6)) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  labs(x = "n/N", y = NULL) +
  theme_void() +
  theme(axis.title.x = element_text(size = 8, colour = "black", margin = margin(t = 4)))

p2_ci <- ggplot(mod_plot, aes(x = 0, y = y_num)) +
  geom_text(aes(label = ci_lab), hjust = 0, size = 2.7) +
  scale_y_continuous(breaks = mod_plot$y_num, expand = expansion(add = 0.6)) +
  scale_x_continuous(limits = c(0, 1.6), expand = c(0, 0)) +
  labs(x = "% (95% CI)", y = NULL) +
  theme_void() +
  theme(axis.title.x = element_text(size = 8, colour = "black", margin = margin(t = 4)))

fig2 <- p2_forest + p2_n + p2_ci + plot_layout(widths = c(3.2, 0.7, 1.35))

# ---- Figure 3: forest with OR column; International omitted from the scale --
forest <- nco_terms |>
  filter(term != "(Intercept)", term != "Registry_fInternational") |>
  mutate(
    label = unname(term_labels[term]),
    or_lab = sprintf("%.2f (%.2f-%.2f)   %s", OR, lower, upper, format_p(p)),
    y_num = n():1
  )

p3a <- ggplot(forest, aes(OR, y_num)) +
  geom_vline(xintercept = 1, linetype = "22", linewidth = 0.35, colour = "grey40") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.22, linewidth = 0.45, colour = col_navy) +
  geom_point(size = 2.1, shape = 15, colour = col_navy) +
  geom_text(aes(x = 14.5, label = or_lab), hjust = 0, size = 2.55) +
  scale_x_log10(breaks = c(0.2, 0.5, 1, 2, 4, 8), labels = c("0.2", "0.5", "1", "2", "4", "8")) +
  scale_y_continuous(breaks = forest$y_num, labels = forest$label, expand = expansion(add = 0.65)) +
  coord_cartesian(xlim = c(0.16, 12), clip = "off") +
  labs(x = "Adjusted odds ratio (log scale)", y = NULL) +
  theme_journal(8) +
  theme(
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    plot.margin = margin(6, 118, 8, 6)
  )

adj_plot <- adjusted_probabilities |>
  mutate(
    label = recode(
      Sponsor,
      "Industry" = "Industry",
      "Academic/Investigator-Initiated" = "Academic/investigator",
      "Government/Cooperative Group" = "Government/cooperative"
    ),
    y_num = 3:1,
    pct_lab = sprintf("%.1f%%", 100 * probability)
  )

p3b <- ggplot(adj_plot, aes(probability * 100, y_num)) +
  geom_errorbarh(aes(xmin = lower * 100, xmax = upper * 100),
                 height = 0.18, linewidth = 0.45, colour = col_navy) +
  geom_point(size = 2.2, shape = 15, colour = col_navy) +
  geom_text(aes(x = pmin(upper * 100 + 1.4, 36), label = pct_lab), hjust = 0, size = 2.6) +
  scale_x_continuous(limits = c(0, 42), breaks = seq(0, 40, 10), expand = c(0, 0)) +
  scale_y_continuous(breaks = adj_plot$y_num, labels = adj_plot$label, expand = expansion(add = 0.55)) +
  labs(x = "Adjusted NCO probability (%)", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

fig3 <- p3a / p3b +
  plot_layout(heights = c(1.55, 0.85)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 10))

# ---- Figure 4: volume, GAM (points only if n>=5), industry rolling line -----
p4a <- ggplot(annual, aes(Year, n)) +
  geom_col(fill = "grey80", colour = NA, width = 0.85) +
  scale_y_continuous(name = "Trials registered", expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL) +
  theme_journal(8) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    plot.margin = margin(6, 18, 0, 6)
  )

annual_plot <- annual |> filter(n >= 5)
p4b <- ggplot() +
  geom_ribbon(
    data = year_grid,
    aes(Year, ymin = 100 * lower, ymax = 100 * upper),
    fill = col_navy, alpha = 0.12
  ) +
  geom_line(data = year_grid, aes(Year, 100 * fit), colour = col_navy, linewidth = 0.7) +
  geom_point(
    data = annual_plot, aes(Year, percent, size = n),
    shape = 21, fill = "white", colour = col_navy, stroke = 0.45
  ) +
  geom_vline(xintercept = 2010, linetype = "22", linewidth = 0.35, colour = "grey40") +
  scale_size_area(max_size = 5.5, breaks = c(5, 15, 30), name = "Trials/year") +
  coord_cartesian(ylim = c(0, 42), expand = FALSE) +
  scale_y_continuous(breaks = seq(0, 40, 10)) +
  labs(x = NULL, y = "NCO registration (%)") +
  theme_journal(8) +
  theme(
    legend.position = "right",
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    plot.margin = margin(4, 18, 0, 6)
  )

p4c <- ggplot(filter(rolling, !is.na(percent)), aes(Year, percent, colour = Group)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = 2010, linetype = "22", linewidth = 0.35, colour = "grey40") +
  scale_colour_manual(values = c("Industry" = col_accent, "Non-industry" = col_navy), name = NULL) +
  scale_y_continuous(limits = c(0, 40), breaks = seq(0, 40, 10), expand = c(0, 0)) +
  labs(x = "Registration year (ClinicalTrials.gov)", y = "5-year rolling NCO (%)") +
  theme_journal(8) +
  theme(
    legend.position = "bottom",
    legend.margin = margin(t = 0),
    plot.margin = margin(4, 18, 6, 6)
  )

fig4 <- p4a / p4b / p4c +
  plot_layout(heights = c(0.5, 1.2, 1.0)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 10))

# ---- Figure 5: prevalence + ICCTF quality ----------------------------------
prev <- data.frame(
  Endpoint = factor(c("Objective NCO", "HRQoL"), levels = c("HRQoL", "Objective NCO")),
  est = c(mean(d$NCO), mean(hrqol_data$HRQoL)),
  lower = c(nco_ci["lower"], hrqol_ci["lower"]),
  upper = c(nco_ci["upper"], hrqol_ci["upper"]),
  lab = c(
    sprintf("%d/%d (%.1f%%)", sum(d$NCO), nrow(d), 100 * mean(d$NCO)),
    sprintf("%d/%d (%.1f%%)", sum(hrqol_data$HRQoL), nrow(hrqol_data), 100 * mean(hrqol_data$HRQoL))
  )
)

p5a <- ggplot(prev, aes(100 * est, Endpoint)) +
  geom_errorbarh(aes(xmin = 100 * lower, xmax = 100 * upper),
                 height = 0.15, linewidth = 0.5, colour = col_navy) +
  geom_point(size = 2.6, shape = 15, colour = col_navy) +
  geom_text(aes(label = lab), nudge_y = 0.28, size = 2.6) +
  scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, 10), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Trials registering the endpoint (%)", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

icctf_bars <- icctf_summary |>
  filter(metric != "NCO-positive trials") |>
  mutate(
    metric = recode(
      metric,
      "Any ICCTF core test (HVLT-R, TMT, or COWAT)" = "Any ICCTF core test",
      "Full ICCTF core battery (all three)" = "Full ICCTF core battery",
      "MMSE or MoCA without an ICCTF core test" = "MMSE/MoCA only",
      "Named domain only" = "Named domain only"
    ),
    metric = factor(
      metric,
      levels = rev(c("Any ICCTF core test", "Full ICCTF core battery",
                     "MMSE/MoCA only", "Named domain only"))
    ),
    pct = 100 * n / nrow(icctf)
  )

p5b <- ggplot(icctf_bars, aes(pct, metric)) +
  geom_col(width = 0.62, fill = col_navy, colour = NA) +
  geom_text(aes(label = sprintf("%d/%d", n, nrow(icctf))), hjust = -0.15, size = 2.6) +
  scale_x_continuous(limits = c(0, 72), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Among NCO-positive trials (%)", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

fig5 <- p5a + p5b + plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 10))

fig_s1 <- ggplot(instrument_counts, aes(n, Instrument, fill = icctf)) +
  geom_col(width = 0.7, colour = NA) +
  geom_text(aes(label = n), hjust = -0.3, size = 2.7) +
  scale_fill_manual(
    values = c("TRUE" = col_navy, "FALSE" = "grey70"),
    labels = c("TRUE" = "ICCTF core", "FALSE" = "Other"),
    name = NULL
  ) +
  scale_x_continuous(
    limits = c(0, max(instrument_counts$n) + 3),
    expand = expansion(mult = c(0, 0.02)),
    breaks = seq(0, 20, 5)
  ) +
  labs(x = "Trials registering the instrument", y = NULL) +
  theme_journal(8) +
  theme(
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "bottom"
  )

sens_acad <- sensitivity_results |>
  filter(term == "Sponsor_fAcademic/Investigator-Initiated") |>
  mutate(
    analysis = factor(analysis, levels = rev(unique(analysis))),
    y_num = as.numeric(analysis)
  )
fig_s2 <- ggplot(sens_acad, aes(OR, y_num)) +
  geom_vline(xintercept = 1, linetype = "22", linewidth = 0.35, colour = "grey40") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.2, linewidth = 0.45, colour = col_navy) +
  geom_point(size = 2.1, shape = 15, colour = col_navy) +
  geom_text(
    aes(x = 11.2, label = sprintf("%.2f (%.2f-%.2f)", OR, lower, upper)),
    hjust = 1, size = 2.5
  ) +
  scale_x_continuous(limits = c(0.8, 12), breaks = c(1, 2, 4, 8)) +
  scale_y_continuous(breaks = sens_acad$y_num, labels = as.character(sens_acad$analysis)) +
  labs(x = "Adjusted OR, academic vs industry", y = NULL) +
  theme_journal(8) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())

save_figure(fig1, "Figure1_discordance_mosaic", 6.8, 3.6)
save_figure(fig2, "Figure2_modality_prevalence", 7.1, 3.5)
save_figure(fig3, "Figure3_adjusted_associations", 7.2, 5.2)
save_figure(fig4, "Figure4_temporal_by_sponsor", 7.1, 6.2)
save_figure(fig5, "Figure5_endpoint_summary", 7.2, 3.3)
save_figure(fig_s1, "FigureS1_instruments", 5.8, 4.2)
save_figure(fig_s2, "FigureS2_sensitivity_academic", 6.6, 3.4)
