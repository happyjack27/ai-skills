# Reusable PowerShell functions for tfs.milwaukee.gov (on-prem Azure DevOps Server / TFS).
# Dot-source this file, then call the functions. Uses Windows Integrated auth (current AD
# session) - no PAT needed. See ../SKILL.md and ../references/api-reference.md for the "why".
#
#   . .\tfs-boards.ps1
#   Invoke-TfsWiql "SELECT [System.Id],[System.Title] FROM WorkItems WHERE [System.AssignedTo] = @Me"

$Script:TfsCollectionUrl = "https://tfs.milwaukee.gov/ApplicationAndDevelopment"
$Script:TfsProject       = "Internal Systems Projects"
$Script:TfsApiVersion    = "6.0"

function Invoke-TfsApi {
    param(
        [Parameter(Mandatory)][string]$RelativeUri,   # e.g. "wit/workitems/423"
        [string]$Method = "Get",
        [object]$Body = $null,
        [string]$ApiVersion = $Script:TfsApiVersion,
        [string]$ContentType = "application/json",
        [string]$TeamId = $null   # team-scoped APIs (e.g. work/boards) need {project}/{team}/_apis/...
    )
    $sep = if ($RelativeUri -match '\?') { '&' } else { '?' }
    $projectSeg = [uri]::EscapeDataString($Script:TfsProject)
    $teamSeg = if ($TeamId) { "/$TeamId" } else { "" }
    $uri = "$($Script:TfsCollectionUrl)/$projectSeg$teamSeg/_apis/$RelativeUri${sep}api-version=$ApiVersion"
    $params = @{ Uri = $uri; Method = $Method; UseDefaultCredentials = $true }
    if ($Body -ne $null) {
        if ($Body -is [string]) {
            $params.Body = $Body
        } elseif ($Body -is [array]) {
            # -AsArray: ConvertTo-Json silently un-arrays a single-element array, breaking JSON Patch bodies.
            $params.Body = $Body | ConvertTo-Json -Depth 10 -AsArray
        } else {
            $params.Body = $Body | ConvertTo-Json -Depth 10
        }
        $params.ContentType = $ContentType
    }
    Invoke-RestMethod @params
}

function Invoke-TfsWiql {
    <# Runs a WIQL query, returns the raw work item id/url list (not full field data). #>
    param([Parameter(Mandatory)][string]$Query)
    Invoke-TfsApi -RelativeUri "wit/wiql" -Method Post -Body @{ query = $Query }
}

function Get-TfsWorkItem {
    <# Fetches one work item with all fields/relations expanded. #>
    param([Parameter(Mandatory)][int]$Id)
    Invoke-TfsApi -RelativeUri "wit/workitems/${Id}?`$expand=all" -Method Get
}

function New-TfsWorkItem {
    <#
      Creates a work item. $Fields is a hashtable of "System.Title" -> value, etc.
      -ParentId links it as a child (e.g. Task under a PBI) via a relations patch op -
      parent/child is NOT a plain field, System.Parent in $Fields will NOT work.
      Example: New-TfsWorkItem -Type "Task" -Fields @{ "System.Title" = "Fix thing" } -ParentId 373
    #>
    param(
        [Parameter(Mandatory)][string]$Type,          # "Task", "Bug", "Product Backlog Item"
        [Parameter(Mandatory)][hashtable]$Fields,
        [int]$ParentId = 0
    )
    # @(...) is required: PowerShell unwraps a single-item foreach result, breaking the JSON Patch array shape.
    $ops = @(foreach ($key in $Fields.Keys) {
        @{ op = "add"; path = "/fields/$key"; value = $Fields[$key] }
    })
    if ($ParentId -gt 0) {
        $ops += @{
            op = "add"; path = "/relations/-"
            value = @{ rel = "System.LinkTypes.Hierarchy-Reverse"; url = "$($Script:TfsCollectionUrl)/_apis/wit/workItems/$ParentId" }
        }
    }
    Invoke-TfsApi -RelativeUri "wit/workitems/`$$([uri]::EscapeDataString($Type))" -Method Patch `
        -Body $ops -ContentType "application/json-patch+json"
}

function Add-TfsParentLink {
    <#
      Adds a parent link to an EXISTING work item (retroactive fix for one created without
      -ParentId). New-TfsWorkItem -ParentId only works at creation time; this covers after-the-fact.
      Example: Add-TfsParentLink -Id 561 -ParentId 540
    #>
    param([Parameter(Mandatory)][int]$Id, [Parameter(Mandatory)][int]$ParentId)
    $ops = @(@{
        op = "add"; path = "/relations/-"
        value = @{ rel = "System.LinkTypes.Hierarchy-Reverse"; url = "$($Script:TfsCollectionUrl)/_apis/wit/workItems/$ParentId" }
    })
    Invoke-TfsApi -RelativeUri "wit/workitems/$Id" -Method Patch -Body $ops -ContentType "application/json-patch+json"
}

function Remove-TfsWorkItem {
    <#
      Deletes a work item. Default is a soft delete (recycle bin, recoverable). Pass -Destroy for
      a permanent, unrecoverable delete.
    #>
    param([Parameter(Mandatory)][int]$Id, [switch]$Destroy)
    $uri = "wit/workitems/${Id}"
    if ($Destroy) { $uri += "?destroy=true" }
    Invoke-TfsApi -RelativeUri $uri -Method Delete
}

function Update-TfsWorkItemFields {
    <# Updates one or more fields on an existing item, e.g. state or board column. #>
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][hashtable]$Fields
    )
    # @(...) is required: PowerShell unwraps a single-item foreach result, breaking the JSON Patch array shape.
    $ops = @(foreach ($key in $Fields.Keys) {
        @{ op = "add"; path = "/fields/$key"; value = $Fields[$key] }
    })
    Invoke-TfsApi -RelativeUri "wit/workitems/$Id" -Method Patch -Body $ops `
        -ContentType "application/json-patch+json"
}

function Add-TfsWorkItemComment {
    <# Adds a discussion comment (does NOT change System.History-style revision text). #>
    param([Parameter(Mandatory)][int]$Id, [Parameter(Mandatory)][string]$Text)
    Invoke-TfsApi -RelativeUri "wit/workItems/$Id/comments" -Method Post -Body @{ text = $Text } `
        -ApiVersion "6.0-preview.3"
}

function Get-TfsTeamBoardColumns {
    <# List a team's Kanban board columns (name/type/WIP limit). #>
    param(
        [Parameter(Mandatory)][string]$TeamId,
        [Parameter(Mandatory)][string]$BoardId   # "Backlog items" | "Features" | "Epics" board GUID
    )
    Invoke-TfsApi -RelativeUri "work/boards/$BoardId/columns" -TeamId $TeamId
}

function Get-TfsTeams {
    <# List teams in $Script:TfsProject (name + id) - id feeds TeamId params above. #>
    param()
    $uri = "$($Script:TfsCollectionUrl)/_apis/projects/$([uri]::EscapeDataString($Script:TfsProject))/teams?api-version=$($Script:TfsApiVersion)"
    Invoke-RestMethod -Uri $uri -UseDefaultCredentials
}

function Get-TfsTeamBoards {
    <# List a team's boards (Backlog items / Features / Epics) - name + id feeds BoardId params above. #>
    param([Parameter(Mandatory)][string]$TeamId)
    Invoke-TfsApi -RelativeUri "work/boards" -TeamId $TeamId
}
