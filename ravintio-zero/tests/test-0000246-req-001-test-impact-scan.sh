#!/usr/bin/env bash
# Tests for feature 0000246-plan-checks-count-and-cap-tests, req-001: the plan
# skill holds a Test impact scan section and the execution plan template holds
# a Test impact section.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
PLAN="$ZERO_DIR/skills/ravintio-plan/SKILL.md"
TEMPLATE="$ZERO_DIR/templates/execution-plan.template.md"

echo ""
echo "=== req-001 AC-1: the plan skill carries the scan ==="
SCAN=$(awk '/^## Test impact scan/{f=1;next} /^## /{f=0} f' "$PLAN")
assert_contains "Skill count" "$SCAN" "req-001 AC-1: the scan names the skill count"
assert_contains "Skill-text budget" "$SCAN" "req-001 AC-1: the scan names the skill-text budget"
assert_contains "Size cap" "$SCAN" "req-001 AC-1: the scan names the size cap"
assert_contains "Backlog entry id" "$SCAN" "req-001 AC-1: the scan names the backlog entry id"
assert_contains "ravintio-zero/tests/" "$SCAN" "req-001 AC-1: the scan greps the tests folder"
assert_contains "none found" "$SCAN" "req-001 AC-1: the scan records none found"

echo ""
echo "=== req-001 AC-2: the template carries the section ==="
SECTION=$(awk '/^## Test impact/{f=1;next} /^## /{f=0} f' "$TEMPLATE")
assert_contains "| Cause | Test | Unit |" "$SECTION" "req-001 AC-2: the section holds the three columns"
IMPACT_LINE=$(grep -n '^## Test impact' "$TEMPLATE" | head -1 | cut -d: -f1)
CONC_LINE=$(grep -n '^## Concurrency plan' "$TEMPLATE" | head -1 | cut -d: -f1)
ORDER=$([ -n "${IMPACT_LINE:-}" ] && [ -n "${CONC_LINE:-}" ] && [ "$IMPACT_LINE" -lt "$CONC_LINE" ] && echo before || echo other)
assert_equals "before" "$ORDER" "req-001 AC-2: the section sits before the Concurrency plan"

echo ""
echo "=== req-001 AC-3: the scan stays small ==="
LINES=$(printf '%s\n' "$SCAN" | grep -c . || true)
assert_equals "yes" "$([ "$LINES" -gt 0 ] && [ "$LINES" -le 15 ] && echo yes || echo no)" "req-001 AC-3: the scan holds 1 to 15 lines ($LINES)"

print_summary
