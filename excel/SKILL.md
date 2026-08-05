---
name: excel
description: 'Use for Microsoft Excel tasks: writing worksheet formulas, VBA macros, Power Query (M) transformations, pivot tables, and automating repetitive Excel workflows on Windows/Mac/Excel Online.'
---

# Excel Skill

## Purpose

Help an AI assist with Microsoft Excel tasks: formulas, data modeling, VBA macros, Power Query, and pivot tables.

## Scope

- Excel desktop (Windows/Mac) and Excel Online.
- VBA, Power Query (M language), and standard worksheet formulas.
- Out of scope: Power BI, Google Sheets (separate skill folders).

## When to Use

- User needs a formula, macro, or data transformation in Excel.
- User needs to automate a repetitive Excel workflow.
- User needs to analyze or reshape tabular data.

## Inputs Expected

| Input | Description |
|---|---|
| Table layout | Column names, data types, sample rows |
| Goal | What the output should look like |
| Constraints | Excel version, VBA allowed?, performance requirements |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Formula | Excel formula string | Ready to paste into a cell |
| VBA macro | VBA code block | Paste into the VBA editor |
| Power Query | M code block | Paste into Advanced Editor |

## Workflow

1. Confirm the table structure and goal.
2. Choose the right tool: formula → VBA → Power Query (in order of preference for maintainability).
3. Write and explain the solution.
4. Note any version-specific limitations.

## Quality Standards

- Formulas use absolute references (`$A$1`) where the reference should not shift.
- VBA includes error handling (`On Error GoTo`).
- Power Query steps are named descriptively.
- Avoid volatile functions (`NOW()`, `RAND()`, `OFFSET()`) unless required.

## Common Mistakes

- Using `VLOOKUP` when `XLOOKUP` or `INDEX/MATCH` is more robust.
- Forgetting to lock references before copying a formula.
- VBA that breaks when sheet names or column positions change — use named ranges.

## Validation Checklist

- [ ] Formula produces correct result on sample data.
- [ ] Absolute/relative references are correct.
- [ ] VBA compiles without errors.
- [ ] Solution works on stated Excel version.

## Examples

See `examples/`.

## Related Skills

- [`../shared/coding-standards.md`](../shared/coding-standards.md)
- [`../data-analysis/SKILL.md`](../data-analysis/SKILL.md)
