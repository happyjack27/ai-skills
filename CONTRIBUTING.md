# Contributing

## Adding a New Skill Folder

1. Create a folder with a short `kebab-case` name.
2. Add subdirectories: `archetypes/`, `templates/`, `examples/`, `scripts/`, `references/`.
3. Copy `shared/SKILL-template.md` to `<folder>/SKILL.md` and fill in every section.
4. Add YAML frontmatter to the top of `SKILL.md` — `name` must exactly match the folder name,
   or the skill silently fails to load. See [AGENTS.md](AGENTS.md#authoring-rules).
5. Place shared rules in `shared/` rather than duplicating them.

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
