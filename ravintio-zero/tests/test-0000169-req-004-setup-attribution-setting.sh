#!/usr/bin/env bash
# Tests for feature 0000169-release-hygiene, req-004: setup.sh sets
# "attribution": {"commit": "", "pr": ""} in .claude/settings.json when the
# key is absent, leaves a present key byte-identical, and a rerun changes nothing.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
WORKSPACES=()

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000169_req004_test_XXXXXX)
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  mkdir -p "$ws/.claude"
  WORKSPACES+=("$ws")
  printf '%s\n' "$ws"
}

cleanup() {
  local ws
  for ws in "${WORKSPACES[@]:-}"; do
    [ -n "$ws" ] || continue
    rm -rf "$ws"
  done
}
trap cleanup EXIT

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

# Prints the attribution value as compact JSON, or "absent".
attribution_of() {
  node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    process.stdout.write("attribution" in s ? JSON.stringify(s.attribution) : "absent");
  ' "$1/.claude/settings.json"
}

echo ""
echo "=== req-004 (a): an absent key gets the empty strings ==="
WS="$(new_workspace)"
echo '{"allowedTools":["Read"]}' >"$WS/.claude/settings.json"
run_setup "$WS"
assert_exit_zero "$?" "req-004 (a): setup.sh exits 0"
assert_equals '{"commit":"","pr":""}' "$(attribution_of "$WS")" "req-004 (a): attribution holds empty commit and pr"
assert_contains '"Read"' "$(cat "$WS/.claude/settings.json")" "req-004 (a): other settings are kept"

echo ""
echo "=== req-004 (b): no settings file gets the empty strings ==="
WS="$(new_workspace)"
run_setup "$WS"
assert_exit_zero "$?" "req-004 (b): setup.sh exits 0"
assert_equals '{"commit":"","pr":""}' "$(attribution_of "$WS")" "req-004 (b): attribution holds empty commit and pr"

echo ""
echo "=== req-004 (c): a present key stays byte-identical ==="
for value in '{"commit":"x","pr":"y"}' '{}' '"text"' 'null' '7'; do
  WS="$(new_workspace)"
  # Run setup once with the key present so the other writers settle, then compare a rerun.
  printf '{"attribution":%s,"allowedTools":["Agent"]}' "$value" >"$WS/.claude/settings.json"
  run_setup "$WS"
  assert_equals "$(printf '%s' "$value" | node -e 'process.stdout.write(JSON.stringify(JSON.parse(require("fs").readFileSync(0,"utf8"))))')" \
    "$(attribution_of "$WS")" "req-004 (c): attribution $value is untouched"
  cp "$WS/.claude/settings.json" "$WS/before.json"
  run_setup "$WS"
  assert_equals "0" "$(cmp -s "$WS/before.json" "$WS/.claude/settings.json"; echo $?)" "req-004 (c): $value rerun is byte-identical"
done

echo ""
echo "=== req-004 (d): a rerun changes nothing ==="
WS="$(new_workspace)"
run_setup "$WS"
cp "$WS/.claude/settings.json" "$WS/before.json"
run_setup "$WS"
assert_equals "0" "$(cmp -s "$WS/before.json" "$WS/.claude/settings.json"; echo $?)" "req-004 (d): second run is byte-identical"

echo ""
echo "=== req-004 (e): invalid JSON still stops setup ==="
WS="$(new_workspace)"
echo '{not json' >"$WS/.claude/settings.json"
run_setup "$WS"
assert_equals "1" "$?" "req-004 (e): setup.sh exits 1"
assert_equals "0" "$(grep -c attribution "$WS/.claude/settings.json" || true)" "req-004 (e): the file is not overwritten"

print_summary
