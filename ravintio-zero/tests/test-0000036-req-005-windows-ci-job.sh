#!/usr/bin/env bash
# Tests for feature 0000036-test-runner-coverage, req-005 (ADR-003).
#
# The windows-powershell CI job runs run-tests.ps1 under Windows PowerShell
# 5.1 and PowerShell 7, with read-only contents and no secrets. Whether the
# job passes is checked on the PR itself.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORKFLOW="$SCRIPT_DIR/../../.github/workflows/ravintio.yml"

if [ ! -f "$WORKFLOW" ]; then
  echo "  SKIP: no repo workflow next to ravintio-zero/, so this is a consumer copy"
  print_summary
  exit 0
fi

# The job block runs from its key to the next job key at the same indent.
JOB="$(awk '/^  windows-powershell:/{f=1; print; next} f && /^  [a-z][a-z-]*:/{exit} f{print}' "$WORKFLOW")"

assert_equals "yes" "$([ -n "$JOB" ] && echo yes || echo no)" "req-005: the windows-powershell job exists"
assert_contains "runs-on: windows-latest" "$JOB" "req-005: the job runs on windows-latest"
assert_contains "contents: read" "$JOB" "req-005: the job has read-only contents permission"
assert_equals "0" "$(printf '%s\n' "$JOB" | grep -c 'secrets\.' || true)" "req-005: the job uses no secrets"
# 0000151 req-015: the two hosts are matrix entries, and one step runs
# run-tests.ps1 for each entry.
assert_contains "shell: powershell" "$JOB" "req-005: one matrix entry runs under Windows PowerShell 5.1"
assert_contains "shell: pwsh" "$JOB" "req-005: one matrix entry runs under PowerShell 7"
assert_equals "2" "$(printf '%s\n' "$JOB" | grep -cE '^ *- shell: ' || true)" "req-005: the matrix has both hosts"
assert_equals "1" "$(printf '%s\n' "$JOB" | grep -c 'ravintio-zero/tests/run-tests.ps1' || true)" \
  "req-005: the step runs run-tests.ps1 for each matrix entry"

# P5 S-005 and S-006.
assert_equals "1" "$(printf '%s\n' "$JOB" | grep -cE 'uses: actions/checkout@[0-9a-f]{40}' || true)" \
  "req-005: the job pins actions/checkout to a commit"
assert_contains "persist-credentials: false" "$JOB" "req-005: the job leaves no token in .git/config"
assert_equals "1" "$(awk '/^jobs:/{exit} /^permissions:/{p=1} p && /^  contents: read/{print}' "$WORKFLOW" | grep -c . || true)" \
  "req-005: the workflow grants contents: read to every job"

print_summary
