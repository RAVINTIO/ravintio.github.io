# Tests for feature 0000169-release-hygiene, req-004, in setup.ps1 under
# whichever host runs this file. Setup sets attribution to empty commit and pr
# strings when the key is absent, leaves a present key byte-identical, and a
# rerun changes nothing. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

function Get-FileBase64 {
    param([string]$Path)
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

# Returns the attribution value as compact JSON, or 'absent'.
function Get-AttributionText {
    param([string]$Workspace)
    $settings = Read-Settings $Workspace
    if (-not $settings.PSObject.Properties['attribution']) { return 'absent' }
    return ($settings.attribution | ConvertTo-Json -Compress)
}

try {

Write-Host ""
Write-Host "=== req-004 (a): an absent key gets the empty strings ==="
$ws = New-SetupWorkspace
Write-SettingsText $ws '{"allowedTools":["Read"]}'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (a): setup.ps1 exits 0"
Assert-Equal '{"commit":"","pr":""}' (Get-AttributionText $ws) "req-004 (a): attribution holds empty commit and pr"
Assert-True ((Read-Settings $ws).allowedTools -ccontains 'Read') "req-004 (a): other settings are kept"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004 (b): no settings file gets the empty strings ==="
$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (b): setup.ps1 exits 0"
Assert-Equal '{"commit":"","pr":""}' (Get-AttributionText $ws) "req-004 (b): attribution holds empty commit and pr"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004 (c): a present key stays byte-identical ==="
foreach ($value in @('{"commit":"x","pr":"y"}', '{}', '"text"', '7')) {
    $ws = New-SetupWorkspace
    Write-SettingsText $ws ('{"attribution":' + $value + ',"allowedTools":["Agent"]}')
    $run = Invoke-Setup $ws @('claude-code')
    Assert-Equal 0 $run.Code "req-004 (c): setup.ps1 exits 0 for $value"
    Assert-Equal ($value | ConvertFrom-Json | ConvertTo-Json -Compress) (Get-AttributionText $ws) "req-004 (c): attribution $value is untouched"
    $before = Get-FileBase64 (Get-SettingsPath $ws)
    $null = Invoke-Setup $ws @('claude-code')
    Assert-Equal $before (Get-FileBase64 (Get-SettingsPath $ws)) "req-004 (c): $value rerun is byte-identical"
    Remove-SetupWorkspace $ws
}

Write-Host ""
Write-Host "=== req-004 (d): a rerun changes nothing ==="
$ws = New-SetupWorkspace
$null = Invoke-Setup $ws @('claude-code')
$before = Get-FileBase64 (Get-SettingsPath $ws)
$null = Invoke-Setup $ws @('claude-code')
Assert-Equal $before (Get-FileBase64 (Get-SettingsPath $ws)) "req-004 (d): second run is byte-identical"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
