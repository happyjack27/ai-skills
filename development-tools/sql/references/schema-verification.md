# Verify schema before implementation

- Query metadata before introducing database field names, joins, or status logic.
  Existing code can be the bug, not evidence that its identifiers are correct.
- Retrieve exact column spelling/casing, types, primary keys, foreign keys, and
  relevant view definitions. Preserve casing in Java `JsonMap` keys even when SQL
  Server resolves identifiers case-insensitively.
- Follow foreign keys to lookup tables and inspect the relevant lookup rows.
  Do not compare a foreign-key ID with an assumed label/code. Do not infer whether
  an `Active` flag means business eligibility or lookup availability.
- Cite the verified mapping in the implementation summary. Compilation alone
  cannot prove that a field name or status predicate is correct.

## City of Milwaukee connection order

1. Use an authorized application database connection for read-only metadata and
   lookup/data verification. When a SQL password is unavailable, try `SQL-STG`
   using Windows authentication first, then `SQL-DEV` using Windows authentication.
   Do not stop after one unavailable saved SQL connection or one failed server.
   Use database tools when they support that authentication.
2. If a tool uses a saved SQL principal or lacks Windows-authentication support,
   use PowerShell `System.Data.SqlClient` with `Integrated Security=True`; a
   failure by one saved principal does not establish that Windows access fails.
3. On each failed server, connect to `master` using the same Windows identity and
   check the actual database name, `state_desc`, and `HAS_DBACCESS(name)`.
   Distinguish an offline database from unavailable metadata or incorrect credentials.
   Try the next server in the order above when the required database is unavailable.
4. If the application database is unavailable, inspect `KWATControl` metadata,
   scoped by `APP_NAME` and `TABLE_NAME`. Resolve `APP_TABLES.PRIMARY_KEY` and
   `SELECT_FROM`, plus `APP_TABLE_COLUMNS.COLUMN_NAME`, `FK_TABLE`, `FK_KEY`, and
   `FK_VALUE`. Verify the control schema rather than assuming its column names.
5. Use this fallback to establish identifiers and configured joins, not to invent
   business lookup values or claim that staging/development data matches production.
   If the necessary metadata or data still cannot be verified, report the attempted
   servers/authentication and exact blocker. Stop the dependent implementation;
   do not substitute guessed fields, IDs, labels, status meanings, or sample data.

Keep queries read-only. Do not bring databases online, change permissions,
extract application credentials, or change authentication identities to bypass
an access restriction.

### Windows-authentication probe

Run using the current Windows identity; no password is needed. Start with
`SQL-STG`, then repeat with `SQL-DEV` if the required database is unavailable:

```powershell
$connection = New-Object System.Data.SqlClient.SqlConnection `
    'Server=SQL-STG;Database=master;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=15'
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = @'
SELECT name, state_desc, HAS_DBACCESS(name) AS HasAccess
FROM
    sys.databases
WHERE
    name = @database
'@
    [void]$command.Parameters.AddWithValue('@database', 'SanitationHardships')
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)
    $table | Format-Table -AutoSize
}
finally {
    $connection.Dispose()
}
```

### KWATControl fallback

Connect to the available KWATControl instance and bind `@app`/`@table`:

```sql
SELECT TABLE_NAME, PRIMARY_KEY, SELECT_FROM
FROM
	APP_TABLES
WHERE 1 = 1
	AND APP_NAME = @app
	AND TABLE_NAME = @table;

SELECT COLUMN_NAME, FK_TABLE, FK_KEY, FK_VALUE
FROM
	APP_TABLE_COLUMNS
WHERE 1 = 1
	AND APP_NAME = @app
	AND TABLE_NAME = @table;
```

Treat these queries as configuration evidence. Inspect the actual table/view and
lookup rows when available; keep unavailable business semantics explicitly unresolved.
