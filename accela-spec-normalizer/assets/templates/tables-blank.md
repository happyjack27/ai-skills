# Record type spec — blank tables

Fill every cell. Where the answer is not known yet, write `<gap>` rather than leaving
the cell empty — a blank cell is indistinguishable from an oversight, and `<gap>` is
searchable.

## Header

| Field | Value |
|---|---|
| Record type (group / type / subtype / category) | |
| Workflow name | |
| Workflow tasks | |
| Inspection group | |
| Inspection types | |
| Fee schedule | |
| ASI groups and fields | |
| Child record types | |
| Scripts and batch jobs | |

## Table A — Inspection types and results

| Inspection type | Result value | Result group | Schedules what | Offset + anchor | Assign to |
|---|---|---|---|---|---|
| | | | | | |

## Table B — Workflow status routing

One row per status. Every status, including ones with no stated consequence.

| Task | Status | Next task | Record disposition | Child record created |
|---|---|---|---|---|
| | | | | |

## Table C — Status side effects

| Task | Status | Fee action | ASI update | Notification (role + channel) | Trigger type |
|---|---|---|---|---|---|
| | | | | | |

## Table D — Fee definitions

| Fee code | Fee schedule | Triggering status | Tier basis | Source record/inspection | Invoice on add | Late rule |
|---|---|---|---|---|---|---|
| | | | | | | |

## Table E — Automation

| Trigger | Event or batch | Event name | Condition | Match key | Effect |
|---|---|---|---|---|---|
| | | | | | |
