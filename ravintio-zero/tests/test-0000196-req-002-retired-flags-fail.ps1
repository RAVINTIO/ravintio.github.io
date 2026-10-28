# Tests for feature 0000196-setup-argument-checks, req-002: setup.ps1 exits 1
# on a retired flag during argument parsing, names the flag, and leaves the
# repo unchanged. A --backend-url value never reaches the output. ADR-002
# reverses 0000034 ADR-001, which warned and carried on. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

function Get-TreeSnapshot {
    param([string]$Workspace)
    $root = (Resolve-Path -LiteralPath $Workspace).Path
    $gitDir = Join-Path $root '.git'
    $lines = foreach ($item in (Get-ChildItem -LiteralPath $root -Recurse -Force)) {
        if ($item.FullName -eq $gitDir -or $item.FullName.StartsWith($gitDir + [System.IO.Path]::DirectorySeparatorChar)) { continue }
        $rel = $item.FullName.Substring($root.Length)
        if ($item.PSIsContainer) { "D $rel" }
        else { "F $rel $((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)" }
    }
    return (($lines | Sort-Object) -join "`n")
}

function Get-HooksPath {
    param([string]$Workspace)
    $value = & git -C $Workspace config --get core.hooksPath 2>$null
    if ($null -eq $value) { return '' }
    return "$value"
}

$secret = 'https://retired-backend.invalid/token-abc'

try {

Write-Host ""
Write-Host "=== req-002 AC-1 and AC-2: each retired flag exits 1, is named, and changes nothing ==="

foreach ($flag in @('--structured-telemetry-mcp', '--context-mode-mcp', '--include-full-skill-library', '--backend-url')) {
    $ws = New-SetupWorkspace
    $before = Get-TreeSnapshot $ws
    $run = Invoke-Setup $ws @('claude-code', $flag)
    Assert-Equal 1 $run.Code "req-002 AC-1: $flag exits 1"
    Assert-Contains "retired flag $flag" $run.Output "req-002 AC-1: the error names $flag"
    Assert-Contains 'does nothing' $run.Output "req-002 AC-1: the error for $flag says it does nothing"
    Assert-Contains 'Remove it from the command' $run.Output "req-002 AC-1: the error for $flag says to remove it"
    Assert-True ($before -ceq (Get-TreeSnapshot $ws)) "req-002 AC-2: $flag leaves the tree unchanged"
    Assert-Equal '' (Get-HooksPath $ws) "req-002 AC-2: $flag leaves core.hooksPath unset"
    Remove-SetupWorkspace $ws
}

Write-Host ""
Write-Host "=== req-002 AC-1: a retired flag before the tool name still exits 1 ==="

$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('--context-mode-mcp', 'claude-code')
Assert-Equal 1 $run.Code "req-002 AC-1: a retired flag before the tool exits 1"
Assert-Contains 'retired flag --context-mode-mcp' $run.Output "req-002 AC-1: the error names the flag"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002 AC-3: a --backend-url value stays out of the output ==="

foreach ($form in @(@('claude-code', '--backend-url', $secret), @('claude-code', "--backend-url=$secret"))) {
    $ws = New-SetupWorkspace
    $before = Get-TreeSnapshot $ws
    $run = Invoke-Setup $ws $form
    Assert-Equal 1 $run.Code "req-002 AC-3: $($form[1]) exits 1"
    Assert-Contains 'retired flag --backend-url' $run.Output "req-002 AC-3: $($form[1]) names --backend-url"
    Assert-True (-not $run.Output.Contains('token-abc')) "req-002 AC-3: $($form[1]) never prints the value"
    Assert-True ($before -ceq (Get-TreeSnapshot $ws)) "req-002 AC-3: $($form[1]) leaves the tree unchanged"
    Remove-SetupWorkspace $ws
}

Write-Host ""
Write-Host "=== req-002: an unknown flag still exits 1 and --strict-orchestrator still works ==="

$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code', '--bogus')
Assert-Equal 1 $run.Code "req-002: --bogus exits 1"
Assert-Contains 'Unknown flag: --bogus' $run.Output "req-002: --bogus prints Unknown flag"
$run = Invoke-Setup $ws @('claude-code', '--strict-orchestrator')
Assert-Equal 0 $run.Code "req-002: --strict-orchestrator exits 0"
Assert-True (Test-Path -LiteralPath (Join-Path $ws 'plan\.orchestrator-strict')) "req-002: --strict-orchestrator writes the sentinel"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
