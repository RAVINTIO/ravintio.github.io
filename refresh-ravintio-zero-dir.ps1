# Refresh the ravintio-zero pack and the Claude Code install for this repository.
# Derives the repo directory from the script's own location.
# Copies the pack from the sibling Zero repo at ..\zero.
$repoDir = $PSScriptRoot
$packSource = Join-Path $repoDir "..\zero\ravintio-zero"

if (-not (Test-Path $packSource)) {
    Write-Error "Pack source folder not found: $packSource"
    exit 1
}

# Refresh the pack
Remove-Item -Path (Join-Path $repoDir "ravintio-zero") -Recurse -EA SilentlyContinue
Copy-Item -Path $packSource -Destination $repoDir -Recurse

# Remove the installed tree
Remove-Item -Path (Join-Path $repoDir ".claude") -Recurse -EA SilentlyContinue
Remove-Item -Path (Join-Path $repoDir "AGENTS.md") -EA SilentlyContinue
Remove-Item -Path (Join-Path $repoDir "CLAUDE.md") -EA SilentlyContinue

# Re-add Claude Code with the flags recorded in plan/state/claude-code.md
Set-Location $repoDir
.\ravintio-zero\setup.ps1 claude-code --strict-orchestrator
