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
| ASI groups and fields | Billing (value: Billed); group and full value list `<gap>` |
| Child record types | Scattered Litter/Debris Request, City Property Cleanup Request |
| Scripts and batch jobs | ASA, IRSA, WTUA, PRA, nightly past-due batch |

## Table A — Inspection types and results

| Inspection type | Result value | Result group | Schedules what | Offset + anchor | Assign to |
|---|---|---|---|---|---|
| San Skid Inspection | No Violation | `<gap>` | None | — | — |
| San Skid Inspection | 1-4 cubic yards | `<gap>` | San Skid Reinspection | +5 calendar days, anchor `<gap>` | `<gap>` |
| San Skid Inspection | 4+ cubic yards | `<gap>` | San Skid Reinspection | +5 calendar days, anchor `<gap>` | `<gap>` |
| San Skid Inspection | Immediate – 1-4 cubic yards | `<gap>` | San Skid Reinspection | Next business day, anchor `<gap>` | `<gap>` |
| San Skid Inspection | Immediate 4+ cubic yards | `<gap>` | San Skid Reinspection | Next business day, anchor `<gap>` | `<gap>` |
| San Skid Inspection | Refer to DNS | `<gap>` | None | — | — |
| San Skid Inspection | City Property – Illegal Dumping | `<gap>` | None | — | — |
| San Skid Inspection | Duplicate | `<gap>` | None | — | — |
| San Skid Inspection | Void | `<gap>` | None | — | — |
| San Skid Reinspection | Collected | `<gap>` | None | — | — |
| San Skid Reinspection | Done by Owner | `<gap>` | None | — | — |
| San Skid Reinspection | Not Collected | `<gap>` | None | — | — |

## Table B — Workflow status routing

| Task | Status | Next task | Record disposition | Child record created |
|---|---|---|---|---|
| Inspection | No Violation | Terminal | Closed | None |
| Inspection | 1-4 cubic yards | Reinspection | Open | None |
| Inspection | 4+ cubic yards | Reinspection | Open | None |
| Inspection | Immediate – 1-4 cubic yards | Reinspection | Open | None |
| Inspection | Immediate 4+ cubic yards | Reinspection | Open | None |
| Inspection | Refer to DNS | `<gap>` | `<gap>` | Scattered Litter/Debris Request |
| Inspection | City Property – Illegal Dumping | `<gap>` | `<gap>` | City Property Cleanup Request |
| Inspection | Duplicate | Terminal | Closed | None |
| Inspection | Void | Terminal | Closed | None |
| Reinspection | Collected | Payment | Open | None |
| Reinspection | Done by Owner | Terminal | Closed | None |
| Reinspection | Not Collected | Terminal | Closed | None |
| Payment | Paid | Terminal | Closed | None |
| Payment | Past Due | Payment | Open | None |
| Payment | Appealed | `<gap>` | `<gap>` | None |
| Payment | Assessed | `<gap>` | `<gap>` | None |

## Table C — Status side effects

| Task | Status | Fee action | ASI update | Notification | Trigger type |
|---|---|---|---|---|---|
| Inspection | Duplicate | None | None | None | Event, if within 7 days; otherwise manual |
| Reinspection | Collected | Add + invoice | Billing = Billed | None | Event |
| Reinspection | Not Collected | None | None | Supervisor `<gap role>`, channel `<gap>` | Event |
| Payment | Past Due | Add late fee | None | None | Batch |

Note the Reinspection/Collected row: the effect updates a workflow task, so the script
will fire `WorkflowTaskUpdateAfter` on the Payment task as a cascade. Guard for it.

## Table D — Fee definitions

| Fee code | Fee schedule | Triggering status | Tier basis | Source record/inspection | Invoice on add | Late rule |
|---|---|---|---|---|---|---|
| `<gap>` | `<gap>` | Reinspection / Collected | Cubic yards | **San Skid Inspection** (not the reinspection) | Yes | — |
| `<gap>` | `<gap>` | Payment / Past Due | Flat `<gap>` | — | `<gap>` | 37 days, anchor `<gap>` |

## Table E — Automation

| Trigger | Event or batch | Event name | Condition | Match key | Effect |
|---|---|---|---|---|---|
| Record created | Event | ApplicationSubmitAfter | Prior record within 7 cal days | `<gap>` | Set Duplicate, close; else schedule inspection |
| Inspection resulted | Event | InspectionResultSubmitAfter | Result value | — | updateTask, scheduleInspection, create child |
| Reinspection Collected | Event | WorkflowTaskUpdateAfter | Status = Collected | — | Read prior inspection result, addFee, invoiceFee, set ASI, activate Payment (cascades) |
| Payment received | Event | PaymentReceiveAfter | Balance zero `<gap>` | — | updateTask Payment = Paid, close |
| Invoice ages 37 days | Batch | `<gap>` | Unpaid at 37 days | — | addFee late fee, set Past Due |

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
5. **Appealed and Assessed have no outbound transition.** As written, a record entering
   either can never close.
6. **Refer to DNS and City Property leave the parent undefined.** Both create a child
   record; neither says whether the parent closes, stays open, or waits on the child.
7. **37 days from when, and who sets Past Due?** Invoice date or status-change date, and
   batch job or clerk.
8. **"Notify Supervisor" names no recipient and no channel.** Needs a user group or
   module role, and email versus in-platform.
9. **No path exists for a reinspection that is never resulted.**
