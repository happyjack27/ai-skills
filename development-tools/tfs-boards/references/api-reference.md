# TFS/Azure DevOps Server REST API reference — Internal Systems Projects

Verified live against `tfs.milwaukee.gov` on 2026-08-05. All examples use the helper functions in
[`../scripts/tfs-boards.ps1`](../scripts/tfs-boards.ps1); the raw endpoint shapes are documented
here for when a helper doesn't cover a case.

## Environment facts

| Fact | Value |
|---|---|
| Collection URL | `https://tfs.milwaukee.gov/ApplicationAndDevelopment` |
| Project | `Internal Systems Projects` (must be URL-escaped: `Internal%20Systems%20Projects`) |
| Team | `Internal Systems Projects Team` — id `8d2b6fde-f3c1-42e0-a5c2-e39a83987031` |
| Boards | `Backlog items` `abe2e31f-98f1-42d5-81c2-4e90d7746012`, `Features` `99e564b9-b8ff-4c61-b583-3a5602a5a494`, `Epics` `7e14c95a-38b9-4081-ad9f-48bb0512916b` |
| Process template | Scrum (work item types: `Product Backlog Item`, `Task`, `Bug`, `Feature`, `Epic`) |
| Auth | Windows Integrated (current AD session) — **no PAT needed**. `Invoke-RestMethod -UseDefaultCredentials` works directly; confirmed against `wit/wiql`, `wit/workitems`, `wit/workitemtypes/*/states`, `work/boards`, `wit/workItems/{id}/comments` |
| Core API version | `6.0` (this is an on-prem Azure DevOps Server, roughly 2020-vintage) |
| Comments API version | `6.0-preview.3` — the plain `wit/workItems/{id}/comments` endpoint 404s without the `-preview.N` suffix on this server; core `wit/*` endpoints do NOT need a preview suffix |

**Do not assume a PAT is required** just because most Azure DevOps documentation defaults to PAT
examples — on-prem TFS/Azure DevOps Server with Windows auth enabled accepts the calling user's
current Windows session with zero extra setup. If `-UseDefaultCredentials` ever starts failing
with 401, that's a real auth/config change worth investigating, not an expected requirement.

## Work item states (Scrum process template, this project)

| Work item type | States (category) |
|---|---|
| `Product Backlog Item` | New (Proposed) → Approved (Proposed) → Committed (InProgress) → Done (Completed); Removed |
| `Bug` | New (Proposed) → Approved (Proposed) → Committed (InProgress) → Done (Completed); Removed |
| `Task` | To Do (Proposed) → In Progress (InProgress) → Done (Completed); Removed |

Fetch any other type's states with:
```powershell
Invoke-TfsApi -RelativeUri "wit/workitemtypes/$([uri]::EscapeDataString($Type))/states"
```

## Board columns

For the `Backlog items` board, columns map 1:1 onto `Product Backlog Item`/`Bug` states — `New`,
`Approved`, `Committed`, `Done` — with `Approved`/`Committed` set to `inProgress` type and WIP
limit 5. **Don't assume this 1:1 mapping holds on every team/board** — Kanban columns are a
separate configuration from states and can be renamed/split per team; always call
`Get-TfsTeamBoardColumns` to confirm before writing code that maps a column name to a state name.

A work item carries its board position in **two places** that must be kept in sync:
- `System.BoardColumn` / `System.BoardColumnDone` — the "current" board fields.
- `WEF_<extensionGuid>_Kanban.Column` / `WEF_<extensionGuid>_Kanban.Column.Done` — a
  per-team-configuration mirror field with a GUID specific to that team's board settings.

**In practice, when columns map 1:1 to states (as they do here), just update `System.State` and
both board-column fields update automatically** — there is no need to PATCH `System.BoardColumn`
or the `WEF_...` field directly. Only touch the board-column fields directly if a team's board
has multiple columns mapped to the same state (split columns), which isn't the case here.

**This `System.BoardColumn`/`WEF_...Kanban.Column` mechanism is Kanban-board-specific (PBI, Bug,
Feature, Epic) — `Task` work items carry NEITHER field at all** (confirmed: no key matching
`Board|Kanban` exists on a Task's field set). Tasks live on the **Sprint Taskboard**, not a Kanban
board, and that view buckets purely by `System.State` — updating state alone is correct and
sufficient for moving a Task, there's no separate board-column field to worry about.

## WIQL queries

```powershell
Invoke-TfsWiql "SELECT [System.Id],[System.Title],[System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Closed' ORDER BY [System.ChangedDate] DESC"
```

Returns only `{id, url}` pairs (`.workItems`) — WIQL never returns field values directly. Batch-fetch
the actual fields for a set of ids with:
```powershell
$ids = (Invoke-TfsWiql $query).workItems.id -join ','
Invoke-TfsApi -RelativeUri "wit/workitems?ids=$ids&`$expand=all"
```
(cheaper than calling `Get-TfsWorkItem` once per id).

Useful WIQL fields for this project: `[System.AreaPath]`, `[System.IterationPath]` (sprints are
named by date, e.g. `Internal Systems Projects\08-03-2026`), `[System.AssignedTo]`, `[System.Tags]`.

## Creating / updating work items (JSON Patch)

Both create and update use `application/json-patch+json` — an array of `{op, path, value}`
operations, **not** a plain JSON object of fields. `New-TfsWorkItem`/`Update-TfsWorkItemFields`
build this array from a hashtable automatically.

```powershell
New-TfsWorkItem -Type "Task" -Fields @{
    "System.Title"       = "Fix webapp01 mail relay"
    "System.Description" = "<div>Details...</div>"
    "System.AssignedTo"  = "AD\kbaas"
}

Update-TfsWorkItemFields -Id 423 -Fields @{ "System.State" = "Committed" }

Add-TfsWorkItemComment -Id 423 -Text "Deployed to sql-treas, verifying now."
```

Notes (standard Azure DevOps REST behavior, not project-specific):
- `op = "add"` works for both setting a new field and overwriting an existing one — Azure DevOps
  doesn't require `"replace"` for fields that already have a value.
- Setting `System.State` to a value that isn't a valid transition from the current state (per the
  workflow state machine) returns a 400 with a descriptive error — check
  `wit/workitemtypes/{type}/states` first if unsure which transitions are legal.
- `System.AssignedTo` accepts `AD\username`, a display name, or an email-style unique name — the
  server resolves it against the identity service; an unresolvable value 400s.
- `New-TfsWorkItem`, `Update-TfsWorkItemFields` (single- and multi-field), parent-linked create,
  and `Add-TfsWorkItemComment` have all been live-tested against this server (2026-08-05, work
  item #513) — every function in this file is now verified, not just documented.

### Gotcha: PowerShell silently breaks single-field JSON Patch bodies

`ConvertTo-Json` **un-arrays a single-element array by default**: `@(@{a=1}) | ConvertTo-Json`
produces `{"a":1}`, not `[{"a":1}]`. Since a JSON Patch body must always be an array — even with
one op — a single-field `Update-TfsWorkItemFields` call used to fail with
`VssPropertyValidationException: You must pass a valid patch document in the body of the request`.
Fixed in `Invoke-TfsApi` by using `ConvertTo-Json -AsArray` whenever `$Body` is a PowerShell array
(PS 6.2+). Multi-field calls happened to work before the fix (2+ elements stay an array), which is
why this wasn't caught until a single-field update was tried — **always test the 1-field case**,
not just the multi-field case, when touching JSON Patch code.

### Gotcha: parent/child links are NOT a plain field

`System.Parent` in the `-Fields` hashtable does **not** create a parent/child link — Azure DevOps
links are a separate `relations` patch op:
```json
{ "op": "add", "path": "/relations/-", "value": { "rel": "System.LinkTypes.Hierarchy-Reverse", "url": "{collection}/_apis/wit/workItems/{parentId}" } }
```
`New-TfsWorkItem -ParentId <id>` wraps this. `Hierarchy-Reverse` = "this item's parent is...";
use `Hierarchy-Forward` if ever setting a child link from the parent's side instead.

### Gotcha: new work items default to the project root iteration, not any sprint

A newly created item's `System.IterationPath` defaults to the bare project path
(`Internal Systems Projects`), **not** its parent's iteration and **not** the current sprint — it
won't appear on any team's sprint taskboard until `System.IterationPath` is set explicitly. Find
the current sprint with:
```powershell
Invoke-TfsApi -RelativeUri "work/teamsettings/iterations?`$timeframe=current" -TeamId $teamId
```
A parent PBI being in an older sprint (e.g. `07-20-2026`) does not mean that's the *current* one —
check `$timeframe=current` rather than copying the parent's iteration blindly.

## Deleting work items

```powershell
Remove-TfsWorkItem -Id 513              # soft delete - recycle bin, recoverable
Remove-TfsWorkItem -Id 513 -Destroy     # permanent, NOT recoverable
```
Uses `DELETE wit/workitems/{id}` (add `?destroy=true` for permanent). Live-tested (2026-08-05,
#513, soft delete): returns 200 with `deletedDate`/`deletedBy` and the full field snapshot under
`.resource`, item disappears from boards/taskboards immediately. `-Destroy` not live-tested — no
need found yet; soft delete + recycle bin is the safer default for any test/cleanup work.

## Card type / color quick reference

Board card color is a visual cue for work item type, not something to infer state from:
- Product Backlog Item — cyan/blue ribbon (this is what "the blue card" means on this board).
- Task — yellow/gold ribbon.
- Bug — red/orange ribbon.

**Tasks have no board-column field at all** (`System.BoardColumn` / `WEF_...Kanban.Column` are
absent from a Task's field set) — the Sprint **Taskboard** (as opposed to the Kanban **board**)
buckets tasks purely by `System.State`, so `Update-TfsWorkItemFields -Fields @{ "System.State" =
... }` is sufficient and there's nothing else to keep in sync for Tasks. PBIs/Bugs on the Kanban
board do have the board-column fields (see "Board columns" section above).

## Key files

| Path | Purpose |
|---|---|
| `scripts/tfs-boards.ps1` | `Invoke-TfsApi` base wrapper + `Invoke-TfsWiql`, `Get-TfsWorkItem`, `New-TfsWorkItem`, `Update-TfsWorkItemFields`, `Add-TfsWorkItemComment`, `Remove-TfsWorkItem`, `Get-TfsTeams`, `Get-TfsTeamBoards`, `Get-TfsTeamBoardColumns` |
