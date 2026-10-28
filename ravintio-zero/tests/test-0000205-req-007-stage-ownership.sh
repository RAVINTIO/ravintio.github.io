#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-007: each initiative stage has
# one owner, and the three-part table and run sequence are in the standards.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD=$(cat "$ZERO_DIR/standards/roadmap-standards.md")
ORCH=$(cat "$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md")

echo ""
echo "=== req-007 AC-1: each stage has one owner ==="
for row in "I-A Chart:\` | \`ravintio-initiative\`" "I-B Activate:\` | \`ravintio-initiative\`" "I-E Delivery:\` | \`ravintio-initiative\`" "I-C Run:\` | \`ravintio-orchestrator\`" "I-D Advance:\` | \`ravintio-ship\`"; do
  assert_contains "$row" "$STD" "req-007 AC-1: stage row has its owner ($row)"
done
assert_contains "### The three parts" "$STD" "req-007 AC-1: the standards hold the three-part section"
assert_contains "7. **I-E Delivery.**" "$STD" "req-007 AC-1: the standards hold the run sequence"
assert_equals "no" "$(printf '%s\n' "$ORCH" | grep -qF "Chart runs on" && echo yes || echo no)" "req-007 AC-1: the orchestrator holds no I-A procedure"
assert_equals "no" "$(printf '%s\n' "$ORCH" | grep -qF "Activate turns a charted" && echo yes || echo no)" "req-007 AC-1: the orchestrator holds no I-B procedure"
assert_equals "no" "$(printf '%s\n' "$ORCH" | grep -qF "Archive the initiative" && echo yes || echo no)" "req-007 AC-1: the orchestrator holds no I-E procedure"

print_summary
