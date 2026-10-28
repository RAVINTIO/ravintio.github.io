#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-001: driver fixes.
#
# AC-1: an archived Blocked: line stops the driver.
# AC-2: position moves only after the merge, read from the initiative branch ref.
# AC-3: the child env keeps subagents running and marks a step session.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub claude. STUB_MODE: archive-block, unmerged, merge (default).
RM=plan/current-initiative/initiative.md
POSRE='^(position: *)'
pos="$(sed -nE "s/${POSRE}//p" "$RM")"
printf '%s|%s\n' "${CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS-unset}" "${RAVINTIO_INITIATIVE_STEP-unset}" >> "$STUB_ENV"
advance() { sed -i.bak -E "s/${POSRE}.*/\\1$((pos + 1))/" "$RM" && rm -f "$RM.bak"; }
case "${STUB_MODE:-merge}" in
  archive-block)
    mkdir -p plan/_archive/0000051-a-2026-10-27
    printf 'Blocked: CI failed after the archive\n' > plan/_archive/0000051-a-2026-10-27/build-log.md
    advance
    git add -A >/dev/null 2>&1; git commit -qm "step $pos" >/dev/null 2>&1
    exit 0 ;;
  unmerged)
    advance
    exit 0 ;;
esac
# merge: advance and commit on the initiative branch.
if [ "$pos" = 2 ]; then
  mkdir -p plan/_archive
  mv plan/current-initiative plan/_archive/0000050-demo-initiative-2026-10-27
else
  advance
fi
git add -A >/dev/null 2>&1; git commit -qm "step $pos" >/dev/null 2>&1
exit 0
STUB
chmod +x "$WORK/bin/claude"

# make_fixture <name>: a git work tree on branch initiative/0000050-demo. Prints the root.
make_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  cat > "$d/plan/current-initiative/initiative.md" <<EOF2
---
title: "Initiative: demo"
summary: "Two steps."
status: active
---
# Initiative: demo

goal: demo
branch: initiative/0000050-demo
status: active
position: 1

| Step | Feature id | Backlog entries | Bump | Version | Status |
|------|------------|-----------------|------|---------|--------|
| 1 | 0000051-a | 0000011 | minor | | pending |
| 2 | 0000052-b | 0000012 | minor | | pending |
EOF2
  : > "$d/plan/current/build-log.md"
  git -C "$d" init -q -b initiative/0000050-demo
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name t
  printf 'stub.log\nenv.log\n' > "$d/.gitignore"
  git -C "$d" add -A
  git -C "$d" commit -qm init
  printf '%s' "$d"
}

# run_driver <root> <mode>: sets OUT and CODE. Unsets the ceiling variable unless CEIL is set.
run_driver() {
  OUT="$(cd "$1" && env -u CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS ${CEIL:+CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=$CEIL} \
    PATH="$WORK/bin:$PATH" STUB_ENV="$1/env.log" STUB_MODE="$2" \
    node "$DRIVER" --root "$1" 2>&1)"
  CODE=$?
}

echo ""
echo "=== req-001 AC-1: an archived block stops the driver ==="
R="$(make_fixture ac1)"
run_driver "$R" archive-block
assert_equals "1" "$CODE" "AC-1: driver exits 1"
assert_contains "I-C Run: Blocked: step 1 stopped. Blocked: CI failed after the archive" "$OUT" "AC-1: stop line repeats the archived message"
assert_equals "1" "$(wc -l < "$R/env.log" | tr -d ' ')" "AC-1: step 2 did not start"

echo ""
echo "=== req-001 AC-2: position moves only after the merge ==="
R="$(make_fixture ac2)"
run_driver "$R" unmerged
assert_equals "1" "$CODE" "AC-2: driver exits 1"
assert_contains "I-C Run: Blocked: step 1 is not merged into the initiative branch, position stayed at 1" "$OUT" "AC-2: stop line says not merged"
assert_equals "1" "$(wc -l < "$R/env.log" | tr -d ' ')" "AC-2: step 2 did not start"

R="$(make_fixture ac2-merged)"
run_driver "$R" merge
assert_equals "0" "$CODE" "AC-2: a merged step run advances to delivery"
assert_equals "2" "$(wc -l < "$R/env.log" | tr -d ' ')" "AC-2: both steps ran"

echo ""
echo "=== req-001 AC-3: the child environment ==="
R="$(make_fixture ac3-unset)"
run_driver "$R" merge
assert_equals "0|1" "$(sed -n 1p "$R/env.log")" "AC-3: ceiling is 0 and step marker is 1 when unset"
R="$(make_fixture ac3-set)"
CEIL=5 run_driver "$R" merge
assert_equals "5|1" "$(sed -n 1p "$R/env.log")" "AC-3: a parent value of 5 is kept"

echo ""
echo "=== req-001: queue folder is excluded from git ==="
R="$(make_fixture excl)"
run_driver "$R" merge
assert_equals "1" "$(grep -cxF 'plan/.initiative-queue/' "$R/.git/info/exclude")" "queue folder added to info/exclude"

print_summary
