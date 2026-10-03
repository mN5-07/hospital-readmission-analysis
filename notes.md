# NC Hospital Readmission Analysis

## Overview

**Business question:** Which hospitals in North Carolina — particularly
in the Charlotte metro area — have higher-than-expected readmission
rates, and what do the underperformers have in common (ownership type,
star rating, patient experience)?

**Data source:** CMS Provider Data Catalog, three public datasets:
- Hospital Readmissions Reduction Program (FY 2026) — excess
  readmission ratios by hospital and condition
- Hospital General Information — ownership, star rating, location
- HCAHPS (patient experience survey) — patient-reported scores by
  hospital

**Tools:** PostgreSQL (cleaning, analysis) → Power BI (dashboard,
3 pages: NC Hospital Readmission Overview, Charlotte-Area Hospital
Comparison, Hospital Detail (drill-through))

**Repo structure:**
```
data/
  raw/        — original CMS CSVs (RRP, Hospital General Info, HCAHPS)
  processed/  — [describe what's here if anything is exported from SQL]
sql/
  01_staging.sql     — creates DB, staging tables, loads raw CSVs as TEXT
  02_exploration.sql — investigation behind the cleaning decisions
  03_cleaning.sql    — type casts, suppression-code handling, HCAHPS filter
  04_analysis.sql    — builds nc_hospital_readmission_summary + dashboard queries
notes.md      — [describe purpose if kept in repo, or fold into this README]
report.pbix   — Power BI dashboard
requirements.txt
```

**How to reproduce:**
1. Load the three raw CSVs into `data/raw/`
2. Run `sql/01_staging.sql` — creates the database and staging tables,
   loads raw CSVs as-is (all TEXT columns)
3. Run `sql/02_exploration.sql` — optional, documents the investigation
   behind the cleaning decisions below
4. Run `sql/03_cleaning.sql` — casts types, resolves suppression codes,
   filters HCAHPS to comparable measures
5. Run `sql/04_analysis.sql` — builds the `nc_hospital_readmission_summary`
   view and the queries behind the dashboard
6. Open `report.pbix` in Power BI Desktop, point the PostgreSQL
   connector at your local database

## Key Findings

**1. NC's highest-readmission hospitals are predominantly rural and
small-system.** Of the 20 NC hospitals with the worst excess readmission
ratios (1.02–1.11, meaning 2–11% more readmissions than expected for
their patient mix), the large majority are standalone rural or regional
medical centers in small, non-metro counties (e.g. Carteret, Columbus,
Sampson, Duplin, Hertford). Two exceptions stand out: ECU Health Medical
Center (Greenville) — the #1 worst performer in the entire NC
ranking — and Duke Health Lake Norman Hospital (Mooresville), both
flagship or satellite facilities of larger health systems. The pattern
is a strong tendency, not an absolute rule.

**2. Star rating shows a real, if modest, inverse relationship with
readmission performance.** Average excess readmission ratio declines
step-wise with star rating: 1.05 (1-star) → 1.02 (2-star) → 0.99
(3-star) → 0.99 (4-star) → 0.96 (5-star). This is the clearest pattern
in the data — a half-star gradient across the scale — though the
underlying CMS star rating already incorporates readmissions as one
input, so this isn't fully independent confirmation.

**3. Ownership type shows no meaningful difference.** For-profit
(1.003), Nonprofit (0.993), and Government (0.991) hospitals cluster
within half a percentage point of each other. At this sample size, this
doesn't support a claim that ownership structure drives readmission
performance.

**4. In the Charlotte metro area, CaroMont Regional (Gastonia, 1.078)
and Duke Health Lake Norman (Mooresville, 1.076) have the highest
excess readmission ratios among the 12 ranked hospitals; Novant Health
Presbyterian (Charlotte, 0.901) has the lowest.** The spread across the
Charlotte-area hospitals (0.90–1.08) is wider than the overall NC
ownership-category gap, suggesting facility-level factors matter more
locally than system-wide ownership structure.

**5. Patient experience does not clearly track with readmission
performance.** Plotting each Charlotte-area hospital's overall patient
rating (HCAHPS linear mean score) against its excess readmission ratio
shows no visible trend — CaroMont has the worst readmission ratio in
the group but a mid-to-high patient experience score, while several
hospitals with similar patient experience scores land on opposite ends
of the readmission ranking. Patients reporting a good experience is not
a reliable signal of lower readmission rates in this sample.

## Limitations

- **36% of hospital/condition readmission rows have no ratio** — low
  patient volume or data unavailable for the reporting period, not
  suppressed poor performance. See Data Cleaning Decisions.
- **41% of hospitals have no overall star rating** — any star-rating
  analysis implicitly excludes these.
- **2 of 14 Charlotte-area hospitals are excluded** from ranking for
  insufficient reported measures (see Data Cleaning Decisions).
- **Correlation, not causation.** None of the patterns above establish
  that ownership, rating, or patient experience *cause* readmission
  outcomes — only that they do or don't move together in this dataset.
- **Single reporting period.** This reflects one FY2026 snapshot;
  trends over time aren't assessed here.

## Data Cleaning Decisions

### Excess Readmission Ratio missingness (36% of rows)
Of 18,330 hospital/condition rows, 6,610 (36%) have no excess readmission
ratio. Confirmed against CMS's Footnote Crosswalk dataset
(data.cms.gov/provider-data — Footnote Crosswalk, last modified Sept 2025)
as three distinct causes:

- **3,255 rows (18%) — footnote 5**: "Results are not available for
  this reporting period."
- **3,150 rows (17%) — footnote 1**: "The number of cases/patients is
  too few to report." CMS suppresses the discharge count and does not
  compute a ratio when patient volume is too low. This is privacy-driven
  suppression, not evidence of zero or good performance.
- **205 rows (1%) — footnote 7**: "No cases met the criteria for this
  measure." Hospital had zero discharges meeting this measure's
  inclusion criteria in the period; ratio is mathematically undefined
  (division by zero), not missing data.

All three are excluded from ratio-based rankings/averages rather than
treated as zero or silently dropped — see the `ratio_status` column in
`clean_rrp`.

### Suppressed readmission counts
Where `number_of_readmissions = 'Too Few to Report'`, CMS is hiding a
small nonzero count for patient privacy. These are stored as NULL, not
0 — treating them as zero would understate readmissions at small
hospitals and bias any ranking toward falsely rewarding them.

### Facility ID
Stored as TEXT throughout, not cast to integer, to preserve leading
zeros (e.g. `"010001"`), which are part of the identifier, not padding.

### Hospital ownership categories
Collapsed from 12 raw CMS categories to 4 (Nonprofit, For-profit,
Government, Federal/Other) for group comparisons, since several raw
categories (Tribal, Department of Defense) have too few hospitals to
support standalone analysis. Original category retained in
`hospital_ownership` for anyone who wants the granular version.

### HCAHPS filtering
Reduced from 68 measure IDs to the subset ending in `_LINEAR_SCORE` or
`_STAR_RATING` — CMS's own designed-to-be-comparable summary metrics
per patient-experience topic (nurse comm, doctor comm, cleanliness,
etc.). Excluded the raw percentage-breakdown rows (e.g. `_A_P`, `_SN_P`)
since they're different representations of the same underlying measure,
not separate measures.

### Unrated hospitals
2,245 of 5,419 hospitals (41%) have no overall star rating
("Not Available"). This is a meaningful limitation — any analysis
grouped by star rating implicitly excludes over a third of hospitals.

### Charlotte-area hospital coverage (12 of 14)
Of 14 hospitals in the 5-county Charlotte area (Mecklenburg, Cabarrus,
Gaston, Union, Iredell), 2 are excluded from readmission rankings
(fewer than 3 of 6 HRRP conditions reported, the inclusion threshold
used in `nc_hospital_readmission_summary`):

- **Iredell Davis Behavioral Health Hospital** (Iredell County) — a
  psychiatric facility; not subject to the same medical/surgical
  readmission measures (AMI, COPD, HF, etc.) as acute care hospitals.
- **Novant Health Ballantyne Medical Center** (Mecklenburg County) —
  only 2 of 6 conditions reported (pneumonia: 0.96, heart failure:
  0.97); the remaining 4 are suppressed for low volume or unavailable
  for this reporting period, consistent with a lower-volume facility.