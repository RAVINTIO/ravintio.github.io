# Tests for feature 0000036-test-runner-coverage, req-004: setup.ps1 flag
# handling at runtime. Retired flags exit 1 (0000196 ADR-002), and
# never print a --backend-url value. Flags and the tool name match case
# (0000035 ADR-003, S-008). Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

try {

$ws = New-SetupWorkspace

Write-Host ""
Write-Host "=== req-004 (f): retired flags exit 1 and name the flag ==="

foreach ($flag in @('--structured-telemetry-mcp', '--context-mode-mcp', '--include-full-skill-library')) {
    $run = Invoke-Setup $ws @('claude-code', $flag)
    Assert-Equal 1 $run.Code "req-004 (f): $flag exits 1"
    Assert-Contains "retired flag $flag" $run.Output "req-004 (f): $flag prints the retired-flag error"
}

foreach ($form in @(@('claude-code', '--backend-url', 'https://example.invalid/token-abc'), @('claude-code', '--backend-url=https://example.invalid/token-abc'))) {
    $run = Invoke-Setup $ws $form
    Assert-Equal 1 $run.Code "req-004 (f): $($form[1]) exits 1"
    Assert-True (-not $run.Output.Contains('token-abc')) "req-004 (f): $($form[1]) never prints the URL"
}

Write-Host ""
Write-Host "=== req-004 (g): flags and the tool name match case ==="

$run = Invoke-Setup $ws @('claude-code', '--Strict-Orchestrator')
Assert-Equal 1 $run.Code "req-004 (g): --Strict-Orchestrator exits 1"
Assert-Contains 'Unknown flag: --Strict-Orchestrator' $run.Output "req-004 (g): the error names the flag"
$run = Invoke-Setup $ws @('Claude-Code')
Assert-Equal 1 $run.Code "req-004 (g): the tool name Claude-Code exits 1"
$run = Invoke-Setup $ws @('//example.invalid/token-abc')
Assert-Equal 1 $run.Code "req-004 (g): a URL-shaped tool name exits 1"
Assert-True (-not $run.Output.Contains('token-abc')) "req-004 (g): a tool name that isn't a plain name is never printed (P5 S-003)"
$run = Invoke-Setup $ws @('claude-code', '--strict-orchestrator')
Assert-Equal 0 $run.Code "req-004 (g): --strict-orchestrator still works"

Remove-SetupWorkspace $ws
}
finally { Remove-AllWorkspaces }

Complete-Suite
