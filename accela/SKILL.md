---
name: accela
description: 'Use for Accela Civic Platform work: EMSE event scripts, Automation/Construct API, custom fields (ASI/SmartChoice), workflow tasks (SPROCESS), inspections and auto-assign, record type (R3APPTYP) analysis, fee schedules, batch jobs, and Accela-to-external-system (CRM/DPW) integrations for the City of Milwaukee instance. Covers reading a new-record-type spec, querying the SQL-DEV ACCELAPROD snapshot to find existing config, writing/updating EMSE scripts in accela-test, and identifying which setup steps must be done manually by an Accela admin (assignments, inspection results, fee items, workflow status labels) vs. which are code.'
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

## Environments

| Name | What it is | Access |
|---|---|---|
| `sql-dev ACCELAPROD` | Read-only SQL Server snapshot of the live Accela database (`AAPROD` on `SQL-DEV`) | Connect via the `mssql_*` tools, saved profile `sql-dev ACCELAPROD` |
| `sql-dev ACCELATEST` | Read-only SQL Server snapshot of the Accela **test** database (`AATEST` on `SQL-DEV`) | Connect via the `mssql_*` tools, saved profile `sql-dev ACCELATEST` |
| `accela-test` (git repo, workspace folder `accela-test`) | Working/dev copy of the EMSE scripts. **Start every change here.** | Git repo, edit directly |
| `accela_scripts` | Deployment target folder that the live Accela app server actually reads scripts from | Copy files here to deploy — **not the same as the `accela-scripts` git repo** (see note below) |
| `accela-scripts` (git repo) | A different repo in this workspace; despite the similar name it currently holds unrelated `LaborComplianceReporting` SQL reports, not the deployed Accela scripts folder | Don't confuse with `accela_scripts` |
| `accela-supp` (git repo) | Supplementary/reference copy of scripts (older or parallel copy) | Check here if `accela-test` is missing context on an existing script |

**`ACCELAPROD` and `ACCELATEST` can and do disagree on record-type config** — e.g. a workflow
process split or new status may already exist in `ACCELATEST` from earlier in-progress work that
was never promoted to prod (see the "Detecting In-Progress/Stale Work" note below). Always state
which environment a fact came from when they diverge; don't silently assume one is authoritative.

**Workflow: dev in `accela-test` → deploy by copying the finished file(s) to `accela_scripts`.**
Confirm the exact `accela_scripts` path with the user before a real deploy if it isn't already
known in this session — it's a filesystem/deployment target, not necessarily under version control
the way `accela-test` is.

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
3. **Pull the baseline config from `sql-dev ACCELAPROD`** using the queries in
   [`references/database-schema.md`](references/database-schema.md): record type row, workflow
   tasks, inspection types + result sets + auto-assign flags, ASI (SmartChoice) fields, fee items.
   Don't guess at existing result values, task names, or fee codes — look them up.
4. **Read the existing scripts** for this record type and any wildcard (`~`) parent scripts that
   also fire for it, in `accela-test/Scripts/Event/`. See
   [`references/emse-scripts.md`](references/emse-scripts.md) for the naming/prefix convention and
   which scripts fire on which events.
5. **Normalize the spec** against that baseline — note what already exists vs. what's new (new
   inspection result, new fee code, new workflow status, new ASI field, new CRM mapping).
6. **Write/update the EMSE scripts** in `accela-test`.
7. **Produce the companion docs** the user expects for this kind of task (see
   [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) for the exact
   format, modeled on prior work in `accela-test/local-notes/`):
   - a **production-config-reference** doc (what's confirmed to already exist, queried from the DB)
   - a **manual-system-actions** doc (what the user must configure/confirm in Accela Admin —
     assignments, missing inspection results, fee item activation, workflow status labels, CRM
     mapping — since none of that is achievable through script/file changes)
   - plain-language **explainer doc(s)** with the end-to-end lifecycle diagram, plus a **test
     cases** doc mapped 1:1 to the normalized behavior
8. **Consolidate the explainers + test cases into one design-confirmation `.docx`** (see
   [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) Step 9) and get
   the requestor to confirm it matches their intent **before** starting the implementation tail
   end of step 6/7 — this is a distinct, requestor-facing deliverable, not a repackaging of the
   two docs above (which are dev/admin-only).
9. **Create a TFS work item per major implementation step** (e.g. add/activate inspection results,
   update workflow tasks/statuses, add an ASI field, script changes per record type, each
   manual-admin action) using [`../tfs-boards/SKILL.md`](../tfs-boards/SKILL.md), parented under
   the item from step 1 — the board should reflect the plan before work starts, not after.
10. Flag anything you couldn't confirm from the DB (e.g., which user/queue an assignment group
    resolves to) as an **open decision** rather than guessing.

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
  in `accela-test/local-notes/`, not in this skill.

### Where Learnings About This Task Live

"This task" = the whole create-or-modify-a-record-type job described above. Different kinds of
learning from doing it go in different places — don't dump everything into one file:

| Kind of learning | Goes in |
|---|---|
| Reusable schema/script facts (table, column, join, event prefix) | [`references/database-schema.md`](references/database-schema.md) / [`references/emse-scripts.md`](references/emse-scripts.md) |
| Reusable process knowledge (how to run the task itself, what to check) | [`references/spec-analysis-workflow.md`](references/spec-analysis-workflow.md) / [`references/manual-admin-steps-checklist.md`](references/manual-admin-steps-checklist.md) |
| A finished, illustrative worked case (distilled after the fact, as a pattern to point future work at) | `examples/` in this skill |
| Live, in-progress work on one specific record type (raw spec, running TODO, config-reference, manual-actions, implementation plan) | `accela-test/local-notes/<project name>/` — task bookkeeping, not part of this skill, never copied here |

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
- [`scripts/render-docx.sh`](scripts/render-docx.sh) — vendored copy of the
  `accela-spec-normalizer` skill's `.docx` render pipeline, used by Step 9. This is the only thing
  borrowed from that sibling skill — its diagram-consolidation style and `<gap>` convention are
  intentionally not used here.
- [`../sql/SKILL.md`](../sql/SKILL.md) — general T-SQL guidance.
- [`../tfs-boards/SKILL.md`](../tfs-boards/SKILL.md) — use alongside this skill to update the
  TFS/Azure DevOps board (`tfs.milwaukee.gov`) as spec work progresses: move the card when starting
  a phase, add a comment summarizing what was found/changed, and move it to done once implemented
  and deployed — don't let the implementation-plan doc's phase tracking be the only place status
  lives.
- [`../shared/coding-standards.md`](../shared/coding-standards.md)
