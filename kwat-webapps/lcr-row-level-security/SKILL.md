---
name: lcr-row-level-security
description: 'LaborComplianceReporting row-level security (RLS) on SQL Server: RLS_<Table> views, VW_User/VW_UserAttribute attribute-based rights, _RLS_User/_RLS_UserType and per-row CRUD flags, generated enforcement procedures and triggers, KWAT SELECT_FROM configuration, and performance-safe changes to RLS-backed views or exports. Use before modifying LCR data sources, RLS views, export views, CRUD procedures, or queries that join LCR protected tables.'
---

# Labor Compliance Reporting Row-Level Security

## Purpose

Safely understand and modify LCR's database-enforced row-level security without bypassing rights,
changing CRUD semantics, or multiplying its rights matrix.

## Scope

Included: LCR `RLS_<Table>` views, `VW_User` and `VW_UserAttribute`, `_RLS_*` columns, generated
RLS procedures/triggers, KWAT `SELECT_FROM`, and performance implications for LCR export views.

Out of scope: generic SQL Server security policies, application authentication, and non-LCR
application permission design.

## When to Use

- Changing an LCR `RLS_<Table>` view, protected source table, or an `RLS_` stored procedure/trigger.
- Adding a table/view that KWAT reads through `SELECT_FROM`.
- Adding joins or export views for LCR data.
- Investigating why an LCR user can see, edit, delete, or insert a row.
- Diagnosing performance of an `RLS_` view or query consuming one.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The task depends on LCR's per-user, per-row rights exposed by `RLS_<Table>` views.
- A SQL/view/export change could alter the rows or CRUD flags visible to an LCR user.

**Do not use this skill when:**

- The work only changes generic KWATControl UI metadata: use `kwatcontrol-ui-config`.
- The work is ordinary SQL with no LCR RLS table/view in the path: use `sql`.
- The work is shared servlet framework behavior with no RLS contract change: use `kwat-services`.

**Pair with:**

- `kwat-services` for how `CoreServices3` passes authenticated users to data operations.
- `kwatcontrol-ui-config` for `APP_TABLES.SELECT_FROM` and app metadata.
- `sql` for query plans, view DDL, and validation.

## Verified LCR Model

- LCR's `Services` servlet extends `CoreServices3`; do not assume the older `CoreServicesRLS`
  class is the active application base class.
- Each protected `dbo.RLS_<Table>` view returns source fields plus:
  `_RLS_User`, `_RLS_UserType`, `_RLS_Select`, `_RLS_Insert`, `_RLS_Update`, and `_RLS_Delete`.
- `VW_UserAttribute` provides attribute-based rights; `VW_User` supplies broader/default branches.
  A view can expose the same source row once per entitled user and user type.
- Generated `SelectRLS_<Table>ByPK` and `DeleteRLS_<Table>ByPK` procedures accept
  `@_RLS_User` and `@_RLS_UserType`. Generated write triggers check the acting audit user and
  corresponding `_RLS_*` permission against the RLS view.
- The live LCR database has real foreign-key constraints. Use them for relationship discovery;
  do not infer every relationship from a column name alone.

## Data-Source Ordering

For a protected table with a derived source, layer views as:

```text
base tables -> <Table>_Export (optional label joins) -> RLS_<Table> -> KWAT SELECT_FROM
```

`RLS_<Table>` must read the derived source, not bypass it to the base table. The RLS view must
still project the original primary key and all `_RLS_*` columns. A null primary key is interpreted
by the client as a createable row.

## Workflow

1. Identify the KWAT `APP_TABLES.SELECT_FROM` source and whether it is an `RLS_` view.
2. Read the actual `RLS_<Table>` definition and the consuming generated procedures/triggers.
3. Trace every branch to its source, `VW_User`/`VW_UserAttribute` rights set, user type, and CRUD
   flags before changing the query.
4. When adding a derived/export view, place it below the `RLS_` view and preserve source primary
   keys and row cardinality.
5. Verify representative users and both user types for select and relevant write behavior.
6. Measure the RLS view and the caller query on a warm cache before and after the change.

## Performance Rules

- Treat `base CROSS JOIN VW_User CROSS JOIN attributes` patterns as potential rights-matrix
  expansion; measure `COUNT_BIG(*)` before optimizing callers.
- Prefer joins that let `_RLS_User` and `_RLS_UserType` predicates push into rights branches.
- Avoid correlated `CROSS APPLY (SELECT DISTINCT ...)` rights lookups when a join can preserve
  predicate pushdown.
- `LIKE` parameters can prevent UNION-branch contradiction elimination. Do not infer a good plan
  from a simple outer query alone.
- Any export label view must be joined before RLS applies; joining labels outside `RLS_<Table>` can
  expose data for rows that should have been filtered.

## Common Mistakes

- Pointing `SELECT_FROM` directly at `<Table>_Export` and bypassing `RLS_<Table>`.
- Editing a base table/view without preserving the RLS view's primary key and `_RLS_*` fields.
- Replacing an RLS `UNION` with `UNION ALL` without proving both result equivalence and duplicate
  rights semantics.
- Evaluating a performance change only on a cold cache or only for one user type.
- Treating `CoreServicesRLS` documentation as proof of LCR's current servlet inheritance.

## Validation Checklist

- [ ] Live `RLS_<Table>` definition and `APP_TABLES.SELECT_FROM` were inspected.
- [ ] Derived/export view remains below `RLS_<Table>` in the read path.
- [ ] `_RLS_User`, `_RLS_UserType`, and all required `_RLS_*` flags are preserved.
- [ ] Representative ADPlus and Citizen visibility was verified.
- [ ] Required insert/update/delete enforcement was tested or explicitly excluded from scope.
- [ ] Warm-cache performance was measured for the RLS view and consuming export/query.

## Source Material

- `KWATDocumentation/RowLevelSecurity/how_to.txt`
- `LaborComplianceReporting/RLS/`
- Live `sql-itmd` LaborComplianceReporting definitions

## Related Skills

- [`../kwat-services/SKILL.md`](../kwat-services/SKILL.md)
- [`../kwatcontrol-ui-config/SKILL.md`](../kwatcontrol-ui-config/SKILL.md)
- [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md)
- [`../../shared/coding-standards.md`](../../shared/coding-standards.md)
