---
name: citytime-time-entry-check
description: 'Use to verify that a City of Milwaukee DPW employee''s CityTime time tickets (DTICKET) are entered for the current or a given pay period in the live DPWP Oracle database. Read-only check of TANDL.DTICKET by EMPLID, reporting which days are covered, hours, approval status, and gaps. Trigger on "is my time entered", "check my dticket", "did my time go in", "missing time tickets", "CityTime entry check", or "verify my CityTime".'
---

# CityTime Time Entry Check

## Purpose

Confirm that one employee's CityTime time tickets were saved to the DPW Oracle CityTime schema
(`TANDL.DTICKET` in the `DPWP` database) for a pay period, and report what is missing. This is a
read-only verification. It does not enter, edit, approve, or delete time.

## Inputs

Collect these before querying. If the user does not provide them, ask once; do not guess.

| Input | Required | Notes |
|---|---|---|
| `EMPLID` | yes | Employee ID (`TANDL.DTICKET.EMPLID`). Ask the user. |
| Pay period | no | Defaults to the current period from `TANDL.DKDATES`. Accept `pp` and `year` if given. |
| Crew `GROUP_ID` | no | Only needed to check crew-wide entry. |

## Where the data lives

- Database: `DPWP` (Oracle). Schema `TANDL`. Pay-period calendar: `TANDL.DKDATES`
  (`pp`, `year`, `sdate`, `edate`; no `pay_end_dt` column). Holidays: `dpw.holidays` (`sdate`, `h_name`).
- Ticket table `TANDL.DTICKET`, columns used here: `emplid`, `name`, `group_id`, `date_worked`,
  `hours_rptd`, `erncd`, `jobcode`, `union_cd`, `shift_id`, `acct_cd`, `pp`, `tyear`,
  `pay_end_dt`, `ok`, `ok2`, `batch_num`.
- Approval convention (from `getTicketCountRpt` in `DPW_Citytime/src/CTPanelReports.java`):
  a ticket is **approved** when `ok != '-1'` and `ok2 != '-1'`; **un-approved** when either is
  `'-1'`. A row existing at all means the time was entered.
- Late loads: `pp` and `pay_end_dt` are the period a ticket was loaded into, which can be later
  than the period containing `date_worked`. Overtime loaded late appears under a later `pp`, so
  check both (Query 2).
- `SDATE` on `DTICKET` is the load timestamp, not the work date. `ENTERED_ON` is often blank on
  late rows; do not rely on it.

## Workflow

1. **Resolve the pay period.** Run Query 1 and use the row where today falls between `sdate` and
   `edate + 1`. If the user names a period, use that `pp` and `year` instead.
2. **Pull the employee's tickets.** Run Query 2 with `:emplid`, `:pp`, `:year`, `:sdate`, `:edate`.
3. **Summarize** for the user:
   - Period (`pp`, `year`, `sdate` to `edate`).
   - Ticket count, total `hours_rptd`, approved count, un-approved count.
   - Weekdays in the period with **no** ticket, excluding dates from Query 4. Flag these as possibly
     missing. The employee's actual schedule decides whether a given weekday should have time.
   - Tickets whose `pp` is this period but whose `date_worked` falls outside it (late loads).
4. **Interpret carefully.** An un-approved ticket is entered but not yet approved. If no rows come
   back, verify the `emplid` with Query 3 before concluding time is missing.
5. **Do not write.** Never run `INSERT`, `UPDATE`, or `DELETE` against `TANDL.DTICKET` or
   `HIST.DTICKET` for this check. The CityTime app's delete and batch-number update statements
   (`CTPanelPoliceOT.java`, `CTPanelEditDelete.java`) are not part of this skill.

## Queries

Run as read-only `SELECT` statements. In the SQL Developer `dpwp` connection, bind the
`:emplid`, `:pp`, `:year`, `:sdate`, and `:edate` variables.

**Query 1: pay period containing today**

```sql
select pp, year, sdate, edate
  from tandl.dkdates
 where sdate <= trunc(sysdate)
   and edate + 1 > trunc(sysdate)
 order by year, pp;
```

**Query 2: the employee's tickets for the period (loaded into this period, or work dated in it)**

```sql
select emplid, name, group_id, date_worked, hours_rptd, erncd, jobcode,
       union_cd, shift_id, acct_cd, pp, tyear, pay_end_dt, ok, ok2
  from tandl.dticket
 where emplid = :emplid
   and tyear = :year
   and (pp = :pp or (date_worked >= :sdate and date_worked <= :edate))
 order by date_worked;
```

**Query 3: confirm the employee ID and name on file**

```sql
select distinct emplid, name, group_id
  from tandl.dticket
 where emplid = :emplid
   and rownum <= 5;
```

If the user does not know the ID, search by name, but always add a `tyear` filter:
`where name like '%LASTNAME%' and tyear = :year`.

**Query 4: holidays in the period, to exclude from the weekday check**

```sql
select sdate, h_name
  from dpw.holidays
 where sdate between :sdate and :edate
 order by sdate;
```

## Running from the command line (SQLcl)

The Oracle SQL Developer VS Code extension bundles SQLcl at
`%USERPROFILE%\.vscode\extensions\oracle.sql-developer-*\dbtools\sqlcl\bin\sql.exe`.
Use it with the saved `dpwp` connection name. SQLcl prompts for the password if it is not
available to it; never write the password into a file, command line, or the skill.

```powershell
& (Get-ChildItem "$env:USERPROFILE\.vscode\extensions\oracle.sql-developer-*\dbtools\sqlcl\bin\sql.exe" | Select-Object -Last 1).FullName /nolog
```

Then at the `SQL>` prompt, connect with the user's own login (`connect <user>@dpwp`), set bind
variables (`var emplid varchar2(20)`, `exec :emplid := '<EMPLID>'`), and run the SELECT queries
above. Use `SET SQLFORMAT ansiconsole` for readable output.

## Fallback: SQL Server linked server

If the SQL Developer `dpwp` connection is unavailable, query through the `sql-treas` linked server
(`OPENQUERY(DPWP, ...)`), doubling every single quote inside the Oracle statement:

```sql
select *
  from openquery(DPWP, 'select emplid, date_worked, hours_rptd, pp, tyear, ok, ok2
                          from tandl.dticket
                         where emplid = ''<EMPLID>'' and tyear = <YEAR>
                           and date_worked >= date ''<SDATE>'' and date_worked <= date ''<EDATE>''');
```

Substitute real values only after the user supplies them.

## Guardrails

- Read-only. `SELECT` only; never run data-changing statements against CityTime.
- Use the employee's `EMPLID` only as needed for this check. Do not copy results into
  repositories, memory, or shared documents.
- Do not store credentials or connection strings in this skill.
- CityTime data is production. Keep results scoped to one employee and one pay period.

## Related

- [workday-citytime-integration](../../citytime-workday/workday-citytime-integration/SKILL.md): data
  contract and the Workday CSV transfer program (`DTICKET_<year>_<pp>.csv` export).
- `DPW_Citytime/src/CTPanelReports.java`: source of the status and period queries above.
