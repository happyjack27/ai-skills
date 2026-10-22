---
name: mkesdp-servicedesk
description: 'City of Milwaukee IT service desk at mkesdp.milwaukee.gov (Zoho ServiceDesk Plus On-Demand, ITDesk app). Use to check the signed-in user''s open or closed mkesdp requests in a browser, read request status from list rows, sign in through Microsoft SSO, map "mkesdp #NNNNN" references in TFS work items to requests, and track each request and its progress in ai-memory working checkpoints. Keywords: mkesdp, ITDesk, service desk, SDP, open requests, request status, ticket, ai-memory tracking.'
---

# mkesdp IT service desk

## Purpose

Help an AI read the user's City of Milwaukee IT service desk requests in a
browser and report their status, without changing any request.

## Scope

- Included: reading request lists and status, switching list views, reading
  request details where the layout allows, and mapping mkesdp numbers from
  TFS work items to requests.
- Excluded: creating, editing, assigning, picking up, closing, reopening, or
  adding notes or tasks to requests. These change shared records; do them only
  on explicit user instruction for that exact action.
- Excluded: entering or storing credentials, bypassing Microsoft sign-in, and
  saving requester email addresses, phone numbers, or full ticket text to skills
  or memory. Request numbers and short subjects are fine.

## When to Use

- "Check my mkesdp tickets", "what is open in the service desk", "status of request 59020".
- A TFS work item description references `mkesdp #NNNNN` and the user wants its status.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The task needs the City ITDesk web app at `mkesdp.milwaukee.gov`.

**Do not use this skill when:**

- The task is about TFS work items or board columns. Use `tfs-boards`.
- The task is about Accela configuration or code. Use `accela` or its references.
- The task is about mailbox messages. Use `outlook-email`.

**Pair with:**

- `tfs-boards`: find the `mkesdp #NNNNN` references in work item descriptions.
- `ai-memory`: keep one task checkpoint per request, as described in
  [Tracking Requests in ai-memory](#tracking-requests-in-ai-memory).

## Key Facts (verified 2026-10-22)

- Requests page: `https://mkesdp.milwaukee.gov/app/itdesk/ui/requests`.
- Page title when signed in: `Requests - City of Milwaukee`.
- Sign-in: unauthenticated visits redirect to Microsoft sign-in
  (`login.microsoftonline.com`, SAML). The user signs in. The assistant does
  not enter credentials. A "Stay signed in?" prompt may appear; answer it only
  if the user asks.
- Two number systems:
  - Lists and headings show the display number, such as `#66823`.
  - Request URLs use an internal numeric ID. Example: internal ID
    `162131000061150185` is display `#59020`.
  - Do not build a URL from a display number. Find the row in the list, or ask
    the user for the link.

## Views

The list header has a view menu. The default view is **My Open Requests**.

| View | Use for |
|---|---|
| My Open Requests | Open requests assigned to the user (default) |
| All My Requests | Open and closed requests. Use for closed status checks |
| Open Requests, All Requests, My Open Or Unassigned, Requests Opened By Me | Team-wide or unassigned queues |

- Switch views by clicking the view name in the header menu, then the option.
- The "Search Views" box in the menu did not filter the list in testing. Use the menu options instead.

## Reading the List (Preferred Method)

- Each row's text carries the status: `#NUMBER Status Subject by Requester Technician`.
- Read status from the row text. Opening details is usually unnecessary.
- The name after "by" is the requester. The second name is the technician (owner).
- Snapshots are large (over 14 KB). Save the output and grep it for the pattern
  `#\d{5}` plus `Open` or `Closed`, instead of reading the whole file into context.
- A request missing from "My Open Requests" is probably closed, but may have been
  reassigned. Confirm in "All My Requests" before reporting it closed.

## Request Details

- The detail pane renders inside a sandboxed iframe. Snapshot tools show it as
  an empty `iframe`, so its text cannot be read that way.
- In a narrow viewport (about 480 px, mobile layout) the status field is hidden.
  Use a wider viewport or a screenshot if the status must come from the detail pane.
- The Actions sheet lists Edit Request, Pick up, Assign, Mark FCR, Add Note, and
  Add Task. Do not use any of them without explicit instruction.

## Closing or Changing Status (Close Request dialog)

Opening the close dialog is read-only. Only Save changes the request. Do not Save
unless the user explicitly asks to close or change the request.

The **Close Request** dialog has these fields, in order:

| Field | Type | Guidance |
|---|---|---|
| Is FCR | checkbox | Check only for a first-contact resolution the user confirms. |
| Requester Acknowledged Resolution | Yes / No | Defaults to **No**. Set **Yes** only when the requester confirmed the fix. |
| Closing Comments | text | Short resolution summary for the requester. |
| Closure Code | dropdown | Pick the code the user names. Ask if none is given. |
| **Closure Comments / Status Change Comments** | text (bottom box) | Required status note for the change. Fill it with the text the user approves. |

- **Status-change box:** write one or two plain sentences: what was done or why the
  status changed, and any open follow-up. Match the tone of the user's replies. Don't
  add links, requester contact details, or internal notes.
- **Draft, then confirm:** show the user the exact text for the status-change box and
  the Closing Comments, and Save only after they approve it.
- **Not a reply:** this box is internal to the ticket. Requester emails are separate
  and follow the Drafts-only rule.
- **Keep it in memory:** when the status changes, record the change and the approved
  text in the request's ai-memory checkpoint (see Closing in the tracking section).
- **Cancel leaves no change:** Cancel or the X closes the dialog without saving.

## Tracking Requests in ai-memory

Track every open request the user owns, and its progress toward resolution, in
ai-memory Working Memory at `C:\Users\kbaas\git\ai-memory`. Use the
[ai-memory lifecycle policy](C:/Users/kbaas/git/ai-memory/docs/lifecycle.md)
for format details.

- **One checkpoint per request:** `working\<project-id>\tasks\itdesk-<number>-<kebab-subject>.md`.
  The `itdesk-` prefix and the request number make the file easy to find.
- **Project:** the project the request concerns, such as `enotify-suite` for E-Notify
  issues or `outlook-inbox` for Accela, DPW, and general application support. If it's
  unclear, check [projects/PROJECTS.md](C:/Users/kbaas/git/ai-memory/projects/PROJECTS.md)
  or ask.
- **Frontmatter:** from the [task template](C:/Users/kbaas/git/ai-memory/skills/memory-resume/assets/task.md):
  `id: itdesk-<number>-<slug>`, `scope: working`, `project`, `status`, and `updated: 'YYYY-MM-DD'`.
- **Status values:**

  | Request state | Task `status` |
  |---|---|
  | Not yet started | `pending` |
  | Being worked on | `in-progress` |
  | Waiting on the requester, the user, or another team | `blocked` |
  | Resolved, requester confirmed, or closed in mkesdp | `done` |
  | Withdrawn or superseded | `cancelled` |

- **Register it:** add or update a row in
  [working/WORKING.md](C:/Users/kbaas/git/ai-memory/working/WORKING.md) with project,
  task title, status, date, and checkpoint link.
- **Find before creating:** search `working\WORKING.md` and the project's `tasks\`
  folder for `itdesk-<number>`. Update an existing checkpoint rather than making a second one.
- **Contents:** goal and completion conditions (what "done" means), current state
  (what was done and what remains), validation (what was tested or checked, and what
  wasn't), and the blocker or exact next action with its owner.
- **Save at each meaningful step:** a reply drafted or sent, the requester answering,
  a fix deployed, a status change in mkesdp, and before stopping. Don't wait for the end.
- **Drafts only:** write replies to requesters as drafts. Send them only after the user approves.
- **Live state wins:** if a checkpoint disagrees with the live mkesdp list, trust the
  list, then update the checkpoint and its WORKING.md row.
- **Closing:** when the request is `done` or `cancelled`, keep the final checkpoint, set
  its status, and move it to `archive/` only after its important findings are promoted,
  per the lifecycle policy. Remove its active row in the same change.

## Workflow

1. Open the Requests page. If it redirects to Microsoft sign-in, ask the user to
   sign in in the browser, then continue once the page title is `Requests - City of Milwaukee`.
2. Select the view that matches the question (usually My Open Requests).
3. Take a snapshot and extract the rows with grep (`#\d{5}`).
4. For a specific number, switch to All My Requests and match the row. If it is
   not there, ask the user.
5. Report number, status, subject, requester, and technician for each item. Keep the
   report to what the user asked for.
6. For each open request, create or update its ai-memory checkpoint and WORKING.md row
   as described in [Tracking Requests in ai-memory](#tracking-requests-in-ai-memory).

## Common Mistakes

- Treating a TFS `mkesdp #NNNNN` number as an internal URL ID. It is a display number.
- Typing in the view search box and expecting the list to filter.
- Reading the full snapshot into context instead of grepping the saved output.
- Using the Actions sheet while only trying to read status.
- Reporting a status taken from the narrow detail layout without checking the list row.
- Reporting "closed" from absence in one view without checking All My Requests.
- Tracking progress only in chat. The next session can't see it, so save the checkpoint.
- Creating a second checkpoint for a request that already has one. Search first.
- Sending a requester reply without the user's approval.
- Saving the Close Request dialog to test it, or leaving Requester Acknowledged set to Yes without the requester's confirmation.
- Filling the Closure Comments / Status Change Comments box with text the user hasn't approved.

## Validation Checklist

- [ ] Page title is `Requests - City of Milwaukee` and the URL is on `mkesdp.milwaukee.gov`.
- [ ] The active view is confirmed in the snapshot before reporting.
- [ ] Every number and status was read from the list rows or a visible detail field.
- [ ] No request was created, changed, assigned, or closed.
- [ ] No credentials, requester email addresses or phone numbers, or full ticket text were saved to skills or memory.
- [ ] Each open request has one ai-memory checkpoint, registered in `working\WORKING.md` with a current status.
- [ ] Checkpoint status matches the live mkesdp list, and its next action names an owner.
- [ ] Replies to requesters are drafts unless the user approved sending.
- [ ] Close Request dialogs were only opened, not saved, unless the user asked for the change; the status-change box holds approved text.

## Resources

- Accela-related mkesdp integration ticket notes (folder map): open
  [interface-folder-map.md](../../accela-platform/accela/references/interface-folder-map.md)
  when a request concerns an Accela integration.
- Request tracking index (open the first, then only the checkpoints you need):
  [WORKING.md](C:/Users/kbaas/git/ai-memory/working/WORKING.md). Open it when tracking
  or reporting on requests. Existing ITDesk checkpoints are listed there by request number.
