-- ============================================================
-- create_table.sql  —  Phase 3: BUILD DB
-- Creates the `loans` table inside Loan_Portfolio_Database.
-- Run this in PopSQL (connected to your local MySQL) BEFORE loading data.
-- Safe to re-run: it drops and recreates the table.
-- ============================================================

USE Loan_Portfolio_Database;

DROP TABLE IF EXISTS loans;

CREATE TABLE loans (
    -- identifier
    id                    BIGINT          NOT NULL,

    -- loan terms
    loan_amnt             INT             NOT NULL,
    loan_amnt_band        VARCHAR(10),
    term_months           SMALLINT        NOT NULL,
    int_rate              DECIMAL(5,2)    NOT NULL,   -- e.g. 10.65
    installment           DECIMAL(10,2)   NOT NULL,
    grade                 CHAR(1)         NOT NULL,
    sub_grade             VARCHAR(2)      NOT NULL,
    purpose               VARCHAR(30)     NOT NULL,

    -- borrower attributes
    emp_length_years      TINYINT         NULL,       -- 0..10, NULL = unknown
    home_ownership        VARCHAR(10)     NOT NULL,
    annual_inc            DECIMAL(12,2)   NOT NULL,
    income_band           VARCHAR(10),
    verification_status   VARCHAR(20)     NOT NULL,
    dti                   DECIMAL(6,2)    NOT NULL,
    addr_state            CHAR(2)         NOT NULL,
    pub_rec               INT             NOT NULL,
    delinq_2yrs           INT             NOT NULL,
    revol_util            DECIMAL(6,2)    NULL,       -- NULL = unknown
    open_acc              INT             NOT NULL,
    total_acc             INT             NOT NULL,
    pub_rec_bankruptcies  INT             NOT NULL,

    -- dates
    issue_d               DATE            NOT NULL,
    earliest_cr_line      DATE            NULL,

    -- target
    loan_status           VARCHAR(20)     NOT NULL,
    is_default            TINYINT         NOT NULL,   -- 1 = Charged Off, 0 = Fully Paid

    PRIMARY KEY (id)
);

-- Helpful indexes for the analysis queries in Phase 4
CREATE INDEX idx_loans_grade   ON loans (grade);
CREATE INDEX idx_loans_purpose ON loans (purpose);
CREATE INDEX idx_loans_default ON loans (is_default);
