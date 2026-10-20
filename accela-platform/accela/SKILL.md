---
name: accela
description: 'Use for City of Milwaukee Accela Civic Platform work: EMSE scripts, record types, workflow, inspections, fees, and CRM/DPW integrations. Covers verifying production vs test configuration, choosing the authoritative source checkout (including accela-scripts for production CRM-to-DPW changes), committing/pushing source separately from EMSE deployment, and giving exact remaining system-owner actions for go-live.'
---

# Accela Skill

## Purpose

Help analyze a spec for a new or changed Accela record type, ground that analysis in the real
database configuration (not guesses), write/update the EMSE event scripts that implement it, and
give the user a clear, itemized list of manual admin-console steps they still need to do or
confirm.

## Scope

- City of Milwaukee's Accela Civic Platform ("Accela Automation") instance.
- EMSE (Enterprise Multi-purpose Scripting Engine) JavaScript event scripts: naming convention,
  event lifecycle, deployment flow.
- Reading the record-type/workflow/inspection/ASI/fee configuration out of the SQL Server snapshot
  of the Accela database to ground analysis in facts, not assumptions.
- Distinguishing what a script change can do vs. what requires manual Accela Admin configuration
  (workflow templates, inspection types/results, ASI groups, fee schedules, assignment
  groups/queues) — Admin config is not exposed through the scripts repo or any file this skill can
  edit.
- Out of scope: Accela GovXML/Construct API details beyond what's needed to read scripts; Accela
  Citizen Access (ACA) portal front-end customization beyond the `ACA*` event scripts already in
  the repo.

## Routing Boundaries

- Use for Accela record configuration, EMSE implementation, and admin/script
  boundaries. Pair with `accela-spec-normalizer` for loose record-type specs.
- For a PublicStuff/CRM request type that creates an Accela record and/or a DPW work order,
  read [`references/crm-to-accela-dpw-workorders.md`](references/crm-to-accela-dpw-workorders.md)
  before changing routing, allowlist, service-mapping, dispatch, or feedback configuration.
  Use its system-access table for PublicStuff, CRMControl, and Accela production URLs and safe
  credential-location guidance. Inspect the CRM request's Foreign Association directly and confirm
  its exact associated record type in production Accela before deciding which configs to change
  or deploy. If the association is absent, use the request and Accela configuration as evidence,
  flag the candidate as unconfirmed, and resolve it rather than guessing.
- For an inventory of `Scripts/Interface` libraries/configuration and the wider set of likely
  request-type change surfaces, read
  [`references/interface-folder-map.md`](references/interface-folder-map.md).
- Use `accela-reports` for Crystal Reports and report field maps; use the Java
  or SQL skill for generic language work without Accela-specific behavior.

## Environments

Confirm the authoritative source checkout and target environment for the task
before editing. Never infer the production source from the presence of a similarly
named test checkout, and never use a test checkout for a production change merely
because it was the usual location in an earlier workflow.

| Name | What it is | Access |
|---|---|---|
| `sql-dev ACCELAPROD` | Read-only SQL Server snapshot of the live Accela database (`AAPROD` on `SQL-DEV`) | Connect via the `mssql_*` tools, saved profile `sql-dev ACCELAPROD` |
| `sql-dev ACCELATEST` | Read-only SQL Server snapshot of the Accela **test** database (`AATEST` on `SQL-DEV`) | Connect via the `mssql_*` tools, saved profile `sql-dev ACCELATEST` |
| `accela-test` (git repo, workspace folder `accela-test`) | Test/development copy; use for work explicitly targeting AATEST, after verifying that target's configuration | Do not treat as the source for a production release |
| `accela_scripts` | Deployment-side script location referenced by older repository guidance | Do not assume direct file copy is the current deployment procedure. For the Road Plate request, the user confirmed deployment through Accela's EMSE Script Manager/tool. |
| `accela-scripts` (git repo) | Production source repository for the CRM-to-DPW request-type change in this workflow; contains `Scripts/Event`, batch, config, interface, pageflow, and set scripts | Edit, validate, commit, and push production source here; the repository itself is not the EMSE deployment |
| `accela-supp` (git repo) | Supplementary/reference copy of scripts (older or parallel copy) | Check here if `accela-test` is missing context on an existing script |

**`ACCELAPROD` and `ACCELATEST` can and do disagree on record-type config** — e.g. a workflow
process split or new status may already exist in `ACCELATEST` from earlier in-progress work that
was never promoted to prod (see the "Detecting In-Progress/Stale Work" note below). Always state
which environment a fact came from when they diverge; don't silently assume one is authoritative.

**Production CRM-to-DPW source rule:** production request-type integration changes belong in
`accela-scripts`, not `accela-test`. Use `accela-test` only for a change explicitly targeting
AATEST or when current task-specific instructions identify it as the authoritative source. Preserve
unrelated worktree changes; review the exact diff, validate it, and commit/push only the in-scope
files. The Git repository is source control, not the deployment. Publish separately through the
Accela EMSE Script Manager/tool to the confirmed production tenant. Older guidance mentioning
`accela_scripts` is not authorization to copy files there; use that path only if the system owner
confirms it is the active deployment process.

### Detecting In-Progress or Stale Work Across Environments

Before assuming a spec describes brand-new work, check whether `ACCELATEST` already differs from
`ACCELAPROD` for the same record type — it may mean an earlier redesign was started and stalled.

- Compare the record type's `R1_PROCESS_CODE` (and other key config) between the two environments
  first — a different value in test is a strong signal of unfinished work, not a data error.
- Every config table carries `REC_DATE`. Compare it across environments: a recent `REC_DATE` in
  `ACCELATEST` alongside an old, unchanged one in `ACCELAPROD` for the same row/key means the
  change was made in test and never promoted.
- Cross-reference the `REC_DATE` against TFS history (`tfs-boards` skill) for the same record type
  — a work item completed/updated around the same date confirms which effort produced the change,
  and an item still open (not Done/Closed) since then means the work stalled mid-flight rather than
  being intentionally abandoned.
- Found exactly this pattern for Skid Violation (2026-08-05): `ACCELATEST` already has a dedicated
  `PW_SAN_SKID_VIO` process (split off from the shared `PW_SAN_COMP_CV2`) with an added
  `Inspection` task and extra statuses (`Assess`/`Assessed` split, a `Billed` status), all
  `REC_DATE`d 2026-06-08/09 — matching TFS tasks #374/#375/#384/#390/#391 (Done, same dates) under
  PBI #373, plus a UAT task (#392) still `In Progress` since then. `ACCELAPROD`'s config is
  untouched since 2025-12-16. Conclusion: an earlier redesign was built and partially UAT-tested in
  `ACCELATEST` but never finished/promoted — the newly-received spec is very likely describing (or
  refining) that same still-open effort, not a fresh, unrelated request.

## Workflow for a New/Changed Record-Type Spec

1. **Create/confirm a TFS work item for the spec analysis itself** (see
   [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) Step 1) — this
   tracks "flesh this spec out into a plan" on the board from the start, before any DB research.
2. **Identify the record type key** — Module/Type/SubType/Category (the same 4 segments used in
   EMSE filenames as `Module!Type!SubType!Category`, and in `appMatch('Module/Type/SubType/Category')` calls).
3. **Confirm the target environment and query its baseline config** using
   [`references/database-schema.md`](references/database-schema.md): record type row, workflow
   tasks, inspection types + result sets + auto-assign flags, ASI (SmartChoice) fields, fee items.
   For the usual `accela-test` development workflow, query `sql-dev ACCELATEST`
   first, then compare `sql-dev ACCELAPROD` for promoted/live configuration.
   Label every finding by environment; never report test-only config as production.
   Don't guess at existing result values, task names, or fee codes — look them up.
  - Verify the inspection type's `AUTO_ASSIGN` flag and target group/result-group wiring, and keep
    the script names / branch names aligned with the exact inspection, result, task, and status
    strings that exist in the DB.
4. **Read the existing scripts** for this record type and any wildcard (`~`) parent scripts that
   also fire for it, in the confirmed source checkout's `Scripts/Event/`. See
   [`references/emse-scripts.md`](references/emse-scripts.md) for the naming/prefix convention and
   which scripts fire on which events.
  - Before drafting the plan, use the pre-plan comparison checklist in
    [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) to compare the
    source note against the live inspection names/results, sibling record types, and any shared
    vs. dedicated script branches.
5. **Normalize the spec** against that baseline — note what already exists vs. what's new (new
   inspection result, new fee code, new workflow status, new ASI field, new CRM mapping).
6. **Produce the implementation plan and companion docs** the user expects (see
   [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) for the exact
   format, modeled on prior work in `accela-test/local-notes/`):
   - a **production-config-reference** doc (confirmed production config, with
     test-only differences clearly labeled)
   - a **manual-system-actions** doc (what the user must configure/confirm in Accela Admin —
     assignments, missing inspection results, fee item activation, workflow status labels, CRM
     mapping — since none of that is achievable through script/file changes)
   - plain-language **explainer doc(s)** with the end-to-end lifecycle diagram, plus a **test
     cases** doc mapped 1:1 to the normalized behavior
7. **Consolidate the explainers + test cases into one design-confirmation `.docx`** (see
   [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) Step 9) and get
   the requestor to confirm it matches their intent **before** implementation.
   This is a distinct, requestor-facing deliverable, not a repackaging of the
   two docs above (which are dev/admin-only).
8. **Create a TFS work item per major implementation step** (e.g. add/activate inspection results,
   update workflow tasks/statuses, add an ASI field, script changes per record type, each
  manual-admin action) using [`../../development-tools/tfs-boards/SKILL.md`](../../development-tools/tfs-boards/SKILL.md), parented under
   the item from step 1 — the board should reflect the plan before work starts, not after.
9. **Resolve open decisions, then write/update the EMSE scripts** in the confirmed
   source checkout for the requested target. For production CRM-to-DPW changes in
   this workflow, use `accela-scripts`; do not edit `accela-test` as a substitute.
   Never guess unconfirmed assignments,
   result values, fee codes, or task/status strings.
10. **Validate the normalized behavior and confirm deployment authorization and
    exact target** before publishing. Prepare an exact deployment manifest: each source
    path, EMSE script name/type, and complete content to publish. A Git commit/push
    alone does not deploy scripts.

## Manual Admin Steps — Always Check These

These are configured in the Accela Admin console, not in any file this skill can edit. See
[`references/manual-admin-steps-checklist.md`](references/manual-admin-steps-checklist.md) for the
full checklist and how to verify each one via SQL before asking the user to act.

- Assignment groups/queues that "auto-assign" resolves to (department/individual).
- Inspection type existence, its result-group membership, and whether `AUTO_ASSIGN` is set.
- Whether a given inspection *result* value exists yet (adding one is Admin-only).
- Fee item existence/activation and its fee schedule assignment.
- Workflow status label text (scripts branch on exact string matches).
- New workflow task existence in the process template (adding a task/step is Admin-only).
- ASI (SmartChoice) group/field existence if the spec references a new custom field.

## Keep This Skill Current

Record-type spec work regularly turns up things worth writing down for next time — do this before
finishing the task, not as an afterthought (see the `ai-skills` `AGENTS.md` "Feed Learnings Back
Into Skills" policy):

- **Heavy-lifting discoveries** — if you had to run several exploratory queries, cross-reference
  code values against repo memory, or dig through view definitions to figure out which table/column
  actually holds something, add the *answer* (table, column, join) to
  [`references/database-schema.md`](references/database-schema.md) so the next lookup is a read,
  not a rediscovery. This is exactly how the `V_CONFIG_WORKFLOW` stale-view caveat and the
  `SMARTCHOICE` (not `ASI`)/`R3APPTYP` (not `CAP_TYPE`) table-name corrections got into that file.
- **Mistakes you had to fix** — a wrong assumption about a table/column name, a query that returned
  the wrong thing, a manual-admin item you flagged that turned out to already exist (or vice
  versa) — write the corrected fact and a one-line note of the wrong assumption it replaces, so it
  doesn't get re-made.
- **New record-type patterns** — a new inspection/workflow/ASI/fee shape you hadn't seen before, or
  a new EMSE event prefix confirmed in a script body, belongs in `references/emse-scripts.md` or
  `references/database-schema.md` as appropriate.
- Keep updates short and factual (what's true, not the story of finding it) and only add genuinely
  reusable facts — one-off specifics of a single record type's spec belong in that task's own docs
  or configured Working Memory, not in this skill. An existing task-note location under
  `accela-test/local-notes/` does not make that repository the production script source.

### Where Learnings About This Task Live

"This task" = the whole create-or-modify-a-record-type job described above. Different kinds of
learning from doing it go in different places — don't dump everything into one file:

| Kind of learning | Goes in |
|---|---|
| Reusable schema/script facts (table, column, join, event prefix) | [`references/database-schema.md`](references/database-schema.md) / [`references/emse-scripts.md`](references/emse-scripts.md) |
| Reusable process knowledge (how to run the task itself, what to check) | [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) / [`references/manual-admin-steps-checklist.md`](references/manual-admin-steps-checklist.md) |
| A finished, illustrative worked case (distilled after the fact, as a pattern to point future work at) | `examples/` in this skill |
| Live, in-progress work on one specific record type (raw spec, running TODO, config-reference, manual-actions, implementation plan) | Configured Working Memory/task folder or the established local-notes folder — task bookkeeping, not the production source; never copy raw task material into this skill |

## Required Go-Live Handoff

Do not end an implementation with only “not live,” “ask an admin,” or a generic deployment
instruction. After completing the work, report a concise status by system and list every remaining
action in execution order. For each action, identify the owner, target environment, exact UI/tool or
repository, exact values/files/script names, prerequisite or approval, and observable success check.

Always separate and report:

- **Source:** authoritative repository/branch, changed files, validation, commit, and push status.
- **CRM/DPW configuration:** CRMControl mapping row and generated key when available; the exact
  request-type, division, service number/description, transfer flag, and destination. Never ask the
  user to repeat an action already completed and verified.
- **Accela EMSE:** production or test tenant, each artifact's source path and deployed EMSE name,
  script type (event handler vs. named configuration text), whether the complete content was
  published, and whether deployment was verified.
- **Behavioral validation:** CRM intake/Foreign Association, Accela target record and workflow
  trigger, DPW transfer queue/work order, and return updates. State which checks passed or were not
  run and why.
- **Remaining actions:** name the responsible owner/system and provide exact steps, not an inferred
  or generic checklist. If blocked by access or approval, state precisely what is needed and do not
  claim deployment or go-live.

Never equate a source commit/push, a CRMControl row, or an EMSE save with the end-to-end route being
live. If a production request is required for validation, identify its side effects and get the
needed explicit approval before submitting it. Never send a Stage request through a configuration
that points to production.

## Related Skills

- [`references/database-schema.md`](references/database-schema.md) — verified schema, naming
  conventions, join recipes.
- [`references/emse-scripts.md`](references/emse-scripts.md) — event script naming/prefix
  convention and deployment.
- [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) — how to turn a
  spec into config-reference + manual-actions + implementation-plan docs, plus (Step 9) a
  requestor-facing design-confirmation `.docx`.
- [`references/manual-admin-steps-checklist.md`](references/manual-admin-steps-checklist.md) —
  what to flag for the user.
- [`references/crm-to-accela-dpw-workorders.md`](references/crm-to-accela-dpw-workorders.md) —
  when adding/changing a CRM request type, routing it into Accela, creating DPW work orders,
  or sending DPW status/comments back.
- [`references/interface-folder-map.md`](references/interface-folder-map.md) — when tracing
  `Scripts/Interface` file roles, includes, configuration files, or update impact.
- [`scripts/render-docx.sh`](scripts/render-docx.sh) — vendored copy of the
  `accela-spec-normalizer` skill's `.docx` render pipeline, used by Step 9. This is the only thing
  borrowed from that sibling skill — its diagram-consolidation style and `<gap>` convention are
  intentionally not used here.
- [`../../development-tools/sql/SKILL.md`](../../development-tools/sql/SKILL.md) — general T-SQL guidance.
- [`../../development-tools/tfs-boards/SKILL.md`](../../development-tools/tfs-boards/SKILL.md) — use alongside this skill to update the
  TFS/Azure DevOps board (`tfs.milwaukee.gov`) as spec work progresses: move the card when starting
  a phase, add a comment summarizing what was found/changed, and move it to done once implemented
  and deployed — don't let the implementation-plan doc's phase tracking be the only place status
  lives.
- [`../../shared/coding-standards.md`](../../shared/coding-standards.md)
