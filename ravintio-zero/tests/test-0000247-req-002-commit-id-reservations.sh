#!/usr/bin/env bash
# Tests for feature 0000247-git-state-hygiene, req-002: reserve-id.mjs --commit
# commits the counter file alone, and three skills tell the agent to use it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
RESERVE="$ZERO_DIR/scripts/reserve-id.mjs"
TMP="$(mktemp -d -t ravintio_0000247_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "=== req-002 AC-1: the counter change sits in its own commit ==="
R="$TMP/repo"
mkdir -p "$R/plan/backlog"
git -C "$R" init -q
git -C "$R" config user.email t@example.com
git -C "$R" config user.name Tester
printf '0000300\n' > "$R/plan/backlog/.next-id"
printf 'seed\n' > "$R/other.txt"
git -C "$R" add -A
git -C "$R" commit -q -m "chore(seed): seed"
printf 'staged\n' >> "$R/other.txt"
git -C "$R" add other.txt
BEFORE=$(git -C "$R" rev-list --count HEAD)
OUT=$(cd "$R" && node "$RESERVE" 2 --commit 2>&1); RC=$?
assert_equals "0" "$RC" "req-002 AC-1: exit 0"
assert_equals "0000300 0000301" "$(printf '%s' "$OUT" | tr '\n' ' ' | sed 's/ $//')" "req-002 AC-1: prints the two ids"
assert_equals "$((BEFORE + 1))" "$(git -C "$R" rev-list --count HEAD)" "req-002 AC-1: one new commit"
assert_equals "plan/backlog/.next-id" "$(git -C "$R" show --name-only --format= HEAD)" "req-002 AC-1: the commit holds the counter alone"
assert_equals "chore(ids): reserve ids 0000300 to 0000301" "$(git -C "$R" log -1 --format=%s)" "req-002 AC-1: the subject names the ids"
assert_equals "M  other.txt" "$(git -C "$R" status --porcelain)" "req-002 AC-1: the other staged file stays staged"
OUT=$(cd "$R" && node "$RESERVE" --commit 2>&1)
assert_equals "chore(ids): reserve id 0000302" "$(git -C "$R" log -1 --format=%s)" "req-002 AC-1: a single id reads reserve id"

echo ""
echo "=== req-002 AC-1: a new untracked counter is committed ==="
N="$TMP/new"
mkdir -p "$N"
git -C "$N" init -q
git -C "$N" config user.email t@example.com
git -C "$N" config user.name Tester
OUT=$(cd "$N" && node "$RESERVE" --init --commit 2>&1); RC=$?
assert_equals "0" "$RC" "req-002 AC-1: exit 0 for a new counter"
assert_equals "plan/backlog/.next-id" "$(git -C "$N" show --name-only --format= HEAD)" "req-002 AC-1: the commit adds the counter"

echo ""
echo "=== req-002 AC-2: a failed commit keeps the counter and exits 1 ==="
F="$TMP/nogit"
mkdir -p "$F/plan/backlog"
printf '0000400\n' > "$F/plan/backlog/.next-id"
ERR=$(cd "$F" && GIT_CEILING_DIRECTORIES="$TMP" node "$RESERVE" --commit 2>&1 >/dev/null); RC=$?
assert_equals "1" "$RC" "req-002 AC-2: exit 1"
assert_equals "1" "$(printf '%s\n' "$ERR" | grep -c .)" "req-002 AC-2: one stderr line"
assert_equals "0000401" "$(tr -d '\n' < "$F/plan/backlog/.next-id")" "req-002 AC-2: the counter holds the new value"

echo ""
echo "=== req-002 AC-3: three skills carry the rule ==="
for s in initiative retrospective postmortem; do
  assert_contains "reserve-id.mjs --commit" "$(cat "$ZERO_DIR/skills/ravintio-$s/SKILL.md")" "req-002 AC-3: the $s skill names reserve-id.mjs --commit"
done

print_summary
