-- =====================================================================
-- 01_staging.sql
-- Purpose: Create staging tables (all columns as TEXT) and load raw
-- CMS CSVs as-is. No type casting or cleaning happens here — that's
-- 03_cleaning.sql. Loading everything as TEXT means nothing fails on
-- import due to suppression codes like 'N/A' or 'Too Few to Report'
-- sitting in otherwise-numeric columns.
-- =====================================================================

CREATE TABLE staging_rrp (
    facility_name TEXT,
    facility_id TEXT,
    state TEXT,
    measure_name TEXT,
    number_of_discharges TEXT,
    footnote TEXT,
    excess_readmission_ratio TEXT,
    predicted_readmission_rate TEXT,
    expected_readmission_rate TEXT,
    number_of_readmissions TEXT,
    start_date TEXT,
    end_date TEXT
);

CREATE TABLE staging_hgi (
    facility_id TEXT,
    facility_name TEXT,
    address TEXT,
    city_town TEXT,
    state TEXT,
    zip_code TEXT,
    county_parish TEXT,
    telephone_number TEXT,
    hospital_type TEXT,
    hospital_ownership TEXT,
    emergency_services TEXT,
    birthing_friendly TEXT,
    hospital_overall_rating TEXT,
    hospital_overall_rating_footnote TEXT,
    mort_group_measure_count TEXT,
    count_facility_mort_measures TEXT,
    count_mort_better TEXT,
    count_mort_no_different TEXT,
    count_mort_worse TEXT,
    mort_group_footnote TEXT,
    safety_group_measure_count TEXT,
    count_facility_safety_measures TEXT,
    count_safety_better TEXT,
    count_safety_no_different TEXT,
    count_safety_worse TEXT,
    safety_group_footnote TEXT,
    readm_group_measure_count TEXT,
    count_facility_readm_measures TEXT,
    count_readm_better TEXT,
    count_readm_no_different TEXT,
    count_readm_worse TEXT,
    readm_group_footnote TEXT,
    pt_exp_group_measure_count TEXT,
    count_facility_pt_exp_measures TEXT,
    pt_exp_group_footnote TEXT,
    te_group_measure_count TEXT,
    count_facility_te_measures TEXT,
    te_group_footnote TEXT
);

CREATE TABLE staging_hcahps (
    facility_id TEXT,
    facility_name TEXT,
    address TEXT,
    city_town TEXT,
    state TEXT,
    zip_code TEXT,
    county_parish TEXT,
    telephone_number TEXT,
    hcahps_measure_id TEXT,
    hcahps_question TEXT,
    hcahps_answer_description TEXT,
    patient_survey_star_rating TEXT,
    patient_survey_star_rating_footnote TEXT,
    hcahps_answer_percent TEXT,
    hcahps_answer_percent_footnote TEXT,
    hcahps_linear_mean_value TEXT,
    number_of_completed_surveys TEXT,
    number_of_completed_surveys_footnote TEXT,
    survey_response_rate_percent TEXT,
    survey_response_rate_percent_footnote TEXT,
    start_date TEXT,
    end_date TEXT
);

\copy staging_rrp FROM 'data/raw/FY_2026_Hospital_Readmissions_Reduction_Program_Hospital.csv' WITH (FORMAT csv, HEADER true, QUOTE '"');

\copy staging_hgi FROM 'data/raw/Hospital_General_Information.csv' WITH (FORMAT csv, HEADER true, QUOTE '"');

\copy staging_hcahps FROM 'data/raw/HCAHPS-Hospital.csv' WITH (FORMAT csv, HEADER true, QUOTE '"');