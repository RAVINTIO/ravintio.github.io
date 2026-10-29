# Tests for feature 0000151-hardening-efficiency-and-ci, req-004, in
# setup.ps1 under whichever host runs this file. Setup deletes installed
# hooks named on the retired list, keeps every other hook, and leaves no
# settings.json entry that names a pruned file. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$retired = @('phase-enum', 'check-telemetry-failures', 'check-telemetry-receipts')

function Get-RemovalLines {
    param([string]$Output)
    return @($Output -split "`r?`n" | Where-Object { $_.Contains('- removed .claude/hooks/') })
}

try {

Write-Host ""
Write-Host "=== req-004 (a): setup prunes the retired hooks ==="

$ws = New-SetupWorkspace
$hooks = Join-Path $ws '.claude\hooks\enforcement'
New-Item -ItemType Directory -Path $hooks -Force | Out-Null
foreach ($n in $retired) { Set-Content -LiteralPath (Join-Path $hooks "$n.mjs") -Value '// stale' }
Set-Content -LiteralPath (Join-Path $hooks 'custom-local-hook.mjs') -Value '// mine'
$stale = '{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"node \".claude/hooks/enforcement/phase-enum.mjs\""}]}]}}'
Write-SettingsText $ws $stale
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (a): first run exits 0"
foreach ($n in $retired) {
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $hooks "$n.mjs"))) "req-004 (a): $n.mjs is deleted"
    Assert-Contains "  - removed .claude/hooks/enforcement/$n.mjs" $run.Output "req-004 (a): removal line for $n.mjs"
}
Assert-Equal 3 (Get-RemovalLines $run.Output).Count "req-004 (a): exactly three removal lines"
Assert-Contains "  - removed retired hook entry phase-enum from .claude/settings.json" $run.Output "S-005: settings.json removal line for phase-enum"
Assert-Equal 1 @($run.Output -split "`r?`n" | Where-Object { $_.Contains('- removed retired hook entry') }).Count "S-005: only the entry that existed is named"

Write-Host ""
Write-Host "=== req-004 (b): other hooks and settings entries ==="

Assert-True (Test-Path -LiteralPath (Join-Path $hooks 'custom-local-hook.mjs')) "req-004 (b): custom-local-hook.mjs survives"
foreach ($f in Get-ChildItem -LiteralPath (Join-Path $global:ZeroDir 'hooks\enforcement') -Filter '*.mjs') {
    Assert-True (Test-Path -LiteralPath (Join-Path $hooks $f.Name)) "req-004 (b): shipped hook $($f.Name) is present"
    Assert-True (-not $run.Output.Contains("- removed .claude/hooks/enforcement/$($f.Name)")) "req-004 (b): shipped hook $($f.Name) is not in a removal line"
}
$settingsText = [System.IO.File]::ReadAllText((Get-SettingsPath $ws))
foreach ($n in $retired) {
    Assert-True (-not $settingsText.Contains($n)) "req-004 (b): settings.json holds no $n entry"
}

Write-Host ""
Write-Host "=== req-004 (a): a second run prints no removal line ==="

$run2 = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run2.Code "req-004 (a): second run exits 0"
Assert-Equal 0 (Get-RemovalLines $run2.Output).Count "req-004 (a): second run prints no removal line"
Assert-Equal 0 @($run2.Output -split "`r?`n" | Where-Object { $_.Contains('- removed retired hook entry') }).Count "S-005: second run prints no settings.json removal line"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004: both retired lists hold phase-enum ==="

$shText = [System.IO.File]::ReadAllText((Join-Path $global:ZeroDir 'setup.sh'))
$ps1Text = [System.IO.File]::ReadAllText((Join-Path $global:ZeroDir 'setup.ps1'))
Assert-True ($shText -match '(?m)^RETIRED_HOOK_NAMES=.*phase-enum') "req-004: setup.sh list has phase-enum"
Assert-True ($ps1Text -match '(?s)\$RetiredHookNames = @\(.*''phase-enum''') "req-004: setup.ps1 list has phase-enum"

}
finally { Remove-AllWorkspaces }

Complete-Suite
