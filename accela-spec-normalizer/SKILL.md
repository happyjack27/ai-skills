---
name: accela-spec-normalizer
description: Turns loose Accela Civic Platform record type specs into machine-readable tables, a gap list, and mermaid diagrams. Use this whenever the user brings an Accela record type, workflow, inspection type, EMSE script spec, fee schedule, or a Word/PDF document describing how a permit, complaint, enforcement, or service request record should behave — including when they just say "here's a spec", "graph this workflow", "review this record type", or "what's missing from this". Also use when the user asks for a spec template for a new record type, or wants existing bullet-style requirements converted into tables, matrices, or diagrams.
---

# Accela spec normalizer

## What this is for

Accela record type specs arrive as bullet lists written by business analysts. They read
fine to a human and are close to unimplementable, because a single bullet packs several
independent facts behind em-dashes:

> Collected – Add and invoice fee based on cubic yards in inspection result – Update Billing to Billed – move to payment

That is four facts across three different configuration surfaces, plus a silent
cross-inspection data read. A configurer working from that bullet has to guess. This
skill removes the guessing by decomposing each bullet into atomic rows, naming what is
missing rather than filling it in, and generating diagrams from the rows instead of
from the prose.

The single most important rule in this skill: **never infer a missing value.** If the
document does not say whether an offset is calendar days or business days, that is a
gap, not a judgement call. An agent that fills blanks plausibly produces a spec that
looks finished and is not — strictly worse than the loose document it replaced, because
the loose document at least announced its own vagueness.

## Pipeline

Work through these five stages in order. Do not skip ahead to diagrams — diagrams
generated from prose invent transitions that were never in the source.

### Stage 1 — Ingest

Extract text from the source document:

```bash
extract-text /path/to/spec.docx
```

Works for `.docx`, `.odt`, `.pptx`, `.xlsx`. For `.pdf`, check `pdffonts` first; if no
fonts are listed the file is a scan and needs OCR.

Read the whole thing before writing anything. Specs frequently define a result value in
one section and its consequence three sections later.

### Stage 2 — Normalize (the core of this skill)

Decompose every bullet into atomic facts and place each fact in exactly one table cell.
Read `references/tables.md` for the full column definitions and the rules for each
column. Five tables:

| Table | Holds |
|---|---|
| A | Inspection types and their result values |
| B | Workflow status routing — one row per status, no exceptions |
| C | Status side effects — fees, ASI updates, notifications |
| D | Fee definitions and where each tier gets its number |
| E | Automation — event hooks and batch jobs |

**Decomposition worked example.** The Collected bullet above becomes four rows:

- Table B: `Reinspection | Collected | Payment | In Progress | —`
- Table C: `Reinspection | Collected | Add + invoice fee | Billing = Billed | — | Event`
- Table D: `<gap> | <gap> | Reinspection/Collected | Cubic yards | San Skid Inspection | Yes | <gap>`
- Table E: `Reinspection resulted Collected | Event | WorkflowTaskUpdateAfter | Status = Collected | <gap> | Add fee, invoice, set ASI, activate Payment`

Note what the decomposition surfaced: the fee tier is read from the *original*
inspection, not the reinspection that triggered it. That cross-record read is invisible
in the bullet and is the kind of thing that ships as a defect. Table D has a dedicated
"source record" column specifically to force it into the open.

Rules that matter while normalizing:

- Every status value in the source gets a Table B row, even ones with no stated
  consequence. A status with a blank "next task" is the finding.
- Split conjunctions. "Make comment and notify supervisor" is two effects.
- Keep the source's own vocabulary for status and result values. Do not tidy
  `4+ cubic yards` into `Four Plus Cubic Yards` — a configurer will search for the
  original string.
- Mark every unknown with `<gap>` and a matching entry in the gap list. Never
  `N/A`, never blank, never a plausible guess.

### Stage 3 — Gap detection

Run `references/gap-checklist.md` against the normalized tables. Each checklist item
exists because a real spec failed it. Output a numbered list of unanswered questions,
each written so the analyst can answer it without re-reading the whole document:

> **3. Duplicate detection has no match key.** "Automated if placed within 7 calendar
> days" does not say what makes two records duplicates — address, location ID, or skid
> ID — nor whether the 7 days counts from the earlier record's open date or its
> inspection date.

This list is usually the highest-value output. Lead with it when reporting back.

### Stage 4 — Generate diagrams

Generate mermaid source **from the tables**, never from the original prose. If a
transition is not in Table B, it does not go in the diagram.

Produce three diagrams. Read `references/diagram-style.md` for the exact
`themeVariables` block, palette hex values, and `classDef` lines — copy them literally
rather than improvising, so that every record type in the estate renders identically
and diffs stay quiet.

| Diagram | Source | Mermaid type | Always? |
|---|---|---|---|
| Workflow state graph | Table B | `stateDiagram-v2` | Yes |
| Inspection lifecycle | Tables A + B | `flowchart TD` | Only if the record type has inspections |
| Event chain | Table E | `flowchart LR` | Only if there are scripts or batch jobs |

The record type header card is **not** a diagram — it is a table. Do not render it as
mermaid or SVG; that makes reference data uneditable for no gain.

Two layout rules, both learned the hard way:

- **Graph tasks, table statuses.** A state graph with a dozen status edges between five
  nodes renders as overlapping labels in every mermaid layout engine. Consolidate
  edges that share a source and target — four cubic-yard results become two edges
  distinguished by their scheduling offset — and let Table B carry the full list.
- **Keep batch jobs visually distinct from events** in the event chain. A reader has to
  be able to see at a glance that the 37-day late fee is not triggered by anything a
  user does.

Working examples live in `examples/sanitation/diagrams/`. Read
`examples/sanitation/diagrams/RATIONALE.md` alongside them — it explains why each is
shaped the way it is, which matters more than the syntax.

Those examples are stored as `.md` files with a fenced ```mermaid``` block, not bare
`.mmd`. This repo has no `.mmd` previewer — the installed Mermaid extension only offers
a preview command, not a default editor association — so the fenced-Markdown form is
what actually renders on open. This is a convention for this skill's own reference
files only; it does not change Stage 5, where the real deliverable to Accela
configurers is still bare `.mmd` + a generated `.svg`.

### Stage 5 — Render and assemble

Mermaid is the source of truth; SVG is a generated export. Never hand-author both — two
maintained copies drift within weeks.

```bash
bash scripts/render.sh diagrams/
```

The script tries `mmdc` (mermaid-cli) first and falls back to the Kroki HTTP API. If
neither is available, say so plainly and deliver the `.mmd` files alone rather than
silently skipping the export.

Assemble the deliverable using `assets/templates/spec-template.md`:

```
<record-type>-spec/
├── spec.md              filled template: header card + Tables A-E
├── gaps.md              numbered unanswered questions
└── diagrams/
    ├── workflow.mmd     source of truth
    ├── workflow.svg     generated
    └── ...
```

## Reporting back

Lead with the gap list, not the diagrams. The diagrams show what the spec says; the
gaps show what it costs. State the count plainly — "the spec defines 16 statuses and
leaves 7 questions unanswered" — then offer the diagrams.

If the source document is already complete enough that the gap list is short, say so.
Do not manufacture findings to look thorough.

## Reference files

- `references/tables.md` — column definitions and per-column rules for Tables A–E
- `references/gap-checklist.md` — the checklist for Stage 3, with the failure each item catches
- `references/diagram-style.md` — mermaid theme block, palette, `classDef` lines, layout rules
- `assets/templates/spec-template.md` — blank output template
- `assets/templates/tables-blank.md` — blank Tables A–E for analysts filling specs by hand
- `examples/sanitation/` — a complete worked example: loose source in, tables, gaps, and
  diagrams out (`diagrams/` holds the working mermaid for all three diagram types, plus
  rationale)
