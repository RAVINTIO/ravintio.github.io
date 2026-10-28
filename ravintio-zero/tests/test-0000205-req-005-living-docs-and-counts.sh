#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-005: the living docs hold the
# three parts and the run sequence, and the counts name 16 skills.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO="$ZERO_DIR/.."

echo ""
echo "=== req-005 AC-1: the docs hold the three parts ==="
for f in "$ZERO_DIR/standards/roadmap-standards.md" "$ZERO_DIR/project-operations.md"; do
  assert_contains "| \`ravintio-initiative\` skill |" "$(cat "$f")" "req-005 AC-1: $(basename "$f") holds the three-part table"
  assert_contains "7. **I-E Delivery.**" "$(cat "$f")" "req-005 AC-1: $(basename "$f") holds the seven-step sequence"
done

echo ""
echo "=== req-005 AC-2: the counts agree ==="
for f in "$ZERO_DIR/component.yml" "$ZERO_DIR/pipeline-reference.md" "$REPO/docs/architecture-overview.md"; do
  assert_contains "ravintio-initiative" "$(cat "$f")" "req-005 AC-2: $(basename "$f") names the skill"
done
assert_contains "The 16 skills" "$(cat "$ZERO_DIR/component.yml")" "req-005 AC-2: component.yml counts 16 skills"
assert_contains "sixteen" "$(cat "$REPO/docs/architecture-overview.md")" "req-005 AC-2: the overview counts sixteen skills"
assert_equals "16" "$(ls -d "$ZERO_DIR"/skills/*/ | wc -l | tr -d ' ')" "req-005 AC-2: 16 skill folders"

print_summary
