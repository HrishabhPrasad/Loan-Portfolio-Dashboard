# Phase 5 — Power BI Dashboard (click-by-click)

This guide connects **Power BI Desktop** to your local MySQL database
`Loan_Portfolio_Database`, pulls in the views, and builds a clean credit-risk
dashboard.

---

## STEP 0 — One-time prerequisite (IMPORTANT, do this first)

Power BI cannot talk to MySQL until you install Oracle's free connector.
Without it, Power BI shows: *"please install the MySQL Connector/NET"*.

1. Go to: https://dev.mysql.com/downloads/connector/net/
2. Download **MySQL Connector/NET** (the `.msi` for Windows).
3. Run the installer → accept defaults → Finish.
4. **Close and reopen Power BI Desktop** so it detects the connector.

---

## STEP 1 — Connect Power BI to MySQL

1. Open **Power BI Desktop**.
2. Home ribbon → **Get Data** → **More...**
3. In the search box type **MySQL** → select **MySQL database** → **Connect**.
4. In the dialog:
   - **Server:** `localhost:3306`   (include the `:3306`)
   - **Database:** `Loan_Portfolio_Database`
   - Leave Data Connectivity mode = **Import** (default).
   - Click **OK**.
5. Credentials screen → choose **Database** on the left:
   - **User name:** `root`
   - **Password:** your MySQL password (blank if none)
   - Click **Connect**.
6. If a "encryption support" warning appears, click **OK** to continue.

---

## STEP 2 — Pick the views to load

In the **Navigator** window you'll see all tables/views. Tick ONLY:

- ☑ `vw_loans_enriched`   (the main detail table — one row per loan)
- ☑ `vw_risk_summary`     (small pre-aggregated helper)

Then click **Load**. (You do NOT need the raw `loans` table — the views
already contain everything, including risk_segment and the bands.)

---

## STEP 3 — Create measures (the numbers the cards/charts show)

A "measure" is a reusable calculation. Make these 5.

1. In the right-hand **Data** pane, right-click `vw_loans_enriched` →
   **New measure**. Type the formula, press Enter. Repeat for each.

```DAX
Total Loans = COUNTROWS(vw_loans_enriched)
```
```DAX
Total Defaults = SUM(vw_loans_enriched[is_default])
```
```DAX
Default Rate % = DIVIDE([Total Defaults], [Total Loans]) * 100
```
```DAX
Avg Loan Amount = AVERAGE(vw_loans_enriched[loan_amnt])
```
```DAX
Avg Interest Rate = AVERAGE(vw_loans_enriched[int_rate])
```

2. For **Default Rate %**: select it in the Data pane → **Measure tools**
   ribbon → set **Format = Decimal number**, **Decimal places = 1**.
   (Optional: rename shows as "14.6" meaning 14.6%.)

---

## STEP 4 — Build the dashboard

Work on the blank report canvas. For each visual: click the visual TYPE in
the **Visualizations** pane first, then drag fields into its wells.

### Row 1 — KPI cards (top of page)
Use the **Card** visual (the one labelled `123`). Make 3 cards:

| Card | Drag into "Fields" |
|------|--------------------|
| Total Loans | `Total Loans` |
| Default Rate % | `Default Rate %` |
| Avg Loan Amount | `Avg Loan Amount` |

Tip: click each card → Format (paint-roller) → turn on a title, increase
the font size of the value. Place the 3 cards side-by-side across the top.

### Visual 2 — Default rate by grade (Clustered column chart)
- Visual type: **Clustered column chart**
- **X-axis:** `grade`
- **Y-axis:** `Default Rate %`
- Story: clean staircase A→G. This is your headline chart.

### Visual 3 — Default rate by purpose (Clustered bar chart — horizontal)
- Visual type: **Clustered bar chart**
- **Y-axis:** `purpose`
- **X-axis:** `Default Rate %`
- Click the visual → top-right "..." → **Sort axis** → by `Default Rate %`
  → Descending. Story: `small_business` worst, `wedding`/`car` best.

### Visual 4 — Risk segment breakdown (Donut or Clustered column)
- Visual type: **Donut chart**
- **Legend:** `risk_segment`
- **Values:** `Total Loans`
- (Optional second copy with `Default Rate %` to show the 9/19/29% split.)

### Visual 5 — Risk vs interest rate (Line or column chart)
- Visual type: **Clustered column chart**
- **X-axis:** `int_rate_band`
- **Y-axis:** `Default Rate %`
- Story: default rises 5% -> 31% as rate rises.

### Slicers (interactivity)
- Visual type: **Slicer**. Add 1–2:
  - `risk_segment`  (lets viewers filter Low/Med/High)
  - `term_months`   (36 vs 60)
- Place them on the left or top.

---

## STEP 5 — Make it look professional

- **Title:** Insert → Text box → "Credit Risk Dashboard — LendingClub Loans".
- **Theme:** View ribbon → Themes → pick a clean one (e.g. "Executive").
- **Consistent colors:** use one accent color; make the risk donut use
  red=High, amber=Medium, green=Low (click legend → Format → Colors).
- **Align** visuals on a grid (Format → align). Leave whitespace.
- **Data labels:** turn on for the bar/column charts (Format → Data labels)
  so exact percentages show.
- **Tooltips:** hover already shows details; optionally add `Total Loans`
  to each chart's Tooltips well so viewers see sample size.

---

## STEP 6 — Save & export

- **File → Save** as `Credit_Risk_Dashboard.pbix` in the project folder.
- For your portfolio: **File → Export → Export to PDF** to get a shareable
  snapshot, and take a screenshot (PNG) for the README.

---

## Refreshing later
If you reload data into MySQL, just click **Home → Refresh** in Power BI to
pull the latest numbers through the views.
