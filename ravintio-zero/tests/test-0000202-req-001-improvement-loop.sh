#!/usr/bin/env bash
# Tests for feature 0000202-improvement-loops, req-001: the implement skill runs
# a capped improvement loop after GREEN, and the refactor skill has an
# improvement mode.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
IMPL="$ZERO_DIR/skills/ravintio-implement/SKILL.md"
REFACTOR="$ZERO_DIR/skills/ravintio-refactor/SKILL.md"
STD="$ZERO_DIR/standards/agent-dispatch-standards.md"

SKILL_LOOP=$(awk '/^## Improvement loop/{f=1;next} /^## /{f=0} f' "$IMPL")
LOOP=$(awk '/^## Improvement loop/{f=1;next} /^## /{f=0} f' "$STD")
TDD=$(awk '/^## TDD inner loop/{f=1;next} /^## /{f=0} f' "$IMPL")
FAST=$(awk '/^### Fast batch/{f=1;next} /^##/{f=0} f' "$IMPL")

echo ""
echo "=== req-001 AC-1: the implement skill runs a capped loop after GREEN ==="
assert_contains "## Improvement loop" "$(cat "$IMPL")" "req-001 AC-1: the implement skill has an Improvement loop section"
assert_contains "agent-dispatch-standards.md" "$SKILL_LOOP" "req-001 AC-1: the skill points to the dispatch standard"
assert_contains "## Improvement loop" "$(cat "$STD")" "req-001 AC-1: the dispatch standard has an Improvement loop section"
assert_contains "2 cycles" "$SKILL_LOOP" "req-001 AC-1: the section caps the loop at 2 cycles"
assert_contains "per requirement" "$SKILL_LOOP" "req-001 AC-1: the cap is per requirement"
assert_contains "improvement loop" "$TDD" "req-001 AC-1: the TDD loop block names the improvement loop"
assert_contains "improvement loop" "$FAST" "req-001 AC-1: the fast batch names the improvement loop"

echo ""
echo "=== req-001 AC-2: the reviewer is fresh and the loop stops early ==="
assert_contains "fresh context" "$LOOP" "req-001 AC-2: the reviewer runs in a fresh context"
assert_contains "no change worth making" "$LOOP" "req-001 AC-2: the reviewer can return no change worth making"
assert_contains "stops early" "$LOOP" "req-001 AC-2: the loop stops early on no finding"
assert_contains "reverts" "$LOOP" "req-001 AC-2: a failed suite reverts the change"
assert_contains "Improve:" "$SKILL_LOOP" "req-001 AC-2: each cycle appends an Improve marker"
assert_contains "count the" "$LOOP" "req-001 AC-2: a resumed run counts the markers"

echo ""
echo "=== req-001 AC-3: the refactor skill has an improvement mode ==="
RTEXT=$(cat "$REFACTOR")
assert_contains "In improvement mode" "$RTEXT" "req-001 AC-3: the refactor skill describes improvement mode"
assert_contains "with the Hard Limits in force" "$RTEXT" "req-001 AC-3: the hard limits stay in force"
assert_contains "Apply only the change" "$RTEXT" "req-001 AC-3: the mode applies only the reviewer's finding"
assert_contains "reverts the change" "$RTEXT" "req-001 AC-3: a failed suite reverts the change"

print_summary
