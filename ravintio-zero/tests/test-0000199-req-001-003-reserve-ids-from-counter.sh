#!/usr/bin/env bash
# 0000199 req-001 to req-003: reserve-ids-from-counter
# reserve-id.mjs reserves ids from plan/backlog/.next-id under a lock, and the docs call it.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

RESERVE="$ZERO_DIR/scripts/reserve-id.mjs"
TMP="$(mktemp -d -t ravintio_0000199_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "=== req-001: reserve a block ==="
mkdir -p "$TMP/a"
printf '0000188\n' > "$TMP/a/.next-id"
OUT=$(node "$RESERVE" 4 --file "$TMP/a/.next-id" 2>&1); RC=$?
assert_equals "0" "$RC" "AC-1: exit 0"
assert_equals "0000188 0000189 0000190 0000191" "$(printf '%s' "$OUT" | tr '\n' ' ' | sed 's/ $//')" "AC-1: prints 0000188 to 0000191"
assert_equals "0000192" "$(tr -d '\n' < "$TMP/a/.next-id")" "AC-1: the file holds 0000192"
OUT=$(node "$RESERVE" --file "$TMP/a/.next-id" 2>&1)
assert_equals "0000192" "$OUT" "AC-1: the default quantity is 1"
assert_equals "no" "$([ -e "$TMP/a/.next-id.lock" ] && echo yes || echo no)" "AC-1: the lock is released"

echo "=== req-001: concurrent reservations ==="
mkdir -p "$TMP/b"
printf '0000100\n' > "$TMP/b/.next-id"
for i in 1 2 3 4 5 6 7 8; do
  node "$RESERVE" 3 --file "$TMP/b/.next-id" > "$TMP/b/out-$i" 2>&1 &
done
wait
ALL=$(cat "$TMP"/b/out-* | sort)
assert_equals "24" "$(printf '%s\n' "$ALL" | wc -l | tr -d ' ')" "AC-2: 24 ids printed"
assert_equals "24" "$(printf '%s\n' "$ALL" | sort -u | wc -l | tr -d ' ')" "AC-2: the 24 ids are all different"
assert_equals "0000124" "$(tr -d '\n' < "$TMP/b/.next-id")" "AC-2: the file holds 0000124"

echo "=== req-001: a failed reservation changes nothing ==="
fail_case() {
  local name="$1" setup="$2" qty="$3"
  local d="$TMP/f-$name"
  mkdir -p "$d"
  eval "$setup"
  local before after rc
  before=$(cat "$d/.next-id" 2>/dev/null; ls -A "$d" | sort)
  node "$RESERVE" $qty --file "$d/.next-id" >/dev/null 2>&1; rc=$?
  after=$(cat "$d/.next-id" 2>/dev/null; ls -A "$d" | sort)
  assert_equals "1" "$rc" "AC-3 ($name): exit 1"
  assert_equals "$before" "$after" "AC-3 ($name): the folder is unchanged"
}
fail_case held-lock 'printf "0000005\n" > "$d/.next-id"; : > "$d/.next-id.lock"' 1
fail_case letters 'printf "00x0005\n" > "$d/.next-id"' 1
fail_case symlink 'printf "0000005\n" > "$d/real"; ln -s real "$d/.next-id"' 1
fail_case zero-qty 'printf "0000005\n" > "$d/.next-id"' 0
fail_case big-qty 'printf "0000005\n" > "$d/.next-id"' 1001
fail_case word-qty 'printf "0000005\n" > "$d/.next-id"' abc
fail_case overflow 'printf "9999999\n" > "$d/.next-id"' 2

echo "=== req-002: bootstrap and seed ==="
mkdir -p "$TMP/c/plan/_archive/0000041-demo-2026-01-01" "$TMP/c/plan/backlog/0000007-x" "$TMP/c/plan/changelog" "$TMP/c/plan/roadmap/0000030-y"
: > "$TMP/c/plan/changelog/0000039-demo-2026-01-01.md"
OUT=$(node "$RESERVE" --init --file "$TMP/c/plan/backlog/.next-id" 2>&1); RC=$?
assert_equals "0" "$RC" "AC-1: init exits 0"
assert_equals "0000042" "$OUT" "AC-1: init prints 0000042"
assert_equals "0000043" "$(tr -d '\n' < "$TMP/c/plan/backlog/.next-id")" "AC-1: init leaves 0000043"
mkdir -p "$TMP/d/plan/backlog"
node "$RESERVE" --file "$TMP/d/plan/backlog/.next-id" >/dev/null 2>&1; RC=$?
assert_equals "1" "$RC" "AC-2: a missing counter exits 1"
assert_equals "no" "$([ -e "$TMP/d/plan/backlog/.next-id" ] && echo yes || echo no)" "AC-2: no counter file is created"
mkdir -p "$TMP/e/plan/backlog"
OUT=$(node "$RESERVE" --init --file "$TMP/e/plan/backlog/.next-id" 2>&1)
assert_equals "0000001" "$OUT" "AC-1: init in an empty repo starts at 0000001"
SEED=$(tr -d '\n' < "$ROOT_DIR/plan/backlog/.next-id" 2>/dev/null)
assert_equals "yes" "$(printf '%s' "$SEED" | grep -qE '^[0-9]{7}$' && [ "$((10#$SEED))" -ge 210 ] && echo yes || echo no)" "AC-3: the shipped seed is seven digits and at least 0000210"

echo "=== req-003: docs call the counter ==="
SKILL="$ZERO_DIR/skills/ravintio-file-backlog/SKILL.md"
TEMPLATE="$ZERO_DIR/templates/backlog-entry.template.md"
ITEMPLATE="$ZERO_DIR/templates/initiative.template.md"
ROADMAP="$ZERO_DIR/standards/roadmap-standards.md"
DISPATCH="$ZERO_DIR/standards/agent-dispatch-standards.md"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
assert_contains "reserve-id.mjs" "$(cat "$SKILL")" "AC-1: the skill names the script"
assert_contains ".next-id" "$(cat "$SKILL")" "AC-1: the skill names the counter"
assert_equals "no" "$(grep -q 'plan/_archive/' "$SKILL" && echo yes || echo no)" "AC-1: the skill no longer scans plan/_archive/"
assert_contains "source id" "$(cat "$SKILL")" "AC-2: the skill names the source id rule"
assert_contains "source id" "$(cat "$TEMPLATE")" "AC-2: the template names the source id rule"
for f in "$SKILL" "$TEMPLATE" "$ITEMPLATE" "$ROADMAP" "$DISPATCH" "$ORCH"; do
  assert_equals "no" "$(grep -qi 'highest ever allocated\|highest id ever' "$f" && echo yes || echo no)" "AC-3: no scan rule in $(basename "$f")"
done
for f in "$TEMPLATE" "$ITEMPLATE" "$ROADMAP" "$DISPATCH" "$ORCH"; do
  assert_contains ".next-id" "$(cat "$f")" "AC-3: $(basename "$f") names the counter"
done
assert_contains "Keep the higher value" "$(cat "$ROADMAP")" "AC-3: roadmap-standards states the conflict answer"
assert_contains "renumber" "$(cat "$ROADMAP")" "AC-3: roadmap-standards says to renumber the later branch"

print_summary
