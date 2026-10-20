# CRM to Accela to DPW Work Orders

Use this as the centralized procedure when adding or changing a PublicStuff (Accela CRM /
Click for Action) request type that creates an Accela record and may also create a DPW work
order. It consolidates the CRM integration guide and the Civic-to-DPW overview with current
source-based distinctions. Keep those original documents in their application repositories;
use this reference as the cross-system index and recheck implementation facts against the
confirmed source checkout and environment before acting.

For Accela record setup, also follow the main Accela skill's record-type workflow and manual
admin checklist.
For the structure of the Accela `Scripts/Interface` directory and the broader request-type
change-impact matrix, see [`interface-folder-map.md`](interface-folder-map.md).

## System access and credential locations

Use all three systems when verifying a production CRM-to-DPW route:

| System | Production URL | Access/credential source | Verify here |
|---|---|---|---|
| PublicStuff / Accela CRM admin | <https://gov.publicstuff.com/> | `InterfaceAccelaCRMWithDPWWorkOrders/src/util/CRMAPI.java` contains production and staging account settings (`username_production` / `username_staging` and password configuration). The owner identified the production account there for CRM sign-in. Use the production settings only when authorized and secure entry is available; do not copy credential values into this skill, memory, logs, or chat. Reuse an authenticated session when available. | Exact CRM request type, Foreign Association, and associated Accela record type |
| CRMControl | <https://mintapps.milwaukee.gov/CRMControl/indexSidebarNew.jsp#> | LoginMKE sign-in by the authorized user; reuse their authenticated browser session. No reusable password location has been established for this app. | CRM-to-DPW mapping, generated `REC_NUM`, transfer destination/flag, queues |
| Accela Civic Platform | <https://milwaukee-prod-av.accela.com/> | Authorized Accela production account/user-entered browser sign-in; reuse the authenticated session. No reusable credential-file location has been established for this portal. Do not assume CRM API credentials also sign in to Accela. | Target record type, workflow/custom fields, and EMSE deployment/readback |

Resolve the interface project from the configured workspace; the verified Windows source location
is `C:\Users\kbaas\eclipse-workspace\InterfaceAccelaCRMWithDPWWorkOrders\src\util\CRMAPI.java`.
Keep API endpoints distinct from admin websites: that source references PublicStuff API hosts,
which are not the CRM administration UI. Do not treat API tokens as browser passwords or use
staging account settings for production. Never dump the credential-bearing source file or token
responses to discover a URL. If the browser tools cannot securely consume local credentials,
report that limitation and request direct browser login rather than credentials in chat. Do not
create a credential-serving endpoint or save plaintext intermediary files. Recheck current URLs
and access when environments change.

In CRM, open the settings menu, **Manage Request Types**, filter for the exact request, and open
its **Foreign Associations** section. Wait for integration metadata to finish loading before
interpreting the selected integration: a transient "No Integration" label can be replaced by the
configured integration after asynchronous loading. Verify the integration, four-part Foreign Id,
and **Auto Create Work Orders** setting; do not save changes merely to inspect them.

## Keep the identifiers distinct

Several values are easy to confuse. Verify each against the live source/configuration before
changing anything.

| Value | Meaning | Where it is used |
|---|---|---|
| CRM request type / Accela `Request Type` ASI | Exact PublicStuff request-type name | `CONF_DPW_WORKORDERS.json` allowlist and DPW mapping lookup |
| Accela `Workorder Record Type` ASI | Target `Module/Type/SubType/Category` to create from the CRM shadow record | PublicStuff Foreign Association and CRM-to-core routing |
| Accela record-type key | Exact `Module/Type/SubType/Category` | Key in `CONF_CRM_INTEGRATION_RULES.js`; also used by record-specific EMSE logic |
| DPW service mapping | Division, service number, and destination DPW table | `DPW.CRM_TO_DPW_RECORD_MAPPING` |
| `DPW_Insert` first argument | Accela Standard Choice name holding `BaseUrl`, `Service`, and `Environment` | Endpoint configuration; it is not the JSON allowlist filename |

`CONF_DPW_WORKORDERS.json` is an allowlist keyed by the exact `Request Type` value. It does
not map a CRM request type to an Accela record type or select the DPW service. The service and
destination are selected by `DPW.CRM_TO_DPW_RECORD_MAPPING`; despite its `ACCELA_RECORD_TYPE`
column name, verify that the stored value matches the `Request Type` ASI read by the Java
interface.

## End-to-end flow

1. PublicStuff creates an Accela shadow record of type `ServiceRequest/CRM/CRM/NA`.
2. The shadow record's `Workorder Record Type` identifies the Accela core record type to create.
   The integration rules provide the target workflow, initial task, and field mapping.
3. The CRM shadow-record `WTUA` handler processes the shadow record and invokes the DPW insert
   path when its configured workflow trigger is reached.
4. `DPW_Insert` checks the shadow/record's `Request Type` against
   `CONF_DPW_WORKORDERS.json`, then calls the DPWApps Interface service.
5. The Java interface fetches the Accela record, reads `Request Type`, looks it up in
   `DPW.CRM_TO_DPW_RECORD_MAPPING`, and inserts into the configured DPW destination table.
6. DPW status changes are queued and later sent back to Accela/CRM. Accela workflow rules or
   explicit event-script calls control how those updates affect the shadow record and CRM.

Do not assume every request type should create a DPW work order, or that the shared CRM event
is the correct trigger. Confirm the desired business trigger and inspect the event scripts that
fire for both the shadow and target core record before adding another `DPW_Insert` call.

## Add a request type

### 1. Confirm scope and names

- Confirm the exact CRM request type spelling as configured in PublicStuff.
- Confirm whether it targets an existing Accela record type or requires a new one.
- Confirm the exact Accela `Module/Type/SubType/Category`.
- Inspect the actual request type in production PublicStuff and read its Foreign Association
  before asking the requestor for an association value that can be checked directly. Confirm
  that exact four-part target exists in production Accela and has the intended workflow/custom
  fields. Record the observed association, Accela target, and verification status.
- If the Foreign Association is missing, compare the source request/email with existing production
  Accela record types to identify a candidate. Treat it as provisional until confirmed; do not
  invent a Road Plate-specific record type or assume the generic DPW target. Report the exact
  missing CRM setup and who must confirm/set it before claiming the route is ready.
- Confirm whether a DPW work order is required, which DPW service it represents, and the
  destination table (`DPW.CC_PUBLIC`, `DPW.CALL_CENTER`, or `DPW.COMP_PUBLIC`).
- Decide when DPW creation should occur and what status/comment updates must flow back.
- Check CRM request descriptions, confirmation text, development-only fields, and announcements
  for DO NOT USE/under-development notices. Coordinate release of those notices with the CRM
  owner after acceptance; do not remove them or declare availability merely because backend
  configuration was saved.

Do not use one name in place of another. The CRM request type and Accela record-type key serve
different purposes, even if their labels happen to look similar.

### 2. Configure the Accela record type

For a new Accela record type, follow
[`spec-analysis-workflow.md`](spec-analysis-workflow.md) and
[`manual-admin-steps-checklist.md`](manual-admin-steps-checklist.md). Verify the workflow,
initial task, status labels, ASI fields, inspection setup, and other record-type requirements
in the target environment.

The CRM integration engine and DPW interface rely on correctly populated custom fields. In
particular, verify the required `Request Type`, `Workorder Record Type`, and `Core Request ID`
fields on the relevant shadow/core record forms. Confirm their actual group/form placement
against the target environment; do not add duplicate fields to the existing CRM shadow type.

### 3. Configure CRM intake and Accela routing

- In PublicStuff, configure the request type and its Foreign Association to the exact Accela
  record-type string. This supplies `Workorder Record Type` on the shadow record.
- Add or verify a routing rule in `CONF_CRM_INTEGRATION_RULES.js`, keyed by the exact Accela
  `Module/Type/SubType/Category`.
- Compare the CRM Foreign Association's actual `Workorder Record Type` with the production
  `CONF_CRM_INTEGRATION_RULES.js` keys before deciding whether that file needs a change. This
  config is keyed by the Accela core record type, not by the CRM request-type label. An existing
  exact or supported wildcard rule may already serve the request; add a rule only if the verified
  target has no applicable rule or needs different workflow/field behavior.
- Verify the rule's workflow task, initial task, status, event-firing options, address parsing,
  and custom-field map against the configured record type.
- Check the CRM shadow-record `WTUA` handler and any target-specific `ASA`, `WTUA`, or `IRSA`
  scripts. Preserve shared behavior; add a dedicated event script only when the required logic
  is not already handled by the common path.

For a request type targeting an existing Accela record type, reuse its verified workflow and
event behavior; the CRM request type may need only a routing rule, PublicStuff setup, DPW
allowlist entry, and DPW mapping. For a brand-new Accela record type, include Accela Admin
configuration and record-specific scripts as required. Existing integration documentation
identifies these fields as important:

| Record | Field | Role |
|---|---|---|
| CRM shadow | `Workorder Record Type` | Target Accela core record type, set through the PublicStuff Foreign Association |
| CRM shadow and core | `Request Type` | CRM request type / DPW mapping key; verify where it is populated |
| Core record | `Source` | Often set to `Lagan` by the record's ASA when created from a CRM shadow |
| Core record | `Core Request ID` | Stores the core record alt ID to help prevent duplicate core-record creation |

Verify the field groups and behavior in the target environment. The standard
`ServiceRequest/CRM/CRM/NA` shadow record already has integration fields in the documented
setup; inspect before changing it.

### 4. Configure DPW work-order creation

- Add the exact CRM `Request Type` string as a key in `CONF_DPW_WORKORDERS.json`. The
  `DPW_CheckRecordType` helper reads the record's `Request Type` ASI and skips the service call
  if that key is absent.
- Verify or request the corresponding row in `DPW.CRM_TO_DPW_RECORD_MAPPING`. Confirm the
  request-type value, division, service number, and `TRANSFER_TO` destination in the correct
  environment. Find the service number from the DPW service catalog; do not guess it.
- Confirm the intended EMSE trigger and record ID passed to `DPW_Insert`.
- Confirm the first `DPW_Insert` argument names the Standard Choice that supplies
  `BaseUrl`, `Service`, and `Environment`. The shared CRM shadow event currently passes
  `DPW_WORKORDERS`. Some older/how-to examples pass `CONF_DPW_WORKORDERS`; do not copy that
  value without confirming that the matching Standard Choice exists and is intended.
- Verify the Standard Choice values separately in AATEST and AAPROD before any test or rollout.
  The `Environment` value is passed to the Java service, where `production` normalizes to
  Accela `PROD`; a Stage event configured with the production endpoint/environment can therefore
  read production Accela data and create production DPW work orders. Require a non-production
  interface and data source for a Stage dispatch.
- If an inspection-result path creates a CRM child record for DPW insertion, copy the required
  address/contact/parcel data first, then set the child `Request Type` to the intended DPW
  mapping key. Inspect the existing `copyKeyInfo` behavior before changing the order.

The DPW service call requires valid location/contact data. Verify the selected record has the
address and contact information expected by the interface. A missing `Request Type` key,
database mapping, or required address can prevent a DPW work order from being created.

#### Verify the authoritative mapping database

DPW tables can exist in both Oracle `DPWP` and SQL Server copies. Before changing a mapping,
check the DPW migration bookkeeping and the interface's actual database connection; do not
assume that a local SQL Server `DPWP` copy is the production source. As of 2026-10-20,
`DatabaseMigration` marked `DPW.CRM_TO_DPW_RECORD_MAPPING` as `pending` for
`sql-treas.AccelaIntegration`, while the interface servlet uses `jdbc/dpwprod`. Until the
mapping table is cut over and the application is verified against the SQL Server target, use
the authoritative production Oracle mapping. The Oracle source can be queried from `sql-treas`
with `OPENQUERY([DPWP], ...)`; `sql-treas.DPWP` without `OPENQUERY` is the local SQL Server
database, not the linked Oracle source.

Recheck this routing after any migration/cutover. Never update both the Oracle source and a SQL
Server copy as a guess; determine the runtime target first.

#### Enter the mapping through CRMControl

CRMControl's active table configuration labels `DPW.CRM_TO_DPW_RECORD_MAPPING` as **CRM to DPW
Record Type mappings** and assigns `DPW.SEQ_CRM_TO_DPW_RECORD_MAPPING` as the `REC_NUM` sequence.
For an approved production mapping change, use the production CRMControl UI, not a SQL Server
staging copy or direct SQL insert. Let the app generate `REC_NUM`; after saving, filter for the
exact request type and verify the row and generated key before proceeding. Do not repeat a create
if a generic refresh/search reports an error until checking whether the row was nevertheless saved;
avoid creating a duplicate.

The table has separate `XFER_TO_DPW` and `TRANSFER_TO` fields. `XFER_TO_DPW` is the checkmark;
`TRANSFER_TO` is the destination string (`DPW.CC_PUBLIC`, `DPW.CALL_CENTER`, or
`DPW.COMP_PUBLIC`). Do not enter the destination in the checkmark field. Verify
`ACCELA_RECORD_TYPE`, `DIVISION`, `SERVICE_NUM`, `SERVICE_DESC`, checked `XFER_TO_DPW`, and
`TRANSFER_TO`; leave `REC_NUM` sequence-generated and other metadata blank/app-managed unless the
application requires otherwise. Confirm the right CRMControl environment and verify the saved row
before testing.

For an Accela allowlist change, `DPW_CheckRecordType` loads
`getScriptText("CONF_DPW_WORKORDERS")` and parses its contents as JSON. Publish the raw JSON under
script name `CONF_DPW_WORKORDERS` (no `.json` suffix); it is named configuration text, not a new
event handler, and does not need event attachment. Use the **EMSE tool in the initial Civic
Platform UI** at the production portal, as directed by the owner. Open **Launchpad > EMSE Tool**;
the observed route is
`https://milwaukee-prod-av.accela.com/portlets/web/en-us/#/core/spacev360/milwaukee.emsetool`.
Locate and verify that tool's
script selection/publishing controls before editing. Do not substitute Classic Admin's Script
Text editor or its separate versioned Master Scripts search for the requested EMSE tool.

In the EMSE Tool, verify the repository root is the production `accela-scripts.git` repository.
Expand **Agency_scripts > Scripts > Interface** and open the exact changed file to compare
**Source Code Control System Script** with **AA Script**. Select only that file's checkbox, not
the folder or other pending files. Click **Deploy**, confirm the single-script action, and verify
the tool reports that the named script was deployed from Source Code Control System to AA
successfully. Reopen the comparison to verify saved content/difference status. JSON files retain
their repository filename in the tree but deploy under the extensionless script name shown in the
success message. Do not manually recreate configs in Classic Admin.

Before saving, compare the deployed config with the committed source and preserve every unrelated
entry. After saving, search/select the script again and compare the persisted JSON to source.
A returned search page or changed Last Modified date is not proof of deployment. If readback
does not contain the change, report deployment as failed/unverified; do not repeatedly save or
claim success. Record the attempt and request the supported EMSE publishing path.

Before treating `CONF_DPW_WORKORDERS` as the only required Accela publish, verify the separate
CRM-to-core route. `INCLUDES_CRM.js` `MergeRules` obtains a rule with `findRecordTypeRule` for the
Foreign Association's core record type; `GlobalRules` supplies defaults only after a matching
record-type rule is found and is not itself a fallback route. Check exact and supported wildcard
keys in `CONF_CRM_INTEGRATION_RULES.js`. Deploy that named script too only if the verified core
record type needs a new or changed rule.

#### Identify a service for `DPW.CALL_CENTER`

`DPW.CC_SERVICES` identifies a service by the **pair** `DIVISION` + `SERVICE_NUM`; the Java
interface also uses both values when resolving a service description. The catalog does not
itself select the destination table. `TRANSFER_TO = 'DPW.CALL_CENTER'` in
`DPW.CRM_TO_DPW_RECORD_MAPPING` selects the destination, while `DIVISION` and `SERVICE_NUM`
select the service within it.

First search the catalog using the service name or terms supplied by the DPW business owner.
The following SQL Server query is based on the existing integration guide; verify its columns
and database/environment before running it:

```sql
SELECT
	cs.DIVISION,
	d.DIVISION AS DivisionName,
	cs.SERVICE_NUM,
	cs.SERVICE_DESC
FROM
	DPW.CC_SERVICES AS cs
JOIN
	DPW.CC_DIVISIONS AS d
	ON d.DIVNUM = cs.DIVISION
WHERE
	cs.SERVICE_DESC LIKE '%' + @serviceDescription + '%'
ORDER BY
	cs.DIVISION,
	cs.SERVICE_NUM;
```

The verified `DPW.CC_DIVISIONS` column for the division name is `DIVISION`, not
`DIVISION_DESC` (checked in the available `sql-treas` `DPWP` and `CallCenter` databases on
2026-10-20). Confirm the intended database/environment before relying on catalog results.
These are SQL Server examples; the checked `DPW_CallCenter` client source currently sets
`USE_MSSQL = false` and selects its Oracle `CCSrv` path. Treat the SQL Server copies as
non-authoritative until the deployed service catalog and environment are confirmed.

Then review existing Call Center mappings and confirm the selected pair resolves to the intended
service:

```sql
SELECT
	m.ACCELA_RECORD_TYPE,
	m.DIVISION,
	d.DIVISION AS DivisionName,
	m.SERVICE_NUM,
	cs.SERVICE_DESC,
	m.TRANSFER_TO
FROM
	DPW.CRM_TO_DPW_RECORD_MAPPING AS m
JOIN
	DPW.CC_SERVICES AS cs
	ON 1 = 1
	AND cs.DIVISION = m.DIVISION
	AND cs.SERVICE_NUM = m.SERVICE_NUM
JOIN
	DPW.CC_DIVISIONS AS d
	ON d.DIVNUM = m.DIVISION
WHERE
	m.TRANSFER_TO = 'DPW.CALL_CENTER'
ORDER BY
	m.DIVISION,
	m.SERVICE_NUM,
	m.ACCELA_RECORD_TYPE;
```

Use existing rows as examples, not as proof that a service is appropriate for a new request.
Have the DPW Call Center/service owner confirm the business meaning and destination before
configuring the mapping. Do not choose by `SERVICE_NUM` alone or infer the correct service from
the request-type label.

#### Choose the correct dispatch path

The shared CRM shadow-record handler currently calls `DPW_Insert` when `wfTask` is
`Investigation`, passing the shadow record ID. Check whether this existing path applies to the
new request type before adding another call; a second dispatch can create duplicate work orders.

An inspection-result-driven DPW work order is a different path. Existing documentation uses an
IRSA script to create a `ServiceRequest/CRM/CRM/NA` child, copy address/contact/parcel data with
`copyKeyInfo`, set the child `Request Type` to the DPW request type after that copy, and then call
`DPW_Insert`. The order matters because copying ASI data can overwrite `Request Type`. Confirm
the current implementation and the approved trigger before reusing this pattern.

The Java interface's `insertRecord` operation fetches the Accela record by ID, reads its
`Request Type`, resolves the DPW mapping, and transfers supported address/contact/comment and
custom-field data. The DPW transfer queue records transfer state and errors; verify its result
instead of treating an HTTP response alone as proof that a DPW work order was created.

### 5. Send Accela results or new requests back to CRM

Do not conflate a DPW work-order insert with a CRM push. To create a new CRM request from an
Accela inspection result, the documented pattern is to call
`closeTaskProcessCRM(task, status, crmRequestType)` from the relevant IRSA script. Confirm that
the target CRM request type exists in PublicStuff and that the workflow/status change is also
correct.

### 6. Configure status and comment updates back

Treat the reverse path as a separate requirement from creating the DPW work order:

- Verify the DPW update queue and scheduled interface process that sends status changes back.
- For workflow-driven CRM updates, add/verify the exact record-type/task/status rules in
  `CONF_ENFORCEMENT_WORKFLOW_RULES.json`.
- For inspection-result-driven updates or custom timing, inspect the relevant `IRSA` script and
  `closeTaskProcessCRM(...)` behavior.
- Confirm status translation, comment visibility, task closure, and public-facing messages with
  the business owner/CRM admin.

Documented operations use `DPW.CC_CRM_UPDATE_QUEUE` for pending DPW-to-Accela/CRM updates and
`DPW.CC_CRM_UPDATE_QUEUE_FAILS` for failures. A scheduled DPWApps process named
`updateAccelaCRM` handles the queue in the documented setup. DPW status codes have historically
been translated as follows; verify the current Java implementation and target system before
using this as an acceptance oracle:

| DPW status | Documented Accela/PublicStuff status |
|---|---|
| `N` | Received |
| `P`, `T` | In Progress |
| `R`, `V` | Completed |

For Accela workflow changes that should update CRM, `CONF_ENFORCEMENT_WORKFLOW_RULES.json`
provides the documented rule-driven mechanism. `closeTaskProcessCRM(...)` is an imperative
alternative for inspection-result-driven actions; choose one deliberately for each transition.

### 7. Coordinate deployment and operations

The flow spans independently configured systems. Assign an owner and deployment step for each:

| System | Typical change |
|---|---|
| Accela Admin | New record type, workflow, statuses, ASI/SmartChoice groups, inspection/fee configuration |
| Accela EMSE/config | CRM routing, scripts, `CONF_DPW_WORKORDERS.json`, status-propagation rules |
| PublicStuff / CRM Admin | Request type, exact name, Foreign Association, public-facing settings |
| DPW database / CRMControl | DPW service mapping, transfer queues, transfer monitoring |
| DPWApps Interface | Endpoint/environment settings and scheduled update process, if changed |

The documented operations UI is CRMControl, which exposes transfer mappings and queues. The
older Civic-to-DPW overview names its tables as CRMControl screens; confirm the current UI and
database before using those navigation labels. Do not perform production database writes or
deploy scripts/configuration without the appropriate authorization.

### Production source, deployment, and owner handoff

For production CRM-to-DPW request-type changes in this workflow, make source changes in the
`accela-scripts` Git repository, not the `accela-test` checkout. Use `accela-test` only for work
explicitly targeting AATEST. Preserve unrelated edits, validate the exact production diff, and
commit/push only the in-scope files to the intended branch. A commit or push is not an EMSE
deployment.

Before editing, inspect the branch, worktree, and upstream; fetch and fast-forward/pull with
`--ff-only` when the update is safe. Preserve local changes; do not reset, auto-stash, or include
unrelated files in the integration commit. Resolve a divergent branch or overlapping local edits
before proceeding. After validation, commit/push the authorized change and verify the remote branch
contains the expected commit before deploying from the Git-connected EMSE Tool. Perform these
authorized steps when tools/access allow; do not silently leave them for the user.

Before publishing, produce an exact deployment manifest:

| Source change | Accela EMSE artifact | How to publish |
|---|---|---|
| `Scripts/Interface/CONF_DPW_WORKORDERS.json` | Named config script `CONF_DPW_WORKORDERS` | Publish the complete raw JSON through the initial Civic Platform UI's EMSE tool; omit `.json`; do not attach it to an event |
| `Scripts/Interface/CONF_CRM_INTEGRATION_RULES.js` (only if actually changed) | Named config script `CONF_CRM_INTEGRATION_RULES` | Publish the complete source text under the name read by `getScriptText`; verify the exact consumer/name and deployed rule |
| `Scripts/Event/<event-file>.js` (only if actually changed) | Event script named by the complete file/event convention | Deploy the complete changed event script to the intended tenant; verify its event binding/record type behavior |

Do not include a conditional artifact just because it might be needed; inspect the real routing
rule and event behavior first. In the Accela EMSE Script Manager/tool, select the production tenant
when production is the requested target, verify the displayed environment before saving, and then
read the saved script/config back or use the tool's deployment confirmation. Never label a source
commit, CRMControl save, or EMSE save alone as an end-to-end go-live.

Explain the disposition of both configs in the handoff: the request-type allowlist and the separate
CRM-to-core rules. If the associated core type already has the correct deployed rule, state
explicitly that the CRM config is already in the same Accela environment and needs no change for
this request. Do not infer that a file is undeployed, moved elsewhere, or hidden as unchanged merely
because it is absent from a particular EMSE tree/search; verify the named deployed script and its
applicable rule. Report an unexplained UI omission as unverified rather than inventing its cause.

Before ending the task, tell the requestor exactly what is done and what remains, organized by
system/owner. For each remaining item provide:

- Owner or team (CRM admin, Accela admin, DPW owner, or requestor).
- Target environment and exact application/tool/repository.
- Exact action, values, file path, and EMSE script name/content required.
- Dependencies, approvals, or access still needed.
- Observable verification (saved mapping row/key, EMSE script readback, CRM-created Accela record,
  DPW transfer queue/work-order identifier, and any return status/comment).

Separate completed work from unperformed actions. Do not ask the user to repeat a verified step.
If blocked, say what access/decision is needed and list the concrete action that can resume the
rollout; avoid vague instructions such as “have an admin deploy the changes.”

### Controlled test and release handoff

Distinguish **configured/deployed**, **ready for a controlled test**, and **accepted/released for
use**. After configuration and deployment are verified, give a direct readiness recommendation
and ask the CRM request owner to run one agreed test; do not claim end-to-end acceptance in advance.

1. Identify the target environment. For a production test, explain that it can create a real DPW
   work order and obtain explicit approval/coordination with the receiving division. Do not
   substitute a Stage request whose endpoint/environment points to production.
2. Specify the exact CRM request type, agreed address/location, suitable test-identification
   text where supported, and required contact/custom-field data. Have the owner submit one request
   and provide its CRM ID; do not submit duplicates if it stalls.
3. Trace that CRM ID to the Accela shadow and intended core record. Confirm the actual
   `Request Type`, `Workorder Record Type`, core linkage, initial task/status, and dispatch event.
   Compare the configured rule's `Task`, `Initial_Task`, and status against real workflow tasks;
   an existing rule is not proof its runtime behavior works.
4. Inspect the supported transfer queue/log and confirm exactly one work order in the intended
   DPW destination with the expected division/service, address, contact data, request details,
   and form. Capture CRM, Accela, and DPW identifiers for cross-system tracing.
5. Verify required status/comment return updates and visible failure/retry handling. Coordinate
   test-work-order disposition with DPW; do not close/delete a real order without authorization.
6. After acceptance, have the CRM owner coordinate removal/update of DO NOT USE descriptions,
   confirmation text, development-only fields, and announcements, then confirm availability.
   Keep those notices unchanged until the owner authorizes release.

Include a ready-to-send test request when useful: name the exact type and environment, warn about
the real work-order side effect, request one submission and its CRM ID, list what will be checked,
and say to retain release notices until acceptance. State any outstanding workflow/configuration
risk plainly rather than burying it behind a generic "ready" claim.

### 8. Rename a CRM request type safely

For a rename, the documented sequence avoids breaking in-flight requests:

1. Add the new request-type key to `CONF_DPW_WORKORDERS.json`, keeping the old key.
2. Add the new routing rule to `CONF_CRM_INTEGRATION_RULES.js`, keeping the old rule.
3. Have the CRM admin rename/configure the request type in PublicStuff.
4. Allow in-flight records using the old name to complete.
5. Remove the old keys/rule only after confirming they are no longer needed.

Apply the same coordination to the DPW mapping row and any status-propagation rules that use the
old value. Verify the real cutover process with system owners before changing production.

## Test and deployment checklist

- [ ] Confirm the authoritative source checkout and target environment (`accela-scripts` for
      production CRM-to-DPW source changes; `accela-test` only for explicitly targeted AATEST work).
- [ ] Inspect local changes/upstream, fetch, and safely fast-forward before editing; preserve
      unrelated work and resolve divergence/overlap.
- [ ] Validate, commit, and push only the in-scope source changes; record branch and commit.
- [ ] List every required EMSE artifact with source file, exact script name/type, full content, and
      target tenant; separate conditional artifacts and omit unchanged files.
- [ ] Confirm exact CRM request type and Accela record-type strings in their respective systems.
- [ ] Verify the CRM Foreign Association creates the intended `Workorder Record Type`.
- [ ] Verify the CRM rule creates the expected core Accela record and initial workflow task.
- [ ] Verify the `Request Type` value matches the key in `CONF_DPW_WORKORDERS.json`.
- [ ] Verify the DPW mapping resolves the expected division, service number, and destination.
- [ ] For production mapping changes, enter through production CRMControl, allow the sequence to
      generate `REC_NUM`, and filter/reopen the row to verify all values before testing.
- [ ] Verify the intended event calls the expected DPWApps endpoint and the transfer succeeds.
- [ ] Verify the DPW record and transfer queue/log entry, including failure details if unsuccessful.
- [ ] Verify DPW status/comments return to the intended Accela and CRM records.
- [ ] Verify transfer failures and retries through the supported queue/monitoring process.
- [ ] Confirm PublicStuff, Accela Admin, DPW mapping, scheduled-job, and script/config changes
      are each deployed to the intended environment by their authorized owners.
- [ ] Verify the single-file EMSE deployment success message and reopened source/AA comparison;
      for identical content require zero differences, not only a save/date change.
- [ ] Hand off one approved controlled test with exact type/location, real-work-order warning,
      required identifiers, success criteria, and any remaining workflow risks.
- [ ] Record configured/deployed vs tested/accepted status separately; coordinate CRM release
      notices and test-order disposition with the owners after acceptance.

A commit of Accela scripts is not a deployment of PublicStuff configuration, Accela Admin setup,
DPW database mappings, or DPWApps schedules. Coordinate and verify each system separately.

## Source verification

Check the confirmed source checkout and environment before relying on these paths; filenames and
behavior can differ between script copies.

| Concern | Source to inspect |
|---|---|
| CRM request-type routing rules | `Scripts/Interface/CONF_CRM_INTEGRATION_RULES.js` |
| DPW request-type allowlist | `Scripts/Interface/CONF_DPW_WORKORDERS.json` |
| Allowlist check and DPW HTTP call | `Scripts/Interface/INCLUDES_DPWWORKORDERS.js` (`DPW_CheckRecordType`, `DPW_Insert`) |
| Shared CRM shadow-record dispatch | `Scripts/Event/WTUA;SERVICEREQUEST!CRM!CRM!NA.js` |
| Inspection-result DPW dispatch | Relevant `Scripts/Event/IRSA;*.js` |
| CRM/core workflow feedback | `CONF_ENFORCEMENT_WORKFLOW_RULES.json`, `INCLUDES_CRM.js`, and relevant event scripts |
| DPW interface insert/mapping behavior | `InterfaceAccelaCRMWithDPWWorkOrders/src/util/ShareServletMethods.java` (`insertRecord`) |
| DPW service description lookup | `InterfaceAccelaCRMWithDPWWorkOrders/src/util/EservUtil.java` (looks up `SERVICE_DESC` using both `DIVISION` and `SERVICE_NUM`) |
| DPW service/destination mapping and transfer queues | `DPW.CRM_TO_DPW_RECORD_MAPPING`, `DPW.CRM_TO_CC_XFER_QUEUE`, and the DPW update queues in the target DPW database |

## Consolidated source documents

These documents informed this reference and remain in their application repositories:

| Document | Use and caveat |
|---|---|
| `accela-scripts/Scripts/Interface/CRM-INTEGRATION-HOW-TO.md` | Detailed CRM, Accela, DPW, reverse-update, rename, and deployment examples. Verify each example against current source; it includes `DPW_Insert` Standard Choice arguments that differ from the shared CRM shadow handler. |
| `InterfaceAccelaCRMWithDPWWorkOrders/Civic to DPW.docx` | Short operational overview of Civic-to-DPW and DPW-to-Civic queues, CRMControl, and scheduled updates. It uses older `CONF_DPW_WORKORDERS.js` terminology; current source in this checkout uses `CONF_DPW_WORKORDERS.json`. |
| `InterfaceAccelaCRMWithDPWWorkOrders/RoutewareAccelaCreateDesign.md` | Separate Routeware-to-Accela record-creation design. Do not apply it as the PublicStuff CRM intake procedure. |

When these documents conflict, prefer verified current code/configuration and environment-specific
facts. Update this centralized reference when a reusable procedure changes; keep task-specific
record-type values and one-off decisions in that record type's own implementation notes.
