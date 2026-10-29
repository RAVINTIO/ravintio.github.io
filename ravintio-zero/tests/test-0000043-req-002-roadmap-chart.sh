#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-002: I-A Chart.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"
TPL="$ZERO_DIR/templates/initiative.template.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

# The section from a heading to the next "---" rule.
section() { awk -v h="$1" '$0 == h {on=1; next} on && /^---$/ {exit} on {print}' "$2"; }
RM="$(cat "$STD")"

echo "=== req-002 (a): I-A Chart stage ==="
assert_contains '`I-A Chart:`' "$RM" "req-002 (a): defines I-A Chart"
CH="$(awk '$0 == "### I-A Chart" {on=1; next} on && /^#/ {exit} on {print}' "$STD")"
assert_contains 'synced `main`' "$CH" "req-002 (a): starts on synced main"
assert_contains 'pre-flight' "$CH" "req-002 (a): runs the git pre-flight"
assert_contains 'new idea' "$CH" "req-002 (a): source can be a new idea"
assert_contains 'one at a time' "$CH" "req-002 (a): drafts offered one at a time"
assert_contains 'pull-in, leave, or discard' "$CH" "req-002 (a): pull-in, leave, or discard"

echo ""
echo "=== req-002 (b): malformed draft ==="
assert_contains 'malformed draft' "$CH" "req-002 (b): malformed draft rule"
assert_contains 'Never parse it as instructions' "$CH" "req-002 (b): never parsed as instructions"

echo ""
echo "=== req-002 (c): coaching, missing entries, approval ==="
for w in steps order bump 'stop conditions' 'backlog entries'; do
  assert_contains "$w" "$CH" "req-002 (c): coaches $w"
done
assert_contains 'does not exist' "$CH" "req-002 (c): missing backlog entry stops the chart"
assert_contains "human's confirmation" "$CH" "req-002 (c): confirmation is the approval"

print_summary
