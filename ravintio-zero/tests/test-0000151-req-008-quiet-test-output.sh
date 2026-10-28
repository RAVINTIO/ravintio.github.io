#!/usr/bin/env bash
# Test: 0000151 req-008 quiet-test-output
# RAVINTIO_TEST_QUIET=1 hides PASS lines and banners, keeps every FAIL detail,
# leaves exit codes alone, and the skills that run the full suite set it.
# The PowerShell helper cases live in test-0000151-req-008-quiet-test-output.ps1.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/test-pass.sh" <<FIX
source "$SCRIPT_DIR/helpers/assert.sh"
assert_equals "a" "a" "equal case"
assert_contains "b" "abc" "contains case"
assert_exit_zero 0 "exit case"
print_summary
FIX
cat > "$TMP/test-fail.sh" <<FIX
source "$SCRIPT_DIR/helpers/assert.sh"
assert_equals "a" "a" "equal case"
assert_equals "want" "got" "unequal case"
assert_contains "needle-x" "hay-y" "missing needle case"
print_summary
FIX

echo "=== (a) quiet mode, passing suite ==="
OUT=$(RAVINTIO_TEST_QUIET=1 bash "$TMP/test-pass.sh" 2>&1); CODE=$?
assert_equals "0" "$CODE" "quiet passing suite exits 0"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'PASS:')" "quiet passing suite prints no PASS line"
assert_contains "Results: 3 passed, 0 failed" "$OUT" "quiet passing suite prints its summary"

echo "=== (a) quiet mode, failing suite ==="
QOUT=$(RAVINTIO_TEST_QUIET=1 bash "$TMP/test-fail.sh" 2>&1); QCODE=$?
NOUT=$(env -u RAVINTIO_TEST_QUIET bash "$TMP/test-fail.sh" 2>&1); NCODE=$?
assert_equals "$NCODE" "$QCODE" "exit code matches normal mode"
assert_equals "yes" "$([ "$QCODE" -ne 0 ] && echo yes || echo no)" "failing suite exits non-zero"
assert_equals "0" "$(printf '%s\n' "$QOUT" | grep -c 'PASS:')" "quiet failing suite prints no PASS line"
assert_contains "FAIL: unequal case" "$QOUT" "quiet keeps the FAIL line"
assert_contains "expected: want" "$QOUT" "quiet keeps the expected value"
assert_contains "actual:   got" "$QOUT" "quiet keeps the actual value"
assert_contains "needle:   needle-x" "$QOUT" "quiet keeps the needle"
assert_contains "haystack: hay-y" "$QOUT" "quiet keeps the haystack"
assert_equals "1" "$(printf '%s\n' "$QOUT" | grep -c -- '--- test-fail.sh ---')" "quiet names the failing suite once"
FIRST=$(printf '%s\n' "$QOUT" | grep -n -- '--- test-fail.sh ---' | head -1 | cut -d: -f1)
FIRSTFAIL=$(printf '%s\n' "$QOUT" | grep -n 'FAIL:' | head -1 | cut -d: -f1)
assert_equals "yes" "$([ "$FIRST" -lt "$FIRSTFAIL" ] && echo yes || echo no)" "suite name comes before the first FAIL line"

echo "=== (b) normal mode unchanged ==="
POUT=$(env -u RAVINTIO_TEST_QUIET bash "$TMP/test-pass.sh" 2>&1)
assert_contains "  PASS: equal case" "$POUT" "normal mode prints PASS lines"
assert_equals "0" "$(printf '%s\n' "$POUT" | grep -c -- '--- test-pass.sh ---')" "normal mode adds no suite line from the helper"
assert_contains "  FAIL: unequal case" "$NOUT" "normal mode prints FAIL lines"
assert_contains "needle:   needle-x" "$NOUT" "normal mode keeps the needle"
assert_contains "haystack: hay-y" "$NOUT" "normal mode keeps the haystack"

echo "=== (c) runner quiet mode ==="
RT="$TMP/rt"; mkdir -p "$RT/helpers" "$RT/regression"
cp "$SCRIPT_DIR/run-tests.sh" "$RT/"
cp "$SCRIPT_DIR/helpers/assert.sh" "$RT/helpers/"
sed "s|$SCRIPT_DIR|$RT|" "$TMP/test-pass.sh" > "$RT/test-aaa-pass.sh"
sed "s|$SCRIPT_DIR|$RT|" "$TMP/test-fail.sh" > "$RT/test-bbb-fail.sh"
RQ=$(RAVINTIO_TEST_QUIET=1 bash "$RT/run-tests.sh" 2>&1); RQC=$?
RN=$(env -u RAVINTIO_TEST_QUIET bash "$RT/run-tests.sh" 2>&1); RNC=$?
assert_equals "$RNC" "$RQC" "runner exit code matches normal mode"
assert_equals "0" "$(printf '%s\n' "$RQ" | grep -c 'PASS:')" "runner quiet hides PASS lines"
assert_equals "0" "$(printf '%s\n' "$RQ" | grep -c -- '--- test-aaa-pass.sh ---')" "runner quiet hides the passing banner"
assert_equals "1" "$(printf '%s\n' "$RQ" | grep -c -- '--- test-bbb-fail.sh ---')" "runner quiet names the failing suite once"
assert_contains "expected: want" "$RQ" "runner quiet keeps failure detail"
assert_contains "Feature suites:    1 passed, 1 failed." "$RQ" "runner quiet keeps the summary"
assert_contains "--- test-aaa-pass.sh ---" "$RN" "runner normal keeps banners"
assert_contains "  PASS: equal case" "$RN" "runner normal keeps PASS lines"

echo "=== (c) documentation ==="
assert_contains "RAVINTIO_TEST_QUIET" "$(head -12 "$SCRIPT_DIR/run-tests.sh")" "run-tests.sh header documents the variable"
assert_contains "RAVINTIO_TEST_QUIET" "$(head -12 "$SCRIPT_DIR/run-tests.ps1")" "run-tests.ps1 header documents the variable"
for f in $(grep -rl 'run-tests' "$ZERO_DIR/skills" --include=SKILL.md); do
  assert_equals "yes" "$(grep 'run-tests' "$f" | grep -q 'RAVINTIO_TEST_QUIET=1' && echo yes || echo no)" "$(basename "$(dirname "$f")") names RAVINTIO_TEST_QUIET=1 in the command"
done

echo "=== (a) assert.ps1 helpers print and do not recurse ==="
# pwsh may be absent, so read the helper bodies. A helper that calls itself
# recurses until PowerShell stops it and never prints (P3 finding S-002).
PS1_HELPERS="$ZERO_DIR/tests/helpers/assert.ps1"
for h in Write-AssertPass Write-AssertFail; do
  BODY="$(awk -v h="$h" '$0 ~ "^function "h" " {f=1; next} f && /^}/ {exit} f {print}' "$PS1_HELPERS")"
  assert_equals "0" "$(printf '%s\n' "$BODY" | grep -c -- "$h" || true)" "$h does not call itself"
done
assert_contains 'Write-Host "  PASS: $Message"' "$(cat "$PS1_HELPERS")" "Write-AssertPass prints the PASS line"
assert_contains 'Write-Host "  FAIL: $Message"' "$(cat "$PS1_HELPERS")" "Write-AssertFail prints the FAIL line"

print_summary
