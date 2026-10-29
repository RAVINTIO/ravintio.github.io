# Workspace helpers for the PowerShell setup.ps1 suites (0000036 req-004).
# Each workspace is a fresh temporary project holding a copy of
# ravintio-zero/ and its own git repo, so setup.ps1 never touches this
# checkout. Keep this file ASCII: Windows PowerShell 5.1 reads a file with no
# BOM as ANSI.

$global:ZeroDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$global:HostExe = (Get-Process -Id $PID).Path

# The ten entries setup.sh writes, in order (0000035 ADR-001, 0000043 req-006).
$global:ExpectedEntries = @(
    'PreToolUse Write gate-write',
    'PreToolUse Edit gate-write',
    'PreToolUse Write ratchet-check',
    'PreToolUse Edit ratchet-check',
    'PreToolUse Write em-dash-guard',
    'PreToolUse Edit em-dash-guard',
    'PreToolUse Bash merge-guard',
    'UserPromptSubmit .* auto-trigger-orchestrator',
    'UserPromptSubmit .* check-orchestrator-presence',
    'UserPromptSubmit .* check-design'
) -join "`n"

$global:RavintioModules = @(
    'gate-write', 'ratchet-check', 'em-dash-guard', 'merge-guard',
    'auto-trigger-orchestrator', 'check-orchestrator-presence', 'check-design'
)

$global:Workspaces = @()

function New-SetupWorkspace {
    $ws = Join-Path ([System.IO.Path]::GetTempPath()) ("ravintio_0000036_" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $ws | Out-Null
    $copyTimer = [System.Diagnostics.Stopwatch]::StartNew()
    Copy-Item -Path $global:ZeroDir -Destination (Join-Path $ws 'ravintio-zero') -Recurse
    # Timing lines go to the host, never into the data a test captures
    # (0000151 req-015).
    Write-Host ("[timing] workspace copy: {0} ms" -f $copyTimer.ElapsedMilliseconds)
    New-Item -ItemType Directory -Path (Join-Path $ws '.claude') | Out-Null
    & git -C $ws init -q 2>&1 | Out-Null
    # Without its own repo, setup's git config would reach a parent repo
    # (0000036 S-001).
    if ($LASTEXITCODE -ne 0) { throw "git init failed in $ws" }
    $global:Workspaces += $ws
    return $ws
}

function Remove-SetupWorkspace {
    param([string]$Workspace)
    Remove-Item -LiteralPath $Workspace -Recurse -Force -ErrorAction SilentlyContinue
}

# Removes every workspace this suite made. Suites call it from a finally
# block, so a stopped run cleans up too (0000036 S-002).
function Remove-AllWorkspaces {
    foreach ($ws in $global:Workspaces) { Remove-SetupWorkspace $ws }
    $global:Workspaces = @()
}

# Runs setup.ps1 in a child process of the same host. Returns the exit code
# and the combined output.
function Invoke-Setup {
    param([string]$Workspace, [string[]]$SetupArgs)
    $setup = Join-Path $Workspace 'ravintio-zero\setup.ps1'
    Push-Location $Workspace
    # Stop git searching above the workspace's parent folder.
    $savedCeiling = $env:GIT_CEILING_DIRECTORIES
    $env:GIT_CEILING_DIRECTORIES = Split-Path -Parent $Workspace
    try {
        # A bare child process shows the host start-up cost on its own.
        $startTimer = [System.Diagnostics.Stopwatch]::StartNew()
        & $global:HostExe -NoProfile -Command 'exit 0' 2>&1 | Out-Null
        Write-Host ("[timing] pwsh start-up: {0} ms" -f $startTimer.ElapsedMilliseconds)
        $setupTimer = [System.Diagnostics.Stopwatch]::StartNew()
        $output = & $global:HostExe -NoProfile -ExecutionPolicy Bypass -File $setup @SetupArgs 2>&1 | Out-String
        $code = $LASTEXITCODE
        Write-Host ("[timing] setup.ps1: {0} ms" -f $setupTimer.ElapsedMilliseconds)
        # The runner totals these lines from the file it names (0000171 req-003).
        if ($env:RAVINTIO_TIMING_FILE) {
            [System.IO.File]::AppendAllText($env:RAVINTIO_TIMING_FILE, ("{0}`r`n" -f $setupTimer.ElapsedMilliseconds), [System.Text.Encoding]::ASCII)
        }
    }
    finally {
        $env:GIT_CEILING_DIRECTORIES = $savedCeiling
        Pop-Location
    }
    return [PSCustomObject]@{ Code = $code; Output = $output }
}

function Get-SettingsPath {
    param([string]$Workspace)
    return (Join-Path $Workspace '.claude\settings.json')
}

function Read-Settings {
    param([string]$Workspace)
    $bytes = [System.IO.File]::ReadAllBytes((Get-SettingsPath $Workspace))
    $text = (New-Object System.Text.UTF8Encoding $false).GetString($bytes)
    return ($text.TrimStart([char]0xFEFF) | ConvertFrom-Json)
}

function Write-SettingsText {
    param([string]$Workspace, [string]$Json)
    [System.IO.File]::WriteAllText((Get-SettingsPath $Workspace), $Json, (New-Object System.Text.UTF8Encoding $false))
}

# Lists "event matcher module" for every hook command that names a .mjs file.
function Get-HookEntries {
    param($Settings, [switch]$RavintioOnly)
    $lines = @()
    foreach ($event in @('PreToolUse', 'UserPromptSubmit')) {
        foreach ($entry in @($Settings.hooks.$event)) {
            if ($null -eq $entry) { continue }
            foreach ($hook in @($entry.hooks)) {
                if ("$($hook.command)" -match '([A-Za-z0-9-]+)\.mjs') {
                    $module = $Matches[1]
                    if ($RavintioOnly -and $global:RavintioModules -cnotcontains $module) { continue }
                    $lines += "$event $($entry.matcher) $module"
                }
            }
        }
    }
    return ($lines -join "`n")
}
