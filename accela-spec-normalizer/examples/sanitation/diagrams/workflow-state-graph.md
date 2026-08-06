# Workflow state graph — Skid Violation

Generated from Table B. See [RATIONALE.md](./RATIONALE.md) for why the four cubic-yard
results collapse into two edges and why `Appealed`/`Assessed` are drawn as dead ends.

```mermaid
stateDiagram-v2
  state "Child record" as Child
  [*] --> Inspection
  Inspection --> Closed: No violation, duplicate, void
  Inspection --> Reinspection: 1-4 or 4+ cy, 5 cal days
  Inspection --> Reinspection: Immediate, next bus day
  Inspection --> Child: Refer to DNS, city property
  Reinspection --> Payment: Collected
  Reinspection --> Closed: Done by owner
  Reinspection --> Closed: Not collected
  Payment --> Closed: Paid
  Payment --> Payment: Past due, add late fee
  Payment --> Appeal: Appealed
  Payment --> Assessment: Assessed
  Closed --> [*]
```
