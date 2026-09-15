"""Compare regenerated result tables against the committed ones.

Byte-for-byte comparison is the obvious check and it is the wrong one here.
The Firth fits and their profile-likelihood confidence limits are found by
iterative optimisation, so the last two or three of the fifteen digits R
writes out depend on the BLAS/LAPACK build underneath: macOS Accelerate and
the Linux runner's OpenBLAS disagree at a relative size of about 1e-14. That
is numerical noise, not a change in a result.

So numbers are compared with a relative tolerance of 1e-8 -- six orders of
magnitude tighter than the fourth significant figure the manuscript reports,
and still loose enough to survive a different linear-algebra backend. Any
real change to the code, the data, or the model specification moves an
estimate far beyond that and fails the build. The two bootstrap summary
tables are the exception and are explained where their tolerance is set.
Non-numeric cells, the column names, and the row count must match exactly.
"""

from __future__ import annotations

import csv
import math
import sys
from pathlib import Path

RTOL = 1e-8
ATOL = 1e-12

# Two tables summarise 2,000 bootstrap replicates rather than a single fit, so
# the per-fit noise above accumulates: observed drift between macOS and the
# Linux runner is about 6e-6 relative, not 1e-14. They get a tolerance of 1e-4,
# which is still an order of magnitude tighter than the three significant
# figures the manuscript quotes from them.
MONTE_CARLO_RTOL = 1e-4
MONTE_CARLO_TABLES = {
    "bootstrap_performance.csv",
    "prevalence_difference_bootstrap.csv",
}


def as_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def cells_agree(committed, regenerated, rtol=RTOL):
    if committed == regenerated:
        return True
    a, b = as_float(committed), as_float(regenerated)
    if a is None or b is None:
        return False
    if math.isnan(a) and math.isnan(b):
        return True
    return math.isclose(a, b, rel_tol=rtol, abs_tol=ATOL)


def read_rows(path):
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.reader(handle))


def compare(committed_path, regenerated_path):
    name = regenerated_path.name
    if not committed_path.exists():
        return ["%s: no committed version to compare against" % name]

    committed, regenerated = read_rows(committed_path), read_rows(regenerated_path)
    if len(committed) != len(regenerated):
        return ["%s: %d committed rows, %d regenerated"
                % (name, len(committed), len(regenerated))]

    rtol = MONTE_CARLO_RTOL if name in MONTE_CARLO_TABLES else RTOL
    problems = []
    for row_no, (want, got) in enumerate(zip(committed, regenerated), start=1):
        if len(want) != len(got):
            problems.append("%s: row %d has %d committed fields, %d regenerated"
                            % (name, row_no, len(want), len(got)))
            continue
        for col_no, (w, g) in enumerate(zip(want, got), start=1):
            if not cells_agree(w, g, rtol):
                problems.append("%s: row %d, column %d: committed %r, regenerated %r"
                                % (name, row_no, col_no, w, g))
    return problems


def main():
    committed_dir, regenerated_dir = Path(sys.argv[1]), Path(sys.argv[2])
    tables = sorted(regenerated_dir.glob("*.csv"))
    if not tables:
        print("::error::no regenerated tables found in %s" % regenerated_dir)
        return 1

    problems = []
    for table in tables:
        problems.extend(compare(committed_dir / table.name, table))

    for problem in problems[:60]:
        print("::error::%s" % problem)
    if len(problems) > 60:
        print("::error::... and %d further mismatches" % (len(problems) - 60))

    if problems:
        return 1
    print("All %d tables reproduce: relative tolerance %g, or %g for the %d "
          "bootstrap summaries."
          % (len(tables), RTOL, MONTE_CARLO_RTOL, len(MONTE_CARLO_TABLES)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
