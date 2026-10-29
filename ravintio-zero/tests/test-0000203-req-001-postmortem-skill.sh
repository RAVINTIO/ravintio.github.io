#!/usr/bin/env bash
# Tests for feature 0000203-blameless-postmortems, req-001: the
# ravintio-postmortem skill and its record template.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SKILL="$ZERO_DIR/skills/ravintio-postmortem/SKILL.md"
TEMPLATE="$ZERO_DIR/templates/postmortem.template.md"

echo ""
echo "=== req-001 AC-1: the skill exists and is short ==="
assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" "req-001 AC-1: the skill file exists"
TEXT=$(cat "$SKILL" 2>/dev/null)
assert_contains "name: ravintio-postmortem" "$TEXT" "req-001 AC-1: frontmatter names the skill"
LINES=$(printf '%s\n' "$TEXT" | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$LINES" -gt 1 ] && [ "$LINES" -lt 120 ] && echo yes || echo no)" "req-001 AC-1: the skill has fewer than 120 lines ($LINES)"

echo ""
echo "=== req-001 AC-2: the skill states the method ==="
assert_contains "failed CI run" "$TEXT" "req-001 AC-2: trigger failed CI run"
assert_contains "Blocked:" "$TEXT" "req-001 AC-2: trigger Blocked stop"
assert_contains "self-correction" "$TEXT" "req-001 AC-2: trigger P2 self-correction"
assert_contains "escaped defect" "$TEXT" "req-001 AC-2: trigger escaped defect"
assert_contains "human request" "$TEXT" "req-001 AC-2: trigger human request"
assert_contains "blameless" "$TEXT" "req-001 AC-2: the blameless rule"
assert_contains "timeline" "$TEXT" "req-001 AC-2: the timeline"
assert_contains "5 whys" "$TEXT" "req-001 AC-2: the 5 whys method"
assert_contains "process, check, standard, or tool" "$TEXT" "req-001 AC-2: the chain ends at a process or tool gap"
assert_contains "person or an agent" "$TEXT" "req-001 AC-2: a chain that ends at a person or agent is rejected"
assert_contains "corrective" "$TEXT" "req-001 AC-2: corrective action"
assert_contains "preventive" "$TEXT" "req-001 AC-2: preventive action"
assert_contains "detective" "$TEXT" "req-001 AC-2: detective action"
assert_contains "backlog entry or a repo instruction" "$TEXT" "req-001 AC-2: each action is filed"

echo ""
echo "=== req-001 AC-3: records live outside the archive ==="
assert_contains "plan/postmortems/" "$TEXT" "req-001 AC-3: the skill writes to plan/postmortems/"
assert_contains "Write nothing under \`plan/current/\`" "$TEXT" "req-001 AC-3: nothing is written under plan/current/"
TPL=$(cat "$TEMPLATE" 2>/dev/null)
assert_contains "## Timeline" "$TPL" "req-001 AC-3: the template has a timeline"
assert_contains "## 5 whys" "$TPL" "req-001 AC-3: the template has a 5 whys section"
assert_contains "## Actions" "$TPL" "req-001 AC-3: the template has an actions section"

print_summary
