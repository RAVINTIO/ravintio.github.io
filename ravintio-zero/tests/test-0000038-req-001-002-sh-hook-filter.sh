#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh drops a user command or matches a RAVINTIO command by substring.
# Tests for feature 0000038-setup-hook-filter-fixes, req-001 and req-002: the
# setup.sh per-command filter for PreToolUse and UserPromptSubmit.
#
# Each planted entry comes from the shared fixtures in
# fixtures/0000038-hook-filter/, which the setup.ps1 suite also reads. Setup
# removes each RAVINTIO command from a hook entry and keeps every user
# command. The path-boundary match is case-sensitive (0000035 S-004).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
FIXTURES="$SCRIPT_DIR/fixtures/0000038-hook-filter"

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000038_req001_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  printf '%s\n' "$ws"
}

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
}

# Prints every hook command as event|matcher|command. PreToolUse comes first,
# then UserPromptSubmit, then other events in file order. A hook entry with no
# commands prints as event|matcher| (fixtures README).
render_hooks() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const hooks = s.hooks || {};
    const first = ["PreToolUse", "UserPromptSubmit"];
    const events = first.concat(Object.keys(hooks).filter(e => !first.includes(e)));
    for (const ev of events) {
      for (const e of hooks[ev] || []) {
        const cmds = Array.isArray(e.hooks) ? e.hooks : [];
        if (cmds.length === 0) { console.log(ev + "|" + (e.matcher || "") + "|"); continue; }
        for (const h of cmds) console.log(ev + "|" + (e.matcher || "") + "|" + h.command);
      }
    }
  ' "$1"
}

count_lines() {
  printf '%s\n' "$1" | grep -c -F -x -- "$2" || true
}

WS="$(new_workspace)"
cp "$FIXTURES/settings-before.json" "$WS/.claude/settings.json"
run_setup "$WS"
SETUP_EXIT=$?
RENDER="$(render_hooks "$WS/.claude/settings.json")"
EXPECTED="$(cat "$FIXTURES/expected-after.txt")"

echo ""
echo "=== req-001 (a): a shared hook entry keeps only its user command ==="

assert_exit_zero "$SETUP_EXIT" "req-001 (a): setup.sh claude-code exits 0"
assert_equals "1" "$(count_lines "$RENDER" "PreToolUse|Write|node tools/my-lint.mjs")" \
  "req-001 (a): the PreToolUse user command survives with its matcher"
assert_equals "1" "$(count_lines "$RENDER" "UserPromptSubmit|.*|node ./tools/notify.sh")" \
  "req-001 (a): the UserPromptSubmit user command survives with its matcher"
assert_equals "1" "$(count_lines "$RENDER" "PreToolUse|Bash|")" \
  "req-001 (a): a hook entry with no commands stays as it was"

echo ""
echo "=== req-001 (b): RAVINTIO-only entries go, fresh entries appear once ==="

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
    "req-001 (b): fresh RAVINTIO command appears once: $line"
done
assert_equals "0" "$(printf '%s\n' "$RENDER" | grep -c 'Write|Edit' || true)" \
  "req-001 (b): the RAVINTIO-only Write|Edit entry is gone"
assert_equals "$EXPECTED" "$RENDER" \
  "req-001 (b): every hook command matches expected-after.txt"

echo ""
echo "=== req-002 (a): user commands that only look like RAVINTIO ones survive ==="

assert_equals "1" "$(count_lines "$RENDER" "UserPromptSubmit|.*|node ./tools/my-check-design-helper.sh")" \
  "req-002 (a): a module name as a bare substring is a user command"
assert_equals "1" "$(count_lines "$RENDER" "UserPromptSubmit|.*|node ./tools/Check-Design.mjs")" \
  "req-002 (a): the path-boundary match is case-sensitive"
assert_equals "1" "$(count_lines "$RENDER" "PreToolUse|Edit|node tools/Gate-Write.mjs")" \
  "req-002 (a): the PreToolUse match stays case-sensitive"

echo ""
echo "=== req-002 (b): no substring match is left in setup.sh ==="

for module in check-design auto-trigger-orchestrator check-orchestrator-presence; do
  assert_equals "0" "$(grep -c -F "includes(\"$module\")" "$ZERO_DIR/setup.sh" || true)" \
    "req-002 (b): setup.sh has no bare includes(\"$module\")"
done
assert_equals "0" "$(printf '%s\n' "$RENDER" | grep -c '^UserPromptSubmit|.*|node \.claude/hooks/' || true)" \
  "req-002 (b): every unquoted older UserPromptSubmit command is removed"

echo ""
echo "=== req-001 (c): a second run leaves settings.json byte-identical ==="

cp "$WS/.claude/settings.json" "$WS/settings-first.json"
run_setup "$WS"
assert_exit_zero "$?" "req-001 (c): a second run exits 0"
if cmp -s "$WS/settings-first.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
assert_equals "yes" "$SAME" "req-001 (c): settings.json is byte-identical after the re-run"
assert_equals "1" "$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).keep)' "$WS/.claude/settings.json")" \
  "req-001 (c): the top-level key keep survives"
rm -rf "$WS"

echo ""
echo "=== req-001: a hook entry whose hooks is not an array stays as it was ==="

# The entry keeps its string value, even though it names a RAVINTIO module.
# A single-object hooks value now counts as a one-item array (0000039 req-002),
# so this case plants a value that is neither an array nor an object.
WS="$(new_workspace)"
cat > "$WS/.claude/settings.json" <<'JSON'
{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":"node .claude/hooks/enforcement/gate-write.mjs"}]}}
JSON
run_setup "$WS"
assert_exit_zero "$?" "req-001: setup.sh exits 0 with a non-array hooks value"
assert_equals '{"matcher":"Write","hooks":"node .claude/hooks/enforcement/gate-write.mjs"}' \
  "$(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks.PreToolUse[0]))' "$WS/.claude/settings.json")" \
  "req-001: the non-array hook entry stays first and unchanged"
assert_equals "8" "$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks.PreToolUse.length)' "$WS/.claude/settings.json")" \
  "req-001: the seven fresh PreToolUse entries follow it"
rm -rf "$WS"

print_summary
