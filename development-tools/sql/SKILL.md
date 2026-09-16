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

## Routing Boundaries

**Use this skill when:**

- The request is generic SQL, DDL, DML, or performance work without a stronger domain-specific workflow.

**Use a specialized skill instead when:**

- The work is DPW Oracle-to-SQL Server migration routing, cutover, or refresh: use [`../../dpw-migration/migration-operations/SKILL.md`](../../dpw-migration/migration-operations/SKILL.md).
- The work uses `development.DynamicFile` or `development.DynamicSQUID` for standardized file tables: use [`../../kwat-webapps/mssql-dynamic-tables/SKILL.md`](../../kwat-webapps/mssql-dynamic-tables/SKILL.md).
- The work configures KWATControl UI metadata: use [`../../kwat-webapps/kwatcontrol-ui-config/SKILL.md`](../../kwat-webapps/kwatcontrol-ui-config/SKILL.md).
- The work changes Accela record types, workflows, or event scripts: use the relevant skill under [`../../accela-platform/`](../../accela-platform/).

**Pair with:**

- A domain-specific skill when SQL is only one part of a migration, application, or metadata change.

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
2. Write the query with the formatting rules below.
3. Explain any non-obvious joins, window functions, or CTEs.
4. Suggest indexes if a performance issue is apparent.

## Quality Standards

- Keywords uppercase: `SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`.
- Keep clause keywords flush left: `FROM`, `JOIN`, `LEFT JOIN`, `ON 1 = 1`, and `WHERE 1 = 1`.
- Put each table name on its own line immediately below `FROM` or a `JOIN` clause.
- Use `ON 1 = 1` for multi-predicate joins, then indent each join predicate with tabs.
- Use `WHERE 1 = 1` for multi-predicate filters, then indent each filter predicate with tabs.
- Use tabs for SQL indentation; do not replace aligned predicate indentation with spaces.
- Put continuation expressions and predicates on separate lines, with one logical condition per line.
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

Read [`examples/sql-format.md`](examples/sql-format.md) for the required clause and indentation layout. See the other files in `examples/` for dialect and query-pattern examples.

## Related Skills

- [`../../shared/coding-standards.md`](../../shared/coding-standards.md)
