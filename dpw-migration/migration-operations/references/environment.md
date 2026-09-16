# DPW Migration Environment Reference

## Servers

| Server | Role | Access | Oracle reachable? |
|---|---|---|---|
| `sql-treas` | Migration / staging, SQL Server 2022 | Full | **Yes** — Oracle 19c client at `D:\OracleClient19c` |
| `sql-dpw3` | Production, SQL Server 2022 | Not sysadmin; `VIEW SERVER STATE` denied | **No** — linked-server stub only, Msg 7403 |

`sql-dpw3` databases: `Core`, `dbaAdmin`, `GISDPW`, `LoginDPW`, `Logs`, `ReportServer`,
`ReportServerTempDB`, `RestrictedStreets` (offline), `StreetSigns`.

## Oracle

- Oracle 19c, database `DPWP`. All DPW objects owned by schema `DPW` — same name as the
  SQL Server schema, which makes column-matching by name straightforward.
- Linked server `DPWP` on `sql-treas`: provider `OraOLEDB.Oracle`, data source `ORA1:1521/DPWP`.
- Linked-server account is `MSSQLSERVER_LINK`, holding only `CREATE SESSION`, `SELECT ANY TABLE`,
  `SET CONTAINER`, and `INSERT ANY TABLE`. The insert privilege is unnecessary — all sync
  access is read-only — and is worth revoking.
- **No DDL path to Oracle exists from the workstation.** Scripts must be handed to a DBA.

Other linked servers on `sql-treas`: `CORPDB` (Oracle), `ORA2` (Oracle), `sql-rpt` (SQLNCLI).

## Bookkeeping

`DatabaseMigration` on `sql-treas`, schema `migration` (lowercase):

| Object | Purpose |
|---|---|
| `migration.TargetDatabases` | App database → SQL Server |
| `migration.DbObjectTargetDatabases` | Per-object migration status |
| `migration.vRmiEndpointTargetDB` | RMI interface/method → target DB (authoritative) |

## Migration Procedure Template

`_DPWMigrationTemplate` on `sql-treas` is the canonical SQL Server template for the DPW Oracle
→ SQL Server refresh tooling. It contains the current migration procedures and the incremental
sync configuration table, but no application data should be placed there. Use it as the baseline
when provisioning or repairing a target database; run the procedures against the actual target
database that owns the migrated tables.

The template contains:

- `dbo.syncTable`
- `dbo.syncTableIncremental`
- `dbo.syncSequence`
- `dbo.syncDatabase`
- `dbo.syncMissingOracleIndexes`
- `dbo.IncrementalSyncConfig`

## Schema Facts (verified)

- **Zero foreign keys** in any migrated database. Only two check constraints, both in `DPWP`.
- Roughly 900 non-unique nonclustered indexes and 150 triggers across the migrated databases.
- Every migrated table carries a SQL-only `ROWID uniqueidentifier NOT NULL DEFAULT (newid())`.
  Oracle's `ROWID` is a pseudo-column and absent from `ALL_TAB_COLUMNS`, so it has no source;
  leave it to its default.
- 504 distinct `DPW` tables across the app databases. Six are shared by two apps and must not
  be frozen until both are live: `BPR_CORNERS`, `CALL_CENTER`, `CC_ACCELA_QUEUE`, `CC_MOD`,
  `SAG_CHARGES`, `SAN_CART_SURVEY`.
- Three tables exist only in SQL Server and have no Oracle counterpart:
  `APP_FREQUENT_USERS`, `INTERSECN`, `STREET_PROJN`.

## Tooling

- **`sqlcmd` is not installed.** Use ADO.NET from PowerShell; split batches on the regex
  `(?im)^\s*GO\s*$`.
- Oracle provider registration cannot be checked with `xp_regread` — it fails on `HKCR` even
  when the provider *is* registered. Use
  `[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('ClassesRoot', '<server>')`.

## Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| Query returns stale/local data | `DPWP` names both a linked server and a local DB | Use `OPENQUERY([DPWP], '...')` |
| Msg 7403, provider not registered | Running Oracle query on `sql-dpw3` | Use `sql-treas` |
| Msg 7321 preparing the query | Quotes inside `OPENQUERY` over-escaped | Double them **once**: `''Y''` |
| Collation conflict on `sys.*` | Cross-database `STRING_AGG`/`UNION` | Append `COLLATE DATABASE_DEFAULT` |
| "Subqueries are not allowed" | Subquery inside `PRINT` | Assign to a variable first |
| Distributed transaction error | `INSERT … SELECT FROM OPENQUERY` inside a transaction | Stage to `#temp` outside it |
| Aggregate returns a stale value | `SELECT @v = … HAVING COUNT(*) > 0` skips assignment when no rows match | Use `CASE WHEN COUNT(*) > 0 THEN … ELSE '' END` |
| ORA-00942 on a schema that exists | Schema created quoted-lowercase | Verify with `ALL_USERS`; recreate unquoted |

## Procedure Signatures

The five procedures are deployed into **every** target database on `sql-treas`, as well as
`_DPWMigrationTemplate` and `DPWP`; they are never deployed into `DatabaseMigration`, and contain
no `USE` statement. `_DPWMigrationTemplate` is the canonical copy to use when comparing or
refreshing a target database's procedure definitions.

```sql
EXEC syncTable    @Object='ROADLIFE', @WhatIf=1;   -- preview the generated batch
EXEC syncSequence @Object='SEQ_X%';                -- LIKE patterns accepted
EXEC syncDatabase @WhatIf=1;                       -- every table, then sequences once
```

`syncTable` copies name-matched columns only, stages into `#temp`, then truncates and reloads
inside one transaction with `TABLOCK`. It disables and restores only currently-enabled triggers,
sets constraints `NOCHECK` and re-enables them `WITH CHECK`, optionally rebuilds non-unique
nonclustered indexes (enabled by default; pass `@RebuildIndexes=0` only when intentionally
leaving them online), and updates statistics after commit. PK and UNIQUE indexes stay enforcing
on purpose.

If the source Oracle table had indexes, confirm the target SQL Server table has the same
production-relevant index coverage after the reload. A quick sanity check on the target is:

```sql
SELECT i.name, i.type_desc, i.is_primary_key, i.is_unique, i.is_disabled
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('DPW.CALL_CENTER')
  AND i.index_id > 0
ORDER BY i.is_primary_key DESC, i.is_unique DESC, i.name;
```

Use that output to compare against the Oracle source or the expected index list before go-live.
Missing nonclustered indexes are a release blocker on large tables, even if the data reload itself
completed successfully.

`syncDatabase` now invokes `dbo.syncMissingOracleIndexes` after each table load to repair any
missing Oracle indexes, unique constraints, or eligible one-column keys on the SQL Server copy.
You can run it directly for a single table when you want to repair structure without reloading the
data again:

```sql
EXEC dbo.syncMissingOracleIndexes @Schema = 'DPW', @Table = 'SAN_SCALE';
```

## Oracle Freeze Schema

`MIGRATIONS` (uppercase) in `DPWP`. Not to be confused with SQL Server's lowercase `migration`
bookkeeping schema.

| Object | Purpose |
|---|---|
| `MIGRATED_TABLES` | Control table: target server/db, `BLOCKED`, `AUDIT_MODE`, cutover date |
| `WRITE_ATTEMPTS` | One row per blocked statement, full session detail |
| `WRITE_ACTIVITY` | Audit counters per table/user/machine/program/verb/day |
| `BLOCK_EXEMPT` | Accounts allowed through (logged, not blocked) |
| `TRIGGER_BUILD_LOG` | Outcome of each `CREATE_ALL_TRIGGERS` run |
| `V_FREEZE_STATUS` | Intended state vs actual trigger state |
| `V_STILL_WRITING` | Who is still writing — read this before freezing |

Triggers are statement-level (not `FOR EACH ROW`), owned by `MIGRATIONS`, named `TRG_BLK_<TABLE>`,
and generated by `BLOCK_PKG.CREATE_ALL_TRIGGERS`. Requires `CREATE ANY TRIGGER` granted
**directly**, since roles are disabled inside definer's-rights PL/SQL.

Oracle triggers do not fire on `TRUNCATE`, and dropping `DPW.<TABLE>` drops the cross-schema
trigger with it. Neither is a gap worth closing — both require privileges the app accounts lack.

`EXEC MIGRATIONS.BLOCK_PKG.DISABLE_ALL_TRIGGERS` is the escape hatch if the package ever goes
invalid and starts blocking DML everywhere at once.
