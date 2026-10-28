#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh fails or keeps a non-array hook event.
# Tests for feature 0000037-self-host-on-planifest-zero, req-008: a
# non-array PreToolUse or UserPromptSubmit value in setup.sh.
#
# If the value is present and isn't an array, setup.sh warns on stderr,
# replaces it with the RAVINTIO entries, and exits 0 (ADR-003). The warning
# names the event and the file, and never prints the old value (0000041
# ADR-003). setup.ps1 prints the same text. An absent or null value gets no warning.
# Each case runs setup.sh in a temporary workspace.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000037_req008_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  printf '%s\n' "$ws"
}

# Runs setup.sh and leaves its stderr in $1/stderr.txt.
run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code >/dev/null 2>"$1/stderr.txt")
}

# Prints "isArray matcher module" for each entry of one event. A non-array
# value prints "not-array".
event_entries() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const v = s.hooks[process.argv[2]];
    if (!Array.isArray(v)) { console.log("not-array"); process.exit(0); }
    for (const e of v) {
      const cmds = (e.hooks || []).map(h => h.command || "").join(" ");
      const m = /([A-Za-z0-9-]+)\.mjs/.exec(cmds);
      console.log(e.matcher + " " + (m ? m[1] : cmds));
    }
  ' "$1" "$2"
}

expected_entries() {
  if [ "$1" = "PreToolUse" ]; then
    printf '%s\n' "Write gate-write" "Edit gate-write" "Write ratchet-check" \
      "Edit ratchet-check" "Write em-dash-guard" "Edit em-dash-guard" "Bash merge-guard"
  else
    printf '%s\n' ".* auto-trigger-orchestrator" ".* check-orchestrator-presence" ".* check-design"
  fi
}

warning_for() {
  printf '  ! Warning: hooks.%s in .claude/settings.json is not an array. Setup replaced it with the RAVINTIO entries.' "$1"
}

for EV in PreToolUse UserPromptSubmit; do
  if [ "$EV" = "PreToolUse" ]; then OTHER="UserPromptSubmit"; else OTHER="PreToolUse"; fi
  for VAL in '{"matcher":"Write","hooks":[{"type":"command","command":"node tools/my-check.mjs"}]}' \
             '"broken"' '""' '0' 'false'; do
    echo ""
    echo "=== req-008: $EV holds $VAL ==="

    WS="$(new_workspace)"
    printf '{"keep":1,"hooks":{"Notification":"keep-me","%s":%s}}\n' "$EV" "$VAL" > "$WS/.claude/settings.json"
    run_setup "$WS"
    assert_exit_zero "$?" "req-008: setup.sh exits 0 with $EV set to $VAL"
    ERR="$(cat "$WS/stderr.txt")"
    assert_equals "$(warning_for "$EV")" "$ERR" \
      "req-008: setup.sh warns about $EV on stderr with the new line only"
    assert_equals "0" "$(grep -c -F -- "Old value" "$WS/stderr.txt" || true)" \
      "req-008: the warning about $EV does not print the old value"
    assert_equals "$(expected_entries "$EV")" "$(event_entries "$WS/.claude/settings.json" "$EV")" \
      "req-008: $EV is an array of only the RAVINTIO entries"
    assert_equals "$(expected_entries "$OTHER")" "$(event_entries "$WS/.claude/settings.json" "$OTHER")" \
      "req-008: $OTHER still gets the RAVINTIO entries"
    assert_equals "1 keep-me" "$(node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log(s.keep+" "+s.hooks.Notification)' "$WS/.claude/settings.json")" \
      "req-008: other keys and events stay as they were"
    rm -rf "$WS"
  done
done

for CASE in absent null; do
  echo ""
  echo "=== req-008: both events are $CASE ==="

  WS="$(new_workspace)"
  if [ "$CASE" = "absent" ]; then
    printf '{"hooks":{}}\n' > "$WS/.claude/settings.json"
  else
    printf '{"hooks":{"PreToolUse":null,"UserPromptSubmit":null}}\n' > "$WS/.claude/settings.json"
  fi
  run_setup "$WS"
  assert_exit_zero "$?" "req-008: setup.sh exits 0 when both events are $CASE"
  assert_equals "0" "$(grep -c 'is not an array' "$WS/stderr.txt" || true)" \
    "req-008: setup.sh prints no warning when both events are $CASE"
  for EV in PreToolUse UserPromptSubmit; do
    assert_equals "$(expected_entries "$EV")" "$(event_entries "$WS/.claude/settings.json" "$EV")" \
      "req-008: $EV gets the RAVINTIO entries when it is $CASE"
  done
  rm -rf "$WS"
done

print_summary
