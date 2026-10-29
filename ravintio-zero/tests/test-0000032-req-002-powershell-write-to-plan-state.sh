#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-002:
# powershell-write-to-plan-state.
#
# Covers ADR-001 (setup-config record lives in plan/state/): setup.ps1's
# Write-SetupConfigOverride writes plan/state/{tool}.md instead of
# ravintio-overrides/setup-config/{tool}.md, and Invoke-RavintioSetup keeps
# calling it before Write-SetupFlagsMarker.
#
# No PowerShell runner exists in this CI (backlog 0000084), so pwsh is not
# installed on this machine and these assertions are static: they grep
# setup.ps1's source rather than executing it. A documented manual pwsh run
# fills the execution gap — see tests/README.md.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SETUP_PS1="$ZERO_DIR/setup.ps1"

# Extracts the body of Write-SetupConfigOverride: from its `function` line up
# to the next top-level `function` line.
extract_function_body() {
  local name="$1"
  awk -v name="function $name" '
    $0 ~ "^" name { flag=1 }
    flag && /^function / && $0 !~ "^" name { exit }
    flag { print }
  ' "$SETUP_PS1"
}

BODY="$(extract_function_body 'Write-SetupConfigOverride')"

echo ""
echo "=== req-002: Write-SetupConfigOverride path ==="

assert_contains "plan" "$(echo "$BODY" | grep -o "plan[\\\\/]state" | head -1)" \
  "req-002: Write-SetupConfigOverride references plan/state (or plan\\state)"

if echo "$BODY" | grep -q "ravintio-overrides"; then
  FOUND_OLD="yes"
else
  FOUND_OLD="no"
fi
assert_equals "no" "$FOUND_OLD" \
  "req-002: Write-SetupConfigOverride no longer references ravintio-overrides"

echo ""
echo "=== req-002: call order in Invoke-RavintioSetup ==="

CONFIG_CALL_LINE="$(grep -n 'Write-SetupConfigOverride -ToolName' "$SETUP_PS1" | head -1 | cut -d: -f1)"
MARKER_CALL_LINE="$(grep -n 'Write-SetupFlagsMarker -ToolName' "$SETUP_PS1" | head -1 | cut -d: -f1)"

if [ -n "$CONFIG_CALL_LINE" ] && [ -n "$MARKER_CALL_LINE" ] && [ "$CONFIG_CALL_LINE" -lt "$MARKER_CALL_LINE" ]; then
  ORDER_OK="yes"
else
  ORDER_OK="no"
fi
assert_equals "yes" "$ORDER_OK" \
  "req-002: Invoke-RavintioSetup calls Write-SetupConfigOverride before Write-SetupFlagsMarker"

echo ""
echo "=== req-002: record shape matches the bash version field for field ==="

# Only the [ordered]@{...} hash literal defines field order — the tool/flags
# names also appear earlier in the function body (param checks), so scope the
# extraction to the hash block itself.
ORDERED_HASH="$(echo "$BODY" | awk '/\[ordered\]@\{/{flag=1} flag{print} flag && /\}/{if (/\[ordered\]@\{/ == 0) exit}')"
FIELD_ORDER="$(echo "$ORDERED_HASH" | grep -oE '^\s*(tool|flags|backendUrl|writtenAt)\s*=' | grep -oE '(tool|flags|backendUrl|writtenAt)')"
EXPECTED_ORDER=$'tool\nflags\nwrittenAt'

assert_equals "$EXPECTED_ORDER" "$FIELD_ORDER" \
  "req-002: here-string/JSON block declares tool, flags, writtenAt in bash order"

# ADR-001 decision 6 drops backendUrl from the record entirely.
if echo "$BODY" | grep -q "backendUrl"; then
  FOUND_BACKEND_URL="yes"
else
  FOUND_BACKEND_URL="no"
fi
assert_equals "no" "$FOUND_BACKEND_URL" \
  "req-002: Write-SetupConfigOverride does not mention backendUrl anywhere"

echo ""
echo "=== req-002: success/failure messaging names the new path ==="

assert_contains "plan/state" "$(echo "$BODY" | grep 'Write-Host')" \
  "req-002: success line names plan/state/{tool}.md"

assert_contains "plan/state" "$(echo "$BODY" | grep 'Write-Warning')" \
  "req-002: failure warning names plan/state"

print_summary
