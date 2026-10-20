# Accela `Scripts/Interface` Folder Map

Use this map to navigate the Accela `Scripts/Interface` directory and identify likely change
surfaces when adding a CRM request type or changing CRM/DPW behavior. The directory is a mixture
of runtime libraries, executable configuration, data configuration, a separate Legistar
integration, and task notes; it is not one standalone application.

The inventory and call-site search below were checked against the available
`accela-scripts` checkout on 2026-10-20. Confirm the authoritative checkout and re-run the
searches before making a task-specific change. A concrete update list still depends on the exact
CRM request name, Accela record type, DPW destination/service, and desired trigger.

## Runtime and configuration flow

1. **CRM intake:** PublicStuff creates a `ServiceRequest/CRM/CRM/NA` shadow record. Its WTUA
   handler loads `INCLUDES_CRM.js` and `CONF_CRM_INTEGRATION_RULES.js` to create and configure
   the Accela core record.
2. **DPW dispatch:** The relevant event loads `INCLUDES_DPWWORKORDERS.js`, which gates on
   `CONF_DPW_WORKORDERS.json` before calling the DPWApps Interface.
3. **DPW destination:** DPWApps reads `DPW.CRM_TO_DPW_RECORD_MAPPING` and writes to
   `DPW.CC_PUBLIC`, `DPW.CALL_CENTER`, or `DPW.COMP_PUBLIC`.
4. **Return updates:** DPW status/comment queues are processed by the DPWApps Interface and
   update Accela/CRM. Accela workflow feedback rules are loaded separately by module.
5. **Separate integration:** `UPDATE_RECORD_WITH_LEGISTAR_DATA.js` receives data from the
   Legistar interface; it is not part of the CRM-to-DPW path.

The CRM engine reads request-to-record routing from `CONF_CRM_INTEGRATION_RULES.js`. DPW
insertion is a separate dispatch path gated by the `Request Type` value in
`CONF_DPW_WORKORDERS.json`, then routed by the DPW database mapping. Workflow-feedback rules
are loaded separately by Accela module.

## Files in `Scripts/Interface`

### CRM and DPW runtime

| File | Structure and responsibility | Typical change when adding a request type? |
|---|---|---|
| `INCLUDES_CRM.js` | Shared CRM engine. Main entry points include `processShadowRecord`, `autoCreateRecordFromCRM`, `MergeRules`, `updateCoreSRWorkflow`, `callBackToCRM`, and `process_WF_JSON_Rules`. Helpers cover CRM-to-core field copying, comments, workflow propagation, address/parcel/owner handling, HTTP, and logging. | **Usually no.** Change only for a shared engine bug or genuinely new cross-request behavior. |
| `INCLUDES_CRM_CUSTOM.js` | Overrides/adds local CRM behavior: `AutoCloseShadowRec`, location-based `SetRecTypeBasedOnLocation`, `SetPriorityOnCore`, contact creation, document copying, custom address lookup/parsing, and reference-address attachment. | **Conditional.** Review if the request needs different contact, priority, location, address, or document behavior. |
| `INCLUDES_DPWWORKORDERS.js` | `DPW_CheckRecordType` reads the Accela `Request Type` ASI and checks the JSON allowlist; `DPW_Insert` uses a Standard Choice for endpoint settings and calls the DPWApps service; local HTTP/status helpers process the response. | **Usually no.** A new allowlist key and DPW map row normally suffice. Change for shared transport/protocol behavior. |
| `CONF_CRM_INTEGRATION_RULES.js` | JavaScript object of global defaults plus per-Accela-record-type rules. Controls workflow propagation, initial task, event firing, address parsing, and custom-field mapping. | **Often.** Add a per-record-type rule when the target record type is not already covered by a suitable rule. |
| `CONF_DPW_WORKORDERS.json` | JSON object keyed by exact CRM `Request Type` values accepted for DPW insertion. Values are currently empty objects. | **Yes, if DPW insertion is required and the exact key is absent.** This is an allowlist, not an Accela or DPW service mapping. |

### Workflow-feedback configuration

`INCLUDES_CRM.js` selects a workflow rules file using the Accela record module:
`CONF_<MODULE>_WORKFLOW_RULES`. The current directory has:

| File | Applies to |
|---|---|
| `CONF_ENFORCEMENT_WORKFLOW_RULES.json` | Enforcement records |
| `CONF_SERVICEREQUEST_WORKFLOW_RULES.json` | ServiceRequest records |
| `CONF_ENVHEALTH_WORKFLOW_RULES.json` | EnvHealth records |

These files contain wildcard and record-type-specific task/status rules for propagating
workflow changes, comments, and closures to related CRM shadow records. Add or update a rule
only when the new record's task/status behavior needs CRM feedback; select the file from the
actual record module, then verify wildcard rules and exclusions before adding a specific rule.
An inspection-result script may instead call `closeTaskProcessCRM(...)` directly.

### Other runtime, documentation, and task material

| Path | Purpose | Relationship to CRM → DPW |
|---|---|---|
| `UPDATE_RECORD_WITH_LEGISTAR_DATA.js` | Receives a `recordObj` through the EMSE environment and updates a Planning/Development record's custom fields, custom lists/history, and workflow from the separate Legistar interface. | Separate integration; not a CRM request-type change surface unless the target requirements explicitly involve Legistar. |
| `CRM-INTEGRATION-HOW-TO.md` | Original application-repository guide for CRM routing, DPW transfer, reverse updates, renames, and deployment. | Useful source material; verify against current code and use the centralized AI-Skills guide for the reusable workflow. |
| `mkesdp integration tickets/ticket-*.md` | Ticket-specific plans and examples for prior/requested integration work. | Historical/task context, not authoritative generic procedure. Revalidate status and facts before reuse. |
| `mkesdp integration tickets/examples.csv` | Example/cross-check data. | Operational data, not skill documentation; do not copy its record values into reusable docs. |
| `mkesdp integration tickets/all together.txt` | Compiled request/ticket notes. | Historical context, not runtime configuration or a source of verified current state. |

## Update surfaces for a new CRM request type

Use this as a conditional checklist, not as an instruction to edit every file:

| Requirement | Change or verification surface |
|---|---|
| CRM request creates an Accela core record | PublicStuff request type and Foreign Association; `CONF_CRM_INTEGRATION_RULES.js`; correct shadow-record workflow; verify the target Accela record type/workflow/ASI setup. |
| CRM request creates a DPW work order | Add exact `Request Type` key to `CONF_DPW_WORKORDERS.json`; verify `DPW.CRM_TO_DPW_RECORD_MAPPING` with exact request type, division, service number, and `TRANSFER_TO`; confirm an event path calls `DPW_Insert`. |
| New Accela record type has special setup | Accela Admin configuration plus necessary record-specific ASA/WTUA/IRSA scripts; inspect the applicable wildcard scripts before adding a dedicated file. |
| Accela or DPW updates CRM status/comments | Correct module-specific `CONF_*_WORKFLOW_RULES.json` entry, or an intentional `closeTaskProcessCRM(...)` call; verify DPW update queues and scheduled DPWApps processing. |
| Shared behavior changes across CRM request types | Review `INCLUDES_CRM.js`, `INCLUDES_CRM_CUSTOM.js`, or `INCLUDES_DPWWORKORDERS.js` only where their shared behavior is actually changing. |
| Endpoint, payload, or database-transfer behavior changes | Review the separate `InterfaceAccelaCRMWithDPWWorkOrders` Java application and DPW schema; a simple new request/service mapping should not by itself require Java changes. |

### DPW dispatch call sites found in this checkout

A repository search for `DPW_Insert` / `INCLUDES_DPWWORKORDERS` found these active source paths:

| Event script | Existing purpose |
|---|---|
| `Scripts/Event/WTUA;SERVICEREQUEST!CRM!CRM!NA.js` | Shared CRM shadow-record handler; calls DPW insertion when `wfTask == 'Investigation'`, passing the shadow `capId`. |
| `Scripts/Event/IRSA;ENFORCEMENT!COMPLAINT!SANITATION!INSPECTION.js` | Inspection-result-specific flow creates a CRM child record and calls DPW insertion on that child. |
| `Scripts/Event/IRSA;SERVICEREQUEST!STREETS AND SIDEWALKS!POTHOLES!~.js` | Pothole-specific inspection flow calls DPW insertion on its core record object. |

The Skid Violation IRSA file contains a commented-out DPW call; it is not an active dispatch.
These call sites also appear under `SortedByRecordType/` as sorted copies. Do not treat the
sorted tree as an independent second runtime dispatch. Follow the repository's
`SortScriptsByRecordType` / `UnsortScriptsByRecordType` workflow and avoid editing both copies
independently.

For a standard new CRM request, first determine whether the shared CRM shadow handler already
performs the intended transfer. Add another event call only if the required trigger or record
payload differs; otherwise it may duplicate an existing dispatch.

### Adjacent event and batch surfaces

These files are outside `Scripts/Interface` but participate in shared CRM behavior:

| Path | Role | When to change |
|---|---|---|
| `Scripts/Event/WTUA;ENFORCEMENT!~!~!~.js` | Loads `INCLUDES_CRM` and invokes `process_WF_JSON_Rules` for Enforcement workflow updates. | When the target Enforcement record needs CRM workflow/status/comment propagation. |
| `Scripts/Event/WTUA;SERVICEREQUEST!~!~!~.js` | Same rule engine for ServiceRequest workflow updates. | When the target ServiceRequest needs CRM workflow/status/comment propagation. |
| `Scripts/Event/WTUA;ENVHEALTH!~!~!~.js` | Same rule engine for EnvHealth workflow updates. | When the target EnvHealth record needs CRM workflow/status/comment propagation. |
| `Scripts/Batch/CRMFixAPO.js` | On-demand batch that selects CRM shadow records and uses CRM includes to repair address/APO data. | Only when the work requires existing-record address/APO repair or backfill; it is not routine request-type routing. |

## Source checks and cautions

- Search the confirmed checkout for `DPW_Insert`, `INCLUDES_DPWWORKORDERS`,
  `CONF_CRM_INTEGRATION_RULES`, `CONF_DPW_WORKORDERS`, and `process_WF_JSON_Rules` before
  changing a request type. Include `Scripts/Event/` and `SortedByRecordType/` in the search.
- `CONF_DPW_WORKORDERS.json` is an allowlist. `DPW.CRM_TO_DPW_RECORD_MAPPING` determines the
  DPW division, service number, and destination table.
- `DPW_Insert` takes a Standard Choice name as its first argument (`BaseUrl`, `Service`,
  `Environment`), not the JSON filename. Existing call sites pass different values; verify the
  matching Standard Choice rather than copying an example blindly.
- The JSDoc above `DPW_CheckRecordType` in `INCLUDES_DPWWORKORDERS.js` says
  `CONF_CRM_INTEGRATION_RULES`, while the implementation actually loads
  `CONF_DPW_WORKORDERS`. Treat the implementation as the behavior and correct the comment when
  that source file is next changed.
- Some older notes refer to `CONF_DPW_WORKORDERS.js`; this checkout uses
  `CONF_DPW_WORKORDERS.json`.
- Confirm source checkout, environment, deployment target, and authorization. A source edit does
  not update PublicStuff, Accela Admin configuration, DPW database mappings, or DPWApps schedules.

See [`crm-to-accela-dpw-workorders.md`](crm-to-accela-dpw-workorders.md) for the end-to-end
request-type procedure and DPW `CC_SERVICES` lookup.
