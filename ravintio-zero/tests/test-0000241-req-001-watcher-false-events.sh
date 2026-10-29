#!/usr/bin/env bash
# Tests for feature 0000241-watcher-false-events, req-001 to req-004.
#
# The watcher reports a stale log only when a commit is 15 minutes newer than the log,
# prints each stale state once, prints one line for a branch switch, and reads the lock
# state on each pass.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WATCH="$SCRIPT_DIR/../scripts/initiative-watch.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# make_repo <name>: a repo with an initiative, a build log dated 00:00, and one commit at 00:00.
make_repo() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  printf 'status: active\nposition: 3\n' > "$d/plan/current-initiative/initiative.md"
  printf '### P0: Discover\n' > "$d/plan/current/build-log.md"
  : > "$d/plan/.initiative-runner.lock"
  git -C "$d" init -q
  git -C "$d" add -A
  GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" git -C "$d" commit -q -m "first commit" --date "2026-01-01T00:00:00Z"
  node -e "const t=new Date('2026-01-01T00:00:00Z');require('fs').utimesSync(process.argv[1],t,t)" "$d/plan/current/build-log.md"
  echo "$d"
}

# commit_at <repo> <iso time> <subject>
commit_at() {
  echo "$3" >> "$1/f.txt"
  git -C "$1" add f.txt
  GIT_COMMITTER_DATE="$2" git -C "$1" commit -q -m "$3" --date "$2"
}

watch() {
  local root="$1"; shift
  OUT="$(node "$WATCH" --root "$root" --once "$@" 2>&1)"
  CODE=$?
}

count() { printf '%s\n' "$OUT" | grep -c "$1"; }

echo ""
echo "=== req-001: stale needs a commit 15 minutes newer than the log ==="
R="$(make_repo r1a)"
FIRST="$(git -C "$R" rev-parse HEAD)"
commit_at "$R" "2026-01-01T00:00:05Z" "five seconds later"
watch "$R" --since-commit "$FIRST" --now "2026-01-01T00:20:00Z"
assert_exit_zero "$CODE" "req-001 AC-1: exits 0"
assert_equals "0" "$(count 'I-C Run: stale:')" "req-001 AC-1: a commit 5 seconds newer gives no stale line"

R="$(make_repo r1b)"
FIRST="$(git -C "$R" rev-parse HEAD)"
commit_at "$R" "2026-01-01T00:20:00Z" "twenty minutes later"
watch "$R" --since-commit "$FIRST" --now "2026-01-01T00:21:00Z"
assert_equals "1" "$(count 'I-C Run: stale:')" "req-001 AC-2: a commit 20 minutes newer gives one stale line"

echo ""
echo "=== req-002: each stale state prints once ==="
R="$(make_repo r2)"
FIRST="$(git -C "$R" rev-parse HEAD)"
commit_at "$R" "2026-01-01T00:20:00Z" "twenty minutes later"
watch "$R" --since-commit "$FIRST" --passes 3 --now "2026-01-01T00:21:00Z"
assert_exit_zero "$CODE" "req-002 AC-1: three passes exit 0"
assert_equals "1" "$(count 'I-C Run: stale:')" "req-002 AC-1: three passes give one stale line"

# State stays in memory, so a new process prints the stale state again.
watch "$R" --since-commit "$FIRST" --now "2026-01-01T00:21:00Z"
assert_equals "1" "$(count 'I-C Run: stale:')" "req-002 AC-2: a restarted watcher prints the stale state again"

echo ""
echo "=== req-003: a branch switch prints one line ==="
R="$(make_repo r3)"
git -C "$R" checkout -q -b old
commit_at "$R" "2026-01-01T00:01:00Z" "old tip"
OLD="$(git -C "$R" rev-parse HEAD)"
git -C "$R" checkout -q -
git -C "$R" checkout -q -b newer
for i in $(seq 1 100); do
  GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" git -C "$R" commit -q --allow-empty -m "older $i" --date "2026-01-01T00:00:00Z"
done
watch "$R" --since-commit "$OLD" --now "2026-01-01T00:02:00Z"
assert_exit_zero "$CODE" "req-003 AC-1: exits 0"
assert_equals "1" "$(count 'I-C Run: event: branch changed to newer')" "req-003 AC-1: one branch-change line"
assert_equals "0" "$(count 'I-C Run: event: commit')" "req-003 AC-1: no commit lines"

R="$(make_repo r3b)"
FIRST="$(git -C "$R" rev-parse HEAD)"
commit_at "$R" "2026-01-01T00:01:00Z" "second"
commit_at "$R" "2026-01-01T00:02:00Z" "third"
watch "$R" --since-commit "$FIRST" --now "2026-01-01T00:03:00Z"
assert_equals "2" "$(count 'I-C Run: event: commit')" "req-003 AC-2: two newer commits give two commit lines"
assert_equals "0" "$(count 'branch changed')" "req-003 AC-2: no branch-change line"

echo ""
echo "=== req-004: the heartbeat reports the real lock state ==="
R="$(make_repo r4)"
watch "$R" --passes 2 --now "2026-01-01T00:02:00Z"
assert_contains "lock held" "$OUT" "req-004 AC-2: lock present reads as held"
rm "$R/plan/.initiative-runner.lock"
watch "$R" --now "2026-01-01T00:02:00Z"
assert_contains "lock free" "$OUT" "req-004 AC-1: lock removed reads as free"
assert_not_contains "lock held" "$OUT" "req-004 AC-1: no held text after removal"

print_summary
