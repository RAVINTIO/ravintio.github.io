#!/usr/bin/env bash
# Tests for feature 0000200-reply-conventions, req-001 and req-002: the boot
# template holds the reply conventions, the orchestrator lists Supervise: and
# the reporting rule, and each phase skill opens with its own prefix line.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
BOOT="$ZERO_DIR/templates/standard-boot.md"
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"

RULE_LIST="results, deviations, failures, and decisions"
RULE_BAR="never states that the agent followed a standing rule"
STATUS_FORM='{prefix} {Status}: {one-liner}'

SECTION=$(awk '/^## Reply Conventions/{f=1;next} /^## /{f=0} f' "$BOOT")

echo ""
echo "=== req-001 AC-1: the boot file carries the table ==="
assert_contains "## Reply Conventions" "$(cat "$BOOT")" "req-001 AC-1: the boot file has a Reply Conventions section"
for p in 'P0 Discovery:' 'P1 Plan:' 'P2 Implement:' 'P3 Validate:' 'P4 Ship:' \
         'I-A Chart:' 'I-B Activate:' 'I-C Run:' 'I-D Advance:' 'I-E Delivery:' 'Supervise:'; do
  assert_contains "$p" "$SECTION" "req-001 AC-1: the section holds $p"
done
assert_contains "$STATUS_FORM" "$SECTION" "req-001 AC-1: the section holds the status form"

echo ""
echo "=== req-001 AC-2: the reporting rule is stated twice ==="
assert_contains "$RULE_LIST" "$SECTION" "req-001 AC-2: the boot section names results, deviations, failures, decisions"
assert_contains "$RULE_BAR" "$SECTION" "req-001 AC-2: the boot section bars reporting compliance"
ORCH_TEXT=$(cat "$ORCH")
assert_contains "$RULE_LIST" "$ORCH_TEXT" "req-001 AC-2: the orchestrator names results, deviations, failures, decisions"
assert_contains "$RULE_BAR" "$ORCH_TEXT" "req-001 AC-2: the orchestrator bars reporting compliance"

echo ""
echo "=== req-001 AC-3: the orchestrator lists Supervise: ==="
PREFIX_BLOCK=$(awk '/^## Phases and Response Prefixes/{f=1;next} /^## /{f=0} f' "$ORCH")
assert_contains '`Supervise:`' "$PREFIX_BLOCK" "req-001 AC-3: the prefix section lists Supervise:"
SUP_LINE=$(printf '%s\n' "$PREFIX_BLOCK" | grep -F 'Supervise: ' | grep -F '{Status}' || true)
assert_contains "{Status}: {one-liner}" "$SUP_LINE" "req-001 AC-3: Supervise: appears with the status form"

echo ""
echo "=== req-002 AC-1: each phase skill states its prefix ==="
check_skill() {
  local skill="$1" prefix="$2"
  local head
  head=$(awk 'c>=2{print; n++; if(n>=15) exit} /^---$/{c++}' "$ZERO_DIR/skills/$skill/SKILL.md")
  assert_contains "$prefix" "$head" "req-002 AC-1: $skill holds $prefix in the first 15 lines"
  assert_contains "$STATUS_FORM" "$head" "req-002 AC-1: $skill holds the status form in the first 15 lines"
}
check_skill ravintio-plan 'P1 Plan:'
check_skill ravintio-implement 'P2 Implement:'
check_skill ravintio-validate-and-accept 'P3 Validate:'
check_skill ravintio-ship 'P4 Ship:'

print_summary
