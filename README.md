# ai-skills

A reusable knowledge base and instruction library for AI assistants (ChatGPT, GitHub Copilot, Cursor, Claude, Gemini, and others).

## Purpose

Store AI "skills" as Markdown files — curated prompts, standards, templates, and examples — organized by domain. The goal is to conserve tokens by having the hard research pre-gathered so AI agents can produce higher-quality output faster.

## Philosophy

- **Composition over copying** — shared rules live in `shared/`; skill folders reference them.
- **Concise over exhaustive** — every file earns its tokens.
- **Tool-agnostic** — content works with any AI assistant.
- **Human-readable** — also useful as a personal reference without AI.

## Repository Layout

```
ai-skills/
├── shared/          # Cross-cutting standards and checklists
├── excel/           # Microsoft Excel / VBA / Power Query
├── sql/             # SQL (ANSI + dialects)
├── java/
├── python/
├── javascript/
├── powershell/
├── web/             # HTML, CSS, REST APIs
├── linux/
├── windows/
├── git/
├── documentation/
├── writing/
├── research/
├── data-analysis/
├── investing/
├── accela/          # Accela Civic Platform
├── aurora/          # Aurora platform
├── personal/        # Personal workflows and preferences
└── tools/           # Dev tools, IDEs, CLIs
```

Each skill folder contains:

| Path | Purpose |
|---|---|
| `SKILL.md` | Overview, workflow, quality standards |
| `archetypes/` | Reusable prompt archetypes |
| `templates/` | Fill-in-the-blank templates |
| `examples/` | Concrete worked examples |
| `scripts/` | Helper scripts |
| `references/` | Cheat sheets and links |

## How AI Agents Should Use This Repository

1. Read `shared/` files first to understand baseline standards.
2. Navigate to the relevant skill folder and read `SKILL.md`.
3. Pull in templates or archetypes as needed.
4. Follow the Workflow and Quality Standards sections before producing output.

## Naming Conventions

- Folder names: `kebab-case`, plural avoided.
- File names: `kebab-case.md`.
- SKILL.md is always uppercase — it is the entry point for each domain.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
