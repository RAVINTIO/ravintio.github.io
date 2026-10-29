#!/usr/bin/env bash
# Tests for feature 0000201-plan-concurrent-work, req-002: the dispatch standard
# states the concurrent default and the departure rule, and the implement skill
# dispatches by the batches of the plan's concurrency plan.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD="$ZERO_DIR/standards/agent-dispatch-standards.md"
IMPL="$ZERO_DIR/skills/ravintio-implement/SKILL.md"

SECTION=$(awk '/^## Concurrency plan/{f=1;next} /^## /{f=0} f' "$STD")

echo ""
echo "=== req-002 AC-1: the standard states the default ==="
assert_contains "## Concurrency plan" "$(cat "$STD")" "req-002 AC-1: the standard has a Concurrency plan section"
assert_contains "no dependency and no shared write target" "$SECTION" "req-002 AC-1: the section names the no-dependency and no-shared-write rule"
assert_contains "share a batch" "$SECTION" "req-002 AC-1: the section puts such units in one batch"
assert_contains "Sequential reason" "$SECTION" "req-002 AC-1: the section names the Sequential reason column"

echo ""
echo "=== req-002 AC-2: the standard covers departures ==="
assert_contains "departure" "$SECTION" "req-002 AC-2: the section states a departure rule"
assert_contains "build log" "$SECTION" "req-002 AC-2: the departure goes in the build log"
assert_contains "with its reason" "$SECTION" "req-002 AC-2: the departure carries its reason"

echo ""
echo "=== req-002 AC-3: implement dispatches by batch ==="
PAR=$(awk '/^## Parallel dispatch/{f=1;next} /^## /{f=0} f' "$IMPL")
assert_contains "Concurrency plan" "$PAR" "req-002 AC-3: the parallel dispatch section names the concurrency plan"
assert_contains "plan/current/execution-plan.md" "$PAR" "req-002 AC-3: the section names the execution plan as the source"
assert_contains "batches" "$PAR" "req-002 AC-3: the section dispatches by batches"

print_summary
