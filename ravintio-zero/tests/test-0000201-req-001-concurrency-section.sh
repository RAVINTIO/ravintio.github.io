#!/usr/bin/env bash
# Tests for feature 0000201-plan-concurrent-work, req-001: the execution plan
# template holds a Concurrency plan section, the plan skill requires it and
# batches independent units, and the mid-pipeline reference rewrites it on a P1 re-run.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
TEMPLATE="$ZERO_DIR/templates/execution-plan.template.md"
PLAN="$ZERO_DIR/skills/ravintio-plan/SKILL.md"
MID="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-mid-pipeline-changes.md"

echo ""
echo "=== req-001 AC-1: the template carries the section ==="
CONC_LINE=$(grep -n '^## Concurrency plan' "$TEMPLATE" | head -1 | cut -d: -f1)
ASSUME_LINE=$(grep -n '^## Assumptions' "$TEMPLATE" | head -1 | cut -d: -f1)
assert_contains "## Concurrency plan" "$(cat "$TEMPLATE")" "req-001 AC-1: the template has a Concurrency plan section"
if [ -n "${CONC_LINE:-}" ] && [ -n "${ASSUME_LINE:-}" ] && [ "$CONC_LINE" -lt "$ASSUME_LINE" ]; then
  assert_contains "before" "before" "req-001 AC-1: the section sits before Assumptions"
else
  assert_contains "before" "not before" "req-001 AC-1: the section sits before Assumptions"
fi
SECTION=$(awk '/^## Concurrency plan/{f=1;next} /^## /{f=0} f' "$TEMPLATE")
assert_contains "| Unit | Depends on | Writes | Batch | Sequential reason |" "$SECTION" "req-001 AC-1: the section holds the five columns"

echo ""
echo "=== req-001 AC-2: the plan skill requires the section ==="
PLAN_TEXT=$(cat "$PLAN")
assert_contains "## Concurrency plan" "$PLAN_TEXT" "req-001 AC-2: the plan skill has a Concurrency plan section"
PSEC=$(awk '/^## Concurrency plan/{f=1;next} /^## /{f=0} f' "$PLAN")
assert_contains "each execution plan" "$PSEC" "req-001 AC-2: the skill requires the section in each plan"
assert_contains "re-plan after a reopened phase" "$PSEC" "req-001 AC-2: the skill requires a rewrite in a re-plan"

echo ""
echo "=== req-002 plan line: independent units share a batch ==="
assert_contains "no dependency and no shared write target" "$PSEC" "req-002: the skill batches independent units together"
assert_contains "Sequential reason" "$PSEC" "req-002: the skill requires a reason for a unit alone in its batch"
assert_contains "check 8" "$PSEC" "req-001: the skill names consistency check 8"

echo ""
echo "=== req-001 AC-3: the re-run reference points to the rule ==="
assert_contains "P1 re-run rewrites the concurrency plan" "$(cat "$MID")" "req-001 AC-3: the reference states a P1 re-run rewrites the concurrency plan"

print_summary
