# Tables A–E: column definitions

Every column here exists to catch a specific failure mode. Where a column has a rule,
the rule is followed by the reason.

---

## Table A — Inspection types and results

| Column | Rule |
|---|---|
| Inspection type | Exact name as configured in Accela. One block of rows per type. |
| Result value | Exact string from the source. Do not normalize casing or punctuation. |
| Result group | The Accela result group the value belongs to. Optional configuration metadata, not a blocking gap — mark `—` when unstated rather than `<gap>`, and don't carry it into the gap list. Unlike every other column here, it doesn't drive routing, fees, or automation. |
| Schedules what | Which inspection type this result causes to be scheduled, or `None`. |
| Offset + anchor | Both halves required: `+5 calendar days from result date`. |
| Assign to | Role, user group, or named inspector. Not "the inspector". |

**Offset + anchor is one column on purpose.** Specs routinely give a number without
units or without a starting point. Forcing both into one cell makes a half-answer
visibly incomplete instead of quietly passing.

**Anchor has a default for scheduling offsets.** When the spec gives an offset for the
*next inspection* and doesn't name an anchor, default to the triggering inspection's
result date — that's Accela's standard `scheduleInspection()` convention, not a guess.
Only mark `<gap>` here if the spec implies some other anchor without naming it. This
default is specific to Table A; it does not extend to fee or batch timers (Table D/E),
where no such convention exists and the anchor is a genuine open question.

---

## Table B — Workflow status routing

One row per status value. No exceptions — a status with no stated consequence still
gets a row, and the blank is the finding.

| Column | Rule |
|---|---|
| Task | Workflow task name. |
| Status | Exact status string. |
| Next task | The task activated, or `Terminal`, or `<gap>`. |
| Record disposition | `In Progress` or `Closed`. **Derived, never `<gap>`:** `Closed` only when the source explicitly closes the record ("Close Record" or equivalent); `In Progress` otherwise — even when Next task itself is still `<gap>`. A status that doesn't explicitly close the record leaves it exactly where it is. |
| Child record created | Record type spawned, or `None`. |

**Next task and disposition are separate columns** because they come apart, just not by
both being unknown at once. A status can spawn a child and still leave the parent
`In Progress`, or close the parent while also spawning a child. Read disposition off
whether the source says "close" — don't infer it from whether Next task is filled in.

---

## Table C — Status side effects

| Column | Rule |
|---|---|
| Task | Workflow task name. |
| Status | Exact status string. |
| Fee action | `Add`, `Add + invoice`, `Void`, `None`, or `<gap>`. Cross-references Table D. |
| ASI update | `Field = Value`, or `None`. |
| Notification | Role or user group **and** channel. "Supervisor" alone is a gap. |
| Trigger type | `Event` or `Batch`. Never blank. |

**Trigger type is mandatory** because it is the question specs never answer. Anything
involving elapsed time — a past-due fee, an escalation, an auto-close after N days —
cannot be event-driven, and discovering that during build is expensive.

---

## Table D — Fee definitions

| Column | Rule |
|---|---|
| Fee code | As configured. |
| Fee schedule | As configured. |
| Triggering status | Task and status from Table B. |
| Tier basis | The field whose value picks the amount. |
| Source record/inspection | **Which record and which inspection that field lives on.** |
| Invoice on add | `Yes` or `No`. |
| Late rule | Amount, threshold, and what the clock starts from. |

**The source record column is the one that earns this table.** Fees are frequently
triggered by one inspection and priced from a different one. Left implicit, the script
reads the wrong record and the error only shows up in billing.

---

## Table E — Automation

| Column | Rule |
|---|---|
| Trigger | Plain description of what happens in the world. |
| Event or batch | One or the other. |
| Event name | EMSE event (`ApplicationSubmitAfter`, `InspectionResultSubmitAfter`, `WorkflowTaskUpdateAfter`, `PaymentReceiveAfter`, ...) or the batch job name. |
| Condition | The guard the script evaluates. |
| Match key | For any lookup or dedupe: the fields compared. `<gap>` if unstated. |
| Effect | Function calls and their targets. |

**Watch for event cascades.** A script calling `updateTask()` inside an inspection-result
event fires `WorkflowTaskUpdateAfter`, which may fire its own script. Where a row's
effect updates a task, note the cascade in the Effect cell — it is where double-charged
fees come from.
