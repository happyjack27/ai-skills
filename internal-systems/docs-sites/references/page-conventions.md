# Page conventions

Observed in the existing pages on both sites (verified 2026-11-03). Match the neighbours before inventing a style.

## Topic folder layout

```text
<topic>\
  index.md          required: first "# " heading is the page title and the topic title
  <page>.md         kebab-case names
  images\           pictures used by the pages (png, jpg, jpeg, gif, webp)
  files\            attachments (pdf, docx, xlsx, pptx, vsdx, txt, csv, zip)
```

- Folder names are `kebab-case` on the developer site; the end-user site also has mixed-case names (`SanitationHardships-DPW-WorkOrders`). Prefer `kebab-case` for new folders.
- Reference images and files with relative paths (`images/x.png`, `files/x.pdf`). The viewer rewrites them to `/<Site>/markdown/...` and serves them from the share.
- Upload limits (editor): page 2 MB, upload 25 MB. Images and files use the allow-lists above; `bmp` is served but cannot be uploaded.

## Front matter

Optional, at the top of the page, used for tags and search:

```yaml
---
tags:
  - KWAT
  - Framework
---
```

- A block list under `tags:` or inline `tags: [a, b]`. Reuse existing tags (the tag page lists them) before adding new ones.
- If a page starts with `---` it must be a valid front-matter block or the editor refuses to save it.
- The page title is the first `# ` heading after the front matter.

## Index pages

- Developer topic index: an intro paragraph, then a **Contents** list. Existing topics (for example `kwat`) list each page and its main anchors:

```markdown
- [Architecture](architecture.md): the tiers, the metaData object, the projects
  - [Tiers](architecture.md#tiers)
```

- Site root, developer: `index.md` ends with `## Topics`; `tools\update-index.ps1` regenerates one bullet per folder (link text is the first heading of that folder's `index.md`, link target is `<folder>/index.md`), alphabetical by folder.
- Site root, end-user: hand-edited `## Guides` list. Each bullet is a link to the guide's `index.md` followed by a colon and one sentence. Add the new guide in the same style, as in the existing line:

```markdown
- [Using KWAT applications](kwat/index.md): the shared layout and controls used across KWAT-based applications.
```

## Developer-audience pages

- Open with what the thing is and who it is for; give the source repository or project name in plain text and a verified date.
- Prefer tables for servers, tables of objects, and procedure signatures; fenced code with a language tag (`sql`, `java`, `powershell`, `text`).
- Include a glossary, a repository/file map, failure modes with a symptom -> cause -> fix table, and "known issues" where they exist.
- Describe credentials by name and location only.
- Diagrams: a `text` block or table. No mermaid.

## End-user-audience pages

- Task-oriented: what the user wants to do, numbered steps, the exact button/menu labels in bold.
- Screenshots come from a staging or practice copy, never production data. The KWAT guide marks each control with red numbered boxes and explains them in a table beside the picture; follow that style.
- Plain language, no internal server, database, or code names unless the user must see them.
- Start from the whole application and move down to single controls; end each guide with where to get help.

## Anchors and links

- Anchors follow GitHub rules: lowercase, punctuation removed, spaces to hyphens (`## Known issues` -> `#known-issues`).
- Link only to pages inside the same site with relative `.md` paths. Use plain text for anything outside it.
- After renaming a heading, search the topic for `#old-anchor` and fix every link.
