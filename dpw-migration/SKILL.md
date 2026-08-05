---
name: dpw-migration
description: 'Use for the City of Milwaukee DPW Oracle (DPWP) to SQL Server migration: reloading/refreshing a migrated table or database from live Oracle via syncTable/syncSequence/syncDatabase, deciding which SQL Server database a table/RMI method/servlet page should route to, looking up app-to-database mappings in the DatabaseMigration bookkeeping DB, blocking or auditing writes to already-migrated Oracle tables, diagnosing wrong-database routing bugs in MSSQL-converted RMI servers (GenericServer/RoutingChecker/DPWConnectionFactory), and any work under DPW_Includes_DataServer_MSSQL/sql/.'
---

# DPW Oracle → SQL Server Migration Skill

## Purpose

Help an AI work on the City of Milwaukee DPW migration of Oracle (`DPWP`) applications onto
per-application SQL Server databases: refreshing data, routing queries, and freezing the
Oracle originals after cutover.

## Scope

- **In scope:** the `DatabaseMigration` bookkeeping DB, the `syncTable`/`syncSequence`/`syncDatabase`
  refresh procedures, the Oracle-side `MIGRATIONS` freeze schema, RMI method → target-DB routing,
  and cutover sequencing.
- **Out of scope:** general SQL authoring (see [`../sql/SKILL.md`](../sql/SKILL.md)), Java servlet
  and RMI server code (see [`../java/SKILL.md`](../java/SKILL.md)), Accela specifics
  (see [`../accela/SKILL.md`](../accela/SKILL.md)).

## When to Use

- Reloading a migrated table or database from live Oracle before a production cutover.
- Deciding which SQL Server database a given table, RMI method, or app should point at.
- Looking up what an app touches, who its users are, or what belongs in a target database.
- Pointing a servlet page at SQL Server, or checking that a page is using the right environment.
- Blocking, auditing, or unblocking writes to Oracle tables that have already moved.
- Diagnosing "wrong database" bugs in the MSSQL-converted RMI servers.
- Any task touching `DPW_Includes_DataServer_MSSQL/sql/`.

## Inputs Expected

| Input | Description |
|---|---|
| Object name | Table, sequence, or app database, e.g. `ROADLIFE`, `RoadLife` |
| Direction | Oracle → SQL Server refresh, or Oracle-side freeze |
| Environment | `sql-treas` (migration/staging) or `sql-dpw3` (production) |
| Cutover state | Not yet migrated / migrated but Oracle still live / frozen |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Refresh command | T-SQL `EXEC` | Run against the target DB, not `DatabaseMigration` |
| Oracle DDL | PL/SQL script | Delivered as a file — no Oracle DDL path exists from the workstation |
| Routing answer | Prose + query | Which DB an object or RMI method belongs to |

## Environment

Reference files:

- [`references/environment.md`](references/environment.md) — servers, credentials, linked-server
  details, procedure signatures, and the full gotcha list.
- [`references/database-migration-db.md`](references/database-migration-db.md) — the
  `DatabaseMigration` bookkeeping database: schema layout, table groups, and ready-made queries
  for "what tables go in this database?", "which apps use it?", and "who are its main users?".
- [`references/servlet-routing.md`](references/servlet-routing.md) — how each servlet page picks
  its database, backend, and environment. Read before flipping any page to SQL Server.

The essentials:

| Fact | Value |
|---|---|
| Migration/staging SQL Server | `sql-treas` — full access, Oracle client installed |
| Production SQL Server | `sql-dpw3` — **not** sysadmin, **no Oracle provider** |
| Oracle source | 19c, database `DPWP`, all objects owned by schema `DPW` |
| Linked server | `DPWP` on `sql-treas` only — always via `OPENQUERY` |
| Bookkeeping | `DatabaseMigration` DB, schema `migration` (lowercase) |
| Oracle freeze schema | `MIGRATIONS` (uppercase, plural) |

## Workflow

### Refreshing data from Oracle

1. Connect to the **target** database on `sql-treas` — the procedures are deployed into every
   target DB and deliberately contain no `USE` statement.
2. Preview first: `EXEC syncTable @Object='ROADLIFE', @WhatIf=1` returns the generated batch
   without running it.
3. Run it. For a whole database, `EXEC syncDatabase` loops every table then syncs sequences once.
4. Check the returned log for skipped columns and row counts.

### Answering a placement or ownership question

1. Query `DatabaseMigration` on `sql-treas` — it is the authoritative source, not the code.
2. For an object, join `DatabaseObjects` → `DbObjectTargetDatabases` → `TargetDatabases`.
3. For an RMI method, use `migration.vRmiEndpointTargetDB`.
4. For app users, `LoginDPW.DPW.APP_FREQUENT_USERS` — filter out the blank `LOGIN_ID` rows. For a
   set of apps cutting over together, use the `IN (...)` + dedupe-by-person recipe in
   [`references/database-migration-db.md`](references/database-migration-db.md#who-actually-uses-an-app)
   to build the notification list, then send
   [`templates/cutover-notification-email.md`](templates/cutover-notification-email.md).

### Pointing a servlet page at SQL Server

Three separate switches must agree; see
[`references/servlet-routing.md`](references/servlet-routing.md) for the detail.

1. List **every** database the page touches via `migration.ServletTargetDatabases` — 28 servlets
   touch more than one, and one `USE_MSSQL` boolean flips all of them together.
2. Confirm each of those databases is migrated (`DbObjectTargetDatabases.migration_status`).
3. Confirm each is `DbEnvironment.PROD` in the `Database` enum if this is a production cutover.
   Anything left at `DEV` silently falls back to Oracle no matter what the page's flag says.
4. Flip the flag, redeploy, then check `migration.RoutingFallbackLog` for new rows.

### Freezing Oracle after cutover

1. Weeks ahead: `EXEC MIGRATIONS.BLOCK_PKG.AUDIT_DB('RoadLife')`, then read
   `MIGRATIONS.V_STILL_WRITING`. An empty result is the evidence that freezing breaks nothing.
2. Repoint any straggler the audit names.
3. At cutover: `EXEC MIGRATIONS.BLOCK_PKG.FREEZE_DB('RoadLife')`.
4. Reverse instantly with `UNFREEZE_DB` — freezing is a data change, not DDL.

## Quality Standards

- Refresh procedures run **in the target database**; never add a `USE` statement to them.
- Stage `OPENQUERY` results into a `#temp` **outside** the transaction to avoid MSDTC promotion.
- Leave PK and UNIQUE indexes enforcing during a load so bad Oracle data fails loudly.
- Only disable objects that are currently enabled, and restore them inside the same transaction.
- Deliver Oracle DDL as a reviewable file; it cannot be executed or tested from the workstation.
- Verify a claim against the database before asserting it — both servers hold surprises
  (see Common Mistakes).

## Common Mistakes

- **`DPWP` is both a linked server and a local database.** Three-part `DPWP.DPW.TBL` silently
  reads the *local* copy. Always `OPENQUERY([DPWP], '...')`.
- **Running Oracle queries against `sql-dpw3`.** The linked server exists there as a dead
  metadata stub with no provider — Msg 7403. Only `sql-treas` can reach Oracle.
- **Assuming Oracle identifiers are uppercase.** A schema created as `"migration"` is genuinely
  lowercase and needs quoting forever. Check with
  `SELECT USERNAME FROM ALL_USERS WHERE UPPER(USERNAME) = '...'`.
- **Mixing up `migration` and `MIGRATIONS`.** Lowercase `migration` is the SQL Server bookkeeping
  schema; uppercase `MIGRATIONS` is the Oracle freeze schema. A blind case-insensitive
  find/replace across both breaks one of them.
- **Forgetting the `ROWID` column.** Migrated tables carry a SQL-only
  `ROWID uniqueidentifier DEFAULT newid()` with no Oracle counterpart. Match columns by name.
- **`STRING_AGG` over `sys.*` across databases** fails on collation — append `COLLATE DATABASE_DEFAULT`.
- **`PRINT` cannot contain a subquery**, and truncates `nvarchar(max)` at 4000 characters.
- **Presence in `DPWP` does not mean a table was not migrated** — staging copies persist during
  the transition. Check `migration.DbObjectTargetDatabases`.
- **An invalid Oracle package blocks every table carrying its trigger.** After touching
  `BLOCK_PKG`, re-check `USER_OBJECTS` for `STATUS <> 'VALID'`.

## Validation Checklist

- [ ] Connected to the correct database, and the correct server (`sql-treas` for anything Oracle).
- [ ] Oracle access goes through `OPENQUERY`, not three-part naming.
- [ ] `@WhatIf=1` reviewed before a real reload of a production-bound table.
- [ ] Row counts compared before and after; skipped columns explained.
- [ ] Triggers, constraints, and indexes confirmed re-enabled after a load.
- [ ] Before any freeze: audit run, `V_STILL_WRITING` empty, shared tables excluded.
- [ ] No Oracle object left `INVALID`.

## Key Files

| Path | Purpose |
|---|---|
| `DPW_Includes_DataServer_MSSQL/sql/create_syncTable.sql` | Reload one table from Oracle |
| `DPW_Includes_DataServer_MSSQL/sql/create_syncSequence.sql` | Reset sequences to Oracle's `LAST_NUMBER` |
| `DPW_Includes_DataServer_MSSQL/sql/create_syncDatabase.sql` | Whole-database wrapper |
| `DPW_Includes_DataServer_MSSQL/sql/oracle/create_migration_schema.sql` | `MIGRATIONS` tables and views |
| `DPW_Includes_DataServer_MSSQL/sql/oracle/block_pkg.sql` | `MIGRATIONS.BLOCK_PKG` |
| `DPW_Includes_DataServer_MSSQL/sql/oracle/seed_migrated_tables.sql` | Generated control-table rows |
| `DPW_Includes_DataServer_MSSQL/src/util/RoutingChecker.java` | Runtime query routing |
| `templates/cutover-notification-email.md` | User-facing cutover notification email |

## Related Skills

- [`../sql/SKILL.md`](../sql/SKILL.md)
- [`../java/SKILL.md`](../java/SKILL.md)
- [`../powershell/SKILL.md`](../powershell/SKILL.md)
- [`../shared/coding-standards.md`](../shared/coding-standards.md)
