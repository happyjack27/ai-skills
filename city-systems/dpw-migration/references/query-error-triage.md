# Tracking Query Errors — `CheckerQueryLog` Triage and `CheckerQueryFix` Resolution

SQL statements executed via `Checker.executeQueryPlus`/`executeUpdatePlus` are logged to
`migration.CheckerQueryLog` in `DatabaseMigration` — `log_type = 'EXEC'` on success, `'ERROR'` on
failure, with `sql_before` (Oracle-style), `sql_after` (translated T-SQL), `error_message`,
`calling_class`/`calling_method`, `target_db`, and `logged_at`. **`Checker.prepareStatement()` alone
does NOT log anything** — it only translates the SQL and hands back a raw JDBC `PreparedStatement`.
See "The intended protection: forcing execution through `...Plus`" below before assuming a query's
absence from the log means it succeeded, was misrouted, or was skipped by chance.

`migration.vCheckerQuerySummary` groups that log by `(sql_before, sql_after)` and computes
`total_calls`/`error_count`/`first_seen`/`lastErrorSeen`/`top_caller`/`target_dbs`/`query_hash`
(SHA2-256 hex of the two SQL texts). Use it, not the raw log, for triage — it collapses tens of
thousands of log rows down to one row per distinct query shape.

## Triage recipe

Rank by recency, not just volume — a pattern with 200 hits that stopped last month is stale; one
with 20 hits and a `lastErrorSeen` of today is live:

```sql
SELECT sql_before, error_count, total_calls, lastErrorSeen, top_caller, target_dbs, resolution_type
FROM   migration.vCheckerQuerySummary
WHERE  error_count > 0 AND (fixed_at IS NULL OR lastErrorSeen > fixed_at)
ORDER  BY lastErrorSeen DESC;
```

Don't filter on `fixed_at IS NULL` alone — `query_hash` is unique, so a row marked once
(any `resolution_type`) stays forever. Comparing `lastErrorSeen > fixed_at` is what actually
reopens a query group: if it errors again *after* the date it was marked, that's a genuine
regression/reopen signal, not noise. See the grain caveat below for why the reopened error
can be a completely different bug than the one you originally fixed.

For each candidate, get 2-3 raw rows (`error_message`, `sql_before`, `sql_after`, `target_db`)
from `CheckerQueryLog` to see the exact failure, not just the grouped summary.

**`sql_before` identical to `sql_after` + "Invalid object/column name"** usually means a genuine
schema gap on the SQL Server side (missing table/column/sequence), not a translation bug — check
`INFORMATION_SCHEMA.COLUMNS`/`sys.sequences`/`sys.objects` on the actual target DB directly before
suspecting `Checker.java`. Cross-check against Oracle too, via `OPENQUERY([DPWP], 'SELECT ... FROM
ALL_TAB_COLUMNS/ALL_SEQUENCES WHERE ...')` from `sql-treas` — if the object is missing in Oracle as
well, it's dead/incomplete application code, not a migration gap.

**A commented-out line directly above the active one is often the pre-migration Oracle query.**
Grep-searching the workspace for a distinctive identifier from the error message (a column or table
name) is the fastest way from a runtime error straight to source — and the commented predecessor
frequently reveals logic (e.g. a `NULL`-coalescing fallback) that was silently dropped during the
Oracle → T-SQL port.

## Gotcha: Oracle `||` concatenation becomes ambiguous `+` in T-SQL

Oracle's `COL1||'lit'||COL2` is translated (by `sqlines` and/or `Checker`'s regex rules) to
`COL1+'lit'+COL2`. T-SQL's `+` is overloaded for both arithmetic and string concatenation; if
`COL1`/`COL2` are a numeric type, SQL Server tries to convert the string literal to numeric instead
of converting the number to a string, and throws:

```
Error converting data type varchar to numeric.
```

Oracle's `||` never has this ambiguity — it always coerces to string — so this class of bug only
appears after the T-SQL port, and only for columns that are numeric on the SQL Server side.

`Checker.castConcatOperands` (see `util/sqlParsing/Checker.java`, called from `postTranslate`) is
the fix: it wraps any bare identifier that touches a string literal via `+` in
`CAST(... AS VARCHAR(4000))`, on either side, in two passes (left-operand pass then right-operand
pass) so a chain like `A+' '+B+' x '+C` gets every operand fixed. `VARCHAR(4000)` deliberately, not
bare `VARCHAR` (which defaults to 30 chars and would silently truncate long concatenations
elsewhere). Canonical example: `dpw.ss_sign_type_cds_sub` (`SIZE_1||' x '||SIZE_2`).

If you hit this error and `castConcatOperands` already exists in the source, don't assume the regex
is wrong — verify it first by running the two patterns
(`castConcatLeftOperands`/`castConcatRightOperands`) against the exact failing SQL text. It's cheap
to prove the fix logic is correct with an ad hoc Python/Node regex test even without a Java runtime
handy. If the logic is correct but the live server still fails, see the deployment-lag gotcha next.

**Sub-gotcha: `identifier||identifier` with no literal anywhere in the pair is a separate case.**
`castConcatLeftOperands`/`castConcatRightOperands` only fire when a string *literal* is adjacent to
the identifier being cast — `A||B` with both sides bare identifiers (no literal at all, e.g.
`HOUSE_BLOCK_NUMBER||INTERSECT_EST_INDIC`, a numeric house number concatenated with a varchar(1)
suffix flag) falls through both regexes untouched. `Checker.castConcatBareIdentifierOperands`
handles this — but it must run *before* `sqlLines` converts `||` to `+` (in `translateStatement`,
right after `applyRegexReplacements`), not in `postTranslate` alongside `castConcatOperands`, since
by then the `||`/`+` distinction that makes this fixable is already gone.

## Gotcha: a routing/translation fix can be committed but not yet live

`RoutingFallbackLog` or `CheckerQueryLog` continuing to show identical errors **after** a fix's
commit date does not necessarily mean the fix is wrong — the far more common cause in this
environment is that the RMI server process (or servlet) serving that traffic has not been rebuilt,
redeployed, or restarted since the fix was committed. This has shown up at least twice:

- `RoutingChecker.routeByBoundSubjectTable` (for `DATA_DICTIONARY_COLUMNS`) — code fix traced
  line-by-line against the exact failing SQL and confirmed correct, yet fallback rows kept
  appearing after the commit.
- `Checker.castConcatOperands` — committed 2026-08-04 (`b6fb69e`), regex-verified correct against
  `dpw.ss_sign_type_cds_sub`'s exact query text, yet `CheckerQueryLog` still showed the same error
  on 2026-08-05.

Before concluding a fix doesn't work: (1) find the fix's commit date (`git log -S"<function
name>"`), (2) compare it to `lastErrorSeen`/`logged_at` on the still-failing rows, (3) if errors
persist strictly after the commit, verify the fix logic in isolation (regex test, unit test, or a
manual trace against the exact captured SQL) rather than re-diagnosing the whole feature. If the
logic checks out, the answer is almost always "redeploy the server," not "the fix is broken" — say
so explicitly and mark the row `pending_deploy` (see below) rather than `fixed`.

## Recording resolution status — `migration.CheckerQueryFix`

`migration.CheckerQueryFix` (see
[`../../../DPW_Includes_DataServer_MSSQL/sql/create_CheckerQueryFix.sql`](../../../DPW_Includes_DataServer_MSSQL/sql/create_CheckerQueryFix.sql))
joins to `vCheckerQuerySummary` on `query_hash` and carries a `resolution_type`.

**Grain matters here**: `CheckerQueryLog` is one row per *execution* (115k+ rows and
growing); `CheckerQueryFix` is one row per *distinct query shape* — `query_hash` is
`UNIQUE`, so marking a resolution once applies to every past and future event for
that statement via the view's join. Don't add resolution columns to `CheckerQueryLog`
itself (that would need updating per event) and don't confuse this with the unrelated
`migration.SqlQueryInventory` table, which tracks source-code Oracle→dual-branch
conversion progress per file/line and already uses `status` for that different purpose.

`project` records which repo the underlying code fix was applied in (e.g.
`DPW_Includes_DataServer_MSSQL` for a shared `Checker.java` regex fix vs. `AppServ_MSSQL`
for an app-specific query change) — free text, comma-list if a fix spans more than one repo.

**Not distinct by error type — only by `query_hash`.** There is no error-code/error-message
column anywhere in this grain (`UQ_CheckerQueryFix_Hash` is `(query_hash)` alone, and
`vCheckerQuerySummary`'s `GROUP BY` is `(sql_before, sql_after)` only). `error_count`/
`lastErrorSeen` aggregate *every* error for that query shape regardless of cause. Confirmed
live on 2026-08-05: `dpw.data_dictionary_columns` errored with a `DPWP` login failure months
ago, then with an unrelated "Invalid object name" once routing later sent it to `StreetSigns`
instead — same `query_hash`, two unrelated root causes. The `lastErrorSeen > fixed_at` check
still catches this as a reopen either way, but always re-read the raw `error_message` in
`CheckerQueryLog` before assuming a reopened row is the *same* bug you originally marked.

`fixed_at` also auto-refreshes on `UPDATE` — `trg_CheckerQueryFix_RefreshFixedAt` re-stamps it
to `SYSUTCDATETIME()` whenever `resolution_type` changes (e.g. `pending_deploy` → `fixed` once
a redeploy is confirmed), so "errors after this date = reopen" stays meaningful across re-marking.

| Value | Meaning |
|---|---|
| `fixed` | Fix is committed **and deployed**; should not error again. |
| `pending_deploy` | Fix is committed to source but the running process hasn't picked it up yet. Don't upgrade to `fixed` until `CheckerQueryLog` shows no new errors after the redeploy date. |
| `wont_fix` | Real bug, deliberately left alone (dead code path, not worth the risk/effort). |
| `benign` | Not actually a bug — expected/handled exception or cosmetic-only. |

```sql
-- Mark a query group's resolution (any status)
INSERT INTO migration.CheckerQueryFix (query_hash, sql_before, sql_after, resolution_type, fixed_by, fix_notes, project)
SELECT query_hash, sql_before, sql_after, 'pending_deploy', 'yourname', 'brief description', 'RepoName'
FROM   migration.vCheckerQuerySummary
WHERE  sql_before LIKE '%distinguishing text%'
  AND  error_count > 0
  AND  NOT EXISTS (SELECT 1 FROM migration.CheckerQueryFix x    -- UQ_CheckerQueryFix_Hash also prevents duplicates
                    WHERE x.query_hash = vCheckerQuerySummary.query_hash);

-- Find fixes still waiting on a deploy
SELECT * FROM migration.vCheckerQuerySummary WHERE resolution_type = 'pending_deploy';
```

If `migration.CheckerQueryFix` or its `resolution_type` column doesn't exist yet in a given
environment, run `sql/create_CheckerQueryFix.sql` (idempotent-ish — it's a plain `CREATE TABLE`, so
check first) and `sql/create_vCheckerQuerySummary.sql` to bring the view's definition — including
`resolution_type` — under source control.

## The intended protection: forcing execution through `...Plus`

**Design intent**: `Checker`/`RoutingChecker` is supposed to hide the real JDBC connection so every
query is *forced* through `executeQueryPlus`/`executeUpdatePlus` — the only two methods that ever
call `Checker.handleException()`, which is the only thing that ever calls `logToMigration("ERROR",
...)`. If a caller could reach `execute()`/`executeQuery()`/`executeUpdate()` directly on the raw
statement, it bypasses logging (and any future centralized retry/routing logic) entirely, silently.

**Current reality (found 2026-08-05): the protection is not actually implemented.**
`Checker.prepareStatement()` returns a plain `java.sql.PreparedStatement` — the interface exposes
`executeQuery()`/`executeUpdate()`/`execute()` directly, and nothing stops a caller from using them.
`DPW_Server_CTServ_MSSQL` only "complies" by convention (every `checker.prepareStatement()` call
site happens to be followed by `executeQueryPlus`/`executeUpdatePlus` — grep-confirmed, hundreds of
pairs). `DPW_Server_StreetServ_MSSQL` does not comply at all: **zero** calls to
`executeQueryPlus`/`executeUpdatePlus` anywhere in ~352 raw `cstmt.executeQuery()`/`executeUpdate()`
call sites across 8 files (`SSServ`, `SSRpts`, `RLServ`, `RLReports`, `PavServ`, `AlleyServ`,
`SLServ`, `StreetServ.java`). Every error from every StreetSigns query has always been swallowed
by that method's own local `catch(Exception ex){ System.out.println(...) }` — proved directly by
matching a hardcoded console label (`"123:" + exxa` in `SSServ.getJSSLightsLoc()`) to a live error
the user observed that never appeared in `CheckerQueryLog`. **This means `CheckerQueryLog` has
never seen a single StreetSigns error, ever** — not a regression, a gap since day one of the MSSQL
conversion. Don't assume a query's absence from the log means anything about routing or timing
for a server until you've confirmed (`grep -c executeQueryPlus\|executeUpdatePlus`) that the server
actually uses the `...Plus` methods at all.

**Planned real fix (agreed 2026-08-05, StreetServ_MSSQL only for now, not yet implemented):**
- **Phase A** — change `Checker`/`RoutingChecker`'s `prepareStatement()` return type/API so the raw
  `execute*` methods are no longer reachable by callers (e.g. return a wrapper that only exposes
  parameter setters + `close()`, not `executeQuery`/`executeUpdate`/`execute`). This is expected to
  break compilation at every StreetServ bypass call site — that's the point: the resulting compiler
  errors ARE the migration checklist, proving the protection actually works.
- **Phase B** — migrate every StreetServ call site the Phase A compile breaks to call
  `GenericServer.checker.executeQueryPlus(cstmt)`/`executeUpdatePlus(cstmt)` instead of
  `cstmt.executeQuery()`/`executeUpdate()` directly.
- CTServ_MSSQL and other servers were deliberately left out of this pass (StreetServ only, per
  explicit scoping decision) — don't assume they've been audited or fixed too.

**Compiling for real (not just `get_errors`'s lightweight syntax check) needs the real multi-project
classpath** — read each project's `.classpath` file, don't guess. For
`DPW_Server_StreetServ_MSSQL`, the working recipe found 2026-08-05:
- Local JDK 8 is installed at `C:\Java Server Jre\jdk1.8.0\bin\javac.exe` (1.8.0_162) — despite
  there being no JDK on the general PATH, don't assume there's no local compiler available; check
  `C:\Java Server Jre\`, `C:\Program Files (x86)\Eclipse Adoptium\`, and `C:\sqldeveloper\jdk\`.
- Sourcepath needs `DPW_Server_StreetServ_MSSQL\src` + `DPW_Includes_DataServer_MSSQL\src` +
  `DPW_Includes_DataClient\{src,DndJTable,ColorTable,ExcelObj,WordObj,Misc,Print}` +
  (transitively) `DPW_Includes_DataServer\src` and `DPW_jcom` — `DPW_Includes_DataClient`'s own
  `.classpath` lists all of these as sibling `kind="src"` entries, it is not a single `src` folder.
- Classpath jars live at each project's own root (not a `lib/` subfolder):
  `DPW_Server_StreetServ_MSSQL\{ojdbc6,jdbc-mssql,sqljdbc4}.jar` and
  `DPW_Includes_DataServer_MSSQL\{ojdbc6,activation,bcprov-jdk14-136,mail,jdbc-mssql,sqljdbc4}.jar`.
  Missing `bcprov-jdk14-136.jar`/`mail.jar`/`activation.jar` on the classpath produces
  `org.bouncycastle`/`javax.mail` "package does not exist" errors that look unrelated to whatever
  you actually changed — don't misread those as real bugs.
