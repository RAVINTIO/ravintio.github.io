#!/usr/bin/env bash
# REGRESSION-CANDIDATE: guards a setup contract that older installs depend on.
# Tests for feature 0000034-setup-hardening, req-001: retired flags.
#
# Covers 0000196 ADR-002, which reverses 0000034 ADR-001: setup fails on each
# of four retired flags during argument parsing, names the flag, leaves the
# repo unchanged, never prints the value after --backend-url, and still exits
# 1 on any other unknown flag. setup.ps1 has no runtime runner here, so its
# half gets static checks. The runtime checks for both shells live in
# test-0000196-req-002-retired-flags-fail.sh and .ps1.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/../.."
RETIRED_FLAGS=(--structured-telemetry-mcp --backend-url --context-mode-mcp --include-full-skill-library)
SECRET_URL="http://retired-backend.invalid:9999/path"

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000034_req001_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

count_lines() {
  printf '%s\n' "$1" | grep -c -- "$2" || true
}

# ── (a): each retired flag fails, setup changes nothing ───────────────────

echo ""
echo "=== req-001 (a): each retired flag exits 1 and is named once ==="

for flag in "${RETIRED_FLAGS[@]}"; do
  WS=$(make_workspace)
  cd "$WS"
  OUT="$(bash ravintio-zero/setup.sh claude-code "$flag" 2>&1)"
  EXIT=$?
  assert_equals "1" "$EXIT" "req-001 (a): setup exits 1 on $flag"
  assert_equals "1" "$(count_lines "$OUT" "retired flag $flag")" \
    "req-001 (a): exactly one error names $flag"
  assert_equals "0" "$(count_lines "$OUT" "Unknown flag")" \
    "req-001 (a): no Unknown flag error for $flag"
  assert_equals "no" "$([ -f .claude/settings.json ] && echo yes || echo no)" \
    "req-001 (a): $flag leaves no settings.json"
  assert_equals "0" "$(count_lines "$OUT" "Setup complete")" \
    "req-001 (a): setup never completes with $flag"
  cd /; rm -rf "$WS"
done

# ── (b): the --backend-url value rule ─────────────────────────────────────

echo ""
echo "=== req-001 (b): the --backend-url value never reaches the output or a file ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh claude-code --backend-url "$SECRET_URL" 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-001 (b): the spaced form exits 1"
assert_equals "0" "$(count_lines "$OUT" "retired-backend.invalid")" \
  "req-001 (b): the spaced form never prints the value"
LEAK="$(grep -rl "retired-backend.invalid" . --exclude-dir=ravintio-zero --exclude-dir=.git 2>/dev/null | head -1)"
assert_equals "" "$LEAK" \
  "req-001 (b): the value is written to no file"
OUT="$(bash ravintio-zero/setup.sh claude-code "--backend-url=$SECRET_URL" 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-001 (b): the --backend-url=value form exits 1"
assert_equals "0" "$(count_lines "$OUT" "retired-backend.invalid")" \
  "req-001 (b): the --backend-url=value form never prints the value"
OUT="$(bash ravintio-zero/setup.sh claude-code "--bogus=$SECRET_URL" 2>&1)"
assert_equals "0" "$(count_lines "$OUT" "retired-backend.invalid")" \
  "req-001 (b): an unknown --flag=value prints the flag name only"
cd /; rm -rf "$WS"

# ── (c): other unknown flags still fail, usage hides retired flags ────────

echo ""
echo "=== req-001 (c): an unknown flag still exits 1 ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh claude-code --bogus 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-001 (c): --bogus exits 1"
assert_contains "Unknown flag: --bogus" "$OUT" "req-001 (c): --bogus prints Unknown flag"
USAGE="$(bash ravintio-zero/setup.sh 2>&1)"
for flag in "${RETIRED_FLAGS[@]}"; do
  assert_equals "0" "$(count_lines "$USAGE" "$flag")" \
    "req-001 (c): usage text doesn't list $flag"
done
cd /; rm -rf "$WS"

# ── (d): setup.ps1 static checks ──────────────────────────────────────────

echo ""
echo "=== req-001 (d): setup.ps1 holds the same retired flags and error ==="

PS1="$ZERO_DIR/setup.ps1"
for flag in "${RETIRED_FLAGS[@]}"; do
  assert_equals "yes" "$(grep -q -- "'$flag'" "$PS1" && echo yes || echo no)" \
    "req-001 (d): setup.ps1 names $flag as retired"
done
assert_equals "yes" "$(grep -q 'retired flag' "$PS1" && echo yes || echo no)" \
  "req-001 (d): setup.ps1 prints a retired flag error"
assert_equals "no" "$(grep -q 'ignoring retired flag' "$PS1" && echo yes || echo no)" \
  "req-001 (d): setup.ps1 no longer warns and carries on"
assert_equals "yes" "$(grep -q 'RetiredFlags -ccontains' "$PS1" && echo yes || echo no)" \
  "req-001 (d): setup.ps1 matches retired flags case-sensitively, like setup.sh"
assert_equals "yes" "$(grep -q "StartsWith('--backend-url=')" "$PS1" && grep -q "split '=', 2" "$PS1" && echo yes || echo no)" \
  "req-001 (d): setup.ps1 never prints a --flag=value value"
assert_equals "yes" "$(grep -q 'Unknown flag' "$PS1" && echo yes || echo no)" \
  "req-001 (d): setup.ps1 still rejects other unknown flags"

print_summary
