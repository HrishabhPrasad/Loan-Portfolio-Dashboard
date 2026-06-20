-- ============================================================
-- views.sql  —  Phase 4: views for Power BI
-- Run this ONCE in PopSQL. It creates two views that Power BI reads directly.
-- Safe to re-run (uses CREATE OR REPLACE).
-- ============================================================

USE Loan_Portfolio_Database;

-- ------------------------------------------------------------
-- VIEW 1: vw_loans_enriched
-- One row per loan, with ready-made analysis buckets and a
-- high/medium/low RISK SEGMENT. This is the MAIN table Power BI uses.
--
-- Risk segment logic (based on grade, the strongest single predictor):
--   Low    = grades A, B   (~6-12% default)
--   Medium = grades C, D   (~17-22% default)
--   High   = grades E, F, G(~27-34% default)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_loans_enriched AS
SELECT
    id,
    loan_amnt,
    loan_amnt_band,
    term_months,
    int_rate,
    installment,
    grade,
    sub_grade,
    purpose,
    emp_length_years,
    home_ownership,
    annual_inc,
    income_band,
    verification_status,
    dti,
    addr_state,
    pub_rec,
    delinq_2yrs,
    revol_util,
    open_acc,
    total_acc,
    pub_rec_bankruptcies,
    issue_d,
    YEAR(issue_d)                         AS issue_year,
    earliest_cr_line,
    loan_status,
    is_default,

    -- risk segment (high / medium / low)
    CASE
        WHEN grade IN ('A', 'B')           THEN 'Low'
        WHEN grade IN ('C', 'D')           THEN 'Medium'
        ELSE                                    'High'
    END                                   AS risk_segment,

    -- interest-rate band
    CASE
        WHEN int_rate < 8  THEN '1. <8%'
        WHEN int_rate < 11 THEN '2. 8-11%'
        WHEN int_rate < 14 THEN '3. 11-14%'
        WHEN int_rate < 17 THEN '4. 14-17%'
        ELSE                    '5. 17%+'
    END                                   AS int_rate_band,

    -- dti band
    CASE
        WHEN dti < 10 THEN '1. <10'
        WHEN dti < 15 THEN '2. 10-15'
        WHEN dti < 20 THEN '3. 15-20'
        WHEN dti < 25 THEN '4. 20-25'
        ELSE             '5. 25+'
    END                                   AS dti_band
FROM loans;

-- ------------------------------------------------------------
-- VIEW 2: vw_risk_summary
-- Pre-aggregated default rates by risk segment. Handy for a quick
-- summary visual / sanity check.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_risk_summary AS
SELECT
    CASE
        WHEN grade IN ('A', 'B') THEN 'Low'
        WHEN grade IN ('C', 'D') THEN 'Medium'
        ELSE                          'High'
    END                                   AS risk_segment,
    COUNT(*)                              AS loans,
    SUM(is_default)                       AS defaults,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct,
    ROUND(AVG(int_rate), 2)               AS avg_int_rate,
    ROUND(AVG(loan_amnt), 0)              AS avg_loan_amnt
FROM loans
GROUP BY risk_segment;
