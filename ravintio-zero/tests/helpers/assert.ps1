# Assert helpers for PowerShell suites, the counterpart of assert.sh
# (0000036 ADR-002). Dot-source this file, call the asserts, then end the
# suite with Complete-Suite. Each suite runs in its own process, so the
# counters live in global scope. Works on Windows PowerShell 5.1 and
# PowerShell 7.

$global:AssertPass = 0
$global:AssertFail = 0
$global:AssertNamed = $false

# RAVINTIO_TEST_QUIET=1 hides PASS lines. A failing suite prints its name
# once, before its first FAIL line (0000151 req-008).
function Write-AssertPass {
    param([string]$Message)
    if ($env:RAVINTIO_TEST_QUIET -ne '1') { Write-Host "  PASS: $Message" }
}

function Write-AssertFail {
    param([string]$Message)
    if ($env:RAVINTIO_TEST_QUIET -eq '1' -and -not $global:AssertNamed) {
        $frames = @(Get-PSCallStack)
        $suiteName = 'suite'
        if ($frames.Count -gt 0 -and $frames[$frames.Count - 1].ScriptName) {
            $suiteName = Split-Path -Leaf $frames[$frames.Count - 1].ScriptName
        }
        Write-Host "--- $suiteName ---"
        $global:AssertNamed = $true
    }
    Write-Host "  FAIL: $Message"
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ("$Expected" -ceq "$Actual") {
        $global:AssertPass++
        Write-AssertPass $Message
    }
    else {
        $global:AssertFail++
        Write-AssertFail $Message
        Write-Host "        expected: $Expected"
        Write-Host "        actual:   $Actual"
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        $global:AssertPass++
        Write-AssertPass $Message
    }
    else {
        $global:AssertFail++
        Write-AssertFail $Message
    }
}

function Assert-Contains {
    param([string]$Needle, [string]$Haystack, [string]$Message)
    if ($Haystack.Contains($Needle)) {
        $global:AssertPass++
        Write-AssertPass $Message
    }
    else {
        $global:AssertFail++
        Write-AssertFail $Message
        Write-Host "        needle:   $Needle"
        Write-Host "        haystack: $Haystack"
    }
}

function Complete-Suite {
    Write-Host ""
    Write-Host "Results: $global:AssertPass passed, $global:AssertFail failed"
    if ($global:AssertFail -gt 0 -or $global:AssertPass -eq 0) { exit 1 }
    exit 0
}
