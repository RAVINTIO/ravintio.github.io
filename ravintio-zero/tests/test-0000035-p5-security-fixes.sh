#!/usr/bin/env bash
# Tests for feature 0000035-powershell-setup-parity, P5 findings S-001 to
# S-008 in setup.ps1. No pwsh runner exists (backlog 0000084), so these checks
# read the source. Each case names the finding it guards.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SETUP_PS1="$ZERO_DIR/setup.ps1"

extract_function_body() {
  awk -v name="function $1" '
    $0 ~ "^" name { flag=1 }
    flag && /^function / && $0 !~ "^" name { exit }
    flag { print }
  ' "$SETUP_PS1"
}

echo ""
echo "=== S-001: settings.json is read and written as UTF-8 on both versions ==="

assert_equals "0" "$(grep -E 'Get-Content -Raw -Path \$(SettingsPath|settings)' "$SETUP_PS1" | grep -vc 'Encoding UTF8' || true)" \
  "S-001: every Get-Content of settings.json names -Encoding UTF8"
ATOMIC="$(extract_function_body 'Write-SettingsAtomic')"
assert_contains 'UTF8Encoding $false' "$ATOMIC" "S-001: Write-SettingsAtomic writes UTF-8 with no BOM"
assert_equals "0" "$(printf '%s\n' "$ATOMIC" | grep -c 'Set-Content' || true)" \
  "S-001: Write-SettingsAtomic no longer uses Set-Content"

echo ""
echo "=== S-002, S-003: the temporary path never follows a link or recurses ==="

HELPER="$(extract_function_body 'Remove-SettingsTmpEntry')"
assert_contains 'System.IO.FileInfo' "$HELPER" "S-002: the helper reads the entry with FileInfo, so a dangling link is found"
assert_equals "0" "$(printf '%s\n' "$HELPER" | grep -c 'Remove-Item\|Get-Item' || true)" \
  "S-003: the helper uses no Remove-Item or Get-Item"
assert_contains 'Remove-SettingsTmpEntry' "$ATOMIC" "S-002: Write-SettingsAtomic uses the helper"
assert_equals "0" "$(printf '%s\n' "$ATOMIC" | grep -c 'Remove-Item' || true)" \
  "S-003: Write-SettingsAtomic uses no Remove-Item"
assert_contains 'Remove-SettingsTmpEntry' "$(extract_function_body 'Remove-LeftoverSettingsTmp')" \
  "S-002: Remove-LeftoverSettingsTmp uses the helper"

echo ""
echo "=== S-004: the hook filters match module files case-sensitively ==="

# Both events filter through Remove-RavintioHookCommands (0000038 ADR-002).
# It tests each command with -cmatch, and each caller passes a <module>.mjs
# pattern.
MERGE="$(extract_function_body 'Merge-EnforcementHookSettings')"
FILTER_FN="$(extract_function_body 'Remove-RavintioHookCommands')"
assert_equals "1" "$(printf '%s\n' "$FILTER_FN" | grep -c -- '-cmatch \$Pattern' || true)" \
  "S-004: the per-command filter uses -cmatch"
# Three filters since 0000200 added the Stop event.
assert_equals "3" "$(printf '%s\n' "$MERGE" | grep -c -- "-Pattern '.*\\\\.mjs" || true)" \
  "S-004: the three filters pass a <module>.mjs pattern"
assert_equals "0" "$(printf '%s\n' "$MERGE$FILTER_FN" | grep -c -- ' -match ' || true)" \
  "S-004: no filter uses case-insensitive -match"

echo ""
echo "=== S-005: hook commands quote the path, as setup.sh does ==="

assert_contains 'command = "node `"$HooksDir/$Module.mjs`""' "$(extract_function_body 'New-HookEntry')" \
  "S-005: New-HookEntry quotes the module path"
assert_contains 'node \"$hooks_dir_rel/gate-write.mjs\"' "$(cat "$ZERO_DIR/setup.sh")" \
  "S-005: setup.sh quotes the same path"
assert_contains "EnforcementHooksDir = '.claude/hooks/enforcement'" "$(cat "$ZERO_DIR/setup/claude-code.ps1")" \
  "S-005: setup.ps1 uses the same hooks folder as setup.sh"

echo ""
echo "=== S-006: Merge-AllowedTools matches setup.sh ==="

ALLOWED="$(extract_function_body 'Merge-AllowedTools')"
assert_contains "-cnotcontains 'Agent'" "$ALLOWED" "S-006: the Agent check is case-sensitive"
assert_contains '-is [System.Array]' "$ALLOWED" "S-006: a non-array allowedTools counts as empty"
assert_contains 'return' "$ALLOWED" "S-006: a file that isn't a JSON object is left unwritten"

echo ""
echo "=== S-007, S-008: no PowerShell 6 escape, exact tool name ==="

assert_equals "0" "$(cat "$SETUP_PS1" "$ZERO_DIR"/setup/*.ps1 | grep -c '`u{' || true)" \
  "S-007: no \`u{} escape, which PowerShell 5.1 lacks"
assert_equals "0" "$(grep -c 'ToLower()' "$SETUP_PS1" || true)" "S-008: the tool name is not lower-cased"
assert_equals "1" "$(grep -c '\$ValidTools -ccontains \$Tool' "$SETUP_PS1" || true)" \
  "S-008: the tool name must match exactly"

print_summary
