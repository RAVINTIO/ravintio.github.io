#!/usr/bin/env bash
# Tests for feature 0000240-stream-step-session-activity, req-002, req-003 and req-005.
#
# The watcher reads the step log and prints one "I-C Run: activity:" line per stream
# event, in order, each at most 200 characters. The skill relays those lines.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WATCH="$SCRIPT_DIR/../scripts/initiative-watch.mjs"
SKILL="$SCRIPT_DIR/../skills/ravintio-initiative/SKILL.md"
STANDARDS="$SCRIPT_DIR/../standards/roadmap-standards.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

make_repo() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current" "$d/plan/.initiative-logs"
  printf 'status: active\nposition: 3\n' > "$d/plan/current-initiative/initiative.md"
  printf '### P0: Discover\n' > "$d/plan/current/build-log.md"
  : > "$d/plan/.initiative-runner.lock"
  git -C "$d" init -q
  git -C "$d" add -A
  git -C "$d" commit -q -m "first commit"
  echo "$d"
}

tool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"%s","input":%s}]}}\n' "$1" "$2"; }

watch() {
  local root="$1"; shift
  OUT="$(node "$WATCH" --root "$root" --once "$@" 2>&1)"
  CODE=$?
  ACT="$(printf '%s\n' "$OUT" | grep 'I-C Run: activity:')"
}

echo ""
echo "=== req-002: one line per event, in order ==="
R="$(make_repo a)"
L="$R/plan/.initiative-logs/step-3.log"
{
  printf '{"type":"system","subtype":"init"}\n'
  tool Bash '{"command":"run-tests.sh"}'
  tool Read '{"file_path":"/tmp/a.md"}'
  tool Grep '{"pattern":"needle"}'
  tool Task '{"subagent_type":"test-writer","description":"write REQ-002 test"}'
} > "$L"
watch "$R" --since-bytes 0
assert_exit_zero "$CODE" "req-002 AC-1: exits 0"
assert_equals "4" "$(printf '%s\n' "$ACT" | grep -c .)" "req-002 AC-1: four activity lines"
assert_contains "I-C Run: activity: tool: Bash run-tests.sh" "$(printf '%s\n' "$ACT" | sed -n 1p)" "req-002 AC-1: first line is the Bash call"
assert_contains "tool: Read /tmp/a.md" "$(printf '%s\n' "$ACT" | sed -n 2p)" "req-002 AC-1: second line is the Read call"
assert_contains "tool: Grep needle" "$(printf '%s\n' "$ACT" | sed -n 3p)" "req-002 AC-1: third line is the Grep call"
assert_contains "agent: started test-writer write REQ-002 test" "$(printf '%s\n' "$ACT" | sed -n 4p)" "req-002 AC-1: fourth line is the subagent start"

R="$(make_repo b)"
L="$R/plan/.initiative-logs/step-3.log"
{
  printf 'not json\n'
  printf '{"type":"mystery"}\n'
  printf '{"type":"assistant","message":{"content":[{"type":"text","text":"hello there\\nsecond line"}]}}\n'
  printf '{"type":"assistant","message":{"con'
} > "$L"
watch "$R" --since-bytes 0
assert_exit_zero "$CODE" "req-002 AC-2: bad input exits 0"
assert_equals "1" "$(printf '%s\n' "$ACT" | grep -c .)" "req-002 AC-2: only the text event prints"
assert_contains "I-C Run: activity: text: hello there" "$ACT" "req-002 AC-2: text prints its first line"
assert_not_contains "second line" "$OUT" "req-002 AC-2: later lines of the text stay out"

R="$(make_repo c)"
printf '%s\n' "$(tool Bash '{"command":"old"}')" > "$R/plan/.initiative-logs/step-3.log"
watch "$R"
assert_equals "0" "$(printf '%s\n' "$ACT" | grep -c .)" "req-002: a fresh watcher starts at the end of the log"
assert_contains "POLL_MS = 10000" "$(grep 'POLL_MS' "$WATCH")" "req-002 AC-3: poll constant is 10000"

echo ""
echo "=== req-003: lines stay within 200 characters ==="
R="$(make_repo d)"
LONG="$(printf 'a%.0s' $(seq 1 1000))"
{
  tool Bash "{\"command\":\"$LONG\"}"
  tool Bash '{"command":"first\nsecond"}'
} > "$R/plan/.initiative-logs/step-3.log"
watch "$R" --since-bytes 0
LONGEST="$(printf '%s\n' "$ACT" | awk '{ if (length($0) > m) m = length($0) } END { print m }')"
assert_equals "yes" "$([ "$LONGEST" -le 200 ] && echo yes || echo no)" "req-003 AC-1: every activity line is 200 characters or fewer"
assert_contains "I-C Run: activity: tool: Bash aaa" "$(printf '%s\n' "$ACT" | sed -n 1p)" "req-003 AC-1: the cut line keeps its prefix"
assert_equals "2" "$(printf '%s\n' "$ACT" | grep -c .)" "req-003 AC-2: a multi-line command stays on one line"

echo ""
echo "=== req-005: skill and standards ==="
assert_contains "I-C Run: activity:" "$(cat "$SKILL")" "req-005 AC-1: the skill names the activity line"
assert_contains "Relay each one" "$(grep "activity" "$SKILL")" "req-005 AC-1: the skill tells the session to relay it"
assert_contains "stream-json" "$(cat "$STANDARDS")" "req-005 AC-2: the standards name stream-json"
assert_contains "I-C Run: activity:" "$(cat "$STANDARDS")" "req-005 AC-2: the standards name the activity line"

print_summary
