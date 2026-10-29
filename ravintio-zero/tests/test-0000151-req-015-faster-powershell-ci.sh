#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-015.
#
# The windows-powershell job runs Windows PowerShell 5.1 and PowerShell 7 as a
# parallel matrix, and the workspace helpers print per-case timing.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORKFLOW="$SCRIPT_DIR/../../.github/workflows/ravintio.yml"
HELPER="$SCRIPT_DIR/helpers/setup-workspace.ps1"

if [ -f "$WORKFLOW" ]; then
  JOB="$(awk '/^  windows-powershell:/{f=1; print; next} f && /^  [a-z][a-z-]*:/{exit} f{print}' "$WORKFLOW")"

  assert_contains "strategy:" "$JOB" "req-015: the job defines a strategy"
  assert_contains "fail-fast: false" "$JOB" "req-015: one failing entry does not cancel the other"
  assert_contains "matrix:" "$JOB" "req-015: the job defines a matrix"
  assert_equals "2" "$(printf '%s\n' "$JOB" | grep -cE '^ *- shell: ' || true)" "req-015: the matrix has exactly two entries"
  assert_contains "- shell: powershell" "$JOB" "req-015: one entry is Windows PowerShell 5.1"
  assert_contains "- shell: pwsh" "$JOB" "req-015: one entry is PowerShell 7"
  assert_contains 'shell: ${{ matrix.shell }}' "$JOB" "req-015: the step takes its shell from the matrix"
  # GitHub rejects an expression in a step's shell key, so it must sit under
  # the job's defaults.run.
  assert_contains "$(printf 'defaults:\n      run:\n        shell: ${{ matrix.shell }}')" "$JOB" "req-015: the matrix shell is the job's default run shell"
  assert_equals "1" "$(printf '%s\n' "$JOB" | grep -cE 'shell: \$\{\{' || true)" "req-015: no step sets an expression shell"
  assert_equals "1" "$(printf '%s\n' "$JOB" | grep -c 'ravintio-zero/tests/run-tests.ps1' || true)" \
    "req-015: one run-tests.ps1 invocation per matrix entry"
  assert_contains "runs-on: windows-latest" "$JOB" "req-015: the job keeps windows-latest"
  assert_contains "contents: read" "$JOB" "req-015: the job keeps read-only contents"
  assert_equals "0" "$(printf '%s\n' "$JOB" | grep -c 'secrets\.' || true)" "req-015: the job uses no secrets"
  assert_equals "1" "$(printf '%s\n' "$JOB" | grep -cE 'uses: actions/checkout@[0-9a-f]{40}' || true)" \
    "req-015: the checkout stays pinned to a commit"
  assert_contains "persist-credentials: false" "$JOB" "req-015: the checkout leaves no token"

  BASH_JOB="$(awk '/^  bash-suites:/{f=1; print; next} f && /^  [a-z][a-z-]*:/{exit} f{print}' "$WORKFLOW")"
  assert_contains 'RAVINTIO_REQUIRE_PWSH: "1"' "$BASH_JOB" "req-015: bash-suites still requires pwsh"
else
  echo "  SKIP: no repo workflow next to ravintio-zero/, so this is a consumer copy"
fi

# Timing goes to the host, never into the pipeline a test captures.
assert_equals "3" "$(grep -c 'Write-Host .*\[timing\]' "$HELPER" || true)" \
  "req-015: the helpers print three timing lines"
assert_contains "[timing] workspace copy" "$(cat "$HELPER")" "req-015: workspace copy time is printed"
assert_contains "[timing] pwsh start-up" "$(cat "$HELPER")" "req-015: pwsh start-up time is printed"
assert_contains "[timing] setup.ps1" "$(cat "$HELPER")" "req-015: setup.ps1 run time is printed"

print_summary
