#!/usr/bin/env python3
"""
HW3 Data Quality checks A--M for page_blocks_dirty.csv

Constraints:
- Use only: csv, sys, math
- Output format: first line is the count, remaining lines are identities
  - Feature checks (A–F): identities are column names (one per line)
  - Case checks (G–M): identities are row numbers (file line numbers; header is line 1)
"""

import csv
import sys
from math import sqrt

MISSING = "?"

# ---------------------------
# basic stats (no packages)
# ---------------------------

def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0

def sd(xs):
    if not xs:
        return 0.0
    mu = mean(xs)
    return sqrt(sum((x - mu) ** 2 for x in xs) / len(xs))

def pearson(xs, ys):
    mx, my = mean(xs), mean(ys)
    num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    dx = sum((x - mx) ** 2 for x in xs)
    dy = sum((y - my) ** 2 for y in ys)
    if dx == 0 or dy == 0:
        return 0.0
    return num / sqrt(dx * dy)

# ---------------------------
# IO helpers
# ---------------------------

def load_rows(path):
    with open(path, newline="") as f:
        rdr = csv.DictReader(f)
        headers = rdr.fieldnames[:] if rdr.fieldnames else []
        rows = list(rdr)
    return headers, rows

def try_float(s):
    try:
        return float(s)
    except Exception:
        return None

def numeric_columns(headers):
    """Treat all columns except class! as numeric candidates."""
    return [h for h in headers if h != "class!"]

def col_values(rows, col):
    return [r[col] for r in rows]

def print_feature_result(cols):
    cols = sorted(set(cols))
    print(len(cols))
    for c in cols:
        print(c)

def print_case_result(rownums):
    rownums = sorted(set(rownums))
    print(len(rownums))
    for i in rownums:
        print(i)

# ---------------------------
# Domain knowledge checks
# ---------------------------

POSITIVE_COLS = {
    "HEIGHT", "LENGHT", "WIDTH", "AREA",
    "BLACKPIX", "BLACKAND", "WB_TRANS", "MEAN_TR"
}

def violates_referential(r):
    """
    Return list of violated referential constraints for row r.
    Skips if any needed field is missing (caller may skip row entirely).
    """
    needed = ["HEIGHT", "LENGHT", "AREA", "ECCEN", "P_BLACK", "P_AND", "BLACKPIX", "BLACKAND"]
    if any(r.get(c, MISSING) == MISSING for c in needed):
        return []  # caller can treat as "skip"
    h = try_float(r["HEIGHT"])
    l = try_float(r["LENGHT"])
    a = try_float(r["AREA"])
    e = try_float(r["ECCEN"])
    pb = try_float(r["P_BLACK"])
    pa = try_float(r["P_AND"])
    bpx = try_float(r["BLACKPIX"])
    ba = try_float(r["BLACKAND"])
    if None in (h, l, a, e, pb, pa, bpx, ba):
        return []

    bad = []

    # AREA = HEIGHT * LENGHT (exact)
    if a != h * l:
        bad.append("AREA=H*L")

    # ECCEN = LENGHT / HEIGHT (tolerance 0.01)
    if h > 0 and abs(e - (l / h)) > 0.01:
        bad.append("ECCEN=L/H")

    # P_BLACK = BLACKPIX / AREA (tolerance 0.001)
    if a > 0 and abs(pb - (bpx / a)) > 0.001:
        bad.append("P_BLACK=BLACKPIX/AREA")

    # P_AND = BLACKAND / AREA (tolerance 0.001)
    if a > 0 and abs(pa - (ba / a)) > 0.001:
        bad.append("P_AND=BLACKAND/AREA")

    return bad

def violates_plausibility(r):
    """
    Return list of (column_name) involved in plausibility violations for row r.
    Missing values are ignored here (missingness handled by S2).
    """
    bad_cols = set()

    # > 0 constraints
    for c in POSITIVE_COLS:
        v = r.get(c, MISSING)
        if v == MISSING:
            continue
        x = try_float(v)
        if x is None or x <= 0:
            bad_cols.add(c)

    # proportions in [0,1]
    for c in ("P_BLACK", "P_AND"):
        v = r.get(c, MISSING)
        if v == MISSING:
            continue
        x = try_float(v)
        if x is None or x < 0 or x > 1:
            bad_cols.add(c)

    # ECCEN > 0
    v = r.get("ECCEN", MISSING)
    if v != MISSING:
        x = try_float(v)
        if x is None or x <= 0:
            bad_cols.add("ECCEN")

    # class! in {1..5}
    v = r.get("class!", MISSING)
    if v != MISSING:
        if v not in ("1", "2", "3", "4", "5"):
            bad_cols.add("class!")

    # BLACKPIX <= BLACKAND
    v1 = r.get("BLACKPIX", MISSING)
    v2 = r.get("BLACKAND", MISSING)
    if v1 != MISSING and v2 != MISSING:
        x1 = try_float(v1)
        x2 = try_float(v2)
        if x1 is None or x2 is None or x1 > x2:
            bad_cols.add("BLACKPIX")
            bad_cols.add("BLACKAND")

    return sorted(bad_cols)

# ---------------------------
# Column statistics caches
# ---------------------------

def compute_col_stats(rows, cols):
    """
    For each numeric col, compute mean/sd over non-missing parseable floats.
    Returns dict col -> (mu, sigma)
    """
    stats = {}
    for c in cols:
        xs = []
        for r in rows:
            v = r.get(c, MISSING)
            if v == MISSING:
                continue
            x = try_float(v)
            if x is None:
                continue
            xs.append(x)
        mu = mean(xs) if xs else 0.0
        sigma = sd(xs) if xs else 0.0
        stats[c] = (mu, sigma)
    return stats

def compute_class_stats(rows, cols):
    """
    For each class label, compute per-col mean/sd over that class's rows.
    Returns dict cls -> dict col -> (mu, sigma)
    """
    by_class = {}
    for r in rows:
        cls = r.get("class!", MISSING)
        if cls == MISSING:
            continue
        by_class.setdefault(cls, []).append(r)

    out = {}
    for cls, rlist in by_class.items():
        out[cls] = compute_col_stats(rlist, cols)
    return out

# ---------------------------
# A--M checks
# ---------------------------

def check_A(headers, rows):
    """Identical features: columns with identical values for every row."""
    sig_to_cols = {}
    for c in headers:
        if c == "":  # defensive
            continue
        sig = tuple(r.get(c, "") for r in rows)
        sig_to_cols.setdefault(sig, []).append(c)

    bad = []
    for cols in sig_to_cols.values():
        if len(cols) > 1:
            bad.extend(cols)
    print_feature_result(bad)

def check_B(headers, rows):
    """Correlated features: numeric pairs with |r| > 0.95 (report involved columns)."""
    cols = numeric_columns(headers)
    involved = set()

    # build float columns once (with None for missing/non-numeric)
    col_data = {}
    for c in cols:
        xs = []
        for r in rows:
            v = r.get(c, MISSING)
            x = None
            if v != MISSING:
                x = try_float(v)
            xs.append(x)
        col_data[c] = xs

    n = len(cols)
    for i in range(n):
        for j in range(i + 1, n):
            c1, c2 = cols[i], cols[j]
            xs, ys = [], []
            for a, b in zip(col_data[c1], col_data[c2]):
                if a is None or b is None:
                    continue
                xs.append(a)
                ys.append(b)
            if len(xs) < 2:
                continue
            r = pearson(xs, ys)
            if abs(r) > 0.95:
                involved.add(c1)
                involved.add(c2)

    print_feature_result(involved)

def check_C(headers, rows):
    """Outlier features: any value beyond mu ± 3 sigma (report columns)."""
    cols = numeric_columns(headers)
    stats = compute_col_stats(rows, cols)
    bad_cols = set()

    for c in cols:
        mu, sigma = stats[c]
        if sigma == 0:
            continue
        lo, hi = mu - 3 * sigma, mu + 3 * sigma
        for r in rows:
            v = r.get(c, MISSING)
            if v == MISSING:
                continue
            x = try_float(v)
            if x is None:
                continue
            if x < lo or x > hi:
                bad_cols.add(c)
                break

    print_feature_result(bad_cols)

def check_D(headers, rows):
    """Features with conflicting values: columns involved in any violated referential constraint."""
    bad_cols = set()

    for r in rows:
        bad = violates_referential(r)
        if not bad:
            continue
        for which in bad:
            if which == "AREA=H*L":
                bad_cols.update(["AREA", "HEIGHT", "LENGHT"])
            elif which == "ECCEN=L/H":
                bad_cols.update(["ECCEN", "LENGHT", "HEIGHT"])
            elif which == "P_BLACK=BLACKPIX/AREA":
                bad_cols.update(["P_BLACK", "BLACKPIX", "AREA"])
            elif which == "P_AND=BLACKAND/AREA":
                bad_cols.update(["P_AND", "BLACKAND", "AREA"])

    print_feature_result(bad_cols)

def check_E(headers, rows):
    """Features with implausible values: columns with any plausibility violation."""
    bad_cols = set()
    for r in rows:
        bad_cols.update(violates_plausibility(r))
    print_feature_result(bad_cols)

def check_F(_headers, _rows, deps_cols):
    """Union of A–E (handled by Makefile)."""
    print_feature_result(deps_cols)

def check_G(headers, rows):
    """Outlier cases: any numeric value beyond global mu ± 3 sigma (report row numbers)."""
    cols = numeric_columns(headers)
    stats = compute_col_stats(rows, cols)

    bad_rows = set()
    for idx, r in enumerate(rows):
        rowno = idx + 2
        for c in cols:
            mu, sigma = stats[c]
            if sigma == 0:
                continue
            v = r.get(c, MISSING)
            if v == MISSING:
                continue
            x = try_float(v)
            if x is None:
                continue
            if abs(x - mu) > 3 * sigma:
                bad_rows.add(rowno)
                break

    print_case_result(bad_rows)

def check_H(headers, rows):
    """Inconsistent cases: identical on all non-class fields but different class!."""
    key_to_class = {}
    key_to_rows = {}
    bad_rows = set()

    nonclass = [h for h in headers if h != "class!"]

    for idx, r in enumerate(rows):
        rowno = idx + 2
        key = tuple(r.get(c, "") for c in nonclass)
        cls = r.get("class!", "")
        key_to_rows.setdefault(key, []).append(rowno)
        if key not in key_to_class:
            key_to_class[key] = cls
        else:
            if key_to_class[key] != cls:
                # mark all rows with this key as bad
                for rn in key_to_rows[key]:
                    bad_rows.add(rn)

    print_case_result(bad_rows)

def check_I(headers, rows):
    """Class-conditional outlier cases: within each class, any numeric value beyond class mu ± 3 sigma."""
    cols = numeric_columns(headers)
    stats_by_class = compute_class_stats(rows, cols)

    bad_rows = set()
    for idx, r in enumerate(rows):
        rowno = idx + 2
        cls = r.get("class!", MISSING)
        if cls == MISSING or cls not in stats_by_class:
            continue
        cstats = stats_by_class[cls]
        for c in cols:
            mu, sigma = cstats.get(c, (0.0, 0.0))
            if sigma == 0:
                continue
            v = r.get(c, MISSING)
            if v == MISSING:
                continue
            x = try_float(v)
            if x is None:
                continue
            if abs(x - mu) > 3 * sigma:
                bad_rows.add(rowno)
                break

    print_case_result(bad_rows)

def check_J(headers, rows):
    """Cases with conflicting values: violate referential integrity (skip rows with ? in involved fields)."""
    bad_rows = []
    for idx, r in enumerate(rows):
        rowno = idx + 2
        bad = violates_referential(r)
        if bad:  # non-empty means we evaluated and found a violation
            bad_rows.append(rowno)
    print_case_result(bad_rows)

def check_K(headers, rows):
    """Cases with implausible values: any plausibility violation (ignore missing fields for that check)."""
    bad_rows = set()
    for idx, r in enumerate(rows):
        rowno = idx + 2
        if violates_plausibility(r):
            bad_rows.add(rowno)
    print_case_result(bad_rows)

def check_L(_headers, _rows, deps_rows):
    """Union of G–K (handled by Makefile)."""
    print_case_result(deps_rows)

def check_M(_headers, _rows, deps_rows):
    """Same as L here (handled by Makefile)."""
    print_case_result(deps_rows)

# ---------------------------
# Dispatch
# ---------------------------

def main():
    if len(sys.argv) != 3:
        print("usage: python3 checks.py <A|B|C|D|E|G|H|I|J|K> <csvfile>", file=sys.stderr)
        sys.exit(2)

    target = sys.argv[1].strip().upper()
    path = sys.argv[2]

    headers, rows = load_rows(path)

    if target == "A":
        check_A(headers, rows)
    elif target == "B":
        check_B(headers, rows)
    elif target == "C":
        check_C(headers, rows)
    elif target == "D":
        check_D(headers, rows)
    elif target == "E":
        check_E(headers, rows)
    elif target == "G":
        check_G(headers, rows)
    elif target == "H":
        check_H(headers, rows)
    elif target == "I":
        check_I(headers, rows)
    elif target == "J":
        check_J(headers, rows)
    elif target == "K":
        check_K(headers, rows)
    else:
        # F, L, M are unions done by Makefile; checks.py doesn't need to run them.
        print(f"unknown/unsupported target '{target}' (use A,B,C,D,E,G,H,I,J,K)", file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
