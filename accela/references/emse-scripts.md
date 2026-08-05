# EMSE Event Scripts — Naming, Lifecycle, Deployment

## File Naming Convention

`Scripts/Event/<Prefix>;<Module>!<Type>!<SubType>!<Category>.js`

- The 4 segments after `;` are the record type, separated by `!` — matches
  `R3APPTYP.R1_PER_GROUP!R1_PER_TYPE!R1_PER_SUB_TYPE!R1_PER_CATEGORY` (see
  [`database-schema.md`](database-schema.md)).
- `~` in any segment = wildcard/NA for that segment (matches any value, or a record type where
  that segment is literally `NA`). E.g. `WTUA;ENFORCEMENT!COMPLAINT!SANITATION!~.js` fires for
  every category under `Enforcement/Complaint/Sanitation`.
- More specific files win over wildcard ones for the same event — a dedicated
  `IRSA;ENFORCEMENT!COMPLAINT!SANITATION!CONSTRUCTION MATERIAL.js` fires instead of/in addition to
  `IRSA;ENFORCEMENT!COMPLAINT!SANITATION!~.js` depending on how Accela resolves it; check both when
  editing, and prefer adding record-specific logic to a dedicated file over piling more
  `appMatch(...)` branches into a shared `~` file (see repo memory: this is the pattern already
  used for sanitation callbacks/skid/construction-material work).
- Case in the record-type segments is inconsistent across the repo (`BUILDING` vs `Building`) —
  this doesn't matter functionally (Accela/`appMatch` compares case-insensitively) but keep
  whatever casing the sibling scripts for that record type already use.

## Event Prefixes (confirmed / high-confidence from code inspection)

| Prefix | Event | Confirmed by |
|---|---|---|
| `ASA` | Application Submit After | Script bodies branch on `Application Submittal` task; fires once per record creation |
| `ASB` | Application Submit After (secondary/second-registered script for same event) | Sibling files to `ASA` for the same record types |
| `WTUA` | Work Task Update After | Scripts read `wfTask`/`wfStatus` after a workflow task status changes |
| `WTUB` | Work Task Update After (secondary) | Sibling files to `WTUA`; some use `appTypeArray[3]` instead of `appMatch` |
| `IRSA` | Inspection Result Submit After | Scripts branch on inspection result values (`Collected`, `No violation`, etc.) |
| `IRSB` | Inspection Result Submit After (secondary) | Sibling files to `IRSA` |
| `DUA` | Document Upload After | Bodies send "New Document Uploaded" emails |
| `DUB` | Document Upload After (secondary) | Bodies use `comment(...)` to restrict upload conditions |
| `DUPA` | Document Upload (Public/ACA) After — inferred, not fully verified | — |
| `CTRCA` | Contact/Record Creation After — inferred, not fully verified | — |
| `PRA` | Payment Received After — inferred from fee/balance-due logic in bodies (`balanceDue`, `feeExists`) | — |
| `IFA`, `ISA`, `ISB`, `LLSA`, `LPUA`, `PPA`, `RIUA`, `ASIUA`, `ASIUB`, `ASUA`, `ASUB` | Not yet confirmed for this repo — check the script body's logic (what fields/state it reads) before assuming the meaning | — |
| `ACAAPO*`, `ACAASI*`, `ACADOCUMENT*`, `ACALICENSEPROFESSIONAL*` | ACA (Citizen Access portal) equivalents of APO/ASI/Document/License-professional events, split into `BEFORE`/`AFTER`/`ONLOAD` variants | File names are explicit |

When a prefix's meaning is genuinely unclear for a task, don't guess — open a sibling script for a
record type you already understand and read what state (`wfTask`, `wfStatus`, inspection result
variables, `balanceDue`, etc.) it relies on; that tells you which event it must be.

**Recording an inspection result almost always also moves the workflow forward** — closing the
current task, scheduling the next one, or closing the whole record — not just logging a value.
When analyzing what an `IRSA` script does (or should do) for a given result, assume it has a
workflow-side effect (`activateTask(...)`, `closeTaskProcessCRM(...)`, scheduling a follow-up task,
etc.) until you've actually confirmed it's a no-op result, rather than treating the inspection
result and the workflow transition as two separate, possibly-unrelated things to analyze.

## Shared Includes

- `INCLUDES_CUSTOM.js` / `INCLUDES_CUSTOM/*.js` — shared helper functions (`eventMatch`,
  `syncAPOLinks`, `findLastestLicenseEffDate`, etc.) available to all event scripts. Check here
  before writing a new helper — it may already exist.
- `INCLUDES_ACCELA_FUNCTIONS_ACA.js` / `INCLUDES_ACCELA_GLOBALS_ACA.js` — Accela-provided
  functions/globals, not to be edited.
- `eventMatch(recordType4Part, eventPrefix, [userIds], [recordSource])` — the standard guard used
  instead of/alongside `appMatch(...)` to scope a shared script's logic to one record type + event
  + optionally specific users + AA vs. ACA source. Prefer this pattern when adding record-specific
  branches to a shared wildcard script, matching existing usage.

## Deployment Flow

1. Edit/add the `.js` file under `accela-test/Scripts/Event/` (or the relevant subfolder —
   `Batch/`, `Config/`, `Expression/`, `Interface/`, `Pageflow/`, `Set/`).
2. Commit/push in `accela-test` per the repo's normal git workflow.
3. **Deploy by copying the file(s) to the `accela_scripts` folder** — this is the folder the live
   Accela app server actually loads scripts from. Confirm the exact path with the user if it isn't
   already established in the session; it is a deployment target, not necessarily itself a git repo.
4. A new script file becomes active once deployed — Accela resolves the event/record-type binding
   from the filename convention, so no separate Admin-console "attach script to event" step is
   needed for `Scripts/Event/*.js` files in this setup. It still needs to physically reach
   `accela_scripts` to run; a change only committed in `accela-test` has no effect on production.

Don't confuse `accela_scripts` (deployment target) with the `accela-scripts` git repo in this
workspace — despite the near-identical name, `accela-scripts` currently contains unrelated
`LaborComplianceReporting` SQL report files, not the deployed Accela script set. If in doubt, ask.

## Config JSON Files (non-script config also living in `accela-test`)

Several cross-cutting behaviors are driven by JSON config read by scripts, not hardcoded per
record type — check these before assuming logic belongs in a `.js` file:

- `Scripts/Interface/CONF_DPW_WORKORDERS.json` — CRM request-type → Accela record type mapping.
- `Scripts/Config/CONF_*_SEND_CONTACT_EMAILS.json` — task-triggered contact email rules.
- `CONF_ENFORCEMENT_WORKFLOW_RULES.json`, `CONF_CRM_INTEGRATION_RULES.js` (per repo memory) —
  workflow propagation / CRM closure rules keyed by exact record-type string. These must use the
  **exact** `Module/Type/SubType/Category` string (confirm via `R3APPTYP`, not the CRM request-type
  label) or the rule silently won't match.
