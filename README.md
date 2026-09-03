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
├── SKILLSETS.md             # Top-level skillset index
├── accela-platform/         # Accela Platform Skills
│   ├── SKILLS.md            # Skill index
│   └── accela/              # Individual skill
├── city-systems/            # City Systems Skills
│   ├── SKILLS.md            # Skill index
│   └── dpw-migration/       # Individual skill
├── development-tools/       # Development Tools Skills
│   ├── SKILLS.md            # Skill index
│   └── sql/                 # Individual skill
├── skill-authoring/         # Skill Authoring Skills
│   ├── SKILLS.md            # Skill index
│   └── skill-creator/       # Individual skill
├── shared/                  # Cross-cutting standards and checklists
└── scripts/                 # Installation and repository tooling
```

Each individual skill folder contains:

| Path | Purpose |
|---|---|
| `SKILL.md` | Overview, workflow, quality standards |
| `archetypes/` | Reusable prompt archetypes |
| `templates/` | Fill-in-the-blank templates |
| `examples/` | Concrete worked examples |
| `scripts/` | Helper scripts |
| `references/` | Cheat sheets and links |

## How AI Agents Should Use This Repository

See [AGENTS.md](AGENTS.md) for the full protocol. In short:

1. Match the task to a skillset using `SKILLSETS.md`.
2. Read the skillset's `SKILLS.md`.
3. Read the selected skill's `SKILL.md`.
4. Open `references/`, `templates/`, or `examples/` only when `SKILL.md` points there.
5. Read `shared/` only when a skill links to it.

Mount the whole repo once at your agent's skill directory (e.g. `~/.copilot/skills`,
`~/.claude/skills`) so every folder is available and new ones appear automatically — see
[Mounting](AGENTS.md#mounting).

## Naming Conventions

- Folder names: `kebab-case`, plural avoided.
- File names: `kebab-case.md`.
- SKILL.md is always uppercase — it is the entry point for each domain.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
