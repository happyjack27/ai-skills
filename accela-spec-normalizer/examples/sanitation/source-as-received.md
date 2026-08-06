# Source as received

The original is `spec input.docx`. This file is what a text extractor (`pandoc`)
returns from it — reproduced here so the delta below is visible.

**That text is not the whole spec.** The docx is 1.3 MB; the text extraction is a few
hundred words. The rest of the actual workflow — every status, every routing decision,
every "do not close the record" — lives in an embedded screenshot, not in text runs.
See [source-workflow-diagram.png](./source-workflow-diagram.png). Stage 1 of the skill
now calls this out explicitly: check `word/media/` before treating a text extraction as
complete.

## Text extraction

Inspection Types

San Skid Inspection

- No Violation
- 1-4 cubic yards
- 4+ cubic yards
- Immediate – 1-4 cubic yards
- Immediate 4+ cubic yards
- Refer to DNS
- City Property – Illegal Dumping
- Duplicate
- Void

San Skid Reinspection

- Collected
- Done by Owner
- Not Collected – Make Comment and Notify Supervisor

Skid Violation Workflow

Inspection – San Skid Inspection assigned to next business day to Sanitation Inspector

- No Violation – Close Record
- 1-4 cubic yards – Assign San Skid Reinspection in 5 calendar days
- 4+ cubic yards – Assign San Skid Reinspection in 5 calendar days

*(The remaining Immediate/Refer to DNS/City Property/Duplicate/Void/Reinspection/
Billing/Payment routing is not in the extracted text at all — it exists only in the
diagram image.)*

## What the diagram adds

`source-workflow-diagram.png` is an "Accela Process Workflow – Skid Violations" chart
with four swimlanes: Inspection, Reinspection, Billing, Payment. It is where the
following come from, none of which appear in the text extraction:

- The Immediate tiers' offset ("next business day") and every non-Immediate result's
  routing (Refer to DNS, City Property, Duplicate, Void).
- Duplicate's own consequence: "Close record – Automated if placed within 7 calendar
  days."
- Reinspection's header note: "assigned based on inspection outcome."
- The full Reinspection → Billing → Payment handoff, including "Billing Status: Billed"
  as its own box between Reinspection and Payment.
- Payment's four outcomes, in full: `Paid` → Close Record; `Past Due` → Add Late Fee if
  not paid within 37 days; `Appealed` → **Under Appeal (Do not close record)**;
  `Assessed` → **Assessment Issued (Do not close record)**.

The last point matters: the diagram states explicitly that Appealed/Assessed do not
close the record, but it does not name a next task for either — "Under Appeal" and
"Assessment Issued" read as status labels, not task names. See `normalized.md`'s open
questions for how that ambiguity is carried forward.
