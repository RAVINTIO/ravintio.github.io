#!/usr/bin/env bash
# 0000173 req-003: metric-markers
# Phase skills write one fixed marker line per rework loop, requirement
# change, and gate correction. The governance standard lists every marker.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

IMPL="$ZERO_DIR/skills/ravintio-implement/SKILL.md"
VAL="$ZERO_DIR/skills/ravintio-validate-and-accept/SKILL.md"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
MID="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-mid-pipeline-changes.md"
STD="$ZERO_DIR/standards/workflow-governance-standards.md"
STD_NAME='workflow-governance-standards.md'

echo ""
echo "=== 0000173 req-003 metric-markers ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}
holds() { grep -qF -- "$1" "$2"; }

# AC-1: implement and validate write Rework and name the standard
ok=1
if holds 'Rework: REQ-{nnn}:' "$IMPL" && holds "$STD_NAME" "$IMPL" \
  && holds 'Rework: REQ-{nnn}:' "$VAL" && holds "$STD_NAME" "$VAL"; then ok=0; fi
check "req-003 AC-1: implement and validate hold the Rework marker and name the standard" "$ok"

# AC-2: reference holds Requirement change, orchestrator holds Gate revised
ok=1
if holds 'Requirement change: {cosmetic | additive | contradictory}:' "$MID" \
  && holds "$STD_NAME" "$MID" \
  && holds 'Gate revised: P{N}' "$ORCH"; then ok=0; fi
check "req-003 AC-2: mid-pipeline reference and orchestrator hold their markers" "$ok"

# AC-3: the standard lists every marker
ok=1
if [ -f "$STD" ] && holds 'Rework:' "$STD" && holds 'Blocked:' "$STD" \
  && holds 'Requirement change:' "$STD" && holds 'Gate revised:' "$STD"; then ok=0; fi
check "req-003 AC-3: standard lists Rework, Blocked, Requirement change, Gate revised" "$ok"

print_summary
