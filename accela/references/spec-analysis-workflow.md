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
phase itself (Steps 2-7 below) so it shows up on the board from the moment work starts, not just
once an implementation plan exists.

- Don't wait for Step 8's per-phase cards — those come later and cover the *implementation* work
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

## Step 8 — Create TFS Work Items for the Major Steps

Before starting the actual work (script edits, asking the user to make Admin changes), turn the
implementation plan's phases into TFS cards, using [`../../tfs-boards/SKILL.md`](../../tfs-boards/SKILL.md).
Do this once the plan is written (Step 7), not after work is already done — the point is to track
progress on the board as you go, not to log it retroactively.

- One item per major, independently-completable piece, not one giant catch-all card. Typical
  split for a record-type spec: **Admin config** items (new/reactivated inspection result, new
  ASI field, new fee item, new workflow status label — one per distinct Admin action, since each
  needs the user/an admin to actually go do it) and **script** items (one per EMSE script file or
  tightly-related group of files, e.g. "IRSA/WTUA/ASA changes for Skid Violation").
- Use `Task` for concrete execution work, `Bug` only if the spec is fixing a defect in existing
  behavior, `Product Backlog Item` for the overall record-type change if one doesn't already exist
  to parent the Tasks under — check first rather than assuming a PBI is already there (this may
  already be the item created in Step 1, in which case parent the new Tasks under it).
- Set `System.IterationPath` explicitly on each new item (defaults to project root, not the current
  sprint) and use `-ParentId` to link Tasks under the PBI — see the tfs-boards skill's Common
  Mistakes for both gotchas.
- Note each work item's id/link in the implementation plan doc next to the phase it corresponds to,
  so the doc and the board cross-reference each other.

## Keep the Docs Living

Update phase status (`NOT STARTED` / `COMPLETED (date)`) as work progresses, the same way the
construction-material implementation plan tracks it — this lets you or the user resume mid-task
without re-deriving what's done. If the work is tracked on the TFS board, mirror status there too
(move the card, add a comment) per [`../../tfs-boards/SKILL.md`](../../tfs-boards/SKILL.md) —
don't let the doc and the board drift out of sync.

## Step 9 — Feed Discoveries Back Into the Skill

Before considering the task done, check whether anything from Steps 2-7 is worth writing into the
skill itself rather than just the task's own docs — see "Keep This Skill Current" in
[`../SKILL.md`](../SKILL.md). In particular:

- Any table/column/join you had to hunt for (multiple exploratory queries, cross-referencing code
  values, reading a view definition) → add the confirmed answer to
  [`database-schema.md`](database-schema.md).
- Any wrong assumption that led to a bad query or a wrong manual-action flag → correct it in the
  relevant reference file with a short note of what was wrong.
- Any newly-confirmed EMSE event prefix or script pattern → [`emse-scripts.md`](emse-scripts.md).

Task-specific facts (this record type's specific fee code, this spec's specific decisions) stay in
the task's own docs under `accela-test/local-notes/` — only genuinely reusable facts belong in the
skill.
