# Query Rewrite Pipeline — Oracle SQL → T-SQL

How a query gets from Oracle dialect to something SQL Server accepts. For the specific bugs this
pipeline has produced (the `||`→`+` numeric/NULL gotchas, the logging-bypass gotcha), see
[`query-error-triage.md`](query-error-triage.md) — this file is the mechanism, that one is the
incident history. Don't duplicate fixes between them.

## Where it runs

`util.sqlParsing.Checker.translateStatement(String, boolean)` runs on every statement passed to
`Checker.prepareStatement(...)`, before it ever reaches the JDBC driver. Fixed, ordered pipeline:

1. **Strip a `"USE dbName; "` prefix** — that's routing syntax for `RoutingChecker`
   (see [`rmi-routing.md`](rmi-routing.md)), not valid SQL; never sent to the driver.
2. **`convertJoins`** — Oracle's old `(+)` outer-join syntax → ANSI `JOIN`, only if `(+)` appears
   in the statement at all.
3. **`upperCaseNonLiterals` / `compressWhiteSpace`** — normalize casing/whitespace, but only
   *outside* string literals. Both work by splitting the SQL on `'` and only touching the
   even-indexed segments — an odd number of quotes (e.g. an unescaped apostrophe slipping through)
   silently shifts every segment's literal/non-literal classification for the rest of the string.
4. **`applyRegexReplacements`** (`pre_replace_regex` table) — fixes for constructs SQLines (step 7)
   doesn't handle: `NVL2(a,b,c)` → `CASE WHEN a IS NOT NULL THEN b ELSE c END` (SQLines has no
   `NVL2` equivalent at all — "not a recognized built-in function name"), several `TO_CHAR(x,
   'mask')` date-format masks → `FORMAT(x,'mask')`, `SUBSTR(x,0,n)` → `SUBSTRING(x,1,n)` (Oracle is
   0-based, T-SQL is 1-based), `ADD_MONTHS(x,n)` → `DATEADD(MONTH,n,x)`, Oracle `'DD-MON-YYYY'`
   date literals → ISO format, and `/*+ ... */` optimizer hints stripped entirely (SQL Server
   ignores them, but some client tools reject the syntax outright). Runs on the **full** SQL
   string, string literals included — the date-literal rewrites above depend on this.
5. **`castConcatBareIdentifierOperands`** — must run here, *before* step 7 converts `||` to `+`,
   while `||` still unambiguously means concatenation. See gotcha below.
6. **`preTranslate`** — schema prefix rewrite (`DPW.`/`dpw.` → `dbo.` for the CityTime database;
   `dbo.`/`DBO.` → `DPW.` for every other DPW app database — this is how one shared `Checker` class
   serves both naming conventions) plus a literal find/replace table (`pre_replace`) for exact
   Oracle expression shapes SQLines doesn't recognize: `SYSDATE` → `GETDATE()`, several
   `date_col + N` → `DATEADD(DAY,N,date_col)` patterns, a `STDDEV(` → `STDEV(` rename, hardcoded
   `TO_CHAR(col/100,'$99,999.99')` money-format conversions, etc. These are literal substrings, not
   regexes — a formatting change in the source query (extra space, different alias) silently stops
   matching instead of erroring.
7. **`sqlLines(String)`** — shells out to the third-party **SQLines** translator
   (`<homeFolder>/sqlines/sqlines.exe`, `homeFolder` = `/rmi/lib_MSSQL/translateSQL/` on Linux,
   `C:\translateSQL\` on Windows) for the bulk of the Oracle→T-SQL conversion: `||` → `+`, `NVL` →
   `ISNULL`, Oracle implicit-join resolution, etc. Everything before this step exists to either
   pre-fix constructs SQLines mishandles, or do something that needs to happen while the SQL is
   still in its original Oracle form.
8. **`postTranslate`** — cleanup after SQLines: `convertRemainingOracleModFunctions`,
   `normalizeModuloSpacing`/`castModuloOperands` (modulo-operator type casting), `castConcatOperands`
   (the literal-adjacent `||`→`+` cases — see gotcha below), `addImplicitConvertAliases`, and a
   final literal-substitution table (`post_replace`): `from dual`/`FROM DUAL` removed, `[ORDER] BY`
   typo fixed, a couple of `CONVERT(DATETIME2,?,101)±1` → `DATEADD(DAY,±1,...)` patterns.

## Gotcha: Oracle `||` vs. T-SQL `+`

Full incident writeups and the exact regexes live in
[`query-error-triage.md`](query-error-triage.md#gotcha-oracle--concatenation-becomes-ambiguous--in-t-sql).
Short version: Oracle's `||` is unambiguous and NULL-safe; SQLines converts it to T-SQL's `+`,
which is both ambiguous with arithmetic (numeric operand → "Error converting data type varchar to
numeric") and NULL-propagating (a single NULL operand blanks the *entire* expression, silently, no
error). Three `castConcat*` methods cover the three shapes (literal-then-identifier,
identifier-then-literal, bare-identifier-to-bare-identifier with no literal) by wrapping operands in
`ISNULL(CAST(x AS VARCHAR(4000)),'')`.

## Where rewrite errors are logged, and how to see/update them

When a query does go through the logging-aware execution path (see gotcha below), both the
original Oracle SQL and the translated T-SQL are logged to `migration.CheckerQueryLog` in the
`DatabaseMigration` database — `sql_before`, `sql_after`, `error_message`, `log_type` (`'EXEC'` vs.
`'ERROR'`), `calling_class`/`calling_method`, `target_db`, `logged_at`. This is the same table
routing errors land in — it's keyed by query, not by error category.

Don't query the raw log for triage; use `migration.vCheckerQuerySummary`, which groups it by
`(sql_before, sql_after)` and adds `total_calls`/`error_count`/`lastErrorSeen`/`resolution_type`:

```sql
SELECT sql_before, error_count, total_calls, lastErrorSeen, resolution_type
FROM   migration.vCheckerQuerySummary
WHERE  error_count > 0 AND (fixed_at IS NULL OR lastErrorSeen > fixed_at)
ORDER  BY lastErrorSeen DESC;
```

To record that a rewrite bug has been fixed (or is pending deploy, won't-fix, or benign), insert
into `migration.CheckerQueryFix` — it joins to the view on `query_hash` and drives
`resolution_type`/`fixed_at` for that query shape going forward:

```sql
INSERT INTO migration.CheckerQueryFix (query_hash, sql_before, sql_after, resolution_type, fixed_by, fix_notes, project)
SELECT query_hash, sql_before, sql_after, 'pending_deploy', 'yourname', 'brief description', 'DPW_Includes_DataServer_MSSQL'
FROM   migration.vCheckerQuerySummary
WHERE  sql_before LIKE '%distinguishing text%' AND error_count > 0;
```

Full triage workflow, the `fixed`/`pending_deploy`/`wont_fix`/`benign` status meanings, and the
"reopen" logic (`lastErrorSeen > fixed_at`) are in
[`query-error-triage.md`](query-error-triage.md#recording-resolution-status--migrationcheckerqueryfix)
— don't duplicate that here, this section is just "where do rewrite errors specifically end up."

## Gotcha: this pipeline doesn't guarantee errors get logged

`Checker.prepareStatement(...)` only *translates* SQL — it does not execute it, and does not log
anything. Only `executeQueryPlus`/`executeUpdatePlus` (a separate pair of methods, called
separately by the RMI server after getting the `PreparedStatement` back) ever write to
`migration.CheckerQueryLog`. A server that calls `prepareStatement(...)` and then
`cstmt.executeQuery()`/`executeUpdate()` directly (as `DPW_Server_StreetServ_MSSQL` does,
everywhere) gets full Oracle→T-SQL translation with **zero** error logging — so for that server,
the recipe above will show nothing even though rewrite bugs are still happening. See "The intended
protection" section of [`query-error-triage.md`](query-error-triage.md) for the full story and the
planned fix.

## Debugging a translation problem

- The regex/literal tables (`pre_replace`, `pre_replace_regex`, `post_replace`,
  `schema_replace_for_citytime`, `schema_replace_for_dpwapps`) are all `static String[][]` fields
  near the top of `Checker.java` — read them directly rather than guessing what's handled.
- To test a regex fix without a Java runtime handy: port it to Python's `regex` module (not stdlib
  `re` — several of these use possessive quantifiers `++`, which only `regex` supports) and run it
  against the exact captured `sql_before` text from `CheckerQueryLog`. Cheaper than standing up a
  compile just to prove logic.
- A negative lookahead placed right after a greedy quantifier (e.g. `[A-Z0-9_.\[\]?]+(?!\s*\()`,
  meant to exclude identifiers immediately followed by a function call like `CONVERT(...)`) does
  **not** reliably exclude the intended case — the greedy quantifier can backtrack
  character-by-character until the lookahead is satisfied on a truncated match, corrupting the
  output (e.g. `'$'+CONVERT(...)` mangled to `'$'+CAST(CONVER AS VARCHAR(4000))T(...)`). Use a
  possessive quantifier (`++`) or an atomic group instead whenever a lookahead's whole purpose is
  to reject what the preceding greedy token just matched.
- `System.out.println` before/after (`"from statement:\n"` / `"to statement:\n"`) in
  `translateStatement` prints both the original and fully-translated SQL to server console — useful
  when `CheckerQueryLog` isn't populated for the server you're debugging (see gotcha above).

## Key Files

| Path | Purpose |
|---|---|
| `DPW_Includes_DataServer_MSSQL/src/util/sqlParsing/Checker.java` | The whole pipeline: `translateStatement`, `preTranslate`, `postTranslate`, `castConcat*`, the regex/literal tables |
