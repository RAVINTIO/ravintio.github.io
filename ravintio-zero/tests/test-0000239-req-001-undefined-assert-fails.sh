#!/usr/bin/env bash
# Test: 0000239 req-001 undefined-assert-fails
# A call to an undefined assert_* function fails the suite, and
# assert_not_contains passes on an absent needle and fails on a present one.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== req-001 AC-1: an undefined assert function fails the suite ==="
# A fixture copy of the helpers without assert_not_contains.
mkdir -p "$TMP/helpers"
sed '/^assert_not_contains() {/,/^}/d' "$SCRIPT_DIR/helpers/assert.sh" > "$TMP/helpers/assert.sh"
cat > "$TMP/suite.sh" <<'SUITE'
#!/usr/bin/env bash
source "$(dirname "$0")/helpers/assert.sh"
assert_not_contains "x" "abc" "negative check"
print_summary
SUITE
OUT="$(bash "$TMP/suite.sh" 2>&1)"; RC=$?
assert_equals "yes" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "suite exits non-zero"
assert_contains "FAIL: undefined assert function: assert_not_contains" "$OUT" "FAIL line names the function"

echo "=== req-001 AC-1: other unknown commands keep the shell default ==="
cat > "$TMP/other.sh" <<'SUITE'
#!/usr/bin/env bash
source "$(dirname "$0")/helpers/assert.sh"
not_an_assert_name 2>/dev/null
print_summary
SUITE
bash "$TMP/other.sh" >/dev/null 2>&1; RC=$?
assert_equals "0" "$RC" "a non-assert unknown command does not fail the suite"

echo "=== req-001 AC-2: assert_not_contains checks absence ==="
OUT="$(RAVINTIO_TEST_QUIET=0 bash -c 'source "$1"; assert_not_contains needle "hay stack" absent; assert_not_contains stack "hay stack" present; print_summary' _ "$SCRIPT_DIR/helpers/assert.sh" 2>&1)"
assert_contains "PASS: absent" "$OUT" "absent needle passes"
assert_contains "FAIL: present" "$OUT" "present needle fails"

print_summary
