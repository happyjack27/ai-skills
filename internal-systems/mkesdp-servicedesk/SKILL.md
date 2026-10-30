---
name: mkesdp-servicedesk
description: 'City of Milwaukee IT service desk at mkesdp.milwaukee.gov (Zoho ServiceDesk Plus On-Demand, ITHelp app). Use to check the signed-in user''s open or closed mkesdp requests in a browser, read request status from list rows, sign in through Microsoft SSO, map "mkesdp #NNNNN" references in TFS work items to requests, and track each request and its progress in ai-memory working checkpoints. Keywords: mkesdp, ITHelp, service desk, SDP, open requests, request status, ticket, ai-memory tracking.'
---

# mkesdp IT service desk

## Purpose

Help an AI read the user's City of Milwaukee IT service desk requests in a
browser, report their status, and create new requests when the user asks, in
a browser. Do not change existing requests unless the user asks for that exact action.

## Scope

- Included: reading request lists and status, switching list views, reading
  request details where the layout allows, mapping mkesdp numbers from TFS work
  items to requests, and creating a new request (see
  [Creating a Request](#creating-a-request)) after the user approves the filled form.
- Excluded: editing, assigning, picking up, closing, reopening, or adding notes or
  tasks to existing requests. These change shared records; do them only on explicit
  user instruction for that exact action.
- Excluded: entering or storing credentials, bypassing Microsoft sign-in, and
  saving requester email addresses, phone numbers, or full ticket text to skills
  or memory. Request numbers and short subjects are fine.

## When to Use

- "Check my mkesdp tickets", "what is open in the service desk", "status of request 59020".
- A TFS work item description references `mkesdp #NNNNN` and the user wants its status.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The task needs the City ITHelp web app at `mkesdp.milwaukee.gov`.

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

## Creating a Request

Create a request only when the user asks for it. Fill the form, show the user
the field values, and submit only after they approve. Submitting creates a
shared record. Requester emails and phone numbers are entered into the form
but are never saved to skills or memory.

- **Open the form:** go to `https://mkesdp.milwaukee.gov/app/itdesk/ui/requests/add`
  directly. Clicking the New Incident menu item is blocked by a Home breadcrumb
  overlay. The menu path is the `+` button in the Requests list header, then New Incident.
  "Quick Incident" is a separate header option and is not the same form.
- **Required fields** (marked with an asterisk): Urgency, Request Type, Requester
  Name, Work Phone, Category, Subject, Description. Urgency keeps its default
  unless the user names one.
- **Request Type** options: Incident Report (default), Security Incident, Service Requests.
- **Category** (Select2 dropdown, click the "-- Select Category --" span, then the option)
  options include Database, GIS, Applications, Server, Network Drives, User Administration,
  and about 50 others. Use GIS for GIS data work. Pick the values the user names; ask if none are given.
- **Group** options include Applications, Database Administration, GIS, Enterprise Systems,
  Server Support, and IT Support. Use GIS for GIS work and Database Administration for database
  changes. The Group list only fills after Category is set, so set Category first.
- **Ticket lookup:** TFS (`tfs.milwaukee.gov`) is not reachable from this machine. Find the
  original work in mkesdp instead. My Open Requests shows only open items, so closed tickets need
  Requests Opened By Me (switch with the view dropdown on the list header). Open the request's
  details page and check the Conversations tab (`details?selectTab=conversationsDetails`)
  to read the thread. The URL uses the internal ID (for example `162131000066991117`), not
  the display number.
- **Browser sessions:** if VS Code restarts or freezes, the browser page is closed and the
  partly filled form is lost. Reopen the form and refill it. Nothing is saved until Add Request.
- **Browser tool hygiene (learned 2026-10-28):** Never call `stop_powershell` on a
  browser run; it only stops shell processes and the page can be lost. Avoid scanning every
  frame with `page.frames()` and `evaluate`, because it can hang. Read the form directly with
  `page.getByRole`/`page.locator` instead. If `openBrowserPage` times out, check the returned
  page ID with a short `runPlaywrightCode` call before retrying. Keep the viewport at
  1600x1000 so the Select2 options render. Refill the form in one pass after a reopen.
- **Work in a page Kevin can see (learned 2026-10-28).** Kevin must be able to watch the
  form. If a page is listed as "(not visible)" in the Browser Pages attachment, do not keep
  driving it. Ask Kevin to share the page or open a fresh one with
  `openBrowserPage` using `forceNew: true`, and only work on a page marked "(active)".
  Opening a new page discards the earlier draft, so refill it in one pass and read back every
  field before submitting. Also, the new page may load in a mobile layout (about 375px wide).
  Call `page.setViewportSize({width:1600,height:1000})` before filling. A `browserRefresh`
  overlay ("refresh the page") appears after a size change. Click its refresh action (or
  reload) and then refill, rather than working around it. Do not treat the form reset as a
  failure.
- **Always fill the email for Kevin (learned 2026-10-28).** Kevin's address is
  kbaas@milwaukee.gov. The form has a "Work Email" field (`udf_fields-udf_char8`) and an
  "Emails to Notify" field. Fill both with his address before submitting, and read them back.
  Do not submit a request with either one empty.
- **Editing a submitted request (learned 2026-10-28).** Open the details page and click
  "Edit." The form's submit button is "Update Request" at the bottom of the form, not "Save."
  The top-nav "Save" button (`#savepersonalize`) is unrelated. Scroll down and click
  "Update Request," then confirm the "Request updated" message and reopen the details page.
- **Write the description for the assignee, not for Kevin (learned 2026-10-28).** The assignee
  may not see the original email or thread. Put the concrete work in the description: the exact
  field and table names, and the action. Do not add research steps for the assignee unless Kevin
  asks for them. Name the fields from the database or ai-memory before submitting.
- **Description editor does not sync (2026-10-28).** The Description iframe (`about:srcdoc`)
  holds the text, but the hidden `textarea[name=description]` stays empty and Add Request
  reports "Provide value for field Description." Typing, Tab, and mouse clicks did not fix it.
  Stop and ask Kevin before trying more workarounds.
- **Subject** is prefilled with "General Incident -- Please update this Subject line --".
  Replace the whole text with the user's subject.
- **Requester Name** is a typeahead with a search dialog. Searching for a person
  may show "No requester found". The form says the requester is created when the
  request is submitted, so the typed name is accepted. Confirm the value in the
  form before submitting. For Kevin Baas the requester is "Baas, Kevin" (Last, First
  format). Choose that typeahead match and confirm its department matches the user.
  Press Escape to close the search dialog.
- **Work Phone** and **Work Email** are separate textboxes. Do not put a phone
  number in the email field.
- **Description** is a rich-text editor inside an iframe. Snapshot tools do not
  show its text. Setting `document.body.innerHTML` shows the text but does not
  clear the form's "Provide value for field Description" error, so the submit is
  rejected. Instead, click into the editor, clear it with a loop of Backspace
  key presses (Ctrl+A did not select reliably), type the lines with keyboard.type
  and Enter between them, then click another field (such as Subject) to blur the
  editor. Check that the alert is gone before submitting.
- **Submit button** is labeled "Add Request" (not Submit). It opens the new
  request's details page, whose title is `#NNNNN Request Details`.
- **Filling fields:** `typeInPage` with element refs misfired when refs shifted, and
  phone and email ended up in the same field. Use `runPlaywrightCode` with
  `page.getByRole('textbox', { name: ... }).fill(...)`, then read the page back to
  verify each field.
- **Keyboard select-all** (Ctrl+A, Shift+Home) did not select text reliably in the
  Description editor. Replace the content instead.
- **Verify, then ask:** before submitting, read back every field and the Description
  text, and show them to the user. Submit only after approval.
- **Record it:** after submission, note the new request number and the approved
  subject in the ai-memory checkpoint and WORKING.md (see Tracking Requests in ai-memory).
- **Save nothing sensitive:** do not record requester email, phone, or full ticket text in the skill or memory.

## Request Details

- The detail pane renders inside a sandboxed iframe. Snapshot tools show it as
  an empty `iframe`, so its text cannot be read that way.
- In a narrow viewport (about 480 px, mobile layout) the status field is hidden.
  Use a wider viewport or a screenshot if the status must come from the detail pane.
- The Actions sheet lists Edit Request, Pick up, Assign, Mark FCR, Add Note, and
  Add Task. Do not use any of them without explicit instruction.

## Editing Request Fields (learned 2026-10-23)

- The details page's read-only fields (such as **Emails to Notify**, shown as "-")
  do not open on click or double-click, and hovering shows no edit icon.
- Use the toolbar **Edit** button on the details page. It opens the full
  `Edit Incident` form at `/app/itdesk/ui/requests/<internalId>/edit`. The request
  number appears at the top right of that form.
- In the edit form, **Emails to Notify** is a select2-style box below Description,
  with the placeholder `-- Select Emails to Notify --`. Clicking it focuses the box.
  Typing an address to add it is not yet verified; check the picker first.
- Nothing is saved until the form's Save is used. Confirm the exact value with the
  user before Save, and leave the form with Cancel if the user declines.
- Required fields in the edit form have a red asterisk.

## Closing or Changing Status (Close Request dialog)

Opening the close dialog is read-only. Only Save changes the request. Do not Save
unless the user explicitly asks to close or change the request.

The **Close Request** dialog has these fields, in order:

| Field | Type | Guidance |
|---|---|---|
| Is FCR | checkbox | Check only for a first-contact resolution the user confirms. |
| Requester Acknowledged Resolution | Yes / No | Defaults to **No**. Set **Yes** only when the requester confirmed the fix. |
| Closing Comments | text | Short resolution summary for the requester. |
| Closure Code | dropdown | Always **Success**, unless the user names a different code. |
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

### Field details and comment style (learned 2026-10-23)

- The top box is **Closing Comments** (`#closure_info-requester_ack_comments`). The
  bottom box is **Closure Comments / Status Change Comments**
  (`#closure_info-closure_comments`). Fill only the box the user names, and clear the
  top box unless the user supplies text for it.
- Status-change text should be very short, in the user's own wording. For a
  change of contact details, use a phrase such as `Updated email address.` Do not add
  reasons, names, addresses, or follow-up notes. Shorten the text when the user says
  it is too long.
- Closure Code is a select2 dropdown (`#closure_info-closure_code`). The options are
  Cancelled, Failed, Postponed, Rejected, Resolved, Success, Unable to Contact, and
  Unable to Reproduce. Use **Success** by default. Use another code only when the user names it. Do not default to Resolved.
- Requester Acknowledged Resolution is a radio group (name
  `closure_info-requester_ack_resolution`). It defaults to No.

### Saving the dialog

- The dialog's Save is the button with `name="submit"` at the bottom of the dialog.
  Other visible buttons labeled "Save" elsewhere on the page can be matched first.
  Select by name, then confirm the position is inside the dialog before clicking.
- After Save, check the dialog and the list. If the dialog is still open and shows
  "Error" markers, the request is not saved. Read which field is invalid before retrying.
- After a save, confirm the list row status and the closure code before recording it
  in memory. A row missing from the Open view is not proof of closure. Check the
  Closed or All My Requests views.

### Browser handling

- Use a desktop-width viewport (about 1280x900). At narrow widths the page shows a
  mobile layout with no Close Request form. If the "Browser resized! Refresh" overlay
  appears, reload.
- Hidden inputs report a bounding box at (0,0). Clicking at computed coordinates can
  hit the hamburger "Instances" menu instead. Click only visible elements, and
  unselect a row after a misclick.
- Keep the browser window visible and tell the user before each browser action. Do
  not leave background pages or hidden windows. If the user cannot see a window, open
  a new visible page and say so.

## Tracking Requests in ai-memory

Track every open request the user owns, and its progress toward resolution, in
ai-memory Working Memory at `C:\Users\kbaas\git\ai-memory`. Use the
[ai-memory lifecycle policy](C:/Users/kbaas/git/ai-memory/docs/lifecycle.md)
for format details.

- **One folder per request:** `C:\Users\kbaas\git\ai-memory\working\mkesdp-tickets\<number>\`
  (`<number>` is the display number, such as `66537`). Put the checkpoint in it as
  `itdesk-<number>-<kebab-subject>.md`. Put query exports or other output in an optional
  `output\` subfolder (for example `working\mkesdp-tickets\66537\output\`). Don't put
  ITHelp checkpoints in project `tasks\` folders.
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
- **Find before creating:** check `working\mkesdp-tickets\<number>\` and search
  `working\WORKING.md` for `itdesk-<number>`. Update an existing checkpoint rather than making a second one.
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
- Clicking the first "Save" on the page instead of the dialog's `name="submit"` Save.
- Setting a closure code other than Success when the user didn't name one.
- Using long closing text when the user asked for a short status note.
- Clicking hidden checkboxes at computed coordinates, which can open the hamburger menu.
- Assuming a request is closed because it left the Open view, without checking the Closed view.

## Validation Checklist

- [ ] Page title is `Requests - City of Milwaukee` and the URL is on `mkesdp.milwaukee.gov`.
- [ ] The active view is confirmed in the snapshot before reporting.
- [ ] Every number and status was read from the list rows or a visible detail field.
- [ ] No request was created without explicit user instruction, and no existing request was changed, assigned, or closed.
- [ ] A new request was submitted only after the user approved every field, including the Description.
- [ ] No credentials, requester email addresses or phone numbers, or full ticket text were saved to skills or memory.
- [ ] Each open request has one ai-memory checkpoint in `working\mkesdp-tickets\<number>\`, registered in `working\WORKING.md` with a current status.
- [ ] Checkpoint status matches the live mkesdp list, and its next action names an owner.
- [ ] Replies to requesters are drafts unless the user approved sending.
- [ ] Close Request dialogs were only opened, not saved, unless the user asked for the change; the status-change box holds approved text.

## Resources

- Accela-related mkesdp integration ticket notes (folder map): open
  [interface-folder-map.md](../../accela-platform/accela/references/interface-folder-map.md)
  when a request concerns an Accela integration.
- Request tracking index (open the first, then only the checkpoints you need):
  [WORKING.md](C:/Users/kbaas/git/ai-memory/working/WORKING.md). Open it when tracking
  or reporting on requests. Existing ITHelp checkpoints are listed there by request number.
