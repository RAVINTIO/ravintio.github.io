#!/usr/bin/env bash
# Tests for feature 0000196-setup-argument-checks, req-001: setup validates
# the tool straight after argument parsing. An unknown tool exits 1 and
# leaves the repo unchanged. A missing tool keeps its usage text and exit 0.
# A valid tool still installs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000196_req001_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

# Prints one checksum over every path outside .git and every file's content,
# so an added, changed, or removed file changes it.
snapshot() {
  {
    find . -path ./.git -prune -o -print | sort
    find . -path ./.git -prune -o -type f -exec cksum {} + | sort
  } | cksum
}

hooks_path() {
  git config --get core.hooksPath 2>/dev/null || true
}

echo ""
echo "=== req-001 AC-1: an unknown tool exits 1 and leaves the repo unchanged ==="

for tool in windsurf cursor open-code; do
  WS=$(make_workspace)
  cd "$WS"
  BEFORE="$(snapshot)"
  OUT="$(bash ravintio-zero/setup.sh "$tool" 2>&1)"
  EXIT=$?
  assert_equals "1" "$EXIT" "req-001 AC-1: tool $tool exits 1"
  assert_contains "Unknown tool: $tool" "$OUT" "req-001 AC-1: tool $tool prints the Unknown tool line"
  assert_contains "Valid tools: claude-code codex" "$OUT" "req-001 AC-1: tool $tool prints the valid tools"
  assert_equals "$BEFORE" "$(snapshot)" "req-001 AC-1: tool $tool leaves the tree unchanged"
  assert_equals "" "$(hooks_path)" "req-001 AC-1: tool $tool leaves core.hooksPath unset"
  cd /; rm -rf "$WS"
done

echo ""
echo "=== req-001 AC-1: an unknown tool beats the old-folder check ==="

WS=$(make_workspace)
cd "$WS"
mkdir "plan""ifest-zero"
OUT="$(bash ravintio-zero/setup.sh windsurf 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-001 AC-1: unknown tool with an old folder exits 1"
assert_contains "Unknown tool: windsurf" "$OUT" "req-001 AC-1: the tool error comes before the old-folder error"
cd /; rm -rf "$WS"

echo ""
echo "=== req-001 AC-2: a missing tool prints usage, exits 0, and changes nothing ==="

WS=$(make_workspace)
cd "$WS"
BEFORE="$(snapshot)"
OUT="$(bash ravintio-zero/setup.sh 2>&1)"
EXIT=$?
assert_equals "0" "$EXIT" "req-001 AC-2: no tool exits 0"
assert_contains "Usage: ./ravintio-zero/setup.sh claude-code [flags]" "$OUT" "req-001 AC-2: no tool prints the usage text"
assert_equals "$BEFORE" "$(snapshot)" "req-001 AC-2: no tool leaves the tree unchanged"
assert_equals "" "$(hooks_path)" "req-001 AC-2: no tool leaves core.hooksPath unset"
cd /; rm -rf "$WS"

echo ""
echo "=== req-001 AC-3: a valid tool still installs ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
EXIT=$?
assert_exit_zero "$EXIT" "req-001 AC-3: claude-code exits 0"
assert_equals "ravintio-zero/hooks" "$(hooks_path)" "req-001 AC-3: core.hooksPath is ravintio-zero/hooks"
cd /; rm -rf "$WS"

print_summary
