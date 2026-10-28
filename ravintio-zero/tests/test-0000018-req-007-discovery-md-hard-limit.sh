#!/usr/bin/env bash
# Tests for feature 0000018 req-007: discovery.md elevated to Hard Limit status
# in ravintio-orchestrator/SKILL.md (self-audit finding, ADR-003).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ORCHESTRATOR="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

# ── AC-1: new Hard Limit entry, matching build-log.md's pattern ─────────────

echo ""
echo "=== req-007: discovery.md Hard Limit entry ==="

HL=$(sed -n '/^## Hard Limits/,/^---/p' "$ORCHESTRATOR")
assert_contains "12." "$HL" \
  "req-007: Hard Limits list has the discovery.md entry"
assert_contains "discovery.md" "$HL" \
  "req-007: the Hard Limit names discovery.md"
assert_contains "pipeline error" "$HL" \
  "req-007: the Hard Limit uses 'pipeline error' teeth"
assert_contains "stop and write it" "$HL" \
  "req-007: the Hard Limit carries the stop-and-write instruction"

# ── AC-2: step 3d cross-references the new Hard Limit ────────────────────────

echo ""
echo "=== req-007: step 3d cross-reference ==="

WRITE_STEP=$(grep "Write .discovery.md." "$ORCHESTRATOR")
assert_contains "Hard Limit 12" "$WRITE_STEP" \
  "req-007: the discovery start action cross-references Hard Limit 12 by number"

# ── AC-3: Gate Checklist has a discovery.md item ─────────────────────────────

echo ""
echo "=== req-007: Gate Checklist item ==="

GATE=$(sed -n '/### Discovery Gate Checklist/,/^## /p' "$ORCHESTRATOR")
assert_contains "discovery.md" "$GATE" \
  "req-007: Gate Checklist has a discovery.md item"
assert_contains "Hard Limit 12" "$GATE" \
  "req-007: Gate Checklist item cross-references Hard Limit 12"

print_summary
