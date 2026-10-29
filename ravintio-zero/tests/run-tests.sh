#!/usr/bin/env bash
# Test runner for ravintio-zero tests
# Usage: bash ravintio-zero/tests/run-tests.sh
#
# Environment:
#   RAVINTIO_PWSH=<path>        PowerShell 7 program to run .ps1 suites (default: pwsh)
#   RAVINTIO_REQUIRE_PWSH=1     fail the run when pwsh is missing (0000036 ADR-002)
#   RAVINTIO_PREFLIGHT_ONLY=1   check for stray files, run no suite, and exit
#   RAVINTIO_TEST_QUIET=1       hide PASS lines and banners, keep every failure and the summary

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGRESSION_DIR="$SCRIPT_DIR/regression"
PWSH="${RAVINTIO_PWSH:-pwsh}"

TOTAL_PASS=0
TOTAL_FAIL=0
PS_SKIPPED=0

# ── Pre-flight: every file under tests/ is a suite or a known non-suite ──────
#
# A suite is test-*.sh or test-*.ps1 directly in tests/ or tests/regression/.
# Any other file the runner would skip without a word, which is how a
# misnamed suite once went unrun for a whole release (backlog 0000084). So
# each one is named here, and the run fails (0000036 ADR-001). A new helper or
# data file needs an entry in this list.
KNOWN_NON_SUITES=(
  "README.md"                              # how to run the tests
  "run-tests.sh"                           # this runner
  "run-tests.ps1"                          # the PowerShell-only runner (0000036 ADR-002)
  "test-gate-write-windows.mjs"            # called by test-gate-write-windows.sh
  "helpers/gate-write-harness.mjs"         # shared harness for the 0000164 gate-write suites
  "test-0000164-req-001-gate-write-outside-project.mjs"  # called by the req-001 .sh suite
  "test-0000164-req-002-gate-write-documented-scope.mjs" # called by the req-002 .sh suite
  "test-0000164-req-006-gate-write-symlink-cases.mjs"    # called by the req-006 .sh suite
  "regression/test-gate-write-windows.mjs" # the regression copy of the same
  "regression/regression-manifest.json"    # the promoted-suite list
  "regression/.gitkeep"                    # keeps the folder in git
  "helpers/assert.sh"                      # Bash assert helpers
  "helpers/version.sh"                     # version comparison for the 0000160 req-004 and 0000164 req-011 suites
  "helpers/assert.ps1"                     # PowerShell assert helpers (0000036 ADR-002)
  "helpers/setup-workspace.ps1"            # temporary projects for the setup.ps1 suites
  "fixtures/0000038-hook-filter/README.md"              # what the 0000038 fixtures hold
  "fixtures/0000038-hook-filter/settings-before.json"  # planted settings.json for the 0000038 suites
  "fixtures/0000038-hook-filter/expected-after.txt"    # hook commands after one setup run
  "fixtures/0000039-setup-hardening/README.md"                # what the 0000039 fixtures hold
  "fixtures/0000039-setup-hardening/invalid-settings.json"    # invalid JSON with a planted value (0000039 req-001)
  "fixtures/0000039-setup-hardening/single-object-hooks.json" # single-object hooks values (0000039 req-002)
  "fixtures/0000039-setup-hardening/deep-settings.json"       # a value nested 15 levels deep (0000039 req-003)
  "fixtures/0000151-orchestrator-skill-base.md"               # orchestrator SKILL.md at the base commit (0000151 req-011)
  "fixtures/0000243-resume-detection-base.md"                 # the Resume Detection section before 0000243 (0000243 req-005)
)

is_known_file() {
  local rel="$1" dir base known
  dir="$(dirname "$rel")"
  base="$(basename "$rel")"
  [ "$base" = ".DS_Store" ] && return 0        # macOS Finder metadata
  if [ "$dir" = "." ] || [ "$dir" = "regression" ]; then
    case "$base" in test-*.sh|test-*.ps1) return 0 ;; esac
  fi
  for known in "${KNOWN_NON_SUITES[@]}"; do
    [ "$rel" = "$known" ] && return 0
  done
  return 1
}

UNDISCOVERED=0
while IFS= read -r file; do
  [ -n "$file" ] || continue
  rel="${file#"$SCRIPT_DIR"/}"
  if ! is_known_file "$rel"; then
    echo "Undiscovered file: $rel"
    UNDISCOVERED=$((UNDISCOVERED + 1))
  fi
done <<< "$(find "$SCRIPT_DIR" \( -type f -o -type l \) | LC_ALL=C sort)"

if [ "${RAVINTIO_PREFLIGHT_ONLY:-0}" = "1" ]; then
  [ "$UNDISCOVERED" -eq 0 ]
  exit $?
fi

HAVE_PWSH=0
command -v "$PWSH" >/dev/null 2>&1 && HAVE_PWSH=1

# Runs one suite and prints its name. Returns 0 on pass, 1 on fail, and 2 when
# a PowerShell suite can't run because pwsh is missing. With
# RAVINTIO_TEST_QUIET=1 the output of a passing suite is dropped, and a
# failing suite prints its output with its name once (0000151 req-008).
run_one() {
  local file="$1" quiet_out code name
  name="$(basename "$file")"
  if [ "${RAVINTIO_TEST_QUIET:-0}" = "1" ]; then
    case "$file" in
      *.ps1) [ "$HAVE_PWSH" -eq 0 ] && return 2 ;;
    esac
    quiet_out="$(run_suite_body "$file" 2>&1)"
    code=$?
    if [ "$code" -ne 0 ]; then
      case "$quiet_out" in
        *"--- $name ---"*) ;;
        *) echo ""; echo "--- $name ---" ;;
      esac
      printf '%s\n' "$quiet_out"
    fi
    return "$code"
  fi
  echo ""
  echo "--- $name ---"
  case "$file" in
    *.ps1)
      if [ "$HAVE_PWSH" -eq 0 ]; then
        echo "  SKIP: pwsh not found"
        return 2
      fi
      ;;
  esac
  run_suite_body "$file"
}

run_suite_body() {
  case "$1" in
    *.ps1) "$PWSH" -NoProfile -File "$1" ;;
    *) bash "$1" ;;
  esac
}

run_suite() {
  run_one "$1"
  case $? in
    0) TOTAL_PASS=$((TOTAL_PASS + 1)) ;;
    2) PS_SKIPPED=$((PS_SKIPPED + 1)) ;;
    *) TOTAL_FAIL=$((TOTAL_FAIL + 1)) ;;
  esac
}

# Every test-*.sh and test-*.ps1 in this directory is discovered and run
# automatically. No suite needs to be registered by hand (backlog 0000004:
# hardcoded list silently skipped 5 of 14 suites, including this feature's own).
for suite in "$SCRIPT_DIR"/test-*.sh "$SCRIPT_DIR"/test-*.ps1; do
  [ -e "$suite" ] || continue
  run_suite "$suite"
done

# ── Regression Suite ──────────────────────────────────────────────────────────

REGRESSION_PASS=0
REGRESSION_FAIL=0

echo ""
echo "=== Regression Suite ==="

REGRESSION_TESTS=()
for regression_test in "$REGRESSION_DIR"/test-*.sh "$REGRESSION_DIR"/test-*.ps1; do
  [ -e "$regression_test" ] && REGRESSION_TESTS+=("$regression_test")
done

if [ "${#REGRESSION_TESTS[@]}" -eq 0 ]; then
  echo "  No regression tests yet."
else
  for regression_test in "${REGRESSION_TESTS[@]}"; do
    run_one "$regression_test"
    case $? in
      0) REGRESSION_PASS=$((REGRESSION_PASS + 1)) ;;
      2) PS_SKIPPED=$((PS_SKIPPED + 1)) ;;
      *) REGRESSION_FAIL=$((REGRESSION_FAIL + 1)) ;;
    esac
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "================================"
echo "Feature suites:    $TOTAL_PASS passed, $TOTAL_FAIL failed."
echo "Regression suite:  $REGRESSION_PASS passed, $REGRESSION_FAIL failed."
if [ "$PS_SKIPPED" -gt 0 ]; then
  echo "Skipped $PS_SKIPPED PowerShell suites: pwsh not found"
fi
if [ "$UNDISCOVERED" -gt 0 ]; then
  echo "Undiscovered files: $UNDISCOVERED (named above)"
fi
echo "================================"

PS_REQUIRED_FAIL=0
if [ "$PS_SKIPPED" -gt 0 ] && [ "${RAVINTIO_REQUIRE_PWSH:-0}" = "1" ]; then
  echo "RAVINTIO_REQUIRE_PWSH=1, so the skipped PowerShell suites fail the run."
  PS_REQUIRED_FAIL=1
fi

if [ "$TOTAL_FAIL" -eq 0 ] && [ "$REGRESSION_FAIL" -eq 0 ] && [ "$UNDISCOVERED" -eq 0 ] && [ "$PS_REQUIRED_FAIL" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "One or more tests failed."
  exit 1
fi
