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

Confirm the source checkout and test/production target before editing or publishing.
`accela-test` is for explicitly targeted test/development work; production CRM-to-DPW
request-type changes in this workflow use `accela-scripts`. Do not assume a source checkout
from a previous task is authoritative for a different target.

1. Inspect branch/worktree/upstream, fetch and safely fast-forward with `--ff-only` before editing.
   Preserve unrelated local changes and stop to resolve divergence/overlapping edits.
   Edit/add files in the confirmed source checkout under `Scripts/Event/` or the relevant
   subfolder (`Batch/`, `Config/`, `Expression/`, `Interface/`, `Pageflow/`, `Set/`).
2. Validate the change and preserve unrelated worktree changes. Commit/push only the in-scope
   source files when authorized; verify the expected branch and remote state.
3. Prepare and report an exact deployment manifest: source file, target environment, EMSE name,
   artifact type, and complete content to publish. Include only files whose deployment is required;
   list conditional files separately and do not deploy them speculatively.
4. **Deploy through the Accela Admin EMSE Script Manager/tool** to the confirmed tenant when that
   is the authorized environment workflow. Event scripts use the filename convention for
   event/record-type resolution; they do not need a separate event attachment in this setup.
   A commit/push alone does not deploy the script.
5. For configuration text loaded with `getScriptText`, deploy under the exact name passed to
   `getScriptText`. For example, `DPW_CheckRecordType` calls
   `getScriptText("CONF_DPW_WORKORDERS")`; deploy the raw JSON contents from
   `Scripts/Interface/CONF_DPW_WORKORDERS.json` under script code `CONF_DPW_WORKORDERS`
   (without the `.json` suffix). It is configuration text, not a new event handler. For this
   production workflow, use the **EMSE tool in the initial Civic Platform UI**, as directed by
   the owner. Do not replace that publishing path with Classic Admin's Script Text editor or
   the separate versioned Master Scripts search. Verify the actual EMSE tool controls before
   editing or saving. Follow the exact Launchpad, repository-tree, single-file Deploy, and
   reopened-comparison procedure in
   [`crm-to-accela-dpw-workorders.md`](crm-to-accela-dpw-workorders.md).
6. Do not confuse `accela-scripts` (Git source repository) with `accela_scripts` (legacy
   deployment-side location). Use a direct-copy path only when the system owner confirms it is
   current; do not substitute it for the EMSE tool specified for the task.
7. Reopen the saved script/config in the selected tenant and compare its persisted content with
   source. A successful-looking save/redirect or updated date alone is insufficient; report a
   failed readback explicitly and stop repeated saves. Do not mark the route live until the
   CRM/DPW configuration and required behavioral checks are also verified.

Never deploy a Stage request through a `DPW_WORKORDERS` Standard Choice that points to a production
endpoint or sets `Environment=production`; that value normalizes to Accela PROD and can create
production DPW work orders. Verify endpoint and environment separately for AATEST and AAPROD.

## Config JSON Files

Several cross-cutting behaviors are driven by JSON config read by scripts, not hardcoded per
record type — check these before assuming logic belongs in a `.js` file:

- `Scripts/Interface/CONF_DPW_WORKORDERS.json` — exact `Request Type` allowlist checked by
  `DPW_Insert`; it is not the CRM-to-Accela record-type routing map. CRM-to-core routing is in
  `CONF_CRM_INTEGRATION_RULES.js`; DPW service/destination routing is in
  `DPW.CRM_TO_DPW_RECORD_MAPPING`. For production CRM-to-DPW work, edit the confirmed
  `accela-scripts` source and deploy script code `CONF_DPW_WORKORDERS` with the complete
  raw JSON document. See
  [`crm-to-accela-dpw-workorders.md`](crm-to-accela-dpw-workorders.md).
- `Scripts/Config/CONF_*_SEND_CONTACT_EMAILS.json` — task-triggered contact email rules.
- `CONF_ENFORCEMENT_WORKFLOW_RULES.json`, `CONF_CRM_INTEGRATION_RULES.js` (per repo memory) —
  workflow propagation / CRM closure rules keyed by exact record-type string. These must use the
  **exact** `Module/Type/SubType/Category` string (confirm via `R3APPTYP`, not the CRM request-type
  label) or the rule silently won't match.
