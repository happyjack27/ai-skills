# Skid Violation — normalized

## Header

| Field | Value |
|---|---|
| Record type (group / type / subtype / category) | `<gap>` |
| Workflow name | Skid Violation Workflow |
| Workflow tasks | Inspection, Reinspection, Payment |
| Inspection group | `<gap>` |
| Inspection types | San Skid Inspection, San Skid Reinspection |
| Fee schedule | `<gap>` |
| ASI groups and fields | Billing Status (value: Billed; full value list `<gap>`); Appeal/Assessment flag field name `<gap>` (values: Under Appeal, Assessment Issued) |
| Child record types | Scattered Litter/Debris Request, City Property Cleanup Request |
| Scripts and batch jobs | ASA, IRSA, WTUA, PRA, nightly past-due batch |

## Table A — Inspection types and results

| Inspection type | Result value | Result group | Schedules what | Offset + anchor | Assign to |
|---|---|---|---|---|---|
| San Skid Inspection | No Violation | — | None | — | — |
| San Skid Inspection | 1-4 cubic yards | — | San Skid Reinspection | +5 calendar days, anchor = inspection result date | `<gap>` |
| San Skid Inspection | 4+ cubic yards | — | San Skid Reinspection | +5 calendar days, anchor = inspection result date | `<gap>` |
| San Skid Inspection | Immediate – 1-4 cubic yards | — | San Skid Reinspection | Next business day, anchor = inspection result date | `<gap>` |
| San Skid Inspection | Immediate 4+ cubic yards | — | San Skid Reinspection | Next business day, anchor = inspection result date | `<gap>` |
| San Skid Inspection | Refer to DNS | — | None | — | — |
| San Skid Inspection | City Property – Illegal Dumping | — | None | — | — |
| San Skid Inspection | Duplicate | — | None | — | — |
| San Skid Inspection | Void | — | None | — | — |
| San Skid Reinspection | Collected | — | None | — | — |
| San Skid Reinspection | Done by Owner | — | None | — | — |
| San Skid Reinspection | Not Collected | — | None | — | — |

**Initial inspection isn't a result-driven row.** On record creation (and not flagged
Duplicate), San Skid Inspection itself is scheduled for the next business day from
record creation and assigned to the Sanitation Inspector role. Everything above governs
*results*, not the record's first inspection — see Table E.

## Table B — Workflow status routing

| Task | Status | Next task | Record disposition | Child record created |
|---|---|---|---|---|
| Inspection | No Violation | Terminal | Closed | None |
| Inspection | 1-4 cubic yards | Reinspection | In Progress | None |
| Inspection | 4+ cubic yards | Reinspection | In Progress | None |
| Inspection | Immediate – 1-4 cubic yards | Reinspection | In Progress | None |
| Inspection | Immediate 4+ cubic yards | Reinspection | In Progress | None |
| Inspection | Refer to DNS | `<gap>` | In Progress | Scattered Litter/Debris Request |
| Inspection | City Property – Illegal Dumping | `<gap>` | In Progress | City Property Cleanup Request |
| Inspection | Duplicate | Terminal | Closed | None |
| Inspection | Void | Terminal | Closed | None |
| Reinspection | Collected | Payment | In Progress | None |
| Reinspection | Done by Owner | Terminal | Closed | None |
| Reinspection | Not Collected | Terminal | Closed | None |
| Payment | Paid | Terminal | Closed | None |
| Payment | Past Due | Payment | In Progress | None |
| Payment | Appealed | `<gap>` | In Progress | None |
| Payment | Assessed | `<gap>` | In Progress | None |

The diagram states "(Do not close record)" explicitly for both Appealed and Assessed —
disposition is a stated fact here, not the derived default. Next task is still `<gap>`:
"Under Appeal" and "Assessment Issued" read as status labels the diagram draws next to
the status, not task names, and nothing routes onward from either.

## Table C — Status side effects

| Task | Status | Fee action | ASI update | Notification | Trigger type |
|---|---|---|---|---|---|
| Inspection | Duplicate | None | None | None | Event, if within 7 days; otherwise manual |
| Reinspection | Collected | Add + invoice | Billing Status = Billed | None | Event |
| Reinspection | Not Collected | None | Comment added (target field `<gap>`) | Supervisor `<gap role>`, channel `<gap>` | Event |
| Payment | Past Due | Add late fee | None | None | Batch |
| Payment | Appealed | None | `<gap field>` = Under Appeal | None | Event |
| Payment | Assessed | None | `<gap field>` = Assessment Issued | None | Event |

Note the Reinspection/Collected row: the effect updates a workflow task, so the script
will fire `WorkflowTaskUpdateAfter` on the Payment task as a cascade. Guard for it.

**"Billing" is modeled here as an ASI update, not a task.** The diagram draws it as its
own swimlane between Reinspection and Payment, the same visual weight as the three
real tasks. ASI updates don't normally get their own SPROCESS task in Accela, so this
is modeled as the Billing Status field changing on Reinspection/Collected — matching
the original loose bullet ("Update Billing to Billed") — rather than as a fourth task.
Confirm this reading; see open question 6.

## Table D — Fee definitions

| Fee code | Fee schedule | Triggering status | Tier basis | Source record/inspection | Invoice on add | Late rule |
|---|---|---|---|---|---|---|
| `<gap>` | `<gap>` | Reinspection / Collected | Cubic yards | **San Skid Inspection** (not the reinspection) | Yes | — |
| `<gap>` | `<gap>` | Payment / Past Due | Flat `<gap>` | — | `<gap>` | 37 days, anchor `<gap>` |

## Table E — Automation

| Trigger | Event or batch | Event name | Condition | Match key | Effect |
|---|---|---|---|---|---|
| Record created | Event | ApplicationSubmitAfter | Prior record within 7 cal days | `<gap>` | If duplicate: set Duplicate, close. Else: schedule San Skid Inspection next business day from creation, assign Sanitation Inspector |
| Inspection resulted | Event | InspectionResultSubmitAfter | Result value | — | updateTask, scheduleInspection, create child |
| Reinspection Collected | Event | WorkflowTaskUpdateAfter | Status = Collected | — | Read prior inspection result, addFee, invoiceFee, set Billing Status = Billed, activate Payment (cascades) |
| Reinspection Not Collected | Event | WorkflowTaskUpdateAfter | Status = Not Collected | — | Add comment, notify supervisor, close record |
| Payment received | Event | PaymentReceiveAfter | Balance zero `<gap>` | — | updateTask Payment = Paid, close |
| Invoice ages 37 days | Batch | `<gap>` | Unpaid at 37 days | — | addFee late fee, set Past Due |
| Payment Appealed | Event | WorkflowTaskUpdateAfter | Status = Appealed | — | Set `<gap field>` = Under Appeal; do not close |
| Payment Assessed | Event | WorkflowTaskUpdateAfter | Status = Assessed | — | Set `<gap field>` = Assessment Issued; do not close |

## Open questions

1. **Four-level record type, inspection group, and fee schedule are unnamed.** Nothing
   can be configured without them.
2. **The fee is priced from the wrong inspection.** `Collected` is a San Skid
   Reinspection result, but the cubic-yard value lives on the original San Skid
   Inspection. Confirm the script should read back the most recent San Skid Inspection,
   and state which one wins if a record carries more than one.
3. **Do the Immediate tiers bill the same as their base results?** The spec uses
   Immediate only to change the reinspection offset and never addresses the fee.
4. **Duplicate detection has no match key.** "Automated if placed within 7 calendar
   days" does not say what makes two records duplicates — address, location ID, or skid
   ID — nor whether the 7 days counts from the earlier record's open date or its
   inspection date.
5. **Appeal/Assessment flag has no stated resolution and no named field.** Appealed
   sets a flag to "Under Appeal" and Assessed to "Assessment Issued," both explicitly
   not closing the record — but neither the ASI/custom field name nor anything that
   later resolves the flag (a manual close? a third Payment status?) appears in the
   source.
6. **Is Billing a real workflow task, or the diagram's staging for an ASI update?**
   Modeled here as the Billing Status field changing on Reinspection/Collected, matching
   the loose spec's "Update Billing to Billed" — not as a fourth SPROCESS task. The
   diagram draws it with the same visual weight as Inspection/Reinspection/Payment, so
   confirm this reading before configuring.
7. **Refer to DNS and City Property don't name a next task for the parent.** Both
   create a child record and, absent an explicit close, leave the parent In Progress by
   default — but no task is named to own the parent afterward, nor whether it waits on
   the child's outcome.
8. **37 days from when, and who sets Past Due?** Invoice date or status-change date, and
   batch job or clerk.
9. **"Notify Supervisor" names no recipient and no channel.** Needs a user group or
   module role, and email versus in-platform.
10. **No path exists for a reinspection that is never resulted.**
