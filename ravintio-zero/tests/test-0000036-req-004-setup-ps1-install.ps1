# Tests for feature 0000036-test-runner-coverage, req-004: setup.ps1 install
# behaviour at runtime, under whichever host runs this file (ADR-002).
# Covers the 0000035 behaviours: six hooks in the setup.sh shape, no
# duplicate after an old Write|Edit entry, UTF-8 with no BOM, the leftover
# temporary file, a non-array hook value, and Agent in allowedTools.
# Keep this file ASCII. Non-ASCII test text is built from [char] codes.

. (Join-Path $PSScriptRoot 'helpers\assert.ps1')
. (Join-Path $PSScriptRoot 'helpers\setup-workspace.ps1')

try {

Write-Host ""
Write-Host "=== req-004 (a): a fresh install wires the ten setup.sh entries ==="

$ws = New-SetupWorkspace
$tmp = Join-Path $ws '.claude\settings.json.ravintio-tmp'
Set-Content -LiteralPath $tmp -Value 'partial'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (a): setup.ps1 claude-code exits 0"
if ($run.Code -ne 0) { Write-Host $run.Output }
$settings = Read-Settings $ws
Assert-Equal $global:ExpectedEntries (Get-HookEntries $settings) "req-004 (a): settings.json holds the ten entries in the setup.sh order"
$gate = @($settings.hooks.PreToolUse)[0].hooks[0].command
Assert-Equal 'node ".claude/hooks/enforcement/gate-write.mjs"' $gate "req-004 (a): the command quotes the module path"
Assert-Equal 1 (@($settings.allowedTools | Where-Object { $_ -ceq 'Agent' }).Count) "req-004 (a): allowedTools holds Agent once"
$bytes = [System.IO.File]::ReadAllBytes((Get-SettingsPath $ws))
Assert-True (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) "req-004 (a): settings.json has no BOM"
Assert-True (-not (Test-Path -LiteralPath $tmp)) "req-004 (a): the leftover temporary file is gone"

Write-Host ""
Write-Host "=== req-004 (b): a re-run changes nothing ==="

$first = [System.IO.File]::ReadAllText((Get-SettingsPath $ws))
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (b): a second run exits 0"
Assert-Equal $first ([System.IO.File]::ReadAllText((Get-SettingsPath $ws))) "req-004 (b): settings.json is unchanged by the re-run"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004 (c): an old Write|Edit entry is replaced, a user hook stays ==="

$ws = New-SetupWorkspace
Write-SettingsText $ws '{"hooks":{"PreToolUse":[{"matcher":"Write|Edit","hooks":[{"type":"command","command":"node .claude/hooks/enforcement/gate-write.mjs"}]},{"matcher":"Write","hooks":[{"type":"command","command":"node tools/my-check.mjs"}]}]}}'
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (c): setup exits 0"
$settings = Read-Settings $ws
Assert-Equal $global:ExpectedEntries (Get-HookEntries $settings -RavintioOnly) "req-004 (c): the RAVINTIO entries match setup.sh with no duplicate"
Assert-Equal 0 (@($settings.hooks.PreToolUse | Where-Object { $_.matcher -ceq 'Write|Edit' }).Count) "req-004 (c): the Write|Edit entry is gone"
Assert-Contains 'PreToolUse Write my-check' (Get-HookEntries $settings) "req-004 (c): the user's own hook stays"
Remove-SetupWorkspace $ws

Write-Host ""
Write-Host "=== req-004 (d): non-ASCII text survives as UTF-8 ==="

$ws = New-SetupWorkspace
$note = "caf$([char]0xE9) $([char]0x2713) $([char]0x00FC)n$([char]0x00EF)code"
Write-SettingsText $ws ('{"note":"' + $note + '"}')
$run = Invoke-Setup $ws @('claude-code')
Assert-Equal 0 $run.Code "req-004 (d): setup exits 0"
Assert-Equal $note (Read-Settings $ws).note "req-004 (d): the non-ASCII note is unchanged"
Remove-SetupWorkspace $ws

}
finally { Remove-AllWorkspaces }

Complete-Suite
