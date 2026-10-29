#!/usr/bin/env bash
# Tests for feature 0000204-run-and-initiative-retrospectives, req-003: the
# living docs name the skill and count 16 skills.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO="$ZERO_DIR/.."

echo ""
echo "=== req-003 AC-1: the docs name the skill ==="
for f in "$ZERO_DIR/component.yml" "$ZERO_DIR/pipeline-reference.md" "$REPO/docs/architecture-overview.md"; do
  assert_contains "ravintio-retrospective" "$(cat "$f")" "req-003 AC-1: $(basename "$f") names the skill"
done
assert_contains "The 16 skills" "$(cat "$ZERO_DIR/component.yml")" "req-003 AC-1: component.yml counts 16 skills"
assert_contains "sixteen" "$(cat "$REPO/docs/architecture-overview.md")" "req-003 AC-1: the overview counts sixteen skills"

echo ""
echo "=== req-003 AC-2: the skill folder count is 16 ==="
assert_equals "16" "$(ls -d "$ZERO_DIR"/skills/*/ | wc -l | tr -d ' ')" "req-003 AC-2: 16 skill folders"

print_summary
