#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh keeps an old RAVINTIO entry on another matcher.
# Tests for feature 0000037-self-host-on-planifest-zero, req-007: the
# setup.sh PreToolUse filter removes RAVINTIO entries on any matcher.
#
# An older setup.ps1 wired gate-write as one Write|Edit entry. setup.sh must
# remove it by module name, as setup.ps1 does (ADR-003). The match is
# case-sensitive, and only <module>.mjs at a path boundary counts
# (0000035 S-004). Each case runs setup.sh in a temporary workspace.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/../.."

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000037_req007_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  printf '%s\n' "$ws"
}

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
}

# Prints "matcher command" for every PreToolUse hook command.
pre_tool_lines() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    for (const e of s.hooks.PreToolUse || []) {
      for (const h of e.hooks || []) console.log(e.matcher + " " + h.command);
    }
  ' "$1"
}

count_lines() {
  printf '%s\n' "$1" | grep -c -F -x -- "$2" || true
}

echo ""
echo "=== req-007 (a): an old Write|Edit gate-write entry goes, a user hook stays ==="

WS="$(new_workspace)"
cat > "$WS/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "node .claude/hooks/enforcement/gate-write.mjs"}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/ratchet-check.mjs\""}]},
      {"matcher": "Write", "hooks": [{"type": "command", "command": "node tools/my-check.mjs"}]},
      {"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "node tools/my-gate-write.mjs"}]},
      {"matcher": "Edit", "hooks": [{"type": "command", "command": "node tools/Gate-Write.mjs"}]}
    ]
  }
}
JSON
run_setup "$WS"
assert_exit_zero "$?" "req-007 (a): setup.sh claude-code exits 0"
LINES="$(pre_tool_lines "$WS/.claude/settings.json")"
GATE='node ".claude/hooks/enforcement/gate-write.mjs"'
assert_equals "1" "$(count_lines "$LINES" "Write $GATE")" \
  "req-007 (a): gate-write appears once for Write"
assert_equals "1" "$(count_lines "$LINES" "Edit $GATE")" \
  "req-007 (a): gate-write appears once for Edit"
assert_equals "2" "$(printf '%s\n' "$LINES" | grep -c 'enforcement/gate-write.mjs' || true)" \
  "req-007 (a): gate-write appears twice in all"
assert_equals "0" "$(count_lines "$LINES" "Write|Edit node .claude/hooks/enforcement/gate-write.mjs")" \
  "req-007 (a): no Write|Edit gate-write entry remains"
assert_equals "0" "$(count_lines "$LINES" "Bash node \".claude/hooks/enforcement/ratchet-check.mjs\"")" \
  "req-007 (a): a RAVINTIO entry on another matcher goes too"
assert_equals "1" "$(count_lines "$LINES" "Write node tools/my-check.mjs")" \
  "req-007 (a): the planted user hook is still present"
assert_equals "1" "$(count_lines "$LINES" "Write|Edit node tools/my-gate-write.mjs")" \
  "req-007 (a): a module name not at a path boundary stays"
assert_equals "1" "$(count_lines "$LINES" "Edit node tools/Gate-Write.mjs")" \
  "req-007 (a): the match is case-sensitive"
assert_equals "10" "$(printf '%s\n' "$LINES" | grep -c .)" \
  "req-007 (a): PreToolUse holds the seven RAVINTIO entries and three user entries"

echo ""
echo "=== req-007 (b): a second run leaves settings.json unchanged ==="

FIRST="$(cat "$WS/.claude/settings.json")"
run_setup "$WS"
assert_exit_zero "$?" "req-007 (b): a second run exits 0"
assert_equals "$FIRST" "$(cat "$WS/.claude/settings.json")" \
  "req-007 (b): settings.json is unchanged by the re-run"
rm -rf "$WS"

print_summary
