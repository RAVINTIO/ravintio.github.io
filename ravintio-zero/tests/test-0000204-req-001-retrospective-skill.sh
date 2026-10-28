#!/usr/bin/env bash
# Tests for feature 0000204-run-and-initiative-retrospectives, req-001: the
# ravintio-retrospective skill and its record template.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SKILL="$ZERO_DIR/skills/ravintio-retrospective/SKILL.md"
TEMPLATE="$ZERO_DIR/templates/retrospective.template.md"

echo ""
echo "=== req-001 AC-1: the skill exists and is short ==="
assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" "req-001 AC-1: the skill file exists"
TEXT=$(cat "$SKILL" 2>/dev/null)
assert_contains "name: ravintio-retrospective" "$TEXT" "req-001 AC-1: frontmatter names the skill"
LINES=$(printf '%s\n' "$TEXT" | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$LINES" -gt 1 ] && [ "$LINES" -lt 120 ] && echo yes || echo no)" "req-001 AC-1: the skill has fewer than 120 lines ($LINES)"

echo ""
echo "=== req-001 AC-2: the skill states the method ==="
assert_contains "run mode" "$TEXT" "req-001 AC-2: the run mode"
assert_contains "initiative mode" "$TEXT" "req-001 AC-2: the initiative mode"
assert_contains "blameless" "$TEXT" "req-001 AC-2: the blameless rule"
assert_contains "person or an agent" "$TEXT" "req-001 AC-2: a cause never names a person or agent"
assert_contains "postmortems" "$TEXT" "req-001 AC-2: the run mode reads postmortems"
assert_contains "Rework:" "$TEXT" "req-001 AC-2: the run mode reads Rework lines"
assert_contains "charted steps, bumps, and versions" "$TEXT" "req-001 AC-2: question 1, charted versus shipped"
assert_contains "friction repeated" "$TEXT" "req-001 AC-2: question 2, repeated friction"
assert_contains "each stop" "$TEXT" "req-001 AC-2: question 3, stops and step duration"
assert_contains "tooling gaps" "$TEXT" "req-001 AC-2: question 4, tooling gaps"
assert_contains "one thing to keep and one to change" "$TEXT" "req-001 AC-2: keep and change are required"
assert_contains "backlog entry or a repo instruction" "$TEXT" "req-001 AC-2: each change is filed"
assert_contains "source retrospective" "$TEXT" "req-001 AC-2: the filed item names its source retrospective"

echo ""
echo "=== req-001 AC-3: records live outside the archive ==="
assert_contains "plan/retrospectives/" "$TEXT" "req-001 AC-3: the skill writes to plan/retrospectives/"
assert_contains "Write nothing under \`plan/current/\`" "$TEXT" "req-001 AC-3: nothing is written under plan/current/"
TPL=$(cat "$TEMPLATE" 2>/dev/null)
assert_contains "## Keep" "$TPL" "req-001 AC-3: the template has a keep section"
assert_contains "## Change" "$TPL" "req-001 AC-3: the template has a change section"
assert_contains "## Actions" "$TPL" "req-001 AC-3: the template has an actions section"

print_summary
