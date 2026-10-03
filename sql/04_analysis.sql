-- =====================================================================
-- 04_analysis.sql
-- Purpose: Answer the business question — which NC (esp. Charlotte-
-- area) hospitals perform worse than expected on readmissions, and
-- what do they have in common (ownership, rating, patient experience)?
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. NC hospital ranking: average excess readmission ratio across all
-- reported conditions. Only includes ratio_status = 'reported' rows —
-- see 03_cleaning.sql / README for why the other 36% are excluded.
-- min_measures_reported guards against ranking a hospital on just 1
-- condition when others have 5-6; low-n comparisons are misleading.
-- ---------------------------------------------------------------------

DROP VIEW IF EXISTS nc_hospital_readmission_summary;
CREATE VIEW nc_hospital_readmission_summary AS
SELECT
    h.facility_id,
    h.facility_name,
    h.city_town,
    h.county_parish,
    h.ownership_category,
    h.hospital_overall_rating,
    (h.county_parish IN ('MECKLENBURG','CABARRUS','GASTON','UNION','IREDELL')) AS is_charlotte_area,
    COUNT(r.excess_readmission_ratio) AS measures_reported,
    ROUND(AVG(r.excess_readmission_ratio), 4) AS avg_excess_readmission_ratio
FROM clean_hgi h
JOIN clean_rrp r ON r.facility_id = h.facility_id
WHERE h.state = 'NC'
  AND r.ratio_status = 'reported'
GROUP BY h.facility_id, h.facility_name, h.city_town, h.county_parish,
         h.ownership_category, h.hospital_overall_rating
HAVING COUNT(r.excess_readmission_ratio) >= 3;  -- at least half of 6 conditions

-- Worst-performing NC hospitals (ratio > 1.0 = more readmissions than expected)
SELECT * FROM nc_hospital_readmission_summary
ORDER BY avg_excess_readmission_ratio DESC
LIMIT 20;

-- ---------------------------------------------------------------------
-- 2. Charlotte-area hospitals specifically, ranked
-- ---------------------------------------------------------------------
SELECT * FROM nc_hospital_readmission_summary
WHERE is_charlotte_area
ORDER BY avg_excess_readmission_ratio DESC;

-- ---------------------------------------------------------------------
-- 3. Does ownership type correlate with readmission performance?
-- NC only. AVG excludes NULLs automatically.
-- ---------------------------------------------------------------------
SELECT
    ownership_category,
    COUNT(*) AS hospital_count,
    ROUND(AVG(avg_excess_readmission_ratio), 4) AS mean_ratio
FROM nc_hospital_readmission_summary
GROUP BY ownership_category
ORDER BY mean_ratio DESC;

-- ---------------------------------------------------------------------
-- 4. Does star rating correlate with readmission performance?
-- Excludes unrated hospitals (NULL) — see README: 41% of all US
-- hospitals are unrated, so treat this comparison as partial.
-- ---------------------------------------------------------------------
SELECT
    hospital_overall_rating,
    COUNT(*) AS hospital_count,
    ROUND(AVG(avg_excess_readmission_ratio), 4) AS mean_ratio
FROM nc_hospital_readmission_summary
WHERE hospital_overall_rating IS NOT NULL
GROUP BY hospital_overall_rating
ORDER BY hospital_overall_rating;

-- ---------------------------------------------------------------------
-- 5. Patient experience vs. readmission performance (Charlotte area).
-- Joins in HCAHPS linear mean scores for the "overall hospital rating"
-- and "recommend" composites specifically, as the most general
-- patient-experience signals.
-- ---------------------------------------------------------------------
SELECT
    s.facility_name,
    s.county_parish,
    s.avg_excess_readmission_ratio,
    hc_overall.linear_mean_value AS overall_rating_linear_score,
    hc_recommend.linear_mean_value AS recommend_linear_score
FROM nc_hospital_readmission_summary s
LEFT JOIN clean_hcahps hc_overall
    ON hc_overall.facility_id = s.facility_id
   AND hc_overall.hcahps_measure_id = 'H_HSP_RATING_LINEAR_SCORE'
LEFT JOIN clean_hcahps hc_recommend
    ON hc_recommend.facility_id = s.facility_id
   AND hc_recommend.hcahps_measure_id = 'H_RECMND_LINEAR_SCORE'
WHERE s.is_charlotte_area
ORDER BY s.avg_excess_readmission_ratio DESC;