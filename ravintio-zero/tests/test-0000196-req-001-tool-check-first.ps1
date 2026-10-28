# Tests for feature 0000196-setup-argument-checks, req-001: setup.ps1
# validates the tool straight after argument parsing. An unknown tool exits 1
# and leaves the repo unchanged. A missing tool keeps its usage text and
# exit 0. A valid tool still installs. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

# One string over every path outside .git and every file's hash, so an
# added, changed, or removed file changes it.
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

try {

Write-Host ""
Write-Host "=== req-001 AC-1: an unknown tool exits 1 and leaves the repo unchanged ==="

foreach ($tool in @('windsurf', 'cursor', 'open-code')) {
    $ws = New-SetupWorkspace
    $before = Get-TreeSnapshot $ws
    $run = Invoke-Setup $ws @($tool)
    Assert-Equal 1 $run.Code "req-001 AC-1: tool $tool exits 1"
    Assert-Contains "Unknown tool: $tool" $run.Output "req-001 AC-1: tool $tool prints the Unknown tool line"
    Assert-Contains 'Valid tools: claude-code, codex' $run.Output "req-001 AC-1: tool $tool prints the valid tools"
    Assert-True ($before -ceq (Get-TreeSnapshot $ws)) "req-001 AC-1: tool $tool leaves the tree unchanged"
    Assert-Equal '' (Get-HooksPath $ws) "req-001 AC-1: tool $tool leaves core.hooksPath unset"
    Remove-SetupWorkspace $ws
}

Write-Host ""
Write-Host "=== req-001 AC-1: an unknown tool beats the old-folder check ==="

$ws = New-SetupWorkspace
New-Item -ItemType Directory -Path (Join-Path $ws ('plan' + 'ifest-zero')) | Out-Null
$run = Invoke-Setup $ws @('windsurf')
Assert-Equal 1 $run.Code "req-001 AC-1: unknown tool with an old folder exits 1"
Assert-Contains 'Unknown tool: windsurf' $run.Output "req-001 AC-1: the tool error comes before the old-folder error"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-001 AC-2: a missing tool prints usage, exits 0, and changes nothing ==="

$ws = New-SetupWorkspace
$before = Get-TreeSnapshot $ws
$run = Invoke-Setup $ws @()
Assert-Equal 0 $run.Code "req-001 AC-2: no tool exits 0"
Assert-Contains 'Usage:' $run.Output "req-001 AC-2: no tool prints the usage text"
Assert-True ($before -ceq (Get-TreeSnapshot $ws)) "req-001 AC-2: no tool leaves the tree unchanged"
Assert-Equal '' (Get-HooksPath $ws) "req-001 AC-2: no tool leaves core.hooksPath unset"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-001 AC-3: a valid tool still installs ==="

$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-001 AC-3: claude-code exits 0"
Assert-Equal 'ravintio-zero/hooks' (Get-HooksPath $ws) "req-001 AC-3: core.hooksPath is ravintio-zero/hooks"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
