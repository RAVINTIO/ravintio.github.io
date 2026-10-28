#!/usr/bin/env bash
# 0000189 req-004: initiative-states
# The initiative template status takes the five lifecycle states and
# roadmap-standards.md names the stage that sets each one.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TPL="$ZERO_DIR/templates/initiative.template.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

echo ""
echo "=== 0000189 req-004 initiative-states ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

ok=1
if [ -f "$TPL" ] && grep -E '^\*\*Status:\*\*|^status:' "$TPL" \
  | grep -qF -- 'proposed | charted | active | delivered | blocked'; then ok=0; fi
if [ -f "$TPL" ] && grep -E '^\*\*Status:\*\*|^status:' "$TPL" | grep -qE 'draft|done'; then ok=1; fi
check "req-004 AC-1: template status field reads proposed | charted | active | delivered | blocked" "$ok"

ok=0
for pair in 'proposed:Drafting' 'charted:I-A Chart' 'active:I-B Activate' 'delivered:I-E Delivery' 'blocked:exception stop'; do
  st="${pair%%:*}"; sg="${pair#*:}"
  grep -F -- "\`$st\`" "$STD" | grep -qF -- "$sg" || ok=1
done
check "req-004 AC-2: roadmap-standards.md names each state with the stage that sets it" "$ok"

print_summary
