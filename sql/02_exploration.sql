-- =====================================================================
-- 02_exploration.sql
-- Purpose: Investigate raw staging data before writing cleaning logic
-- in 03_cleaning.sql. Answers: what values actually appear in each
-- column, especially non-numeric junk in numeric-looking fields, so
-- cleaning rules are based on observed data rather than assumptions.
-- =====================================================================

-- 1. All distinct conditions measured in the readmissions program.
-- Expect 6: AMI, CABG, COPD, HF, HIP-KNEE, PN (pneumonia).
SELECT DISTINCT measure_name FROM staging_rrp;

-- 2. Non-numeric values in "Number of Discharges" — expect CMS
-- suppression codes like 'N/A' mixed in with plain integers.
SELECT DISTINCT number_of_discharges FROM staging_rrp
WHERE number_of_discharges !~ '^[0-9]+$';

-- 3. Non-numeric values in "Number of Readmissions" — expect
-- 'Too Few to Report' (CMS small-cell suppression), not a true zero.
SELECT DISTINCT number_of_readmissions FROM staging_rrp
WHERE number_of_readmissions !~ '^[0-9]+$';

-- 4. Footnote codes on RRP rows and their frequency — determines
-- whether footnotes correlate with suppressed rows and need their
-- own lookup/explanation in the cleaned table.
SELECT footnote, COUNT(*) FROM staging_rrp
GROUP BY footnote
ORDER BY COUNT(*) DESC;

-- 5. Distinct hospital ownership categories — this is a candidate
-- explanatory variable for "what do underperforming hospitals
-- have in common" (e.g. Proprietary vs. Voluntary non-profit vs. Government).
SELECT DISTINCT hospital_ownership FROM staging_hgi;

-- 6. Distribution of overall star rating, including non-numeric/blank
-- values (some hospitals aren't rated — need to know how common
-- that is before deciding how to handle it in cleaning).
SELECT DISTINCT hospital_overall_rating, COUNT(*) FROM staging_hgi
GROUP BY hospital_overall_rating
ORDER BY hospital_overall_rating;

-- 7. Distinct HCAHPS measure ID suffixes — determines which rows to
-- keep. Expect a mix of: _A_P / _SN_P / _U_P (answer % breakdowns),
-- _LINEAR_SCORE (mean score, what we mainly want), and star-rating-only
-- rows. Only a LIMIT 40 sample for now — full distinct list needed
-- before finalizing the filter in 03_cleaning.sql.
SELECT DISTINCT hcahps_measure_id FROM staging_hcahps
ORDER BY hcahps_measure_id
LIMIT 40;

-- 8. Uncapped version of previous query
SELECT DISTINCT hcahps_measure_id FROM staging_hcahps ORDER BY hcahps_measure_id;