#!/usr/bin/env bash
# Tests for feature 0000204-run-and-initiative-retrospectives, req-002: the
# ship and delivery hooks, and the P0 and chart reads.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
CATALOGUE="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-skills-catalogue.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
ROADMAP="$ZERO_DIR/standards/roadmap-standards.md"

STEP5=$(awk '/^### Step 5: Build assessment/{f=1;next} /^### /{f=0} f' "$SHIP")
CHART=$(awk '/^### I-A Chart/{f=1;next} /^### /{f=0} f' "$ROADMAP")
DELIVERY=$(awk '/^### I-E Delivery/{f=1;next} /^### /{f=0} f' "$ROADMAP")
DISCOVERY=$(cat "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-discovery-coaching.md")

echo ""
echo "=== req-002 AC-1: ship writes the run retrospective ==="
assert_contains "ravintio-retrospective" "$STEP5" "req-002 AC-1: Step 5 names the skill"
assert_contains "run mode" "$STEP5" "req-002 AC-1: Step 5 uses run mode"
assert_contains "plan/retrospectives/" "$STEP5" "req-002 AC-1: Step 5 names the record folder"
assert_contains "Retrospective:" "$STEP5" "req-002 AC-1: the build report lists the record"

echo ""
echo "=== req-002 AC-2: delivery writes the initiative retrospective ==="
assert_contains "ravintio-retrospective" "$DELIVERY" "req-002 AC-2: I-E Delivery names the skill"
assert_contains "initiative mode" "$DELIVERY" "req-002 AC-2: I-E Delivery uses initiative mode"
ARCHIVE_LINE=$(printf '%s\n' "$DELIVERY" | grep -n 'Move `plan/current-initiative/`' | head -1 | cut -d: -f1)
RETRO_LINE=$(printf '%s\n' "$DELIVERY" | grep -n 'initiative mode' | head -1 | cut -d: -f1)
PR_LINE=$(printf '%s\n' "$DELIVERY" | grep -n 'gh pr create' | head -1 | cut -d: -f1)
assert_equals "yes" "$([ -n "$ARCHIVE_LINE" ] && [ -n "$RETRO_LINE" ] && [ -n "$PR_LINE" ] && [ "$ARCHIVE_LINE" -lt "$RETRO_LINE" ] && [ "$RETRO_LINE" -lt "$PR_LINE" ] && echo yes || echo no)" "req-002 AC-2: the record comes after the archive and before the PR"
assert_contains "retrospective" "$(printf '%s\n' "$DELIVERY" | grep -i 'body')" "req-002 AC-2: the PR body lists the record"

echo ""
echo "=== req-002 AC-3: P0 and chart read past records ==="
assert_contains "plan/retrospectives/" "$DISCOVERY" "req-002 AC-3: the discovery coaching reference reads retrospectives"
assert_contains "plan/retrospectives/" "$CHART" "req-002 AC-3: I-A Chart reads retrospectives"
assert_contains "| ravintio-retrospective |" "$(cat "$CATALOGUE")" "req-002 AC-3: the catalogue has a row"

echo ""
echo "=== req-002 AC-4: neither stage blocks on a missing record ==="
assert_contains "never block" "$(cat "$SHIP" "$ROADMAP")" "req-002 AC-4: a missing retrospective never blocks"

print_summary
