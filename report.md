# REPORT — Data Quality Analysis of *page_blocks_dirty.csv*

## Summary

This analysis evaluated structural, statistical, and domain-logic data quality issues in the dataset using automated gawk and Python checks. Results show the dataset contains widespread quality problems affecting both features and cases, indicating it is not suitable for modeling without cleaning.

---

## Part 1 — Structural Issues (gawk)

* **Ragged rows (S1):** 0 — file structure is consistent.
* **Missing values (S2):** 24 rows affected; columns: `P_AND`, `MEAN_TR`.
* **Constant columns (S3):** `DATASET_ID` is constant → non-informative.
* **Invalid class labels (S4):** 4 rows.
* **Duplicate rows (S5):** 124 duplicate entries.

**Interpretation:** File formatting is clean, but redundancy and missing data are present. The constant column should be removed for analysis.

---

## Part 2 — Feature-Level Problems

* **Identical features (A):** `LENGHT`, `WIDTH`
* **Highly correlated (B):** 4 columns (`BLACKAND`, `BLACKPIX`, `LENGHT`, `WIDTH`)
* **Outlier columns (C):** 11 columns contain extreme values.
* **Formula violations (D):** 7 columns break derived relationships.
* **Implausible values (E):** 4 columns (`HEIGHT`, `P_AND`, `P_BLACK`, `class!`)
* **Total problem features (F):** **12**

**Interpretation:** Nearly all features exhibit at least one issue. Redundant or dependent variables dominate, and several violate domain constraints, indicating systemic generation or preprocessing errors.

---

## Part 3 — Case-Level Problems

* **Global outlier rows (G):** 508
* **Conflicting duplicate rows (H):** 55
* **Class-conditional outliers (I):** 449
* **Formula-violating rows (J):** 43
* **Implausible rows (K):** 16
* **Total problematic rows (L/M):** **753**

**Interpretation:** Over 13% of rows contain at least one quality issue, with outliers being the dominant problem.

---

## Key Findings

* Most common issue: statistical outliers.
* Most concerning issue: derived-feature inconsistencies (indicates broken data generation logic).
* Least reliable columns: `AREA`, `P_AND`, `P_BLACK`, and correlated dimension features.
* Dataset trustworthiness: **Not reliable for ML without cleaning**, because violations break mathematical consistency and distort distributions.

---

## Takeaway

**Even well-formatted datasets can be deeply flawed; automated validation checks are essential before any analysis or modeling.**
