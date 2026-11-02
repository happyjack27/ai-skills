---
name: enotify-send
description: 'City of Milwaukee legacy E-Notify: preparing and sending a manual E-Notification to a subscriber category (for example "Employee Email Accounts") from itmdapps.milwaukee.gov/Enotify/admin/send-enotification.jsp. Covers how send rights work (Oracle EUSER_INFO, Portal login), finding what was sent last time, filling the form with an image in the body plus a PDF attachment, the Send to creator test, verifying headers, and the Outlook image-blocking and sizing pitfalls. Keywords: enotify, E-Notify, e-notification, popcorn, Employee Email Accounts, send-enotification, ENOTIFY_NOTIFIER_CATEGORIES.'
---

# Sending a legacy E-Notify

## Purpose

Prepare and send a one-off E-Notify to a subscriber category from the legacy
Enotify admin page, with the right send rights, a tested message, and the
image and attachment arriving as the requester expects.

## Scope

- Included: finding the last send, checking and requesting send rights, filling
  the form, a creator test, header verification, and recording progress.
- Excluded: sending to subscribers without the user's explicit go-ahead (one
  send reaches thousands of employees); granting send rights on the user's behalf
  with credentials you were not given; editing the Enotify or EnotifyAdmin code.

## Two apps, two permission stores

Do not mix these up.

| App | URL path | Sign-in | Send list comes from |
|---|---|---|---|
| Legacy Enotify (use this) | `/Enotify/admin/send-enotification.jsp` | Portal login (email and password) | Oracle `EUSER_INFO.ENOTIFY_NOTIFIER_CATEGORIES` (USER_ID, CATEGORY_ID) |
| EnotifyAdmin | `/EnotifyAdmin/...` | AD login | SQL Server `Enotify` DB `admin.SubscribablePermission` through `admin.VW_SubscribablePermission` |

- EnotifyAdmin pages redirect to a report page when the user has no SQL Server
  permission row. That is not the legacy send page.
- Source: `eclipse-workspace\Enotify` (legacy) and `eclipse-workspace\EnotifyAdmin`.
  `UtilDB.getSendableEmailCategoriesByUserId(userId)` reads the Oracle grants.

## Read-only lookups

Route: SQL Server `SQL-DEV`, database `Enotify`, Windows authentication, then the
linked server `CORPDB` (Oracle owner `EUSER_INFO`) with `OPENQUERY(CORPDB, '...')`.
Double any single quotes inside the Oracle text. The linked-server login is
read-only: an INSERT fails with ORA-01031.

- Last send: `ENOTIFY_NOTIFICATIONS` keeps the sender, time, category, recipient
  count, and subject only. It does not keep the body or attachment. Find the body
  and attachment in the received copy in Outlook (inbox, sender
  `Milwaukee.E-Notify@enotify.milwaukee.gov`).
- User's Portal ID: `PORTAL_USER` (look up by `NAME` or `USER_ID`; the username
  column is not reliable).
- Category IDs are numeric in Oracle. SQL Server category IDs are GUIDs.

## Send rights

1. Look up the Portal USER_ID and the category ID the last send used.
2. Check for an existing row in `ENOTIFY_NOTIFIER_CATEGORIES`.
3. If missing, the owner or someone with Oracle write rights runs one INSERT and
   COMMIT for that user and that category only. Do not copy another person's
   full grant list. Give the user the SQL to run when the linked server cannot
   write.
4. Sign in to the legacy page with the Portal account. Never type or store the
   user's password.

## Filling the form

Fields on the page: `header`, `subject`, `msg` (CKEditor), `attachment` (file
input `#inp_attachment`, uploads on change), hidden `category` (locked to the
user's single category), buttons `#btn_sendToCreator` and
`#btn_sendToSubscribers`.

- Header: blank gives the default "You have a Milwaukee.Gov E-Notification for
  <category>". A value replaces that line. Match the last send's layout: the
  bold, underlined, centered title went in the message body.
- Image in the body: use an `<img>` that points at a file on
  `staticwebfiles.milwaukee.gov`. The form cannot embed an inline image. Confirm the
  link loads and note the pixel size.
- PDF: set the file input, then confirm "Successfully uploaded ..." and the hidden
  `attachment` field.

### Image size pitfall

Outlook's Word-based renderer ignores CSS `width` and `max-width`. A full-size
flyer then shows huge in forwards and replies. Use `width` and `height`
attributes on the tag, keeping the aspect ratio (for example 2550x3941 at width
800 is height 1236), plus `style="height:auto; max-width:100%"` for other
clients. CKEditor removes these attributes when it cleans the HTML. Work around it
by overriding the editor's output for the page session:

- Set the attributes in the raw HTML, then replace `CKEDITOR.instances.msg.getData`
  and `.updateElement` so they return and write that raw string to the `#msg`
  textarea. Read the textarea back to confirm the attributes are present.

### Image blocked pitfall

Outlook blocks external pictures in the reading pane by default, so a remote
`<img>` looks missing until the user chooses "download pictures". The compose
window and forwards show it. This is expected. Keep the PDF attached and say so.

## Test, then send

- "Send to creator" sends only to the signed-in user's email. Each click submits the
  form three times (the click handler in `send-enotification.jsp` calls submit
  three times), so expect three copies. "Send to subscribers" submits once.
  To get one copy, rebind the button for the page session before the user clicks:
  `$('#btn_sendToCreator').off('click').on('click', function(){ $('#submit_type').val('creator'); $('#emailForm')[0].submit(); })`.
  Reloading the page loses this, so redo it after any reload. The permanent fix is
  to delete the duplicate `submit()` calls in the handler and deploy it.
- The creator copy also carries `ATT00001.txt`. This is the mail library's debug
  report (`MailUtil` debug mode): the TO, CC, and BCC lists the real send would
  use. It is not in a real subscriber send.
- Verify the test: open the received copy, read the transport headers
  (`PR_TRANSPORT_MESSAGE_HEADERS`, property tag `0x007D001E`) and confirm `To:` is
  only the user, with no `Cc:` or `Bcc:`, and that the image tag and PDF are present.
- Leave the real send button for the user, or press it only on an explicit go-ahead
  for that send. The page's jQuery `submit()` is swallowed by the form validator
  (a code comment says so), so bind the subscriber button to one native submit with
  a once-only guard before clicking:
  `window.__subSent=false; $('#btn_sendToSubscribers').off('click').on('click', function(){ if(window.__subSent){return;} window.__subSent=true; $('#submit_type').val('subscribers'); $('#emailForm')[0].submit(); })`.
  Verify the form first (category, subject, `#msg` textarea, hidden `attachment`).
- Confirm one send: `ENOTIFY_NOTIFICATIONS` (read through `OPENQUERY(CORPDB, ...)` with
  `SELECT *`; columns are ID, CATEGORY_ID, SENT_BY, SENT_DATE, MSG_DETAIL, NUM_SENT)
  should show exactly one new row with the expected recipient count.
- For recurring sends (for example Monday, Wednesday, and Friday), each send is a
  separate manual action. Record each one in the working checkpoint.

## Record keeping

- Track the request in the ai-memory working checkpoint for the mkesdp number.
- Delete temporary copies of attachments from `%TEMP%` after the last send.
