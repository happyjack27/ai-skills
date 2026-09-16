# CityTime Workday Implementation Status

## Implemented and verified in source

### DPW_Citytime_Workday_Integration

This is an Eclipse Java project, not a Maven project. Its classpath includes the SQL Server JDBC
driver and JavaMail/activation JARs. The source contains no JSch, SSH, SFTP, FTP, scheduler, or
remote API client. File transfer is therefore an external deployment concern: the program reads
and writes folders that are presumably populated or collected by an SFTP service, mount, or job.

#### Inbound Workday import

`ImportFromWorkday` implements the inbound pipeline:

1. Select a table directly, or select a schedule (`Hourly`, `Daily`, `Weekly`, `BiWeeekly`).
2. For a schedule, query active rows from `[integration].[TableIntegrationRules]`.
3. Build the source path from `K:\workday_samples\` on Windows or
	`/home/workday/Transfers/FromWorkDay/` on Linux. Add `sql-dev`, `sql-stg`, or `sql-itmd`
	beneath `Transfers` for non-production environments.
4. Start an import with `[integration].[importStart]`.
5. Read `<table>[_test].csv`, parse comma-separated rows with quoted-field handling, and add
	`IMPORT_NUMBER` and `IMPORT_ROW` columns. Rename an incoming `EMPL_RCD` header to
	`[EMPL_RCD#]`.
6. Insert batches of 100 rows into `[integration].[FROM_WORKDAY_<TABLE>]`.
7. Use `TableIntegrationRules.ExpectedRows` and `ImportType` to reject a suspiciously small
	full import (fewer than half the expected rows).
8. Record progress and failures through `[integration].[importUpdate]`, then call
	`[integration].[doTableUpdates]` to apply the staged data.
9. Query `[integration].[ImportLogDetail]`, send failure mail when needed, and move the source
	file into `Imported` or `Failed` with a date/import-number suffix.

The no-argument default currently processes only `ps_leave_accrual_test`; the `all` mode scans
CSV files in the inbound folder. The test suffix is controlled by the source code's production
flag and should not be inferred from the environment name alone.

#### Outbound CityTime export

`ExportToWorkday` queries `[integration].[VW_DTICKET_EXPORT]` for a pay period and year, writes a
quoted CSV named `DTICKET_<year>_<pp>.csv`, and places it under the environment-specific
`ToWorkDay` folder (`K:\workday_samples\` on Windows or `/home/workday/Transfers/ToWorkDay/` on
Linux). With no year/pay-period arguments it calls `[integration].[getLastPP]` first. The output
contract contains 36 columns, including employee, pay-period, worked-date, job, union, hours,
earnings, accounting, approval/status, and `SupOrg`, `Program`, and `ProjectGrant` fields.

#### Operational notifications

Import failure and optional success notices are sent through `DPWMailer1` to the local SMTP relay
(`localhost`). Recipients come from `TableIntegrationRules.NotifyOnFailure` or
`NotifyOnSuccess`, with a source-code fallback address. The importer also appends a plain-text
`importLog` file in the inbound transfer folder.

### DPW_CitytimeSSO

The application is a Java 8 desktop Swing project using:

- Maven and Ant build files.
- MSAL4J 1.14.2 for Microsoft Entra ID sign-in.
- Microsoft SQL Server JDBC 12.4.2 for database access.
- JExcelAPI 2.6.12 for existing spreadsheet/report support.
- JUnit 5 test dependencies.

Configuration is in `src/main/resources/application.properties`, with environment-variable overrides:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_REDIRECT_URI`
- `AZURE_SCOPES`

The README documents `mvn clean package` and running the generated JAR. Do not treat the checked-in tenant/client identifiers as credentials; obtain deployment configuration from the approved environment.

### Existing CityTime backend

`DPW_Includes_DataServer_MSSQL` contains the shared CityTime server and SQL translation layer:

- `GenericServer` contains legacy CityTime query and employee lookup behavior.
- `Checker` rewrites `tandl.`/`TANDL.` and related schema prefixes for SQL Server translation.
- `RoutingChecker` and `DPWConnectionFactory` control database routing and connections.
- CityTime development and staging use dedicated SQL Server environments; consult the `Database` and `DbEnvironment` enums rather than assuming the shared DPW migration server.

Use the [`migration-operations`](../../../dpw-migration/migration-operations/SKILL.md) skill alongside this skill when the task concerns database routing, SQL Server migration, or converted RMI behavior.

## Not yet demonstrated in checked-in source

The repository does not contain the SFTP transport or job orchestration around the Java transfer
program. Specifically, do not claim that the checked-in integration project contains:

- A Workday REST, SOAP, RaaS, Studio, or SFTP client.
- A scheduler or cron configuration.
- A production-grade outbound export protocol.
- Automated crew-to-supervisory-organization reconciliation.

The current evidence supports this statement: Java code implements the database-facing CSV import
and export steps, while an external SFTP/mount layer must deliver and collect those files. The
database procedures and views are part of the operational contract but are not defined in this
Java repository.

## Build and verification

From `DPW_CitytimeSSO`:

```powershell
mvn clean package
java -jar target\dpw-citytime-sso-0.0.1-SNAPSHOT.jar
```

`DPW_Citytime_Workday_Integration` has Eclipse metadata and compiled output under `bin/`, but no
checked-in Maven/Ant build. Build it with the workspace's Java/Eclipse project configuration or
an equivalent `javac` classpath containing the checked-in JDBC and JavaMail dependencies. Validate
against a non-production CityTime database and test both successful and failed archive moves.

For the SQL contract, review and test the schema script against a non-production `CityTime` database. For crew mapping, review the source/target dialect before execution and preserve the intermediate tables and tie statistics for auditability.

## Source files

- `DPW_CitytimeSSO/README.md`
- `DPW_CitytimeSSO/pom.xml`
- `DPW_CitytimeSSO/src/main/resources/application.properties`
- `DPW_Citytime_Workday_Integration/.classpath`
- `DPW_Citytime_Workday_Integration/.project`
- `DPW_Citytime_Workday_Integration/src/ImportFromWorkday.java`
- `DPW_Citytime_Workday_Integration/src/ExportToWorkday.java`
- `DPW_Citytime_Workday_Integration/src/CitytimeDB.java`
- `DPW_Citytime_Workday_Integration/src/DPWMailer1.java`
- `DPW_Citytime_MSSQL/integration notes/table_schema_for_workday_to_citytime.sql`
- `DPW_Citytime_MSSQL/notes/crew-suporg-math.sql`
- `DPW_Includes_DataServer_MSSQL/src/GenericServer.java`
- `DPW_Includes_DataServer_MSSQL/src/util/sqlParsing/Checker.java`
