#!/usr/bin/env bash
# Tests for feature 0000247-git-state-hygiene, req-001: the orchestrator and
# ship skills tell a step of an active initiative to stage by explicit path and
# never to stage a backlog entry the step did not write.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

echo ""
echo "=== req-001 AC-1: the orchestrator carries the rule ==="
O=$(cat "$ORCH")
assert_contains "active initiative" "$O" "req-001 AC-1: the rule names an active initiative"
assert_contains "explicit path" "$O" "req-001 AC-1: the rule says to stage by explicit path"
assert_contains "plan/backlog/" "$O" "req-001 AC-1: the rule names plan/backlog/"
assert_contains "did not write" "$O" "req-001 AC-1: the rule bans entries the step did not write"

echo ""
echo "=== req-001 AC-2: the ship skill carries the rule ==="
S=$(awk '/^### Step 4: Archive/{f=1;next} /^### /{f=0} f' "$SHIP")
assert_contains "active initiative" "$S" "req-001 AC-2: Step 4 names an active initiative"
assert_contains "explicit path" "$S" "req-001 AC-2: Step 4 says to stage by explicit path"
assert_contains "plan/changelog/" "$S" "req-001 AC-2: Step 4 names plan/changelog/"
assert_contains "plan/_archive/" "$S" "req-001 AC-2: Step 4 names plan/_archive/"
assert_contains "did not write" "$S" "req-001 AC-2: Step 4 bans entries the step did not write"

echo ""
echo "=== req-001 AC-3: the orchestrator stays under its cap ==="
BYTES=$(wc -c < "$ORCH" | tr -d ' ')
assert_equals "yes" "$([ "$BYTES" -le 9000 ] && echo yes || echo no)" "req-001 AC-3: orchestrator SKILL.md holds $BYTES bytes (cap 9000)"

print_summary
