#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-006 (ADR-002).
#
# The bash-suites CI job runs run-tests.sh on ubuntu-latest, with pwsh
# required, read-only contents, a pinned checkout, and no secrets. Whether
# the job passes is checked on the PR itself.

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
JOB="$(awk '/^  bash-suites:/{f=1; print; next} f && /^  [a-z][a-z-]*:/{exit} f{print}' "$WORKFLOW")"

assert_equals "yes" "$([ -n "$JOB" ] && echo yes || echo no)" "req-006: the bash-suites job exists"
assert_contains "runs-on: ubuntu-latest" "$JOB" "req-006: the job runs on ubuntu-latest"
assert_contains "contents: read" "$JOB" "req-006: the job has read-only contents permission"
assert_equals "0" "$(printf '%s\n' "$JOB" | grep -c 'secrets\.' || true)" "req-006: the job uses no secrets"
assert_contains "RAVINTIO_REQUIRE_PWSH: \"1\"" "$JOB" "req-006: the job requires pwsh"
assert_contains "bash ravintio-zero/tests/run-tests.sh" "$JOB" "req-006: the job runs run-tests.sh"
assert_equals "1" "$(printf '%s\n' "$JOB" | grep -cE 'uses: actions/checkout@[0-9a-f]{40}' || true)" \
  "req-006: the job pins actions/checkout to a commit"
assert_contains "persist-credentials: false" "$JOB" "req-006: the job leaves no token in .git/config"

# Both test jobs pin the same checkout commit.
PINS="$(grep -oE 'uses: actions/checkout@[0-9a-f]{40}' "$WORKFLOW" | sort -u | wc -l | tr -d ' ')"
assert_equals "1" "$PINS" "req-006: every pinned checkout uses the same commit"

assert_contains "bash-suites" "$(cat "$SCRIPT_DIR/README.md")" "req-006: tests/README.md describes the bash-suites job"

print_summary
