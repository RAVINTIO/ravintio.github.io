# Tests for feature 0000160-ravintio-rebrand, req-002, in setup.ps1 under
# whichever host runs this file. Setup writes the .ravintio-* markers, removes
# the old markers, sets core.hooksPath, and stops with a migration message when
# an old-brand folder is still present (ADR-003). Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')


try {

Write-Host ""
Write-Host "=== req-002: setup.ps1 writes ravintio markers and clears old ones ==="

$ws = New-SetupWorkspace
$skills = Join-Path $ws '.claude\skills'
New-Item -ItemType Directory -Path $skills -Force | Out-Null
Set-Content -LiteralPath (Join-Path $ws ".claude\.planifest-setup-flags") -Value '{}'
Set-Content -LiteralPath (Join-Path $skills ".planifest-manifest") -Value '[]'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-002: setup exits 0"
Assert-True (Test-Path -LiteralPath (Join-Path $ws '.claude\.ravintio-setup-flags')) "req-002: .ravintio-setup-flags is written"
Assert-True (Test-Path -LiteralPath (Join-Path $skills '.ravintio-manifest')) "req-002: .ravintio-manifest is written"
Assert-True (-not (Test-Path -LiteralPath (Join-Path $ws ".claude\.planifest-setup-flags"))) "req-002: old setup-flags marker is removed"
Assert-True (-not (Test-Path -LiteralPath (Join-Path $skills ".planifest-manifest"))) "req-002: old manifest marker is removed"
$hooksPath = (& git -C $ws config core.hooksPath 2>&1 | Out-String).Trim()
Assert-Equal 'ravintio-zero/hooks' $hooksPath "req-002: core.hooksPath is ravintio-zero/hooks"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002: setup.ps1 stops on a leftover old folder ==="

foreach ($folder in @("planifest-zero", "planifest-overrides")) {
    $ws = New-SetupWorkspace
    New-Item -ItemType Directory -Path (Join-Path $ws $folder) | Out-Null
    $run = Invoke-Setup $ws @('claude-code')
    Assert-True ($run.Code -ne 0) "req-002: setup exits non-zero when $folder exists"
    Assert-Contains $folder $run.Output "req-002: message names $folder"
    Assert-Contains 'migrate-ravintio-rename.ps1' $run.Output "req-002: message names the migration script ($folder)"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $ws '.claude\.ravintio-setup-flags'))) "req-002: nothing is installed ($folder)"
    Remove-SetupWorkspace $ws
}

}
finally { Remove-AllWorkspaces }

Complete-Suite
