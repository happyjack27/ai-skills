---
name: accela-report-deploy-request
description: 'Use to submit an Accela Report Upload Request (Report Request) on the Accela Success Community at success.accela.com, asking Accela Reporting to deploy or upload a City of Milwaukee Crystal report after its change is committed, and then to register the deployed report in Production Accela Report Manager (name, category, report link, Reports 1, parameters, permissions) once Accela emails that the case is closed. Covers navigation, form fields, environment choice, attachments, approval before Submit, the deployment-email check, and Report Manager setup.'
---

# Accela report deploy request (Success Community)

Use this skill after a Crystal report change is committed in
`C:\Users\kbaas\git\accela-reports` and needs to go to production or staging through Accela.
Accela Reporting handles the upload. The assistant prepares and fills the form. The user submits or approves.

## Scope

- Included: opening the Report Request form, filling its fields, attaching files, and reading
  back the values for approval.
- Excluded: signing in, entering credentials, or saving a password anywhere. The user signs in
  in the browser.
- Excluded: clicking **Submit** without explicit user approval of every field. Submitting creates
  a shared Accela case.
- Excluded: Technical Support issues. Use the Request Support form for those.
- Included (new report only): after Accela's deployment email, registering the report in Production
  Accela Report Manager. This writes to production, so the user must ask for it or approve it, and
  every value is shown before each save. Finding or reading existing reports in Report Manager is
  covered by the `accela-reports` skill ("Finding a Report in Accela Report Manager").

## Key facts

- Community home: `https://success.accela.com/s/`. Sign-in page is `https://success.accela.com/s/login/`.
- Direct form URL: `https://success.accela.com/s/report-request`.
- Home page tile: **Report Upload Request** ("Submit a Report Request with ease."). Its link opens
  the form at the URL above. Clicking the tile in the browser may not navigate; navigate to the URL instead.
- The form is titled **Submit a Report Request**. Its banner says the case is routed to the Accela
  Reporting Team for report uploads.
- The **Contact Name** lookup is pre-filled with the signed-in user (Kevin Baas for this user).

## Form fields

| Field | Type | Guidance |
|---|---|---|
| Account Name | lookup | Use the account the request is for. |
| Contact Name | lookup | Pre-filled with the signed-in user. Change only if the user names someone else. |
| Subject | text | Always `Deploy to production and test` (user standing instruction, 2026-10-30). Do not substitute a report-specific subject. |
| Environment | picklist | Production or Staging. The form instructions require this. Ask the user if unclear. |
| Staging Environment | picklist | Disabled until Environment is set. Fill only when the request is for staging. |
| Description | textarea | Always `Deploy to production and test` (user standing instruction, 2026-10-30). The attached `.rpt` identifies the report. Keep the report name, folder path, commit hash and change summary in the ai-memory checkpoint, not in the form, unless the user asks otherwise. |
| Case Severity | picklist | Defaults to **Severity 3**. Keep the default unless the user names another. |
| Upload File | button | Attach the `.rpt` file (and any PDF the user wants reviewed). The form asks for files at the bottom. |
| Submit | button | Creates the case. Do not click without approval. |

## Workflow

1. Confirm what is being deployed: the report file path (for example
   `C:\Users\kbaas\git\accela-reports\dns admin\<report>.rpt`), the commit hash, the Environment
   (Production or Staging), and the description the user wants.
2. Navigate to `https://success.accela.com/s/report-request`. If it shows the login page, ask the
   user to sign in in the browser, then continue.
3. Check the page title is `Report Request` and the heading is **Submit a Report Request**.
4. Fill Subject, Environment, Description, and Case Severity. Verify each by reading the page back.
5. Ask the user to attach the `.rpt` (and optionally the PDF) with **Upload File**. Do not guess
   file paths in the file dialog without confirming them with the user.
   - Upload flow (verified 2026-10-23): the form's **Upload File** opens a Salesforce "Select File"
     dialog. Its own **Upload File** button opens the native file chooser. Use
     `page.waitForEvent('filechooser')` before that click, then `chooser.setFiles(path)`.
   - Click the Upload Files dialog's **Done** with a DOM click (`button.slds-button.ok`). A
     Playwright locator click times out on it.
   - Confirm the file name appears as a link under the upload control before Submit.
6. Show the user the exact field values and attachments. Submit only after approval.
7. After submission, record the case number (if shown) and status in a checkpoint in
   ai-memory (`working\accela-reports\tasks\`) and add its row to `working\WORKING.md`.
   Include the follow-up: when the Accela deployment email arrives, set up the report in
   ReportManager. Do not set it up before that email confirms deployment.
   - Requester update (standing instruction, 2026-10-30): if an mkesdp ticket exists for this report
     (the SDP number is usually in the commit message, the ai-memory ticket folder, or a TFS item),
     reply to the last email on that ticket (find it in Outlook with the `outlook-email` skill) saying
     a new version has been requested for deployment and will be ready tomorrow. Do this right after
     Submit. Use Reply All per the `outlook-email` skill's ITHelp rules (the reply to `itmdhelp` updates
     the ticket), with no greeting, written in the first person, for example: "I updated the report to
     <change>. A new version has been requested for deployment and will be ready tomorrow." Save it as
     a draft and show it to the user; the user sends it. If no ticket can be found, skip it and tell
     the user. Do not email Accela.
8. Check Outlook (see the `outlook-email` skill) for the Accela reply on the case. Search the Inbox
   by case number. The confirmation comes from "Accela Support" ("Report Request <case> -
   Confirmation") and the completion reply comes from the Accela support agent with the subject
   "<your subject> - <case>". Open the body: "Completed and case is closed" means deployed. The
   reply does not say which environment, so confirm it matches what was requested.
9. Once deployed, register the report in Report Manager (next section) and verify it with Preview,
   then mark the checkpoint done and remove its row from `working\WORKING.md`.

## Register the deployed report in Report Manager (Production)

A deployed `.rpt` is not runnable until it has a Report Manager entry. A new report needs the
Report Detail, Parameters and Permissions. Copy the settings from a sibling report in the same
category instead of guessing. Do not save anything the user has not approved.

Window and navigation:

1. Open a visible window with `openBrowserPage` (`forceNew: true`) to
   `https://milwaukee-prod-av.accela.com/portlets/admin/en-us/#/main/dashboard`. The user signs in
   in that window. If the user says they cannot see the window, open another with `forceNew: true`
   (the viewport is full-size and visible, and the session cookies carry over). A page marked
   "not visible" in the attachment list is not shown to the user.
2. Click `Report` then `Report Manager` with DOM clicks inside `runPlaywrightCode`. Normal clicks
   time out. `a.p-panelmenu-header-link` with text `Report`, then the anchor with text
   `Report Manager`. Wait about 15 seconds for the nested frames (`reportTree.do`, `reportDetail.do`).
   Do not navigate straight to the legacy URL (blank page).
3. The tree is Dojo. Expand `Reports by Category`, then the category (such as `DPW - Forestry`), by
   clicking the `treenode_expand_plus.gif` image inside the node (the first image is a spacer).
   Expansion can stay on `treenode_loading.gif` for 30 seconds or more, so poll instead of
   clicking again. Click a report name span (`span.dojoTreeNodeLabelTitle`) to open it.
4. `screenshotPage` lags behind the legacy frames. Before acting, read each frame's text with
   `page.frames()` and confirm the header `Report Name: <expected report>`. After a form submit, the
   result list can appear in the same frame URL (for example `reportPicker.do`), so find the frame
   by content, not only by URL. Return JSON strings from `evaluate`, not arrays.
5. The tabs are anchors with ids `#reportDetail`, `#parameters`, `#security`, `#portlets`,
   `#workFlow`. Click them with `frame.evaluate(() => document.querySelector('#parameters').click())`.

Report Detail (create): in `reportDetail.do?mode=new`, set the fields below with
`evaluate` and dispatch `input` and `change` events, then read the values back before saving.

| Field (`value(...)`) | Value |
|---|---|
| `reportName` | The Report Manager name the user gives (for example `Forestry Fee Summary`). |
| `categoryId` | The category, such as `1918` = `DPW - Forestry`. List the options first. |
| `reportType` | `56` = Crystal. |
| `reportLink` | The deployed `.rpt` file name (for example `ForestryFeeSummary.rpt`). |
| Reports 1 (`num` checkbox value `1`) | Check it when the user asks for Reports 1 (Include on Report Portlet). |
| Everything else | Leave at defaults (Default Format, no EDMS, no e-mail). |

Save with the form's `input[type=image]` Submit. After saving, the URL becomes
`reportDetail.do?module=Development&mode=edit&REPORT_ID=<id>` and the page shows "Added successfully".
Record the `REPORT_ID`. The `Parameters`, `Permissions`, `Portlets` and `Workflow` tabs appear after the save.

Parameters (`#parameters` > New `#a_new`): the form fields are `parameterName` (label), `parameterType`
(`Date`, `String`, `Number`, `Dropdown`, ...), `parameterSource` (the exact Crystal parameter name),
`parameterRequired` (`Y`), `parameterVisible` (`Y`), `defaultValue`, `parameterOrder` (10, 20, ...),
`parameterMask`. Save with `#acsubmit`; one parameter per save. Do not click `Cancel`
(`#cancel`) unless discarding.
- The `.rpt` is compressed, so the parameter names cannot be read from the file (searched ASCII and
  UTF-16). No Crystal managed runtime is installed, only `crpe32.dll`. Get the exact names from
  Crystal Designer (Field Explorer > Parameter Fields) or from the user, and prefer that over the
  draft SQL. The name must match exactly or the report will not use the date range.
- Model reports in `DPW - Forestry` use `StartDate` and `ThruDate` (Date, Required Yes, Visible Yes,
  order 10 and 20), which can differ from a ticket's draft SQL (`{?StartDate}`, `{?EndDate}`).

Permissions (`#security`): copy the sibling report's permissions. For `DPW - Forestry` reports that
is Module `Enforcement` and Module `PublicWorks`. Click `#Add_module` ("Assign Module"), click the
module node (`#stree4` = Enforcement, `#stree8` = PublicWorks), then `#acsubmit`. One module per
Assign Module. Read the Permissions list back to confirm both.

Verify with Preview (required before calling the setup done):
1. On the report's `Report Detail` tab, the **Preview** button (`#a_new`, runs `openReportPre()`) opens
   `reportShow.do?mode=show&isNewRequest=Y&reportId=<REPORT_ID>&module=Development&reportType=56&reportName=<file>.rpt&isPreview=Y&isDisplaySendEmail=N&attachContact=ATTACH_ALL_SET`
   in a popup window. A popup is not captured by `runPlaywrightCode`, so open that same URL directly
   with `openBrowserPage` (`forceNew: true`) so the user can watch. It is read-only.
2. The page "report set Parameter" shows one required field per Accela parameter. Fill each with
   `getByRole('textbox', { name: 'Select Date' }).nth(i).fill('MM/DD/YYYY')`, then click `Submit`
   (the `Submit` link by ref). Use a short recent range so it runs quickly.
3. The Crystal Reports Viewer opens at
   `https://prod-reports.accela.com/CReport_PROD/adapter/XReport.aspx?reportName=/PRODUCTION/MILWAUKEE/<file>.rpt&<Param>=...`.
   The URL carries the parameter names Accela passed. The report body is in an `about:blank` frame, so
   read each frame's `innerText` (the viewer's own frame only shows "Group Tree Main Report"). The
   viewport is narrow by default; use `page.setViewportSize` to read it.
4. Pass criteria: no error text, the expected column headers, and data rows. Then confirm the
   parameters filter: re-run by navigating the viewer URL with a different `<Param>` range (for
   example one day and a range in 2020) and compare row counts. They must change. If the viewer
   errors, prompts again, or the counts do not change, the Accela parameter names do not match the
   `.rpt`; edit them on the Parameters tab (`value(parameterSource)` must match exactly).
5. Record the result in the ai-memory checkpoint (ranges tried, row counts, any mismatch).

Also check the `Portlets` and `Workflow` tabs against the sibling report when the user asks.
Update the ai-memory checkpoint with the `REPORT_ID`, the settings, and what is unverified.

## Validation checklist

- [ ] Page is `https://success.accela.com/s/report-request` and shows **Submit a Report Request**.
- [ ] Contact Name is the intended person.
- [ ] Environment is set (Production or Staging, as the user confirmed).
- [ ] Subject and Description are both `Deploy to production and test`.
- [ ] Attachments match the committed `.rpt`.
- [ ] User approved every value before **Submit**.
- [ ] After deployment: the report has a Report Manager entry (name, category, `.rpt` link, Reports 1,
      parameters, permissions) and a Preview run returned data and changed with the date range.
- [ ] No credentials stored in this skill or in memory.

## Common mistakes

- Clicking the home-page tile and assuming it opened the form. Check the page title and URL.
- Submitting before the Environment is chosen. The form requires it.
- Forgetting the attachment. The request is for an upload, so the `.rpt` must be attached.
- Filling Staging Environment when the request is for production (or the reverse).
- Changing the Subject or Description from `Deploy to production and test`. The Environment
  picklist allows one value per case; set it to Production, as in case 01579340, and let the
  Subject and Description carry the "and test" request. Do not file a separate Staging case
  unless the user asks.
- Leaving Account Name blank without telling the user. On the 2026-10-28 form the field was
  missing; confirm with the user before submitting.
