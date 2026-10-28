# Tests for feature 0000038-setup-hook-filter-fixes, req-001 and req-002, in
# setup.ps1 under whichever host runs this file.
# Setup removes RAVINTIO commands from PreToolUse and UserPromptSubmit
# entries one command at a time (ADR-002). A user command in a shared entry
# survives. The match is case-sensitive and needs <module>.mjs at a path
# boundary. The planted input and the expected result are the shared
# fixtures in fixtures/0000038-hook-filter/, which the setup.sh suite reads
# too.
# Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$fixtureDir = Join-Path $PSScriptRoot 'fixtures\0000038-hook-filter'

# Lists every hook command as "event|matcher|command". PreToolUse comes
# first, then UserPromptSubmit, then the other events in file order. An
# entry with no commands lists one line with an empty command. Reads each
# property directly, never through the pipeline, so Windows PowerShell 5.1
# can't unwrap a one-item array (R-001).
function Get-HookRender {
    param($Settings)
    $names = @('PreToolUse', 'UserPromptSubmit')
    foreach ($prop in $Settings.hooks.PSObject.Properties) {
        if ($prop.Name -cne 'PreToolUse' -and $prop.Name -cne 'UserPromptSubmit') { $names += $prop.Name }
    }
    $lines = @()
    foreach ($ev in $names) {
        $value = $Settings.hooks.$ev
        if ($null -eq $value) { continue }
        foreach ($entry in @($value)) {
            $cmds = $entry.hooks
            if (($cmds -is [array]) -and $cmds.Count -gt 0) {
                foreach ($hook in $cmds) { $lines += "$ev|$($entry.matcher)|$($hook.command)" }
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

$expectedText = [System.IO.File]::ReadAllText((Join-Path $fixtureDir 'expected-after.txt'))
$expected = ($expectedText -replace "`r`n", "`n").TrimEnd([char]10)
$expectedLines = $expected -split "`n"
$plantedJson = [System.IO.File]::ReadAllText((Join-Path $fixtureDir 'settings-before.json'))

try {

Write-Host ""
Write-Host "=== req-001 and req-002: planted shared entries ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws $plantedJson
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-001: setup.ps1 exits 0 on the planted settings"
if ($run.Code -ne 0) { Write-Host $run.Output }

$settings = Read-Settings $ws
$render = Get-HookRender $settings
$renderLines = $render -split "`n"

Assert-True ($renderLines -ccontains 'PreToolUse|Write|node tools/my-lint.mjs') "req-001 (a): the user command in the shared PreToolUse entry stays, with its matcher"
Assert-True ($renderLines -ccontains 'UserPromptSubmit|.*|node ./tools/notify.sh') "req-001 (a): the user command in the shared UserPromptSubmit entry stays, with its matcher"
Assert-True ($renderLines -ccontains 'PreToolUse|Bash|') "req-001 (a): the entry with no commands stays as it was"

foreach ($line in $expectedLines) {
    if ($line -notmatch 'enforcement/') { continue }
    $count = @($renderLines | Where-Object { $_ -ceq $line }).Count
    Assert-Equal 1 $count "req-001 (b): $line appears exactly once"
}
Assert-Equal 0 (@($renderLines | Where-Object { $_ -cmatch '^PreToolUse\|Write\|Edit\|' }).Count) "req-001 (b): the entry holding only RAVINTIO commands is gone"

Assert-True ($renderLines -ccontains 'UserPromptSubmit|.*|node ./tools/my-check-design-helper.sh') "req-002 (a): node ./tools/my-check-design-helper.sh survives"
Assert-True ($renderLines -ccontains 'UserPromptSubmit|.*|node ./tools/Check-Design.mjs') "req-002 (a): node ./tools/Check-Design.mjs survives"
Assert-True ($renderLines -ccontains 'PreToolUse|Edit|node tools/Gate-Write.mjs') "req-002 (a): the case-sensitive match keeps node tools/Gate-Write.mjs"
Assert-Equal 0 (@($renderLines | Where-Object { $_ -cmatch '^UserPromptSubmit\|.*\|node \.claude/hooks/enforcement/' }).Count) "req-002 (b): every unquoted UserPromptSubmit shape an earlier setup wrote is gone"

Assert-Equal $expected $render "req-002 (c): setup.ps1 gives exactly the entries in expected-after.txt"

Assert-Equal '1' "$($settings.keep)" "req-001 (a): the top-level keep key survives"

# R-001: Windows PowerShell 5.1 can unwrap a one-item array. The kept user
# command must still be a one-element array of objects.
$shared = @($settings.hooks.PreToolUse)[0]
$sharedHooks = $shared.hooks
Assert-True ($sharedHooks -is [array]) "req-001 (a): the shared PreToolUse entry's hooks is still an array"
Assert-Equal 1 (@($sharedHooks).Count) "req-001 (a): the shared PreToolUse entry holds one command"
Assert-True (@($sharedHooks)[0] -is [System.Management.Automation.PSCustomObject]) "req-001 (a): the kept command is an object, not unwrapped"
Assert-Equal 'node tools/my-lint.mjs' "$(@($sharedHooks)[0].command)" "req-001 (a): the kept command is the user command"

$firstRun = Get-FileBase64 (Get-SettingsPath $ws)
$run2 = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run2.Code "req-001 (c): the second setup.ps1 run exits 0"
if ($run2.Code -ne 0) { Write-Host $run2.Output }
Assert-Equal $firstRun (Get-FileBase64 (Get-SettingsPath $ws)) "req-001 (c): a second run gives a byte-identical settings.json"
Assert-Equal $expected (Get-HookRender (Read-Settings $ws)) "req-001 (c): the second run still gives the expected entries"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-001: an entry whose hooks is not an array ==="

# The entry stays as it was, even though it names a RAVINTIO module. A
# single-object hooks value now counts as a one-item array (0000039
# req-002), so this case plants a value that is neither an array nor an
# object.
$ws = New-SetupWorkspace
Write-SettingsText $ws '{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":"node .claude/hooks/enforcement/gate-write.mjs"}]}}'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-001: setup.ps1 exits 0 with a non-array hooks value"
if ($run.Code -ne 0) { Write-Host $run.Output }
$settings = Read-Settings $ws
$odd = @($settings.hooks.PreToolUse)[0]
Assert-Equal 'Write' "$($odd.matcher)" "req-001: the non-array entry stays first"
Assert-True ($odd.hooks -is [string]) "req-001: the non-array hooks value stays a string"
Assert-Equal 'node .claude/hooks/enforcement/gate-write.mjs' "$($odd.hooks)" "req-001: the non-array hooks value keeps its text"
Assert-Equal 8 (@($settings.hooks.PreToolUse).Count) "req-001: the seven fresh PreToolUse entries follow it"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
