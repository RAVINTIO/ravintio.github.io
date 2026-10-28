# Test: 0000151 req-008 quiet-test-output (PowerShell helper cases)
# RAVINTIO_TEST_QUIET=1 hides PASS lines in assert.ps1, keeps every FAIL
# detail and the suite name, leaves exit codes alone, and Assert-Contains
# prints its needle and haystack on failure in both modes.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'helpers/assert.ps1')

$hostExe = (Get-Process -Id $PID).Path
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ravintio-quiet-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$helper = Join-Path $here 'helpers/assert.ps1'

try {
    Set-Content -LiteralPath (Join-Path $tmp 'test-pass.ps1') -Value @"
. '$helper'
Assert-Equal 'a' 'a' 'equal case'
Assert-Contains 'b' 'abc' 'contains case'
Assert-True `$true 'true case'
Complete-Suite
"@
    Set-Content -LiteralPath (Join-Path $tmp 'test-fail.ps1') -Value @"
. '$helper'
Assert-Equal 'a' 'a' 'equal case'
Assert-Equal 'want' 'got' 'unequal case'
Assert-Contains 'needle-x' 'hay-y' 'missing needle case'
Complete-Suite
"@

    function Invoke-Suite([string]$Name, [string]$Quiet) {
        if ($Quiet -eq '1') { $env:RAVINTIO_TEST_QUIET = '1' } else { Remove-Item Env:RAVINTIO_TEST_QUIET -ErrorAction SilentlyContinue }
        $out = (& $hostExe -NoProfile -File (Join-Path $tmp $Name) 2>&1 | Out-String)
        $code = $LASTEXITCODE
        Remove-Item Env:RAVINTIO_TEST_QUIET -ErrorAction SilentlyContinue
        return @{ Out = $out; Code = $code }
    }

    Write-Host "=== (a) quiet mode, passing suite ==="
    $q = Invoke-Suite 'test-pass.ps1' '1'
    Assert-Equal 0 $q.Code 'quiet passing suite exits 0'
    Assert-True (-not $q.Out.Contains('PASS:')) 'quiet passing suite prints no PASS line'
    Assert-Contains 'Results: 3 passed, 0 failed' $q.Out 'quiet passing suite prints its summary'

    Write-Host "=== (a) quiet mode, failing suite ==="
    $qf = Invoke-Suite 'test-fail.ps1' '1'
    $nf = Invoke-Suite 'test-fail.ps1' '0'
    Assert-Equal $nf.Code $qf.Code 'exit code matches normal mode'
    Assert-True ($qf.Code -ne 0) 'failing suite exits non-zero'
    Assert-True (-not $qf.Out.Contains('PASS:')) 'quiet failing suite prints no PASS line'
    Assert-Contains 'FAIL: unequal case' $qf.Out 'quiet keeps the FAIL line'
    Assert-Contains 'expected: want' $qf.Out 'quiet keeps the expected value'
    Assert-Contains 'actual:   got' $qf.Out 'quiet keeps the actual value'
    Assert-Contains 'needle:   needle-x' $qf.Out 'quiet keeps the needle'
    Assert-Contains 'haystack: hay-y' $qf.Out 'quiet keeps the haystack'
    Assert-Contains 'needle:   needle-x' $nf.Out 'normal mode prints the needle'
    Assert-Contains 'haystack: hay-y' $nf.Out 'normal mode prints the haystack'
    $names = ([regex]::Matches($qf.Out, '--- test-fail.ps1 ---')).Count
    Assert-Equal 1 $names 'quiet names the failing suite once'
    Assert-True ($qf.Out.IndexOf('--- test-fail.ps1 ---') -lt $qf.Out.IndexOf('FAIL:')) 'suite name comes before the first FAIL line'

    Write-Host "=== (b) normal mode unchanged ==="
    $n = Invoke-Suite 'test-pass.ps1' '0'
    Assert-Contains '  PASS: equal case' $n.Out 'normal mode prints PASS lines'

    Write-Host "=== (c) documentation ==="
    $runner = Get-Content -LiteralPath (Join-Path $here 'run-tests.ps1') -TotalCount 12
    Assert-True ((($runner -join "`n")).Contains('RAVINTIO_TEST_QUIET')) 'run-tests.ps1 header documents the variable'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Complete-Suite
