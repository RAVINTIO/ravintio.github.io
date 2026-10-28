#!/usr/bin/env bash
# 0000172 req-002: fast-batches-per-phase
# The dispatch standard defines fast batches, each phase skill lists its fast
# batch, and the orchestrator applies the run speed at each transition.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

STD="$ZERO_DIR/standards/agent-dispatch-standards.md"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
echo ""
echo "=== 0000172 req-002 fast-batches-per-phase ==="

check() {
  if [ "$2" = "0" ]; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi
}

# AC-1: the standard's Fast batches section names the rules
sec="$(awk '/^## Fast batches/{f=1;next} /^## /{f=0} f' "$STD")"
ok=1
if [ -n "$sec" ] \
  && printf '%s\n' "$sec" | grep -qF 'plan/.run-speed' \
  && printf '%s\n' "$sec" | grep -qi 'one message' \
  && printf '%s\n' "$sec" | grep -qi 'disjoint' \
  && printf '%s\n' "$sec" | grep -qi 'in order' \
  && printf '%s\n' "$sec" | grep -qi 'gate'; then ok=0; fi
check "req-002 AC-1: dispatch standard defines fast batches" "$ok"

# AC-2: each phase skill has a Fast batch section naming the run speed file
for skill in plan implement validate-and-accept ship; do
  f="$ZERO_DIR/skills/ravintio-$skill/SKILL.md"
  fsec="$(awk '/^### Fast batch/{f=1;next} /^##/{f=0} f' "$f")"
  ok=1
  if [ -n "$fsec" ] && printf '%s\n' "$fsec" | grep -qF 'plan/.run-speed'; then ok=0; fi
  check "req-002 AC-2: $skill skill lists its fast batch" "$ok"
done

# AC-3: orchestrator Phase Invocation names the run speed file and fast batch
osec="$(awk '/^## Phase Invocation/{f=1;next} /^## /{f=0} f' "$ORCH")"
ok=1
if [ -n "$osec" ] \
  && printf '%s\n' "$osec" | grep -qF 'plan/.run-speed' \
  && printf '%s\n' "$osec" | grep -qi 'fast batch'; then ok=0; fi
check "req-002 AC-3: orchestrator applies the speed at each transition" "$ok"

print_summary
