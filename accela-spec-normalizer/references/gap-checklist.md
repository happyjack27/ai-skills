# Gap checklist

Run every item against the normalized tables. Each is here because a production spec
failed it. For each failure, write a numbered question the analyst can answer without
re-reading their own document.

## Routing

1. **Every status has a next task or is explicitly terminal.** Dangling statuses mean a
   record that can never close. Look for statuses listed with no consequence at all —
   these are the easiest to miss because they read as complete bullets. Record
   disposition itself is derived from this (`Closed` only if the source says so,
   `In Progress` otherwise) — don't ask the analyst a separate question about it.
2. **Every scheduled inspection has a no-result path.** Specs describe what happens when
   an inspection is resulted and are silent on the one that never gets resulted.
3. **Every child-record spawn names a next task for the parent, if one exists.**
   Disposition rarely needs asking here — `In Progress` by default unless the source
   explicitly closes the parent — but which task (if any) owns the parent afterward can
   still be a genuine gap.
4. **Every task has at least one inbound and one outbound transition** unless it is the
   start or a terminal.

## Time

5. **Every offset names calendar or business days.** Never assume.
6. **Every offset names its anchor** — with one default: a Table A scheduling offset
   (e.g. "schedule reinspection in 5 days") defaults to the triggering inspection's
   result date if unstated. Everywhere else — fee timers, batch windows — there is no
   default. "Within 37 days" of the invoice date and of the status change are different
   rules producing different money, and neither can be assumed.
7. **Every elapsed-time rule is marked batch, not event.** If Table C says `Event` for
   anything time-based, that is wrong and worth flagging directly.

## Money

8. **Every fee names its tier basis field and the record that field lives on.**
9. **Fee tiers are exhaustive.** Check every result value that leads to a fee has a tier.
   Watch for variant results — a spec that adds an "Immediate" version of a result to
   change scheduling usually forgets to say whether it shares the original's fee tier.
10. **Invoice timing is stated** for every fee — added and invoiced together, or added
    now and invoiced later.
11. **Every late or penalty fee states amount, threshold, and clock start.**

## Automation

12. **Every "automatic" declares event or batch.**
13. **Every dedupe or lookup rule names its match key and window anchor.**
14. **Every notification names a role or user group and a channel.** "Notify supervisor"
    is not implementable.
15. **Cascading task updates are identified** wherever a script updates a workflow task
    from inside another event.

## Configuration

16. **The four-level record type is given** — group, type, subtype, category.
17. **Inspection group is named** and contains every inspection type in Table A.
18. **Every ASI field referenced has its group and full value list**, not just the one
    value the spec happens to mention.
19. **Every child record type named actually exists** or is flagged as also-to-be-built.
