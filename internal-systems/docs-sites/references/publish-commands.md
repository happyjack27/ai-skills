# Publish commands

PowerShell, Windows. Set the variables first, then use the steps in order. Use the file-edit tools for content; these commands only read, copy, and compare. Run `Get-FileHash` loops on one topic at a time: hashing a whole site over the share is slow.

```powershell
$site  = 'DeveloperDocumentation'      # or 'EndUserDocumentation'
$topic = 'dpw-oracle-migration'
$loc   = "C:\Users\kbaas\eclipse-workspace\$site\WebContent\markdown"
$shr   = "\\MkeAppsFs\FS\Apps\$site"
```

## 1. Pull and check for recent browser edits

```powershell
# Compare one topic (ignores .history and .lock)
function Compare-Topic($a, $b) {
  $rel = { param($root,$p) $p.Substring($root.Length+1) }
  $fa = Get-ChildItem $a -Recurse -File -ErrorAction SilentlyContinue | % { & $rel $a $_.FullName }
  $fb = Get-ChildItem $b -Recurse -File -ErrorAction SilentlyContinue | % { & $rel $b $_.FullName }
  $fa | ? { $_ -notin $fb } | % { "only in A: $_" }
  $fb | ? { $_ -notin $fa } | % { "only in B: $_" }
  $fa | ? { $_ -in $fb } | ? { (Get-FileHash "$a\$_").Hash -ne (Get-FileHash "$b\$_").Hash } | % { "differs: $_" }
}
Compare-Topic "$loc\$topic" "$shr\$topic"

# Recent edits by anyone (last 10 lines; one JSON object per line)
Get-Content "$shr\.history\edits.log" -Tail 10 | % { $j = $_ | ConvertFrom-Json; '{0}  {1}  {2}  {3}' -f $j.time,$j.user,$j.action,$j.file }

# If the share is newer or different, pull it down before editing
Copy-Item "$shr\$topic\*" "$loc\$topic\" -Recurse -Force
```

If `.history\edits.log` does not exist, nobody has used the browser editor on that site yet.

## 2. Validate (relative links, anchors, mermaid, size, secrets)

```powershell
function Test-Topic($dir) {
  $bad = 0
  $anchors = @{}
  foreach ($f in Get-ChildItem $dir -Recurse -Filter *.md) {
    $set = @{}
    foreach ($m in [regex]::Matches((Get-Content $f -Raw),'(?m)^#{1,6}\s+(.+?)\s*$')) {
      $set[($m.Groups[1].Value.ToLower() -replace '`','' -replace '[^\w\s-]','' -replace '\s','-')] = 1
    }
    $anchors[$f.FullName] = $set
  }
  foreach ($f in Get-ChildItem $dir -Recurse -Filter *.md) {
    $c = Get-Content $f -Raw
    if ($c -match '(?m)^\s*[`]{3}mermaid') { "$($f.Name): mermaid block"; $bad++ }
    if ($f.Length -gt 2MB)       { "$($f.Name): over 2 MB"; $bad++ }
    if ($c -match '(?i)(password|passwd|secret|api[_-]?key|token)\s*[:=]\s*\S{6,}') { "$($f.Name): possible secret"; $bad++ }
    foreach ($m in [regex]::Matches($c,'\]\(([^)#\s]*)(#[^)\s]*)?\)')) {
      $p = $m.Groups[1].Value; $a = $m.Groups[2].Value
      if ($p -match '^(https?:|mailto:)') { continue }
      $target = if ($p) { Join-Path $f.DirectoryName $p } else { $f.FullName }
      if (-not (Test-Path $target)) { "$($f.Name): missing file $p"; $bad++; continue }
      if ($a -and $target -like '*.md') {
        $key = (Resolve-Path $target).Path
        if (-not $anchors[$key].ContainsKey($a.Substring(1))) { "$($f.Name): missing anchor $p$a"; $bad++ }
      }
    }
  }
  "problems: $bad"
}
Test-Topic "$loc\$topic"
```

The secret pattern is a tripwire, not proof; still read the pages for credentials, connection strings, and personal data. Links that leave the topic (for example `../itmdpedia/index.md`) are checked by file existence only.

## 3. Publish

```powershell
# Back up any existing share pages you will overwrite
$bak = "$env:TEMP\docs-backup-$site-$topic-$(Get-Date -Format yyyyMMdd-HHmmss)"
if (Test-Path "$shr\$topic") { Copy-Item "$shr\$topic" $bak -Recurse }

New-Item -ItemType Directory "$shr\$topic" -Force | Out-Null
Copy-Item "$loc\$topic\*" "$shr\$topic\" -Recurse -Force
```

Never copy into or delete `.history`, `.lock`, or other dot-named entries. To remove a page, delete it deliberately from both copies and say so in the memory note.

## 4. Update the index

```powershell
# DeveloperDocumentation only: regenerates the list after "## Topics" in both roots
$tool = 'C:\Users\kbaas\eclipse-workspace\DeveloperDocumentation\tools\update-index.ps1'
& $tool -Root $loc
& $tool -Root $shr
```

`EndUserDocumentation`: edit `index.md` by hand in the local project and add one bullet per guide under `## Guides`, in the form shown below, then copy the file to the share:

```markdown
- [Using KWAT applications](kwat/index.md): one-sentence description of the guide.
```

```powershell
Copy-Item "$loc\index.md" "$shr\index.md" -Force
```

## 5. Verify

```powershell
Compare-Topic "$loc\$topic" "$shr\$topic"      # expect no output
(Get-FileHash "$loc\index.md").Hash -eq (Get-FileHash "$shr\index.md").Hash   # expect True
Select-String -Path "$shr\index.md" -Pattern $topic                            # topic is listed
```

Optionally open `http://<tomcat-host>/<Site>/` and the topic page to confirm it renders (the server picks up share changes within a few seconds).
