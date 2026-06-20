"""
load_to_mysql.py  —  Phase 3: BUILD DB (loader)
Loads loans_clean.csv into the `loans` table in Loan_Portfolio_Database.

WHY a Python loader (not LOAD DATA INFILE):
  MySQL's LOAD DATA INFILE is often blocked by the `secure_file_priv` setting
  and needs the file in a special folder. This script just connects and
  INSERTs in batches — it "just works" from anywhere on your machine.

BEFORE running:
  1) Run create_table.sql in PopSQL first (creates the empty `loans` table).
  2) Install the connector:   pip install mysql-connector-python
  3) Make sure loans_clean.csv is in the same folder as this script.

RUN:
  python load_to_mysql.py
It will ask for your MySQL root password (typed hidden). If root has NO
password, just press Enter.
"""

import csv
import getpass
import sys

try:
    import mysql.connector
except ImportError:
    sys.exit("Missing connector. Run:  pip install mysql-connector-python")

CSV_FILE = "loans_clean.csv"
DB_NAME = "Loan_Portfolio_Database"
BATCH = 1000

# Columns that may be empty in the CSV and must become SQL NULL (not "").
NULLABLE = {"emp_length_years", "revol_util", "earliest_cr_line",
            "loan_amnt_band", "income_band"}
# Integer columns (empty -> None, else int). Floats handled by MySQL directly.
INT_COLS = {"id", "loan_amnt", "term_months", "emp_length_years", "pub_rec",
            "delinq_2yrs", "open_acc", "total_acc", "pub_rec_bankruptcies",
            "is_default"}


def clean(col, val):
    """Convert a CSV string cell into the right Python value for MySQL."""
    if val == "" or val is None:
        return None
    if col in INT_COLS:
        # emp_length came through as e.g. "10.0"; handle float-looking ints.
        return int(float(val))
    return val


def main():
    pwd = getpass.getpass("MySQL root password (press Enter if none): ")

    print("Connecting to MySQL ...")
    conn = mysql.connector.connect(
        host="localhost", port=3306, user="root", password=pwd, database=DB_NAME
    )
    cur = conn.cursor()

    with open(CSV_FILE, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)

        placeholders = ", ".join(["%s"] * len(header))
        cols = ", ".join(f"`{c}`" for c in header)
        sql = f"INSERT INTO loans ({cols}) VALUES ({placeholders})"

        batch, total = [], 0
        for row in reader:
            batch.append([clean(header[i], row[i]) for i in range(len(header))])
            if len(batch) >= BATCH:
                cur.executemany(sql, batch)
                total += len(batch)
                batch = []
                print(f"  inserted {total:,} rows ...")
        if batch:
            cur.executemany(sql, batch)
            total += len(batch)

    conn.commit()

    cur.execute("SELECT COUNT(*) FROM loans")
    db_count = cur.fetchone()[0]
    cur.close()
    conn.close()

    print("-" * 50)
    print(f"DONE. Inserted {total:,} rows. Table now has {db_count:,} rows.")
    print("Expected: 38,577 rows." if db_count == 38577
          else "WARNING: row count differs from expected 38,577 — tell Claude.")


if __name__ == "__main__":
    main()
