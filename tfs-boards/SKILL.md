---
name: tfs-boards
description: 'Use for the City of Milwaukee "Internal Systems Projects" TFS/Azure DevOps Server board at tfs.milwaukee.gov: querying assigned/open work items (WIQL), creating or updating Product Backlog Items/Tasks/Bugs, moving cards between Kanban board columns, adding comments, and any REST API automation against this on-prem TFS instance. Also use when asked to check "my board", "my tasks", "the sprint", or update ticket status.'
---

# TFS Boards Skill — Internal Systems Projects (tfs.milwaukee.gov)

## Purpose

Help an AI query and update the City of Milwaukee "Internal Systems Projects" board on the
on-prem TFS/Azure DevOps Server instance at `tfs.milwaukee.gov`, without rediscovering auth,
project/team ids, or API quirks each time.

## Scope

- **In scope:** WIQL queries, work item CRUD (Product Backlog Item / Task / Bug), Kanban board
  column/state changes, comments, on this one project/team.
- **Out of scope:** other TFS collections/projects (would need their own ids/facts verified the
  same way — don't assume they share this project's team/board GUIDs or process template),
  build/release pipelines, Git repos hosted in the same collection.

## When to Use

- "What's on my board?" / "What am I assigned right now?"
- Creating a new Task/Bug/PBI from a reported issue or a piece of work just finished.
- Moving a card ("mark this Done", "move it to Committed").
- Adding a status comment to an existing work item.
- Any ad hoc REST call against `tfs.milwaukee.gov` this skill doesn't already wrap.

## Inputs Expected

| Input | Description |
|---|---|
| Work item id | Numeric TFS id, e.g. `423` |
| Work item type | `Product Backlog Item`, `Task`, or `Bug` |
| Target state | Must be a legal state for that type — see `references/api-reference.md` |
| Field values | Title, description, assignee, comment text, etc. — assignee defaults to the user (`AD\kbaas`) for anything newly created |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Query results | PowerShell objects | Work item ids/fields from a WIQL query |
| Create/update confirmation | PowerShell object | The REST response for the created/patched item |

## Environment

Reference: [`references/api-reference.md`](references/api-reference.md) — collection/project/team/
board ids, auth method, API version quirks (including the comments-endpoint preview-version
gotcha), work item states, board-column-vs-state field mapping, and JSON Patch examples.

The essentials:

| Fact | Value |
|---|---|
| Auth | Windows Integrated — current AD session, **no PAT**. `-UseDefaultCredentials` |
| Collection | `https://tfs.milwaukee.gov/ApplicationAndDevelopment` |
| Project | `Internal Systems Projects` |
| Process template | Scrum |
| Helper script | [`scripts/tfs-boards.ps1`](scripts/tfs-boards.ps1) — dot-source it first |

## Workflow

### Answering "what's on my board / what am I assigned"

1. `. scripts/tfs-boards.ps1`
2. `Invoke-TfsWiql` with `[System.AssignedTo] = @Me AND [System.State] <> 'Closed'` (or filter by
   `[System.IterationPath]`/`[System.State]` for a specific sprint/column).
3. Batch-fetch fields for the returned ids (see reference doc — cheaper than one call per id).

### Creating a work item

1. Confirm the work item type (`Task` for small execution work, `Bug` for a defect, `Product
   Backlog Item` for a larger deliverable) — ask if ambiguous.
2. `New-TfsWorkItem -Type ... -Fields @{ "System.Title" = ...; "System.Description" = ...;
   "System.AssignedTo" = "AD\kbaas" }` — **always assign new items to the user** (`AD\kbaas` /
   "Baas, Kevin") unless explicitly told to assign someone/something else. Don't leave new items
   unassigned by default.
   Pass `-ParentId <id>` to link it under a PBI/Feature — `System.Parent` as a plain field does
   NOT work, see reference doc.
3. **Keep the description short and plain, like a quick note a person jotted down** — one or two
   sentences of what needs doing and where, not a structured writeup of findings/analysis. Don't
   let it read as AI-generated (no bullet-itemized breakdowns, no "confirmed via X" phrasing) —
   the board is for humans tracking work, not a place to dump research output.
4. If it needs to show on a sprint taskboard, explicitly set `System.IterationPath` — new items
   default to the project root, not the current sprint or the parent's iteration.
5. Report back the new id and a link: `{collection}/{project}/_workitems/edit/{id}`.

### Moving a card / changing state

1. Check the type's legal states in `references/api-reference.md` (or
   `wit/workitemtypes/{type}/states`) — don't guess a transition.
2. `Update-TfsWorkItemFields -Id ... -Fields @{ "System.State" = "Committed" }` — this alone moves
   the board column too when columns map 1:1 to states (verify with `Get-TfsTeamBoardColumns` if
   unsure for a given team).

### Adding a comment

1. `Add-TfsWorkItemComment -Id ... -Text ...` — uses the dedicated comments endpoint (needs the
   `6.0-preview.3` api-version on this server, already baked into the helper).

### Deleting a work item

1. Default to `Remove-TfsWorkItem -Id ...` (soft delete — recycle bin, recoverable). Only use
   `-Destroy` (permanent) if the user explicitly asks for it.

### Live-testing write operations with a human in the loop

When validating create/update/comment functions against the real board (not just reading):
- Propose the exact call (function + args) and get explicit confirmation before running it.
- After running it, stop and wait for the user's explicit "confirmed"/"verified" — do **not**
  propose the next step in the same message as the verification request. Asking "please verify"
  and immediately describing step N+1 reads as not actually waiting for an answer.
- Only after that confirmation, propose the next step.
- Document any new gotcha discovered immediately (this file / reference doc), before moving on —
  that's the whole point of testing against the real system instead of guessing.

## Quality Standards

- Verify a work item's current state/type before attempting a state change — an illegal
  transition 400s with a specific error, don't guess-and-retry blindly.
- Don't assume another team/board on this same project shares the "columns map 1:1 to states"
  simplification — confirm with `Get-TfsTeamBoardColumns` first if working with an unfamiliar team.
- Prefer the batch `wit/workitems?ids=...` fetch over one `Get-TfsWorkItem` call per id when
  handling a list from a WIQL query.

## Common Mistakes

- Assuming a PAT is required — it isn't, on this on-prem instance with Windows auth enabled.
- Calling the comments endpoint with the core `6.0` api-version — it 404s; needs `6.0-preview.3`.
- Sending update bodies as a plain JSON object instead of a JSON Patch array — Azure DevOps work
  item create/update always expects `application/json-patch+json` with `{op, path, value}` entries.
- **Single-field JSON Patch calls silently 400** unless the request body is forced to stay a JSON
  array (`ConvertTo-Json -AsArray`) — PowerShell un-arrays a 1-element array by default. Test the
  1-field case explicitly, not just multi-field.
- Setting `System.Parent` as a plain field to link a child to a PBI — it's silently ignored; parent
  links need a `relations` patch op (`New-TfsWorkItem -ParentId`).
- Forgetting to set `System.IterationPath` on a new item — it defaults to the project root, so it
  won't show on any sprint taskboard until explicitly moved into the current sprint (check with
  `$timeframe=current`, don't assume the parent's iteration is the current one).
- Creating throwaway/test work items directly on the real board without confirming with the user
  first — when testing, confirm the exact payload before each write, and agree on cleanup
  (state → Removed, or destroy) up front.
- **Setting `System.State` to a non-default value (e.g. `"In Progress"`) in the same call as
  `New-TfsWorkItem`** — creation only allows the type's initial state; passing anything else 400s
  with `RuleValidationException: ... not in the list of supported values`. Create the item first
  (state defaults to `New`/`To Do`), then call `Update-TfsWorkItemFields` to transition it.

## Validation Checklist

- [ ] Confirmed the work item type's legal states before changing `System.State`.
- [ ] Used the batch id-list fetch for multi-item WIQL results, not N individual calls.
- [ ] Reported back a direct link (`_workitems/edit/{id}`) after creating/updating an item.
- [ ] Set `System.IterationPath` explicitly if the item needs to appear on a sprint taskboard.
- [ ] Used `-ParentId` (relations op), not a `System.Parent` field, for parent/child links.

## Related Skills

- [`../powershell/SKILL.md`](../powershell/SKILL.md) — general PowerShell/cmdlet conventions.
