# Example: VLOOKUP vs XLOOKUP

## Scenario

Look up an employee's department from a reference table.

**Reference table (Sheet2, A:B):**

| EmployeeID | Department |
|---|---|
| 101 | Engineering |
| 102 | Marketing |

**Target cell:** `C2` on Sheet1, where `A2` contains an EmployeeID.

---

## VLOOKUP (Excel 2016 and earlier compatible)

```excel
=VLOOKUP(A2, Sheet2!$A:$B, 2, FALSE)
```

- `A2` — lookup value
- `Sheet2!$A:$B` — table range (locked with `$`)
- `2` — return column index
- `FALSE` — exact match

**Limitation:** breaks if a column is inserted before the return column.

---

## XLOOKUP (Excel 2019+ / Microsoft 365)

```excel
=XLOOKUP(A2, Sheet2!$A:$A, Sheet2!$B:$B, "Not found")
```

- Lookup and return arrays are separate — immune to column insertion.
- Fourth argument provides a fallback instead of `#N/A`.

---

## Recommendation

Use `XLOOKUP` if the Excel version supports it. Fall back to `INDEX/MATCH` for older versions.

```excel
=IFERROR(INDEX(Sheet2!$B:$B, MATCH(A2, Sheet2!$A:$A, 0)), "Not found")
```
