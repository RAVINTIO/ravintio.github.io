#!/usr/bin/env bash
# Tests for feature 0000206-chart-time-decisions, req-002: a step applies a
# matching decision row, and the skills point to the rules.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD="$ZERO_DIR/standards/roadmap-standards.md"
RUN=$(sed -n '/^### I-C Run/,/^### Driver environment/p' "$STD")
INIT=$(cat "$ZERO_DIR/skills/ravintio-initiative/SKILL.md")
ORCH=$(cat "$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")")
echo ""
echo "=== req-002 AC-1: a step applies a row ==="
assert_contains "## Decisions" "$RUN" "req-002 AC-1: I-C Run reads the Decisions table"
assert_contains "Decision applied (initiative chart): {fork}" "$RUN" "req-002 AC-1: the build log line"
assert_contains "stops only for a fork no row covers" "$RUN" "req-002 AC-1: an uncovered fork stops"
assert_contains "missing table counts as an empty one" "$RUN" "req-002 AC-1: a missing table is empty"

echo ""
echo "=== req-002 AC-2: CI criteria wait for CI ==="
assert_contains "first CI run" "$RUN" "req-002 AC-2: validated after the first CI run"

echo ""
echo "=== req-002 AC-3: the skills point to the rules ==="
assert_contains "## Decisions" "$INIT" "req-002 AC-3: the initiative skill names Decisions"
assert_contains "## Decisions" "$ORCH" "req-002 AC-3: the orchestrator skill names Decisions"
TOTAL=$(find "$ZERO_DIR/skills" -name "SKILL.md" -exec cat {} + | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$TOTAL" -le 1720 ] && echo yes || echo no)" "req-002 AC-3: skill text $TOTAL <= 1720"

print_summary 2>/dev/null || true
