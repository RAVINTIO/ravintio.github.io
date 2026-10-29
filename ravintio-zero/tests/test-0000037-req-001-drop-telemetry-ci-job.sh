#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-001 (ADR-002).
#
# The validate-telemetry-schema CI job goes. The workflow then reads no
# secret and names no old folder. The other jobs stay.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORKFLOW="$SCRIPT_DIR/../../.github/workflows/ravintio.yml"

if [ ! -f "$WORKFLOW" ]; then
  echo "  SKIP: no repo workflow next to ravintio-zero/, so this is a consumer copy"
  print_summary
  exit 0
fi

# Built by concatenation, so this file does not name the old folder itself.
OLD_FOLDER="planifest-""framework"

count() {
  grep -cE "$1" "$WORKFLOW" || true
}

assert_equals "0" "$(count '^  validate-telemetry-schema:')" "req-001: the workflow has no validate-telemetry-schema job"
assert_equals "0" "$(count 'RAVINTIO_TELEMETRY_URL')" "req-001: the workflow has no RAVINTIO_TELEMETRY_URL"
assert_equals "0" "$(count 'secrets\.')" "req-001: the workflow has no secrets reference"
assert_equals "0" "$(count "$OLD_FOLDER")" "req-001: the workflow names no old folder"

for job in validate-branch self-description-check windows-powershell; do
  assert_equals "1" "$(count "^  $job:")" "req-001: the $job job still exists"
done

print_summary
