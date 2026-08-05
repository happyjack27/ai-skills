# Tables A–E: column definitions

Every column here exists to catch a specific failure mode. Where a column has a rule,
the rule is followed by the reason.

---

## Table A — Inspection types and results

| Column | Rule |
|---|---|
| Inspection type | Exact name as configured in Accela. One block of rows per type. |
| Result value | Exact string from the source. Do not normalize casing or punctuation. |
| Result group | The Accela result group the value belongs to. Usually `<gap>` in loose specs. |
| Schedules what | Which inspection type this result causes to be scheduled, or `None`. |
| Offset + anchor | Both halves required: `+5 calendar days from result date`. |
| Assign to | Role, user group, or named inspector. Not "the inspector". |

**Offset + anchor is one column on purpose.** Specs routinely give a number without
units or without a starting point. Forcing both into one cell makes a half-answer
visibly incomplete instead of quietly passing.

---

## Table B — Workflow status routing

One row per status value. No exceptions — a status with no stated consequence still
gets a row, and the blank is the finding.

| Column | Rule |
|---|---|
| Task | Workflow task name. |
| Status | Exact status string. |
| Next task | The task activated, or `Terminal`, or `<gap>`. |
| Record disposition | `Open`, `Closed`, or `<gap>`. Independent of next task. |
| Child record created | Record type spawned, or `None`. |

**Next task and disposition are separate columns** because they come apart. A status can
close the parent while spawning a child, or advance a task while leaving the record
open. Merging them loses the distinction.

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
