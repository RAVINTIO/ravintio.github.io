# Tests for feature 0000171-faster-setup-ps1-tests, req-003: run-tests.ps1
# prints one setup.ps1 timing total, and Invoke-Setup feeds it through the
# file named in RAVINTIO_TIMING_FILE (ADR-003). Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$hostExe = (Get-Process -Id $PID).Path
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ravintio-0000171-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$savedTimingFile = $env:RAVINTIO_TIMING_FILE
$savedQuiet = $env:RAVINTIO_TEST_QUIET

# Copies the real runner into a fresh folder holding the given stub suites.
# Each stub is a name and a script body. Returns the runner path.
function New-StubFolder([string]$Name, [hashtable]$Stubs) {
    $dir = Join-Path $tmp $Name
    New-Item -ItemType Directory -Path $dir | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'run-tests.ps1') -Destination $dir
    foreach ($key in $Stubs.Keys) {
        Set-Content -LiteralPath (Join-Path $dir $key) -Value $Stubs[$key] -Encoding ASCII
    }
    return (Join-Path $dir 'run-tests.ps1')
}

function Invoke-Runner([string]$Runner, [string]$Quiet) {
    if ($Quiet -eq '1') { $env:RAVINTIO_TEST_QUIET = '1' } else { Remove-Item Env:RAVINTIO_TEST_QUIET -ErrorAction SilentlyContinue }
    $out = (& $hostExe -NoProfile -ExecutionPolicy Bypass -File $Runner 2>&1 | Out-String)
    $code = $LASTEXITCODE
    Remove-Item Env:RAVINTIO_TEST_QUIET -ErrorAction SilentlyContinue
    return [PSCustomObject]@{ Code = $code; Out = $out }
}

function Add-TimingValue([string]$Value) {
    return "[System.IO.File]::AppendAllText(`$env:RAVINTIO_TIMING_FILE, '$Value' + [Environment]::NewLine)"
}

try {
    Write-Host ""
    Write-Host "=== req-003 AC-1: runner prints the total ==="
    $runner = New-StubFolder 'ac1' @{
        'test-a.ps1' = (Add-TimingValue '100')
        'test-b.ps1' = (Add-TimingValue '250')
    }
    foreach ($quiet in @('0', '1')) {
        $r = Invoke-Runner $runner $quiet
        Assert-Equal 0 $r.Code "AC-1 (quiet=$quiet): runner exits 0"
        Assert-Contains '[timing] setup.ps1 total: 350 ms over 2 cases' $r.Out "AC-1 (quiet=$quiet): total line sums both values"
        Assert-True ($r.Out.IndexOf('[timing] setup.ps1 total:') -lt $r.Out.IndexOf('PowerShell suites:')) "AC-1 (quiet=$quiet): total comes before the summary"
    }

    $runner = New-StubFolder 'ac1-empty' @{ 'test-a.ps1' = 'exit 0' }
    $r = Invoke-Runner $runner '0'
    Assert-Contains '[timing] setup.ps1 total: 0 ms over 0 cases' $r.Out 'AC-1: no values gives 0 ms over 0 cases'

    Write-Host ""
    Write-Host "=== req-003 AC-2: Invoke-Setup appends one line per run ==="
    $timingFile = Join-Path $tmp 'ac2-timing.txt'
    [System.IO.File]::WriteAllText($timingFile, '')
    $env:RAVINTIO_TIMING_FILE = $timingFile
    $ws = New-SetupWorkspace
    Invoke-Setup $ws @('claude-code') | Out-Null
    Invoke-Setup $ws @('claude-code') | Out-Null
    $lines = @([System.IO.File]::ReadAllLines($timingFile))
    Assert-Equal 2 $lines.Count 'AC-2: two runs append two lines'
    foreach ($line in $lines) {
        Assert-True ($line -match '^\d+$') "AC-2: line '$line' is a whole number"
    }

    Remove-Item Env:RAVINTIO_TIMING_FILE -ErrorAction SilentlyContinue
    Invoke-Setup $ws @('claude-code') | Out-Null
    Assert-Equal 2 @([System.IO.File]::ReadAllLines($timingFile)).Count 'AC-2: unset variable appends nothing'

    Write-Host ""
    Write-Host "=== req-003 AC-3: timing file cleaned up ==="
    $sideFile = Join-Path $tmp 'ac3-path.txt'
    $runner = New-StubFolder 'ac3' @{
        'test-fail.ps1' = "[System.IO.File]::WriteAllText('$sideFile', `$env:RAVINTIO_TIMING_FILE)`nexit 1"
    }
    $r = Invoke-Runner $runner '0'
    Assert-Equal 1 $r.Code 'AC-3: failing suite makes the runner exit 1'
    Assert-True (Test-Path -LiteralPath $sideFile) 'AC-3: stub suite saw a timing file path'
    $named = if (Test-Path -LiteralPath $sideFile) { [System.IO.File]::ReadAllText($sideFile) } else { '' }
    Assert-True ($named.Length -gt 0) 'AC-3: the path is not empty'
    Assert-True (-not (Test-Path -LiteralPath $named)) 'AC-3: the timing file no longer exists'
}
finally {
    $env:RAVINTIO_TIMING_FILE = $savedTimingFile
    if ($null -eq $savedTimingFile) { Remove-Item Env:RAVINTIO_TIMING_FILE -ErrorAction SilentlyContinue }
    if ($null -eq $savedQuiet) { Remove-Item Env:RAVINTIO_TEST_QUIET -ErrorAction SilentlyContinue } else { $env:RAVINTIO_TEST_QUIET = $savedQuiet }
    Remove-AllWorkspaces
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Complete-Suite
