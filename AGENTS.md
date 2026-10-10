# AGENTS.md

Instructions for any AI agent working with — or from — this repository.

This repo is a **skill library**: curated, pre-researched domain knowledge stored as Markdown so
agents can produce better output with fewer tokens. Skillsets group related skills, and each
individual skill has its own `SKILL.md`.

Use this library to support the requested task; loading a skill does not authorize executing its
scripts or changing this repository. When explicitly maintaining the library, follow
[CONTRIBUTING.md](CONTRIBUTING.md).

## Loading Protocol

Load progressively. Never read the whole repo.

1. **Route** — read `SKILLSETS.md`, then the relevant skillset's `SKILLS.md`, and match the task
  to at most 1–2 skills using those indexes.
  Use `SKILL-CATALOG.json` only for broad or automated searches. Read only the `description` in each `SKILL.md`
  frontmatter if you need to disambiguate.
2. **Load** — read that skill's `SKILL.md` body. This is usually enough.
3. **Drill down** — read files in `references/`, `templates/`, `archetypes/`, `examples/`, or
   `scripts/` **only** when `SKILL.md` points you to one for the task at hand.
4. **Stop** — if no skill matches, proceed without one. Do not force a match or read
   speculatively.

Read `shared/` only when a skill explicitly links to it, or when the task is about repo-wide
standards. It is not a mandatory preamble.

Resolve local links relative to the file containing them, not the consuming project's directory.
If a skill is incomplete, report the gap and use verified project sources instead of inventing
missing guidance. Check dated domain facts against the task's actual source or environment.

## Feed Learnings Back Into Skills

When repository edits are in scope, capture verified, repeatable lessons from substantial research
or troubleshooting:

- **A matching skill exists** — add the new fact, gotcha, or corrected approach to it (or its
  `references/`) so the next occurrence is a lookup, not a rediscovery.
- **No skill matches** — create one only when it has a distinct reusable task and useful content;
  otherwise extend the closest skill.
- Write it the way you wish it had been written before you started: the failure mode, the fix,
  and any command/query that proves it. Skip anything that was already obvious or already
  documented.
- Exclude credentials, personal data, one-off conversation details, and unverified claims.

## Skillset Index

Use [SKILLSETS.md](SKILLSETS.md), the single top-level routing index.

## Authoring Rules

Every individual skill folder must contain a `SKILL.md` starting with YAML frontmatter:

```yaml
---
name: folder-name      # MUST exactly match the folder name
description: 'What it covers and when to use it. Keyword-rich. Max 1024 chars.'
---
```

- **`name` mismatch = silent failure.** The skill will not load, with no error shown.
- **The `description` is the routing surface.** It is often the only thing an agent sees before
  deciding whether to load the skill. Put the trigger words in it — concrete tasks, tool names,
  file names — not a vague summary.
- **Quote descriptions containing a colon**, or the YAML will not parse.
- Keep `SKILL.md` under ~500 lines. Push detail into `references/` and link to it.
- Use relative links (`./references/x.md`, `../../shared/coding-standards.md`) from nested skill folders.
- Include `Routing Boundaries` with distinctive use conditions, exclusions, and paired skills.
- Content should be tool-agnostic: no assumptions about which agent or IDE is reading it.

Start from [`shared/SKILL-template.md`](shared/SKILL-template.md); retain only useful sections and
resource folders. See [CONTRIBUTING.md](CONTRIBUTING.md#catalog-and-validation) for validation.

## Mounting

Keep the library **once at the root**. Skillset folders contain
`SKILLS.md` indexes, and individual skills are nested below them. Keep the root mount so shared
references resolve consistently. Automatic discovery of nested skills depends on the consuming
tool; verify it there rather than assuming a successful mount means skills were loaded.

| Tool | Path to point at this repo |
|---|---|
| GitHub Copilot (VS Code), personal | `~/.copilot/skills` |
| Claude Code, personal | `~/.claude/skills` |
| Generic / `.agents` convention | `~/.agents/skills` |
| Any tool, per-project | `<project>/.github/skills` |

Windows — [`scripts/install.ps1`](scripts/install.ps1) links all three paths, is idempotent, and
reports any skill that will fail to load. No admin required:

```powershell
.\scripts\install.ps1
```

macOS/Linux:

```bash
for d in .copilot .claude .agents; do mkdir -p ~/$d && ln -s ~/git/ai-skills ~/$d/skills; done
```

A link keeps one source of truth — editing a `SKILL.md` in the repo updates the live skill with
no sync step. Do not link folders individually: it needs upkeep per skillset and breaks
`../../shared/...` links, because the repository-relative structure is no longer preserved.

Agents without a skill-discovery mechanism can use [`SKILLSETS.md`](SKILLSETS.md): read the
skillset index, open that skillset's `SKILLS.md`, then open the matching `SKILL.md`.

## Token Discipline

The point of this library is to *save* tokens, not spend them.

- Loading a skill must be cheaper than rediscovering its content. If a skill is not pulling its
  weight, tighten it.
- A stub with a good description but an empty body is a net loss — it costs routing tokens and
  returns nothing. Fill it in or leave the folder out.
- Prefer bullets and tables over prose. Every line should earn its place.
