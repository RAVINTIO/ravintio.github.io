# Tests for feature 0000039-setup-hardening-release-sizing, req-001 to
# req-003, in setup.ps1 under whichever host runs this file.
# req-001: invalid JSON in settings.json stops the hook install step with one
# fixed error line, exit 1, no leaked content, and an unchanged file (ADR-002).
# req-002: a single-object hooks value counts as a one-item array before the
# per-command filter (ADR-003).
# req-003: settings.json writes use -Depth 100, so a value nested 15 levels
# deep survives.
# The planted input is the shared fixtures in
# fixtures/0000039-setup-hardening/, which the setup.sh suite reads too.
# Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$fixtureDir = Join-Path $PSScriptRoot 'fixtures\0000039-setup-hardening'
$planted = 'PLANTED-0000039-secret-value'
$expectedError = '! Error: .claude/settings.json is not valid JSON. Fix it and rerun setup.'

# Runs setup.ps1 in a child process of the same host and keeps stdout and
# stderr apart, so each stream can be checked on its own. Windows
# PowerShell 5.1 wraps redirected stderr in error records, so this reads
# the raw streams from the process instead.
function Invoke-SetupSplit {
    param([string]$Workspace, [string[]]$SetupArgs)
    $setup = Join-Path $Workspace 'ravintio-zero\setup.ps1'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $global:HostExe
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$setup`" " + ($SetupArgs -join ' ')
    $psi.WorkingDirectory = $Workspace
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['GIT_CEILING_DIRECTORIES'] = Split-Path -Parent $Workspace
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $err = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $out = $outTask.Result
    return [PSCustomObject]@{ Code = $proc.ExitCode; Stdout = $out; Stderr = $err }
}

# Lists every hook command as "event|matcher|command" for PreToolUse, then
# UserPromptSubmit. A single-object hooks value lists its one command with
# a "(object)" tag, so the test can tell it from a one-item array. Reads
# each property directly, never through the pipeline, so Windows
# PowerShell 5.1 can't unwrap a one-item array (R-001).
function Get-HookRender {
    param($Settings)
    $lines = @()
    foreach ($ev in @('PreToolUse', 'UserPromptSubmit')) {
        $value = $Settings.hooks.$ev
        if ($null -eq $value) { continue }
        foreach ($entry in @($value)) {
            $cmds = $entry.hooks
            if ($cmds -is [array]) {
                foreach ($hook in $cmds) { $lines += "$ev|$($entry.matcher)|$($hook.command)" }
            }
            elseif ($cmds -is [System.Management.Automation.PSCustomObject]) {
                $lines += "$ev|$($entry.matcher)|$($cmds.command) (object)"
            }
            else { $lines += "$ev|$($entry.matcher)|" }
        }
    }
    return ($lines -join "`n")
}

function Get-FileBase64 {
    param([string]$Path)
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

function Copy-FixtureToSettings {
    param([string]$Workspace, [string]$Name)
    [System.IO.File]::Copy((Join-Path $fixtureDir $Name), (Get-SettingsPath $Workspace), $true)
}

try {

Write-Host ""
Write-Host "=== req-001: invalid JSON in settings.json ==="

$ws = New-SetupWorkspace
Copy-FixtureToSettings $ws 'invalid-settings.json'
$before = Get-FileBase64 (Get-SettingsPath $ws)
$run = Invoke-SetupSplit $ws @('claude-code')

Assert-Equal 1 $run.Code "req-001 (a): setup.ps1 exits 1 on invalid JSON"
$allLines = @(($run.Stdout + "`n" + $run.Stderr) -split "`r?`n")
$errorLines = @($allLines | Where-Object { $_.Contains('! Error:') })
Assert-Equal 1 $errorLines.Count "req-001 (a): setup.ps1 prints exactly one error line"
if ($errorLines.Count -gt 0) {
    Assert-Equal $expectedError $errorLines[0].Trim() "req-001 (a): the error line is the fixed text naming .claude/settings.json"
}
Assert-Equal 1 (@($allLines | Where-Object { $_.Contains('is not valid JSON') }).Count) "req-001 (a): the invalid-JSON text appears once"
Assert-True (-not $run.Stdout.Contains($planted)) "req-001 (b): the planted value is absent from stdout"
Assert-True (-not $run.Stderr.Contains($planted)) "req-001 (b): the planted value is absent from stderr"
Assert-True (-not $run.Stderr.Contains('ConvertFrom-Json')) "req-001 (b): no parser exception text reaches stderr"
Assert-Equal $before (Get-FileBase64 (Get-SettingsPath $ws)) "req-001 (a): settings.json stays byte-identical"
Assert-True (-not (Test-Path -LiteralPath ((Get-SettingsPath $ws) + '.ravintio-tmp'))) "req-001 (a): no temporary file is left behind"
if ($run.Code -ne 1) { Write-Host $run.Stdout; Write-Host $run.Stderr }
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002: single-object hooks values ==="

$ws = New-SetupWorkspace
Copy-FixtureToSettings $ws 'single-object-hooks.json'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-002: setup.ps1 exits 0 on single-object hooks values"
if ($run.Code -ne 0) { Write-Host $run.Output }

$settings = Read-Settings $ws
$render = Get-HookRender $settings
$renderLines = @($render -split "`n")

Assert-True (-not ($renderLines -ccontains 'PreToolUse|Write|Edit|node ".claude/hooks/enforcement/gate-write.mjs" (object)')) "req-002 (a): the single-object RAVINTIO PreToolUse entry is gone"
Assert-True (-not ($renderLines -ccontains 'UserPromptSubmit|.*|node .claude/hooks/enforcement/check-design.mjs (object)')) "req-002 (a): the single-object RAVINTIO UserPromptSubmit entry is gone"
Assert-True ($renderLines -ccontains 'PreToolUse|Write|node tools/my-lint.mjs (object)') "req-002 (b): the single-object user PreToolUse entry stays as it was"
Assert-True ($renderLines -ccontains 'UserPromptSubmit|.*|node ./tools/notify.sh (object)') "req-002 (b): the single-object user UserPromptSubmit entry stays as it was"

foreach ($module in $global:RavintioModules) {
    $count = @($renderLines | Where-Object { $_.Contains("/$module.mjs") }).Count
    $expectedCount = 1
    if (@('gate-write', 'ratchet-check', 'em-dash-guard') -ccontains $module) { $expectedCount = 2 }
    Assert-Equal $expectedCount $count "req-002 (a): $module appears once per matcher"
}

# The exact result, which setup.sh gives on the same fixture too.
$expected = @(
    'PreToolUse|Write|node tools/my-lint.mjs (object)',
    'PreToolUse|Write|node ".claude/hooks/enforcement/gate-write.mjs"',
    'PreToolUse|Edit|node ".claude/hooks/enforcement/gate-write.mjs"',
    'PreToolUse|Write|node ".claude/hooks/enforcement/ratchet-check.mjs"',
    'PreToolUse|Edit|node ".claude/hooks/enforcement/ratchet-check.mjs"',
    'PreToolUse|Write|node ".claude/hooks/enforcement/em-dash-guard.mjs"',
    'PreToolUse|Edit|node ".claude/hooks/enforcement/em-dash-guard.mjs"',
    'PreToolUse|Bash|node ".claude/hooks/enforcement/merge-guard.mjs"',
    'UserPromptSubmit|.*|node ./tools/notify.sh (object)',
    'UserPromptSubmit|.*|node ".claude/hooks/enforcement/auto-trigger-orchestrator.mjs"',
    'UserPromptSubmit|.*|node ".claude/hooks/enforcement/check-orchestrator-presence.mjs"',
    'UserPromptSubmit|.*|node ".claude/hooks/enforcement/check-design.mjs"'
) -join "`n"
Assert-Equal $expected $render "req-002: setup.ps1 gives exactly the expected entries"

# R-001: the fresh entries still hold one-element arrays of objects.
$fresh = @($settings.hooks.PreToolUse)[1]
Assert-True ($fresh.hooks -is [array]) "req-002: a fresh entry's hooks is still an array"
Assert-Equal 1 (@($fresh.hooks).Count) "req-002: a fresh entry holds one command"

$firstRun = Get-FileBase64 (Get-SettingsPath $ws)
$run2 = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run2.Code "req-002: the second setup.ps1 run exits 0"
if ($run2.Code -ne 0) { Write-Host $run2.Output }
Assert-Equal $firstRun (Get-FileBase64 (Get-SettingsPath $ws)) "req-002: a second run gives a byte-identical settings.json"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002: a hooks value that is neither an array nor an object ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws '{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":"node .claude/hooks/enforcement/gate-write.mjs"}]}}'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-002: setup.ps1 exits 0 with a string hooks value"
if ($run.Code -ne 0) { Write-Host $run.Output }
$settings = Read-Settings $ws
$odd = @($settings.hooks.PreToolUse)[0]
Assert-Equal 'node .claude/hooks/enforcement/gate-write.mjs' "$($odd.hooks)" "req-002: the string hooks value stays as it was"
Assert-Equal 8 (@($settings.hooks.PreToolUse).Count) "req-002: the seven fresh PreToolUse entries follow it"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-003: a value nested 15 levels deep ==="

$ws = New-SetupWorkspace
Copy-FixtureToSettings $ws 'deep-settings.json'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-003: setup.ps1 exits 0 on deep settings"
if ($run.Code -ne 0) { Write-Host $run.Output }
$node = (Read-Settings $ws).custom
for ($level = 1; $level -le 14; $level++) {
    if ($null -eq $node) { break }
    $node = $node."level$level"
}
$leaf = $null
if ($null -ne $node) { $leaf = $node.level15 }
Assert-True ($leaf -is [string]) "req-003: the 15-level value is still a string"
Assert-Equal 'leaf-0000039' "$leaf" "req-003: leaf-0000039 survives at the same path"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-003: the non-array warning omits a deep old value ==="

$ws = New-SetupWorkspace
$deepValue = '"deep-warn-0000039"'
for ($level = 12; $level -ge 1; $level--) { $deepValue = '{"d' + $level + '":' + $deepValue + '}' }
Write-SettingsText $ws ('{"hooks":{"PreToolUse":' + $deepValue + '}}')
$run = Invoke-SetupSplit $ws @('claude-code')
Assert-Equal 0 $run.Code "req-003: setup.ps1 exits 0 with a deep non-array PreToolUse value"
if ($run.Code -ne 0) { Write-Host $run.Stdout; Write-Host $run.Stderr }
# The warning never prints the old value (0000041 ADR-003).
Assert-Contains "  ! Warning: hooks.PreToolUse in .claude/settings.json is not an array. Setup replaced it with the RAVINTIO entries." $run.Stderr "req-003: setup.ps1 warns about the deep PreToolUse value"
Assert-True (-not $run.Stderr.Contains('Old value')) "req-003: the warning prints no Old value"
Assert-True (-not ($run.Stdout + $run.Stderr).Contains('deep-warn-0000039')) "req-003: the 12-level old value stays out of the output"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
