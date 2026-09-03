Mubashir Ahmad Khan, MBBS
Independent Researcher
[City, Country]
khanmubashirahmad@gmail.com

[Date]

The Editors
Journal of Clinical Epidemiology

Dear Editors,

I am submitting "Objective Neurocognitive Endpoints in Randomized Glioblastoma
and High-Grade Glioma Trials: A Cross-Sectional Registry Analysis" for
consideration as an Original Article.

The paper asks a measurement question rather than a clinical one. A large body
of work has assessed how well cognitive outcomes are *reported* once a trial has
elected to measure them. Almost none has asked how often they are elected at
all, or how that election compares with a second patient-centered domain inside
the same trial. Across 289 randomized phase II, II/III and III trials, an
objective neurocognitive outcome was registered in 13.5% and health-related
quality of life in 37.2%. Seventy trials registered HRQoL without cognition; four
did the reverse. Two trials in the whole cohort made cognition a primary
endpoint, and registration did not improve after 2010.

Three features seem to me to belong in this journal rather than a
subject-specialty one.

The paired within-trial contrast is the design point. Two independently reported
domain prevalences cannot distinguish a field that measures cognition rarely
from one that measures it rarely *because* something else occupies the
patient-centered slot. The McNemar discordance can, and it gives a different
answer than the marginal comparison would.

The separation problem is instructive rather than incidental. No
international-only record registered an objective neurocognitive outcome, so
ordinary logistic regression returned an odds ratio of 0.000 with an infinite
interval. Firth penalized likelihood recovered estimable associations across
every covariate. Registry audits with sparse strata will meet this regularly,
and the paper is explicit about it being a prespecified response rather than a
post-hoc rescue.

The specificity test is the part I would most want reviewed. It would have been
easy to report that academic sponsorship predicts cognitive-outcome registration
and stop. Stacking both outcomes within trial and testing a sponsor-by-domain
interaction gives P = .389 — the association is not demonstrably specific to
cognition. That negative result is reported prominently because a single-outcome
model would have licensed a claim the data do not support.

The analysis is fully reproducible. One R script reads the retained source
matrix, asserts the cohort count and event count before estimating anything, and
regenerates every table and figure with no hard-coded values. Data and code are
public at https://github.com/Mubashir-zz/glioma-nco-registry-study.

The manuscript is original, is not under consideration elsewhere, and has not
been published previously. I am the sole author and have no funding or competing
interests to declare. Screening and abstraction were performed by one
investigator without independent duplicate review; this is stated in the
limitations and I have not softened it. AI tools were used for coding assistance,
statistical verification and language editing under my direction, as declared in
the manuscript; they did not serve as reviewers or adjudicators and I retain
responsibility for every scientific decision.

Thank you for considering the work.

Yours sincerely,

Mubashir Ahmad Khan, MBBS
