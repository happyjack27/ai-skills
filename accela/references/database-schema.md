# Accela Database Schema Reference (Milwaukee `AAPROD` on `SQL-DEV`)

Verified 2026-08-05 by querying `INFORMATION_SCHEMA` and `sys.sql_modules` directly against the
`sql-dev ACCELAPROD` snapshot (server `SQL-DEV`, database `AAPROD`, ~1,300 tables). Everything
below is confirmed by live query, not assumed from generic Accela docs — column names and joins in
particular differ from what public Accela documentation implies, so trust this file over intuition.

**Always connect read-only.** This is a snapshot for research, not the record of truth — never run
writes against it. Use the `mssql_*` tools with the saved profile `sql-dev ACCELAPROD`
(`profileId 2c5e9367-ce23-47e9-a1d4-088e19acd981`, server `SQL-DEV`, database `AAPROD`).

## Naming Convention Decode

Table/column prefixes are meaningful once you know the pattern:

| Prefix | Meaning |
|---|---|
| `R` (e.g. `R3APPTYP`, `RINSPTYP`, `RFEE_SCHEDULE`) | Reference/definition table — the configured setup, not transactional data |
| `X` (e.g. `XRINSPTYP`, `XAPPTYP_FEESCHEDULE`) | Cross-reference/junction table linking two reference tables |
| `G` (e.g. `G3DPTTYP`, `GASSET_INSPECTION`) | General/group config table |
| `B` (e.g. `BCHCKBOX`, `BAPPSPECTABLE_VALUE`) | Business/transactional data table (per-record data) |
| `S` (e.g. `SPROCESS`, `SPROCESS_DEF`, `SINSP_PROCESS`) | Process/workflow-instance-related table |
| `V_` | View — often a pre-built join worth reading with `sys.sql_modules` before hand-rolling the same join |
| `R1_`, `R3_`, `R6_`, `R7_` (column prefixes) | Column added in a given Accela release; **not** a semantic grouping — e.g. `R1_PER_TYPE` and `R3_AGENCY_CODE` can appear side-by-side on the same table |
| `SERV_PROV_CODE` | Service provider code — the agency/tenant key (`MILWAUKEE`), present on nearly every table |
| `REC_STATUS` | Soft-delete/active flag: `'A'` = active, `'I'` = inactive. Always filter on it |
| `REC_DATE`, `REC_FUL_NAM` | Audit columns: last-modified date and user |

⚠️ Some views in this database appear stale relative to the current table split (e.g.
`V_CONFIG_WORKFLOW` selects `SP.SD_PRO_DES`/`SP.ASGN_FNAME` etc. from an alias on `SPROCESS`, but
those columns actually live on `SPROCESS_DEF`, not `SPROCESS`). Don't trust a view's column
provenance at face value — verify against `INFORMATION_SCHEMA.COLUMNS` for the table it actually
joins, or just query the base tables directly per the recipes below.

## Record Type — `R3APPTYP`

The record type definition. Key = `SERV_PROV_CODE` + the 4-part type:

| Column | Meaning |
|---|---|
| `R1_PER_GROUP` | Module (e.g. `Enforcement`) |
| `R1_PER_TYPE` | Type (e.g. `Complaint`) |
| `R1_PER_SUB_TYPE` | SubType (e.g. `Sanitation`) |
| `R1_PER_CATEGORY` | Category (e.g. `Construction Material`) |
| `R1_APP_TYPE_ALIAS` | Display alias shown in the UI |
| `R1_PROCESS_CODE` | Workflow template code → join to `SPROCESS_GROUP.SPROCESS_GROUP_CODE` |
| `R1_SMARTCHOICE_CODE` | ASI (custom field) group code → join to `SMARTCHOICE.GROUP_CODE` |
| `R1_UDCODE1` | Inspection group code → join to `RINSPTYP.INSP_CODE` |
| `R1_FEE_CODE` | Fee schedule code |
| `APP_DEFAULT_STATUS_CODE` | Default status on record creation |
| `R1_MODULE_NAME` | Underlying Accela module (Building/Licensing/Enforcement/etc.) |
| `IS_RENEWAL`, `RENEWAL_*` | Renewal-record wiring, if applicable |

The 4-part key is exactly the `Module!Type!SubType!Category` string used in EMSE filenames
(`~` = wildcard/NA there) and in `appMatch('Module/Type/SubType/Category')` calls in script code.

```sql
SELECT R1_PER_GROUP, R1_PER_TYPE, R1_PER_SUB_TYPE, R1_PER_CATEGORY,
       R1_APP_TYPE_ALIAS, R1_PROCESS_CODE, R1_SMARTCHOICE_CODE, R1_UDCODE1,
       R1_FEE_CODE, APP_DEFAULT_STATUS_CODE
FROM R3APPTYP
WHERE REC_STATUS = 'A'
  AND R1_PER_GROUP = 'Enforcement' AND R1_PER_TYPE = 'Complaint'
  AND R1_PER_SUB_TYPE = 'Sanitation' AND R1_PER_CATEGORY = 'Construction Material';
```

## Workflow — `SPROCESS_GROUP`, `SPROCESS`, `SPROCESS_DEF`, `R3STATYP`

⚠️ **Corrected 2026-08-05** — an earlier pass at this file had `SPROCESS`/`SPROCESS_DEF` reversed.
Verified directly against `INFORMATION_SCHEMA.COLUMNS` for both tables; the facts below are right.

- `SPROCESS_GROUP` links a record type's `R1_PROCESS_CODE` to a `SPROCESS_GROUP_CODE`.
- `SPROCESS_DEF` (`R1_PROCESS_CODE`, `R1_SPROCESS_DEFINITION`) is the workflow template header —
  only 6 columns (`SERV_PROV_CODE`, `R1_PROCESS_CODE`, `REC_DATE`, `REC_STATUS`, `REC_FUL_NAM`,
  `R1_SPROCESS_DEFINITION`), no task detail.
- `SPROCESS` holds the actual tasks/steps: `SD_STP_NUM` (step #), `SD_PRO_DES` (task name),
  `SD_NXT_ID1` (next-step routing), `SD_APP_COD`/`SD_APP_DES`, `SD_STAT_COD`/`SD_STAT_DES` (status
  set on completion), `ASGN_AGENCY_CODE`/`ASGN_BUREAU_CODE`/`ASGN_DIVISION_CODE`/
  `ASGN_GROUP_CODE`/`ASGN_SECTION_CODE`/`ASGN_OFFICE_CODE` + `ASGN_FNAME`/`ASGN_MNAME`/`ASGN_LNAME`
  (default assignment group/individual — this is the "who does auto-assign resolve to" answer for
  workflow tasks), `SD_DUE_DAY`.
- `R3STATYP` holds the record-level status vocabulary per process: `R3_APP_TYP_CODE` (in practice
  often `NULL` — the effective key is just `SERV_PROV_CODE` + `R3_PROCESS_CODE`, don't filter on
  `R3_APP_TYP_CODE`), `R3_PROCESS_CODE`, `R3_ACT_STAT_COD`/`R3_ACT_STAT_DES` (status code/label),
  `PARENT_STATUS`, `APPLICATION_STATUS` (the record-level status a task status rolls up to — check
  this before assuming a given `wfStatus` does or doesn't close the record). Scripts branch on the
  exact `R3_ACT_STAT_DES` text via `wfStatus`, so confirm exact label spelling/casing here before
  writing a script condition.
- `G3DPTTYP` is the assignment-group hierarchy (`R3_AGENCY_CODE`/`R3_BUREAU_CODE`/
  `R3_DIVISION_CODE`/`R3_SECTION_CODE`/`R3_GROUP_CODE`/`R3_OFFICE_CODE` → `R3_DEPTNAME`,
  `R3_DEPT_KEY`) — join `SPROCESS.ASGN_*` to this to resolve a task's default assignment to a
  human-readable department name.

```sql
-- All workflow tasks for a record type's process, in step order, with default assignment
SELECT sd.SD_STP_NUM, sd.SD_PRO_DES AS TaskName, sd.SD_DUE_DAY,
       sd.SD_STAT_COD, sd.SD_STAT_DES,
       g.R3_DEPTNAME AS DefaultAssignedDept,
       sd.ASGN_FNAME, sd.ASGN_LNAME
FROM R3APPTYP rat
JOIN SPROCESS_GROUP spg ON spg.SPROCESS_GROUP_CODE = rat.R1_PROCESS_CODE
                        AND spg.SERV_PROV_CODE = rat.SERV_PROV_CODE
JOIN SPROCESS sd ON sd.R1_PROCESS_CODE = spg.R1_PROCESS_CODE
                 AND sd.SERV_PROV_CODE = spg.SERV_PROV_CODE
LEFT JOIN G3DPTTYP g ON g.SERV_PROV_CODE = sd.SERV_PROV_CODE
                     AND g.R3_AGENCY_CODE = sd.ASGN_AGENCY_CODE
                     AND g.R3_BUREAU_CODE = sd.ASGN_BUREAU_CODE
                     AND g.R3_DIVISION_CODE = sd.ASGN_DIVISION_CODE
                     AND g.R3_GROUP_CODE = sd.ASGN_GROUP_CODE
                     AND g.R3_SECTION_CODE = sd.ASGN_SECTION_CODE
                     AND g.R3_OFFICE_CODE = sd.ASGN_OFFICE_CODE
WHERE rat.REC_STATUS = 'A' AND sd.REC_STATUS = 'A'
  AND rat.R1_PER_GROUP = 'Enforcement' AND rat.R1_PER_TYPE = 'Complaint'
  AND rat.R1_PER_SUB_TYPE = 'Sanitation' AND rat.R1_PER_CATEGORY = 'Construction Material'
ORDER BY sd.SD_STP_NUM;
```

## Inspections — `RINSPTYP`, `RINSP_RESULT_GROUP`, `XRINSPTYP`

- `RINSPTYP` = inspection type/group definition. Key columns: `INSP_CODE` (group code — this is
  what `R3APPTYP.R1_UDCODE1` points to), `INSP_TYPE` (display name, e.g. `San. Inspection`),
  `INSP_RESULT_GROUP` (→ `RINSP_RESULT_GROUP.INSP_RESULT_GROUP`), `INSP_REQUIRED`,
  **`AUTO_ASSIGN`** (the actual auto-assign flag — confirm this is `'Y'`/set before assuming a new
  inspection type will auto-assign), `GUIDE_GROUP` (guidesheet), `DISPLAY_IN_ACA`,
  `INSP_GROUP_NAME`.
- `RINSP_RESULT_GROUP` = the list of valid result values for a result group: `INSP_RESULT_GROUP`,
  `INSP_RESULT` (the actual result string scripts compare against), `INSP_RESULT_TYPE`,
  `RESULT_CATEGORY`. **A result value not present in this table for the record's result group does
  not exist yet — that's an Admin-only addition, not something a script can create.**
- `XRINSPTYP` = auto-follow-up-inspection scheduling rules keyed off a specific result:
  `PARENT_SEQ_NBR` + `INSP_RESULT` → `CHILD_SEQ_NBR`, `IS_AUTO`, `INTERVAL_DAY`/`INTERVAL_MONTH`/
  `INTERVAL_YEAR`, `INIT_STATUS`. This is where "does result X auto-schedule inspection Y in N
  days" configuration lives, separate from anything a script does.

```sql
-- Inspection types and result options available to a record type
SELECT rit.INSP_CODE, rit.INSP_TYPE, rit.AUTO_ASSIGN, rit.INSP_REQUIRED, rit.GUIDE_GROUP,
       rirg.INSP_RESULT, rirg.INSP_RESULT_TYPE
FROM R3APPTYP rat
JOIN RINSPTYP rit ON rit.INSP_CODE = rat.R1_UDCODE1 AND rit.SERV_PROV_CODE = rat.SERV_PROV_CODE
JOIN RINSP_RESULT_GROUP rirg ON rirg.INSP_RESULT_GROUP = rit.INSP_RESULT_GROUP
                             AND rirg.SERV_PROV_CODE = rit.SERV_PROV_CODE
WHERE rat.REC_STATUS = 'A' AND rit.REC_STATUS = 'A' AND rirg.REC_STATUS = 'A'
  AND rat.R1_PER_GROUP = 'Enforcement' AND rat.R1_PER_TYPE = 'Complaint'
  AND rat.R1_PER_SUB_TYPE = 'Sanitation' AND rat.R1_PER_CATEGORY = 'Construction Material'
ORDER BY rit.INSP_TYPE, rirg.INSP_RESULT_DISPLAY_ORDER;
```

Note: in practice one `RINSPTYP`/`INSP_CODE` inspection group is often **shared across several
sibling record types** (e.g. all `Enforcement/Complaint/Sanitation/*`), so a result set you find
here may be broader than what one specific category actually uses — confirm with the user which
subset is intended for this category before assuming every listed result applies.

## ASI Custom Fields — `SMARTCHOICE`, `SMARTCHOICE_GROUP`, `SMARTCHOICE_OPTION`, `BAPPSPECTABLE`

⚠️ **Corrected 2026-08-05** — `SMARTCHOICE.BLOCK_NAME` is **not** a per-field custom-field label.
Verified against real data: for ASI group `PW_COMP`, `BLOCK_NAME` values are section/tab visibility
toggles (`CAPDETAIL`, `ADDRESS`, `PARCEL`, `OWNER`, `APPLICATION SPECIFIC INFO`, `DOCUMENT`, etc.).
`DISPLAY_FLG`/`REQUIRED_FLG` there control whether that whole section shows/is required on the
record, not an individual field. Don't use this table to answer "what custom fields exist for this
group" — it answers "what sections show up on the record" instead.

- `SMARTCHOICE_GROUP` — group code shell (`GROUP_CODE`).
- `SMARTCHOICE` — per-section display config: `GROUP_CODE`, `BLOCK_NAME` (section name, not a
  field), `DISPLAY_FLG`, `VALIDATE_FLG`, `REQUIRED_FLG`, `DISPLAY_ORDER`, `DEFAULT_VALUE`.
- `SMARTCHOICE_OPTION` — picklist options, but scoped to whatever `SMARTCHOICE` actually
  represents here — re-verify before relying on this for field-level picklists.
- `BAPPSPECTABLE` — the actual per-record ASI **field values** (`B` prefix = business/transactional,
  matches the naming convention above): `GROUP_NAME`, `COLUMN_NAME` (the field name, e.g. `Cubic
  Yards`), `COLUMN_TYPE`, `B1_ATTRIBUTE_VALUE`. This proves a field exists/was used on a record, but
  it's transactional data, not the reference definition of the group's field schema.
- **The reference table that defines "what ASI/custom fields exist for group X, with what
  types/options" has not been identified in this database yet.** `editAppSpecific("Cubic
  Yards", ...)` calls work in production scripts, so the field exists somewhere and is configured
  through Accela Admin — just don't have the backing reference table confirmed. If you find it,
  correct this note.
- **A 0-row result on `BAPPSPECTABLE` for a given `COLUMN_NAME` does not necessarily mean the field
  doesn't exist or that something's wrong.** `BAPPSPECTABLE` only holds a row once that field has
  actually been *saved with a value* on at least one real record — a field can be fully configured
  in Accela Admin and referenced correctly by a script (`editAppSpecific("Cubic Yards", ...)`) and
  still have zero rows here simply because that code path has never run in production yet. Don't
  treat this the same as the `R1_FEE_CODE`/`R1_GF_COD` case above (a genuine documentation bug that
  caused a wrong-column exact match) — confirm which situation you're in by checking whether the
  *script* referencing the field is live/reachable before concluding the field itself is missing.

## Fees — `RFEE_SCHEDULE`, `RFEEITEM`, `XAPPTYP_FEESCHEDULE`

⚠️ **Corrected 2026-08-05, then corrected AGAIN 2026-08-05** — the column *names* in the first
correction were right, but the two codes' roles were documented backwards. Verified directly this
time (`SELECT ... WHERE R1_FEE_CODE = 'PW_SAN_COMP_CC'` returns the full `PWDC*`/`PWCC*` item list):

- **`R1_FEE_CODE`** = the fee **schedule/group** code (e.g. `PW_SAN_COMP_CC`) — this is the 2nd
  argument to the EMSE `addFee(feeCode, groupCode, ...)` call, confusingly.
- **`R1_GF_COD`** = the individual **fee item** code (e.g. `PWDC007`) — this is `addFee`'s 1st
  argument. `R1_GF_DES` is that item's description (e.g. `Late Fee`), `R1_GF_FIX` its flat amount.
- An exact filter like `WHERE R1_FEE_CODE IN ('PWDC004','PWDC007')` will silently return **0 rows**
  — those are `R1_GF_COD` values, not `R1_FEE_CODE` values. This is exactly the mistake that looked
  like a data anomaly earlier; it wasn't one, the column roles were just swapped in this doc.
- `R1_FEE_CODE_STATUS` and `REC_STATUS` both exist on the row — check both before assuming a fee
  item is active. `R1_GF_AUTO_INVOICED_FLAG`, `R1_GF_AUTO_ASSESS_FLAG`, `R1_EFFECT_DATE`/
  `R1_EXPIRE_DATE` round out the row.
- `RFEEITEM` — the fee item catalog, `RFEEITEM_GROUP` for grouping.
- `RFEE_SCHEDULE` — named fee schedules; `XAPPTYP_FEESCHEDULE` cross-references a record type to
  its schedule(s).
- Confirm a fee code exists and is active (`REC_STATUS='A'`) in `RFEEITEM` before a spec assumes it
  can just be invoiced — adding/activating a fee item is Admin config, not a script change.

```sql
-- List every fee item in a schedule (filter on R1_FEE_CODE = the SCHEDULE code, not the item code)
SELECT DISTINCT R1_GF_COD, R1_GF_DES, R1_GF_FIX, REC_STATUS, R1_FEE_CODE_STATUS
FROM RFEEITEM
WHERE R1_FEE_CODE = 'PW_SAN_COMP_CC'
ORDER BY R1_GF_COD;
```

## EMSE Script Registration — `REVT_EVENT`, `REVT_MASTER_SCRIPT`, `XEXPRESSION_EMSE_SCRIPT`

- `REVT_EVENT` — the catalog of event hook names EMSE can fire on.
- `REVT_MASTER_SCRIPT` — actual deployed script source per agency (`MASTER_SCRIPT_TEXT`). This
  confirms scripts are loaded into the DB from files (via Accela Admin's Script Manager / the
  `accela_scripts` deployment step), not read live off disk.
- `XEXPRESSION_EMSE_SCRIPT` — links a named expression/script to a `SCRIPT_CODE`.
- In this Milwaukee setup, event-to-record-type binding for the `Scripts/Event/*.js` files is done
  by the **filename convention itself** (`Prefix;Module!Type!SubType!Category.js`, see
  [`emse-scripts.md`](emse-scripts.md)) — you generally do not need to hand-register a new script
  file's event/record-type binding separately, but a **new script file still has to be
  deployed/loaded** (copied to `accela_scripts`) before it takes effect; it does nothing sitting
  only in `accela-test`.

## Useful System Queries

```sql
-- Find a table by a keyword when unsure of the exact name
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%KEYWORD%' ORDER BY TABLE_NAME;

-- List a table's columns in order, compactly
SELECT STRING_AGG(COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION) AS cols
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TABLE_NAME_HERE';

-- Read a view's real join logic instead of guessing (verify it isn't stale, see caveat above)
SELECT m.definition FROM sys.sql_modules m JOIN sys.objects o ON m.object_id = o.object_id
WHERE o.name = 'VIEW_NAME_HERE';
```
