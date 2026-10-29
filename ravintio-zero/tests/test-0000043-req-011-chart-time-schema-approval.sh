#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-011: chart-time schema approval.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
TPL="$ZERO_DIR/templates/initiative.template.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"
CH="$(awk '$0 == "### I-A Chart" {on=1; next} on && /^#/ {exit} on {print}' "$STD")"
RC="$(awk '$0 == "### I-C Run" {on=1; next} on && /^#/ {exit} on {print}' "$STD")"
echo "=== req-011 (a) and (b): Chart predicts and approves schema changes ==="
SC="$(awk '$0 == "### Chart-time schema approval" {on=1; next} on && /^### / {exit} on {print}' "$STD")"
T="$(cat "$TPL")"
assert_contains 'Chart-time schema approval' "$CH" "req-011 (a): Chart points to chart-time schema approval"
assert_contains 'data contracts' "$SC" "req-011 (a): Chart surveys the data contracts each step touches"
assert_contains '`## Schema changes`' "$SC" "req-011 (a): predicted changes go in the Schema changes table"
assert_contains 'approves, edits, or strikes each row' "$SC" "req-011 (a): human approves, edits, or strikes each row"
assert_contains 'approves every row left in the table' "$SC" "req-011 (a): chart confirmation approves the remaining rows"
assert_contains "pre-approve additive changes that Chart didn't predict" "$SC" "req-011 (b): asks the opt-in fallback question"
assert_contains 'The default is `stop`' "$SC" "req-011 (b): fallback defaults to stop"
assert_contains 'Hard Limit 4' "$SC" "req-011 (c): destructive rows still stop under Hard Limit 4"
assert_contains '## Schema changes' "$T" "req-011 (b): template has a Schema changes section"
assert_contains '| Step | Component | Change | Kind |' "$T" "req-011 (b): template has the Schema changes table"
assert_contains '**Unpredicted additive changes:**' "$T" "req-011 (b): template records the fallback answer"

echo ""
echo "=== req-011 (c): a step matches chart-approved changes ==="
SC="$(awk '$0 == "### Chart-time schema approval" {on=1; next} on && /^### / {exit} on {print}' "$STD")"
IMPL="$(cat "$ZERO_DIR/skills/ravintio-implement/SKILL.md")"
assert_contains 'Chart-time schema approval' "$RC" "req-011 (c): I-C Run points to chart-time schema approval"
assert_contains 'still writes the proposal' "$SC" "req-011 (c): the step still writes the migration proposal"
assert_contains 'same component, the same field names and types' "$SC" "req-011 (c): match needs same component, field names, and types"
assert_contains '`approved (initiative chart)`' "$SC" "req-011 (c): a match is marked approved (initiative chart)"
assert_contains 'carry on without stopping' "$SC" "req-011 (c): a match does not stop"
assert_contains 'normal schema-change exception stop' "$SC" "req-011 (c): no match stops unless the fallback is pre-approved"
assert_contains '`approved (initiative chart fallback)`' "$SC" "req-011 (c): fallback marks unpredicted additive changes"
assert_contains 'A destructive change always stops' "$SC" "req-011 (c): destructive changes always stop"
assert_contains 'roadmap-standards.md' "$(printf '%s\n' "$IMPL" | grep 'Schema changes')" "req-011 (c): implement schema rule points to the initiative standard"

print_summary
