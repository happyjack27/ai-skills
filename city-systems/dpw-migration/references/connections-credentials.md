# Database Connections, Environments, and Credentials

How an RMI server picks a server/port and a set of credentials for a logical database name, and
where those credentials are stored. For which *database* a query should target, see
[`rmi-routing.md`](rmi-routing.md) (RMI layer) or [`servlet-routing.md`](servlet-routing.md)
(servlet layer) — this file is one layer further down: once a database name is decided, how the
actual connection gets opened.

## The three pieces

- **`util.dbConnections.enums.Database`** — one enum constant per logical database (`ROADLIFE`,
  `STREETSIGNS`, `DPWP`, `MIGRATION` = `DatabaseMigration`, …), each pinned to one
  `DbEnvironment`. A database that exists in more than one environment (currently only `CityTime`,
  which has real dev/staging boxes distinct from the shared `sql-treas`/`sql-dpw3` pair everything
  else uses) gets two separate constants with distinct **aliases** (`CityTime:dev`,
  `CityTime:stg`) — `Database.fromName` refuses to resolve a bare `"CityTime"` for exactly this
  reason (ambiguous), so callers must use the alias.
- **`util.dbConnections.enums.DbEnvironment`** — `DEV` (`sql-treas.ad.milwaukee.gov`), `PROD`
  (`sql-dpw3.ad.milwaukee.gov`), `CITYTIME_DEV`/`CITYTIME_STAGING` (CityTime's own separate boxes).
  **The server hostname lives here, not in the properties file and not per-database** — deliberate,
  so a database's server can never drift out of sync with its declared environment. Promoting a
  database from dev to prod is a one-line enum edit (`DbEnvironment.DEV` → `.PROD`) plus a rebuild,
  not a config change and not something that takes effect without a redeploy.
- **`util.dbConnections.ConnectionRegistry`** — loads `db-connections.properties` once, lazily (on
  first `get()`), and builds a `Database → DbConnection` map. Fails fast at load time
  (`IllegalStateException`) if any database's `.user`/`.password` keys are missing, rather than
  waiting for a connection attempt to discover it. `DbConnection` is an immutable value object
  bundling dbName/user/password with the environment; it deliberately does **not** store a server
  of its own — `getServer()` delegates to `environment.getServer()` so there's only ever one copy.

`DPWConnectionFactory.connect(dbName)` (the actual JDBC connection opener, used by
`RoutingChecker`/`GenericServer` — see [`rmi-routing.md`](rmi-routing.md)) just resolves the
`Database` enum constant for the name, asks `ConnectionRegistry` for its `DbConnection`, and opens
`jdbc:sqlserver://<env-server>;databaseName=<db>;encrypt=true;trustServerCertificate=true` with
that connection's user/password.

## `db-connections.properties`

Lives at `DPW_Includes_DataServer_MSSQL/resources/db-connections.properties`. One `user`/`password`
pair per `<DbName>.<env>` key, where `<DbName>` is exactly `Database.getDbName()` and `<env>` is
`dev`/`prod` (lowercase enum name) — e.g. `RoadLife.dev.user` / `RoadLife.dev.password`.

- Login convention is `api<DbName>` for every database — **except** `DPWP`, which uses `apiDPW`
  (the legacy generic login). The `apiDPWP` login the naming convention implies does **not**
  actually exist on `sql-treas` — confirmed via `sys.server_principals`. Don't assume you can
  "just create the missing login" without checking first; the working login is `apiDPW`,
  `db_owner` on `DPWP`.
- Dev passwords are a single shared throwaway credential (`sqldev`, or `sqlstg` for
  `CityTime.citytime_staging`) — fine to have visible in a checked-in file.
- Filled-in production passwords are long, random-looking strings stored as **plain text** — they
  are **not** encrypted with `dkCrypt` (see below). The only protection is keeping the populated
  file out of source control; commit a `.template` copy with prod passwords blanked instead.
- Unfilled production entries are the literal placeholder `__SET_PROD_PASSWORD__` — `populate()`
  in `ConnectionRegistry` doesn't treat this specially, so a database that's never had its prod
  password set will connect (or rather, fail to authenticate) using that literal string if
  `DbEnvironment.PROD` is ever exercised for it. Check for this placeholder before assuming a
  prod credential is real.

## `dkCrypt` is unrelated — don't assume it protects these passwords

`DPW_Includes_DataServer_MSSQL/src/dkCrypt.java` is a small, old (1998) reversible
character-swap/hash-distortion cipher (`encrypt`/`uncrypt`, truncates input to 16 chars). It exists
in this codebase for a different, older purpose and is **not** used anywhere in the
`ConnectionRegistry`/`db-connections.properties` path — those passwords are stored and read as
plain text. Don't assume the long hex-looking prod password strings in the properties file are
`dkCrypt`-encrypted; they're just real passwords that happen to look opaque.

## Gotcha: `GenericServer` has its own separate, parallel credential path

`GenericServer` (the RMI server base class every MSSQL-converted server extends) has its own
**legacy** static credential fields — `getDBPassword()`/`getDBUser()`, gated by a
`USE_MSSQL_PROD` boolean, with hardcoded `mssql_user_PROD`/`mssql_password_PROD` constants — used
only for its own static bootstrap connection (`connector_new_prod`, `new_server_connector`, etc.).
**This path does not go through `ConnectionRegistry` or `db-connections.properties` at all.**
If a database's password ever needs to change, both places have to be updated — changing
`db-connections.properties` alone does not update `GenericServer`'s own hardcoded fallback, and
vice versa. This has already caused at least one real incident (a stale `apiDPW` password sent
by both paths independently, only one of which anyone remembered to check) — see the
2026-08-05 apiDPW incident in repo memory / `query-error-triage.md`-adjacent history.

`CityTime`'s dev/staging environment choice has a similar historical duplicate-switch problem:
`GenericServer.citytime_use_sqlstg` (resolved once at class-load from a `-Dcitytime.env`
sysprop/`CITYTIME_ENV` env var, default dev) now also drives `CTServer.IS_STAGING` (which picks
the RMI port and service name), specifically so the two can't drift out of sync the way they used
to when each was an independently-hardcoded boolean.

## Verification recipe

- **"Which server/environment does database X use?"** — `Database.valueOf(...).getEnv()` in
  source, or just read the enum table in [`servlet-routing.md`](servlet-routing.md#3-which-environment--the-database-enum-not-a-config-file).
- **"What are X's live credentials?"** — read `db-connections.properties` directly (it's a secret
  file, not queryable from SQL); cross-check the login actually exists with
  `SELECT name FROM sys.server_principals WHERE name = 'apiX'` on the target server.
- **"Why did a connection to X fail after a password rotation?"** — check *both*
  `db-connections.properties` and, if the caller is `GenericServer`/`CTServer`-based, its
  hardcoded `mssql_password_PROD`/`getDBPassword()` fallback too.

## Key Files

| Path | Purpose |
|---|---|
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/enums/Database.java` | One constant per logical database, pinned `DbEnvironment`, alias for multi-environment databases |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/enums/DbEnvironment.java` | Environment → server hostname |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/ConnectionRegistry.java` | Loads the properties file, builds `DbConnection`s, fails fast on missing keys |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/DbConnection.java` | Immutable dbName/user/password/environment value object, builds the JDBC URL |
| `DPW_Includes_DataServer_MSSQL/src/util/dbConnections/DPWConnectionFactory.java` | Opens/caches the actual JDBC connections, one per database |
| `DPW_Includes_DataServer_MSSQL/resources/db-connections.properties` | Per-database/environment credentials (secret — keep out of source control) |
| `DPW_Includes_DataServer_MSSQL/src/dkCrypt.java` | Unrelated legacy cipher — not used for these credentials |
| `DPW_Includes_DataServer_MSSQL/src/GenericServer.java` | Separate legacy hardcoded credential path (`getDBPassword`/`getDBUser`/`USE_MSSQL_PROD`) — keep in sync manually |
