# Tests for feature 0000151-hardening-efficiency-and-ci, req-005, in
# setup.ps1 under whichever host runs this file. A read-only settings.json
# stops setup with one fixed line that names the relative path, exit 1, and
# no absolute path in the output. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$expectedError = '! Error: .claude/settings.json could not be written. Fix its permissions and rerun setup.'

# Runs setup.ps1 in a child process of the same host and keeps stdout and
# stderr apart. Windows PowerShell 5.1 wraps redirected stderr in error
# records, so this reads the raw streams from the process instead.
function Invoke-SetupSplit {
    param([string]$Workspace, [string[]]$SetupArgs)
    $setup = Join-Path $Workspace 'ravintio-zero\setup.ps1'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $global:HostExe
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$setup`" " + ($SetupArgs -join ' ')
    $psi.WorkingDirectory = $Workspace
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['GIT_CEILING_DIRECTORIES'] = Split-Path -Parent $Workspace
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $err = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $out = $outTask.Result
    return [PSCustomObject]@{ Code = $proc.ExitCode; Stdout = $out; Stderr = $err }
}

function Get-FileBase64 {
    param([string]$Path)
    return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
}

try {

Write-Host ""
Write-Host "=== req-005 (b): a read-only settings.json ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws '{"allowedTools":["Agent"]}'
$path = Get-SettingsPath $ws
$before = Get-FileBase64 $path
Set-ItemProperty -LiteralPath $path -Name IsReadOnly -Value $true
$run = Invoke-SetupSplit $ws @('claude-code')
Set-ItemProperty -LiteralPath $path -Name IsReadOnly -Value $false
Assert-Equal 1 $run.Code "req-005 (b): setup.ps1 exits 1"
$stderrLines = @($run.Stderr -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
Assert-True ($stderrLines -ccontains $expectedError) "req-005 (b): stderr holds the fixed line"
Assert-Equal 1 $stderrLines.Count "req-005 (b): stderr holds no other line"
$all = $run.Stdout + $run.Stderr
Assert-True (-not $all.Contains($ws)) "req-005 (b): no absolute path in the output"
Assert-True (-not $all.Contains('read-only: ')) "req-005 (b): no raw PowerShell error text in the output"
Assert-Equal $before (Get-FileBase64 $path) "req-005 (b): the file bytes are unchanged"
Assert-True (-not (Test-Path -LiteralPath ($path + '.ravintio-tmp'))) "req-005 (b): no temporary file is left"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
