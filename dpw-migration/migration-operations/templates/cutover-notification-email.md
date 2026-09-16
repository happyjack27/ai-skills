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

## Alternative: asking the app owner to pick the cutover window

Use this version when writing to the business owner/lead of a self-contained app (rather than a
broad user list) — it spells out the technical steps and asks them to propose the least
disruptive day/time, instead of the team announcing a fixed window. Good fit for the last app or
two in a batch, once the earlier apps have already proven the sync/lock/sync/flip sequence works.

```text
Subject: Scheduling the {{APP_1}} / {{APP_2}} database cutover

{{RECIPIENT_NAME}},

On that note - we're in the process of migrating apps from our Oracle database over to MS SQL,
starting with the more self-contained apps. So far I've moved over {{PRIOR_APP_1}},
{{PRIOR_APP_2}}, and {{PRIOR_APP_3}}.

{{APP_1}} and {{APP_2}} look like good candidates for the next batch - they're pretty
self-contained, so the cutover should only require a little bit of downtime. The plan would be:

1. Sync the tables from Oracle to MS SQL
2. Lock the tables in the old (Oracle) database
3. Sync the tables one more time to catch anything that changed in between
4. Flip the switch on the server so it translates to MS SQL instead of Oracle

On the {{APP_1}} side, the only impact would be having staff restart their apps after the
switch, then run through a quick test to confirm everything's working as expected before going
back to normal use.

Could you let me know what a good day and time would be to schedule this? I'd like to pick a
window that minimizes disruption on your end.

Thanks,
{{SENDER_NAME}}
```

### Fill-in notes

| Placeholder | Notes |
|---|---|
| `{{RECIPIENT_NAME}}` | The app's business owner, not a broad distribution list |
| `{{PRIOR_APP_1..3}}` | Apps already cut over in earlier batches — builds confidence this is routine |
| `{{APP_1}}` / `{{APP_2}}` | The apps in this batch; keep to genuinely self-contained ones |
| `{{SENDER_NAME}}` | The single point of contact for post-cutover issues |

The 4-step plan (sync → lock → sync again → flip) maps directly onto this skill's workflow:
`syncTable`/`syncDatabase` for steps 1 and 3, `MIGRATIONS.BLOCK_PKG.FREEZE_DB` for step 2, and the
servlet/RMI routing flag change (see
[`../references/servlet-routing.md`](../references/servlet-routing.md)) for step 4. Don't run
step 2 (freeze) until the `V_STILL_WRITING` audit from
[the main workflow](../SKILL.md#freezing-oracle-after-cutover) comes back empty.
