#!/usr/bin/env bash
# 0000189 req-008: open-backlog-entries
# Open backlog entries 0000174 to 0000186 use the new initiative terms. Entries
# 0000178, 0000181, and 0000182 carry the agreed wording. No open entry keeps an
# old roadmap-charted-unit name or an R-A to R-E prefix.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

BACKLOG="$ZERO_DIR/../plan/backlog"

echo ""
echo "=== 0000189 req-008 open-backlog-entries ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

entry_of() {
  ls -d "$BACKLOG"/"$1"-*/ 2>/dev/null | head -n 1
}

# req-008 AC-2: named entries carry the agreed wording
e178="$(entry_of 0000178)entry.md"
e181="$(entry_of 0000181)entry.md"
e182="$(entry_of 0000182)entry.md"

ok=1
# Entry 0000178 left the backlog when 0000204 pulled it in. A missing entry passes.
if [ ! -f "$e178" ] || grep -qF -- 'post-initiative retrospective' "$e178"; then ok=0; fi
check "req-008 AC-2: 0000178 says post-initiative retrospective" "$ok"

ok=1
# Entry 0000181 left the backlog when 0000200 pulled it in. A missing entry passes.
if [ ! -f "$e181" ] || grep -qF -- 'I-A' "$e181"; then ok=0; fi
check "req-008 AC-2: 0000181 names the I-A prefix" "$ok"

ok=1
# Entry 0000182 left the backlog when 0000205 pulled it in. A missing entry passes.
if [ ! -f "$e182" ] || { grep -qF -- 'ravintio-initiative' "$e182" \
  && grep -qF -- 'plan/.initiative-ack' "$e182"; }; then ok=0; fi
check "req-008 AC-2: 0000182 names ravintio-initiative and plan/.initiative-ack" "$ok"

# req-008 AC-1: no open entry keeps an old name or an R-A to R-E prefix
found=""
for d in "$BACKLOG"/0000{174..186}-*/; do
  [ -d "$d" ] || continue
  f="$d/entry.md"
  [ -f "$f" ] || continue
  for old in 'current-roadmap' 'roadmap-run' 'RAVINTIO_ROADMAP_' 'roadmap/*' 'roadmap/**'; do
    if grep -qF -- "$old" "$f"; then found="$found $(basename "$d"):$old"; fi
  done
  if grep -qE '(^|[^A-Za-z0-9])R-[A-E]([^A-Za-z0-9]|$)' "$f"; then
    found="$found $(basename "$d"):R-prefix"
  fi
done
ok=1
if [ -z "$found" ]; then ok=0; fi
check "req-008 AC-1: no open entry 0000174 to 0000186 holds an old name${found:+ (found:$found)}" "$ok"

print_summary
