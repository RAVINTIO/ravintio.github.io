# Tests for feature 0000171-faster-setup-ps1-tests, req-002, in setup.ps1
# under whichever host runs this file. Setup installs each skill's own source
# folder byte for byte (REQ-004) and the hook modules. A rerun overwrites a
# changed file. The output keeps one "+ {skill}/SKILL.md" line per skill in
# source order, and the copy code uses System.IO calls in place of Copy-Item
# (ADR-002).
# Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

function Get-FileBase64 {
    param([string]$Path)
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Get-RelativePath {
    param([string]$Root, [string]$Path)
    return $Path.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
}

# Adds every file and folder under $SrcDir to the expected maps, below the
# relative path $DestRel.
function Add-ExpectedTree {
    param($Files, $Dirs, [string]$SrcDir, [string]$DestRel)
    $Dirs[$DestRel] = $true
    foreach ($d in [System.IO.Directory]::GetDirectories($SrcDir, '*', [System.IO.SearchOption]::AllDirectories)) {
        $Dirs[$DestRel + '/' + (Get-RelativePath $SrcDir $d)] = $true
    }
    foreach ($f in [System.IO.Directory]::GetFiles($SrcDir, '*', [System.IO.SearchOption]::AllDirectories)) {
        $Files[$DestRel + '/' + (Get-RelativePath $SrcDir $f)] = $f
    }
}

# Computes the files and folders each skill's own source folder holds,
# keyed by path relative to .claude/skills (REQ-004). Returns the maps and
# the skill order.
function Get-ExpectedSkillTree {
    param([string]$Zero)
    $files = @{}
    $dirs = @{}
    $skills = @()
    $skillsSrc = Join-Path $Zero 'skills'
    foreach ($skill in (Get-ChildItem -Path $skillsSrc -Directory)) {
        $name = $skill.Name
        if (-not [System.IO.File]::Exists((Join-Path $skill.FullName 'SKILL.md'))) { continue }
        $skills += $name
        Add-ExpectedTree $files $dirs $skill.FullName $name
    }
    return [PSCustomObject]@{ Files = $files; Dirs = $dirs; Skills = $skills }
}

# Compares the installed skills folder with the expected tree and asserts on
# the missing, extra, and differing paths.
function Assert-SkillTree {
    param([string]$Workspace, [string]$Label)
    $expected = Get-ExpectedSkillTree (Join-Path $Workspace 'ravintio-zero')
    $root = Join-Path $Workspace '.claude/skills'
    $actualFiles = @{}
    $actualDirs = @{}
    foreach ($f in [System.IO.Directory]::GetFiles($root, '*', [System.IO.SearchOption]::AllDirectories)) {
        $rel = Get-RelativePath $root $f
        # Setup writes the manifest at the top level, outside any skill folder.
        if ($rel -eq '.ravintio-manifest') { continue }
        $actualFiles[$rel] = $f
    }
    foreach ($d in [System.IO.Directory]::GetDirectories($root, '*', [System.IO.SearchOption]::AllDirectories)) {
        $actualDirs[(Get-RelativePath $root $d)] = $true
    }
    $missing = @($expected.Files.Keys | Where-Object { -not $actualFiles.ContainsKey($_) } | Sort-Object)
    $extra = @($actualFiles.Keys | Where-Object { -not $expected.Files.ContainsKey($_) } | Sort-Object)
    $missingDirs = @($expected.Dirs.Keys | Where-Object { -not $actualDirs.ContainsKey($_) } | Sort-Object)
    $extraDirs = @($actualDirs.Keys | Where-Object { -not $expected.Dirs.ContainsKey($_) } | Sort-Object)
    Assert-Equal '' ($missing -join ', ') "${Label}: no expected file is missing"
    Assert-Equal '' ($extra -join ', ') "${Label}: no unexpected file exists"
    Assert-Equal '' ($missingDirs -join ', ') "${Label}: no expected folder is missing"
    Assert-Equal '' ($extraDirs -join ', ') "${Label}: no unexpected folder exists"
    $differ = @()
    foreach ($rel in $expected.Files.Keys) {
        if (-not $actualFiles.ContainsKey($rel)) { continue }
        if ((Get-FileBase64 $expected.Files[$rel]) -cne (Get-FileBase64 $actualFiles[$rel])) { $differ += $rel }
    }
    Assert-Equal '' ((@($differ) | Sort-Object) -join ', ') "${Label}: every file matches its source"
    Assert-True ($expected.Files.Count -gt 12) "${Label}: the expected tree holds every skill's files"
}

# Returns the text of one function in a script, up to the next function line.
function Get-FunctionBody {
    param([string]$Text, [string]$Name)
    $start = $Text.IndexOf("function $Name")
    if ($start -lt 0) { return '' }
    $next = $Text.IndexOf("`nfunction ", $start + 1)
    if ($next -lt 0) { return $Text.Substring($start) }
    return $Text.Substring($start, $next - $start)
}

try {

Write-Host ""
Write-Host "=== req-002 AC-1: a fresh install matches the skill source folders ==="
$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "AC-1: setup.ps1 exits 0"
Assert-SkillTree $ws 'AC-1'

Write-Host ""
Write-Host "=== req-002 AC-2: a rerun overwrites a changed skill file ==="
$changed = Get-ChildItem -Path (Join-Path $ws '.claude/skills') -Recurse -File |
    Where-Object { $_.FullName -match '[\\/]references[\\/]orchestrator-[^\\/]+\.md$' } | Select-Object -First 1
Assert-True ($null -ne $changed) "AC-2: an installed skill reference file exists"
[System.IO.File]::WriteAllText($changed.FullName, 'changed by hand')
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "AC-2: the rerun exits 0"
Assert-SkillTree $ws 'AC-2'

Write-Host ""
Write-Host "=== req-002 AC-3: hooks and output are unchanged ==="
$ws3 = New-SetupWorkspace
$run3 = Invoke-Setup $ws3 @('claude-code')
$hooksSrc = Join-Path $ws3 'ravintio-zero/hooks/enforcement'
$hooksDest = Join-Path $ws3 '.claude/hooks/enforcement'
$hookFiles = @([System.IO.Directory]::GetFiles($hooksSrc, '*.mjs'))
Assert-True ($hookFiles.Count -gt 0) "AC-3: the source holds hook modules"
foreach ($f in $hookFiles) {
    $name = [System.IO.Path]::GetFileName($f)
    $dest = Join-Path $hooksDest $name
    Assert-True ([System.IO.File]::Exists($dest)) "AC-3: $name is installed"
    if ([System.IO.File]::Exists($dest)) {
        Assert-Equal (Get-FileBase64 $f) (Get-FileBase64 $dest) "AC-3: $name matches its source bytes"
    }
}
$expectedLines = @((Get-ExpectedSkillTree (Join-Path $ws3 'ravintio-zero')).Skills | ForEach-Object { "  + $_/SKILL.md" })
$actualLines = @($run3.Output -split "\r?\n" | Where-Object { $_ -match '^  \+ [^/ ]+/SKILL\.md$' })
Assert-Equal ($expectedLines -join "`n") ($actualLines -join "`n") "AC-3: one SKILL.md line per skill in source order"

Write-Host ""
Write-Host "=== req-002: the copy code uses System.IO calls (ADR-002) ==="
$setupText = [System.IO.File]::ReadAllText((Join-Path $global:ZeroDir 'setup.ps1'))
foreach ($fn in @('Copy-RavintioSkills', 'Install-EnforcementHooks')) {
    $body = Get-FunctionBody $setupText $fn
    Assert-True ($body.Length -gt 0) "ADR-002: $fn is found in setup.ps1"
    Assert-True ($body -notmatch 'Copy-Item') "ADR-002: $fn holds no Copy-Item call"
}

}
finally {
    Remove-AllWorkspaces
}

Complete-Suite
