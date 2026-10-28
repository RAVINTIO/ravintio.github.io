# migrate-initiative-rename.ps1 - Move a consumer repo from the roadmap names to the initiative names.
# Idempotent: safe to run multiple times. Stops before it changes anything on a conflict.
# Run from the consumer project root, the folder that holds ravintio-zero/.
# Works on Windows PowerShell 5.1 and PowerShell 7. Keep this file ASCII.

$ErrorActionPreference = 'Stop'

$Active = 'plan/current-roadmap'
$Drafts = 'plan/roadmap'
$Workflow = '.github/workflows/ravintio.yml'
$OldLogs = 'plan/.roadmap-logs'
$NewLogs = 'plan/.initiative-logs'
$Migration = 'ravintio-zero/migrations/0005-initiative-rename.md'

$changed = $false

function Get-FullPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).ProviderPath, $Path))
}

# Attributes of the entry itself, or $null when nothing is there. A link is
# read as a link, never followed, so a dangling link still counts as present.
function Get-EntryAttributes {
    param([string]$Path)
    try { return [System.IO.File]::GetAttributes((Get-FullPath $Path)) }
    catch { return $null }
}

# True when the entry itself is a link, dangling or not.
function Test-Link {
    param([string]$Path)
    $full = Get-FullPath $Path
    $attrs = Get-EntryAttributes $Path
    if (($null -ne $attrs) -and (($attrs -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) { return $true }
    try {
        $info = New-Object System.IO.FileInfo $full
        if (($null -ne $info.PSObject.Properties['LinkTarget']) -and ($null -ne $info.LinkTarget)) { return $true }
    }
    catch { }
    try {
        $item = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
        if ($null -ne $item) {
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
            if (($null -ne $item.PSObject.Properties['LinkType']) -and (@('SymbolicLink', 'Junction') -contains "$($item.LinkType)")) { return $true }
        }
    }
    catch { }
    return $false
}

function Test-Present {
    param([string]$Path)
    if ($null -ne (Get-EntryAttributes $Path)) { return $true }
    return (Test-Link $Path)
}

function Test-Tracked {
    param([string]$Path)
    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $listed = @(& git ls-files -- $Path 2>$null)
        if ($LASTEXITCODE -ne 0) { return $false }
        return ($listed.Count -gt 0)
    }
    catch { return $false }
    finally { $ErrorActionPreference = $saved }
}

function Move-Entry {
    param([string]$From, [string]$To)
    if (Test-Tracked $From) {
        & git mv $From $To
        if ($LASTEXITCODE -ne 0) { throw "git mv failed for $From" }
    }
    else {
        Move-Item -LiteralPath $From -Destination $To
    }
}

function Get-FirstLink {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if (Test-Link $p) { return $p }
    }
    return ''
}

function Stop-OnLink {
    param([string]$Path)
    Write-Host "ERROR: $Path is a symlink. Refusing to continue. Nothing was changed."
    Write-Host "Replace the link with a real file or folder, or remove it, then run this helper again."
    exit 1
}

# Stop while an initiative is active. Finish or park it first.
if (Test-Present $Active) {
    Write-Host "ERROR: $Active/ exists. An initiative is active. Nothing was changed."
    Write-Host "Finish or park the active initiative, then run this helper again."
    exit 1
}

foreach ($p in @('plan', $Drafts, $OldLogs, $NewLogs)) {
    if (Test-Link $p) { Stop-OnLink $p }
}
if (Test-Present $Workflow) {
    $wfLink = Get-FirstLink @('.github', '.github/workflows', $Workflow)
    if ($wfLink -ne '') { Stop-OnLink $wfLink }
}

$found = @()
if (Test-Path -LiteralPath $Drafts -PathType Container) {
    foreach ($entry in @(Get-ChildItem -LiteralPath $Drafts -Force)) {
        $d = "$Drafts/$($entry.Name)"
        if (Test-Present "$d/roadmap.md") {
            if (Test-Link $d) { Stop-OnLink $d }
            if (Test-Link "$d/roadmap.md") { Stop-OnLink "$d/roadmap.md" }
            if (Test-Link "$d/initiative.md") { Stop-OnLink "$d/initiative.md" }
            $found += $d
        }
    }
}

# Check every conflict before the first change.
foreach ($d in $found) {
    if (Test-Present "$d/initiative.md") {
        Write-Host "ERROR: $d/ holds both roadmap.md and initiative.md. Nothing was changed."
        Write-Host "Decide which file is authoritative, delete the other, then run this helper again."
        exit 1
    }
}
if ((Test-Present $OldLogs) -and (Test-Present $NewLogs)) {
    Write-Host "ERROR: Both $OldLogs/ and $NewLogs/ exist. Nothing was changed."
    Write-Host "Merge or delete one folder, then run this helper again."
    exit 1
}

# Step 1: rename each draft.
foreach ($d in $found) {
    Move-Entry "$d/roadmap.md" "$d/initiative.md"
    Write-Host "Renamed $d/roadmap.md to $d/initiative.md."
    $changed = $true
}

# Step 2: rename the CI branch pattern. A path such as plan/roadmap/** stays.
if (Test-Path -LiteralPath $Workflow -PathType Leaf) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $full = Get-FullPath $Workflow
    $text = [System.IO.File]::ReadAllText($full)
    $pattern = '(^|[^/\w-])roadmap/\*\*'
    if ([regex]::IsMatch($text, $pattern, 'Multiline')) {
        $new = [regex]::Replace($text, $pattern, '${1}initiative/**', 'Multiline')
        [System.IO.File]::WriteAllText($full, $new, $utf8)
        Write-Host "Replaced roadmap/** with initiative/** in $Workflow."
        $changed = $true
    }
}

# Step 3: rename the log folder.
if (Test-Path -LiteralPath $OldLogs -PathType Container) {
    Move-Entry $OldLogs $NewLogs
    Write-Host "Renamed $OldLogs/ to $NewLogs/."
    $changed = $true
}

# Archive this migration once it has changed the repo, so the orchestrator
# stops offering it. A repo with nothing to move keeps it pending.
$migrationsLink = ''
if ($changed) { $migrationsLink = Get-FirstLink @('ravintio-zero', 'ravintio-zero/migrations') }
if ($migrationsLink -ne '') {
    Write-Host "WARNING: $migrationsLink is a symlink. Skipped archiving $Migration, so nothing is written through the link."
}
elseif ($changed -and (Test-Path -LiteralPath $Migration -PathType Leaf)) {
    if (-not (Test-Link $Migration)) {
        New-Item -ItemType Directory -Path 'ravintio-zero/migrations/_done' -Force | Out-Null
        Move-Item -LiteralPath $Migration -Destination 'ravintio-zero/migrations/_done/'
        Write-Host "Archived $Migration to ravintio-zero/migrations/_done/."
    }
}

if (-not $changed) {
    Write-Host "Nothing to do. This repo already uses the initiative names."
}
else {
    Write-Host "Done."
}
exit 0
