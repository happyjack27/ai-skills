# Contributing

## Adding a New Skill

1. Choose the appropriate skillset folder, or create a new skillset and add it to `SKILLSETS.md`.
2. Add the skill folder with a short `kebab-case` name under the skillset.
3. Add subdirectories: `archetypes/`, `templates/`, `examples/`, `scripts/`, `references/`.
4. Copy `shared/SKILL-template.md` to `<skillset>/<skill>/SKILL.md` and fill in every section.
5. Add YAML frontmatter to the top of `SKILL.md` — `name` must exactly match the skill folder name,
   or the skill silently fails to load. See [AGENTS.md](AGENTS.md#authoring-rules).
6. Add `Routing Boundaries` so agents can distinguish this skill from neighboring skills.
7. Add the skill to the skillset's `SKILLS.md` index.
8. Regenerate `SKILL-CATALOG.json` and run `python scripts/validate-skills.py`.
9. Place shared rules in `shared/` rather than duplicating them.

## Editing Existing Files

- Keep files concise — every sentence should earn its place.
- Prefer bullet points over prose for AI readability.
- Use fenced code blocks with language tags for all code samples.

## Commit Messages

Use the format: `<domain>: <short description>`  
Example: `excel: add VLOOKUP archetype`

## File Naming

- `kebab-case.md` for all Markdown files.
- `SKILL.md` is always uppercase (entry point convention).

## Catalog and Validation

The generated [`SKILL-CATALOG.json`](SKILL-CATALOG.json) contains routing metadata only; it does
not duplicate skill bodies or references. Regenerate it with:

```bash
python scripts/generate-catalog.py
```

Validate frontmatter, local links, skillset indexes, and catalog consistency with:

```bash
python scripts/validate-skills.py
```
