# AGENTS.md

Instructions for any AI agent working with — or from — this repository.

This repo is a **skill library**: curated, pre-researched domain knowledge stored as Markdown so
agents can produce better output with fewer tokens. Each top-level folder is one skill.

## Two Ways Agents Use This Repo

**As a library (the normal case).** The repo is mounted into an agent's skill directory, and the
agent loads a skill when a task calls for it. See [Mounting](#mounting).

**As a workspace.** You are editing the library itself. Follow
[Authoring Rules](#authoring-rules) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Loading Protocol

Load progressively. Never read the whole repo.

1. **Route** — match the task to at most 1–2 skills using the [index](#skill-index). Read only
   the `description` in each `SKILL.md` frontmatter if you need to disambiguate.
2. **Load** — read that skill's `SKILL.md` body. This is usually enough.
3. **Drill down** — read files in `references/`, `templates/`, `archetypes/`, `examples/`, or
   `scripts/` **only** when `SKILL.md` points you to one for the task at hand.
4. **Stop** — if no skill matches, proceed without one. Do not force a match or read
   speculatively.

Read `shared/` only when a skill explicitly links to it, or when the task is about repo-wide
standards. It is not a mandatory preamble.

## Feed Learnings Back Into Skills

If a task required heavy lifting — extended research, trial and error, a mistake that had to be
fixed, or a workaround for a gotcha that wasn't already documented — capture that as a skill
update before finishing:

- **A matching skill exists** — add the new fact, gotcha, or corrected approach to it (or its
  `references/`) so the next occurrence is a lookup, not a rediscovery.
- **No skill matches** — create one, or add a section to the closest existing skill, following
  [Authoring Rules](#authoring-rules).
- Write it the way you wish it had been written before you started: the failure mode, the fix,
  and any command/query that proves it. Skip anything that was already obvious or already
  documented.
- Do this for genuine repeatable lessons, not one-off trivia. If it's specific to one user's
  environment or a single conversation, it belongs in that agent's own memory system instead.

## Skill Index

| Skill | Use for |
|---|---|
| `accela` | Accela Civic Platform: EMSE scripts, Automation API, ASI fields, workflows |
| `dpw-migration` | City of Milwaukee DPW Oracle → SQL Server migration and query routing |
| `excel` | Formulas, VBA, Power Query (M), pivot tables |
| `java` | JDBC, RMI servers, servlets/JSP, classpath issues, legacy modernization |
| `kwatcontrol-ui-config` | KWATControl database (sql-itmd): configuring UI rendering for all MSSQL web apps (KWAT, DPW, HHMP). Add/hide table columns, configure dropdowns, manage reports, sidebar navigation, access grants, and enhancements |
| `mssql-dynamic-tables` | SQL Server file tables and CRUD generation: development.DynamicFile/DynamicSQUID procs, naming conventions, indexes, foreign keys, delete tracking |
| `skill-creator` | Creating or updating skills in this library (SKILL.md structure, frontmatter, folders) |
| `sql` | Queries, DDL, procs, views, indexes, tuning (T-SQL, PG, MySQL, SQLite, Oracle) |
| `tfs-boards` | tfs.milwaukee.gov "Internal Systems Projects" board: WIQL queries, work item CRUD, board columns |

`shared/` is not a skill — it holds cross-cutting standards that skills link to.

## Authoring Rules

Every skill folder must contain a `SKILL.md` starting with YAML frontmatter:

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
- Use relative links (`./references/x.md`, `../shared/coding-standards.md`).
- Content should be tool-agnostic: no assumptions about which agent or IDE is reading it.

Structure within a skill folder:

| Path | Purpose |
|---|---|
| `SKILL.md` | Entry point: purpose, scope, when to use, workflow |
| `references/` | Cheat sheets and deep detail, loaded on demand |
| `templates/` | Fill-in-the-blank starting points |
| `archetypes/` | Reusable prompt patterns |
| `examples/` | Concrete worked examples |
| `scripts/` | Helper scripts |

Start from [`shared/SKILL-template.md`](shared/SKILL-template.md).

## Mounting

The whole repo is the library, so mount it **once at the root**. Every folder then becomes an
available skill, and folders added later are picked up automatically.

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
no sync step. Do not link folders individually: it needs upkeep per skill and breaks
`../shared/...` links, because `..` is normalized away before the filesystem resolves the link.

Agents without a skill-discovery mechanism can use this file directly: read the
[index](#skill-index), then open the one `SKILL.md` that matches.

## Token Discipline

The point of this library is to *save* tokens, not spend them.

- Loading a skill must be cheaper than rediscovering its content. If a skill is not pulling its
  weight, tighten it.
- A stub with a good description but an empty body is a net loss — it costs routing tokens and
  returns nothing. Fill it in or leave the folder out.
- Prefer bullets and tables over prose. Every line should earn its place.
