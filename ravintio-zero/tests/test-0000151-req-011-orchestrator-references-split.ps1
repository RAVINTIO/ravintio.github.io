# Tests for feature 0000151-hardening-efficiency-and-ci, req-011, in
# setup.ps1 under whichever host runs this file. Setup installs every
# orchestrator reference file under the installed skill's references folder,
# and the Pack Index lists each one. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$skillDir = Join-Path $global:ZeroDir 'skills\ravintio-orchestrator'
$refFiles = @(Get-ChildItem -LiteralPath (Join-Path $skillDir 'references') -Filter 'orchestrator-*.md')

try {

Write-Host ""
Write-Host "=== req-011 (b): the Pack Index lists every reference file ==="

$skillText = [System.IO.File]::ReadAllText((Join-Path $skillDir 'SKILL.md'))
Assert-True ($refFiles.Count -ge 6) "req-011 (b): at least six reference files exist"
foreach ($f in $refFiles) {
    Assert-True ($skillText.Contains("references/$($f.Name)")) "req-011 (b): Pack Index has a row for $($f.Name)"
}
# A Windows checkout may convert line endings to CRLF, so count the bytes
# with LF endings, as the repository stores them.
$skillText = [IO.File]::ReadAllText((Join-Path $skillDir 'SKILL.md')) -replace "`r`n", "`n"
Assert-True ([Text.Encoding]::UTF8.GetByteCount($skillText) -le 9000) "req-011 (a): SKILL.md is 9000 bytes or fewer"

Write-Host ""
Write-Host "=== req-011 (c): setup installs the reference files ==="

$ws = New-SetupWorkspace
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-011 (c): setup exits 0"
$installed = Join-Path $ws '.claude\skills\ravintio-orchestrator\references'
foreach ($f in $refFiles) {
    $target = Join-Path $installed $f.Name
    Assert-True (Test-Path -LiteralPath $target) "req-011 (c): $($f.Name) is installed"
    if (Test-Path -LiteralPath $target) {
        Assert-Equal ([System.IO.File]::ReadAllText($f.FullName)) ([System.IO.File]::ReadAllText($target)) "req-011 (c): installed $($f.Name) matches the source"
    }
}
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
