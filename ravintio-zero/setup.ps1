<#
.SYNOPSIS
    RAVINTIO Setup - Configures skills for your agentic coding tool.

.DESCRIPTION
    Copies RAVINTIO skills into the directory structure each coding tool expects.
    Each tool's specific config lives in setup/<tool>.ps1.
    This script handles shared logic only.

.EXAMPLE
    .\ravintio-zero\setup.ps1 claude-code
#>

# Manual arg parsing — supports --flag style for cross-platform consistency
$Tool = $null
$StrictOrchestrator = $false
# Flags that earlier releases removed (0000034 ADR-001). A retired flag does
# nothing, so setup fails on it during argument parsing, before any change
# (0000196 ADR-002). The message names the flag and never prints what follows
# it, so a --backend-url value never reaches the output.
# Matching is case-sensitive, the same as setup.sh.
$RetiredFlags = @('--structured-telemetry-mcp', '--backend-url', '--context-mode-mcp', '--include-full-skill-library')
function Stop-OnRetiredFlag {
    param([string]$Flag)
    [Console]::Error.WriteLine("! Error: retired flag $Flag was removed in an earlier release and does nothing.")
    [Console]::Error.WriteLine("  Remove it from the command, then rerun setup.")
    exit 1
}
$i = 0
while ($i -lt $args.Count) {
    # PowerShell 7 splits a -File argument such as --backend-url=https://x at
    # its first colon, so match the flag by prefix and print the name only.
    if ("$($args[$i])".StartsWith('--backend-url=')) { Stop-OnRetiredFlag '--backend-url' }
    if ($RetiredFlags -ccontains $args[$i]) { Stop-OnRetiredFlag "$($args[$i])" }
    # Case-sensitive, the same as setup.sh (0000035 ADR-003).
    switch -CaseSensitive ($args[$i]) {
        '--strict-orchestrator' { $StrictOrchestrator = $true; $i++ }
        default {
            if ($args[$i] -like '-*') { Write-Host "Unknown flag: $(("$($args[$i])" -split '=', 2)[0])"; exit 1 }
            else { $Tool = $args[$i]; $i++ }
        }
    }
}

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SkillsSrc = Join-Path $ScriptDir 'skills'
$WorkflowsSrc = Join-Path $ScriptDir 'workflows'
$SetupDir = Join-Path $ScriptDir 'setup'

$ValidTools = @('claude-code', 'codex')

# --- Shared functions ---

# Copy helpers built on System.IO calls. Per-file cmdlets cost far more than
# these on Windows PowerShell and PowerShell 7 (0000171 ADR-002). Both use
# only APIs that Windows PowerShell 5.1 has, and overwrite existing files.

# Copies a file into a folder, or makes the named folder for a folder source
# (the same as Copy-Item without -Recurse). Makes the destination folder first.
function Copy-RavintioItem {
    param([string]$Source, [string]$DestDir)
    [System.IO.Directory]::CreateDirectory($DestDir) | Out-Null
    $leaf = [System.IO.Path]::GetFileName($Source)
    if ([System.IO.Directory]::Exists($Source)) {
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($DestDir, $leaf)) | Out-Null
    }
    else {
        [System.IO.File]::Copy($Source, [System.IO.Path]::Combine($DestDir, $leaf), $true)
    }
}

# Copies the children of a folder into another folder, keeping every file
# (dot files included) and every subfolder, empty ones too.
function Copy-RavintioTree {
    param([string]$SourceDir, [string]$DestDir)
    $all = [System.IO.SearchOption]::AllDirectories
    [System.IO.Directory]::CreateDirectory($DestDir) | Out-Null
    $prefix = $SourceDir.TrimEnd('\', '/').Length + 1
    foreach ($dir in [System.IO.Directory]::GetDirectories($SourceDir, '*', $all)) {
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($DestDir, $dir.Substring($prefix))) | Out-Null
    }
    foreach ($file in [System.IO.Directory]::GetFiles($SourceDir, '*', $all)) {
        [System.IO.File]::Copy($file, [System.IO.Path]::Combine($DestDir, $file.Substring($prefix)), $true)
    }
}

function Copy-RavintioSkills {
    param($TargetDir)

    Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
        $skillName = $_.Name
        $srcDir = $_.FullName
        $destDir = Join-Path $TargetDir $skillName
        
        $srcSkillMd = Join-Path $srcDir "SKILL.md"
        if ([System.IO.File]::Exists($srcSkillMd)) {
            # Install the skill's own folder only, byte for byte (0000171 req-004,
            # ADR-004). Pack templates, standards, and schemas stay in ravintio-zero/.
            Copy-RavintioTree $srcDir $destDir

            Write-Host "  + $skillName/SKILL.md"

            Remove-BundledFiles $srcDir $destDir
        }
    }
}

# True when the path exists and is a link or junction.
function Test-RavintioLink {
    param([string]$Path)
    if (-not ([System.IO.File]::Exists($Path) -or [System.IO.Directory]::Exists($Path))) { return $false }
    $link = [System.IO.FileAttributes]::ReparsePoint
    return (([System.IO.File]::GetAttributes($Path) -band $link) -eq $link)
}

# Removes the pack copies an older install bundled into a skill (0000171
# req-004). It deletes only the paths where that install put a pack file:
# assets/templates/{name}, assets/schemas/{name}, and references/{name}.
# It never walks the folder, never deletes a path the skill source holds,
# and skips any linked path, so it can't reach outside the install.
function Remove-BundledFiles {
    param([string]$SourceDir, [string]$DestDir)
    if (Test-RavintioLink $DestDir) { return }
    $all = [System.IO.SearchOption]::AllDirectories
    foreach ($pair in @(@('templates', 'assets', 'templates'), @('schemas', 'assets', 'schemas'), @('standards', 'references', ''))) {
        $top = [System.IO.Path]::Combine($DestDir, $pair[1])
        $to = if ($pair[2]) { [System.IO.Path]::Combine($top, $pair[2]) } else { $top }
        if ((Test-RavintioLink $top) -or (Test-RavintioLink $to)) { continue }
        if (-not [System.IO.Directory]::Exists($to)) { continue }
        $rel = if ($pair[2]) { [System.IO.Path]::Combine($pair[1], $pair[2]) } else { $pair[1] }
        foreach ($f in [System.IO.Directory]::GetFiles([System.IO.Path]::Combine($ScriptDir, $pair[0]), '*', $all)) {
            $name = [System.IO.Path]::GetFileName($f)
            if ([System.IO.File]::Exists([System.IO.Path]::Combine($SourceDir, $rel, $name))) { continue }
            $target = [System.IO.Path]::Combine($to, $name)
            if ([System.IO.File]::Exists($target) -and -not (Test-RavintioLink $target)) {
                [System.IO.File]::Delete($target)
            }
        }
    }
    # Deepest first, so a parent is empty when its turn comes. A folder that
    # still holds a user file stays.
    $folders = @(
        [System.IO.Path]::Combine('assets', 'templates'),
        [System.IO.Path]::Combine('assets', 'schemas'),
        'assets',
        'references'
    )
    foreach ($rel in $folders) {
        $dir = [System.IO.Path]::Combine($DestDir, $rel)
        if (-not [System.IO.Directory]::Exists($dir) -or (Test-RavintioLink $dir)) { continue }
        if ([System.IO.Directory]::Exists([System.IO.Path]::Combine($SourceDir, $rel))) { continue }
        if ([System.IO.Directory]::GetFileSystemEntries($dir).Length -eq 0) {
            [System.IO.Directory]::Delete($dir)
        }
    }
}

function Remove-RetiredSkills {
    # Removes any folder in the tool's skills directory whose name is absent
    # from the skills/ source set, so retired skills vanish on regeneration.
    # Scoped to subfolders of the skills directory only. Capability skills from
    # ravintio-overrides/ are copied back in after this prune runs.
    param($TargetDir)

    if (-not (Test-Path $TargetDir)) { return }

    Get-ChildItem -Path $TargetDir -Directory | ForEach-Object {
        # Never follow a planted symlink or junction: deleting through it
        # would reach outside the skills directory.
        if ($_.LinkType) { return }
        $srcDir = Join-Path $SkillsSrc $_.Name
        if (-not (Test-Path $srcDir)) {
            Remove-Item -Path $_.FullName -Recurse -Force
            Write-Host "  - pruned retired skill: $($_.Name)"
        }
    }
}

function Write-RavintioBootFile {
    # Boot files are disposable build outputs (0000029 ADR-001): always
    # regenerate from the current template so template fixes propagate on
    # every run. Durable local customization lives in
    # ravintio-overrides/instructions/ and is re-applied by
    # Append-OverrideInstructions after this write.
    param($RelPath, $Content)

    $fullPath = Join-Path $ProjectRoot $RelPath
    $dir = Split-Path -Parent $fullPath
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if (-not (Test-Path $fullPath)) {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  + $RelPath (created)"
    }
    else {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  ~ $RelPath (regenerated from template)"
    }
}

function Copy-RavintioWorkflow {
    param($WorkflowFile, $TargetDir)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowFile)
    $destFile = Join-Path $TargetDir "$name.md"

    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Copy-Item -Path $WorkflowFile -Destination $destFile -Force
    Write-Host "  + workflows/$name.md"
}

# Writes settings.json through a temporary file in the same folder, then
# swaps it in, so settings.json is always the old file or the new one
# (0000034 ADR-002). An existing file is swapped with File.Replace, which is
# atomic and keeps the original's ACL and attributes. A new file is moved into
# place. A read-only settings.json stays unchanged. Any leftover temporary
# file is removed first, so a planted link at that path is never followed.
function Remove-SettingsTmpEntry {
    # Remove a file or link at the temporary path without following a link
    # (0000035 S-002, S-003). FileInfo reads the entry itself, so a dangling
    # link is found too. A plain folder stays, and the write that follows fails.
    param([string]$Tmp)
    $info = New-Object System.IO.FileInfo $Tmp
    if ([int]$info.Attributes -eq -1) { return }
    $isLink = $info.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    $isFolder = $info.Attributes -band [System.IO.FileAttributes]::Directory
    if ($isLink -and $isFolder) { [System.IO.Directory]::Delete($Tmp) }
    elseif (-not $isFolder) { [System.IO.File]::Delete($Tmp) }
}

function Write-SettingsAtomic {
    param([string]$Path, [string]$Json)
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $tmp = "$full.ravintio-tmp"
    $existing = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.IsReadOnly) {
        throw "settings.json is read-only: $Path"
    }
    try { Remove-SettingsTmpEntry -Tmp $tmp } catch { }
    try {
        # UTF-8 with no BOM on both PowerShell versions, as setup.sh writes
        # (0000035 S-001).
        [System.IO.File]::WriteAllText($tmp, $Json + "`n", (New-Object System.Text.UTF8Encoding $false))
        if ($existing) {
            [System.IO.File]::Replace($tmp, $full, [NullString]::Value)
        }
        else {
            Move-Item -LiteralPath $tmp -Destination $full -ErrorAction Stop
        }
    }
    catch {
        # Remove the temporary file only while the original is still there.
        if (Test-Path -LiteralPath $full) {
            try { Remove-SettingsTmpEntry -Tmp $tmp } catch { }
        }
        throw
    }
}

function Write-SettingsOrExit {
    # Write-SettingsAtomic, with any fault turned into one fixed line on
    # stderr and exit 1, as setup.sh prints it (0000151 req-005). The line holds
    # no absolute path and no PowerShell error text.
    param(
        [string]$Path,
        [string]$Json,
        [string]$SettingsRel = '.claude/settings.json'
    )
    try {
        Write-SettingsAtomic -Path $Path -Json $Json
    }
    catch {
        [Console]::Error.WriteLine("! Error: $SettingsRel could not be written. Fix its permissions and rerun setup.")
        exit 1
    }
}

function New-HookEntry {
    # One settings.json hook entry: a matcher and one node command.
    param([string]$Matcher, [string]$Module, [string]$HooksDir)
    [ordered]@{
        matcher = $Matcher
        hooks   = @([ordered]@{ type = 'command'; command = "node `"$HooksDir/$Module.mjs`"" })
    }
}

function Remove-RavintioHookCommands {
    # Filter one event's entries one command at a time (0000038 ADR-002).
    # Each command that matches the pattern goes. An entry that had commands
    # and has none left goes too. Any other entry keeps its remaining
    # commands in their order. A single-object hooks value counts as a
    # one-item array (0000039 req-002, ADR-003). An entry with no commands,
    # or whose hooks value is neither an array nor an object, stays as it
    # was. The kept commands go back into
    # the entry as an array built with @(), never through the pipeline, so
    # Windows PowerShell 5.1 can't unwrap a one-item array (0000035 ADR-002,
    # 0000038 R-001). Callers wrap the output in @().
    param($Entries, [string]$Pattern)
    foreach ($entry in @($Entries)) {
        $hooks = $null
        if ($null -ne $entry) { $hooks = $entry.hooks }
        # Wrap a single object with @(). A kept entry keeps its object form,
        # since only a removal writes entry.hooks (0000039 req-002).
        if ($hooks -is [System.Management.Automation.PSCustomObject]) { $hooks = @($hooks) }
        if (-not ($hooks -is [array]) -or $hooks.Count -eq 0) { $entry; continue }
        $keptHooks = @()
        foreach ($hook in $hooks) {
            if ("$($hook.command)" -cmatch $Pattern) { continue }
            $keptHooks += $hook
        }
        if ($keptHooks.Count -eq 0) { continue }
        if ($keptHooks.Count -ne $hooks.Count) { $entry.hooks = $keptHooks }
        $entry
    }
}

function Test-JsonText {
    # True when the text is one strict JSON value, as node's JSON.parse reads
    # it. ConvertFrom-Json accepts some invalid JSON, such as a trailing
    # comma, so setup.ps1 checks the text first. Both scripts then reject the
    # same files (0000039 req-001). Anchored patterns match strings and
    # numbers, and a typed stack tracks the nesting, so deep input never
    # recurses. Push and pop cost constant time, so the cost grows linearly
    # with the input (0000040 req-003, ADR-004).
    # Nesting past $maxDepth fails at once, since ConvertFrom-Json can't read
    # it anyway. A caller can pass a [ref] as -Failure. A depth failure sets
    # it to 'depth', so the caller can tell it from a syntax failure.
    param([string]$Text, $Failure)
    $maxDepth = 1024
    $strRe = [regex]'\G"(?:[^"\\\u0000-\u001F]|\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4}))*"'
    $numRe = [regex]'\G-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?'
    $wsRe = [regex]'\G[ \t\n\r]*'
    $n = $Text.Length
    $i = 0
    $stack = [System.Collections.Generic.Stack[char]]::new()
    $depth = 0
    $state = 'value'
    $canClose = $false
    while ($true) {
        $i += $wsRe.Match($Text, $i).Length
        if ($i -ge $n) { break }
        $c = $Text[$i]
        $top = [char]0
        if ($depth -gt 0) { $top = $stack.Peek() }
        if ($state -eq 'value') {
            if ($c -eq [char]'{' -or $c -eq [char]'[') {
                $depth++
                if ($depth -gt $maxDepth) {
                    if ($Failure -is [ref]) { $Failure.Value = 'depth' }
                    return $false
                }
                $stack.Push($c); $i++; $canClose = $true
                if ($c -eq [char]'{') { $state = 'key' }
                continue
            }
            if ($c -eq [char]']' -and $canClose) {
                [void]$stack.Pop(); $depth--; $i++; $state = 'after'; continue
            }
            $m = $strRe.Match($Text, $i)
            if (-not $m.Success) { $m = $numRe.Match($Text, $i) }
            if ($m.Success) { $i += $m.Length; $state = 'after'; continue }
            $word = $null
            foreach ($literal in @('true', 'false', 'null')) {
                if ([string]::CompareOrdinal($Text, $i, $literal, 0, $literal.Length) -eq 0) { $word = $literal; break }
            }
            if ($null -eq $word) { return $false }
            $i += $word.Length; $state = 'after'; continue
        }
        if ($state -eq 'key') {
            if ($c -eq [char]'}' -and $canClose) {
                [void]$stack.Pop(); $depth--; $i++; $state = 'after'; continue
            }
            $m = $strRe.Match($Text, $i)
            if (-not $m.Success) { return $false }
            $i += $m.Length; $state = 'colon'; continue
        }
        if ($state -eq 'colon') {
            if ($c -ne [char]':') { return $false }
            $i++; $state = 'value'; $canClose = $false; continue
        }
        # After a value: a comma, a matching close, or nothing at top level.
        if ($depth -eq 0) { return $false }
        if ($c -eq [char]',') {
            $i++; $canClose = $false
            if ($top -eq [char]'{') { $state = 'key' } else { $state = 'value' }
            continue
        }
        if (($c -eq [char]'}' -and $top -eq [char]'{') -or ($c -eq [char]']' -and $top -eq [char]'[')) {
            [void]$stack.Pop(); $depth--; $i++; continue
        }
        return $false
    }
    return ($state -eq 'after' -and $depth -eq 0)
}

function Read-SettingsObject {
    # The shape check that the hook install step uses (0000040 ADR-002, 0000041 ADR-002).
    # Returns 'ok', 'invalid', or 'shape', and never prints. On 'ok' the
    # parsed settings object goes to -Settings. Text that fails Test-JsonText
    # on syntax is 'invalid'. Each of these is 'shape':
    # - nesting past the depth cap (0000040 req-003, ADR-004)
    # - a parse failure, such as case-duplicate keys (0000040 ADR-003)
    # - a top level that is not an object
    # - a hooks value that is present, not null, and not an object
    # The top-level test reads the first character. PowerShell 7 unrolls a
    # one-item array into its item, so the parsed value can't show it.
    param([string]$Raw, [ref]$Settings)
    $jsonFailure = $null
    if (-not (Test-JsonText $Raw -Failure ([ref]$jsonFailure)) -and $jsonFailure -ne 'depth') {
        return 'invalid'
    }
    $parsed = $null
    $readable = ($jsonFailure -ne 'depth') -and $Raw.TrimStart().StartsWith('{')
    if ($readable) {
        try { $parsed = ConvertFrom-Json -InputObject $Raw -ErrorAction Stop } catch { $readable = $false }
    }
    if ($readable -and $parsed -isnot [System.Management.Automation.PSCustomObject]) { $readable = $false }
    if ($readable) {
        $hooksProp = $parsed.PSObject.Properties['hooks']
        if ($null -ne $hooksProp -and $null -ne $hooksProp.Value -and
            $hooksProp.Value -isnot [System.Management.Automation.PSCustomObject]) { $readable = $false }
    }
    if (-not $readable) { return 'shape' }
    $Settings.Value = $parsed
    return 'ok'
}

function Merge-EnforcementHookSettings {
    # Merge the eight enforcement hooks into settings.json: gate-write,
    # ratchet-check, em-dash-guard, and merge-guard (PreToolUse), then
    # auto-trigger-orchestrator, check-orchestrator-presence, and check-design
    # (UserPromptSubmit), then check-reply-prefix (Stop). Idempotent. The entries match setup.sh in event,
    # matcher, and order (0000035 ADR-001), and a parity suite checks it.
    param(
        [string]$SettingsPath,
        [string]$HooksDir,
        [string]$SettingsRel = '.claude/settings.json'
    )

    $preToolEntries = @(
        (New-HookEntry 'Write' 'gate-write' $HooksDir),
        (New-HookEntry 'Edit' 'gate-write' $HooksDir),
        (New-HookEntry 'Write' 'ratchet-check' $HooksDir),
        (New-HookEntry 'Edit' 'ratchet-check' $HooksDir),
        (New-HookEntry 'Write' 'em-dash-guard' $HooksDir),
        (New-HookEntry 'Edit' 'em-dash-guard' $HooksDir),
        (New-HookEntry 'Bash' 'merge-guard' $HooksDir)
    )
    $userPromptEntries = @(
        (New-HookEntry '.*' 'auto-trigger-orchestrator' $HooksDir),
        (New-HookEntry '.*' 'check-orchestrator-presence' $HooksDir),
        (New-HookEntry '.*' 'check-design' $HooksDir)
    )
    $stopEntries = @(
        (New-HookEntry '.*' 'check-reply-prefix' $HooksDir)
    )

    if (Test-Path $SettingsPath) {
        # An invalid file stops setup with one fixed line that names it. The
        # content and the parser message never reach the output, and the
        # file stays as it was (0000039 req-001, ADR-002). Valid JSON that
        # setup can't read as a settings object stops setup with its own
        # fixed line, before any write (0000040 req-002, ADR-002).
        $raw = "$(Get-Content -Raw -Path $SettingsPath -Encoding UTF8)"
        $existing = $null
        $check = Read-SettingsObject -Raw $raw -Settings ([ref]$existing)
        if ($check -eq 'invalid') {
            [Console]::Error.WriteLine("! Error: $SettingsRel is not valid JSON. Fix it and rerun setup.")
            exit 1
        }
        if ($check -ne 'ok') {
            [Console]::Error.WriteLine("! Error: $SettingsRel is valid JSON but not a settings object setup can read. Fix it and rerun setup.")
            exit 1
        }

        if (-not $existing.hooks) {
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        # A present value that is not an array is non-array (0000037 ADR-003).
        # Warn and replace it with the RAVINTIO entries. The warning never
        # prints the old value, since a hook command can hold a secret
        # (0000041 ADR-003). An absent or null value gets the entries with no
        # warning. Test the property directly, never through the pipeline, so
        # Windows PowerShell 5.1 can't unwrap or wrap it (0000035 ADR-002).
        # setup.sh prints the same text.
        foreach ($eventName in @('PreToolUse', 'UserPromptSubmit', 'Stop')) {
            $prop = $existing.hooks.PSObject.Properties[$eventName]
            if ($null -eq $prop -or $null -eq $prop.Value) { continue }
            if ($prop.Value -is [array]) { continue }
            [Console]::Error.WriteLine("  ! Warning: hooks.$eventName in $SettingsRel is not an array. Setup replaced it with the RAVINTIO entries.")
            $existing.hooks.$eventName = @()
        }

        # Drop each settings entry that runs a retired hook, on every event
        # (0000151 ADR-007), so no entry names a pruned file. The match is the
        # same path-boundary rule as below. A non-array event value stays as it
        # was. setup.sh does the same from RETIRED_HOOK_NAMES.
        $retiredPattern = '(^|[\s"''/\\])(' + ($RetiredHookNames -join '|') + ')\.mjs\b'
        foreach ($eventName in @($existing.hooks.PSObject.Properties.Name)) {
            if (-not $eventName) { continue }
            $eventValue = $existing.hooks.$eventName
            if ($eventValue -is [array]) {
                # One line per removed entry names it (0000164 S-005).
                foreach ($entry in $eventValue) {
                    foreach ($hook in @($entry.hooks)) {
                        $m = [regex]::Match("$($hook.command)", $retiredPattern)
                        if ($m.Success) { Write-Host "  - removed retired hook entry $($m.Groups[2].Value) from $SettingsRel" }
                    }
                }
                $existing.hooks.$eventName = @(Remove-RavintioHookCommands -Entries $eventValue -Pattern $retiredPattern)
            }
        }

        # Merge PreToolUse. Remove every earlier command for the three
        # modules, on any matcher, so an old single Write|Edit entry goes too.
        # A user command in the same entry stays (0000038 ADR-002).
        if (-not $existing.hooks.PreToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @() -Force
        }
        # Case-sensitive, and only <module>.mjs at a path boundary (0000035 S-004).
        $filtered = @(Remove-RavintioHookCommands -Entries $existing.hooks.PreToolUse `
            -Pattern '(^|[\s"''/\\])(gate-write|ratchet-check|em-dash-guard|merge-guard)\.mjs\b')
        $existing.hooks.PreToolUse = $filtered + $preToolEntries

        # Merge UserPromptSubmit. Remove stale commands one at a time, then
        # append fresh entries in order (0000038 ADR-002).
        if (-not $existing.hooks.UserPromptSubmit) {
            $existing.hooks | Add-Member -NotePropertyName 'UserPromptSubmit' -NotePropertyValue @() -Force
        }
        $filtered = @(Remove-RavintioHookCommands -Entries $existing.hooks.UserPromptSubmit `
            -Pattern '(^|[\s"''/\\])(auto-trigger-orchestrator|check-orchestrator-presence|check-design)\.mjs\b')
        $existing.hooks.UserPromptSubmit = $filtered + $userPromptEntries

        # Merge Stop the same way (0000200 req-004).
        if (-not $existing.hooks.Stop) {
            $existing.hooks | Add-Member -NotePropertyName 'Stop' -NotePropertyValue @() -Force
        }
        $filtered = @(Remove-RavintioHookCommands -Entries $existing.hooks.Stop `
            -Pattern '(^|[\s"''/\\])(check-reply-prefix)\.mjs\b')
        $existing.hooks.Stop = $filtered + $stopEntries

        # Depth 100 keeps deep user values whole (0000039 req-003).
        Write-SettingsOrExit -Path $SettingsPath -Json ($existing | ConvertTo-Json -Depth 100) -SettingsRel $SettingsRel
        Write-Host "  ~ .claude/settings.json (enforcement hook entries merged)"
    }
    else {
        $dir = Split-Path -Parent $SettingsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        $settings = [PSCustomObject]@{
            hooks = [PSCustomObject]@{
                PreToolUse       = @($preToolEntries)
                UserPromptSubmit = @($userPromptEntries)
                Stop             = @($stopEntries)
            }
        }
        Write-SettingsOrExit -Path $SettingsPath -Json ($settings | ConvertTo-Json -Depth 100) -SettingsRel $SettingsRel
        Write-Host "  + .claude/settings.json (created with enforcement hook entries)"
    }
}

function Merge-AllowedTools {
    # Idempotently add "Agent" to allowedTools in .claude/settings.json (REQ-002).
    # Preserves existing allowedTools entries — additive merge only.
    param([string]$SettingsPath)

    # Plain ConvertFrom-Json, with no hashtable switch, so this runs on Windows
    # PowerShell 5.1 (0000035 ADR-002).
    $settings = [PSCustomObject]@{}
    if (Test-Path $SettingsPath) {
        $raw = Get-Content -Raw -Path $SettingsPath -Encoding UTF8
        try { $parsed = $raw | ConvertFrom-Json -ErrorAction Stop } catch { $parsed = $null }
        if ($parsed -isnot [System.Management.Automation.PSCustomObject]) {
            # Never overwrite a file that isn't a JSON object (0000035 S-006).
            Write-Warning "Could not read .claude/settings.json as a JSON object, so Agent was not added to allowedTools"
            return
        }
        $settings = $parsed
    }

    # A non-array allowedTools counts as empty, as in setup.sh. The outer @()
    # stops PowerShell unrolling a one-entry array to a string, which would
    # turn ["Read"] into "ReadAgent" below.
    $existing = @(if ($settings.PSObject.Properties['allowedTools'] -and $settings.allowedTools -is [System.Array]) {
        $settings.allowedTools
    })

    $addAgent = $existing -cnotcontains 'Agent'
    # An absent attribution key gets empty strings, so the host writes no
    # attribution lines. A present key stays as it is (0000169 req-004).
    $addAttribution = -not $settings.PSObject.Properties['attribution']
    if ($addAgent) {
        $settings | Add-Member -NotePropertyName 'allowedTools' -NotePropertyValue ($existing + @('Agent')) -Force
    }
    if ($addAttribution) {
        $settings | Add-Member -NotePropertyName 'attribution' -NotePropertyValue ([PSCustomObject]@{ commit = ''; pr = '' }) -Force
    }
    if ($addAgent -or $addAttribution) {
        $dir = Split-Path -Parent $SettingsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Write-SettingsOrExit -Path $SettingsPath -Json ($settings | ConvertTo-Json -Depth 100)
    }
    if ($addAgent) {
        Write-Host "  ~ .claude/settings.json (Agent added to allowedTools)"
    } else {
        Write-Host "  - .claude/settings.json (Agent already in allowedTools)"
    }
    if ($addAttribution) {
        Write-Host "  ~ .claude/settings.json (attribution set to empty commit and pr)"
    } else {
        Write-Host "  - .claude/settings.json (attribution already set)"
    }
}

function Remove-LeftoverSettingsTmp {
    # Remove the temporary file a hard stop left between the write and the
    # rename (0000035 ADR-003, backlog 0000104). Runs before the first
    # settings.json writer. A folder stays. A link goes without its target.
    param([string]$SettingsRel)
    $tmp = Join-Path $ProjectRoot "$SettingsRel.ravintio-tmp"
    # Silent, as in setup.sh. The next atomic write replaces it anyway.
    try { Remove-SettingsTmpEntry -Tmp $tmp } catch { }
}

# The retired-hooks list (0000151 ADR-007). Install-EnforcementHooks deletes an
# installed hook named here and never one absent from it, through
# Remove-RetiredHooks. Retiring a hook means adding its name here and in setup.sh.
$RetiredHookNames = @(
    'emit-phase-start',
    'emit-phase-end',
    'emit-event-receipt',
    'emit-event',
    'context-pressure',
    'resolve-phase',
    'record-telemetry-failure',
    'check-telemetry-failures',
    'check-telemetry-receipts',
    'phase-enum'
)

function Test-UnderRealRoot {
    # True when the item and every folder between it and the root are plain
    # entries, not reparse points, and the item sits under the root.
    param($Item, [string]$RootFull)
    if (-not $Item.FullName.StartsWith($RootFull + [IO.Path]::DirectorySeparatorChar)) { return $false }
    $current = $Item
    while ($current -and $current.FullName.TrimEnd('\', '/') -ne $RootFull) {
        if ($current.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $false }
        $current = if ($current -is [IO.FileInfo]) { $current.Directory } else { $current.Parent }
    }
    return $true
}

function Remove-RetiredHooks {
    # Mirror of prune_retired_hooks in setup.sh (0000151 req-004, ADR-007).
    # Deletes each installed hook whose base name is on $RetiredHookNames,
    # checks the whole hooks tree, and prints one line per removal.
    param([string]$HooksRootRel)
    $root = Join-Path $ProjectRoot $HooksRootRel
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return }
    foreach ($name in $RetiredHookNames) {
        # Windows PowerShell 5.1 follows junctions on -Recurse, so drop any
        # match under a reparse point or outside the hooks root.
        $rootFull = (Get-Item -LiteralPath $root).FullName.TrimEnd('\', '/')
        $found = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "$name.mjs" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ceq "$name.mjs" } |
            Where-Object { Test-UnderRealRoot -Item $_ -RootFull $rootFull })
        foreach ($file in $found) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $rel = $file.FullName.Substring($ProjectRoot.TrimEnd('\', '/').Length + 1) -replace '\\', '/'
                Write-Host "  - removed $rel"
            }
            catch { }
        }
    }
}

function Install-EnforcementHooks {
    # Copy the enforcement hook modules and wire all six into settings.json.
    # Always runs — no flag required.
    param(
        [string]$HooksSrcRel,
        [string]$HooksDirRel,
        [string]$SettingsRel
    )

    $src      = Join-Path $ScriptDir $HooksSrcRel
    $dest     = Join-Path $ProjectRoot $HooksDirRel
    $settings = Join-Path $ProjectRoot $SettingsRel

    if (-not [System.IO.Directory]::Exists($src)) {
        Write-Host "  ! Warning: enforcement hook scripts not found at $src — skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing RAVINTIO enforcement hooks"

    [System.IO.Directory]::CreateDirectory($dest) | Out-Null

    Get-ChildItem -Path $src -Filter '*.mjs' | ForEach-Object {
        Copy-RavintioItem $_.FullName $dest
        Write-Host "  + $HooksDirRel/$($_.Name)"
    }

    Remove-RetiredHooks -HooksRootRel (Split-Path -Parent $HooksDirRel)

    Merge-EnforcementHookSettings -SettingsPath $settings -HooksDir $HooksDirRel -SettingsRel $SettingsRel
}

function Install-CodexHooks {
    # Wire the Codex hooks (0000207 ADR-002). Only merge-guard has a Codex
    # contract that the Codex docs confirm: a PreToolUse group for Bash, exit
    # 2, and the reason on stderr. Every other RAVINTIO hook stays an
    # instruction in AGENTS.md. setup.sh prints the same report.
    param(
        [string]$HooksDirRel,
        [string]$HooksFileRel
    )

    $src = Join-Path (Join-Path $ScriptDir 'hooks') 'enforcement'
    $dest = Join-Path $ProjectRoot $HooksDirRel
    $hooksFile = Join-Path $ProjectRoot $HooksFileRel

    if (-not [System.IO.Directory]::Exists($src)) {
        Write-Host "  ! Warning: enforcement hook scripts not found at $src - skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing RAVINTIO Codex hooks"

    [System.IO.Directory]::CreateDirectory($dest) | Out-Null
    foreach ($name in @('merge-guard.mjs', 'read-stdin.mjs')) {
        Copy-RavintioItem (Join-Path $src $name) $dest
        Write-Host "  + $HooksDirRel/$name"
    }

    $mark = "$HooksDirRel/merge-guard.mjs"
    $commandLine = 'node "$(git rev-parse --show-toplevel)/' + $mark + '"'
    $entry = [ordered]@{
        matcher = 'Bash'
        hooks   = @([ordered]@{ type = 'command'; command = $commandLine; statusMessage = 'Checking merge command' })
    }

    if (Test-Path -LiteralPath $hooksFile) {
        $raw = "$(Get-Content -Raw -Path $hooksFile -Encoding UTF8)"
        $existing = $null
        $check = Read-SettingsObject -Raw $raw -Settings ([ref]$existing)
        if ($check -eq 'invalid') {
            [Console]::Error.WriteLine("! Error: $HooksFileRel is not valid JSON. Fix it and rerun setup.")
            exit 1
        }
        if ($check -eq 'shape') {
            [Console]::Error.WriteLine("! Error: $HooksFileRel is valid JSON but not a hooks file setup can read. Fix it and rerun setup.")
            exit 1
        }
        if ($null -eq $existing.PSObject.Properties['hooks'] -or $null -eq $existing.hooks) {
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        if (-not $existing.hooks.PreToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @() -Force
        }
        $pattern = '(^|[\s"''/\\])' + [regex]::Escape($mark)
        $filtered = @(Remove-RavintioHookCommands -Entries $existing.hooks.PreToolUse -Pattern $pattern)
        $existing.hooks.PreToolUse = $filtered + @($entry)
        Write-SettingsOrExit -Path $hooksFile -Json ($existing | ConvertTo-Json -Depth 100) -SettingsRel $HooksFileRel
    }
    else {
        $dir = Split-Path -Parent $hooksFile
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $settings = [PSCustomObject]@{ hooks = [PSCustomObject]@{ PreToolUse = @($entry) } }
        Write-SettingsOrExit -Path $hooksFile -Json ($settings | ConvertTo-Json -Depth 100) -SettingsRel $HooksFileRel
    }
    Write-Host "  + $HooksFileRel (merge-guard wired)"

    Write-Host ""
    Write-Host "  Active hooks:"
    Write-Host "    merge-guard (PreToolUse: Bash)"
    Write-Host "  Fallback hooks, stated as instructions in AGENTS.md:"
    Write-Host "    gate-write, ratchet-check, em-dash-guard, auto-trigger-orchestrator,"
    Write-Host "    check-orchestrator-presence, check-design, check-reply-prefix"
    Write-Host "  Review and trust the project hooks with /hooks in Codex."
    Write-Host "  Until you trust it, Codex skips merge-guard, including in codex exec."
}

function Invoke-RavintioGuardrails {
    Write-Host ""
    Write-Host "  Activating RAVINTIO Git Guardrails"

    # Point Git to the version-controlled hooks directory
    git config core.hooksPath ravintio-zero/hooks
    Write-Host "  + git config core.hooksPath ravintio-zero/hooks"

    # Note: chmod is not available on Windows; hooks are made executable by setup.sh on Unix.
    # On Windows, Git for Windows respects the executable bit stored in the repo,
    # so no additional step is required here.

    # Deploy the CI/CD pipeline workflow
    $githubWorkflows = Join-Path $ProjectRoot '.github\workflows'
    $workflowSrc = Join-Path $ScriptDir 'hooks\ravintio.yml'
    if (Test-Path $workflowSrc) {
        New-Item -ItemType Directory -Path $githubWorkflows -Force | Out-Null
        $dest = Join-Path $githubWorkflows 'ravintio.yml'
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $workflowSrc -Destination $dest -Force
            Write-Host "  + .github/workflows/ravintio.yml (created)"
        }
        else {
            Write-Host "  - .github/workflows/ravintio.yml (already exists, skipped)"
        }
    }

    # Deploy .gitattributes to enforce LF endings on hook scripts.
    # Without this, Git for Windows re-adds CRLF on checkout, breaking the bash shebang.
    $gitattributesSrc = Join-Path $ScriptDir '.gitattributes'
    $gitattributesDest = Join-Path $ProjectRoot '.gitattributes'
    if (Test-Path $gitattributesSrc) {
        if (-not (Test-Path $gitattributesDest)) {
            Copy-Item -Path $gitattributesSrc -Destination $gitattributesDest -Force
            Write-Host "  + .gitattributes (created - enforces LF on hook scripts)"
        }
        else {
            Write-Host "  - .gitattributes (already exists, skipped)"
        }
    }

    Write-Host "  $([char]0x2705) Git guardrails activated."
}

function Initialize-RavintioRepo {
    Write-Host ""
    Write-Host "  Initializing Repository Structure"

    $gitignoreSrc = Join-Path $ScriptDir ".gitignore"
    $gitignoreDest = Join-Path $ProjectRoot ".gitignore"
    
    if (Test-Path $gitignoreSrc) {
        if (-not (Test-Path $gitignoreDest)) {
            Copy-Item -Path $gitignoreSrc -Destination $gitignoreDest
            Write-Host "  + .gitignore (copied)"
        }
        else {
            Write-Host "  - .gitignore (already exists at root, skipped)"
        }
    }
    else {
        Write-Host "  ! Warning: .gitignore not found in the ravintio-zero directory ($gitignoreSrc)"
    }

    $srcDir = Join-Path $ProjectRoot "src"
    if (-not (Test-Path $srcDir)) {
        New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
        Write-Host "  + src/ (created)"
    }
    
    $srcReadme = Join-Path $srcDir "README.md"
    if (-not (Test-Path $srcReadme)) {
        Set-Content -Path $srcReadme -Value @'
# src/

Components live here. Each component is a subfolder with a `component.yml` manifest.

See [plan/feature-structure.md](../plan/feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + src/README.md (created)"
    }

    $planDir = Join-Path $ProjectRoot "plan"
    if (-not (Test-Path $planDir)) {
        New-Item -ItemType Directory -Path $planDir -Force | Out-Null
        Write-Host "  + plan/ (created)"
    }
    
    $planReadme = Join-Path $planDir "README.md"
    if (-not (Test-Path $planReadme)) {
        Set-Content -Path $planReadme -Value @'
# plan/

Feature specifications live here. Each feature gets a subfolder.

See [plan/feature-structure.md](feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + plan/README.md (created)"
    }

    $planStructure = Join-Path $planDir "feature-structure.md"
    if (-not (Test-Path $planStructure)) {
        Set-Content -Path $planStructure -Value @'
# RAVINTIO - Repository Structure

> The canonical layout for a RAVINTIO-managed repository. Three top-level folders, three concerns.

---

## The Three Folders

```
repo/
+-- ravintio-zero/        <- The pack (skills, templates, schemas, standards)
|                                  Drop this in. Don't modify it per-project.
|
+-- plan/                       <- The specifications (organized by feature)
|                                  Plans, briefs, specs, ADRs, risk, scope, glossary.
|                                  Everything that describes WHAT to build and WHY.
|
+-- src/                        <- The code (organized by component)
                                   Implementation, tests, config, manifests.
                                   Everything that IS the built thing.
```

---

## `ravintio-zero/` - The pack

This folder is RAVINTIO Zero itself. It is the same across every project. You do not modify it per-feature - you update it when RAVINTIO Zero evolves.

```
ravintio-zero/
+-- skills/           <- Agent instructions (orchestrator + phase skills)
+-- templates/        <- File format templates for every artifact
+-- schemas/          <- JSON Schema validation definitions
+-- standards/        <- Code quality standards
+-- spec/             <- This file - the canonical structure definition
```

---

## `plan/` - The Plan/Specifications

Organized by feature. Each feature gets a subfolder. This is where humans write briefs and agents write specs. No code lives here.

```
plan/
+-- {feature-id}/
    +-- feature-brief.md          <- Human input (start here)
    +-- design.md                 <- Validated plan (orchestrator output)
    +-- pipeline-run.md              <- Audit trail (per run)
    +-- pipeline-run-phase-2.md      <- Phase 2 audit (if phased)
    |
    +-- design-requirements.md               <- Functional & non-functional requirements
    +-- design-spec-phase-2.md       <- Phase 2 spec (if phased)
    +-- openapi-spec.yaml            <- API contract
    +-- scope.md                     <- In / Out / Deferred
    +-- risk-register.md             <- Risk items with likelihood & impact
    +-- domain-glossary.md           <- Ubiquitous language
    +-- security-report.md           <- Security review findings
    +-- quirks.md                    <- Quirks and workarounds
    +-- recommendations.md           <- Improvement suggestions
    |
    +-- adr/
        +-- ADR-001-{title}.md       <- Architecture decision records
        +-- ADR-002-{title}.md
        +-- ...
```

### Path Rules - plan/

1. **Feature ID** follows the format `{0000000}-{kebab-case-name}` - a 7-digit zero-padded number prefix for chronological ordering, followed by a human-chosen kebab-case name.
2. **No nesting** - specs, ADRs, and supporting docs are flat within the feature folder. One level of subfolders only (adr/).
3. **No code** - nothing executable lives in `plan/`. If it runs, it belongs in `src/`.
4. **Phased features** append the phase number: `design-spec-phase-2.md`, `pipeline-run-phase-2.md`. The `design.md` is updated per phase, not duplicated.
5. **ADRs** are numbered sequentially. Never renumber. Superseded ADRs stay with `status: superseded`.

---

## `src/` - The Code

Organized by component. Each component is a subfolder at the top level of `src/`. The component manifest lives with the code, not with the plan.

```
src/
+-- {component-id}/
    +-- component.yml               <- Component manifest (from template)
    +-- package.json                  <- (or equivalent for the stack)
    |
    +-- src/                          <- Implementation (structure varies by stack)
    |   +-- ...
    |
    +-- tests/                        <- Tests
    |   +-- ...
    |
    +-- docs/
        +-- data-contract.md          <- Schema ownership & invariants
        +-- migrations/
            +-- proposed-{desc}.md    <- Migration proposals
```

### Path Rules - src/

1. **Component ID** is kebab-case, matches the `id` in `component.yml`.
2. **component.yml is mandatory** - every component has one. Read it before any work; update it after every build.
3. **Component-specific docs** live with the component at `src/{component-id}/docs/`. These describe the component's data contract, migrations, and technical specifics.
4. **Feature-level docs** live in `plan/`. The component's `component.yml` references the feature via the `feature` field.
5. **Existing components** that predate RAVINTIO are retrofitted by adding a `component.yml` at their root.

---

## How the Three Folders Connect

```
plan/current/design.md
    +-- lists component IDs -> src/{component-id}/component.yml
                                    +-- references feature -> plan/

plan/current/design-requirements.md
    +-- functional requirements -> implemented in -> src/{component-id}/src/

plan/current/adr/ADR-001-*.md
    +-- decisions -> followed by -> src/{component-id}/src/

plan/current/openapi-spec.yaml
    +-- API contract -> implemented in -> src/{component-id}/src/
```

The relationship is bidirectional:
- `design.md` lists all component IDs
- Each `component.yml` references its feature ID
- The plan describes WHAT; the code IS the WHAT

---

## Retrofit Ã¢â‚¬â€ Adding RAVINTIO to an Existing Repo

If the repo already has code:

1. Drop `ravintio-zero/` into the repo root
2. Create `plan/` for the first feature
3. Move existing components under `src/` (or leave them if they're already there)
4. Add a `component.yml` to each existing component
5. The orchestrator's retrofit mode will read the codebase and infer the existing architecture

---

*Templates for each file are in [ravintio-zero/templates/](../ravintio-zero/templates/). Skills reference these paths.*
'@ -Encoding UTF8
        Write-Host "  + plan/feature-structure.md (created)"
    }

    # Add tool ignore rules to keep context windows lean
    $ignoreContent = @"

# RAVINTIO - Token Reduction (keeps agent semantic search from bloating context)
plan/_archive/
node_modules/
dist/
build/
out/
.next/
"@

    $ignoreFile = '.claudeignore'
    $ignorePath = Join-Path $ProjectRoot $ignoreFile
    if (-not (Test-Path $ignorePath)) {
        Set-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
        Write-Host "  + $ignoreFile (created)"
    }
    else {
        $existing = Get-Content -Path $ignorePath -Raw -Encoding UTF8
        if ($existing -notmatch "RAVINTIO - Token Reduction") {
            Add-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
            Write-Host "  + $ignoreFile (appended RAVINTIO ignore rules)"
        }
    }
}

function Copy-CapabilitySkills {
    # Copies permanent capability skills from ravintio-overrides/capability-skills/
    # into the tool's skill directory (ADR-006). The tool discovers them the same way
    # it discovers built-in skills — no separate registry file needed.
    param($TargetDir)

    $capSkillsDir = Join-Path $ProjectRoot 'ravintio-overrides\capability-skills'
    if (-not (Test-Path $capSkillsDir)) { return }

    $found = @(Get-ChildItem -Path $capSkillsDir -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName 'SKILL.md')
    })
    if ($found.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Syncing capability skills from ravintio-overrides/capability-skills/"
    foreach ($dir in $found) {
        $destDir = Join-Path $TargetDir $dir.Name
        Copy-Item -Path $dir.FullName -Destination $destDir -Recurse -Force
        Write-Host "  + capability-skill: $($dir.Name)"
    }
}

function Remove-OverrideBlock {
    # Removes any ravintio-overrides:instructions marker block from one file.
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }
    $startMarker = '<!-- ravintio-overrides:instructions:start -->'
    $endMarker   = '<!-- ravintio-overrides:instructions:end -->'
    $current = Get-Content -Path $Path -Raw -Encoding UTF8
    if ($current -and $current -match [regex]::Escape($startMarker)) {
        $pattern = "(?s)\r?\n?$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))\r?\n?"
        $current = [regex]::Replace($current, $pattern, '')
        Set-Content -Path $Path -Value $current.TrimEnd() -Encoding UTF8 -NoNewline
    }
}

function Get-OverrideParts {
    # Returns @{ Target; Body } for an override file. Target is $null when the
    # frontmatter has no `target:` key, and '(empty)' when the key has no value.
    param([string]$Path)
    $raw = (Get-Content -Path $Path -Raw -Encoding UTF8)
    $lines = $raw -split "`r?`n"
    $target = $null
    $body = $raw
    if ($lines.Count -gt 0 -and $lines[0] -match '^---\s*$') {
        $end = -1
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^---\s*$') { $end = $i; break }
            if ($null -eq $target -and $lines[$i] -match '^target:\s*(.*?)\s*$') {
                $v = $Matches[1].Trim('"', "'")
                $target = if ($v -eq '') { '(empty)' } else { $v }
            }
        }
        if ($end -ge 0) {
            $body = ($lines[($end + 1)..($lines.Count - 1)] -join "`n")
        } else {
            $target = $null
        }
    }
    return @{ Target = $target; Body = $body }
}

function Append-OverrideInstructions {
    # Appends project-specific instructions from ravintio-overrides/instructions/.
    # An override with `target: {skill}` goes to {skills dir}/{skill}/SKILL.md with
    # its frontmatter stripped. Every other override, and any with a bad target,
    # goes to the boot file. Idempotent: strips and replaces each block on every
    # run (0000245 REQ-002, parity with setup.sh append_override_instructions).
    param($BootFilePath, $SkillsDir)

    $startMarker = '<!-- ravintio-overrides:instructions:start -->'
    $endMarker   = '<!-- ravintio-overrides:instructions:end -->'
    $bootPath = if ($BootFilePath) { Join-Path $ProjectRoot $BootFilePath } else { $null }

    # Drop stale blocks from every installed skill and the boot file
    if ($SkillsDir -and (Test-Path $SkillsDir)) {
        foreach ($sd in @(Get-ChildItem -Path $SkillsDir -Directory -Force)) {
            if ($sd.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
            Remove-OverrideBlock -Path (Join-Path $sd.FullName 'SKILL.md')
        }
    }
    if ($bootPath) { Remove-OverrideBlock -Path $bootPath }

    $instrDir = Join-Path $ProjectRoot 'ravintio-overrides\instructions'
    if (-not (Test-Path $instrDir)) { return }
    $files = @(Get-ChildItem -Path $instrDir -File -Filter '*.md' | Sort-Object Name)
    if ($files.Count -eq 0) { return }

    $bootFiles = @()
    $skillBlocks = [ordered]@{}
    foreach ($file in $files) {
        $parts = Get-OverrideParts -Path $file.FullName
        if ($null -eq $parts.Target) { $bootFiles += $file; continue }
        $t = $parts.Target
        $skillMd = if ($SkillsDir) { Join-Path (Join-Path $SkillsDir $t) 'SKILL.md' } else { $null }
        $ok = $false
        if ($t -cmatch '^[a-z0-9][a-z0-9-]*$' -and $skillMd) {
            $dirItem = Get-Item -LiteralPath (Join-Path $SkillsDir $t) -Force -ErrorAction SilentlyContinue
            $fileItem = Get-Item -LiteralPath $skillMd -Force -ErrorAction SilentlyContinue
            $ok = $dirItem -and $fileItem -and -not $fileItem.PSIsContainer `
                -and -not ($dirItem.Attributes -band [IO.FileAttributes]::ReparsePoint) `
                -and -not ($fileItem.Attributes -band [IO.FileAttributes]::ReparsePoint)
        }
        if ($ok) {
            if (-not $skillBlocks.Contains($t)) { $skillBlocks[$t] = '' }
            $skillBlocks[$t] += "`n" + $parts.Body.TrimEnd() + "`n"
        } else {
            Write-Warning "override $($file.Name) has target '$t' that names no installed skill; appending to the boot file"
            $bootFiles += $file
        }
    }

    foreach ($t in $skillBlocks.Keys) {
        $skillMd = Join-Path (Join-Path $SkillsDir $t) 'SKILL.md'
        $block = "`n`n$startMarker`n" + $skillBlocks[$t] + "`n$endMarker"
        Add-Content -Path $skillMd -Value $block -Encoding UTF8
        Write-Host "  Appending override instructions to $t/SKILL.md"
    }

    if (-not $bootPath -or -not (Test-Path $bootPath) -or $bootFiles.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Appending override instructions from ravintio-overrides/instructions/"

    $block = "`n`n$startMarker`n"
    foreach ($file in $bootFiles) {
        $block += "`n" + (Get-Content -Path $file.FullName -Raw -Encoding UTF8).TrimEnd() + "`n"
        Write-Host "  + $($file.Name)"
    }
    $block += "`n$endMarker"

    Add-Content -Path $bootPath -Value $block -Encoding UTF8
    Write-Host "  ~ $BootFilePath updated with override instructions"
}

# Remove the marker files the pre-rename setup wrote (0000160 REQ-002).
# A symlink or junction is skipped, never followed. Legacy, remove at 1.0.0
# (ADR-002).
function Remove-OldMarkers {
    param([string]$ToolDirRel, [string]$SkillsDirRel)
    $oldMarkers = @(
        ($ToolDirRel + '/.planifest-setup-flags'),
        ($SkillsDirRel + '/.planifest-manifest')
    )
    foreach ($rel in $oldMarkers) {
        $path = Join-Path $ProjectRoot $rel
        # A linked parent folder would send the removal outside the project.
        $linkedParent = $false
        foreach ($dirRel in @($ToolDirRel, ($rel -replace '/[^/]*$', ''))) {
            $dirItem = Get-Item -LiteralPath (Join-Path $ProjectRoot $dirRel) -Force -ErrorAction SilentlyContinue
            if ($dirItem -and ($dirItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $linkedParent = $true }
        }
        if ($linkedParent) {
            [Console]::Error.WriteLine("  ! Warning: skipped $rel under a symlinked folder")
            continue
        }
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($null -eq $item) { continue }
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            [Console]::Error.WriteLine("  ! Warning: skipped symlink $rel")
            continue
        }
        if ($item.PSIsContainer) { continue }
        try {
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
            Write-Host "  - removed $rel"
        }
        catch {
            [Console]::Error.WriteLine("  ! Warning: could not remove $rel")
        }
    }
}

function Invoke-RavintioSetup {
    param($ToolName)

    $toolConfigPath = Join-Path $SetupDir "$ToolName.ps1"
    if (-not (Test-Path $toolConfigPath)) {
        Write-Host "Error: no config file at setup/$ToolName.ps1"
        exit 1
    }

    # Load tool-specific config
    $toolConfig = & $toolConfigPath

    $skillsDir = Join-Path $ProjectRoot $toolConfig.SkillsDir

    Write-Host ""
    Write-Host "  Setting up $ToolName"
    Write-Host "  Skills directory: $($toolConfig.SkillsDir)/"

    # Manifest cleanup — remove only previously installed directories on re-run
    $manifest = Join-Path $skillsDir ".ravintio-manifest"
    if (Test-Path $manifest) {
        Write-Host "  Re-run detected — removing previously installed directories"
        Get-Content -Path $manifest -Encoding UTF8 | Where-Object { $_ -ne '' } | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item -Path $_ -Recurse -Force
                Write-Host "  - removed: $(Split-Path -Leaf $_)"
            }
        }
        Remove-Item -Path $manifest -Force
    }

    # Copy each skill's own folder
    Copy-RavintioSkills -TargetDir $skillsDir

    # Prune folders that no longer exist in the skills/ source set
    Remove-RetiredSkills -TargetDir $skillsDir

    # Copy permanent capability skills from ravintio-overrides/ (ADR-006)
    Copy-CapabilitySkills -TargetDir $skillsDir

    # Copy workflows (if tool defines a workflow dir)
    if ($toolConfig.WorkflowsDir -and (Test-Path $WorkflowsSrc)) {
        $workflowsDir = Join-Path $ProjectRoot $toolConfig.WorkflowsDir
        Get-ChildItem -Path $WorkflowsSrc -Filter '*.md' | ForEach-Object {
            Copy-RavintioWorkflow -WorkflowFile $_.FullName -TargetDir $workflowsDir
        }
    }

    # Create boot file (if tool defines one)
    if ($toolConfig.BootFile) {
        $bootContent = $toolConfig.BootContent
        if (-not $bootContent -and $toolConfig.BootTemplate) {
            $bootContentPath = Join-Path $ProjectRoot $toolConfig.BootTemplate
            $bootContent = Get-Content -Raw -Path $bootContentPath -Encoding UTF8
        }
        Write-RavintioBootFile -RelPath $toolConfig.BootFile -Content $bootContent
    }

    # Append project-specific instructions to boot file (idempotent on re-run)
    # Targeted overrides go to their skill, so this runs after the skill copies.
    Append-OverrideInstructions -BootFilePath $toolConfig.BootFile -SkillsDir $skillsDir

    # Ordered BEFORE the enforcement hook install so that install is the last
    # writer of settings.json this run.
    if ($toolConfig.SettingsFile) {
        Remove-LeftoverSettingsTmp -SettingsRel $toolConfig.SettingsFile
    }

    # Install RAVINTIO enforcement hooks unconditionally (gate-write, check-design)
    if ($toolConfig.EnforcementHooksSrc -and $toolConfig.EnforcementHooksDir -and $toolConfig.SettingsFile) {
        Install-EnforcementHooks `
            -HooksSrcRel $toolConfig.EnforcementHooksSrc `
            -HooksDirRel $toolConfig.EnforcementHooksDir `
            -SettingsRel $toolConfig.SettingsFile
    }

    # Codex wires its own hook set (0000207).
    if ($toolConfig.CodexHooksFile -and $toolConfig.CodexHooksDir) {
        Install-CodexHooks -HooksDirRel $toolConfig.CodexHooksDir -HooksFileRel $toolConfig.CodexHooksFile
    }

    # Add Agent to allowedTools so sub-agent dispatch works without per-use confirmation (REQ-002)
    if ($toolConfig.SettingsFile) {
        $settingsPath = Join-Path $ProjectRoot $toolConfig.SettingsFile
        Merge-AllowedTools -SettingsPath $settingsPath
    }

    # Write manifest listing all installed skill directories (enables safe re-run cleanup)
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    $installedDirs = @(Get-ChildItem -Path $skillsDir -Directory | ForEach-Object { $_.FullName })
    if ($installedDirs.Count -gt 0) {
        $installedDirs | Set-Content -Path $manifest -Encoding UTF8
        Write-Host "  + .ravintio-manifest ($($installedDirs.Count) entries)"
    }

    # Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
    # Guarded on SkillsDir being present so a tool config without one skips silently
    # rather than erroring under $ErrorActionPreference = 'Stop'.
    if ($toolConfig -and $toolConfig.SkillsDir) {
        $toolDir = Split-Path -Parent $toolConfig.SkillsDir
        Remove-OldMarkers -ToolDirRel $toolDir -SkillsDirRel $toolConfig.SkillsDir
        if (Write-SetupConfigOverride -ToolName $ToolName) {
            Remove-LegacySetupConfig -ToolName $ToolName
        }
        Write-SetupFlagsMarker -ToolName $ToolName -ToolDir $toolDir
    }

    Write-Host "  Done."
}

# Write plan/state/{tool}.md — the tracked, git-versioned source of truth for
# active setup flags (0000032 req-002, ADR-001; 0000033 ADR-001 decision 6). This is additive:
# it does not replace Write-SetupFlagsMarker, and it is called BEFORE it so
# the gitignored marker is always (re)written to match this file's values for the current
# run (ADR-001 decision 5, carried over from 0000025 ADR-002 decision 3). On failure to
# write (e.g. permissions), warns and returns $false so the caller falls back to existing
# marker-only behavior rather than aborting setup (req-002 acceptance criteria, sad path).
function Write-SetupConfigOverride {
    param($ToolName)

    $configDir = Join-Path $ProjectRoot 'plan\state'
    $configFile = Join-Path $configDir "$ToolName.md"

    $flags = @()
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $writtenAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $configJson = [ordered]@{
        tool      = $ToolName
        flags     = $flags
        writtenAt = $writtenAt
    } | ConvertTo-Json -Depth 10

    $fence = [char]96 + [char]96 + [char]96
    $content = "# Setup config: $ToolName`n`n" +
        "> Tracked source of truth for active setup flags for **$ToolName**`n" +
        "> (0000032 ADR-001). The gitignored ``.ravintio-setup-flags`` marker in`n" +
        "> this tool's config directory is a local completion-status cache, reconciled to`n" +
        "> match this file on every ``setup.sh``/``setup.ps1`` run.`n`n" +
        "$fence" + "json`n$configJson`n$fence`n"

    try {
        New-Item -ItemType Directory -Path $configDir -Force -ErrorAction Stop | Out-Null
        Set-Content -Path $configFile -Value $content -Encoding UTF8 -ErrorAction Stop
        Write-Host "  + plan/state/$ToolName.md"
        return $true
    } catch {
        Write-Warning "Could not write plan/state/$ToolName.md — continuing with .ravintio-setup-flags-only behavior"
        return $false
    }
}

# Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
# Called only after a tool's setup completes successfully. $ErrorActionPreference = 'Stop' means
# a failed Invoke-RavintioSetup call halts the script before this function is ever reached,
# satisfying REQ-008's "a failed install does not write the marker" requirement.
function Write-SetupFlagsMarker {
    param($ToolName, $ToolDir)

    $targetDir = Join-Path $ProjectRoot $ToolDir
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $markerPath = Join-Path $targetDir '.ravintio-setup-flags'

    $flags = @()
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $marker = [ordered]@{
        tool          = $ToolName
        flags         = $flags
        writtenAt     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        attemptStatus = 'completed'
    }

    $marker | ConvertTo-Json -Depth 10 | Set-Content -Path $markerPath -Encoding UTF8
    Write-Host "  + $ToolDir\.ravintio-setup-flags"
}

# Remove the stale ravintio-overrides\setup-config\{tool}.md left by setup
# runs before 0000032 ADR-001 moved the record to plan\state\ (0000032
# req-003, ADR-003 decisions 1-2). Called only after a successful write of
# plan/state/{tool}.md; a failed write leaves the old file alone since the
# record it depends on isn't in place yet. Removal failure warns and
# continues (ADR-003 decision 4).
function Remove-LegacySetupConfig {
    param($ToolName)

    $legacyDir = Join-Path $ProjectRoot 'ravintio-overrides\setup-config'
    $legacyFile = Join-Path $legacyDir "$ToolName.md"

    if (Test-Path $legacyFile) {
        try {
            Remove-Item -Path $legacyFile -Force -ErrorAction Stop
            Write-Host "  - removed ravintio-overrides/setup-config/$ToolName.md"
        } catch {
            Write-Warning "Could not remove ravintio-overrides/setup-config/$ToolName.md"
        }
    }

    if (Test-Path $legacyDir) {
        $remaining = @(Get-ChildItem -Path $legacyDir -Force -ErrorAction SilentlyContinue)
        if ($remaining.Count -eq 0) {
            try {
                Remove-Item -Path $legacyDir -Force -ErrorAction Stop
                Write-Host "  - removed ravintio-overrides/setup-config/"
            } catch {
                Write-Warning "Could not remove ravintio-overrides/setup-config/"
            }
        }
    }
}

# --- Main ---

if (-not $Tool) {
    Write-Host ""
    Write-Host "RAVINTIO Setup"
    Write-Host ""
    Write-Host "Usage: .\ravintio-zero\setup.ps1 claude-code [flags]"
    Write-Host ""
    Write-Host "Tools:"
    foreach ($t in $ValidTools) {
        Write-Host "  $t"
    }
    Write-Host ""
    Write-Host "Flags:"
    Write-Host "  --strict-orchestrator        Write plan/.orchestrator-strict to enable strict mode."
    Write-Host "                               The check-orchestrator-presence hook will require the"
    Write-Host "                               orchestrator to ack each new session before proceeding."
    Write-Host ""
    Write-Host "Run from the repository root."
    Write-Host "Each tool's config: ravintio-zero\setup\[tool].ps1"
    exit 0
}

# Reject an unknown tool before anything changes in the repo (0000196 REQ-001).
# Exact, case-sensitive match, the same as setup.sh (0000035 S-008).
if (-not ($ValidTools -ccontains $Tool)) {
    # Print only a plain name, so a stray flag value never reaches the
    # output (0000036 S-003).
    if ($Tool -cmatch '^[a-z0-9-]+$') { Write-Host "Unknown tool: $Tool" }
    else { Write-Host "Unknown tool (name not shown)" }
    Write-Host "Valid tools: $($ValidTools -join ', ')"
    exit 1
}

# Stop before installing anything if an old-brand folder is still present
# (0000160 REQ-002, ADR-003). The migration renames it first.
foreach ($oldFolder in @('planifest-zero', 'planifest-overrides')) {
    # Get-Item -Force also finds a dangling link, which Test-Path misses.
    if ($null -ne (Get-Item -LiteralPath (Join-Path $ProjectRoot $oldFolder) -Force -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("! Error: found the old folder $oldFolder/ in this project.")
        [Console]::Error.WriteLine("  Run ravintio-zero/migrations/migrate-ravintio-rename.ps1 first, then rerun setup.")
        exit 1
    }
}

Write-Host "RAVINTIO Setup"
Write-Host ("=" * 40)

Initialize-RavintioRepo
Invoke-RavintioGuardrails

# Write strict-mode sentinel if --strict-orchestrator flag was passed (REQ-008)
if ($StrictOrchestrator) {
    $planDir = Join-Path $ProjectRoot 'plan'
    New-Item -ItemType Directory -Path $planDir -Force | Out-Null
    $strictPath = Join-Path $planDir '.orchestrator-strict'
    New-Item -ItemType File -Path $strictPath -Force | Out-Null
    Write-Host "  + plan/.orchestrator-strict (strict orchestrator mode enabled)"
}

Invoke-RavintioSetup -ToolName $Tool

Write-Host ""
Write-Host "Setup complete."
Write-Host "  Source of truth: ravintio-zero/"
Write-Host "  Re-run after you update the pack."

