#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-004:
# setup.sh deletes installed hooks named on the retired list, keeps every
# other hook, and leaves no settings.json entry that names a pruned file.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000151_req004_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude/hooks/enforcement"
  printf '%s\n' "$ws"
}

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

RETIRED="phase-enum check-telemetry-failures check-telemetry-receipts"

echo ""
echo "=== req-004 (a): setup prunes the retired hooks ==="

WS="$(new_workspace)"
H="$WS/.claude/hooks/enforcement"
for n in $RETIRED; do echo "// stale" >"$H/$n.mjs"; done
echo "// mine" >"$H/custom-local-hook.mjs"
# A stale wiring entry for phase-enum.
cat >"$WS/.claude/settings.json" <<'JSON'
{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"node \".claude/hooks/enforcement/phase-enum.mjs\""}]}]}}
JSON
run_setup "$WS"
assert_exit_zero "$?" "first run exits 0"
OUT="$(cat "$WS/setup.out")"
for n in $RETIRED; do
  [ -e "$H/$n.mjs" ] && ex=present || ex=absent
  assert_equals absent "$ex" "$n.mjs is deleted"
  assert_contains "  - removed .claude/hooks/enforcement/$n.mjs" "$OUT" "removal line for $n.mjs"
done
count="$(grep -c -- '- removed .claude/hooks/' "$WS/setup.out" || true)"
assert_equals 3 "$count" "exactly three removal lines"

count="$(grep -c -- '- removed retired hook entry phase-enum from .claude/settings.json' "$WS/setup.out" || true)"
assert_equals 1 "$count" "S-005: one settings.json removal line for phase-enum"
count="$(grep -c -- '- removed retired hook entry' "$WS/setup.out" || true)"
assert_equals 1 "$count" "S-005: only the entry that existed is named"

echo ""
echo "=== req-004 (b): other hooks and settings entries ==="
[ -e "$H/custom-local-hook.mjs" ] && ex=present || ex=absent
assert_equals present "$ex" "custom-local-hook.mjs survives"
for f in "$ZERO_DIR"/hooks/enforcement/*.mjs; do
  b="$(basename "$f")"
  [ -e "$H/$b" ] && ex=present || ex=absent
  assert_equals present "$ex" "shipped hook $b is present"
  case "$OUT" in *"- removed .claude/hooks/enforcement/$b"*) r=named ;; *) r=unnamed ;; esac
  assert_equals unnamed "$r" "shipped hook $b is not in a removal line"
done
SETTINGS="$(cat "$WS/.claude/settings.json")"
for n in $RETIRED; do
  case "$SETTINGS" in *"$n"*) r=found ;; *) r=none ;; esac
  assert_equals none "$r" "settings.json holds no $n entry"
done

echo ""
echo "=== req-004 (a): a second run prints no removal line ==="
run_setup "$WS"
assert_exit_zero "$?" "second run exits 0"
count="$(grep -c -- '- removed .claude/hooks/' "$WS/setup.out" || true)"
assert_equals 0 "$count" "second run prints no removal line"
count="$(grep -c -- '- removed retired hook entry' "$WS/setup.out" || true)"
assert_equals 0 "$count" "S-005: second run prints no settings.json removal line"

echo ""
echo "=== req-004: the retired list holds phase-enum ==="
assert_contains "phase-enum" "$(grep '^RETIRED_HOOK_NAMES=' "$ZERO_DIR/setup.sh")" "setup.sh list has phase-enum"
assert_contains "'phase-enum'" "$(cat "$ZERO_DIR/setup.ps1")" "setup.ps1 list has phase-enum"

rm -rf "$WS"
print_summary
