# Feature 0000160 req-005: migrate-ravintio-rename.ps1 moves a consumer repo to
# the ravintio names. Covers the clean run, a rerun, each stop condition,
# symlink refusal, the skip under a linked parent folder, and the backup move
# of the old pack, in scratch git repos. Works on Windows PowerShell 5.1 and
# PowerShell 7. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')

$zeroDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$helper = Join-Path $zeroDir 'migrations\migrate-ravintio-rename.ps1'
$hostExe = (Get-Process -Id $PID).Path
$old = 'plan' + 'ifest'
$oldUpper = 'PLAN' + 'IFEST'
$packVars = @('REQUIRE_PWSH', 'PWSH', 'TEST_QUIET', 'PREFLIGHT_ONLY', 'REGRESSION_DIR', 'ROADMAP_MODEL', 'ROADMAP_MAX_TURNS')
$backupMessage = "Moved $old-zero/ to .ravintio-backup/$old-zero/. Delete .ravintio-backup/ once you have checked that nothing of yours is in it."
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('ravintio_0000160_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false

function New-Repo {
    param([string]$Name)
    $d = Join-Path $scratch $Name
    foreach ($sub in @('ravintio-zero', "$old-zero", "$old-overrides\instructions", '.github\workflows', '.claude\skills')) {
        New-Item -ItemType Directory -Path (Join-Path $d $sub) -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $d "$old-overrides\instructions\a.md"), 'mine', $utf8)
    $wf = "run: bash $old-zero/tests/run-tests.sh`nenv:`n"
    foreach ($v in $packVars) { $wf += "  ${oldUpper}_${v}: 1`n" }
    $wf += '  TOKEN: ${{ secrets.' + $oldUpper + "_DEPLOY_TOKEN }}`n"
    [System.IO.File]::WriteAllText((Join-Path $d ".github\workflows\$old.yml"), $wf, $utf8)
    [System.IO.File]::WriteAllText((Join-Path $d ".claude\.$old-setup-flags"), 'x', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $d ".claude\skills\.$old-manifest"), 'x', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $d "$old-zero\file.md"), 'x', $utf8)
    [System.IO.File]::WriteAllText((Join-Path $d "$old-zero\setup.sh"), 'x', $utf8)
    New-Item -ItemType Directory -Path (Join-Path $d 'ravintio-zero\migrations') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $d 'ravintio-zero\migrations\0004-ravintio-rename.md'), 'm', $utf8)
    & git -C $d init -q 2>&1 | Out-Null
    & git -C $d config user.email t@example.com
    & git -C $d config user.name t
    & git -C $d add -A 2>&1 | Out-Null
    & git -C $d commit -q -m init 2>&1 | Out-Null
    return $d
}

# Run the helper in Repo. Print its output when the exit code is not Expect,
# so an unexpected result is visible in the CI log.
function Invoke-Helper {
    param([string]$Repo, [int]$Expect = 0, [string]$Ceiling = '')
    if ($Ceiling -eq '') { $Ceiling = Split-Path -Parent $Repo }
    Push-Location $Repo
    $savedCeiling = $env:GIT_CEILING_DIRECTORIES
    $env:GIT_CEILING_DIRECTORIES = $Ceiling
    try {
        $output = & $hostExe -NoProfile -ExecutionPolicy Bypass -File $helper 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        $env:GIT_CEILING_DIRECTORIES = $savedCeiling
        Pop-Location
    }
    if ($code -ne $Expect) {
        Write-Host "  helper exited $code, expected $Expect, with output:"
        Write-Host $output
    }
    return [PSCustomObject]@{ Code = $code; Output = $output }
}

function Get-Snapshot {
    param([string]$Repo)
    $prefix = $Repo.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $names = @(Get-ChildItem -LiteralPath $Repo -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike '*\.git\*' -and $_.FullName -notlike '*/.git/*' -and $_.Name -ne '.git' } |
        ForEach-Object { $_.FullName.Substring($prefix.Length) } | Sort-Object)
    return ($names -join '|')
}

function Read-Text {
    # Returns '' for a missing file, so one failed case does not stop the suite.
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return [System.IO.File]::ReadAllText($Path, $utf8)
}

# True when Path is a link, dangling or not. PowerShell 7 on Linux can miss a
# directory symlink in the attributes, so this also reads LinkType and LinkTarget.
function Test-IsLink {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $item) {
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
        if (($null -ne $item.PSObject.Properties['LinkType']) -and (@('SymbolicLink', 'Junction') -contains "$($item.LinkType)")) { return $true }
    }
    $info = New-Object System.IO.FileInfo $Path
    return (($null -ne $info.PSObject.Properties['LinkTarget']) -and ($null -ne $info.LinkTarget))
}

# Make a directory link at Path: a junction where the host allows it, else a
# symlink. Returns $false when the host allows neither.
function New-DirLink {
    param([string]$Path, [string]$Target)
    foreach ($type in @('Junction', 'SymbolicLink')) {
        try {
            New-Item -ItemType $type -Path $Path -Target $Target -ErrorAction Stop | Out-Null
            if (Test-IsLink $Path) { return $true }
        }
        catch { }
    }
    return $false
}

function Get-ExcludeCount {
    param([string]$GitDir)
    $text = Read-Text (Join-Path $GitDir 'info\exclude')
    return @($text -split "`n" | Where-Object { $_.TrimEnd("`r") -ceq '.ravintio-backup/' }).Count
}

function Get-BackupStatusCount {
    param([string]$Repo)
    return @(& git -C $Repo status --porcelain --untracked-files=all | Where-Object { $_ -match 'ravintio-backup' }).Count
}

try {

Write-Host ""
Write-Host "=== (a) clean run ==="
$r = New-Repo 'clean'
$run = Invoke-Helper $r
$wfText = Read-Text (Join-Path $r '.github\workflows\ravintio.yml')
Assert-Equal 0 $run.Code 'clean run exits 0'
Assert-Equal 'mine' (Read-Text (Join-Path $r 'ravintio-overrides\instructions\a.md')) 'overrides moved with content'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r "$old-overrides"))) 'old overrides folder gone'
Assert-True (Test-Path -LiteralPath (Join-Path $r '.github\workflows\ravintio.yml')) 'workflow renamed'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r ".github\workflows\$old.yml"))) 'old workflow gone'
Assert-Contains 'ravintio-zero/tests/run-tests.sh' $wfText 'workflow paths rewritten'
Assert-Contains 'RAVINTIO_REQUIRE_PWSH' $wfText 'workflow variables rewritten'
foreach ($v in $packVars) {
    Assert-True ($wfText.Contains("`n  RAVINTIO_${v}: 1`n")) "pack variable $v rewritten"
}
Assert-Contains "secrets.${oldUpper}_DEPLOY_TOKEN" $wfText 'consumer secret name kept'
Assert-Equal 1 ([regex]::Matches($wfText, "${oldUpper}_").Count) 'only the consumer secret keeps the old prefix'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r ".claude\.$old-setup-flags"))) 'flags marker removed'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r ".claude\skills\.$old-manifest"))) 'manifest marker removed'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r "$old-zero"))) 'old pack folder gone from the root'
Assert-Equal 'x' (Read-Text (Join-Path $r ".ravintio-backup\$old-zero\file.md")) 'old pack moved to the backup'
Assert-Contains $backupMessage $run.Output 'prints the backup message'
Assert-Equal 0 @(& git -C $r ls-files -- "$old-zero").Count 'git no longer tracks the old pack'
Assert-Equal 1 (Get-ExcludeCount (Join-Path $r '.git')) 'backup folder added to .git/info/exclude'
Assert-Equal 0 (Get-BackupStatusCount $r) 'backup hidden from git status'
Assert-True (Test-Path -LiteralPath (Join-Path $r 'ravintio-zero')) 'new pack folder kept'
Assert-Contains 'Next step: run ravintio-zero/setup.sh claude-code' $run.Output 'prints the setup command'
$renames = @(& git -C $r diff --cached --name-status | Where-Object { $_ -match '^R' })
Assert-Equal 2 $renames.Count 'git records the overrides file and workflow as renames'
Assert-True (Test-Path -LiteralPath (Join-Path $r 'ravintio-zero\migrations\_done\0004-ravintio-rename.md')) 'clean run archives migration 0004'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r 'ravintio-zero\migrations\0004-ravintio-rename.md'))) 'migration 0004 no longer pending'

Write-Host ""
Write-Host "=== (b) rerun changes nothing ==="
$before = Get-Snapshot $r
$run = Invoke-Helper $r
Assert-Equal 0 $run.Code 'rerun exits 0'
Assert-Equal $before (Get-Snapshot $r) 'rerun changes nothing'
Assert-Contains 'Nothing to do' $run.Output 'rerun says nothing to do'
Assert-Equal 1 (Get-ExcludeCount (Join-Path $r '.git')) 'rerun adds no second exclude line'

Write-Host ""
Write-Host "=== (b2) a repo with no old install keeps 0004 pending ==="
$s = Join-Path $scratch 'source'
New-Item -ItemType Directory -Path (Join-Path $s 'ravintio-zero\migrations') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $s 'ravintio-zero\migrations\0004-ravintio-rename.md'), 'm', $utf8)
& git -C $s init -q 2>&1 | Out-Null
$run = Invoke-Helper $s
Assert-Equal 0 $run.Code 'no old install exits 0'
Assert-True (Test-Path -LiteralPath (Join-Path $s 'ravintio-zero\migrations\0004-ravintio-rename.md')) 'no old install leaves 0004 pending'

Write-Host ""
Write-Host "=== (c) untracked folder uses plain move ==="
$r = New-Repo 'untracked'
& git -C $r rm -rq --cached "$old-overrides" 2>&1 | Out-Null
& git -C $r commit -q -m untrack 2>&1 | Out-Null
$run = Invoke-Helper $r
Assert-Equal 0 $run.Code 'untracked run exits 0'
Assert-Equal 'mine' (Read-Text (Join-Path $r 'ravintio-overrides\instructions\a.md')) 'untracked overrides moved'

Write-Host ""
Write-Host "=== (d) no ravintio-zero/ stops ==="
$r = New-Repo 'nopack'
Remove-Item -LiteralPath (Join-Path $r 'ravintio-zero') -Recurse -Force
$before = Get-Snapshot $r
$run = Invoke-Helper $r -Expect 1
Assert-Equal 1 $run.Code 'missing ravintio-zero exits 1'
Assert-Contains 'ravintio-zero/ not found' $run.Output 'names the missing folder'
Assert-Equal $before (Get-Snapshot $r) 'missing ravintio-zero moves nothing'

Write-Host ""
Write-Host "=== (e) both override folders stop ==="
$r = New-Repo 'both'
New-Item -ItemType Directory -Path (Join-Path $r 'ravintio-overrides') | Out-Null
$before = Get-Snapshot $r
$run = Invoke-Helper $r -Expect 1
Assert-Equal 1 $run.Code 'both override folders exit 1'
Assert-Contains 'WARNING: Both' $run.Output 'prints the warning'
Assert-Equal $before (Get-Snapshot $r) 'both override folders move nothing'

Write-Host ""
Write-Host "=== (f) existing ravintio.yml stops before any move ==="
$r = New-Repo 'wf'
[System.IO.File]::WriteAllText((Join-Path $r '.github\workflows\ravintio.yml'), 'new', $utf8)
$before = Get-Snapshot $r
$run = Invoke-Helper $r -Expect 1
Assert-Equal 1 $run.Code 'existing ravintio.yml exits 1'
Assert-Contains 'ravintio.yml already exists' $run.Output 'names the existing workflow'
Assert-Equal $before (Get-Snapshot $r) 'existing ravintio.yml moves nothing'

Write-Host ""
Write-Host "=== (g) symlink refusal ==="
foreach ($name in @("$old-overrides", 'ravintio-overrides', "$old-zero", '.ravintio-backup')) {
    $r = New-Repo "link-$name"
    $target = Join-Path $scratch "target-$name"
    New-Item -ItemType Directory -Path $target | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $target 'keep.txt'), 'keep', $utf8)
    $link = Join-Path $r $name
    if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Recurse -Force }
    $made = $true
    try { New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null }
    catch { $made = $false }
    if (-not $made) {
        Write-Host "  SKIP: cannot create a symlink for $name on this host"
        continue
    }
    $before = Get-Snapshot $r
    $run = Invoke-Helper $r -Expect 1
    Assert-Equal 1 $run.Code "symlinked $name exits 1"
    Assert-Contains 'is a symlink' $run.Output "symlinked $name is named"
    Assert-Equal $before (Get-Snapshot $r) "symlinked $name moves nothing"
    Assert-True (Test-IsLink $link) "link $name still a link"
    Assert-Equal 'keep' (Read-Text (Join-Path $target 'keep.txt')) "target of $name untouched"
}

Write-Host ""
Write-Host "=== (h) a nested link in the old pack moves as a link ==="
$r = New-Repo 'nested-junction'
$outside = Join-Path $scratch 'outside-nested'
New-Item -ItemType Directory -Path $outside | Out-Null
[System.IO.File]::WriteAllText((Join-Path $outside 'keep.txt'), 'keep', $utf8)
if (-not (New-DirLink (Join-Path $r "$old-zero\nested") $outside)) {
    Write-Host "  SKIP: cannot create a junction or directory symlink on this host"
}
else {
    $run = Invoke-Helper $r
    Assert-Equal 0 $run.Code 'nested link run exits 0'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $r "$old-zero"))) 'old pack folder moved with its nested link'
    Assert-True (Test-IsLink (Join-Path $r ".ravintio-backup\$old-zero\nested")) 'nested link still a link in the backup'
    Assert-Equal 'keep' (Read-Text (Join-Path $outside 'keep.txt')) 'file behind the nested link survives'
}

Write-Host ""
Write-Host "=== (i) a workflow link stops before any move ==="
foreach ($wf in @("$old.yml", 'ravintio.yml')) {
    foreach ($kind in @('live', 'dangling')) {
        $r = New-Repo "wflink-$wf-$kind"
        $target = Join-Path $scratch "wftarget-$wf-$kind.yml"
        if ($kind -eq 'live') { [System.IO.File]::WriteAllText($target, "keep $old-zero/ x", $utf8) }
        $link = Join-Path $r ".github\workflows\$wf"
        if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Force }
        $made = $true
        try { New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null }
        catch { $made = $false }
        if (-not $made) {
            Write-Host "  SKIP: cannot create a $kind file symlink for $wf on this host"
            continue
        }
        $before = Get-Snapshot $r
        $run = Invoke-Helper $r -Expect 1
        Assert-Equal 1 $run.Code "$kind link at $wf exits 1"
        Assert-Contains 'is a symlink' $run.Output "$kind link at $wf is named"
        Assert-Equal $before (Get-Snapshot $r) "$kind link at $wf moves nothing"
        if ($kind -eq 'live') {
            Assert-Equal "keep $old-zero/ x" (Read-Text $target) "target of $wf untouched"
        }
    }
}

Write-Host ""
Write-Host "=== (j) a linked parent folder skips only the step that writes through it ==="
foreach ($parent in @('.claude', '.claude/skills', '.github', '.github/workflows', 'ravintio-zero', 'ravintio-zero/migrations')) {
    $slug = $parent.Replace('/', '-')
    $r = New-Repo "parent-$slug"
    $real = Join-Path $scratch "real-$slug"
    $here = Join-Path $r ($parent.Replace('/', '\'))
    Move-Item -LiteralPath $here -Destination $real
    if (-not (New-DirLink $here $real)) {
        Write-Host "  SKIP: cannot create a junction or directory symlink for $parent on this host"
        continue
    }
    $realBefore = Get-Snapshot $real
    $run = Invoke-Helper $r
    Assert-Equal 0 $run.Code "linked $parent exits 0"
    Assert-Contains "WARNING: $parent is a symlink" $run.Output "linked $parent is named in a warning"
    Assert-Equal $realBefore (Get-Snapshot $real) "target of $parent untouched"
    Assert-True (Test-Path -LiteralPath (Join-Path $r ".ravintio-backup\$old-zero\setup.sh") -PathType Leaf) "linked $parent still moves the old pack"
    Assert-Equal 'mine' (Read-Text (Join-Path $r 'ravintio-overrides\instructions\a.md')) "linked $parent still moves the overrides"
}

Write-Host ""
Write-Host "=== (k) a project below its git top level upgrades ==="
$inner = New-Repo 'inner'
Remove-Item -LiteralPath (Join-Path $inner '.git') -Recurse -Force
$outer = Join-Path $scratch 'outer'
New-Item -ItemType Directory -Path $outer | Out-Null
Move-Item -LiteralPath $inner -Destination (Join-Path $outer 'inner')
& git -C $outer init -q 2>&1 | Out-Null
& git -C $outer config user.email t@example.com
& git -C $outer config user.name t
& git -C $outer add -A 2>&1 | Out-Null
& git -C $outer commit -q -m init 2>&1 | Out-Null
$r = Join-Path $outer 'inner'
$run = Invoke-Helper $r -Ceiling $scratch
Assert-Equal 0 $run.Code 'run below the top level exits 0'
Assert-True (Test-Path -LiteralPath (Join-Path $r ".ravintio-backup\$old-zero\setup.sh") -PathType Leaf) 'nested project pack moved to the backup'
Assert-Equal 1 (Get-ExcludeCount (Join-Path $outer '.git')) 'nested project backup excluded in the outer repo'
Assert-Equal 0 (Get-BackupStatusCount $outer) 'nested project backup hidden from git status'

Write-Host ""
Write-Host "=== (l) a pack that git never tracked moves to the backup ==="
$r = New-Repo 'untracked-pack'
& git -C $r rm -rq --cached "$old-zero" 2>&1 | Out-Null
& git -C $r commit -q -m untrack 2>&1 | Out-Null
$run = Invoke-Helper $r
Assert-Equal 0 $run.Code 'untracked pack exits 0'
Assert-True (Test-Path -LiteralPath (Join-Path $r ".ravintio-backup\$old-zero\file.md") -PathType Leaf) 'untracked pack lands in the backup'

Write-Host ""
Write-Host "=== (m) a stray untracked file in the old pack moves with it ==="
$r = New-Repo 'stray'
[System.IO.File]::WriteAllText((Join-Path $r "$old-zero\.DS_Store"), 'x', $utf8)
$run = Invoke-Helper $r
Assert-Equal 0 $run.Code 'stray untracked file exits 0'
Assert-True (Test-Path -LiteralPath (Join-Path $r ".ravintio-backup\$old-zero\.DS_Store") -PathType Leaf) 'stray file lands in the backup'

Write-Host ""
Write-Host "=== (n) a folder outside git moves the pack and writes no exclude ==="
$r = New-Repo 'nogit'
Remove-Item -LiteralPath (Join-Path $r '.git') -Recurse -Force
[System.IO.File]::WriteAllText((Join-Path $r "$old-zero\custom.md"), 'mine', $utf8)
$run = Invoke-Helper $r
Assert-Equal 0 $run.Code 'folder outside git exits 0'
Assert-Equal 'mine' (Read-Text (Join-Path $r ".ravintio-backup\$old-zero\custom.md")) 'custom file kept in the backup outside git'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $r '.git'))) 'outside git writes no .git'

Write-Host ""
Write-Host "=== (o) an existing backup stops before any move ==="
$r = New-Repo 'backup-exists'
New-Item -ItemType Directory -Path (Join-Path $r ".ravintio-backup\$old-zero") -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $r ".ravintio-backup\$old-zero\old.md"), 'older', $utf8)
$before = Get-Snapshot $r
$run = Invoke-Helper $r -Expect 1
Assert-Equal 1 $run.Code 'existing backup exits 1'
Assert-Contains ".ravintio-backup/$old-zero already exists" $run.Output 'names the existing backup'
Assert-Equal $before (Get-Snapshot $r) 'existing backup moves nothing'

}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Complete-Suite
