#!/usr/bin/env bash
# Tests for feature 0000025, req-005: backlog unification for deferred items.
#
# Confirms:
#   1. ravintio-zero/templates/backlog-entry.template.md carries the
#      "Deferral source" field distinguishing discovered mid-flight,
#      deliberate scope decision, and tech debt.
#   2. Backlog mechanics (monotonic id sequence, pull-in/leave/discard
#      pickup) live in the orchestrator's discovery text.
#   3. Subagent out-of-scope filing routes through
#      standards/agent-dispatch-standards.md with a pre-assigned id.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMPLATE="$ZERO_DIR/templates/backlog-entry.template.md"
ORCHESTRATOR="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
DISPATCH="$ZERO_DIR/standards/agent-dispatch-standards.md"

grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

echo ""
echo "=== req-005: backlog-entry.template.md has a Deferral source field ==="

assert_equals "yes" "$(grep_has '\*\*Deferral source:\*\*' "$TEMPLATE")" \
  "req-005: template has a Deferral source field"
assert_equals "yes" "$(grep_has 'discovered mid-flight' "$TEMPLATE")" \
  "req-005: template's Deferral source field names discovered mid-flight"
assert_equals "yes" "$(grep_has 'deliberate scope decision' "$TEMPLATE")" \
  "req-005: template's Deferral source field names deliberate scope decision"
assert_equals "yes" "$(grep_has 'tech debt' "$TEMPLATE")" \
  "req-005: template's Deferral source field names tech debt"

echo ""
echo "=== req-005: template retains source and id-allocation fields ==="

assert_equals "yes" "$(grep_has '\*\*Source feature:\*\*' "$TEMPLATE")" \
  "req-005: template still has Source feature field"
assert_equals "yes" "$(grep_has '\*\*Source phase:\*\*' "$TEMPLATE")" \
  "req-005: template still has Source phase field"
assert_equals "yes" "$(grep_has 'counter file' "$TEMPLATE")" \
  "req-005: template documents the counter-file allocation convention"

echo ""
echo "=== req-005: backlog mechanics live in the orchestrator's discovery text ==="

assert_equals "yes" "$(grep_has 'Backlog pickup' "$ORCHESTRATOR")" \
  "req-005: discovery has a backlog pickup start action"
assert_equals "yes" "$(grep_has 'pull-in / leave / discard' "$ORCHESTRATOR")" \
  "req-005: pickup offers pull-in / leave / discard per entry"
assert_equals "yes" "$(grep_has 'counter file' "$ORCHESTRATOR")" \
  "req-005: backlog ids come from the counter file"
assert_equals "yes" "$(grep_has 'spent ids never return' "$ORCHESTRATOR")" \
  "req-005: spent ids never return"

echo ""
echo "=== req-005: subagent filing routes through the dispatch standards ==="

assert_equals "yes" "$(grep_has 'plan/backlog/{id}-{slug}/entry.md' "$DISPATCH")" \
  "req-005: dispatch standards name the plan/backlog/{id}-{slug}/entry.md target path"
assert_equals "yes" "$(grep_has 'Deferral source: discovered mid-flight' "$DISPATCH")" \
  "req-005: mid-flight discoveries are tagged discovered mid-flight"
assert_equals "yes" "$(grep_has 'backlog-entry.template.md' "$DISPATCH")" \
  "req-005: filings follow the backlog entry template"
assert_equals "yes" "$(grep_has 'pre-computes the next available backlog ID' "$DISPATCH")" \
  "req-005: the dispatching agent pre-computes the backlog id"

print_summary
