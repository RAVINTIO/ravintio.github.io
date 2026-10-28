#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-002.
#
# The repo refresh script reinstalls Claude Code with no flag that setup has
# retired. It still derives its path from its own location.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

REFRESH="$SCRIPT_DIR/../../refresh-ravintio-zero-dir.ps1"

if [ ! -f "$REFRESH" ]; then
  echo "  SKIP: no refresh script next to ravintio-zero/, so this is a consumer copy"
  print_summary
  exit 0
fi

BODY="$(cat "$REFRESH")"

for flag in --structured-telemetry-mcp --context-mode-mcp --include-full-skill-library --backend-url; do
  assert_equals "0" "$(grep -c -- "$flag" "$REFRESH" || true)" \
    "req-002: the refresh script passes no retired flag $flag"
done

assert_equals "1" "$(grep -cE '^\.\\ravintio-zero\\setup\.ps1 claude-code[[:space:]]*$' "$REFRESH" || true)" \
  "req-002: the refresh script calls ravintio-zero\\setup.ps1 claude-code"
assert_contains "PSScriptRoot" "$BODY" "req-002: the refresh script derives its path from its location"
assert_equals "3" "$(grep -c '^Remove-Item' "$REFRESH" || true)" \
  "req-002: the refresh script keeps its three Remove-Item lines"

print_summary
