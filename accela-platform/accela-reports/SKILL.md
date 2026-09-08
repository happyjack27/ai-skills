---
name: accela-reports
description: 'This skill should be used when building or updating Accela Crystal Reports, report SQL, report templates, or field maps for City of Milwaukee records; it covers mapping report text to live ACCELAPROD data, validating sample records, and separating summary-page fields, ASI/custom fields, and finance values from copied SQL.'
---

# Accela Reports

## Overview

Use this skill to turn an Accela report request into a grounded field map and a working Crystal Reports query. Start from the requested letter or report layout, then verify the source record and live values in `sql-dev ACCELAPROD` before changing SQL.

## When To Use

Use this skill when a request involves any of the following:

- Building a new Crystal Report for an Accela record type
- Copying an existing report and replacing its SQL
- Mapping template text to Accela summary-page fields, ASI fields, or finance values
- Validating a report against a sample record such as `VAC-21-00498`
- Checking whether a requested value comes from the summary page, a custom field, or a derived calculation

## Workflow

1. Identify the report template and the exact record type or sample record that the report should match.
2. Query `sql-dev ACCELAPROD` for the sample record first, then confirm the live source for each line item.
3. Prefer summary-page and finance tables for core record values, and use ASI or custom-field tables only for values that are not already on the summary page.
4. Treat copied SQL as a starting point only. If it joins unrelated tables or record types, replace it instead of trying to patch it.
5. Keep clause keywords like `FROM`, `LEFT JOIN`, `ON 1 = 1`, and `WHERE 1 = 1` flush left; indent only the table names and predicates below them.
6. Put each table name on its own line after `FROM` or `LEFT JOIN`, then indent the predicates below it.
7. Use tabs for SQL indentation in report drafts so aligned predicates stay easy to move with copy and paste.
8. Put report-specific derived values in the SQL with a clear output alias so Crystal can reference them as command fields; reserve Crystal formulas for layout-only behavior.
9. Refer to [`examples/report-sql-format.md`](examples/report-sql-format.md) when drafting or revising report SQL.
10. Run the finished SQL in SSMS against every sample ALT_ID supplied by the report template or request, replacing the Crystal parameter with the exact literal for the test. Confirm that the query returns the expected row and compare every highlighted/template value field-by-field against the document before creating Crystal tags.
11. Call out any value that is still guessed, hard-coded, or not yet confirmed in the database. Do not finalize the Crystal field map until ambiguous identifiers, such as a permit number versus an `ACA temp Record #` custom field, are resolved against the sample output.

## Grounding Rules

Keep the report grounded in actual Accela data.

- Use the sample record to verify the exact internal IDs, not just the public record number.
- Use the summary page sources for owner, address, tax key, balance, and similar top-level fields when they exist.
- Use ASI or custom-field tables for report-specific values such as waiver amounts, approval flags, or expiration dates.
- Prefer `FN_GET_APP_SPEC_INFO` for app-spec / custom-field lookups when the report schema already exposes it; only fall back to raw `BAPPSPECTABLE` / `BAPPSPECTABLE_VALUE` joins when the helper cannot return the needed value.
- Return report-specific decisions, labels, and derived values from SQL with explicit aliases so Crystal can reference them as command fields; do not move that logic into Crystal formulas.
- Use Crystal formulas only for layout-only behavior, such as formatting or a display-only date when the value does not belong in the query result.
- Avoid carrying forward joins from a copied report unless they still match the requested record type and field source.

## Lessons Learned

Keep these failure modes explicit so they are not repeated.

- Verify the target schema before trusting copied SQL. A report copied from another record type can point at the wrong tables entirely.
- Use the sample record's internal IDs when querying ASI or custom-field tables. The public record number alone is not enough.
- If the copied report already uses `FN_GET_APP_SPEC_INFO`, keep that helper in the final SQL instead of replacing it with direct custom-field joins.
- Prefer `ON 1 = 1` and `WHERE 1 = 1` as a formatting convention when a query has multiple predicates that are easier to align and copy in a stable order.
- Put the table name on its own line after `FROM` and `LEFT JOIN` so clause headers are easy to scan and move.
- Use tabs for SQL indentation in the draft and final query; avoid space-only indentation on aligned predicate blocks.
- Confirm which fields are summary-page values, which are finance values, and which are ASI values before assembling the final SQL.
- Treat missing ASI rows as a data question, not a cue to invent a value.
- Recheck one known example record such as `VAC-21-00498` after each rewrite so the report stays anchored to the same case.
- Treat template confirmation as an executable check: run each report query for every record number shown in the Word/text source documents, compare owner mailing address, property address, date, identifier, and status-specific values to the document, and record any mismatch before handing the query to Crystal.
- Do not assume a displayed `Re:` identifier is the Accela permit number or an `ACA temp Record #`; select both when the source is ambiguous and resolve which one matches the template's sample value in SSMS.

## Common Report Sources

Read [`references/report-mapping.md`](references/report-mapping.md) before drafting SQL for a new report. It captures the report-source pattern confirmed in the fee-waiver example and keeps the lookup targets explicit.

## Output Expectations

When responding to a report request, provide:

- The record type or sample record used for grounding
- A field-by-field source map
- The tables or views that should feed the Crystal report
- Any open data gaps or admin-config items that still need confirmation

