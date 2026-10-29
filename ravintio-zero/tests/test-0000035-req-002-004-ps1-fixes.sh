#!/usr/bin/env bash
# Tests for feature 0000035-powershell-setup-parity, req-002 to req-004.
#
# req-003: setup.ps1 uses no -AsHashtable, so it runs on Windows PowerShell
# 5.1 (ADR-002). req-004: the flag switch is case-sensitive (ADR-003). The
# req-002 checks tested the legacy telemetry cleanup, which 0000164 retired.
# No pwsh runner exists (backlog 0000084), so these checks read the source.

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
echo "=== req-003: setup.ps1 runs on Windows PowerShell 5.1 ==="

assert_equals "0" "$(cat "$SETUP_PS1" "$ZERO_DIR"/setup/*.ps1 | grep -c -- '-AsHashtable' || true)" \
  "req-003: setup.ps1 and setup/*.ps1 use no -AsHashtable"
ALLOWED="$(extract_function_body 'Merge-AllowedTools')"
# 0000151 req-005 routes the write through Write-SettingsOrExit, which wraps
# Write-SettingsAtomic, so the write stays atomic.
assert_contains "Write-SettingsOrExit" "$ALLOWED" \
  "req-003: Merge-AllowedTools writes through Write-SettingsOrExit"
assert_contains "Write-SettingsAtomic" "$(extract_function_body 'Write-SettingsOrExit')" \
  "req-003: Merge-AllowedTools still writes through Write-SettingsAtomic"
assert_contains "notcontains 'Agent'" "$ALLOWED" \
  "req-003: Merge-AllowedTools still adds Agent only once"

echo ""
echo "=== req-004: setup.ps1 flags are case-sensitive ==="

assert_equals "1" "$(grep -c 'switch -CaseSensitive (\$args\[\$i\])' "$SETUP_PS1" || true)" \
  "req-004: the argument loop uses switch -CaseSensitive"
assert_equals "1" "$(grep -c "^        '--strict-orchestrator' {" "$SETUP_PS1" || true)" \
  "req-004: the --strict-orchestrator label is lower case"

print_summary
