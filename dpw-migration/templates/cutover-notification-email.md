# Cutover Notification Email Template

Send this to the main users of an app (or set of apps) before repointing it from Oracle to SQL
Server. Get the recipient list from the "Building a notification list for a set of apps" query
in [`../references/database-migration-db.md`](../references/database-migration-db.md).

If the apps in one cutover batch have different, non-overlapping user groups, send separate
emails so each group only has to answer for its own apps.

## Template

```text
Subject: Upcoming database change for {{APP_NAMES}}

We are moving the DPW Apps data from our Oracle database to a Microsoft SQL Server database.
The following applications will be switched over to the new database:

- {{APP_1}}
- {{APP_2}}
- {{APP_3}}

At cutover we will copy the current data from Oracle into SQL Server, so all existing records
come along — nothing is lost. After the switch the applications will look and work exactly the
same. Only the location where the data is stored is changing. There is nothing to install, and
you will log in the same way you do today.

The cutover itself is quick. I just need everyone to log out of these applications and stay out
until I let you know it's done, so no entries are made while the data is being copied.

What time would work best for your group? Let me know a day and time that's least disruptive,
by {{REPLY_BY_DATE}}, and I'll schedule it then.

If anything looks off after the switch, contact me directly and I'll take care of it.

{{SENDER_NAME}}
```

## Fill-in notes

| Placeholder | Notes |
|---|---|
| `{{APP_NAMES}}` | Short form for the subject line, e.g. "StreetSigns, RestrictedStreets, Alleys, AlleysSS" |
| `{{APP_1..N}}` | One line per app in the batch |
| `{{REPLY_BY_DATE}}` | Always include one — open-ended "let me know" gets few replies |
| `{{SENDER_NAME}}` | The single point of contact for post-cutover issues |
