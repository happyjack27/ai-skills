# Event chain — Skid Violation

Generated from Table E. See [RATIONALE.md](./RATIONALE.md) for why hooks and effects are
drawn as two columns rather than a chain, and why the nightly batch gets its own class.

```mermaid
flowchart LR
  E1["ApplicationSubmitAfter<br/>record created"] --> R1["Schedule inspection<br/>after 7-day duplicate check"]
  E2["InspectionResultSubmitAfter<br/>both inspection types"] --> R2["Route the result<br/>updateTask, scheduleInspection"]
  E3["WorkflowTaskUpdateAfter<br/>Reinspection, Collected"] --> R3["Add and invoice fee<br/>tier from prior inspection"]
  E4["PaymentReceiveAfter<br/>payment received"] --> R4["Close the record<br/>updateTask on Payment"]
  E5["Nightly batch<br/>not event driven"] --> R5["Late fee at 37 days<br/>addFee on unpaid invoice"]

  classDef hook fill:#E6F1FB,stroke:#185FA5,color:#0C447C
  classDef effect fill:#E1F5EE,stroke:#0F6E56,color:#085041
  classDef terminal fill:#F1EFE8,stroke:#5F5E5A,color:#2C2C2A
  class E1,E2,E3,E4 hook
  class R1,R2,R3,R4,R5 effect
  class E5 terminal
```
