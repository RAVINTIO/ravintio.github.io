#!/usr/bin/env bash
# Tests for feature 0000206-chart-time-decisions, req-001 and req-003: the
# Chart-time decisions rules, the template tables, and the worked example.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD="$ZERO_DIR/standards/roadmap-standards.md"
TPL="$ZERO_DIR/templates/initiative.template.md"

SEC=$(sed -n '/^### Chart-time decisions/,/^### I-B Activate/p' "$STD" | tr "[:upper:]" "[:lower:]")
CHART=$(sed -n '/^### I-A Chart/,/^### Chart-time schema approval/p' "$STD")

echo ""
echo "=== req-001 AC-1: the standards state the rules ==="
assert_contains "### chart-time decisions" "$SEC" "req-001 AC-1: the section exists"
assert_contains "pre-mortem" "$SEC" "req-001 AC-1: pre-mortem"
assert_contains "baseline" "$SEC" "req-001 AC-1: baseline"
assert_contains "criterion critic" "$SEC" "req-001 AC-1: criterion critic"
assert_contains "fallback" "$SEC" "req-001 AC-1: fallback"
assert_contains "bump rule" "$SEC" "req-001 AC-1: bump rule"
assert_contains "environment check" "$SEC" "req-001 AC-1: environment check"
assert_contains "retrospective" "$SEC" "req-001 AC-1: retrospective input"
assert_contains "plan/retrospectives/" "$SEC" "req-001 AC-1: reads the retrospective folder"

echo ""
echo "=== req-001 AC-2: the template holds the tables ==="
D=$(grep -n '^## Dependencies' "$TPL" | cut -d: -f1)
DE=$(grep -n '^## Decisions' "$TPL" | cut -d: -f1)
B=$(grep -n '^## Baselines' "$TPL" | cut -d: -f1)
C=$(grep -n '^## Criteria' "$TPL" | cut -d: -f1)
S=$(grep -n '^## Steps' "$TPL" | cut -d: -f1)
assert_equals "yes" "$([ -n "$DE" ] && [ -n "$B" ] && [ -n "$C" ] && [ -n "$S" ] && [ "$D" -lt "$DE" ] && [ "$DE" -lt "$B" ] && [ "$B" -lt "$C" ] && [ "$C" -lt "$S" ] && echo yes || echo no)" "req-001 AC-2: Decisions, Baselines, Criteria sit between Dependencies and Steps"

echo ""
echo "=== req-001 AC-3: Chart names the tables ==="
assert_contains "## Decisions" "$CHART" "req-001 AC-3: Chart names Decisions"
assert_contains "## Baselines" "$CHART" "req-001 AC-3: Chart names Baselines"
assert_contains "## Criteria" "$CHART" "req-001 AC-3: Chart names Criteria"

echo ""
echo "=== req-003 AC-1: the worked example answers the four stops ==="
assert_contains "profile on windows" "$SEC" "req-003 AC-1: profile on Windows"
assert_contains "drop skill bundling" "$SEC" "req-003 AC-1: drop skill bundling"
assert_contains "raise the bump" "$SEC" "req-003 AC-1: raise the bump"
assert_contains "measure per case" "$SEC" "req-003 AC-1: measure per case"

print_summary 2>/dev/null || true
