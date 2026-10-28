#!/usr/bin/env bash
# Tests for feature 0000164-hardening-and-backlog-skill, req-004:
# setup carries no legacy telemetry cleanup in either shell, leaves old
# telemetry files and entries untouched, and still prunes retired hooks.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

echo ""
echo "=== req-004 (a): the cleanup code is gone ==="
pattern='remove_legacy_telemetry_wiring|Remove-LegacyTelemetryWiring|TELEMETRY_MCP_MATCHER|TelemetryMcpMatcher|TELEMETRY_HOOK_MODULES|TelemetryHookModules'
if grep -n -i -E "$pattern" "$ZERO_DIR/setup.sh" "$ZERO_DIR/setup.ps1" >/dev/null; then r=found; else r=none; fi
assert_equals none "$r" "setup.sh and setup.ps1 name no cleanup symbol"
assert_contains "RETIRED_HOOK_NAMES=" "$(cat "$ZERO_DIR/setup.sh")" "setup.sh defines RETIRED_HOOK_NAMES"
assert_contains '$RetiredHookNames = @(' "$(cat "$ZERO_DIR/setup.ps1")" "setup.ps1 defines \$RetiredHookNames"

echo ""
echo "=== req-004 (b): setup leaves telemetry files and entries alone ==="
WS="$(mktemp -d -t ravintio_0000164_req004_test_XXXXXX)"
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
git init "$WS" >/dev/null 2>&1
mkdir -p "$WS/.claude" "$WS/plan/.telemetry-failures" "$WS/plan/.telemetry-receipts"
echo on >"$WS/.claude/telemetry-enabled"
cat >"$WS/.claude/settings.json" <<'JSON'
{"hooks":{"PostToolUse":[{"matcher":"mcp__structured-telemetry-mcp__emit_event","hooks":[{"type":"command","command":"echo keep-me"}]}]}}
JSON
(cd "$WS" && GIT_CEILING_DIRECTORIES="$(dirname "$WS")" bash ravintio-zero/setup.sh claude-code \
  >"$WS/setup.out" 2>"$WS/setup.err")
assert_exit_zero "$?" "setup exits 0"
[ -e "$WS/.claude/telemetry-enabled" ] && ex=present || ex=absent
assert_equals present "$ex" ".claude/telemetry-enabled stays"
[ -d "$WS/plan/.telemetry-failures" ] && ex=present || ex=absent
assert_equals present "$ex" "plan/.telemetry-failures stays"
[ -d "$WS/plan/.telemetry-receipts" ] && ex=present || ex=absent
assert_equals present "$ex" "plan/.telemetry-receipts stays"
assert_contains "structured-telemetry-mcp" "$(cat "$WS/.claude/settings.json")" "settings.json keeps the telemetry matcher"
if grep -i -q "telemetry" "$WS/setup.out" "$WS/setup.err"; then r=printed; else r=silent; fi
assert_equals silent "$r" "setup prints no telemetry line"

echo ""
echo "=== req-004 (c): retired-hook pruning still works ==="
H="$WS/.claude/hooks/enforcement"
mkdir -p "$H"
echo "// stale" >"$H/emit-event.mjs"
(cd "$WS" && GIT_CEILING_DIRECTORIES="$(dirname "$WS")" bash ravintio-zero/setup.sh claude-code \
  >"$WS/setup2.out" 2>"$WS/setup2.err")
assert_exit_zero "$?" "second setup exits 0"
[ -e "$H/emit-event.mjs" ] && ex=present || ex=absent
assert_equals absent "$ex" "emit-event.mjs is pruned"

rm -rf "$WS"
print_summary
