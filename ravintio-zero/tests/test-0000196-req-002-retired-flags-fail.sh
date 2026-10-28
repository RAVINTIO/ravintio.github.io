#!/usr/bin/env bash
# Tests for feature 0000196-setup-argument-checks, req-002: a retired flag
# exits 1 during argument parsing, names the flag, and leaves the repo
# unchanged. A --backend-url value never reaches the output. ADR-002
# reverses 0000034 ADR-001, which warned and carried on.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
RETIRED_FLAGS=(--structured-telemetry-mcp --context-mode-mcp --include-full-skill-library --backend-url)
SECRET_URL="http://retired-backend.invalid:9999/path"

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000196_req002_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

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
echo "=== req-002 AC-1 and AC-2: each retired flag exits 1, is named, and changes nothing ==="

for flag in "${RETIRED_FLAGS[@]}"; do
  WS=$(make_workspace)
  cd "$WS"
  BEFORE="$(snapshot)"
  OUT="$(bash ravintio-zero/setup.sh claude-code "$flag" 2>&1)"
  EXIT=$?
  assert_equals "1" "$EXIT" "req-002 AC-1: $flag exits 1"
  assert_contains "retired flag $flag" "$OUT" "req-002 AC-1: the error names $flag"
  assert_contains "does nothing" "$OUT" "req-002 AC-1: the error for $flag says it does nothing"
  assert_contains "Remove it from the command" "$OUT" "req-002 AC-1: the error for $flag says to remove it"
  assert_equals "$BEFORE" "$(snapshot)" "req-002 AC-2: $flag leaves the tree unchanged"
  assert_equals "" "$(hooks_path)" "req-002 AC-2: $flag leaves core.hooksPath unset"
  cd /; rm -rf "$WS"
done

echo ""
echo "=== req-002 AC-1: a retired flag before the tool name still exits 1 ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh --context-mode-mcp claude-code 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-002 AC-1: a retired flag before the tool exits 1"
assert_contains "retired flag --context-mode-mcp" "$OUT" "req-002 AC-1: the error names the flag"
cd /; rm -rf "$WS"

echo ""
echo "=== req-002 AC-3: a --backend-url value stays out of the output ==="

WS=$(make_workspace)
cd "$WS"
BEFORE="$(snapshot)"
OUT="$(bash ravintio-zero/setup.sh claude-code --backend-url "$SECRET_URL" 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-002 AC-3: the spaced form exits 1"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'retired-backend.invalid' || true)" \
  "req-002 AC-3: the spaced form never prints the value"
assert_equals "$BEFORE" "$(snapshot)" "req-002 AC-3: the spaced form leaves the tree unchanged"
OUT="$(bash ravintio-zero/setup.sh claude-code "--backend-url=$SECRET_URL" 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-002 AC-3: the = form exits 1"
assert_contains "retired flag --backend-url" "$OUT" "req-002 AC-3: the = form names --backend-url"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'retired-backend.invalid' || true)" \
  "req-002 AC-3: the = form never prints the value"
assert_equals "$BEFORE" "$(snapshot)" "req-002 AC-3: the = form leaves the tree unchanged"
cd /; rm -rf "$WS"

echo ""
echo "=== req-002: an unknown flag still exits 1 and --strict-orchestrator still works ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh claude-code --bogus 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-002: --bogus exits 1"
assert_contains "Unknown flag: --bogus" "$OUT" "req-002: --bogus prints Unknown flag"
OUT="$(bash ravintio-zero/setup.sh claude-code --strict-orchestrator 2>&1)"
EXIT=$?
assert_exit_zero "$EXIT" "req-002: --strict-orchestrator exits 0"
assert_equals "yes" "$([ -f plan/.orchestrator-strict ] && echo yes || echo no)" "req-002: --strict-orchestrator writes the sentinel"
cd /; rm -rf "$WS"

print_summary
