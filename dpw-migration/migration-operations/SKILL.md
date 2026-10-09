---
name: migration-operations
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
- **Out of scope:** general SQL authoring (see [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md)), Java servlet
  and RMI server code (see [`../../development-tools/java/SKILL.md`](../../development-tools/java/SKILL.md)), Accela specifics
  (see [`../../accela-platform/accela/SKILL.md`](../../accela-platform/accela/SKILL.md)).

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
- [`references/rmi-routing.md`](references/rmi-routing.md) — the RMI-server side (`GenericServer`/
  `RoutingChecker`/`DPWConnectionFactory`): the routing priority chain, the "subject-table-keyed
  dictionary table" gotcha, and how to tell a bad routing decision from a bad connection/login.
- [`references/query-rewrite.md`](references/query-rewrite.md) — the `Checker.translateStatement`
  Oracle-SQL-to-T-SQL pipeline itself (SQLines shell-out, the regex/literal substitution tables,
  schema prefix rewriting) — the mechanism, not the incident history.
- [`references/query-error-triage.md`](references/query-error-triage.md) — triaging
  `CheckerQueryLog`/`vCheckerQuerySummary` for live vs. stale errors, the Oracle `||`-to-T-SQL-`+`
  numeric-cast gotcha, the "fix committed but not redeployed" pattern, and how to record a query
  group's resolution (`fixed`/`pending_deploy`/`wont_fix`/`benign`) in `CheckerQueryFix`.
- [`references/connections-credentials.md`](references/connections-credentials.md) — how a
  database name resolves to a server/environment (`Database`/`DbEnvironment` enums) and where
  credentials live (`ConnectionRegistry`, `db-connections.properties`), including
  `GenericServer`'s separate legacy credential path that has to be kept in sync by hand.

The essentials:

| Fact | Value |
|---|---|
| Migration/staging SQL Server | `sql-treas` — full access, Oracle client installed |
| Migration procedure template | `sql-treas._DPWMigrationTemplate` — canonical template containing the migration refresh procedures and `dbo.IncrementalSyncConfig`; no application data belongs here |
| Production SQL Server | `sql-dpw3` — **not** sysadmin, **no Oracle provider** |
| Oracle source | 19c, database `DPWP`, all objects owned by schema `DPW` |
| Linked server | `DPWP` on `sql-treas` only — always via `OPENQUERY` |
| Bookkeeping | `DatabaseMigration` DB, schema `migration` (lowercase) |
| Oracle freeze schema | `MIGRATIONS` (uppercase, plural) |

## Workflow

### Refreshing data from Oracle

1. Connect to the **target** database on `sql-treas` — the procedures are deployed into every
  target DB and deliberately contain no `USE` statement. `_DPWMigrationTemplate` is the
  procedure/configuration template, not a normal application target; use it as the baseline when
  provisioning or repairing a target database.
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
- Before a production cutover, verify the migrated SQL Server table still has the expected
  nonclustered indexes as well; do not assume a successful data reload recreated them all.
  If the source Oracle table had an index and the target table does not, treat that as a go-live
  blocker until it is reconciled.
- `syncDatabase` now calls `dbo.syncMissingOracleIndexes` after each table load so the SQL Server
  table keeps the Oracle source's index/key coverage. Use the helper directly if you need to
  repair one table without rerunning the full database sync.
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
- **A "dictionary" table's own migration status is the wrong thing to check.** Tables like
  `DATA_DICTIONARY_COLUMNS` describe *another* table via a `table_name` column/parameter, not
  themselves — route by that bound subject table's own mapping, not the dictionary table's.
  Getting this wrong looks like a legitimate fallback (dictionary table shows "pending") but is
  actually a routing gap. See [`references/rmi-routing.md`](references/rmi-routing.md).
- **A wrong routing decision and a failed connection to the resolved DB are different failures.**
  `migration.RoutingFallbackLog` only records the routing decision, never whether the connection
  actually succeeded — check the target server's `xp_readerrorlog` for login failures separately.
- **Staggered apps sharing an Oracle sequence cannot use local `MAX(key)` for the later import.**
  When one SanScale house moves first, reserve a SQL-only `SEQ_SAN_SCALE` range above Oracle's
  current `LAST_NUMBER`, persist the Oracle `REC_NUM` floor from the initial sync, then merge the
  later house by its `SITE_ID` and that saved floor. `syncTableIncremental` normally uses local
  `MAX(REC_NUM)`, which includes the first house's reserved SQL IDs and would skip the second
  house's lower Oracle IDs. Do not run `syncDatabase`/`syncSequence` after the reservation: they
  reset the SQL sequence back to Oracle. Re-import a small overlap and locally open tickets;
  reject any incoming `REC_NUM` that already belongs to a different site.
- **`DbObjectTargetDatabases` can itself be wrong.** Found in `SanScaleCenter`: `CCURE` and
  `SAN_BILLING_LOOKUP` are mapped there with zero corroborating `AppObjectUsage` rows for any app;
  `SAN_CART_SURVEY`, `NPPS`, `NPPS_CHECK`, `PARKING_REGS2` are correctly mapped to `CallCenter` in
  bookkeeping but a stray physical copy also sits in `SanScaleCenter` and was being silently
  reloaded by `syncDatabase` every run. Don't trust a `DbObjectTargetDatabases` row just because it
  exists — cross-check `AppObjectUsage`/`vw_AppObjectAccess`, and check what tables are *physically
  present* in the database against what bookkeeping says should be there. Log confirmed
  misroutes/duplicates as `PlacementIssues.issue_type = 'MISROUTED_TARGET_DB'`.
- **Not every finding is about one object.** `migration.DatabaseIssues` (added 2026-09-02) holds
  database-scoped findings not tied to a single object (e.g. a whole database missing an expected
  category of object). Use this table instead of forcing a database-level gap into `PlacementIssues`,
  which is object-scoped. See [database-migration-db.md](./references/database-migration-db.md).
- **Oracle sequence naming convention: `SEQ_<TABLE_NAME>`.** When migrating a table, check whether
  Oracle has a matching sequence backing its PK/watermark column before assuming one needs to be
  created. **But an empty result from the linked server does NOT prove the sequence doesn't
  exist** — this bit us on 2026-09-02: `ALL_SEQUENCES` and `ALL_OBJECTS WHERE OWNER = 'DPW'` via
  `OPENQUERY([DPWP], '...')` both returned zero rows for `SEQ_SAN_SCALE`/`SEQ_SAN_CART_SURVEY`/etc,
  and that was wrongly reported as "confirmed absent." Both views are **grant-scoped to the
  linked-server login** (`MSSQLSERVER_LINK`), not schema-scoped — a table's owner having rows in
  `ALL_OBJECTS` doesn't mean every object that owner has is visible, only the ones the link login
  was separately granted privilege on. The sequences existed the whole time; a human with a
  properly-privileged Oracle client could see them immediately. **The real check**: query
  `SELECT TABLE_NAME, GRANTOR, PRIVILEGE FROM USER_TAB_PRIVS_RECD WHERE TABLE_NAME LIKE 'SEQ_%'`
  (self-referential, not privilege-gated, always accessible) to see exactly what the link login has
  been granted. Zero rows there means "no visibility through this link," not "doesn't exist" — you
  cannot enumerate what you don't have grants on. If you need to confirm true absence/existence and
  the link comes up empty, ask someone with direct Oracle access (or request the grant) rather than
  trusting the linked server's silence. `DBA_SEQUENCES`/`DBA_OBJECTS` are typically not accessible
  to a migration-scoped linked-server login either (Msg 7321, insufficient privilege).
  **Update 2026-09-02: this specific gap was closed** — an Oracle-side grant was added for
  `MSSQLSERVER_LINK`, and a plain `OPENQUERY([DPWP], 'SELECT ... FROM ALL_SEQUENCES')` with **no
  impersonation** now returns `SEQ_SAN_CART_SURVEY`/`SEQ_SAN_SCALE` (confirmed via
  `SELECT USER FROM DUAL` = `MSSQLSERVER_LINK`). If this resurfaces for a different object, the fix
  is the same: request the grant, don't reach for `EXECUTE AS` or a SQL Agent job.
  **Do not `SELECT OWNER`** as an output column in any `OPENQUERY` against these Oracle dictionary
  views — it makes the OLE DB provider fail to prepare the query at all (Msg 7321), even though
  `OWNER` is a normal column and filtering by it in `WHERE` works fine.
- **A SQL Agent job does NOT escalate you to a linked server's `sa`-mapped Oracle account, even
  though `EXECUTE AS LOGIN = 'sa'` fails (Msg 7303) and a job looks like a workaround.** `sys.linked_logins`
  on `DPWP` maps the *virtual* account `NT SERVICE\SQLSERVERAGENT` to Oracle `system`, but a
  sysadmin-owned T-SQL job step actually runs as the real Windows/domain account the Agent service
  logs in as (here, a domain account, confirmed via `sysjobhistory.message` = "Executed as user:
  AD\SQLSERVERAGENT") — a *different* login than the virtual-account name in `sys.linked_logins`.
  With no mapping for that specific domain login, the linked server silently falls back to the
  default/public mapping (`MSSQLSERVER_LINK` — the same restricted account you started with).
  **Always verify with `SELECT USER FROM DUAL` via the job's own `OPENQUERY` before trusting any
  "elevated" result** — a job "succeeding" only means the T-SQL ran without error, not that it ran
  as the Oracle account you expected. If you need genuine elevated Oracle access and the linked
  server has no working escalation path, the fastest real fix is asking someone with a directly
  privileged Oracle client to run the query and share results — don't keep inventing SQL Server-side
  workarounds for what is fundamentally an Oracle-side grants gap. Once the grant is actually added,
  the fix shows up as the *default* (unimpersonated) `OPENQUERY` starting to work — `EXECUTE AS
  LOGIN = 'sa'` still fails with Msg 7303 regardless, since that's a separate provider limitation,
  not a grants problem. Don't bother re-testing impersonation after a grant fix; just query plainly.
- **A database's credentials can go stale in two places at once.** `GenericServer` has its own
  hardcoded legacy password fallback (`getDBPassword()`/`mssql_password_PROD`) that is completely
  separate from `db-connections.properties`/`ConnectionRegistry`. Changing one does not change the
  other. See [`references/connections-credentials.md`](references/connections-credentials.md).
- **Oracle `||` becomes T-SQL `+`, which is both ambiguous with arithmetic and NULL-propagating.**
  The numeric-ambiguity case throws; the NULL case silently blanks the whole expression instead.
  Both need separate fixes even though they're the same operator swap — see
  [`references/query-rewrite.md`](references/query-rewrite.md).

## Validation Checklist

- [ ] Connected to the correct database, and the correct server (`sql-treas` for anything Oracle).
- [ ] Oracle access goes through `OPENQUERY`, not three-part naming.
- [ ] `@WhatIf=1` reviewed before a real reload of a production-bound table.
- [ ] Row counts compared before and after; skipped columns explained.
- [ ] Indexes compared against the source Oracle table or the expected target index list; no
  missing production indexes remain.
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
| `DPW_Includes_DataServer_MSSQL/src/util/sqlParsing/Checker.java` | Oracle→T-SQL rewrite pipeline |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/ConnectionRegistry.java` | Credential loading |
| `DPW_Includes_DataServer_MSSQL/resources/db-connections.properties` | Per-database/environment credentials (secret) |
| `templates/cutover-notification-email.md` | User-facing cutover notification email |

## Related Skills

- [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md)
- [`../../development-tools/java/SKILL.md`](../../development-tools/java/SKILL.md)
- [`../../shared/coding-standards.md`](../../shared/coding-standards.md)
