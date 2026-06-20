-- ============================================================
-- analysis.sql  —  Phase 4: ANALYZE
-- Credit-risk analysis queries for the `loans` table.
-- Run these in PopSQL one block at a time (each is self-contained).
-- Every query answers a real question an interviewer might ask.
-- Default rate is always: AVG(is_default) * 100  (because is_default is 1/0).
-- ============================================================

USE Loan_Portfolio_Database;

-- ------------------------------------------------------------
-- Q0. HEADLINE NUMBERS — overall portfolio
-- ------------------------------------------------------------
SELECT
    COUNT(*)                              AS total_loans,
    SUM(is_default)                       AS total_defaults,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0)              AS avg_loan_amnt,
    ROUND(AVG(int_rate), 2)               AS avg_int_rate,
    ROUND(AVG(annual_inc), 0)             AS avg_annual_inc
FROM loans;

-- ------------------------------------------------------------
-- Q1. DEFAULT RATE BY GRADE  (the cleanest risk signal: A safest -> G riskiest)
-- ------------------------------------------------------------
SELECT
    grade,
    COUNT(*)                              AS loans,
    SUM(is_default)                       AS defaults,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct,
    ROUND(AVG(int_rate), 2)               AS avg_int_rate
FROM loans
GROUP BY grade
ORDER BY grade;

-- ------------------------------------------------------------
-- Q2. DEFAULT RATE BY LOAN PURPOSE  (why people borrow vs. how risky it is)
-- ------------------------------------------------------------
SELECT
    purpose,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY purpose
ORDER BY default_rate_pct DESC;

-- ------------------------------------------------------------
-- Q3. DEFAULT RATE BY EMPLOYMENT LENGTH  (does job stability matter?)
--     NULL emp_length shown as 'Unknown'.
-- ------------------------------------------------------------
SELECT
    CASE WHEN emp_length_years IS NULL THEN 'Unknown'
         ELSE CAST(emp_length_years AS CHAR) END   AS emp_length_years,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY emp_length_years
ORDER BY MIN(emp_length_years);

-- ------------------------------------------------------------
-- Q4. DEFAULT RATE BY INCOME BAND  (lower income -> more risk?)
-- ------------------------------------------------------------
SELECT
    income_band,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0)              AS avg_loan_amnt
FROM loans
GROUP BY income_band
ORDER BY FIELD(income_band, '<40k', '40-60k', '60-80k', '80-100k', '100k+');

-- ------------------------------------------------------------
-- Q5. DEFAULT RATE BY LOAN AMOUNT BAND  (do bigger loans default more?)
-- ------------------------------------------------------------
SELECT
    loan_amnt_band,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY loan_amnt_band
ORDER BY FIELD(loan_amnt_band, '<5k', '5-10k', '10-15k', '15-20k', '20k+');

-- ------------------------------------------------------------
-- Q6. RISK vs INTEREST RATE  (LC prices risk: higher rate -> higher default)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN int_rate < 8  THEN '1. <8%'
        WHEN int_rate < 11 THEN '2. 8-11%'
        WHEN int_rate < 14 THEN '3. 11-14%'
        WHEN int_rate < 17 THEN '4. 14-17%'
        ELSE                    '5. 17%+'
    END                                   AS int_rate_band,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY int_rate_band
ORDER BY int_rate_band;

-- ------------------------------------------------------------
-- Q7. RISK vs DTI (debt-to-income)  (more existing debt -> more risk?)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN dti < 10 THEN '1. <10'
        WHEN dti < 15 THEN '2. 10-15'
        WHEN dti < 20 THEN '3. 15-20'
        WHEN dti < 25 THEN '4. 20-25'
        ELSE             '5. 25+'
    END                                   AS dti_band,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY dti_band
ORDER BY dti_band;

-- ------------------------------------------------------------
-- Q8. RISK vs HOME OWNERSHIP
-- ------------------------------------------------------------
SELECT
    home_ownership,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY home_ownership
ORDER BY default_rate_pct DESC;

-- ------------------------------------------------------------
-- Q9. RISK vs TERM  (36 vs 60 months)
-- ------------------------------------------------------------
SELECT
    term_months,
    COUNT(*)                              AS loans,
    ROUND(AVG(is_default) * 100, 2)       AS default_rate_pct
FROM loans
GROUP BY term_months
ORDER BY term_months;
