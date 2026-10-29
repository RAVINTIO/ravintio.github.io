#!/usr/bin/env bash
# 0000170 req-001: story-map-pass
# The story map template exists and the plan skill runs a story mapping pass
# before it writes requirements.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TPL="$ZERO_DIR/templates/story-map.template.md"
SKILL="$ZERO_DIR/skills/ravintio-plan/SKILL.md"

echo ""
echo "=== 0000170 req-001 story-map-pass ==="

check() {
  if [ "$2" = "0" ]; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi
}

# AC-1: template exists with the backbone heading and header row
ok=1
[ -f "$TPL" ] && grep -qxF '## Backbone' "$TPL" \
  && grep -qxF '| Activity | Step | Story | Requirement |' "$TPL" && ok=0
check "req-001 AC-1: template holds Backbone heading and header row" "$ok"

# AC-2: the skill names the template by full path (0000171 ADR-004) and the
# artifact table names the map
ok=1
grep -qF '`ravintio-zero/templates/story-map.template.md`' "$SKILL" \
  && grep '^|' "$SKILL" | grep -qF 'plan/current/story-map.md' && ok=0
check "req-001 AC-2: skill names template by full path and map in artifact table" "$ok"

# AC-3: story mapping pass text states order, dispositions, and one question
sec="$(awk '/^## Story mapping pass/{f=1;next} /^## /{f=0} f' "$SKILL")"
ok=1
if [ -n "$sec" ] \
  && printf '%s\n' "$sec" | grep -qi 'before' \
  && printf '%s\n' "$sec" | grep -qi 'requirement' \
  && printf '%s\n' "$sec" | grep -qF 'out of scope' \
  && printf '%s\n' "$sec" | grep -qF 'added as US-nnn' \
  && printf '%s\n' "$sec" | grep -qi 'one question at a time' \
  && printf '%s\n' "$sec" | grep -qi 'gated'; then ok=0; fi
pos_map="$(grep -n '^## Story mapping pass' "$SKILL" | head -1 | cut -d: -f1)"
pos_req="$(grep -n '^## Requirements rules' "$SKILL" | head -1 | cut -d: -f1)"
if [ -z "$pos_map" ] || [ -z "$pos_req" ] || [ "$pos_map" -ge "$pos_req" ]; then ok=1; fi
check "req-001 AC-3: pass precedes requirements rules and states the gap rule" "$ok"

print_summary
