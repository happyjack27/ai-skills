# Manual Admin Steps Checklist

Run through this list for every new/changed record type spec. For each item: **verify first via
SQL** (read-only, `sql-dev ACCELAPROD`) whether it already exists; only flag it to the user as a
manual action if it's genuinely missing or ambiguous. Don't ask the user to confirm something you
can just look up.

## 1. Assignment / Auto-Assign

- Does the inspection type have `RINSPTYP.AUTO_ASSIGN` set? If the spec assumes auto-assign
  happens and it's not set, that's Admin config, not a script bug.
- What department/individual does a workflow task's default assignment
  (`SPROCESS_DEF.ASGN_*` → `G3DPTTYP`) actually resolve to? Confirm this matches the role name used
  in the spec (e.g. "Sanitation Inspector", "Skid") — the plain-English role name in a spec is not
  guaranteed to map 1:1 to a `G3DPTTYP` department name.
- **Never guess a specific person/queue's identity.** This is exactly the kind of thing that must
  come from the user/project owner, not be inferred from data.

## 2. Inspection Configuration

- Does the inspection type (`RINSPTYP`) already exist for this record type / inspection group?
- Does every result value the spec requires already exist in `RINSP_RESULT_GROUP` for that
  inspection's result group? Missing values must be added in Accela Admin — flag by exact name.
- Is the inspection type shared across multiple sibling record types (common in this DB — see
  [`database-schema.md`](database-schema.md))? If so, confirm whether the spec wants to add a
  result specific to one category or if it will appear for all siblings sharing that group.
- If the spec wants an inspection result to auto-schedule a follow-up inspection, check
  `XRINSPTYP` for whether that (parent result → child inspection) mapping already exists at the
  right interval.

## 3. Workflow / Status Labels

- Do the exact status label strings the spec/script will branch on (`wfStatus`) already exist in
  `R3STATYP.R3_ACT_STAT_DES` for this process? Scripts compare strings exactly — confirm
  spelling/casing before writing the condition, and flag any label that doesn't exist yet as an
  Admin action (new workflow status/task = Admin console change).
- Does every workflow task name the spec references (`wfTask`) already exist in `SPROCESS_DEF`?
  Adding a new task/step to a process template is Admin-only.
- **Is the workflow process (`R1_PROCESS_CODE`) shared by other record types?** Query `R3APPTYP`
  for every record type using the same process code before recommending a new/changed status label.
  A change here affects every sibling record type on that process, not just the one in the spec —
  found `PW_SAN_COMP_CV2` shared by 6 Sanitation complaint categories this way. Prefer adding a new
  status label over repurposing an existing one when the process is shared, and call out the
  sharing explicitly in the manual-actions doc so whoever configures it knows the blast radius.

## 4. Custom Fields (ASI / SmartChoice)

- Does the ASI group (`R3APPTYP.R1_SMARTCHOICE_CODE`) already contain every field the spec
  references (`SMARTCHOICE.BLOCK_NAME`)? A missing field is an Admin addition, and if it needs a
  picklist, its options (`SMARTCHOICE_OPTION`) are configured there too.

## 5. Fee Items

- Does the fee code the spec references exist and is it active (`RFEEITEM`, `REC_STATUS='A'`)?
- Is it wired to the record type's fee schedule (`XAPPTYP_FEESCHEDULE`)? If the spec expects
  automatic invoicing, confirm the fee's calc/invoice behavior is set up for that, not just that
  the code exists.

## 6. Cross-System / Destination Mapping

- If the spec creates or references another record type (e.g. a DNS referral, a linked
  enforcement case), confirm the *exact* destination `Module/Type/SubType/Category` with the user
  — don't assume the "obvious" sibling record type is correct; prior work in this codebase has
  found the existing script pointed at a target that needed reconfirming (see
  `construction-material-manual-system-actions.md` in `accela-test/local-notes/`).
- If a CRM (DPW work order) request type feeds this record type, confirm the request type is
  active/usable in CRM and that the mapping config (`CONF_DPW_WORKORDERS.json` or similar) uses the
  record type's exact key string.
- **Search existing scripts for a precedent before asking the user to name the destination.** A
  spec's business-friendly phrase ("Scattered Litter/Debris Request", "City Property Cleanup
  Request") often already has an exact implementation on a sibling record type (`grep` sibling
  `IRSA`/`WTUA` scripts for `createChild`/`DPW_Insert` calls) — found Construction Material's exact
  DNS-referral `createChild` pattern this way instead of asking the user to spell out the target.
  Only ask when no precedent exists or two different precedents plausibly apply (see item 7).

## 7. Scheduled / Batch Jobs

- Does the spec imply a time-based trigger ("past due after N days", "auto-close if placed within
  N days") that nothing in the EMSE event scripts can compute on its own (no incoming event fires
  after N days of inactivity)? That needs a **daily batch job**, not just an event-script edit —
  check `accela-test/Scripts/Batch/` for an existing job on a sibling record type first (e.g.
  `BATCH_SAN_CONSTMAT_PAST_DUE.js` is the precedent for Sanitation past-due timing) and model the
  new one on it rather than inventing the polling logic from scratch.
- Flag any new/changed batch job as its own line item in the implementation plan and its own TFS
  card — it has a separate deploy/scheduling step (register the job to run daily) beyond copying
  the file to `accela_scripts`.

## Output Format

Compile everything flagged here into a numbered "Manual Actions You Will Handle" doc, grouped by
theme, each item phrased as a concrete yes/no confirmation or action (not an open-ended question) —
match the tone of `construction-material-manual-system-actions.md`. Add a "Findings Used For These
Manual Actions" section underneath citing what you found in the DB that led to each flag.
