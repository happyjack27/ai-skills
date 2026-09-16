# RMI-Layer Query Routing — `RoutingChecker`

This covers the **other** routing mechanism — not the servlet-layer one in
[`servlet-routing.md`](servlet-routing.md). This one lives in the MSSQL-converted RMI servers
(`DPW_Server_CTServ_MSSQL`, `DPW_Server_StreetServ_MSSQL`, etc.) that extend
`DPW_Includes_DataServer_MSSQL/src/GenericServer.java`.

## How it works

`GenericServer.checker` is a `util.RoutingChecker` (extends `util.sqlParsing.Checker`). Every DB
call goes through it, and it picks the right per-database `Checker` in this order:

1. **Pinned DB** — `RoutingChecker.pinDatabase(name)` / `clearPinnedDatabase()`. Overrides
   everything else. Used by single-DB servers (e.g. CityTime) so every query lands on the same DB.
2. **`"USE dbName; "` SQL prefix** — set by callers like `selectGenericInfra`. Stripped before the
   engine sees it, honored by both `prepareStatement` and the later `executeQueryPlus`/etc. calls
   via `DPWConnectionFactory.getClientContextDb()`.
3. **Table-name match** (`routeByTableName`) — regexes the SQL's `FROM`/`INTO`/`UPDATE` target and
   looks it up in `migration.DbObjectTargetDatabases` via `DPWConnectionFactory.getTargetDbForTable`.
4. **Bound subject-table match** (`routeByBoundSubjectTable`, added 2026-08-05) — see below.
5. **Call-stack walk** — matches each frame's method name (compound `ShortClass.method` first,
   then bare method name) against `migration.vRmiEndpointTargetDB`, skipping any frame whose method
   name contains `"Generic"` (those are pass-through helpers with no inherent DB affinity).
6. **Fallback to DPWP** — logged via `DPWConnectionFactory.logRoutingFallback(...)` into
   `migration.RoutingFallbackLog`.

## Gotcha: "dictionary" tables need the bound parameter, not their own name

Step 3 only works when the SQL's own driving table has a mapping. Some tables are
**subject-table-keyed**: they don't describe themselves, they describe *another* table by name in
a `table_name` (or similar) column. `DATA_DICTIONARY_COLUMNS` is the one found so far — a query
like

```sql
select * from dpw.data_dictionary_columns where 1=1 and table_name=? order by column_id asc
```

bound to `table_name='COMMENT_TRANSLATION'` needs to reach **StreetSigns** (where
`COMMENT_TRANSLATION` actually lives), not wherever `DATA_DICTIONARY_COLUMNS` itself is heading.

**Do not assume "the dictionary table's own migration_status is 'pending', so DPWP fallback is
correct" — that was the wrong first read of this bug.** The dictionary table's own status is
irrelevant; what matters is where the *subject* table (the bound parameter) already lives.

### The fix

`Checker`/`RoutingChecker` gained a parameter-aware overload, because `prepareStatement(String
sql)` alone never sees bound values — those are set via `cstmt.setString(i+1, ss_in[i])` **after**
`prepareStatement` returns, so routing can't inspect them unless the caller passes them in up front:

- `Checker.prepareStatement(String sql, String[] paramValues)` — base impl ignores `paramValues`
  and behaves like the 1-arg version.
- `RoutingChecker` overrides it: after the normal table-name match fails, tries
  `routeByBoundSubjectTable(sql, paramValues)` — if the driving table is in the
  `SUBJECT_TABLE_KEYED_TABLES` set (currently just `DATA_DICTIONARY_COLUMNS`) and the SQL has a
  `table_name=?` placeholder, it finds that placeholder's 0-based ordinal
  (`placeholderOrdinalFor`), grabs `paramValues[ordinal]`, and routes via
  `DPWConnectionFactory.getTargetDbForTable(null, thatValue)` instead.
- `GenericServer.selectGeneric(String, String[], boolean)` was updated to call
  `checker.prepareStatement(stm, ss_in)` (both the initial attempt and the reconnect-retry) instead
  of the parameterless overload, so it actually supplies the values.

**This fix is scoped to `selectGeneric` only** (the method the reported bug actually went through).
`GenericServer` has ~35 other `checker.prepareStatement(stm)` call sites
(`getGeneric`/`setGeneric`/`insertGeneric`/`updateGeneric`/`deleteGeneric`/etc.) that were **not**
touched — if a subject-table-keyed table ever needs routing through one of those, give it the same
one-line change (swap `prepareStatement(stm)` for `prepareStatement(stm, ss_in)`).

To add a new subject-table-keyed table, add its name (upper-case) to
`RoutingChecker.SUBJECT_TABLE_KEYED_TABLES` and confirm its call path uses a param-aware
`prepareStatement` overload.

## Diagnosing a routing/connection failure

Two different things can go wrong and they show up in different places:

- **Wrong routing decision** — always logged, check first:
  ```sql
  SELECT TOP 20 rmi_server, schema_name, table_name, method_name, reason, resolved_db, logged_at
  FROM migration.RoutingFallbackLog ORDER BY logged_at DESC;
  ```
- **Connection/login failure to the resolved DB** — routing can be 100% correct and the connection
  can still fail (wrong password, disabled login, etc.). This is **not** in `RoutingFallbackLog`
  (that table only records routing decisions, not connection outcomes). Check the SQL Server error
  log on whichever server the fallback resolved to instead:
  ```sql
  CREATE TABLE #log(LogDate datetime, ProcessInfo varchar(50), TextData varchar(4000));
  INSERT INTO #log EXEC master.dbo.xp_readerrorlog 0, 1, N'<login name>';
  SELECT TOP 20 * FROM #log ORDER BY LogDate DESC;
  DROP TABLE #log;
  ```
  The `Reason:` text (password mismatch vs. login disabled vs. db not accessible) is far more
  specific than what reaches the Java client. Rule out disabled/locked/expired fast with
  `sys.server_principals.is_disabled` and `LOGINPROPERTY(name, 'IsLocked'/'IsExpired')` first.

## Key Files

| Path | Purpose |
|---|---|
| `DPW_Includes_DataServer_MSSQL/src/util/RoutingChecker.java` | Routing priority chain, table/subject-table/stack-walk matching |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/DPWConnectionFactory.java` | `getTargetDbForTable`, `ensureCheckerForDB`, `logRoutingFallback` |
| `DPW_Includes_DataServer_MSSQL/src/util/sqlParsing/Checker.java` | Base `prepareStatement` overloads |
| `DPW_Includes_DataServer_MSSQL/src/GenericServer.java` | `selectGeneric` and the other ~35 Generic-method call sites |
