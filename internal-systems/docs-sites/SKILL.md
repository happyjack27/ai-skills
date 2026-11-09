---
name: docs-sites
description: 'Adding or updating pages on the City of Milwaukee DeveloperDocumentation and EndUserDocumentation Markdown sites (Tomcat viewer apps whose live content is the network share \\MkeAppsFs\FS\Apps\<Site>). Covers choosing the site by audience, pulling the share copy first, authoring in the local Eclipse project WebContent\markdown, page and index.md conventions, front-matter tags, relative links, images, link and secret checks, copying to the share, regenerating the topic index with tools\update-index.ps1, and the .history/.lock/edits.log files the browser editor keeps. Keywords: DeveloperDocumentation, EndUserDocumentation, developer docs, user guide, markdown viewer, MkeAppsFs, publish documentation, update-index.ps1, onboard a developer.'
---

# Developer and end-user documentation sites

## Purpose

Help an AI add or change Markdown pages on the two internal documentation sites and publish them to the live content store without losing anyone's edits.

## Scope

- Included: choosing the site, writing topic folders and pages, validating them, publishing to the network share, regenerating or editing the site index, and recording what changed.
- Excluded: changing the viewer code (servlets, JSP, `editor.js`) — that is ordinary Java/web work in the Eclipse project; deploying Tomcat; TFS check-in of the local project (the user does it).
- Excluded: content that belongs elsewhere — ITMDPedia pages (SharePoint, see `itmdpedia`), the AI skill library, and ai-memory notes.

## When to Use

- "Add this to the developer docs", "write a guide for users of X", "put the docs on the share", "onboard another developer, we need documentation".
- Publishing a new topic folder or updating pages under `DeveloperDocumentation` or `EndUserDocumentation`.
- Fixing a broken link, a stale fact, or the topic list on either site.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The destination is one of the two documentation sites (pages under `WebContent\markdown\` or the share `\\MkeAppsFs\FS\Apps\<Site>`).

**Do not use this skill when:**

- The task is reading the ITMD wiki. Use `itmdpedia`.
- The task is producing a schema/ERD and use-case package for an app. Use `webapp-docs` for the content, then this skill to publish it.
- The documentation belongs only inside a code repository (a repo `docs\` folder); a repo copy is optional and is not the live site.

**Pair with:**

- `webapp-docs`: content for schema and use-case pages.
- The skill for the subject (for example `migration-operations`, `kwat-services`, `accela`): the source of the facts being documented. Verify facts against code or the live system, not against the skill alone.
- `ai-memory`: record the topic, date, and exact next action in the `developer-documentation` project.

## Inputs Expected

| Input | Description |
|---|---|
| Audience | Developers/administrators (`DeveloperDocumentation`) or staff who use an application (`EndUserDocumentation`) |
| Topic folder name | Short `kebab-case` (developer site today: `kwat`, `enotify`, `loginmke`, `itmdpedia`, `accela-taxroll`, `sewer-hotline`, `dpw-oracle-migration`) |
| Source facts | Code, SQL, live systems, or existing pages; cite where verified |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Topic folder | `<topic>\index.md` plus pages, `images\`, `files\` | In the local project and, identical, on the share |
| Updated site index | Root `index.md` | Developer site: generated list. End-user site: hand-edited list |
| Memory note | ai-memory project `developer-documentation` | Topic, date, validation, next action |

## Workflow

1. **Pick the site by audience.** Developers, administrators, runbooks, architecture, code-level detail -> `DeveloperDocumentation`. How staff use an application, with screenshots and steps -> `EndUserDocumentation`. One subject can have a page on each; keep them consistent, and do not link across sites (relative links cannot leave a site).
2. **Resolve the two roots.** Local: `C:\Users\kbaas\eclipse-workspace\<Site>\WebContent\markdown`. Share (live): `\\MkeAppsFs\FS\Apps\<Site>`. Confirm both exist; the share folder name is the Tomcat context name.
3. **Pull before editing an existing page.** The share is the source of truth and people edit it in the browser. Compare it with the local copy, copy the share version down first, and read the tail of `<share>\.history\edits.log` for recent edits to the pages you will touch. A new topic needs no pull. Commands: [references/publish-commands.md](references/publish-commands.md).
4. **Author locally with the file-edit tools.** They cannot write UNC paths (`Network (UNC) paths are not permitted`), which is why the local project is the working area. Follow [references/page-conventions.md](references/page-conventions.md). For end-user screens, capture annotated screenshots (red boxes, circles, numbered labels, arrows) with [references/annotated-screenshots.md](references/annotated-screenshots.md), and put a numbered list or table explaining each number in the page text directly under the picture. Annotations are boxes, numbers, and at most a few short arrow words; never add bands, padding, or instructions to the image.
5. **Validate** with the link/anchor checker in [references/publish-commands.md](references/publish-commands.md): no broken relative links or anchors, no `mermaid` blocks, no secrets, first heading is a `#` title, page under 2 MB, only allowed image/file types.
6. **Publish.** Copy the topic folder from local to the share (never touch `.history`, `.lock`, or other dot-named entries). Update the index: run `tools\update-index.ps1 -Root <markdown root>` against **both** local and share for the developer site; edit the end-user `index.md` by hand (no script). Verify every file hash matches between local and share.
7. **Record.** Update the `developer-documentation` project in ai-memory (topic, date, source skill, anything left undone). Tell the user that the local project is not under git, so a TFS check-in is theirs to do, and list anything you could not verify.

## Quality Standards

- Verify every factual claim against source or the live system; put a "verified <date>" line on pages describing environments that change. Where code and a doc disagree, the code wins — fix the doc.
- Both sites are readable without signing in. Never include passwords, connection strings, keys, tokens, or personal data. A credential's **location or name** may be documented; its value never.
- Write relative links only to `.md` pages and attachments inside the site. Everything else (repository files, other sites, ai-memory) is a plain-text reference, not a link.
- Use tables, numbered steps, and language-tagged code blocks (`text` for diagrams). Do not use mermaid: the viewer does not render it.
- End-user pages show each screen they describe as an annotated capture (boxes, circles, numbered labels, arrows) taken from a practice copy with no real data. Capture only the controls the page explains; redo any picture with clipped labels or misplaced arrows.
- Keep one topic folder per subject with an `index.md` that lists every page; give pages unique, specific titles so search finds them.

## Common Mistakes

- **Overwriting a newer browser edit.** The viewer's editor writes the share directly and keeps `.history`; a plain file copy creates no history entry and no `edits.log` line, so the previous version is lost. Pull first, and before overwriting any existing share page, save a copy of the old file outside the share.
- **Treating `update-index.ps1` as universal.** It exists only in `DeveloperDocumentation\tools` and rewrites everything after `## Topics`. `EndUserDocumentation` has no script; its index is a hand-written `## Guides` list with a sentence per guide.
- **Linking out of the site.** `../README.md` or a repository path renders a dead link. Name the repository and file in plain text.
- **Mermaid blocks.** They display as raw code. Use a text block or a table.
- **Letting local and share drift.** The share folder overlays the WAR (share file wins, else the WAR's `WebContent\markdown`). Keep both identical so a missing share or a redeploy shows the same site.
- **Dot-named files.** Hidden names are never listed or served; do not put content in them.
- **Navigating the user's browser tab.** Captures are taken in a new tab (`forceNew: true`), never by `page.goto` in a shared tab. See [references/annotated-screenshots.md](references/annotated-screenshots.md#browser-handling).
- **Assuming a deploy went live.** The local Tomcat WAR is replaced through `C:\wars`, and a watcher picks it up. Confirm with a fetch of a changed asset (for example `http://localhost/DeveloperDocumentation/assets/viewer-tools.js`), not by file timestamps. Port 8080 refused connections on this machine; port 80 served the site.
- **Rebuilding a WAR from scratch.** To change one file, copy the existing WAR, replace that entry with `System.IO.Compression` (`ZipFile.Open(..., 'Update')`), and check the entry count is unchanged. Diff the old and new file first so only the intended lines change. Back up the original WAR before replacing it.

## Validation Checklist

- [ ] Right site for the audience; topic folder has `index.md` with a `#` title.
- [ ] Share pulled before editing existing pages; recent `edits.log` entries considered.
- [ ] Relative links and anchors resolve; no mermaid; no secrets.
- End-user screens are annotated captures (boxes, numbers, at most a few short arrow words; no added bands or padding), each checked with `view`, with the explanation as numbered text under the picture; no real data in pictures.
- [ ] Local and share copies byte-identical (hash check); index updated.
- [ ] ai-memory project note updated; user told about the TFS check-in and anything unverified.

## Resources

- [references/page-conventions.md](references/page-conventions.md): open before writing pages — front matter, titles, contents lists, images, developer vs end-user style.
- [references/site-internals.md](references/site-internals.md): open when something behaves unexpectedly or you need to know how the viewer, content store, history, and editor work.
- [references/publish-commands.md](references/publish-commands.md): open for the exact pull, validate, publish, index, and verify commands.
- [references/annotated-screenshots.md](references/annotated-screenshots.md): open before capturing any screen for a page. Holds the overlay helper (boxes, circles, arrows, numbered labels) and the pitfalls seen.
