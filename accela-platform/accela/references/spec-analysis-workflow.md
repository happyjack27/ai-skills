# Turning a Spec into Grounded Analysis + Implementation

This mirrors the pattern already used in `accela-test/local-notes/sanitation record types
projects/` (see `construction-material-prod-config-reference.md`,
`construction-material-manual-system-actions.md`, `construction-material-implementation-plan-*.md`
for a real worked example) — reuse this structure for new spec work unless the user asks for
something different.

## Step 0 — Save the Raw Spec + Start a Running TODO File

Before analysis starts, save the spec as given (verbatim, or a faithful text extraction if it
arrived as a `.docx`/image) into its own project folder under
`accela-test/local-notes/<project name>/`, the way `trequest.md` preserves the original
Construction Material request text.

Alongside it, start a lightweight running TODO file — same folder, named like `things i need to
do.md` (see that file in the Construction Material project for the exact tone: short, flat
bullets, one line per action). This is your plan of attack: as you work, add to it every open
question, follow-up, and not-yet-verified item you find — don't only track this in conversation.
It's cheap to maintain and is what lets you (or the user) resume the task later without
re-deriving where things stood. It gets folded into / superseded by the formal
manual-system-actions doc once analysis is complete, but starts life as this scratch list. See
[`../templates/task-todo.md`](../templates/task-todo.md) for a blank starting point.

## Step 1 — Create/Confirm a TFS Work Item for the Spec Analysis Itself

Before diving into DB research, create (or confirm there already is) a TFS work item that
represents fleshing this spec out into concrete action items — using
[`../../tfs-boards/SKILL.md`](../../tfs-boards/SKILL.md). This tracks the *analysis/planning*
phase itself (Steps 2-8 below) so it shows up on the board from the moment work starts, not just
once an implementation plan exists.

- Don't wait for Step 10's per-phase cards — those come later and cover the *implementation* work
  once the plan is known. This item covers "figure out what the plan even is."
- A single `Task` (or `Product Backlog Item` if no parent exists yet for this record-type change)
  titled something like "Analyze <spec name> and produce implementation plan" is enough — it isn't
  meant to be broken down further until Step 8.
- Move/comment on it as analysis progresses, same as any other card (see "Keep the Docs Living").

## Step 2 — Pin Down the Record Type(s) Involved

Get (or confirm) the exact `Module/Type/SubType/Category` for every record type the spec touches,
including any it creates/references as a side effect (e.g. a DNS referral target, a CRM-linked
record). Don't accept a business-friendly name alone — look it up in `R3APPTYP` to get the exact
casing/spelling used elsewhere (`R1_APP_TYPE_ALIAS` vs. the 4-part key can differ).

## Step 3 — Query the Baseline Config (produces a "prod-config-reference" doc)

**Query `ACCELATEST` first, not `ACCELAPROD`.** The scripts you're editing live in `accela-test`,
and `accela-test`'s scripts are written against/deployed to `ACCELATEST` — that's the DB whose
config actually matches the code you're reading. `ACCELAPROD` is what's *live in production today*,
which can lag behind (see the "Detecting In-Progress or Stale Work" note in `../SKILL.md`) — query
it too, but to answer "what's actually deployed/promoted," not as your primary source of truth for
"what does the current script expect." Getting this backwards produces confidently-wrong findings
(e.g. concluding a task/status/inspection-result doesn't exist or isn't wired up, when it does and
is — just not yet promoted to prod).

Using [`database-schema.md`](database-schema.md), pull and record:

1. **Record type config** — group/type/subtype/category, alias, service provider.
2. **Sibling record types** sharing the same inspection group / workflow process / ASI group (so
   you know if a change to shared config affects other record types too).
3. **Available inspection types** for this record type (`INSP_CODE` → `RINSPTYP` rows) and their
   `AUTO_ASSIGN` flag.
4. **Current result options per inspection type** (`RINSP_RESULT_GROUP`), verbatim strings.
5. **Current workflow tasks/status labels** in step order, with default assignment
   department/individual.
6. **ASI/SmartChoice fields** already defined for the group.
7. **Fee items** already defined/active that the spec references.

While doing this, keep the names aligned exactly: if the source note uses a business-friendly phrase,
check whether the real `wfTask`, `wfStatus`, `INSP_TYPE`, or child-record name already exists under
that exact wording. The dedicated script names and branch conditions should mirror the final exact
inspection/result/status strings, so a shared wildcard branch can be disabled cleanly for that
record type.

Write this up as a dated reference doc (see the construction-material example for format): what's
confirmed to exist today, straight from the database, with no interpretation yet.

## Step 4 — Read the Current Scripts

Find every EMSE script that already touches this record type (its own file, its `~` wildcard
parent, and any file matching `eventMatch`/`appMatch` on it). Summarize current behavior in the
same doc or a "current baseline" section — what triggers, what it schedules/closes/creates today.

Also check `accela-test/Scripts/Batch/` for any existing scheduled batch job on this record type
or a sibling one — time-based behavior the spec asks for ("past due after N days", "auto-close if
within N days") usually can't be computed from an incoming event alone and needs a daily batch job.
A sibling's existing batch job (e.g. `BATCH_SAN_CONSTMAT_PAST_DUE.js`) is the pattern to model a new
one on, not something to design from scratch.

**Never reuse an existing inspection type string (`scheduleInspection("X", ...)` / `inspType == "X"`)
without confirming which record type actually owns it.** A shared `INSP_CODE` group (see
[`database-schema.md`](database-schema.md)'s Inspections section) is normal and fine to reuse — the
individual `INSP_TYPE` rows inside it are not automatically shared just because they're visible in
that group. Grep every sibling script for the literal type string first; if it's the name a
*different* category's own dedicated script branches on, it belongs to that category, no matter how
generic the name sounds (`"San. Inspection"` turned out to belong to a distinct
`Enforcement/Complaint/Sanitation/Inspection` record type, not to Skid Violation, even though both
share the same `INSP_CODE` — caught only after scripts were already written and committed against
it). The record type you're working on needs its own dedicated `INSP_TYPE` — new Admin config, not
a code fix.

### Pre-Plan Comparison Checklist

Before writing the implementation plan, do one short pass to compare the source note against the
actual configured names and the nearby sibling implementation. Keep this local and factual:

- Compare the note's inspection names and result names against the live `RINSPTYP` and
  `RINSP_RESULT_GROUP` values.
- Compare the note's workflow shape against the actual workflow tasks and status labels in the DB,
  including any shared process siblings.
- Compare the record-specific script surface against the shared wildcard script and identify which
  branches are already generic and which need dedicated files.
- Compare any business-friendly child-record names in the note against the exact `createChild(...)`
  and `editAppSpecific(...)` strings already used elsewhere.
- If the note is clearly asking for a Skid-Violation-style split, note both halves of the change:
  create the dedicated record-specific EMSE files and disable the overlapping shared-branch logic
  for that record type.
- Treat name mismatches as a planning item, not a coding assumption: record them in the running
  TODO / implementation plan before drafting file-by-file work.

## Step 5 — Normalize the Requested Behavior

Rewrite the spec as an explicit numbered list of behaviors (see the "Requested Behavior
(Normalized)" section in the implementation-plan example) — CRM intake mapping, initial
scheduling, per-result branching, payment/timing branches, etc. This is what you'll actually
implement against, and what test cases get written from later.

Specs are often written in rough/vague business language, not exact system terms — e.g. a listed
inspection result or status name may be a close paraphrase of one that already exists. Where the
intent is clearly the same, normalize the spec's wording to the existing exact value instead of
treating it as a request for something new; only flag a genuine new value (Step 6) when it isn't
just a naming variance.

## Step 6 — Diff Requested vs. Baseline → Manual Actions Doc

For every piece of the normalized behavior, classify it:

- **Already exists / no admin action needed** — script change only.
- **Needs new Admin config** — new inspection result value, new fee item, new workflow status
  label, new ASI field, new workflow task/step, or an assignment-group/queue that doesn't exist yet.
  None of these can be created by editing `accela-test` files or writing SQL against the AAPROD
  snapshot (read-only) — they require the user (or an Accela admin) acting in the Accela Admin
  console.
- **Needs a decision, not just config** — e.g. which existing status label to reuse, which
  assignee/queue an "auto-assign" role should resolve to, which of several similar existing record
  types is the intended target for a cross-reference (DNS referral, etc.). Exhaust research first
  (grep sibling scripts, check DB config, read the spec text again) before treating anything as
  open — see Step 4/5. Most things that look like open decisions turn out to already be answered
  somewhere in the codebase or DB.
- **Needs the requestor's clarification** — a genuine business-intent question that no amount of DB
  or script research can answer, because it's not a question about what already exists, it's a
  question about what the business actually wants. Keep this list separate from the two above:
  those are things *the user* (as developer/admin) can decide; these need to go back to whoever
  wrote the spec. Typical examples: an ambiguous reference date ("within 7 days of *what* event,
  exactly?"), a business rule not covered by the spec's examples (holidays/weekends?), or wording
  that could plausibly mean two different things operationally. Don't guess and don't silently pick
  one — list the question plainly, e.g. `local-notes/<project>/questions-for-requestor.md`, so the
  user can forward it as-is.
  - **Before adding anything here, grep/read the target record type's own sibling scripts first.**
    A behavior that looks like it needs the requestor to weigh in ("should duplicates really
    auto-close?") is very often just a missing feature that a near-identical sibling record type
    already implements — e.g. Skid Violation's spec calling for duplicate-detection turned out to
    be a plain gap (its `ASA` script had zero dedup logic) with an exact precedent to copy
    (Construction Material's `ASA` script). That's a Step 5/normal-implementation item, not a
    business question — don't escalate it to the requestor just because it's not implemented yet.

Write these as a separate dated "manual-system-actions" doc, grouped by theme (assignee config,
inspection result config, destination/mapping confirmation, fee setup, workflow/status labels) —
see [`manual-admin-steps-checklist.md`](manual-admin-steps-checklist.md) for the recurring
categories to check every time.

## Step 7 — Implementation Plan + Work

Produce an implementation plan doc with:

- Objective (1-2 sentences).
- Normalized requested behavior (from Step 5).
- Current baseline (from Steps 3-4).
- Phased work plan, each phase naming the exact file(s) to touch.
- Explicit **open decisions to resolve before coding** (pulled from Step 6's "needs a decision"
  items) — don't silently pick one and proceed.
- Test cases mapped 1:1 to normalized behaviors.
- Suggested file touch list.

Then implement in `accela-test`, per [`emse-scripts.md`](emse-scripts.md), and remind the user
about the deploy step (copy to `accela_scripts`) — implementing in `accela-test` alone does not
change production/test system behavior.

## Step 8 — Write Plain-Language Explainer Docs for the Requestor

The implementation plan (Step 7) and manual-actions doc (Step 6) are written for you/the next
developer — dense, technical, cross-referenced. The requestor also needs a **separate**,
plain-language explanation of what's changing and why, or they have no way to sanity-check the
plan against their own mental model of the business process.

- Write one short `.md` file per major component (mirror however Step 9's TFS cards end up split —
  e.g. one for Workflow, one for Inspections, one for Scripts, one for Testing), in the same
  `local-notes/<project>/` folder, named `<project>-<component>-explainer.md`.
- Each file: what's changing, current state vs. target state, in plain sentences — no SQL, no
  table/column names unless truly necessary. Ground every claim in facts already gathered in
  Steps 2-6; never invent a fact to fill a gap — flag it as an open item to confirm instead (e.g.
  "confirm during testing" or "confirm with admin").
- **Include a Mermaid diagram of the end-state record lifecycle** (a `flowchart` or `stateDiagram`
  covering creation → every task/result branch → close, using the actual status/result names) for
  at least the primary workflow file — this is usually the fastest way for a non-technical
  requestor to confirm the plan matches their intent.
- **Do this as soon as the implementation plan (Step 7) is drafted, not as an afterthought.** This
  step was requested up front in a real task (2026-08-05, PBI #373 Skid Violation) and then
  dropped/forgotten across several follow-up turns (bulleted TFS descriptions, a test-cases file,
  card splits) — the user had to ask for it three separate times before it got done. Treat it as
  a checklist item you complete immediately after Step 7, not something to get back to eventually.

## Step 9 — Consolidate into a Design-Confirmation `.docx` for the Requestor

The explainer(s) from Step 8 and the test cases from Step 7 are the last things that exist
*before* any code is written. Package them into a single reviewer-facing `.docx` and get the
requestor to confirm it matches their intent **before** starting the implementation tail end of
Step 7 — this is the cheapest point to catch a misread requirement, and the last one before it
costs a rewrite. If schedule pressure forces implementation to start in parallel, say so to the
user explicitly as a flagged risk rather than silently skipping the checkpoint.

This is a distinct deliverable from Step 7/8's own docs, not a repackaging of all of them — it
drops everything that's only meaningful to the developer/admin building the thing:

| Keep (drives confirmation) | Drop (internal/dev-only) |
|---|---|
| End-to-end lifecycle diagram + walkthrough (Step 8) | prod-config-reference doc (Step 3) |
| Open questions needing the requestor's answer (Step 6) | manual-system-actions doc (Step 6) |
| Test scenarios, plain-language (Step 7) | implementation plan phases/file lists (Step 7) |
| | database/table/column names |

### Organization

One `.md` file, in this order (blank starting point:
[`../templates/design-confirmation-template.md`](../templates/design-confirmation-template.md)):

1. **Cover** — record type, source spec + date, doc status (draft / in review / confirmed), TFS
   link(s), and a one-paragraph purpose statement: *this is our understanding of the target
   design; please confirm it before we build it.*
2. **What's changing** — 2-3 sentences per component (Workflow/Inspections/Scripts/etc.), each
   pulled from that Step 8 explainer's own "Current state vs. target state" section — summarize,
   don't reproduce the whole explainer.
3. **The end-to-end record lifecycle (target state)** — the Step 8 diagram, embedded as a
   rendered image, followed by the same plain-language step-by-step walkthrough from the
   workflow explainer. This is the section the user asked to lead with, and it's the fastest way
   for a non-technical reader to confirm the shape of the design.
4. **Decisions we need you to confirm** — every item from Step 6's "needs the requestor's
   clarification" list plus each explainer's "open items to confirm" checklist, de-duplicated and
   rephrased as plain business questions (no SQL/config detail). Call this section out visibly
   (bold header, numbered) — it's the actual ask, not background reading.
5. **Test scenarios to validate** — the Step 7 test-cases doc, reworded as "if this happens, this
   should happen" rows grouped by phase (creation → inspection → reinspection → billing/payment →
   regression), same order as the source doc. Keep status/result names verbatim — the requestor
   will recognize them from the live system — but drop TFS IDs, script filenames, and internal
   fee/table codes that mean nothing to them.
6. **How to respond** — one short paragraph: confirm/answer each numbered item in section 4, and
   flag any row in section 5 whose expected result doesn't match their intent.

### Building it

```bash
bash ../scripts/render-docx.sh <project>-design-confirmation.md
```

[`../scripts/render-docx.sh`](../scripts/render-docx.sh) is a vendored copy of the
`accela-spec-normalizer` skill's own render script (copied in, not linked, since the two skills'
diagram conventions have diverged — see "Borrowed from `accela-spec-normalizer`" below). Keep
diagrams for this doc as **one edge per result value**, not consolidated by shared source/target —
that's the layout this skill's own end-to-end lifecycle diagrams already use and is preferred over
the more consolidated style `accela-spec-normalizer` uses for its own diagrams.

- The script embeds each diagram as a rendered image, falling back `mmdc` → `npx @mermaid-js/mermaid-cli`
  → `rsvg-convert` → the Kroki HTTP API — say so plainly and hand over the `.md` alone if none are
  available, rather than shipping a `.docx` with raw mermaid text pasted in as a paragraph.
- **Verify the images actually landed** (unzip the `.docx` and check `word/media/`, or just open
  it) before calling this done.
- Save the output in the project's `local-notes/<project name>/` folder alongside the other docs.

### Borrowed from `accela-spec-normalizer`

That skill solves the same "loose spec → something a requestor can validate" problem and already
had a working `.docx` consolidation pipeline. The **only** thing taken from it here is that
render script (vendored as [`../scripts/render-docx.sh`](../scripts/render-docx.sh)) — its diagram
consolidation style and `<gap>`-tagging convention are deliberately *not* adopted: this skill's
existing per-result-value diagram layout is preferred, and whether an equivalent to the `<gap>`
convention makes sense here is still an open question, not a decision — revisit it later rather
than importing it by default.

## Step 10 — Create TFS Work Items for the Major Steps

Before starting the actual work (script edits, asking the user to make Admin changes), turn the
implementation plan's phases into TFS cards, using [`../../tfs-boards/SKILL.md`](../../tfs-boards/SKILL.md).
Do this once the plan is written (Step 7), not after work is already done — the point is to track
progress on the board as you go, not to log it retroactively.

- One item per major, independently-completable piece, not one giant catch-all card. Typical
  split for a record-type spec: **Admin config** items (new/reactivated inspection result, new
  ASI field, new fee item, new workflow status label — one per distinct Admin action, since each
  needs the user/an admin to actually go do it) and **script** items (one per EMSE script file or
  tightly-related group of files, e.g. "IRSA/WTUA/ASA changes for Skid Violation").
  - **Never merge an Admin config item into a script card just because they cover the same
    component/theme** (e.g. both are "about inspections"). Test: would doing this item require
    opening the Accela Admin console, or opening an editor? Those are always two different cards,
    even if a component-based grouping (Inspections/Workflow/Scripts) would otherwise put them
    together. This was gotten wrong in practice (2026-08-05, PBI #373): a card titled "inspections
    (IRSA scripts + result config)" bundled real script edits with a pure Admin-console action
    (reactivate an inspection result, add a new one) and had to be split apart after the user
    caught it. Put "(Accela Admin config)" in the title of any config-only card so the split is
    obvious at a glance.
- Use `Task` for concrete execution work, `Bug` only if the spec is fixing a defect in existing
  behavior, `Product Backlog Item` for the overall record-type change if one doesn't already exist
  to parent the Tasks under — check first rather than assuming a PBI is already there (this may
  already be the item created in Step 1, in which case parent the new Tasks under it).
- Set `System.IterationPath` explicitly on each new item (defaults to project root, not the current
  sprint) and use `-ParentId` to link Tasks under the PBI — see the tfs-boards skill's Common
  Mistakes for both gotchas. **Don't copy the parent PBI's `IterationPath` blindly** — a PBI that's
  been open a while is often still sitting in an old/closed sprint. Actually query
  `work/teamsettings/iterations?$timeframe=current` and use that value, then verify by re-fetching
  the new item and comparing against the query result — don't just trust the value you intended to
  send.
- Note each work item's id/link in the implementation plan doc next to the phase it corresponds to,
  so the doc and the board cross-reference each other.

## Keep the Docs Living

Update phase status (`NOT STARTED` / `COMPLETED (date)`) as work progresses, the same way the
construction-material implementation plan tracks it — this lets you or the user resume mid-task
without re-deriving what's done. If the work is tracked on the TFS board, mirror status there too
(move the card, add a comment) per [`../../tfs-boards/SKILL.md`](../../tfs-boards/SKILL.md) —
don't let the doc and the board drift out of sync.

## Step 11 — Feed Discoveries Back Into the Skill

Before considering the task done, check whether anything from Steps 2-8 is worth writing into the
skill itself rather than just the task's own docs — see "Keep This Skill Current" in
[`../SKILL.md`](../SKILL.md). In particular:

- Any table/column/join you had to hunt for (multiple exploratory queries, cross-referencing code
  values, reading a view definition) → add the confirmed answer to
  [`database-schema.md`](database-schema.md).
- Any wrong assumption that led to a bad query or a wrong manual-action flag → correct it in the
  relevant reference file with a short note of what was wrong.
- Any newly-confirmed EMSE event prefix or script pattern → [`emse-scripts.md`](emse-scripts.md).
- Anything that made Step 9's design-confirmation `.docx` harder than it should've been (a diagram
  layout that didn't survive rendering, a rendering-pipeline bug) → fix it directly in
  [`../scripts/render-docx.sh`](../scripts/render-docx.sh) — it's a vendored copy local to this
  skill, not shared with `accela-spec-normalizer`, so fix it here rather than upstream.

Task-specific facts (this record type's specific fee code, this spec's specific decisions) stay in
the task's own docs under `accela-test/local-notes/` — only genuinely reusable facts belong in the
skill.
