#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-009: resume detection and R- prefixes.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
REF="$ZERO_DIR/pipeline-reference.md"
TPL="$ZERO_DIR/templates/initiative.template.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

# The section from a heading to the next "---" rule.
section() { awk -v h="$1" '$0 == h {on=1; next} on && /^---$/ {exit} on {print}' "$2"; }
RES="$(section '## Resume Detection' "$ORCH")"$'\n'"$(cat "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md")"
ORCH_SEC="$(section '## Phases and Response Prefixes' "$ORCH")"
REF_SEC="$(section '## Phase Indicators' "$REF")"

echo "=== req-009 (a): resume detection ==="
assert_contains 'plan/current-initiative/' "$RES" "req-009 (a): names plan/current-initiative/"
IDX_R="$(printf '%s\n' "$RES" | grep -n 'plan/current-initiative/' | head -1 | cut -d: -f1)"
IDX_C="$(printf '%s\n' "$RES" | grep -n 'Scan `plan/current/`\|plan/current/` for existing' | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$IDX_R" ] && [ -n "$IDX_C" ] && [ "$IDX_R" -le "$IDX_C" ] && echo yes || echo no)" \
  "req-009 (a): initiative is checked before plan/current/"
assert_contains 'With `plan/current/` artifacts, resume that step' "$RES" "req-009 (a): artifacts resume that step"
assert_contains 'with `plan/current/` empty starts the step at `position`' "$RES" "req-009 (a): empty starts at position"
assert_contains 'load `ravintio-initiative` and stop' "$RES" "req-009 (a): a non-step session loads the initiative skill"

echo ""
echo "=== req-009 (b): prefix tables ==="
for label in orchestrator pipeline-reference; do
  # 0000244 moved the I-A to I-E prefix block from the orchestrator to the roadmap standards.
  if [ "$label" = orchestrator ]; then SEC="$ORCH_SEC"$'\n'"$(cat "$STD")"; else SEC="$REF_SEC"; fi
  for p in 'I-A Chart:' 'I-B Activate:' 'I-C Run:' 'I-D Advance:' 'I-E Delivery:'; do
    assert_contains "\`$p\`" "$SEC" "req-009 (b): $label lists \`$p\`"
  done
  assert_contains '`{prefix} {Status}: {one-liner}`' "$SEC" "req-009 (b): $label states the status form"
  assert_contains 'stage letters, not phase numbers' "$SEC" "req-009 (b): $label says I-A to I-E are stage letters"
  assert_contains '`I-C Run: Starting: ' "$SEC" "req-009 (b): $label shows an R- status in the colon form"
done

echo ""
echo "=== req-009 (c): Hard Limit 10 unchanged ==="
assert_contains 'The pipeline has exactly five phases, P0 to P4.' "$(cat "$ORCH")" "req-009 (c): Hard Limit 10 text"
for t in test-0000042-req-004-phase-numbers-p0-to-p4.sh test-0000042-req-005-message-prefixes.sh test-0000042-req-006-phase-guard-and-stale-cites.sh; do
  bash "$SCRIPT_DIR/$t" >/dev/null 2>&1
  assert_equals "0" "$?" "req-009 (c): $t passes"
done

print_summary
