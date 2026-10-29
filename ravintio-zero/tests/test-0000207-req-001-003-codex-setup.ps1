# Tests for feature 0000207-codex-support, req-001 to req-004: setup.ps1
# installs the pack for the codex tool. It writes AGENTS.md, installs skills
# in .agents\skills, wires merge-guard in .codex\hooks.json, and reports the
# active and fallback hooks. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

function Get-MergeGuardCount {
    param([string]$Path)
    $json = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    $n = 0
    foreach ($group in @($json.hooks.PreToolUse)) {
        foreach ($hook in @($group.hooks)) {
            if ("$($hook.command)" -match 'merge-guard\.mjs' -and $group.matcher -ceq 'Bash') { $n++ }
        }
    }
    return $n
}

try {

Write-Host ""
Write-Host "=== req-001 to req-003: setup codex ==="

$ws = New-SetupWorkspace
# The workspace helper makes .claude for the Claude Code suites.
Remove-Item -LiteralPath (Join-Path $ws '.claude') -Recurse -Force
New-Item -ItemType Directory -Path (Join-Path $ws 'ravintio-overrides\instructions') -Force | Out-Null
Set-Content -Path (Join-Path $ws 'ravintio-overrides\instructions\custom-001-test.md') -Value 'Local rule for the test.'
$run = Invoke-Setup $ws @('codex')
Assert-Equal 0 $run.Code "req-001 AC-1: setup codex exits 0"
Assert-True (Test-Path (Join-Path $ws 'plan\state\codex.md')) "req-001 AC-1: plan/state/codex.md is written"
$boot = Get-Content -Raw -Path (Join-Path $ws 'AGENTS.md')
Assert-Contains 'No code without a confirmed design' $boot "req-002 AC-1: AGENTS.md holds the hard limits"
Assert-Contains 'ravintio-overrides:instructions:start' $boot "req-002 AC-1: AGENTS.md holds the override instructions"
Assert-Contains 'gate-write' (Get-Content -Raw (Join-Path $ws 'ravintio-zero/standards/hook-enforcement.md')) "req-003: the hook reference states the gate-write fallback"
Assert-True (Test-Path (Join-Path $ws '.agents\skills\ravintio-orchestrator\SKILL.md')) "req-002 AC-2: the orchestrator skill is installed"
Assert-True (Test-Path (Join-Path $ws '.agents\skills\.ravintio-manifest')) "req-002 AC-2: the manifest is written"
Assert-True (-not (Test-Path (Join-Path $ws 'CLAUDE.md'))) "req-002 AC-3: CLAUDE.md is absent"
Assert-True (-not (Test-Path (Join-Path $ws '.claude'))) "req-002 AC-3: .claude is absent"
$hooksFile = Join-Path $ws '.codex\hooks.json'
Assert-Equal 1 (Get-MergeGuardCount $hooksFile) "req-003 AC-1: hooks.json holds one merge-guard Bash entry"
Assert-True (Test-Path (Join-Path $ws '.codex\hooks\enforcement\merge-guard.mjs')) "req-003 AC-1: merge-guard.mjs is copied"
Assert-True (Test-Path (Join-Path $ws '.codex\hooks\enforcement\read-stdin.mjs')) "req-003 AC-1: read-stdin.mjs is copied"
Assert-True (-not (Test-Path (Join-Path $ws '.codex\hooks\enforcement\gate-write.mjs'))) "req-003 AC-1: gate-write.mjs is not copied"
Assert-Contains 'Active hooks' $run.Output "req-003 AC-2: the report has an active list"
Assert-Contains 'Fallback hooks' $run.Output "req-003 AC-2: the report has a fallback list"
Assert-Contains '/hooks' $run.Output "req-003 AC-2: the report names the /hooks review"
# 0000217: real Codex 0.163.0 skips project hooks until a person trusts them.
Assert-Contains 'Until you trust it, Codex skips merge-guard' $run.Output "0000217: the report says merge-guard is off until trusted"
Assert-Contains 'nothing blocks a merge' (Get-Content -Raw (Join-Path $ws 'ravintio-zero/standards/hook-enforcement.md')) "0000217: the hook reference says nothing blocks a merge until the hook is trusted"

Write-Host ""
Write-Host "=== req-003 AC-1: a rerun keeps one entry and other entries ==="

$obj = [System.IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json
$obj.hooks.PreToolUse = @($obj.hooks.PreToolUse) + @([PSCustomObject]@{ matcher = 'Bash'; hooks = @([PSCustomObject]@{ type = 'command'; command = 'echo user-hook' }) })
$obj | Add-Member -NotePropertyName 'custom' -NotePropertyValue $true -Force
[System.IO.File]::WriteAllText($hooksFile, ($obj | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
$run = Invoke-Setup $ws @('codex')
Assert-Equal 0 $run.Code "req-003 AC-1: the rerun exits 0"
Assert-Equal 1 (Get-MergeGuardCount $hooksFile) "req-003 AC-1: the rerun leaves one merge-guard entry"
$text = [System.IO.File]::ReadAllText($hooksFile)
Assert-Contains 'user-hook' $text "req-003 AC-1: the rerun keeps the user's hook"
Assert-Contains '"custom"' $text "req-003 AC-1: the rerun keeps other keys"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-003 AC-3: invalid hooks.json stops setup ==="

$ws = New-SetupWorkspace
New-Item -ItemType Directory -Path (Join-Path $ws '.codex') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $ws '.codex\hooks.json'), '{ not json', (New-Object System.Text.UTF8Encoding $false))
$run = Invoke-Setup $ws @('codex')
Assert-Equal 1 $run.Code "req-003 AC-3: invalid JSON exits 1"
Assert-Contains '.codex/hooks.json is not valid JSON' $run.Output "req-003 AC-3: the fixed error line is printed"
Assert-Equal '{ not json' ([System.IO.File]::ReadAllText((Join-Path $ws '.codex\hooks.json'))) "req-003 AC-3: the file is unchanged"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004 AC-3: claude-code is unchanged ==="

$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 AC-3: claude-code exits 0"
Assert-True (Test-Path (Join-Path $ws 'CLAUDE.md')) "req-004 AC-3: CLAUDE.md exists"
Assert-True (Test-Path (Join-Path $ws '.claude\settings.json')) "req-004 AC-3: .claude/settings.json exists"
Assert-True (-not (Test-Path (Join-Path $ws 'AGENTS.md'))) "req-004 AC-3: AGENTS.md is absent"
Assert-True (-not (Test-Path (Join-Path $ws '.codex'))) "req-004 AC-3: .codex is absent"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
