---
name: itmdpedia
description: 'City of Milwaukee ITMD knowledge base (ITMDPedia) on SharePoint Online at milw.sharepoint.com/sites/ITMDPedia. Use to sign in through Microsoft SSO in a browser, browse Wiki Categories, find pages by title or full text, and read page content and attached PDFs or Word files, via the signed-in browser session and read-only SharePoint REST calls. Keywords: ITMDPedia, ITMD wiki, knowledge base, how-to, SharePoint wiki, Wiki Categories, Enhanced Reporting Database, internal documentation.'
---

# ITMDPedia knowledge base

## Purpose

Help an AI find and read pages in the ITMD wiki, `https://milw.sharepoint.com/sites/ITMDPedia/Pages/home.aspx`, through the user's signed-in browser session.

## Scope

- Included: signing in (user does it), browsing categories, finding pages by title, category, or full text, reading page bodies and linked documents, and reporting what was found with the page URL.
- Excluded: creating, editing, deleting, or re-tagging pages, and uploading files. All ITMD staff can write to this wiki, so a mistaken edit is visible to everyone. Edit only on explicit user instruction for that exact change.
- Excluded: entering credentials or bypassing Microsoft sign-in.
- Excluded: copying passwords, connection strings, or secrets from pages into skills, memory, or chat. The wiki's own rule is "do not put passwords on any of the pages", but old pages can still contain them. Report that a secret exists and where; do not repeat it.

## When to Use

- "Look in ITMDPedia for ...", "is there a how-to for ...", "what does our wiki say about ...".
- The user links a `milw.sharepoint.com/sites/ITMDPedia/...` page.
- A task needs internal ITMD procedures (SQL Server, DNS, Hyper-V, Oracle, Accela infrastructure, certificates).

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The source is the ITMD wiki on SharePoint.

**Do not use this skill when:**

- The task is TFS work items. Use `tfs-boards`.
- The task is a service desk request. Use `mkesdp-servicedesk`.
- The task is a mailbox message. Use `outlook-email`.
- The task is Accela configuration or code. Use `accela`; use this skill only for infrastructure notes the wiki holds.

**Pair with:**

- `ai-memory`: record the page URL and a one-line finding, not the page text.

## Key Facts (verified 2026-10-30)

- Home: `https://milw.sharepoint.com/sites/ITMDPedia/Pages/home.aspx`. Title `home`.
- Sign-in: unauthenticated visits redirect to `login.microsoftonline.com`. The user signs in; the assistant does not type credentials. Once signed in, the session carries over to later calls in the same browser page.
- The site is a SharePoint publishing site. Pages are items in the `Pages` library (about 650 items, highest ID about 743 at verification). Most wiki pages have a friendly URL `/sites/ITMDPedia/<slug>`; older pages use `/sites/ITMDPedia/Pages/<Title>.aspx`.
- Organization is by category tags, not folders. Categories seen: Accela, Certificate Services, City Clerk, DCD, DNS, DPW, Health, Hyper-V, ITMD, Mayor, Oracle, SQL Server, TestCategory01. Pages can carry several tags.
- Obsolete pages are tagged `Deprecated` by convention. Treat these as possibly stale and say so.
- Attachments live in the `Documents` library (`/sites/ITMDPedia/Documents/...`, mostly PDFs) and `PublishingImages` (images and Word files).
- Page history is under the page's Page tab, Page History. Prior versions can matter when a page looks changed.
- Home page rules (read from the page): all members of the ITMD AD group have read and write access; no passwords on pages; tag obsolete content `Deprecated`.

## Workflow

1. Open the site in the browser (`openBrowserPage` with the home URL). If the page title is "Sign in to your account", ask the user to sign in and wait for confirmation.
2. Prefer the REST helpers below over reading page snapshots. A home page or list snapshot is over 350 KB. If you do need one, it is saved to a file; grep it for `/url: /sites/ITMDPedia/` and read narrow ranges.
3. Find the page: category, title, or full text (see [Finding Pages](#finding-pages)).
4. Read the page body (see [Reading a Page](#reading-a-page)). Convert HTML to plain text before summarizing.
5. Report the page title, URL, last modified date, categories, and whether it is tagged Deprecated, then the answer.

## Calling REST from the Browser Session

Use `runPlaywrightCode` on the signed-in page and call `fetch` with same-origin credentials. All calls below are GET and read-only.

```js
return page.evaluate(async () => {
  const h = { headers: { Accept: 'application/json;odata=nometadata' }, credentials: 'same-origin' };
  const r = await fetch("/sites/ITMDPedia/_api/web/lists/getbytitle('Pages')/items?$select=Id,Title,FileLeafRef,Modified&$orderby=Modified desc&$top=20", h);
  return JSON.stringify((await r.json()).value);
});
```

- Run it from a page already on `milw.sharepoint.com`; a relative URL then reuses the session.
- The tool result appends a page snapshot after the `Result:` line. If the output is saved to a file, read the first lines only.
- Add `timeoutMs` (for example 30000) for search and large reads.
- Return compact strings. Do not return whole bodies unless needed.
- Do not call `POST`, `MERGE`, `PATCH`, or `DELETE`.

## Finding Pages

| Goal | Call |
|---|---|
| Recent pages | `items?$select=Id,Title,Modified&$orderby=Modified desc&$top=25` |
| Title contains a word | `items?$select=Id,Title&$filter=substringof('report',Title)&$top=25` |
| Pages in a category | `items?$select=Id,Title,TaxCatchAll/Term&$expand=TaxCatchAll&$filter=TaxCatchAll/Term eq 'DNS'&$top=100` |
| Full text (pages and documents) | `/sites/ITMDPedia/_api/search/query?querytext='replicas'&rowlimit=10&selectproperties='Title,Path'&trimduplicates=false` |

All `items` paths are relative to `/sites/ITMDPedia/_api/web/lists/getbytitle('Pages')/`.

- Title and category filters are reliable. Use them first.
- Full-text search covers page bodies and PDFs in `Documents`, but it also returns hits from other sites. Keep only paths that start with `https://milw.sharepoint.com/sites/ITMDPedia/`.
- Search results show the friendly URL (`/sites/ITMDPedia/<slug>`). Open it directly or find the item by title to get its ID.
- A `$filter` on the body field (`substringof(..., PublishingPageContent)`) is rejected with HTTP 400. Use search for body text.
- A path-scoped search query (`path:"…/Pages"`) returned only Home. Do not scope to `/Pages`; filter paths in the result instead.
- `$expand=TaxCatchAll` needs `TaxCatchAll/Term` in `$select`, or SharePoint returns HTTP 400.
- Results are paged. Use `$top` and follow `odata.nextLink` for more, or narrow the filter.

## Reading a Page

Page body is the `PublishingPageContent` field (HTML). The `WikiField` and `CanvasContent1` fields do not exist here; asking for them returns HTTP 400.

```js
return page.evaluate(async () => {
  const h = { headers: { Accept: 'application/json;odata=nometadata' }, credentials: 'same-origin' };
  const r = await fetch("/sites/ITMDPedia/_api/web/lists/getbytitle('Pages')/items(740)?$select=Id,Title,FileRef,Modified,PublishingPageContent,Wiki_x0020_Page_x0020_Categories", h);
  const j = await r.json();
  const text = (j.PublishingPageContent || '').replace(/<br\s*\/?>/gi, '\n').replace(/<\/(p|h\d|li|tr)>/gi, '\n').replace(/<[^>]+>/g, '').replace(/&#160;|&nbsp;/g, ' ');
  return JSON.stringify({ title: j.Title, url: j.FileRef, cats: (j.Wiki_x0020_Page_x0020_Categories || []).map(c => c.Label), text });
});
```

- Find the item ID first (see the finding table). Example: ID 740 is "Accela Enhanced Reporting Database".
- Category labels come from `Wiki_x0020_Page_x0020_Categories` (a multi-value taxonomy field).
- Tables and images are lost in the tag stripping. If a page is mostly a table or screenshot, open the page URL in the browser and read the snapshot instead.
- For a PDF or Word attachment, give the user the link and read it with a local tool only if they ask; the browser viewer is not a reliable text source.
- If a REST result seems to disagree with the rendered page, trust the rendered page and check Page History.

## Browser Navigation (When REST Is Not Enough)

- Search box: `combobox "Search this site"` in the page header, then the Search button.
- Left navigation on home: `Pages` and `Wiki Categories`; expand a category to list its pages.
- Other pages show a Categories section on the right.
- Clicking the blue ITMD logo returns to home.
- Do not click `[Edit this page]`. It opens the page in edit mode.

## Common Mistakes

- Reading the whole home page snapshot: it is 350 KB. Use REST or grep a saved snapshot.
- Using `WikiField` for the body: use `PublishingPageContent`.
- Trusting the full-text search to be scoped to ITMDPedia: filter by path.
- Quoting a Deprecated page as current: check its categories first.
- Copying a password or connection string seen on a page: report location only.
- Opening a page in edit mode and leaving it: shared wiki pages can be locked or overwritten.

## Validation Checklist

- [ ] The browser page title is not "Sign in to your account" before any call.
- [ ] Only GET requests were made.
- [ ] The answer cites the page title and URL, and notes Deprecated or last-modified date.
- [ ] No secrets from the page were repeated or stored.
