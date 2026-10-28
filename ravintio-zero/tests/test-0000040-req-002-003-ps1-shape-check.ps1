# Tests for feature 0000040-setup-json-checks-and-park, req-002 and req-003,
# in setup.ps1 under whichever host runs this file.
# req-002: valid JSON that is not a settings object stops the hook install
# step with one fixed line, exit 1, no leaked content, and an unchanged file
# (ADR-002, ADR-003).
# req-003: Test-JsonText tracks depth with an integer and a typed stack, and
# fails past 1024 levels with the same line (ADR-004).
# Every input is built inline. Keep this file ASCII.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

$shapeError = '! Error: .claude/settings.json is valid JSON but not a settings object setup can read. Fix it and rerun setup.'
$invalidError = '! Error: .claude/settings.json is not valid JSON. Fix it and rerun setup.'
$planted = 'PLANTED-0000040-secret-value'

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

# Checks one rejected input: the shape line on stderr, exit 1, one error
# line in all, no invalid-JSON line, no parser text, and an unchanged file.
function Assert-ShapeRejected {
    param([string]$Workspace, [string]$Json, [string]$Label, [string]$Absent)
    Write-SettingsText $Workspace $Json
    $before = Get-FileBase64 (Get-SettingsPath $Workspace)
    $run = Invoke-SetupSplit $Workspace @('claude-code')
    Assert-Equal 1 $run.Code "$Label exits 1"
    $stderrLines = @($run.Stderr -split "`r?`n" | ForEach-Object { $_.Trim() })
    Assert-True ($stderrLines -ccontains $shapeError) "$Label prints the shape line to stderr"
    $allLines = @(($run.Stdout + "`n" + $run.Stderr) -split "`r?`n")
    Assert-Equal 1 (@($allLines | Where-Object { $_.Contains('! Error:') }).Count) "$Label prints exactly one error line"
    Assert-True (-not ($run.Stdout + $run.Stderr).Contains('is not valid JSON')) "$Label never prints the invalid-JSON line"
    Assert-True (-not $run.Stderr.Contains('ConvertFrom-Json')) "$Label prints no parser text"
    if ($Absent) {
        Assert-True (-not $run.Stdout.Contains($Absent)) "$Label keeps the file content out of stdout"
        Assert-True (-not $run.Stderr.Contains($Absent)) "$Label keeps the file content out of stderr"
    }
    Assert-Equal $before (Get-FileBase64 (Get-SettingsPath $Workspace)) "$Label leaves settings.json byte-identical"
    Assert-True (-not (Test-Path -LiteralPath ((Get-SettingsPath $Workspace) + '.ravintio-tmp'))) "$Label leaves no temporary file"
    if ($run.Code -ne 1) { Write-Host $run.Stdout; Write-Host $run.Stderr }
    return $run
}

# Loads Test-JsonText from setup.ps1 without running the script. The parser
# finds the function, and its text is dot-sourced into this scope.
$setupPath = Join-Path $global:ZeroDir 'setup.ps1'
$parseTokens = $null
$parseErrors = $null
$setupAst = [System.Management.Automation.Language.Parser]::ParseFile($setupPath, [ref]$parseTokens, [ref]$parseErrors)
$testJsonAst = $setupAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-JsonText'
}, $true)
$testJsonSource = ''
if ($null -ne $testJsonAst) {
    $testJsonSource = $testJsonAst.Extent.Text
    . ([scriptblock]::Create($testJsonSource))
}

# Calls Test-JsonText and returns "pass", "depth", or "syntax". Any error
# returns "error". Before req-003 the function had no -Failure parameter, so
# it went to $args and $why stayed empty.
function Get-JsonCheck {
    param([string]$Text)
    $ErrorActionPreference = 'Stop'
    try {
        $why = $null
        $ok = Test-JsonText -Text $Text -Failure ([ref]$why)
        if ($ok -is [bool] -and $ok) { return 'pass' }
        if ($why -eq 'depth') { return 'depth' }
        return 'syntax'
    }
    catch { return 'error' }
}

try {

Write-Host ""
Write-Host "=== req-002 (a): valid JSON that is not a settings object ==="

$ws = New-SetupWorkspace
$rejected = @(
    '["x"]',
    'null',
    '"text"',
    '42',
    'true',
    '{"hooks":"text"}',
    '{"hooks":[]}',
    '{"hooks":5}',
    '{"a":1,"A":2}'
)
foreach ($json in $rejected) {
    Assert-ShapeRejected $ws $json "req-002 (a): $json" $null | Out-Null
}

Write-Host ""
Write-Host "=== req-002 (a): a one-item array of one settings object ==="

# PowerShell 7 unrolls a one-item top-level array into its object, so the
# parsed value alone can't show the array.
Assert-ShapeRejected $ws '[{"hooks":{}}]' "req-002 (a): [{`"hooks`":{}}]" $null | Out-Null

Write-Host ""
Write-Host "=== req-002 (b): a planted value never reaches the output ==="

Assert-ShapeRejected $ws ('["' + $planted + '"]') "req-002 (b): a planted top-level array" $planted | Out-Null
Assert-ShapeRejected $ws ('{"hooks":"' + $planted + '"}') "req-002 (b): a planted string hooks value" $planted | Out-Null
Assert-ShapeRejected $ws ('{"a":"' + $planted + '","A":2}') "req-002 (b): planted case-duplicate keys" $planted | Out-Null
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002 (c): a null hooks value counts as absent ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws '{"hooks":null}'
$run = Invoke-SetupSplit $ws @('claude-code')
Assert-Equal 0 $run.Code "req-002 (c): {`"hooks`":null} exits 0"
if ($run.Code -ne 0) { Write-Host $run.Stdout; Write-Host $run.Stderr }
Assert-Equal $global:ExpectedEntries (Get-HookEntries (Read-Settings $ws) -RavintioOnly) "req-002 (c): {`"hooks`":null} gets the RAVINTIO hooks wired"
Assert-True (-not ($run.Stdout + $run.Stderr).Contains('! Error:')) "req-002 (c): {`"hooks`":null} prints no error line"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-002 (c): invalid JSON keeps its own line ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws '{"a":1,'
$before = Get-FileBase64 (Get-SettingsPath $ws)
$run = Invoke-SetupSplit $ws @('claude-code')
Assert-Equal 1 $run.Code "req-002 (c): {`"a`":1, exits 1"
$stderrLines = @($run.Stderr -split "`r?`n" | ForEach-Object { $_.Trim() })
Assert-True ($stderrLines -ccontains $invalidError) "req-002 (c): {`"a`":1, prints the invalid-JSON line"
Assert-True (-not ($run.Stdout + $run.Stderr).Contains('not a settings object')) "req-002 (c): {`"a`":1, never prints the shape line"
Assert-Equal $before (Get-FileBase64 (Get-SettingsPath $ws)) "req-002 (c): {`"a`":1, leaves settings.json byte-identical"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-003 (a): 100,000 open brackets fail fast ==="

$ws = New-SetupWorkspace
$deepOpen = '[' * 100000
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$run = Assert-ShapeRejected $ws $deepOpen "req-003 (a): 100,000 [ characters" ('[' * 64)
$timer.Stop()
Assert-True ($timer.Elapsed.TotalSeconds -lt 5) "req-003 (a): setup.ps1 finishes in under 5 seconds (took $([math]::Round($timer.Elapsed.TotalSeconds, 2)) s)"

$timer = [System.Diagnostics.Stopwatch]::StartNew()
$result = Get-JsonCheck $deepOpen
$timer.Stop()
Assert-Equal 'depth' $result "req-003 (a): Test-JsonText reports a depth failure on 100,000 [ characters"
Assert-True ($timer.Elapsed.TotalSeconds -lt 5) "req-003 (a): Test-JsonText finishes in under 5 seconds (took $([math]::Round($timer.Elapsed.TotalSeconds, 2)) s)"

Write-Host ""
Write-Host "=== req-003 (b): the depth cap sits at 1024 levels ==="

# An object holding nested arrays, so only the depth can fail it.
$deep1025 = '{"a":' + ('[' * 1024) + (']' * 1024) + '}'
$deep1024 = '{"a":' + ('[' * 1023) + (']' * 1023) + '}'
Assert-ShapeRejected $ws $deep1025 "req-003 (b): 1025 balanced levels" $null | Out-Null
Assert-Equal 'depth' (Get-JsonCheck $deep1025) "req-003 (b): Test-JsonText fails 1025 levels on depth"
Assert-Equal 'pass' (Get-JsonCheck $deep1024) "req-003 (b): Test-JsonText passes 1024 levels"
Assert-Equal 'depth' (Get-JsonCheck (('[' * 1025) + (']' * 1025))) "req-003 (b): Test-JsonText fails 1025 bare array levels on depth"
Assert-Equal 'pass' (Get-JsonCheck (('[' * 1024) + (']' * 1024))) "req-003 (b): Test-JsonText passes 1024 bare array levels"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-003 (c): Test-JsonText keeps its earlier results ==="

Assert-True ($null -ne $testJsonAst) "req-003 (c): setup.ps1 defines Test-JsonText"
$fixtureDir = Join-Path $PSScriptRoot 'fixtures\0000039-setup-hardening'
$fixtureCases = @(
    @{ Name = 'invalid-settings.json'; Want = 'syntax' },
    @{ Name = 'single-object-hooks.json'; Want = 'pass' },
    @{ Name = 'deep-settings.json'; Want = 'pass' }
)
foreach ($case in $fixtureCases) {
    $text = [System.IO.File]::ReadAllText((Join-Path $fixtureDir $case.Name)).TrimStart([char]0xFEFF)
    Assert-Equal $case.Want (Get-JsonCheck $text) "req-003 (c): fixture $($case.Name) gives $($case.Want)"
}
$textCases = @(
    @{ Text = '{}'; Want = 'pass' },
    @{ Text = '[]'; Want = 'pass' },
    @{ Text = ' {"a":[1,-2.5e3,{"b":null}],"c":"\u00e9\n"} '; Want = 'pass' },
    @{ Text = '"text"'; Want = 'pass' },
    @{ Text = '{"a":1,"A":2}'; Want = 'pass' },
    @{ Text = ''; Want = 'syntax' },
    @{ Text = '{"a":1,'; Want = 'syntax' },
    @{ Text = '{"a":1,}'; Want = 'syntax' },
    @{ Text = '[1,]'; Want = 'syntax' },
    @{ Text = '[,1]'; Want = 'syntax' },
    @{ Text = '{,}'; Want = 'syntax' },
    @{ Text = '{"a":01}'; Want = 'syntax' },
    @{ Text = '"\x"'; Want = 'syntax' },
    @{ Text = '{"a" 1}'; Want = 'syntax' },
    @{ Text = '[1 2]'; Want = 'syntax' },
    @{ Text = '{} {}'; Want = 'syntax' },
    @{ Text = '{"a":1}]'; Want = 'syntax' },
    @{ Text = '[}'; Want = 'syntax' },
    @{ Text = '{]'; Want = 'syntax' },
    @{ Text = 'True'; Want = 'syntax' },
    @{ Text = "{'a':1}"; Want = 'syntax' }
)
foreach ($case in $textCases) {
    Assert-Equal $case.Want (Get-JsonCheck $case.Text) "req-003 (c): Test-JsonText gives $($case.Want) for <$($case.Text)>"
}

Assert-True ($testJsonSource.Contains('[System.Collections.Generic.Stack[char]]')) "req-003 (c): Test-JsonText uses [System.Collections.Generic.Stack[char]]"
Assert-True (-not ($testJsonSource -match '\$stack\s*\+=')) "req-003 (c): Test-JsonText has no `$stack += line"
Assert-True (-not $testJsonSource.Contains('$stack.Substring')) "req-003 (c): Test-JsonText has no `$stack.Substring line"

}
finally { Remove-AllWorkspaces }

Complete-Suite
