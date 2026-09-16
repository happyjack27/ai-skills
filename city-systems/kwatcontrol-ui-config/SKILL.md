---
name: kwatcontrol-ui-config
description: 'SQL Server KWATControl database: UI configuration and rendering control across all MSSQL-based web apps. Use for editing APP_TABLES, APP_TABLE_COLUMNS, APP_DROPDOWNS, APP_REPORTS, APP_SIDEBAR, APP_GRANTS, APP_ENHANCEMENTS, and other UI control tables to manage how the web UI renders tables, fields, reports, permissions, and navigation for all applications (KWAT, DPW, HHMP, etc.). Includes patterns for adding/removing fields, configuring dropdowns, managing access, and updating sidebar navigation.'
---

# KWATControl Database - UI Configuration & Rendering

## Purpose

Help an AI edit and manage KWATControl tables that define how MSSQL web applications render tables,
columns, reports, dropdowns, navigation, and access controls.

## Scope

Included: `APP_TABLES`, `APP_TABLE_COLUMNS`, `APP_DROPDOWNS`, `APP_REPORTS`, `APP_GRANTS`,
`APP_SIDEBAR`, `APP_ENHANCEMENTS`, `APP_ACCESS_FILTERS`, `APP_BADGES`, and `APP_CATEGORY`.

Out of scope: application business logic, application source changes, and creation of the existing
KWATControl database schema.

## When to Use

- Add or remove a column from a web-app table view.
- Configure a dropdown, lookup, report, sidebar item, grant, or UI enhancement.
- Change labels, sorting, filtering, form layout, or field visibility.
- Understand how KWATClient, the Services servlet, and KWATControl work together.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The requested change is metadata or DML in the KWATControl SQL Server configuration database.
- The goal is to change how an existing MSSQL web application renders or authorizes UI elements.

**Do not use this skill when:**

- The task changes application business logic, creates physical database schema, or implements
  Java/TypeScript behavior. Use the relevant application skill for that portion.
- Writing generic SQL queries or schema changes: use [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md).
- Working on servlet endpoints or REST-client framework behavior: use [`../kwat-services/SKILL.md`](../kwat-services/SKILL.md).

**Pair with:**

- [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md) for SQL design and verification.
- [`../mssql-dynamic-tables/SKILL.md`](../mssql-dynamic-tables/SKILL.md) when a physical dynamic table or generated CRUD procedure must change first.
- [`../kwat-services/SKILL.md`](../kwat-services/SKILL.md) when a UI metadata change is coupled to servlet behavior.

## Inputs Expected

| Input | Description | Example |
|---|---|---|
| Application | Application being configured | `KWAT`, `DPW_Citytime`, `HHMP` |
| Table | Target table, when applicable | `Project`, `Contractor`, `WorkOrder` |
| Operation | Requested metadata change | Add column, hide field, add dropdown |
| Details | Labels, types, visibility, roles, and ordering | `Visible=1`, `EditableByRoles=Admin,Manager` |

## Outputs Produced

- Change statements: scoped `INSERT`/`UPDATE` SQL for KWATControl.
- Verification queries: SQL proving the intended rows changed.
- Before/after summary: what changed, why, and what was tested.

## Read Only What You Need

- [`references/core-tables.md`](references/core-tables.md) - table and column meanings.
- [`references/workflows.md`](references/workflows.md) - operation-specific SQL procedures.
- [`references/architecture-flow.md`](references/architecture-flow.md) - metadata flow, caching, and rendering.
- [`references/cache-invalidation.md`](references/cache-invalidation.md) - changes not appearing after an update.
- [`examples/add-contractor-columns.md`](examples/add-contractor-columns.md) - complete column example.
- [`examples/dropdowns-and-lookups.md`](examples/dropdowns-and-lookups.md) - complete dropdown example.

## Ground Truth Projects

Consult source projects when metadata behavior is unclear:

| Project | Use for |
|---|---|
| `KWATDocumentation/` | Architecture, load order, conventions, RLS, reports, and templates |
| `KWATClient/` | Frontend metadata consumption, widgets, and rendering |
| `KWATControlMSSQL/` | Metadata assembly, caching, and permission filtering |
| `itmdutil/` | CoreServices3 persistence and SQUID calls |

This skill documents what to change; source code determines how the application consumes it.

## Safety and Quality Rules

- Never delete from KWATControl without a backup; set `Active = 0` first when possible.
- Always filter by the correct `ApplicationID`; an unscoped query can affect another application.
- Resolve actual `TableID`, `ColumnID`, `ReportID`, and role IDs before writing DML.
- Update `DisplayName` with `ColumnName` unless automatic `HUMAN_NAME` generation is intentional.
- Use semantic types such as `email`, `phone`, `address google`, `date`, and `textarea` when supported.
- For file attachments, use `FK_ID` data type `attachments` and verify the parent-key mapping.
- Test in non-production first, document the reason, and verify the UI after every change.
- Check dependent dropdowns, grants, caches, and generated CRUD procedures before finalizing.

## Validation Checklist

- [ ] Correct `ApplicationID` and object IDs retrieved.
- [ ] INSERT/UPDATE syntax is scoped and verified.
- [ ] `Active`, visibility, editability, and ordering values are intentional.
- [ ] Dropdown source matches an existing category.
- [ ] Grants do not lock out intended users.
- [ ] Verification query returns expected rows.
- [ ] A representative UI test confirms the change.

## Related Skills

- [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md) - general SQL.
- [`../mssql-dynamic-tables/SKILL.md`](../mssql-dynamic-tables/SKILL.md) - generated CRUD and dynamic table changes.
- [`../../development-tools/java/SKILL.md`](../../development-tools/java/SKILL.md) - application code that reads KWATControl at runtime.
