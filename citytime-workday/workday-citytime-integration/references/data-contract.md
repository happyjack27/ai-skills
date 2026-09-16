# CityTime Workday Data Contract

## System boundary

The Workday-facing CityTime application is `DPW_CitytimeSSO`. The checked-in project is a Java 8 desktop Swing application. The SQL schema and legacy CityTime code use PeopleSoft-style `PS_` table names even though the source data is described as Workday/Time and Labor data.

The primary target database is SQL Server `CityTime`. The source-side schema referenced by the crew mapping utility is `tandl`.

## Core tables

The schema script at `DPW_Citytime_MSSQL/integration notes/table_schema_for_workday_to_citytime.sql` defines the principal employee and time/labor data contract:

| Table | Domain | Important fields |
|---|---|---|
| `ACC` | Accounts and earnings/account assignments | `GROUP_ID`, `ACCOUNT`, `JOBCODE`, `ERNCD`, `SHIFT`, `EMPLID` |
| `PS_ADDRESSES` | Effective-dated employee addresses | `EMPLID`, `EFFDT`, `ADDRESS_TYPE`, address and postal fields |
| `PS_DEPT_TBL` | Departments | `DEPTID`, `EFFDT`, `DESCR` |
| `PS_EARNINGS_TBL` | Earnings codes | `ERNCD`, `EFFDT`, `PAYMENT_TYPE`, `Y_INPUT_EC_CAT`, tax flags |
| `PS_EMPLOYMENT` | Employment and crew assignment | `EMPLID`, `EMPL_RCD#`, `Y_CREW_ID`, `PHONE` |
| `PS_JOB` | Effective-dated jobs and rates | `EMPLID`, `EFFDT`, `DEPTID`, `JOBCODE`, status/type, rates, union and location fields |
| `PS_JOBCODE_TBL` | Job-code descriptions and classifications | `JOBCODE`, `EFFDT`, `DESCR`, `GRADE`, `STEP`, `UNION_CD` |
| `PS_LEAVE_ACCRUAL` | Leave balances | `EMPLID`, `EMPL_RCD#`, `PLAN_TYPE`, accrual and carryover fields |
| `PS_LOCATION_TBL` | Work locations | `LOCATION`, `EFFDT`, `DESCR`, address fields |
| `PS_NAMES` | Effective-dated names | `EMPLID`, `EFFDT`, `NAME`, `NAME_TYPE` |
| `PS_UNION_TBL` | Union descriptions | `UNION_CD`, `EFFDT`, `DESCR` |
| `PS_Y_ACCT_CD_TBL` | Accounting/project codes | `SETID`, `PROGRAM_CODE`, `PROJECT_ID`, `ACCT_CD`, `ACCOUNT`, `FUND_CODE`, `DEPTID` |
| `PS_Y_TRC_UNION_TBL` | Time-reporting codes by union | `UNION_CD`, `Y_TIME_RPTG_CD`, `EMPL_TYPE`, `ERNCD`, shift flags |

Treat the SQL script as the authoritative schema snapshot. Confirm current database definitions before changing production code; the script is dated October 2024.

## Crew and supervisory organization mapping

`DPW_Citytime_MSSQL/notes/crew-suporg-math.sql` documents a manual five-step workflow:

1. Import the received Workday spreadsheet into `dpw.temp_workday_orgs`.
2. Normalize `supervisory_organization` and derive `org_code`.
3. Join spreadsheet `employee_id` to `tandl.ps_employment.emplid` and aggregate counts by `y_crew_id` and supervisory organization into `dpw.temp_suporg_crew_cross`.
4. Populate `temp_crew_suporg` and `temp_suporg_crew`, selecting the minimum supervisory organization or crew among tied best matches and recording tie/count statistics.
5. Export both conversion tables for review or downstream use.

`PS_EMPLOYMENT.Y_CREW_ID` is the bridge between an employee and CityTime crew data. Do not assume a crew has one unambiguous supervisory organization: the workflow explicitly records `ties_for_first`, `best_total`, `avg_total`, and `worst_total`.

## Integration database contract

The Java transfer program depends on an `integration` schema in `CityTime`. The following objects
are called or queried by source and must be treated as part of the application contract:

- `integration.TableIntegrationRules` - active table list, schedule type, expected row count,
  import type, and notification recipients.
- `integration.FROM_WORKDAY_<TABLE>` - per-table inbound staging target.
- `integration.importStart` - opens an import log and returns an import ID/number.
- `integration.importUpdate` - records import progress, row counts, pass/failure state, and errors.
- `integration.doTableUpdates` - applies staged rows after insertion.
- `integration.ImportLogDetail` - detailed status/error rows used for post-import decisions and mail.
- `integration.VW_DTICKET_EXPORT` - outbound time/attendance export view.
- `integration.getLastPP` - returns the default year/pay period for export.

The exact procedure signatures and staging-table columns are not defined in the Java repository;
inspect the target CityTime database before changing the CSV contract or calling convention.

## SQL dialect caution

The schema snapshot uses SQL Server DDL, while `crew-suporg-math.sql` contains Oracle-style syntax and objects such as `NVARCHAR2`, `NUMBER`, `SUBSTR`, and `LENGTH`. Treat the crew script as a source-side/manual utility unless it has been ported and tested for the target engine.
