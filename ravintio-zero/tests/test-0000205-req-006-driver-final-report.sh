#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-006: driver final report.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/r/plan/current-initiative" "$WORK/r/plan/current"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
RM=plan/current-initiative/initiative.md
POSRE='^(position: *)'
pos="$(sed -nE "s/${POSRE}//p" "$RM")"
if [ "$pos" = 2 ]; then
  mkdir -p plan/_archive
  mv plan/current-initiative plan/_archive/0000050-demo-initiative-2026-10-27
else
  sed -i.bak -E "s/${POSRE}.*/\\1$((pos + 1))/" "$RM" && rm -f "$RM.bak"
fi
git add -A >/dev/null 2>&1; git commit -qm "step $pos" >/dev/null 2>&1
exit 0
STUB
chmod +x "$WORK/bin/claude"

R="$WORK/r"
cat > "$R/plan/current-initiative/initiative.md" <<'EOF2'
---
title: "Initiative: demo"
status: active
---
goal: demo
branch: initiative/0000050-demo
status: active
position: 1

## Steps

| Step | Feature id | Backlog entries | Bump | Version | Status |
|------|------------|-----------------|------|---------|--------|
| 1 | 0000051-a | 0000011 | minor | | pending |
| 2 | 0000052-b | 0000012 | minor | | pending |
EOF2
: > "$R/plan/current/build-log.md"
git -C "$R" init -q -b initiative/0000050-demo
git -C "$R" config user.email t@example.com
git -C "$R" config user.name t
git -C "$R" add -A
git -C "$R" commit -qm init

OUT="$(cd "$R" && PATH="$WORK/bin:$PATH" node "$DRIVER" --root "$R" 2>&1)"
CODE=$?

echo ""
echo "=== req-006 AC-1: the final report names each step ==="
assert_equals "0" "$CODE" "driver exits 0 at delivery"
LAST="$(printf '%s\n' "$OUT" | grep -n '^I-E Delivery:' | tail -1 | cut -d: -f1)"
S1="$(printf '%s\n' "$OUT" | grep -n '^I-E Delivery: Complete: step 1 merged' | cut -d: -f1)"
S2="$(printf '%s\n' "$OUT" | grep -n '^I-E Delivery: Complete: step 2 merged' | cut -d: -f1)"
[ -n "$S1" ] && [ "$S1" -lt "$LAST" ] && r=yes || r=no
assert_equals "yes" "$r" "step 1 line comes before the last I-E Delivery: line"
[ -n "$S2" ] && [ "$S2" -lt "$LAST" ] && r=yes || r=no
assert_equals "yes" "$r" "step 2 line comes before the last I-E Delivery: line"
assert_contains "I-E Delivery: Complete: initiative 0000050-demo archived, driver done" "$(printf '%s\n' "$OUT" | tail -1)" "final line comes last"

echo ""
echo "=== req-006: all steps merged, archive not yet there ==="
P="$WORK/p"
mkdir -p "$P/plan/current-initiative" "$P/plan/current" "$WORK/bin2"
cp "$R/.git/../plan/_archive/0000050-demo-initiative-2026-10-27/initiative.md" "$P/plan/current-initiative/initiative.md"
cat > "$WORK/bin2/claude" <<'STUB'
#!/usr/bin/env bash
RM=plan/current-initiative/initiative.md
pos="$(sed -nE 's/^position: *//p' "$RM")"
sed -i.bak -E "s/^(position: *).*/\\1$((pos + 1))/" "$RM" && rm -f "$RM.bak"
git add -A >/dev/null 2>&1; git commit -qm "step $pos" >/dev/null 2>&1
exit 0
STUB
chmod +x "$WORK/bin2/claude"
sed -i.bak -E 's/^(position: *).*/\11/' "$P/plan/current-initiative/initiative.md" && rm -f "$P/plan/current-initiative/initiative.md.bak"
git -C "$P" init -q -b initiative/0000050-demo
git -C "$P" config user.email t@example.com
git -C "$P" config user.name t
git -C "$P" add -A
git -C "$P" commit -qm init
OUT="$(cd "$P" && PATH="$WORK/bin2:$PATH" node "$DRIVER" --root "$P" 2>&1)"
CODE=$?
assert_equals "0" "$CODE" "pending: driver exits 0"
assert_contains "I-E Delivery: Complete: step 2 merged" "$OUT" "pending: names step 2"
assert_equals "I-E Delivery: Pending: all 2 steps merged, initiative delivery runs from the initiative skill" "$(printf '%s\n' "$OUT" | tail -1)" "pending: last line is the Pending line"
assert_equals "no" "$([ -e "$P/plan/.initiative-runner.lock" ] && echo yes || echo no)" "pending: lock released"

print_summary
