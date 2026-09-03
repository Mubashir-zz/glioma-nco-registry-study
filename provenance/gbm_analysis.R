# =============================================================================
#  GBM Neurocognitive-Outcomes Registry Audit  —  master analysis script
#  Reproduces: Table 3 (Firth model), Figure 2 (forest), Figure 3 (temporal),
#              Figure 5 (PRISMA).  Runs top-to-bottom in RStudio.
#
#  HOW TO RUN
#  1. Put this file and "gbm_analytic_289.csv" in the SAME folder.
#  2. In RStudio: Session > Set Working Directory > To Source File Location.
#  3. Select all (Ctrl/Cmd-A) and Run (Ctrl/Cmd-Enter), or: source("gbm_analysis.R")
#  4. Outputs are written next to the script: Fig2_forest.png, Fig3_temporal.png,
#     Fig5_PRISMA.(svg/png), and the model tables print to the Console.
# =============================================================================

## ---- 0. Install any missing packages (needs internet the first time only) ---
need <- c("logistf", "ggplot2", "DiagrammeR", "DiagrammeRsvg", "rsvg")
new  <- need[!(need %in% rownames(installed.packages()))]
if (length(new)) install.packages(new)      # CRAN works fine on your machine
library(logistf); library(ggplot2)

## ---- 1. Read the analytic sheet --------------------------------------------
# Full path to the CSV on THIS Mac (works no matter what the working directory is).
csv_path <- "/Users/mac/Documents/Trial study/Transfer and new/GBM_Global_Study/gbm_analytic_289.csv"
# If you ever move the file, either edit the line above, OR just use the file picker:
#   csv_path <- file.choose()      # <- un-comment this line to click-and-choose the file
setwd(dirname(csv_path))           # make the project folder the working dir -> all outputs land here
d <- read.csv(csv_path, stringsAsFactors = FALSE)
cat("Rows:", nrow(d), " | NCO events:", sum(d$NCO), "\n")   # expect 289 / 39

# factors with the SAME reference categories used in the manuscript
d$phase_f   <- relevel(factor(d$Phase),        ref = "PHASE2")
d$sponsor_f <- relevel(factor(d$Sponsor_Class),ref = "Industry")
d$reg_f     <- relevel(factor(d$Registry_Source), ref = "US")
d$year      <- as.numeric(d$Registration_Year)
d$year_c    <- d$year - mean(d$year)          # centre year for numerical stability

## ---- 2. Firth penalized-likelihood logistic regression  (=> Table 3) -------
# logistf handles the complete separation caused by the 0/14 international cell.
m <- logistf(NCO ~ phase_f + sponsor_f + year_c + Radiation + reg_f, data = d)

tab <- data.frame(
  Term  = names(coef(m)),
  OR    = round(exp(coef(m)), 2),
  CIlow = round(exp(m$ci.lower), 2),
  CIupp = round(exp(m$ci.upper), 2),
  P     = signif(m$prob, 3),
  row.names = NULL
)
cat("\n================ TABLE 3  (Firth penalized likelihood) ================\n")
print(tab)
cat("N =", nrow(d), " events =", sum(d$NCO), "\n")
print(summary(m))   # this also prints the overall penalized likelihood-ratio test
# (You should see: Academic 2.94, Cooperative 3.55, year 1.05, Radiation 2.25,
#  Phase III 1.65, International 0.20.)

## ---- 3. FIGURE 2 — forest plot (built from the logistf output above) -------
fp <- subset(tab, !(Term %in% c("(Intercept)", "reg_fInternational")))  # main predictors
labmap <- c(sponsor_fAcademic.Investigator.Initiated = "Academic vs Industry",
            "sponsor_fAcademic/Investigator-Initiated" = "Academic vs Industry",
            "sponsor_fGovernment/Cooperative Group"    = "Cooperative group vs Industry",
            Radiation = "Radiation-containing regimen",
            year_c    = "Registration year (per year)",
            phase_fPHASE3 = "Phase III vs Phase II")
fp$lab   <- ifelse(fp$Term %in% names(labmap), labmap[fp$Term], fp$Term)
fp <- fp[match(c("Academic vs Industry","Cooperative group vs Industry",
                 "Radiation-containing regimen","Registration year (per year)",
                 "Phase III vs Phase II"), fp$lab), ]
fp <- fp[!is.na(fp$lab), ]
fp$lab  <- factor(fp$lab, levels = rev(fp$lab))
fp$sig  <- fp$P < 0.05                                   # colour by significance (year IS sig at P<.001)
fp$text <- sprintf("%.2f (%.2f–%.2f)", fp$OR, fp$CIlow, fp$CIupp)  # uniform 2-decimal padding

ggplot(fp, aes(OR, lab, colour = sig)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "#0B3D5C", linewidth = .5) +
  geom_errorbarh(aes(xmin = CIlow, xmax = CIupp), height = .16, linewidth = 1) +
  geom_point(size = 3.4) +
  geom_text(aes(x = CIupp, label = text), hjust = -0.2, colour = "#1a1a1a", size = 3.6) +
  scale_x_log10(limits = c(0.3, 20), breaks = c(.5,1,2,4,8,16),
                labels = c("0.5","1","2","4","8","16")) +
  scale_colour_manual(values = c(`TRUE`="#D55E00", `FALSE`="#8C9196"), guide = "none") +
  labs(x = "Adjusted odds ratio for NCO registration (95% CI, log scale)", y = NULL,
       title = "Figure 2.  Multivariable predictors of neurocognitive-outcome registration",
       caption = "Industry = reference.  Firth penalized likelihood (N=289, 39 events); profile-likelihood 95% CIs.") +
  theme_classic(base_size = 12) +
  theme(axis.text.y = element_text(margin = margin(r = 18)),   # push labels clear of the reference line
        axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        plot.title = element_text(face = "bold", size = 12.5), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, colour = "grey40", size = 8, face = "italic"),
        plot.caption.position = "plot", plot.margin = margin(14, 115, 14, 14)) +  # wide right margin => no clipping
  coord_cartesian(clip = "off")
ggsave("Fig2_forest.png", width = 10, height = 4.7, dpi = 300)

## ---- 4. FIGURE 3 — temporal trend (US ClinicalTrials.gov series) -----------
us <- subset(d, Registry_Source == "US")
us$era <- cut(us$year, breaks = c(-Inf,2009,2014,2019,Inf),
              labels = c("≤2009","2010–2014","2015–2019","2020–2026"))
agg <- aggregate(NCO ~ era, us, function(x) c(k = sum(x), n = length(x)))
ea  <- data.frame(era = agg$era, k = agg$NCO[,"k"], n = agg$NCO[,"n"])
wil <- function(k,n,z=1.96){p<-k/n; d<-1+z^2/n; c<-(p+z^2/(2*n))/d
        h<-z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d; c(100*(c-h),100*(c+h))}
ci  <- t(mapply(wil, ea$k, ea$n))
ea$pct <- round(100*ea$k/ea$n,1); ea$lo <- ci[,1]; ea$hi <- ci[,2]
ea$xlab <- sprintf("%s\n(%d/%d)", ea$era, ea$k, ea$n)

ggplot(ea, aes(era, pct, group = 1)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .12, colour = "#8C9196", linewidth = .8) +
  geom_line(colour = "#0072B2", linewidth = 1) +
  geom_point(colour = "#0072B2", size = 3.8) +
  # % labels placed above the top of each 95% CI whisker, lifted clear of the bars
  geom_text(aes(y = hi, label = sprintf("%.1f%%", pct)), vjust = -1.1, fontface = "bold",
            colour = "#0B3D5C", size = 4.1) +
  scale_x_discrete(labels = ea$xlab, expand = expansion(add = 0.55)) +   # breathing room at both ends
  scale_y_continuous(limits = c(0,45), breaks = seq(0,40,10), expand = expansion(mult = c(0.02,0.04))) +
  labs(x = "Registration era", y = "Trials registering an NCO (%)",
       title = "Figure 3.  Temporal trend in neurocognitive-outcome registration",
       caption = "Adjusted OR 1.05/year (95% CI 1.00–1.11; P<.001, Firth). 275 ClinicalTrials.gov trials, registry-consistent dating.") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12.5), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, colour = "grey40", size = 8, face = "italic"),
        plot.caption.position = "plot", plot.margin = margin(14, 16, 12, 12)) +
  coord_cartesian(clip = "off")
ggsave("Fig3_temporal.png", width = 8.4, height = 5, dpi = 300)

## ---- 5. FIGURE 5 — PRISMA flow (DiagrammeR / Graphviz, true vector) ---------
# Renders a clean vector flowchart. Export to SVG/PNG below.
library(DiagrammeR)
prisma <- grViz("
digraph prisma {
  graph [layout = dot, rankdir = TB, fontsize = 11, fontname = Helvetica, nodesep = 0.5, ranksep = 0.55]
  node  [shape = box, style = 'rounded,filled', fontname = Helvetica, fontsize = 10,
         color = '#33475b', penwidth = 1.3, margin = '0.18,0.12']

  id   [label = 'Records identified across 9 trial registries (n = 758)\\nClinicalTrials.gov 302  •  EU-CTR 224  •  WHO ICTRP 199  •  ISRCTN 33', fillcolor = '#EEF3F8', width = 6]
  us1  [label = 'ClinicalTrials.gov records screened\\n(n = 302)', fillcolor = '#EEF3F8']
  in1  [label = 'International records screened\\n(EU-CTR 224 + ICTRP 199 + ISRCTN 33; n = 456)', fillcolor = '#EEF3F8']
  usx  [label = 'Excluded (n = 27)\\l• Supportive / ancillary care (n = 20)\\l• Ineligible population (n = 6)\\l• Non-randomized on adjudication (n = 1)\\l', fillcolor = '#F6E7E1', color = '#D55E00']
  inx  [label = 'Removed (n = 442)\\l• Duplicate / dual registration (n = 227)\\l• Ineligible design/population/non-therapeutic (n = 215)\\l', fillcolor = '#F6E7E1', color = '#D55E00']
  us2  [label = 'ClinicalTrials.gov eligible primary set\\n(n = 275)', fillcolor = '#E4F1EC', color = '#009E73']
  in2  [label = 'International-only eligible trials\\n(EU-CTR 11 + ISRCTN 3; n = 14)', fillcolor = '#E4F1EC', color = '#009E73']
  note [label = 'Deduplication audit of the 227 duplicates: WHO ICTRP (n = 199) all resolved to\\ntrials already registered on CT.gov / EU-CTR (0 net additions); remaining 28 were dual registrations.', fillcolor = '#FBF3DE', color = '#E69F00', width = 6]
  inc  [label = 'INCLUDED IN ANALYSIS\\n289 randomized GBM/HGG RCTs (275 US + 14 international)', fillcolor = '#0B3D5C', fontcolor = white, penwidth = 0]
  res  [label = 'Objective NCO 39/289 (13.5%), primary in 2  •  HRQoL 105/289 (36.3%)\\nIndustry sponsorship independently predicts NCO omission (Firth-adjusted)', fillcolor = '#EEF3F8']

  id -> us1;  id -> in1
  us1 -> usx [arrowhead=none]; us1 -> us2
  in1 -> inx [arrowhead=none]; in1 -> in2
  us2 -> note; in2 -> note
  note -> inc -> res
  {rank = same; us1; in1}
  {rank = same; usx; inx}
  {rank = same; us2; in2}
}
")
prisma   # shows in RStudio Viewer
# save as vector SVG (best for journals) and a high-res PNG:
svg_raw <- charToRaw(DiagrammeRsvg::export_svg(prisma))
rsvg::rsvg_svg(svg_raw, "Fig5_PRISMA.svg")
rsvg::rsvg_png(svg_raw, "Fig5_PRISMA.png", width = 1800)

cat("\nDONE. Wrote Fig2_forest.png, Fig3_temporal.png, Fig5_PRISMA.svg/.png in the working folder.\n")
