# Worked example — Skid Violation

`spec input.docx` is the original as received. `source-as-received.md` is what a text
extractor returns from it, plus `source-workflow-diagram.png` — the embedded screenshot
that actually carries most of the workflow logic (see Stage 1: check `word/media/`
before trusting a text extraction). `normalized.md` is what this skill produces from
both. Compare them to see which facts had to be split out of which bullets and images,
and which questions the tables forced into the open.

The most instructive single line is the Collected bullet, which decomposes into four
rows across three tables and exposes a cross-inspection data read that is completely
invisible in the original.

`diagrams/` holds the three mermaid diagrams generated from these tables (Stage 4),
plus `RATIONALE.md` explaining the shaping decisions behind each one, and a rendered
`.png` per diagram used only for embedding into `normalized.docx`.

`normalized.docx` is the Stage 6 consolidated export — header, open questions, Tables
A–E, and all three diagrams (rendered as real images, not mermaid source text) in one
file for reviewers who don't want raw markdown or mermaid. No local `mmdc` was
installed and the Kroki HTTP fallback was unreachable on this network, but `npx --yes
@mermaid-js/mermaid-cli` worked (it only needs npm registry access) and rendered all
three diagrams. The first pass of this export shipped with the diagrams as plain
mermaid text because that fallback hadn't been tried yet — a reminder to actually check
`word/media/` inside the generated `.docx` before calling Stage 6 done, not just check
that the file exists.
