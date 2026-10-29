#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh and setup.ps1 wire different hooks.
# Tests for feature 0000035-powershell-setup-parity, req-001: six hooks on
# Windows.
#
# setup.ps1 must wire the same enforcement hooks as setup.sh, in the same
# events, matchers, and order (ADR-001, backlog 0000090). No pwsh runner
# exists (backlog 0000084), so the setup.ps1 side is read from source: its
# entries are New-HookEntry calls inside $preToolEntries and
# $userPromptEntries. The setup.sh side comes from a real run.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/../.."
SETUP_PS1="$ZERO_DIR/setup.ps1"

extract_function_body() {
  awk -v name="function $1" '
    $0 ~ "^" name { flag=1 }
    flag && /^function / && $0 !~ "^" name { exit }
    flag { print }
  ' "$SETUP_PS1"
}

# Prints "event matcher module" for every entry setup.ps1 declares.
ps1_entries() {
  extract_function_body 'Merge-EnforcementHookSettings' | awk '
    /\$preToolEntries = @\(/    { event = "PreToolUse"; next }
    /\$userPromptEntries = @\(/ { event = "UserPromptSubmit"; next }
    event && /^[[:space:]]*\)[[:space:]]*$/ { event = ""; next }
    event && match($0, /New-HookEntry '\''[^'\'']*'\'' '\''[^'\'']*'\''/) {
      split(substr($0, RSTART, RLENGTH), p, "'\''")
      print event " " p[2] " " p[4]
    }
  '
}

# Prints "event matcher module" for every RAVINTIO entry a setup.sh run wrote.
sh_entries() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    for (const ev of ["PreToolUse", "UserPromptSubmit"]) {
      for (const e of s.hooks[ev] || []) {
        for (const h of e.hooks || []) {
          const m = /([a-z-]+)\.mjs/.exec(h.command || "");
          if (m) console.log(ev + " " + e.matcher + " " + m[1]);
        }
      }
    }
  ' "$1"
}

echo ""
echo "=== req-001 (a): setup.ps1 declares the same entries a setup.sh run writes ==="

WS=$(mktemp -d -t ravintio_0000035_req001_test_XXXXXX)
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
SH_LIST="$(sh_entries "$WS/.claude/settings.json")"
PS1_LIST="$(ps1_entries)"
rm -rf "$WS"

assert_equals "10" "$(printf '%s\n' "$SH_LIST" | grep -c .)" \
  "req-001 (a): a setup.sh run writes ten RAVINTIO hook entries"
assert_equals "$SH_LIST" "$PS1_LIST" \
  "req-001 (a): setup.ps1 declares the same event, matcher, and module list in the same order"

for module in gate-write ratchet-check em-dash-guard merge-guard auto-trigger-orchestrator \
              check-orchestrator-presence check-design; do
  assert_contains " $module" "$PS1_LIST" "req-001 (a): setup.ps1 wires $module"
done

echo ""
echo "=== req-001 (b): both settings branches use the declared entries ==="

BODY="$(extract_function_body 'Merge-EnforcementHookSettings')"
assert_equals "0" "$(grep -c "'Write|Edit'" "$SETUP_PS1" || true)" \
  "req-001 (b): setup.ps1 writes no Write|Edit matcher"
assert_contains '$filtered + $preToolEntries' "$BODY" \
  "req-001 (b): an existing settings.json gets the declared PreToolUse entries"
assert_contains '$filtered + $userPromptEntries' "$BODY" \
  "req-001 (b): an existing settings.json gets the declared UserPromptSubmit entries"
assert_contains 'PreToolUse       = @($preToolEntries)' "$BODY" \
  "req-001 (b): a new settings.json gets the declared PreToolUse entries"
assert_contains 'UserPromptSubmit = @($userPromptEntries)' "$BODY" \
  "req-001 (b): a new settings.json gets the declared UserPromptSubmit entries"

echo ""
echo "=== req-001 (c): the PreToolUse filter clears all three modules on any matcher ==="

# The filter is the per-command Remove-RavintioHookCommands call (0000038 ADR-002).
FILTER="$(printf '%s\n' "$BODY" | awk '/Remove-RavintioHookCommands -Entries \$existing\.hooks\.PreToolUse/{f=1} f{print} f && /-Pattern/{exit}')"
for module in gate-write ratchet-check em-dash-guard; do
  assert_contains "$module" "$FILTER" "req-001 (c): the PreToolUse filter names $module"
done
assert_equals "0" "$(printf '%s\n' "$FILTER" | grep -c 'matcher' || true)" \
  "req-001 (c): the PreToolUse filter doesn't test the matcher"

print_summary
