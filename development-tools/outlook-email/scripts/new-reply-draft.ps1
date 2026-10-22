<#
.SYNOPSIS
Creates a Reply All (default) or Reply draft in classic Outlook. Never sends.

.DESCRIPTION
Looks up a message by EntryID, creates a reply, places the reviewed text above
Outlook's quoted original, saves the draft, and reports its recipients. The user
must review the saved draft and confirm before anything is sent.

.PARAMETER EntryID
EntryID of the message being replied to.

.PARAMETER Body
Reviewed reply text. Pass the exact text the user approved.

.PARAMETER ReplyOne
Create a Reply (original sender only) instead of the default Reply All.

.EXAMPLE
.\new-reply-draft.ps1 -EntryID '<EntryID>' -Body $approvedText
#>
param(
    [Parameter(Mandatory)] [string] $EntryID,
    [Parameter(Mandatory)] [string] $Body,
    [switch] $ReplyOne
)

$ErrorActionPreference = 'Stop'
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNamespace('MAPI')
$original = $namespace.GetItemFromID($EntryID)

if ($ReplyOne) {
    $draft = $original.Reply()
} else {
    $draft = $original.ReplyAll()
}

$draft.Body = $Body.TrimEnd() + "`r`n`r`n" + $draft.Body
$draft.Save()

[pscustomobject]@{
    Subject = $draft.Subject
    To      = $draft.To
    CC      = $draft.CC
    EntryID = $draft.EntryID
}
