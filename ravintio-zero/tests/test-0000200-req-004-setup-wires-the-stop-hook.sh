#!/usr/bin/env bash
# Tests for feature 0000200-reply-conventions, req-004: setup wires the Stop hook.
#
# setup.sh is run for real in a scratch project. setup.ps1 has no runner here
# (backlog 0000084), so its side is read from source, as the hook-parity suite does.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

stop_commands() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    for (const e of (s.hooks && s.hooks.Stop) || []) {
      for (const h of e.hooks || []) console.log(h.command);
    }
  ' "$1"
}

new_project() {
  WS=$(mktemp -d -t ravintio_0000200_req004_XXXXXX)
  cp -r "$ZERO_DIR" "$WS/ravintio-zero"
  git init "$WS" >/dev/null 2>&1
}

echo ""
echo "=== req-004 AC-1: setup installs the hook ==="
new_project
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
HOOK_PRESENT=no
[ -f "$WS/.claude/hooks/enforcement/check-reply-prefix.mjs" ] && HOOK_PRESENT=yes
assert_equals "yes" "$HOOK_PRESENT" "req-004 AC-1: the hook file is installed"
CMDS="$(stop_commands "$WS/.claude/settings.json")"
assert_equals "1" "$(printf '%s\n' "$CMDS" | grep -c check-reply-prefix)" \
  "req-004 AC-1: settings.json holds one Stop entry for the hook"
rm -rf "$WS"

echo ""
echo "=== req-004 AC-2: setup is idempotent and keeps a user Stop entry ==="
new_project
mkdir -p "$WS/.claude"
printf '%s\n' '{"hooks":{"Stop":[{"matcher":".*","hooks":[{"type":"command","command":"echo user-stop"}]}]}}' \
  > "$WS/.claude/settings.json"
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
CMDS="$(stop_commands "$WS/.claude/settings.json")"
assert_equals "1" "$(printf '%s\n' "$CMDS" | grep -c check-reply-prefix)" \
  "req-004 AC-2: two runs leave exactly one entry for the hook"
assert_equals "1" "$(printf '%s\n' "$CMDS" | grep -c user-stop)" \
  "req-004 AC-2: the user Stop entry stays"
rm -rf "$WS"

echo ""
echo "=== req-004 AC-3: setup.ps1 matches and the docs name the hook ==="
PS1="$(cat "$ZERO_DIR/setup.ps1")"
assert_contains "check-reply-prefix" "$PS1" "req-004 AC-3: setup.ps1 wires the hook"
assert_contains "'Stop'" "$PS1" "req-004 AC-3: setup.ps1 handles the Stop event"
assert_contains "check-reply-prefix" "$(cat "$ZERO_DIR/component.yml")" \
  "req-004 AC-3: component.yml names the hook"
assert_contains "check-reply-prefix" "$(cat "$ZERO_DIR/standards/hook-enforcement.md")" \
  "req-004 AC-3: the hook reference lists the hook"
assert_contains "check-reply-prefix" "$(cat "$ZERO_DIR/pipeline-reference.md")" \
  "req-004 AC-3: the pipeline reference names the hook"
assert_contains "check-reply-prefix" "$(cat "$ZERO_DIR/project-operations.md")" \
  "req-004 AC-3: the project operations guide names the hook"
assert_contains "check-reply-prefix" "$(cat "$ZERO_DIR/../docs/dependency-graph.md")" \
  "req-004 AC-3: the dependency graph names the hook"

print_summary
