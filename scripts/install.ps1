<#
.SYNOPSIS
    Mounts this skill library into every agent skill directory on a Windows machine.

.DESCRIPTION
    Creates a directory junction from each agent's personal skill folder to this repo,
    so every folder here becomes an available skill and new folders appear automatically.
    Junctions need no admin rights, but require the repo to be on the same volume as
    the user profile. Idempotent: existing correct links are left alone.

.EXAMPLE
    .\scripts\install.ps1
    .\scripts\install.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Agent skill directories to link, relative to the user profile.
    [string[]] $Targets = @('.copilot\skills', '.claude\skills', '.agents\skills')
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ((Split-Path $repo -Qualifier) -ne (Split-Path $env:USERPROFILE -Qualifier)) {
    Write-Warning "Repo is on $(Split-Path $repo -Qualifier) but the profile is on $(Split-Path $env:USERPROFILE -Qualifier). Junctions cannot span volumes; use a symlink (needs admin or Developer Mode)."
}

foreach ($rel in $Targets) {
    $link = Join-Path $env:USERPROFILE $rel
    $parent = Split-Path $link -Parent

    if (Test-Path $link) {
        $existing = Get-Item $link -Force
        if ($existing.LinkType -and $existing.Target -contains $repo) {
            Write-Host "OK        $link" -ForegroundColor Green
            continue
        }
        Write-Warning "SKIPPED   $link already exists and does not point at this repo. Remove it first (cmd /c rmdir `"$link`" for a link)."
        continue
    }

    if ($PSCmdlet.ShouldProcess($link, "Junction -> $repo")) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        cmd /c mklink /J "$link" "$repo" | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "LINKED    $link" -ForegroundColor Cyan }
        else { Write-Warning "FAILED    $link" }
    }
}

# A skill is invisible to discovery without frontmatter, and a name that doesn't match
# its folder fails silently, so report both rather than let them pass unnoticed.
Write-Host "`nSkill check:" -ForegroundColor White
Get-ChildItem $repo -Directory |
    Where-Object { $_.Name -notin @('.git', 'shared', 'scripts') } |
    ForEach-Object {
        $skill = Join-Path $_.FullName 'SKILL.md'
        $issue =
            if (-not (Test-Path $skill)) { 'no SKILL.md' }
            else {
                $head = Get-Content $skill -TotalCount 5
                if ($head[0] -ne '---') { 'no frontmatter (will not load)' }
                elseif (($head | Where-Object { $_ -match '^name:\s*(.+)$' } |
                         ForEach-Object { $Matches[1].Trim() }) -ne $_.Name) { 'name does not match folder (will not load)' }
                elseif (Select-String -Path $skill -Pattern '\*\*TODO:\*\*' -Quiet) { 'stub - description only, empty body' }
                else { $null }
            }
        if ($issue) { Write-Warning ("{0,-16} {1}" -f $_.Name, $issue) }
    }
