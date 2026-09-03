# Example: Aggregation with GROUP BY and HAVING

## Scenario

Find all departments with more than 5 employees hired in the last year.

**Table:** `employees(id, name, department, hire_date)`

---

## Query (ANSI SQL / PostgreSQL)

```sql
SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY department
HAVING COUNT(*) > 5
ORDER BY employee_count DESC;
```

## Query (SQL Server T-SQL)

```sql
SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
WHERE hire_date >= DATEADD(year, -1, GETDATE())
GROUP BY department
HAVING COUNT(*) > 5
ORDER BY employee_count DESC;
```

## Notes

- `WHERE` filters rows **before** grouping; `HAVING` filters **after**.
- Always list every non-aggregate `SELECT` column in `GROUP BY`.
- Use `COUNT(*)` to count rows; use `COUNT(column)` to count non-null values.
