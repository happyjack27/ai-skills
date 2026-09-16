---
name: workday-citytime-integration
description: 'This skill should be used when working on the City of Milwaukee CityTime integration with Workday or Time and Labor data, especially the DPW_CitytimeSSO desktop application, CityTime SQL schema, PeopleSoft-style PS_ tables, employee imports/exports, crew-to-supervisory-organization mapping, Entra ID configuration related to the Workday-facing app, or determining whether a Workday data-transfer feature is implemented.'
---

# CityTime Workday Integration

## Purpose

Document the verified boundary between Workday/Time and Labor data, the CityTime SQL Server
schema, the `DPW_CitytimeSSO` desktop application, and the older CityTime backend. Use this skill
to investigate or implement employee data imports, exports, crew and supervisory-organization
mapping, or Workday-facing authentication and database behavior.

## Routing Boundaries

- Use this skill for Workday-to-CityTime data contracts, `PS_` tables, employee/crew mapping,
	`DPW_CitytimeSSO`, `DPW_Citytime_Workday_Integration`, or questions about the import/export
	workflow.
- Pair with [`../../dpw-migration/migration-operations/SKILL.md`](../../dpw-migration/migration-operations/SKILL.md) when the task changes SQL
	Server migration, database routing, converted RMI servers, or environment/cutover behavior.
- Use the Java skill for generic Java questions and the SQL skill for general SQL authoring;
	this skill supplies the CityTime/Workday-specific facts.
- Treat SFTP as an external operational boundary. `DPW_Citytime_Workday_Integration` reads and
	writes mounted transfer folders; it contains no SFTP client or scheduler. Confirm the external
	SFTP service, mount, and job configuration separately.

## Workflow

1. Identify the direction: Workday into CityTime, CityTime export, employee lookup, time/labor
	 reporting, or crew/supervisory-organization reconciliation.
2. Read [`references/data-contract.md`](references/data-contract.md) for the relevant tables,
	 join keys, intermediate mapping tables, and SQL dialect warnings.
3. Read [`references/implementation-status.md`](references/implementation-status.md) before
	 describing current behavior or adding an integration path. Separate the implemented file-based
	 transfer program from the SSO application, schema snapshots, and manual utilities.
4. Inspect the source project named in the request. Treat
	 `DPW_CitytimeSSO/README.md`, its Maven configuration, and its resource properties as the
	 application-level source of truth; treat the CityTime SQL schema script as a dated contract
	 snapshot that must be checked against the live target before changes.
5. Preserve employee identifiers and effective-dated semantics. In particular, use
	 `PS_EMPLOYMENT.EMPLID` to join imported employee rows and treat `Y_CREW_ID` as a mapping key,
	 not as a supervisory organization.
6. Preserve ambiguity evidence in crew mappings. The existing workflow records best, average,
	 worst, and tied match counts; do not silently discard ties when replacing it with automation.
7. Validate changes with a non-production CityTime database and the narrowest relevant build or
	 SQL verification. Avoid exposing tenant/client configuration or credentials in logs,
	 documentation, or generated output.

## Key Facts

- `DPW_Citytime_Workday_Integration` is the actual Java transfer program. It imports inbound CSVs
	from a mounted folder into CityTime and exports outbound DTICKET CSVs to another mounted folder.
- `DPW_CitytimeSSO` is a separate Java 8 Swing/Entra ID application; do not confuse its identity
	flow with the Workday file-transfer process.
- The CityTime data contract uses PeopleSoft-style tables such as `PS_JOB`, `PS_EMPLOYMENT`,
	`PS_NAMES`, `PS_LEAVE_ACCRUAL`, and `PS_Y_TRC_UNION_TBL`.
- `DPW_Citytime_MSSQL/notes/crew-suporg-math.sql` describes a manual spreadsheet import and
	employee-to-crew/supervisory-organization correlation workflow.
- `DPW_Includes_DataServer_MSSQL` contains shared CityTime query translation and routing code;
	it is not itself evidence of a Workday API or scheduled exchange.

## Verification

Build the desktop project from `DPW_CitytimeSSO` with:

```powershell
mvn clean package
```

For schema or mapping work, review the SQL dialect and target database first. Execute data changes
only in an approved non-production environment until the import/export contract, duplicate policy,
effective-date rules, and operational schedule are explicitly established.
