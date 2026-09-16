<!--
Blank starting point for the Step 9 design-confirmation .docx described in
../references/spec-analysis-workflow.md. Copy into
accela-test/local-notes/<project name>/<project>-design-confirmation.md, fill in, then render:

  bash <path-to-this-skill>/scripts/render-docx.sh <project>-design-confirmation.md

Diagrams should use one edge per result value (not consolidated by shared source/target) - this
skill's own layout convention, kept even though render-docx.sh was vendored from
accela-spec-normalizer. Audience is the requestor, not a developer/admin - no SQL, table/column
names, TFS-internal IDs, or implementation file lists.
-->

# [Record Type Name] — Design Confirmation

**Status:** draft / in review / confirmed
**Source spec:** [filename, date received]
**Related work item:** [TFS link]

This document describes our understanding of the target design for [record type] before we start
building it. Please read it and confirm it matches what you asked for — see "How to respond" at
the end.

## 1. What's changing

<!-- 2-3 plain-language sentences per component, summarized from each Step 8 explainer's own
"Current state vs. target state" section. Don't reproduce the whole explainer here. -->

- **Workflow:** [...]
- **Inspections:** [...]
- **Scripts/automation:** [...]

## 2. The end-to-end record lifecycle (target state)

<!-- Add diagrams/workflow-lifecycle.png when the lifecycle diagram is produced. -->

<!-- Plain-language step-by-step walkthrough, same content/order as the workflow explainer. -->

1. [...]
2. [...]

## 3. Decisions we need you to confirm

<!-- Every item from Step 6's "needs the requestor's clarification" list, plus each explainer's
"open items to confirm" checklist, de-duplicated and rephrased as plain business questions. -->

1. [...]
2. [...]

## 4. Test scenarios to validate

<!-- Reworded from the Step 7 test-cases doc: "if this happens, this should happen," grouped by
phase, in the same order as the source doc. Keep status/result names verbatim. Drop TFS IDs,
script filenames, and internal fee/table codes. -->

### [Phase name, e.g. Record creation]

| # | If this happens | This should happen |
|---|---|---|
| 1 | | |

### [Next phase]

| # | If this happens | This should happen |
|---|---|---|

## How to respond

Please reply confirming (or correcting) each numbered item in section 3, and flag any row in
section 4 whose expected result doesn't match what you intended. We'll treat silence on a specific
item as "no concern," but if anything above looks wrong, say so before we start building.
