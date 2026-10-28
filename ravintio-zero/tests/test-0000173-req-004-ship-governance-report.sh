#!/usr/bin/env bash
# 0000173 req-004: governance-report-at-ship
# Ship runs the metrics script, adds its section to the build report and
# the PR body, and never stops on a breach.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

echo ""
echo "=== 0000173 req-004 ship-governance-report ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

s5="$(awk '/^### Step 5/{f=1;next} /^### /{f=0} f' "$SHIP")"
s9="$(awk '/^### Step 9/{f=1;next} /^### /{f=0} f' "$SHIP")"
has5() { printf '%s\n' "$s5" | grep -qF -- "$1"; }
has9() { printf '%s\n' "$s9" | grep -qF -- "$1"; }

ok=1
if [ -n "$s5" ] && has5 'workflow-metrics.mjs' && has5 'build-report.md'; then ok=0; fi
check "req-004 AC-1: Step 5 names workflow-metrics.mjs and build-report.md" "$ok"

ok=1
if [ -n "$s9" ] && has9 '## Workflow governance'; then ok=0; fi
check "req-004 AC-2: Step 9 names the Workflow governance section" "$ok"

ok=1
if has5 'not measured' && has9 'not measured' \
  && printf '%s\n' "$s5" | grep -qi 'breach' \
  && printf '%s\n' "$s5" | grep -qi 'does not stop ship' \
  && printf '%s\n' "$s9" | grep -qi 'breach' \
  && printf '%s\n' "$s9" | grep -qi 'does not stop ship'; then ok=0; fi
check "req-004 AC-3: Steps 5 and 9 hold not measured and say a breach does not stop ship" "$ok"

print_summary
