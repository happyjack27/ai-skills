# Site internals

How the two sites work, from `ContentStore.java`, `Edit.java`, `markdownViewer.jsp`, and the ai-memory project `developer-documentation` (verified 2026-11-03). Both sites run the same code; only the context name and index differ.

## Projects and locations

| Item | Developer site | End-user site |
|---|---|---|
| Eclipse project (not under git) | `C:\Users\kbaas\eclipse-workspace\DeveloperDocumentation` | `C:\Users\kbaas\eclipse-workspace\EndUserDocumentation` |
| Pages in the project (WAR fallback) | `WebContent\markdown\` | `WebContent\markdown\` |
| Live content folder | `\\MkeAppsFs\FS\Apps\DeveloperDocumentation` | `\\MkeAppsFs\FS\Apps\EndUserDocumentation` |
| Index generator | `tools\update-index.ps1` | none |
| Editor tests | `tools\editor-tests\` | none |

## How a page is served

- `ContentStore` resolves the content folder from, in order: JVM option `-Ddocs.content.dir.<ContextName>`, JNDI `docsContentDir`, context-param `docsContentDir`, then the built-in default `\\MkeAppsFs\FS\Apps\<ContextName>`. Any of them set to `off` disables editing. Nothing needs configuring on a normal server.
- The folder **overlays** the WAR: a file in the folder wins, anything else comes from the WAR's `/markdown/`. Saves and uploads write only to the folder, which a deploy never replaces. If the folder is configured but unreachable, reads keep working from the cache/WAR and edits return 503.
- The server re-checks the folder for changes at most every 3 seconds (WAR every 30), so a copied page appears within seconds without a restart.
- Names that start with `.` (`.history`, `.lock`, temp files) are never listed or served.
- `markdownViewer.jsp` renders in the browser with `marked`, `DOMPurify`, and `highlight.js` loaded from a CDN. Consequences: no mermaid, raw HTML is sanitized, and the first `# ` heading becomes the page title.
- Relative links to `.md` pages open in the viewer. Relative links to attached files and images are rewritten to `/<Context>/markdown/...` and served by `ContentFile` (attachments as downloads).
- Search loads every `.md` file as one JSON document on first use (about 3.2 MB on the developer site, mostly the ITMDPedia import). Tags come from front matter.

## What the browser editor adds

- Editing is for authenticated AD users in the group from context-param `docsEditorGroup` (default `ITMD Developers`). Readers need no sign-in.
- A save writes a temp file then moves it atomically, under a JVM lock plus a `.lock` file lock, and returns 409 if the page changed since the editor loaded it. The previous text is copied to `.history\<page>\<yyyyMMdd-HHmmssSSS>-<user>.md`.
- `.history\edits.log` is one JSON line per `create`, `edit`, or `upload` (time, user, action, file, detail, version hash, previous hash, bytes). It is append-only. It is not public: the log endpoints are editors-only because it names staff.
- A plain file copy to the share bypasses all of this: no history copy, no log line, no 409 check. That is acceptable for publishing but is why pages must be pulled first and old versions backed up.
- Planned but not built (as of 2026-10-30): history/diff/restore screen, rename/delete, new-page button, scheduled share-to-TFS snapshot job, read-only staging copy. Until the snapshot job exists, TFS only has what a developer checks in from the local project.

## Index files

- Developer root `index.md`: text before `## Topics` is kept; everything after is regenerated from each folder's `index.md` first heading by `update-index.ps1`. Folders without an `index.md` are skipped.
- End-user root `index.md`: manual `## Guides` list.

## Files that matter

| File | Why |
|---|---|
| `src/servlets/ContentStore.java` | Folder resolution, overlay, limits, allow-lists, save rules |
| `src/servlets/Edit.java`, `EditLog.java` | Save/upload endpoints and the edit log |
| `src/servlets/MarkdownFiles.java` | Front matter, title, and tag reading |
| `WebContent/markdownViewer.jsp`, `WebContent/assets/*.js` | Viewer, search, tags, editor |
| `tools/update-index.ps1` | Developer topic list generator |
