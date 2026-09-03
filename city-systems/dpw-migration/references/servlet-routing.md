# Servlet Routing: Which Page Talks to Which Database

The three servlet projects are single deployables that fan out to many databases. Nothing in
`web.xml` controls this — there are no `<resource-ref>` entries, no init-params, and no
`context.xml`. **Routing is entirely code-driven**, which means a page can silently talk to the
wrong database and still compile, deploy, and return plausible-looking data.

Three independent questions have to be answered right for a page to hit the correct target:

1. **Which database** does the page need?
2. **Which backend** — Oracle or SQL Server?
3. **Which environment/server** — `sql-treas` (dev) or `sql-dpw3` (prod)?

They are controlled in three different places. Getting two right and one wrong is the normal
failure mode.

## 1. Which Database — `migration.ServletPage`

`DatabaseMigration` tracks every page. 102 rows, by project and connection style:

| Project | Connection type | Pages |
|---|---|---|
| `DPWServletsInternal` | `rmi` | 17 |
| `DPWServletsInternal` | `none` | 9 |
| `DPWServletsInternal` | `direct-jdbc` | 2 |
| `DPWServletsInternal` | `rmi+direct-jdbc` | 1 |
| `DpwServletsPublic` | `jndi` | 15 |
| `DpwServletsPublicAll` | `direct-jdbc` | 53 |
| `DpwServletsPublicAll` | `none` | 5 |

```sql
SELECT sp.project, sp.servlet, sp.mssql_db, sp.connection_type,
       sp.use_mssql_flag, sp.use_mssql_ready
FROM   migration.ServletPage sp
WHERE  sp.servlet = 'garbage_day';
```

`ServletPage.mssql_db` is the *primary* database only. The full set is in
`ServletTargetDatabases`, derived by static parse of the Java:

```sql
SELECT sp.project, sp.servlet, td.db_name, std.is_primary, std.object_names
FROM   migration.ServletPage sp
JOIN   migration.ServletTargetDatabases std ON std.servlet_page_id = sp.id
JOIN   migration.TargetDatabases td         ON td.target_db_id = std.target_db_id
WHERE  sp.servlet = 'assmts2';
```

## 2. Which Backend — the per-page `USE_MSSQL` flag

`DpwServletsPublicAll` and `DpwServletsPublic` pages each declare their own switch:

```java
@WebServlet(urlPatterns = {"/getAllStreets"})
public class getAllStreets extends DPWservlet2 {
    private static final boolean USE_MSSQL = false; // TODO: set true when MSSQL-verified

    public void doPost(...) {
        s = getPublicAppFactory(USE_MSSQL).getAllStreets();
    }
}
```

54 servlet source files carry this constant. `getPublicAppFactory(boolean)` keeps two cached
factories and picks one; passing `false` yields the Oracle-backed `AppImpl2`.

`DPWServletsInternal` does not use a per-page boolean. It selects per *statement* by prefixing
the target database, which `InternalAppImpl.execQueryVec` strips and routes on:

```java
public Vector<String[]> selectGeneric(String stm, String[] ss)      { return execQueryVec("USE DPWP; " + stm, ss); }
public Vector<String[]> selectGenericInfra(String stm, String[] ss) { return execQueryVec("USE InfrastructureProjects; " + stm, ss); }
```

So for internal pages, "which database" is decided by **which wrapper method the code calls** —
easy to get wrong, and invisible at the call site unless you read the method name carefully.

## 3. Which Environment — the `Database` enum, not a config file

This is the part most often misread. The environment is compiled in, at
[`util/dbConnections/enums/Database.java`](../../DPW_Includes_DataServer_MSSQL/src/util/dbConnections/enums/Database.java):

```java
GISDPW            ("GISDPW",            DbEnvironment.PROD),
LOGINDPW          ("LoginDPW",          DbEnvironment.PROD),
RESTRICTEDSTREETS ("RestrictedStreets", DbEnvironment.PROD),
STREETSIGNS       ("StreetSigns",       DbEnvironment.PROD),
CALLCENTER        ("CallCenter",        DbEnvironment.DEV),
ROADLIFE          ("RoadLife",          DbEnvironment.DEV),
// ...every other database is DEV
```

`DbEnvironment` maps each environment to a server: `DEV` → `sql-treas`, `PROD` → `sql-dpw3`,
`STAGING` → an Oracle URL.

Combined with `InternalAppImpl.MSSQL_PROD_ONLY = true`:

```java
public static boolean isOracle(String dbName) {
    Database db = Database.fromNameOrNull(dbName);
    if (MSSQL_PROD_ONLY) {
        if (db == null) return true;                    // unknown name -> Oracle
        if (db.getBackend() == Backend.ORACLE) return true;
        return db.getEnv() != DbEnvironment.PROD;       // not PROD -> Oracle
    }
    return backendFor(dbName) == Backend.ORACLE;
}
```

**The operative rule:** in a production deploy, only the four `PROD` databases actually reach SQL
Server. Everything else falls back to Oracle *regardless of whether its data has been migrated*
and regardless of the page's `USE_MSSQL` flag. Promoting a database to production is an enum
edit plus a rebuild — not a config change, not a restart.

Credentials come from
[`resources/db-connections.properties`](../../DPW_Includes_DataServer_MSSQL/resources/db-connections.properties),
keyed `<DbName>.<env>.user` / `<DbName>.<env>.password`, where `<DbName>` is exactly
`Database.getDbName()`. Servers are *not* in that file.

## Verification Checklist for a Page

Run through all four before declaring a page migrated:

1. **Enumerate its databases** — `ServletTargetDatabases`, not just `ServletPage.mssql_db`.
2. **Confirm every one of them is migrated** — join to `DbObjectTargetDatabases.migration_status`
   for the objects the page touches.
3. **Confirm every one is `DbEnvironment.PROD`** in the `Database` enum, if this is a production
   cutover. A `DEV` entry means the page silently reads Oracle in prod.
4. **Then** flip `USE_MSSQL` (public projects) or repoint the wrapper call (internal project).
5. Check `migration.RoutingFallbackLog` after exercising the page. New rows mean something
   resolved to `DPWP` by fallback rather than by an explicit mapping.

```sql
-- Pages whose flag is on: does every database they touch actually exist on the prod server yet?
SELECT sp.project, sp.servlet, td.db_name
FROM   migration.ServletPage sp
JOIN   migration.ServletTargetDatabases std ON std.servlet_page_id = sp.id
JOIN   migration.TargetDatabases td         ON td.target_db_id = std.target_db_id
WHERE  LOWER(LTRIM(RTRIM(sp.use_mssql_flag))) = 'true'
ORDER  BY sp.servlet, td.db_name;
```

## Landmines

**A single boolean cannot express a multi-database page.** 28 servlets touch more than one
database, and those databases migrate on different dates. `assmts2` spans four — `GISDPW`,
`SpecialAssessments`, `InfrastructureProjects`, `CallCenter`. Flipping its one `USE_MSSQL`
switches *all four* at once. Any page with more than one target needs its databases verified
together, or the flag needs splitting. The worst offenders:

| Servlet | Databases |
|---|---|
| `assmts2` | GISDPW, SpecialAssessments, InfrastructureProjects, CallCenter |
| `CollectionScheduleInfo`, `garbage_day`, `garbageDayService` | GISDPW, SpecialAssessments, CallCenter |
| `np_confirmation`, `rpp_permission` | GISDPW, CallCenter, StreetSigns |
| `osr` | GISDPW, CallCenter, DNSCertifications |

**`use_mssql_ready` is not maintained.** 101 of 102 rows are `False`, including all 14 pages that
already have `use_mssql_flag = 'true'`. Only one row has ever been set `True`. Treat the column
as unpopulated — it is not a safety check, and "ready is False" currently means nothing. Do not
write a gate against it without populating it first.

**Both flag columns are text, not `bit`.** They hold `'true'`, `'false'`, and `'n/a'`. Comparing
them to `1` throws *"Conversion failed when converting the nvarchar value 'true' to data type
int."* Always compare lowercased strings.

**The same servlet name exists in more than one project.** `rpp_permission`, `np_permission`,
`garbage_day` and `CollectionScheduleInfo` all appear in both `DpwServletsPublic` and
`DpwServletsPublicAll`, sometimes with different database sets. Always filter on `project`.

**`DPWServletsInternal` unknown names fail silently to Oracle.** `Database.fromNameOrNull`
returning `null` makes `isOracle` return `true`. A typo in a `USE <db>;` prefix does not raise —
it just routes to Oracle.

**`connection_type = 'jndi'` is recorded for 15 `DpwServletsPublic` pages, but no `<resource-ref>`
exists in that project's `web.xml`.** One of the two is wrong; verify against the running Tomcat
before relying on either.

**Hardcoded connection details bypass all of the above.** `DPWservlet.java`, `GenericServer.java`
(both the Oracle and MSSQL variants), and `testdb.java` contain literal JDBC URLs and credentials,
and `GenericServer` additionally selects an environment by comparing `InetAddress.getLocalHost()`
against hardcoded hostnames and IPs. Pages reaching the database through these paths ignore the
`Database` enum entirely. Audit them separately.
