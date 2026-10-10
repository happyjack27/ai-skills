# ai-skills

A tool-agnostic library of curated domain knowledge, workflows, and examples for AI agents.
Load only the guidance needed for a task instead of repeating research or reading the whole library.

## Repository Layout

```
ai-skills/
├── AGENTS.md                # Agent loading and maintenance rules
├── SKILLSETS.md             # Start here: domain routing
├── SKILL-CATALOG.json       # Generated metadata for automated searches
├── <skillset>/
│   ├── SKILLS.md            # Task routing and exclusions
│   └── <skill>/
│       ├── SKILL.md         # Frontmatter, workflow, and resource links
│       └── references/      # Optional detail loaded on demand
├── shared/                  # Shared guidance, template, and indexed skills
└── scripts/                 # Installation, catalog generation, validation
```

See [SKILLSETS.md](SKILLSETS.md) for the actual domains. Resource folders are optional:
`references/` for detail, `templates/` for starting points, `examples/` for worked results,
`archetypes/` for prompt patterns, `scripts/` for automation, and `assets/` for output files.

## How AI Agents Should Use This Repository

See [AGENTS.md](AGENTS.md) for the full protocol. In short:

1. Read `SKILLSETS.md` and choose the most relevant skillset.
2. Read that skillset's `SKILLS.md` and select at most 1–2 candidates.
3. Read the selected skill's `SKILL.md`.
4. Open `references/`, `templates/`, or `examples/` only when `SKILL.md` points there.
5. Read `shared/` only when a skill links to it or the task concerns repository-wide standards.
6. If nothing matches, proceed without a skill.

`SKILL-CATALOG.json` is an optional machine-readable index for broad or automated searches. It is
not part of the normal routing path; reading the small indexes top down is usually more token
efficient.

Keep the repository-relative structure intact when mounting the library — see
[Mounting](AGENTS.md#mounting).
Automatic nested discovery depends on the consuming tool; the index-based loading path works
without it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
