-- =====================================================================
-- 03_cleaning.sql
-- Purpose: Cast staging (TEXT) columns to real types, convert known
-- suppression/missing codes to NULL, and filter HCAHPS down to
-- comparable per-hospital composite scores. Re-runnable (DROP/CREATE).
-- =====================================================================

DROP TABLE IF EXISTS clean_rrp;
CREATE TABLE clean_rrp AS
SELECT
    facility_id,
    TRIM(facility_name) AS facility_name,
    state,
    measure_name,
    CASE WHEN number_of_discharges ~ '^[0-9]+$'
         THEN number_of_discharges::INT END AS number_of_discharges,
    CASE WHEN number_of_readmissions ~ '^[0-9]+$'
         THEN number_of_readmissions::INT END AS number_of_readmissions,
    CASE WHEN excess_readmission_ratio ~ '^[0-9.]+$'
         THEN excess_readmission_ratio::NUMERIC END AS excess_readmission_ratio,
    CASE WHEN predicted_readmission_rate ~ '^[0-9.]+$'
         THEN predicted_readmission_rate::NUMERIC END AS predicted_readmission_rate,
    CASE WHEN expected_readmission_rate ~ '^[0-9.]+$'
         THEN expected_readmission_rate::NUMERIC END AS expected_readmission_rate,
    NULLIF(footnote, '') AS footnote_code,
    -- Categorizes *why* the ratio is missing, instead of leaving it as
    -- an unexplained NULL. See README for footnote-code caveats.
        CASE
        WHEN excess_readmission_ratio ~ '^[0-9.]+$' THEN 'reported'
        WHEN footnote = '7' THEN 'zero_eligible_cases'
        WHEN footnote = '1' THEN 'too_few_to_report'
        WHEN footnote = '5' THEN 'not_available_this_period'
        ELSE 'other_missing'
    END AS ratio_status,
    start_date::DATE,
    end_date::DATE
FROM staging_rrp;

DROP TABLE IF EXISTS clean_hgi;
CREATE TABLE clean_hgi AS
SELECT
    facility_id,
    TRIM(facility_name) AS facility_name,
    address, city_town, state, zip_code, county_parish,
    hospital_type,
    hospital_ownership,
    -- Collapses 12 raw categories into 4 for cleaner grouping in analysis.
    CASE
        WHEN hospital_ownership LIKE 'Voluntary non-profit%' THEN 'Nonprofit'
        WHEN hospital_ownership IN ('Proprietary', 'Physician') THEN 'For-profit'
        WHEN hospital_ownership LIKE 'Government%' THEN 'Government'
        ELSE 'Federal/Other'                   -- VA, DoD, Tribal
    END AS ownership_category,
    (emergency_services = 'Yes') AS has_emergency_services,
    CASE WHEN hospital_overall_rating ~ '^[0-9]+$'
         THEN hospital_overall_rating::INT END AS hospital_overall_rating
FROM staging_hgi;

DROP TABLE IF EXISTS clean_hcahps;
CREATE TABLE clean_hcahps AS
SELECT
    facility_id,
    hcahps_measure_id,
    hcahps_question,
    CASE WHEN hcahps_linear_mean_value ~ '^[0-9.]+$'
         THEN hcahps_linear_mean_value::NUMERIC END AS linear_mean_value,
    CASE WHEN patient_survey_star_rating ~ '^[0-9]+$'
         THEN patient_survey_star_rating::INT END AS star_rating,
    CASE WHEN number_of_completed_surveys ~ '^[0-9]+$'
         THEN number_of_completed_surveys::INT END AS completed_surveys,
    CASE WHEN survey_response_rate_percent ~ '^[0-9.]+$'
         THEN survey_response_rate_percent::NUMERIC END AS response_rate_percent
FROM staging_hcahps
-- Keep only comparable composite-level scores; drop the raw
-- percentage-breakdown rows (_A_P, _SN_P, _U_P, etc.) — see
-- 02_exploration.sql output for the full suffix list.
WHERE hcahps_measure_id LIKE '%LINEAR_SCORE'
   OR hcahps_measure_id LIKE '%STAR_RATING';