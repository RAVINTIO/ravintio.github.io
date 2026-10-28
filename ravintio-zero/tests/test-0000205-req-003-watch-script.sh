#!/usr/bin/env bash
# Tests for feature 0000205-initiative-skill, req-003: watch script.
#
# scripts/initiative-watch.mjs reads the build log and git log and prints event lines,
# a stale-log line, and a heartbeat. It never writes. Tests run it with --once against
# temporary git repos and simulate an earlier pass with --since-lines and --since-commit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WATCH="$SCRIPT_DIR/../scripts/initiative-watch.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# make_repo <name>: prints a git repo with an initiative, a build log, and one commit.
make_repo() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  printf 'status: active\nposition: 3\n' > "$d/plan/current-initiative/initiative.md"
  printf '### P0: Discover\nP0 Discover: Complete: brief written\n' > "$d/plan/current/build-log.md"
  : > "$d/plan/.initiative-runner.lock"
  git -C "$d" init -q
  git -C "$d" add -A
  GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" git -C "$d" commit -q -m "first commit" --date "2026-01-01T00:00:00Z"
  echo "$d"
}

# watch <root> [args...]: runs the script once and captures output and exit code.
watch() {
  local root="$1"; shift
  OUT="$(node "$WATCH" --root "$root" --once "$@" 2>&1)"
  CODE=$?
}

# --- AC-1: event lines -------------------------------------------------
R="$(make_repo ac1)"
LOG="$R/plan/current/build-log.md"
NOW="2026-01-01T00:02:00Z"

watch "$R" --since-lines 2 --since-commit "$(git -C "$R" rev-parse HEAD)" --now "$NOW"
assert_exit_zero "$CODE" "req-003 AC-1: unchanged log exits 0"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: event:')" "req-003 AC-1: unchanged log prints no event line"

printf '### P1: Plan\nP1 Plan: Complete: requirements written\n' >> "$LOG"
watch "$R" --since-lines 2 --since-commit "$(git -C "$R" rev-parse HEAD)" --now "$NOW"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: event:')" "req-003 AC-1: Complete line prints one event"
assert_contains "I-C Run: event: P1 Plan: Complete: requirements written" "$OUT" "req-003 AC-1: Complete event text"

printf 'Blocked: needs a decision\n' >> "$LOG"
watch "$R" --since-lines 4 --since-commit "$(git -C "$R" rev-parse HEAD)" --now "$NOW"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: event:')" "req-003 AC-1: Blocked line prints one event"
assert_contains "I-C Run: event: Blocked: needs a decision" "$OUT" "req-003 AC-1: Blocked event text"

printf 'Resolved: use option A\n' >> "$LOG"
watch "$R" --since-lines 5 --since-commit "$(git -C "$R" rev-parse HEAD)" --now "$NOW"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: event:')" "req-003 AC-1: Resolved line prints one event"
assert_contains "I-C Run: event: Resolved: use option A" "$OUT" "req-003 AC-1: Resolved event text"

FIRST="$(git -C "$R" rev-parse HEAD)"
echo x > "$R/x.txt"; git -C "$R" add x.txt
git -C "$R" commit -q -m "add the x file"
watch "$R" --since-lines 6 --since-commit "$FIRST" --now "$NOW"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: event:')" "req-003 AC-1: new commit prints one event"
assert_contains "add the x file" "$OUT" "req-003 AC-1: commit event carries the subject"

# --- AC-2: stale log and heartbeat -------------------------------------
R="$(make_repo ac2)"
node -e "const t=new Date('2026-01-01T00:00:00Z');require('fs').utimesSync(process.argv[1],t,t)" "$R/plan/current/build-log.md"
echo y > "$R/y.txt"; git -C "$R" add y.txt
GIT_COMMITTER_DATE="2026-01-01T00:16:00Z" git -C "$R" commit -q -m "newer commit"
watch "$R" --now "2026-01-01T00:16:30Z"
assert_contains "I-C Run: stale:" "$OUT" "req-003 AC-2: stale line printed"
assert_contains "I-C Run: heartbeat:" "$OUT" "req-003 AC-2: heartbeat printed"
assert_contains "step 3" "$OUT" "req-003 AC-2: heartbeat names the step"
assert_contains "lock held" "$OUT" "req-003 AC-2: heartbeat names the lock state"
assert_contains "P0" "$OUT" "req-003 AC-2: heartbeat names the phase"

watch "$R" --now "2026-01-01T00:12:00Z"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: stale:')" "req-003 AC-2: no stale line before 15 minutes"

rm "$R/plan/.initiative-runner.lock"
watch "$R" --now "2026-01-01T00:12:00Z"
assert_contains "lock free" "$OUT" "req-003 AC-2: heartbeat reports a free lock"

# Delivery: lock and initiative both gone.
rm "$R/plan/current-initiative/initiative.md"
watch "$R" --now "2026-01-01T00:12:00Z"
assert_exit_zero "$CODE" "req-003: delivery exits 0"
assert_contains "I-E Delivery:" "$OUT" "req-003: delivery prints the last line"

# --- AC-3: read-only ---------------------------------------------------
R="$(make_repo ac3)"
echo z > "$R/untracked.txt"
hash_tree() { (cd "$R" && find . -path ./.git -prune -o -type f -print | sort | xargs shasum | shasum); }
BEFORE_STATUS="$(git -C "$R" status --porcelain)"
BEFORE_HASH="$(hash_tree)"
watch "$R" --since-lines 0 --now "2026-01-01T00:30:00Z"
assert_equals "$BEFORE_STATUS" "$(git -C "$R" status --porcelain)" "req-003 AC-3: git status unchanged"
assert_equals "$BEFORE_HASH" "$(hash_tree)" "req-003 AC-3: file hashes unchanged"

# --- Constants, flags, refusals ----------------------------------------
assert_contains "HEARTBEAT_MS = 300000" "$(grep 'HEARTBEAT_MS' "$WATCH")" "req-003: heartbeat constant is 300000"
assert_contains "POLL_MS = 10000" "$(grep 'POLL_MS' "$WATCH")" "req-003: poll constant is 10000"
assert_contains "STALE_MS = 900000" "$(grep 'STALE_MS' "$WATCH")" "req-003: stale constant is 900000"

watch "$R" --state "$WORK/state.json"
assert_equals "1" "$CODE" "req-003: --state is refused"
assert_equals "no" "$([ -e "$WORK/state.json" ] && echo yes || echo no)" "req-003: --state writes nothing"

R="$(make_repo link)"
mkdir "$WORK/elsewhere"; printf '### P0: x\n' > "$WORK/elsewhere/build-log.md"
rm -rf "$R/plan/current"; ln -s "$WORK/elsewhere" "$R/plan/current"
watch "$R"
assert_equals "1" "$CODE" "req-003: symlinked plan path exits 1"
assert_contains "refused a symlinked plan path" "$OUT" "req-003: symlink refusal message"

R="$(make_repo cap)"
printf 'Blocked: %s\n' "$(printf 'a%.0s' $(seq 1 700))" >> "$R/plan/current/build-log.md"
watch "$R" --since-lines 2 --now "2026-01-01T00:02:00Z"
LONGEST="$(printf '%s\n' "$OUT" | awk '{ if (length($0) > m) m = length($0) } END { print m }')"
assert_equals "yes" "$([ "$LONGEST" -le 500 ] && echo yes || echo no)" "req-003: every line is at most 500 characters"

print_summary
