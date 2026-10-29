#!/usr/bin/env bash
# req-009: P0 step 7 states standard-iterative mode without asking when it is
# the only signal. Conflicts and the other three modes still ask (ADR-004).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ORCH="$(orch_combined "$(cd "$SCRIPT_DIR/.." && pwd)/skills/ravintio-orchestrator")"
S=$(cat "$ORCH")

STEP7=$(printf '%s\n' "$S" | grep -E '^7\. \*\*Detect adoption mode\*\*')
MODES=$(printf '%s\n' "$S" | sed -n '/### Adoption Modes/,/#### Retrofit Scan/p')
CHECK=$(printf '%s\n' "$S" | grep -F -- '- [ ] Adoption mode')

echo "=== req-009: standard-iterative stated without asking ==="
assert_contains "only signal" "$STEP7" \
  "req-009: step 7 covers standard-iterative as the only signal"
assert_contains "without asking" "$STEP7" \
  "req-009: step 7 states standard-iterative without asking"
assert_contains "P0 briefing" "$STEP7" \
  "req-009: step 7 states the assumed mode in the P0 briefing"

echo "=== req-009: the orchestrator still asks for conflicts and other modes ==="
assert_contains "conflict" "$STEP7" \
  "req-009: step 7 still asks when signals conflict"
assert_contains "can't read a signal" "$STEP7" \
  "req-009: an unreadable signal counts as a conflict"
for mode in "External Anchor" "Retrofit" "Greenfield"; do
  assert_contains "$mode" "$STEP7" \
    "req-009: step 7 still asks for $mode"
done
assert_contains "warn once" "$MODES" \
  "req-009: the conflict warning after the Adoption Modes table stays"

echo "=== req-009: the mode is still recorded ==="
for target in "discovery.md" "design.md" "build log"; do
  assert_contains "$target" "$STEP7" \
    "req-009: step 7 records the mode in $target"
done
assert_contains "signal" "$STEP7" \
  "req-009: step 7 records the signal with the mode"

echo "=== req-009: the design checklist accepts an assumed mode ==="
assert_contains "assumed standard-iterative" "$CHECK" \
  "req-009: checklist accepts an assumed standard-iterative mode"

print_summary
