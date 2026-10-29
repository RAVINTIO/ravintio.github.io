#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when the runner skips a test file without a word.
# Tests for feature 0000036-test-runner-coverage, req-001 and req-003.
#
# req-001 (ADR-001): run-tests.sh names every stray file under tests/ and
# exits 1. req-003 (ADR-002): it runs test-*.ps1 suites with pwsh, or prints
# one skip line with the count. Each case runs the real runner over a small
# copy of tests/, and RAVINTIO_PWSH points it at a missing or fake pwsh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# This suite also runs from tests/regression/, so find tests/ either way.
TESTS_DIR="$SCRIPT_DIR"
[ -f "$TESTS_DIR/run-tests.sh" ] || TESTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$TESTS_DIR/helpers/assert.sh"

# Builds a minimal tests/ folder: the runner, the helpers, one passing bash
# suite, and an empty manifest.
make_tests_dir() {
  local dir
  dir="$(mktemp -d -t ravintio_0000036_runner_XXXXXX)"
  mkdir -p "$dir/tests/helpers" "$dir/tests/regression"
  cp "$TESTS_DIR/run-tests.sh" "$dir/tests/"
  cp "$TESTS_DIR/helpers/assert.sh" "$dir/tests/helpers/"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$dir/tests/test-pass.sh"
  printf '{"tests":[]}\n' > "$dir/tests/regression/regression-manifest.json"
  echo "$dir"
}

echo ""
echo "=== req-001 (a): a stray file fails the run and is named ==="

D="$(make_tests_dir)"
echo 'echo hi' > "$D/tests/my-check.sh"
echo 'notes' > "$D/tests/regression/notes.txt"
OUT="$(RAVINTIO_PWSH=/nonexistent/pwsh bash "$D/tests/run-tests.sh" 2>&1)"
CODE=$?
assert_equals "1" "$CODE" "req-001 (a): the run exits 1"
assert_contains "Undiscovered file: my-check.sh" "$OUT" "req-001 (a): a stray top-level file is named"
assert_contains "Undiscovered file: regression/notes.txt" "$OUT" "req-001 (a): a stray regression file is named"
assert_contains "Feature suites:    1 passed, 0 failed." "$OUT" "req-001 (a): the suites still run"
rm -rf "$D"

echo ""
echo "=== req-001 (b): known non-suites pass, and so does the real tests/ ==="

D="$(make_tests_dir)"
for f in README.md run-tests.ps1 test-gate-write-windows.mjs regression/test-gate-write-windows.mjs \
         regression/.gitkeep helpers/assert.ps1; do
  echo 'x' > "$D/tests/$f"
done
mkdir -p "$D/tests/test-dir"
echo 'x' > "$D/tests/test-dir/test-nested.sh"
echo 'x' > "$D/tests/helpers/test-misplaced.sh"
OUT="$(RAVINTIO_PWSH=/nonexistent/pwsh bash "$D/tests/run-tests.sh" 2>&1)"
assert_equals "2" "$(printf '%s\n' "$OUT" | grep -c 'Undiscovered file:' || true)" \
  "req-001 (b): only the nested suite and the misplaced helper suite are stray"
assert_contains "Undiscovered file: helpers/test-misplaced.sh" "$OUT" \
  "req-001 (b): a suite under helpers/ is stray (P5 S-004)"
assert_contains "Undiscovered file: test-dir/test-nested.sh" "$OUT" \
  "req-001 (b): a suite-shaped file in a subfolder is stray"
rm -rf "$D"

# Only a runner that honours RAVINTIO_PREFLIGHT_ONLY may be called here.
# Any other runner would run the whole pack, this suite included, again.
if grep -q 'RAVINTIO_PREFLIGHT_ONLY' "$TESTS_DIR/run-tests.sh"; then
  OUT="$(RAVINTIO_PREFLIGHT_ONLY=1 bash "$TESTS_DIR/run-tests.sh" 2>&1)"
  CODE=$?
else
  OUT="Undiscovered file: (runner has no pre-flight mode)"
  CODE=1
fi
assert_exit_zero $CODE "req-001 (b): the pre-flight passes on the real tests/"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'Undiscovered file:' || true)" \
  "req-001 (b): the real tests/ has no stray file"

echo ""
echo "=== req-003 (a): with no pwsh, PowerShell suites are skipped out loud ==="

D="$(make_tests_dir)"
echo 'exit 0' > "$D/tests/test-one.ps1"
echo 'exit 0' > "$D/tests/regression/test-two.ps1"
OUT="$(RAVINTIO_REQUIRE_PWSH=0 RAVINTIO_PWSH=/nonexistent/pwsh bash "$D/tests/run-tests.sh" 2>&1)"
CODE=$?
assert_contains "Skipped 2 PowerShell suites: pwsh not found" "$OUT" "req-003 (a): the skip line gives the count"
assert_equals "0" "$CODE" "req-003 (a): a skip alone keeps exit 0"
OUT="$(RAVINTIO_REQUIRE_PWSH=1 RAVINTIO_PWSH=/nonexistent/pwsh bash "$D/tests/run-tests.sh" 2>&1)"
assert_equals "1" "$?" "req-003 (a): RAVINTIO_REQUIRE_PWSH=1 turns the skip into a failure"
rm -rf "$D"

echo ""
echo "=== req-003 (b): a fake pwsh runs once per suite and its exit codes count ==="

D="$(make_tests_dir)"
echo 'exit 0' > "$D/tests/test-one.ps1"
echo 'exit 0' > "$D/tests/regression/test-two.ps1"
printf '{"tests":[{"name":"test-two.ps1"}]}\n' > "$D/tests/regression/regression-manifest.json"
LOG="$D/pwsh.log"
cat > "$D/pwsh" <<FAKE
#!/usr/bin/env bash
echo "\$*" >> "$LOG"
case "\$*" in *test-two.ps1*) exit 1 ;; esac
exit 0
FAKE
chmod +x "$D/pwsh"
OUT="$(RAVINTIO_PWSH="$D/pwsh" bash "$D/tests/run-tests.sh" 2>&1)"
CODE=$?
assert_equals "2" "$(grep -c . "$LOG")" "req-003 (b): the fake pwsh ran once per suite"
assert_contains "-NoProfile -File" "$(cat "$LOG")" "req-003 (b): suites run with -NoProfile -File"
assert_contains "Feature suites:    2 passed, 0 failed." "$OUT" "req-003 (b): a passing .ps1 suite counts as a feature pass"
assert_contains "Regression suite:  0 passed, 1 failed." "$OUT" "req-003 (b): a failing regression .ps1 suite counts as a failure"
assert_equals "1" "$CODE" "req-003 (b): the failure fails the run"
rm -rf "$D"

echo ""
echo "=== req-002: the manifest check covers .ps1 regression suites ==="

for pack in "$TESTS_DIR/test-regression-pack.sh" "$TESTS_DIR/regression/test-regression-pack.sh"; do
  assert_contains "f.endsWith('.ps1')" "$(cat "$pack")" \
    "req-002: $(basename "$(dirname "$pack")")/test-regression-pack.sh lists unlisted .ps1 suites"
done

print_summary
