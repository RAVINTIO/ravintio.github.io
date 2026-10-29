#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh leaks invalid settings.json content or keeps a single-object RAVINTIO hook.
# Tests for feature 0000039-setup-hardening-release-sizing, req-001 and req-002:
# the setup.sh hook install step on an invalid settings.json, and on hook
# entries whose hooks value is one object, not an array.
#
# The planted files come from the shared fixtures in
# fixtures/0000039-setup-hardening/, which the setup.ps1 suite also reads.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
FIXTURES="$SCRIPT_DIR/fixtures/0000039-setup-hardening"
PLANTED="PLANTED-0000039-secret-value"
ERROR_LINE="! Error: .claude/settings.json is not valid JSON. Fix it and rerun setup."

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000039_req001_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  printf '%s\n' "$ws"
}

# Runs setup and writes stdout and stderr to files in the workspace root.
run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

# Prints every hook command as event|matcher|command. A hooks value that is
# one object prints as one command.
render_hooks() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const hooks = s.hooks || {};
    for (const ev of ["PreToolUse", "UserPromptSubmit"]) {
      for (const e of hooks[ev] || []) {
        const v = e.hooks;
        const cmds = Array.isArray(v) ? v : (v && typeof v === "object" ? [v] : []);
        for (const h of cmds) console.log(ev + "|" + (e.matcher || "") + "|" + h.command);
      }
    }
  ' "$1"
}

count_lines() {
  printf '%s\n' "$1" | grep -c -F -x -- "$2" || true
}

echo ""
echo "=== req-001 (a): invalid settings.json stops setup with one fixed line ==="

WS="$(new_workspace)"
cp "$FIXTURES/invalid-settings.json" "$WS/.claude/settings.json"
run_setup "$WS"
SETUP_EXIT=$?
COMBINED="$(cat "$WS/setup.out" "$WS/setup.err")"

assert_equals "1" "$SETUP_EXIT" "req-001 (a): setup.sh exits 1 on invalid JSON"
assert_equals "1" "$(grep -c -F -x -- "$ERROR_LINE" "$WS/setup.err" || true)" \
  "req-001 (a): stderr holds the fixed error line exactly once"
assert_equals "1" "$(grep -c -F -- "not valid JSON" "$WS/setup.err" || true)" \
  "req-001 (a): the hook install step prints no other parse error line"
assert_equals "0" "$(printf '%s\n' "$COMBINED" | grep -c -E '^\s+at |SyntaxError' || true)" \
  "req-001 (a): no stack trace or parser message reaches the output"
if cmp -s "$FIXTURES/invalid-settings.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
assert_equals "yes" "$SAME" "req-001 (a): settings.json is byte-identical"
assert_equals "0" "$(find "$WS/.claude" -maxdepth 1 -name '*.ravintio-tmp' | wc -l | tr -d ' ')" \
  "req-001 (a): no temporary file is left in .claude/"

echo ""
echo "=== req-001 (b): the planted value never reaches the output ==="

assert_equals "0" "$(printf '%s\n' "$COMBINED" | grep -c -F -- "$PLANTED" || true)" \
  "req-001 (b): the planted value is absent from stdout and stderr"
assert_equals "0" "$(printf '%s\n' "$COMBINED" | grep -c -F -- "API_TOKEN" || true)" \
  "req-001 (b): no planted key reaches stdout or stderr"
rm -rf "$WS"

echo ""
echo "=== req-002 (a): single-object RAVINTIO hooks go, fresh entries appear once ==="

WS="$(new_workspace)"
cp "$FIXTURES/single-object-hooks.json" "$WS/.claude/settings.json"
run_setup "$WS"
SETUP_EXIT=$?
RENDER="$(render_hooks "$WS/.claude/settings.json")"

assert_exit_zero "$SETUP_EXIT" "req-002 (a): setup.sh exits 0 with single-object hooks values"
assert_equals "0" "$(count_lines "$RENDER" 'PreToolUse|Write|Edit|node ".claude/hooks/enforcement/gate-write.mjs"')" \
  "req-002 (a): the single-object PreToolUse RAVINTIO entry is gone"
assert_equals "0" "$(count_lines "$RENDER" 'UserPromptSubmit|.*|node .claude/hooks/enforcement/check-design.mjs')" \
  "req-002 (a): the single-object UserPromptSubmit RAVINTIO entry is gone"
for line in \
  'PreToolUse|Write|node ".claude/hooks/enforcement/gate-write.mjs"' \
  'PreToolUse|Edit|node ".claude/hooks/enforcement/gate-write.mjs"' \
  'PreToolUse|Write|node ".claude/hooks/enforcement/ratchet-check.mjs"' \
  'PreToolUse|Edit|node ".claude/hooks/enforcement/ratchet-check.mjs"' \
  'PreToolUse|Write|node ".claude/hooks/enforcement/em-dash-guard.mjs"' \
  'PreToolUse|Edit|node ".claude/hooks/enforcement/em-dash-guard.mjs"' \
  'PreToolUse|Bash|node ".claude/hooks/enforcement/merge-guard.mjs"' \
  'UserPromptSubmit|.*|node ".claude/hooks/enforcement/auto-trigger-orchestrator.mjs"' \
  'UserPromptSubmit|.*|node ".claude/hooks/enforcement/check-orchestrator-presence.mjs"' \
  'UserPromptSubmit|.*|node ".claude/hooks/enforcement/check-design.mjs"'; do
  assert_equals "1" "$(count_lines "$RENDER" "$line")" \
    "req-002 (a): fresh RAVINTIO command appears once: $line"
done
assert_equals "2" "$(printf '%s\n' "$RENDER" | grep -c 'gate-write\.mjs' || true)" \
  "req-002 (a): gate-write runs once per matcher, twice in all"

echo ""
echo "=== req-002 (b): single-object user hooks stay as they were ==="

entry_json() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const e = (s.hooks[process.argv[2]] || []).find(x => x.hooks && !Array.isArray(x.hooks) && x.hooks.command === process.argv[3]);
    console.log(e ? JSON.stringify(e) : "missing");
  ' "$WS/.claude/settings.json" "$1" "$2"
}
assert_equals '{"matcher":"Write","hooks":{"type":"command","command":"node tools/my-lint.mjs"}}' \
  "$(entry_json PreToolUse 'node tools/my-lint.mjs')" \
  "req-002 (b): the PreToolUse user entry keeps its single object"
assert_equals '{"matcher":".*","hooks":{"type":"command","command":"node ./tools/notify.sh"}}' \
  "$(entry_json UserPromptSubmit 'node ./tools/notify.sh')" \
  "req-002 (b): the UserPromptSubmit user entry keeps its single object"

echo ""
echo "=== req-002: a second run leaves settings.json byte-identical ==="

cp "$WS/.claude/settings.json" "$WS/settings-first.json"
run_setup "$WS"
assert_exit_zero "$?" "req-002: a second run exits 0"
if cmp -s "$WS/settings-first.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
assert_equals "yes" "$SAME" "req-002: settings.json is byte-identical after the re-run"
rm -rf "$WS"

print_summary
