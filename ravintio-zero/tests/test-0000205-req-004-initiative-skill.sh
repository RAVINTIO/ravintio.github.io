#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-004: the ravintio-initiative
# skill and the resume split between the skill and the orchestrator.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SKILL="$ZERO_DIR/skills/ravintio-initiative/SKILL.md"
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"

echo ""
echo "=== req-004 AC-1: the skill exists and is short ==="
assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" "req-004 AC-1: the skill file exists"
TEXT=$(cat "$SKILL" 2>/dev/null)
assert_contains "name: ravintio-initiative" "$TEXT" "req-004 AC-1: frontmatter names the skill"
LINES=$(printf '%s\n' "$TEXT" | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$LINES" -gt 1 ] && [ "$LINES" -lt 120 ] && echo yes || echo no)" "req-004 AC-1: the skill has fewer than 120 lines ($LINES)"

echo ""
echo "=== req-004 AC-2: the skill states the method ==="
assert_contains "I-A Chart" "$TEXT" "req-004 AC-2: I-A Chart"
assert_contains "I-B Activate" "$TEXT" "req-004 AC-2: I-B Activate"
assert_contains "I-E Delivery" "$TEXT" "req-004 AC-2: I-E Delivery"
assert_contains "at least every 5 minutes" "$TEXT" "req-004 AC-2: the 5-minute report"
assert_contains "**Initiative:**" "$TEXT" "req-004 AC-2: the Initiative report part"
assert_contains "**Current step:**" "$TEXT" "req-004 AC-2: the Current step report part"
assert_contains "plan/.initiative-queue/" "$TEXT" "req-004 AC-2: the backlog queue folder"
assert_contains "plan/.initiative-ack" "$TEXT" "req-004 AC-2: the initiative ack file"
assert_contains "Never run, resume, or edit a step" "$TEXT" "req-004 AC-2: the skill never resumes a step"
assert_contains "initiative-watch.mjs" "$TEXT" "req-004 AC-2: the skill starts the watch script"
assert_contains "stale" "$TEXT" "req-004 AC-2: the skill flags a stale log"

echo ""
echo "=== req-004 AC-3: the orchestrator no longer resumes an initiative ==="
ORCH_TEXT=$(cat "$ORCH")
RESUME=$(printf '%s\n' "$ORCH_TEXT" | sed -n '/^## Resume Detection/,/^## Pack Index/p')$'\n'$(cat "$(dirname "$ORCH")/references/orchestrator-resume-detection.md")
assert_contains "ravintio-initiative" "$RESUME" "req-004 AC-3: Resume Detection names the initiative skill"
assert_contains "never resumes an initiative" "$RESUME" "req-004 AC-3: the orchestrator never resumes an initiative"
assert_equals "no" "$(printf '%s\n' "$RESUME" | grep -q "run I-E Delivery" && echo yes || echo no)" "req-004 AC-3: Resume Detection does not run I-E Delivery"

print_summary
