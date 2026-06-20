"""
clean_loans.py  —  Phase 2: CLEAN
Credit Risk Predictor portfolio project.

Reads the raw LendingClub file (loan.csv) and writes an analysis-ready file
(loans_clean.csv) with ~25 carefully chosen columns, fixed dtypes, and a
0/1 default target.

The raw loan.csv is NEVER modified. Every cleaning decision is commented and
also printed to the console so you can read what happened.

Run:  python3 clean_loans.py
"""

import pandas as pd
import numpy as np

RAW = "loan.csv"
OUT = "loans_clean.csv"

print("=" * 70)
print("PHASE 2: CLEANING loan.csv")
print("=" * 70)

df = pd.read_csv(RAW, low_memory=False)
print(f"Loaded raw file: {df.shape[0]:,} rows x {df.shape[1]} columns")

# ---------------------------------------------------------------------------
# DECISION 1: Keep only the columns we actually need for credit-risk analysis.
# This drops the 54 fully-empty columns, the 3 mostly-empty ones, free-text /
# identifier noise (url, desc, zip_code, emp_title, title), AND "leaky"
# post-outcome columns (total_pymnt, recoveries, etc.) that would give away
# the answer. We keep loan terms, borrower attributes, dates, and the target.
# ---------------------------------------------------------------------------
keep = [
    # identifier
    "id",
    # loan terms
    "loan_amnt", "term", "int_rate", "installment", "grade", "sub_grade", "purpose",
    # borrower attributes
    "emp_length", "home_ownership", "annual_inc", "verification_status",
    "dti", "addr_state", "pub_rec", "delinq_2yrs", "revol_util",
    "open_acc", "total_acc", "pub_rec_bankruptcies",
    # dates
    "issue_d", "earliest_cr_line",
    # target
    "loan_status",
]
df = df[keep].copy()
print(f"DECISION 1: Kept {len(keep)} columns (dropped the other ~87 incl. empty & leaky cols).")

# ---------------------------------------------------------------------------
# DECISION 2: Drop "Current" loans. Their outcome isn't decided yet, so they
# can't be labelled good/bad. We analyse only finished loans.
# ---------------------------------------------------------------------------
before = len(df)
df = df[df["loan_status"].isin(["Fully Paid", "Charged Off"])].copy()
print(f"DECISION 2: Dropped 'Current' loans -> {before:,} -> {len(df):,} rows.")

# ---------------------------------------------------------------------------
# DECISION 3: Build the 0/1 target. Charged Off = default (1), Fully Paid = 0.
# ---------------------------------------------------------------------------
df["is_default"] = (df["loan_status"] == "Charged Off").astype(int)
print(f"DECISION 3: Created is_default. Default rate = {df['is_default'].mean():.4f} "
      f"({df['is_default'].sum():,} of {len(df):,}).")

# ---------------------------------------------------------------------------
# DECISION 4: Fix messy text-formatted numbers.
#   int_rate   "10.65%" -> 10.65
#   revol_util "83.70%" -> 83.70
#   term       "36 months" -> 36 (int)
# ---------------------------------------------------------------------------
df["int_rate"] = df["int_rate"].str.replace("%", "", regex=False).astype(float)
df["revol_util"] = (df["revol_util"].str.replace("%", "", regex=False)
                    .replace("", np.nan).astype(float))
df["term_months"] = df["term"].str.extract(r"(\d+)").astype(int)
df = df.drop(columns=["term"])
print("DECISION 4: int_rate & revol_util -> numeric; term -> term_months (int).")

# ---------------------------------------------------------------------------
# DECISION 5: emp_length text -> integer years (0..10).
#   "< 1 year" -> 0, "10+ years" -> 10, "N years" -> N. Missing stays NULL.
# ---------------------------------------------------------------------------
def parse_emp(x):
    if pd.isna(x):
        return np.nan
    if "<" in x:
        return 0
    if "10+" in x:
        return 10
    return int(x.split()[0])

df["emp_length_years"] = df["emp_length"].apply(parse_emp)
df = df.drop(columns=["emp_length"])
n_emp_null = df["emp_length_years"].isna().sum()
print(f"DECISION 5: emp_length -> emp_length_years (int). {n_emp_null:,} left NULL (unknown).")

# ---------------------------------------------------------------------------
# DECISION 6: Dates. "Dec-11" -> 2011-12-01.
# issue_d years are 07-11 (all 2000s). earliest_cr_line has 2-digit years that
# span decades; since every loan was issued 2007-2011, any credit line must be
# in the past: years 00-20 -> 2000s, 21-99 -> 1900s.
# ---------------------------------------------------------------------------
df["issue_d"] = pd.to_datetime(df["issue_d"], format="%b-%y")

def parse_cr_line(x):
    if pd.isna(x):
        return pd.NaT
    mon, yy = x.split("-")
    yy = int(yy)
    year = 2000 + yy if yy <= 20 else 1900 + yy
    return pd.to_datetime(f"{mon}-{year}", format="%b-%Y")

df["earliest_cr_line"] = df["earliest_cr_line"].apply(parse_cr_line)
print("DECISION 6: issue_d & earliest_cr_line -> real dates (century fixed).")

# ---------------------------------------------------------------------------
# DECISION 7: Standardize categories.
#   home_ownership: NONE (3 rows) folded into OTHER; keep RENT/MORTGAGE/OWN.
# ---------------------------------------------------------------------------
df["home_ownership"] = df["home_ownership"].replace({"NONE": "OTHER"})
print("DECISION 7: home_ownership 'NONE' folded into 'OTHER'.")

# ---------------------------------------------------------------------------
# DECISION 8: Handle remaining missing values.
#   pub_rec_bankruptcies: NaN -> 0 (no record reported = none).
#   revol_util: small number of NaN -> leave NULL (genuinely unknown).
# ---------------------------------------------------------------------------
df["pub_rec_bankruptcies"] = df["pub_rec_bankruptcies"].fillna(0).astype(int)
print(f"DECISION 8: pub_rec_bankruptcies NaN -> 0. revol_util NULLs left as-is "
      f"({df['revol_util'].isna().sum():,}).")

# ---------------------------------------------------------------------------
# DECISION 9: Derived analysis helpers for Power BI (income & loan bands).
# ---------------------------------------------------------------------------
df["income_band"] = pd.cut(
    df["annual_inc"],
    bins=[0, 40000, 60000, 80000, 100000, np.inf],
    labels=["<40k", "40-60k", "60-80k", "80-100k", "100k+"],
)
df["loan_amnt_band"] = pd.cut(
    df["loan_amnt"],
    bins=[0, 5000, 10000, 15000, 20000, np.inf],
    labels=["<5k", "5-10k", "10-15k", "15-20k", "20k+"],
)
print("DECISION 9: Added income_band & loan_amnt_band for easy BI grouping.")

# ---------------------------------------------------------------------------
# Final column order & save.
# ---------------------------------------------------------------------------
final_cols = [
    "id",
    "loan_amnt", "loan_amnt_band", "term_months", "int_rate", "installment",
    "grade", "sub_grade", "purpose",
    "emp_length_years", "home_ownership", "annual_inc", "income_band",
    "verification_status", "dti", "addr_state",
    "pub_rec", "delinq_2yrs", "revol_util", "open_acc", "total_acc",
    "pub_rec_bankruptcies",
    "issue_d", "earliest_cr_line",
    "loan_status", "is_default",
]
df = df[final_cols]

df.to_csv(OUT, index=False)
print("=" * 70)
print(f"SAVED: {OUT}  ->  {df.shape[0]:,} rows x {df.shape[1]} columns")
print("=" * 70)
print("\nFinal dtypes:")
print(df.dtypes.to_string())
print("\nNull counts (should be tiny):")
print(df.isnull().sum()[df.isnull().sum() > 0].to_string() or "  none")
print("\nSAMPLE (5 rows):")
print(df.head(5).to_string(index=False))
