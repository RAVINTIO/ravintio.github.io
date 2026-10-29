# migrate-ravintio-rename.ps1 - Move a consumer repo from the Planifest names to the RAVINTIO names.
# Idempotent: safe to run multiple times. Stops before it moves anything on a conflict.
# Run from the consumer project root, the folder that holds ravintio-zero/.
# It never deletes the old pack. It moves it to .ravintio-backup/ instead.
# Works on Windows PowerShell 5.1 and PowerShell 7. Keep this file ASCII.

$ErrorActionPreference = 'Stop'

$OldOverrides = 'planifest-overrides'
$NewOverrides = 'ravintio-overrides'
$OldWorkflow = '.github/workflows/planifest.yml'
$NewWorkflow = '.github/workflows/ravintio.yml'
$OldPack = 'planifest-zero'
$Backup = '.ravintio-backup'
$Markers = @('.claude/.planifest-setup-flags', '.claude/skills/.planifest-manifest')
# The pack's own workflow variables. Every other PLANIFEST_ name, such as a
# consumer secret, stays as it is.
$PackVars = 'REQUIRE_PWSH|PWSH|TEST_QUIET|PREFLIGHT_ONLY|REGRESSION_DIR|ROADMAP_MODEL|ROADMAP_MAX_TURNS'

$changed = $false

function Get-FullPath {
    param([string]$Path)
    # Combine keeps a rooted path as it is, such as an absolute path from git.
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).ProviderPath, $Path))
}

# Attributes of the entry itself, or $null when nothing is there. A link is
# read as a link, never followed, so a dangling link still counts as present.
function Get-EntryAttributes {
    param([string]$Path)
    try { return [System.IO.File]::GetAttributes((Get-FullPath $Path)) }
    catch { return $null }
}

# True when the entry itself is a link, dangling or not. On Windows the
# ReparsePoint attribute shows a junction or symlink. PowerShell 7 on Linux
# can miss a directory symlink there, so this also reads LinkTarget (.NET 6
# and later) and the LinkType property of Get-Item.
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
            # A hard link is a plain file, not a link to follow.
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

# Run git and return its output lines, or $null when git fails or is missing.
function Invoke-GitLines {
    param([string[]]$GitArgs)
    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& git @GitArgs 2>$null)
        if ($LASTEXITCODE -ne 0) { return $null }
        return ,$lines
    }
    catch { return $null }
    finally { $ErrorActionPreference = $saved }
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

# Return the first path that is a symlink, or '' when none is.
function Get-FirstLink {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if (Test-Link $p) { return $p }
    }
    return ''
}

$inGit = $false
$inside = Invoke-GitLines @('rev-parse', '--is-inside-work-tree')
if (($null -ne $inside) -and (($inside -join '') -eq 'true')) { $inGit = $true }

# A symlinked parent folder skips only the step that would write through it.
$wfLink = Get-FirstLink @('.github', '.github/workflows')

# Refuse a symlink before any other check. Never follow a planted link.
# This covers each source and target and the two workflow files. A dangling
# link counts too.
$linkChecks = @($OldOverrides, $NewOverrides, $OldPack, $Backup)
if ($wfLink -eq '') { $linkChecks += @($OldWorkflow, $NewWorkflow) }
foreach ($p in $linkChecks) {
    if (Test-Link $p) {
        Write-Host "ERROR: $p is a symlink. Refusing to continue. Nothing was moved."
        Write-Host "Replace the link with a real file or folder, or remove it, then run this helper again."
        exit 1
    }
}

# Step 1: the new pack must be in place. This folder is the project root.
if (-not (Test-Path -LiteralPath 'ravintio-zero' -PathType Container)) {
    Write-Host "ERROR: ravintio-zero/ not found. Nothing was moved."
    Write-Host "Copy the new ravintio-zero/ folder into this repo, then run this helper again."
    exit 1
}

# Step 2: both override folders is a conflict.
if ((Test-Path -LiteralPath $OldOverrides -PathType Container) -and (Test-Path -LiteralPath $NewOverrides -PathType Container)) {
    Write-Host "WARNING: Both $OldOverrides/ and $NewOverrides/ exist. Nothing was moved."
    Write-Host "Cannot merge automatically. Please resolve manually:"
    Write-Host "  1. Decide which folder is authoritative."
    Write-Host "  2. Move its contents to $NewOverrides/ if needed."
    Write-Host "  3. Delete $OldOverrides/."
    exit 1
}

# Step 4 conflict check runs before any move, so a stop leaves the repo untouched.
if (($wfLink -eq '') -and (Test-Present $OldWorkflow) -and (Test-Present $NewWorkflow)) {
    Write-Host "ERROR: $NewWorkflow already exists. Nothing was moved."
    Write-Host "Merge or delete one of $OldWorkflow and $NewWorkflow, then run this helper again."
    exit 1
}

# Step 6 conflict check runs before any move. An earlier backup is never overwritten.
if (Test-Path -LiteralPath $OldPack -PathType Container) {
    $backupIsFile = (Test-Present $Backup) -and (-not (Test-Path -LiteralPath $Backup -PathType Container))
    if ((Test-Present "$Backup/$OldPack") -or $backupIsFile) {
        Write-Host "ERROR: $Backup/$OldPack already exists. Nothing was moved."
        Write-Host "Check $Backup/ and delete it once nothing of yours is in it, then run this helper again."
        exit 1
    }
}

# Step 3: overrides.
if (Test-Path -LiteralPath $OldOverrides -PathType Container) {
    Move-Entry $OldOverrides $NewOverrides
    Write-Host "Moved $OldOverrides/ to $NewOverrides/."
    $changed = $true
}
else {
    Write-Host "Skipped $OldOverrides/: not present."
}

# Step 4: workflow.
if ($wfLink -ne '') {
    Write-Host "WARNING: $wfLink is a symlink. Skipped the workflow step, so nothing is written through the link."
    Write-Host "If $OldWorkflow exists, rename it to ravintio.yml yourself."
}
elseif (Test-Present $OldWorkflow) {
    Move-Entry $OldWorkflow $NewWorkflow
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $full = Get-FullPath $NewWorkflow
    $text = [System.IO.File]::ReadAllText($full, $utf8)
    $text = $text.Replace('planifest-zero/', 'ravintio-zero/')
    $varRule = '(?<![A-Za-z0-9_])PLANIFEST_(' + $PackVars + ')(?![A-Za-z0-9_])'
    $text = [regex]::Replace($text, $varRule, 'RAVINTIO_$1')
    # Write to a temp file in the same folder, then rename it over the target,
    # so the write replaces the file and never follows a link.
    $tmp = Join-Path ([System.IO.Path]::GetDirectoryName($full)) ('.ravintio.yml.' + [guid]::NewGuid().ToString('N'))
    [System.IO.File]::WriteAllText($tmp, $text, $utf8)
    [System.IO.File]::Delete($full)
    [System.IO.File]::Move($tmp, $full)
    Write-Host "Moved $OldWorkflow to $NewWorkflow."
    $changed = $true
}
else {
    Write-Host "Skipped ${OldWorkflow}: not present."
}

# Step 5: old markers. A marker under a symlinked folder is left in place.
foreach ($m in $Markers) {
    $parentLink = Get-FirstLink @('.claude', $m.Substring(0, $m.LastIndexOf('/')))
    if ($parentLink -ne '') {
        Write-Host "WARNING: $parentLink is a symlink. Skipped $m, so nothing is removed through the link."
    }
    elseif (Test-Present $m) {
        Remove-Item -LiteralPath $m -Force
        Write-Host "Removed $m."
        $changed = $true
    }
    else {
        Write-Host "Skipped ${m}: not present."
    }
}

# Step 6: old pack folder. Stop tracking it, then rename it into the backup
# folder. A rename never follows a nested link or junction.
if (Test-Path -LiteralPath $OldPack -PathType Container) {
    if ($inGit -and (Test-Tracked $OldPack)) {
        & git rm -r -q --cached -- $OldPack
        if ($LASTEXITCODE -ne 0) { throw "git rm --cached failed for $OldPack" }
    }
    New-Item -ItemType Directory -Path $Backup -Force | Out-Null
    [System.IO.Directory]::Move((Get-FullPath $OldPack), (Get-FullPath "$Backup/$OldPack"))
    if ($inGit) {
        $exclude = Get-FullPath ((Invoke-GitLines @('rev-parse', '--git-path', 'info/exclude')) -join '')
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($exclude)) | Out-Null
        $utf8 = New-Object System.Text.UTF8Encoding $false
        $current = ''
        if (Test-Path -LiteralPath $exclude -PathType Leaf) { $current = [System.IO.File]::ReadAllText($exclude, $utf8) }
        $listed = @($current -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_ -ceq "$Backup/" })
        if ($listed.Count -eq 0) {
            $add = "$Backup/`n"
            if (($current.Length -gt 0) -and (-not $current.EndsWith("`n"))) { $add = "`n" + $add }
            [System.IO.File]::AppendAllText($exclude, $add, $utf8)
        }
    }
    Write-Host "Moved $OldPack/ to $Backup/$OldPack/. Delete $Backup/ once you have checked that nothing of yours is in it."
    $changed = $true
}
else {
    Write-Host "Skipped $OldPack/: not present."
}

# Archive this migration once it has changed the repo, so the orchestrator
# stops offering it. A repo with no old install keeps it pending.
$Migration = 'ravintio-zero/migrations/0004-ravintio-rename.md'
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

# Step 7: next step.
if (-not $changed) {
    Write-Host "Nothing to do. This repo already uses the ravintio names."
}
else {
    Write-Host "Done."
}
Write-Host "Next step: run ravintio-zero/setup.sh claude-code (ravintio-zero/setup.ps1 claude-code on Windows)."
exit 0
