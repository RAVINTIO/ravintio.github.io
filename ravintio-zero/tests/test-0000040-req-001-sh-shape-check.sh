#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when setup.sh wires hooks into, or leaks, a settings.json that is valid JSON but not a settings object.
# Tests for feature 0000040-setup-json-checks-and-park, req-001: the setup.sh
# shape check (ADR-002). Valid JSON that is not a settings object stops setup
# with one fixed line, exit 1, and the file unchanged.
#
# Every planted file is built inline in a temporary workspace.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
PLANTED="PLANTED-0000040-secret"
SHAPE_LINE="! Error: .claude/settings.json is valid JSON but not a settings object setup can read. Fix it and rerun setup."
INVALID_LINE="! Error: .claude/settings.json is not valid JSON. Fix it and rerun setup."

# One copy of the pack serves every case. Each case gets a fresh project.
TEMPLATE="$(mktemp -d -t ravintio_0000040_req001_tpl_XXXXXX)"
cp -r "$ZERO_DIR" "$TEMPLATE/ravintio-zero"

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000040_req001_test_XXXXXX)
  cp -r "$TEMPLATE/ravintio-zero" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  printf '%s\n' "$ws"
}

# Runs setup and writes stdout and stderr to files in the workspace root.
run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

count_gate_write() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const pre = (s && s.hooks && Array.isArray(s.hooks.PreToolUse)) ? s.hooks.PreToolUse : [];
    let n = 0;
    for (const e of pre) for (const h of (Array.isArray(e.hooks) ? e.hooks : [])) {
      if (/gate-write\.mjs/.test(h.command || "")) n++;
    }
    console.log(n);
  ' "$1" 2>/dev/null || echo "unreadable"
}

echo ""
echo "=== req-001 (a): valid JSON that is not a settings object stops setup ==="

for input in '["x"]' 'null' '"text"' '42' 'true' '{"hooks":"text"}' '{"hooks":[]}' '{"hooks":5}'; do
  WS="$(new_workspace)"
  printf '%s\n' "$input" > "$WS/.claude/settings.json"
  cp "$WS/.claude/settings.json" "$WS/settings-before.json"
  run_setup "$WS"
  SETUP_EXIT=$?

  assert_equals "1" "$SETUP_EXIT" "req-001 (a): setup.sh exits 1 on $input"
  assert_equals "1" "$(grep -c -F -x -- "$SHAPE_LINE" "$WS/setup.err" || true)" \
    "req-001 (a): stderr holds the shape line exactly once on $input"
  assert_equals "0" "$(grep -c -F -- "not valid JSON" "$WS/setup.err" || true)" \
    "req-001 (a): the invalid-JSON line is absent on $input"
  assert_equals "0" "$(cat "$WS/setup.out" "$WS/setup.err" | grep -c -E '^\s+at |TypeError|SyntaxError' || true)" \
    "req-001 (a): no stack trace or parser message reaches the output on $input"
  assert_equals "0" "$(grep -c -F -- "enforcement hooks wired" "$WS/setup.out" || true)" \
    "req-001 (a): setup does not report the hooks as wired on $input"
  if cmp -s "$WS/settings-before.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
  assert_equals "yes" "$SAME" "req-001 (a): settings.json is byte-identical on $input"
  rm -rf "$WS"
done

echo ""
echo "=== req-001 (b): a planted value in a rejected file never reaches the output ==="

WS="$(new_workspace)"
printf '["%s"]\n' "$PLANTED" > "$WS/.claude/settings.json"
cp "$WS/.claude/settings.json" "$WS/settings-before.json"
run_setup "$WS"
SETUP_EXIT=$?
assert_equals "1" "$SETUP_EXIT" "req-001 (b): setup.sh exits 1 on the planted array"
assert_equals "0" "$(grep -c -F -- "$PLANTED" "$WS/setup.out" || true)" \
  "req-001 (b): the planted value is absent from stdout"
assert_equals "0" "$(grep -c -F -- "$PLANTED" "$WS/setup.err" || true)" \
  "req-001 (b): the planted value is absent from stderr"
if cmp -s "$WS/settings-before.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
assert_equals "yes" "$SAME" "req-001 (b): settings.json is byte-identical"
rm -rf "$WS"

echo ""
echo "=== req-001 (c): null hooks and case-duplicate keys pass, invalid JSON keeps its line ==="

for input in '{"hooks":null}' '{"a":1,"A":2}'; do
  WS="$(new_workspace)"
  printf '%s\n' "$input" > "$WS/.claude/settings.json"
  run_setup "$WS"
  SETUP_EXIT=$?
  assert_exit_zero "$SETUP_EXIT" "req-001 (c): setup.sh exits 0 on $input"
  assert_equals "0" "$(grep -c -F -- "$SHAPE_LINE" "$WS/setup.err" || true)" \
    "req-001 (c): the shape line is absent on $input"
  assert_equals "2" "$(count_gate_write "$WS/.claude/settings.json")" \
    "req-001 (c): gate-write is wired for Write and Edit on $input"
  rm -rf "$WS"
done

WS="$(new_workspace)"
printf '%s\n' '{"a":1,"A":2}' > "$WS/.claude/settings.json"
run_setup "$WS"
KEYS="$(node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log(String(s.a)+","+String(s.A))' "$WS/.claude/settings.json")"
assert_equals "1,2" "$KEYS" "req-001 (c): setup.sh keeps both case-duplicate keys"
rm -rf "$WS"

WS="$(new_workspace)"
printf '%s' '{"a":1,' > "$WS/.claude/settings.json"
cp "$WS/.claude/settings.json" "$WS/settings-before.json"
run_setup "$WS"
SETUP_EXIT=$?
assert_equals "1" "$SETUP_EXIT" "req-001 (c): setup.sh exits 1 on invalid JSON"
assert_equals "1" "$(grep -c -F -x -- "$INVALID_LINE" "$WS/setup.err" || true)" \
  "req-001 (c): invalid JSON still prints the invalid-JSON line once"
assert_equals "0" "$(grep -c -F -- "$SHAPE_LINE" "$WS/setup.err" || true)" \
  "req-001 (c): invalid JSON does not print the shape line"
if cmp -s "$WS/settings-before.json" "$WS/.claude/settings.json"; then SAME=yes; else SAME=no; fi
assert_equals "yes" "$SAME" "req-001 (c): the invalid file is byte-identical"
rm -rf "$WS"

rm -rf "$TEMPLATE"
print_summary
