---
name: sql
description: 'Use for writing, optimizing, or explaining SQL: queries, DDL/schema changes, stored procedures, views, indexes, and execution-plan/performance review across SQL Server (T-SQL), PostgreSQL, MySQL, SQLite, and Oracle.'
---

# SQL Skill

## Purpose

Help an AI write, optimize, and explain SQL queries and schema changes.

## Scope

- ANSI SQL plus common dialects: SQL Server (T-SQL), PostgreSQL, MySQL, SQLite, Oracle.
- DDL (CREATE, ALTER, DROP), DML (SELECT, INSERT, UPDATE, DELETE), stored procedures, views, indexes.
- Out of scope: NoSQL, ORM-generated queries (see relevant language skill folders).

## When to Use

- User needs a query, stored procedure, view, or schema change.
- User needs query optimization or an execution plan review.
- User needs data migration or transformation logic in SQL.

## Inputs Expected

| Input | Description |
|---|---|
| Schema | Table names, columns, data types, keys, sample data |
| Goal | What the query should return or accomplish |
| Dialect | SQL Server, PostgreSQL, MySQL, etc. |
| Performance constraints | Row counts, indexes available |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Query | SQL code block | Ready to execute |
| Schema change | DDL SQL block | Migration script |
| Explanation | Prose | How and why the query works |

## Workflow

1. Confirm the dialect and schema.
2. Write the query with clear formatting (one clause per line, uppercase keywords).
3. Explain any non-obvious joins, window functions, or CTEs.
4. Suggest indexes if a performance issue is apparent.

## Quality Standards

- Keywords uppercase: `SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`.
- Each clause on its own line; indent continuation lines 4 spaces.
- Use CTEs (`WITH`) over nested subqueries for readability.
- Always use explicit `JOIN` syntax — never implicit comma joins.
- Include a `WHERE` clause on UPDATE/DELETE; note when a full-table operation is intentional.
- Use parameterized queries in application code — never concatenate user input.

## Common Mistakes

- `SELECT *` in production code — always name columns.
- Missing `GROUP BY` columns when using aggregates.
- Using `!=` instead of `IS NOT NULL` for null checks.
- Forgetting that `NULL` comparisons require `IS NULL` / `IS NOT NULL`.

## Validation Checklist

- [ ] Query runs without syntax errors on stated dialect.
- [ ] Results verified against sample data.
- [ ] No `SELECT *` in final output.
- [ ] UPDATE/DELETE has a `WHERE` clause (or intentional omission is noted).
- [ ] User input is parameterized, not concatenated.

## Examples

See `examples/`.

## Related Skills

- [`../shared/coding-standards.md`](../shared/coding-standards.md)
