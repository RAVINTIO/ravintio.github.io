#!/usr/bin/env bash
# 0000172 req-003: phase-timing
# The build-log template holds the timing rows. The orchestrator and ship
# skills say when to fill them and where to report them.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TPL="$ZERO_DIR/templates/build-log.template.md"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

echo ""
echo "=== 0000172 req-003 phase-timing ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

# AC-1: template holds the timing rows
ok=1
n_end="$(grep -c '^| End |' "$TPL")"
n_wall="$(grep -c '^| Wall clock |' "$TPL")"
if grep -q '^| Run speed |' "$TPL" \
  && [ "$n_end" -ge 2 ] && [ "$n_wall" -ge 2 ] \
  && grep -q '^| Total wall clock |' "$TPL"; then ok=0; fi
check "req-003 AC-1: template holds Run speed, End, Wall clock, Total wall clock rows" "$ok"

# AC-2: orchestrator Phase Invocation closes each phase block
sec="$(awk '/^## Phase Invocation/{f=1;next} /^## /{f=0} f' "$ORCH")"
ok=1
if [ -n "$sec" ] \
  && printf '%s\n' "$sec" | grep -qF 'End' \
  && printf '%s\n' "$sec" | grep -qF 'Wall clock' \
  && printf '%s\n' "$sec" | grep -qi 'completes'; then ok=0; fi
check "req-003 AC-2: Phase Invocation fills End and Wall clock when a phase completes" "$ok"

# AC-3: ship Steps 3 and 5 name wall-clock time, Step 5 names run speed and not recorded
s3="$(awk '/^### Step 3/{f=1;next} /^### /{f=0} f' "$SHIP")"
s5="$(awk '/^### Step 5/{f=1;next} /^### /{f=0} f' "$SHIP")"
ok=1
if [ -n "$s3" ] && [ -n "$s5" ] \
  && printf '%s\n' "$s3" | grep -qi 'wall-clock' \
  && printf '%s\n' "$s5" | grep -qi 'wall-clock' \
  && printf '%s\n' "$s5" | grep -qi 'run speed' \
  && printf '%s\n' "$s5" | grep -qF 'not recorded'; then ok=0; fi
check "req-003 AC-3: ship Steps 3 and 5 list wall-clock time, run speed, not recorded" "$ok"

print_summary
