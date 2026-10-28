# Tests for feature 0000037-self-host-on-planifest-zero, req-008: a
# non-array PreToolUse or UserPromptSubmit value in setup.ps1, under
# whichever host runs this file.
# If the value is present and isn't an array, setup.ps1 warns on stderr,
# replaces it with the RAVINTIO entries, and exits 0 (ADR-003). The warning
# matches the setup.sh text and omits the old value (0000041 ADR-003). An
# absent or null value gets no warning.
# Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$expected = @{
    PreToolUse       = @('Write gate-write', 'Edit gate-write', 'Write ratchet-check',
                         'Edit ratchet-check', 'Write em-dash-guard', 'Edit em-dash-guard',
                         'Bash merge-guard') -join "`n"
    UserPromptSubmit = @('.* auto-trigger-orchestrator', '.* check-orchestrator-presence',
                         '.* check-design') -join "`n"
}

# Lists "matcher module" for each entry of one event. A non-array value
# lists "not-array". Reads the property directly, never through the pipeline.
function Get-EventEntries {
    param($Settings, [string]$EventName)
    $value = $Settings.hooks.$EventName
    if (-not ($value -is [array])) { return 'not-array' }
    $lines = @()
    foreach ($entry in $value) {
        $cmds = (@($entry.hooks) | ForEach-Object { "$($_.command)" }) -join ' '
        if ($cmds -match '([A-Za-z0-9-]+)\.mjs') { $lines += "$($entry.matcher) $($Matches[1])" }
        else { $lines += "$($entry.matcher) $cmds" }
    }
    return ($lines -join "`n")
}

# The console host can wrap long stderr lines, so compare with line breaks
# removed.
function Get-FlatText {
    param([string]$Text)
    return ($Text -replace '\r?\n', '')
}

$values = @(
    '{"matcher":"Write","hooks":[{"type":"command","command":"node tools/my-check.mjs"}]}',
    '"broken"', '""', '0', 'false'
)

try {

foreach ($ev in @('PreToolUse', 'UserPromptSubmit')) {
    if ($ev -eq 'PreToolUse') { $other = 'UserPromptSubmit' } else { $other = 'PreToolUse' }
    foreach ($val in $values) {
        Write-Host ""
        Write-Host "=== req-008: $ev holds $val ==="

        $ws = New-SetupWorkspace
        Write-SettingsText $ws ('{"keep":1,"hooks":{"Notification":"keep-me","' + $ev + '":' + $val + '}}')
        $run = Invoke-Setup $ws @('claude-code')
        Assert-Equal 0 $run.Code "req-008: setup.ps1 exits 0 with $ev set to $val"
        if ($run.Code -ne 0) { Write-Host $run.Output }
        $warning = "  ! Warning: hooks.$ev in .claude/settings.json is not an array. Setup replaced it with the RAVINTIO entries."
        Assert-Contains (Get-FlatText $warning) (Get-FlatText $run.Output) "req-008: setup.ps1 warns about $ev"
        # The warning never prints the old value (0000041 ADR-003).
        Assert-True (-not (Get-FlatText $run.Output).Contains('Old value')) "req-008: setup.ps1 never prints the old $ev value"
        $settings = Read-Settings $ws
        Assert-Equal $expected[$ev] (Get-EventEntries $settings $ev) "req-008: $ev is an array of only the RAVINTIO entries"
        Assert-Equal $expected[$other] (Get-EventEntries $settings $other) "req-008: $other still gets the RAVINTIO entries"
        Assert-Equal '1 keep-me' "$($settings.keep) $($settings.hooks.Notification)" "req-008: other keys and events stay as they were"
        Remove-SetupWorkspace $ws
    }
}

foreach ($case in @('absent', 'null')) {
    Write-Host ""
    Write-Host "=== req-008: both events are $case ==="

    $ws = New-SetupWorkspace
    if ($case -eq 'absent') { Write-SettingsText $ws '{"hooks":{}}' }
    else { Write-SettingsText $ws '{"hooks":{"PreToolUse":null,"UserPromptSubmit":null}}' }
    $run = Invoke-Setup $ws @('claude-code')
    Assert-Equal 0 $run.Code "req-008: setup.ps1 exits 0 when both events are $case"
    Assert-True (-not $run.Output.Contains('is not an array')) "req-008: setup.ps1 prints no warning when both events are $case"
    $settings = Read-Settings $ws
    foreach ($ev in @('PreToolUse', 'UserPromptSubmit')) {
        Assert-Equal $expected[$ev] (Get-EventEntries $settings $ev) "req-008: $ev gets the RAVINTIO entries when it is $case"
    }
    Remove-SetupWorkspace $ws
}

}
finally { Remove-AllWorkspaces }

Complete-Suite
