#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-005:
# a settings.json write fault stops setup.sh with one fixed line that names
# the relative path, exit 1, and no absolute path, error code, or stack frame.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ERROR_LINE="! Error: .claude/settings.json could not be written. Fix its permissions and rerun setup."
WORKSPACES=()

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000151_req005_test_XXXXXX)
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
    chmod -R u+w "$ws" 2>/dev/null
    rm -rf "$ws"
  done
}
trap cleanup EXIT

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

count_line() {
  grep -c -F -x -- "$ERROR_LINE" "$1" || true
}

check_clean_output() {
  local ws="$1" label="$2"
  local combined
  combined="$(cat "$ws/setup.out" "$ws/setup.err")"
  assert_equals "0" "$(printf '%s\n' "$combined" | grep -c -F -- "$ws" || true)" \
    "$label: no absolute path in the output"
  assert_equals "0" "$(printf '%s\n' "$combined" | grep -c -E 'EACCES|EPERM|EROFS|^\s+at ' || true)" \
    "$label: no error code or stack frame in the output"
  assert_equals "0" "$(find "$ws/.claude" -maxdepth 1 -name '*.ravintio-tmp' | wc -l | tr -d ' ')" \
    "$label: no temporary file is left"
}

echo ""
echo "=== req-005 (a): a read-only settings.json ==="

WS="$(new_workspace)"
echo '{"allowedTools":["Agent"]}' >"$WS/.claude/settings.json"
chmod 444 "$WS/.claude/settings.json"
BEFORE="$(shasum "$WS/.claude/settings.json" | cut -d' ' -f1)"
run_setup "$WS"
CODE=$?
assert_equals "1" "$CODE" "req-005 (a): setup.sh exits 1"
assert_equals "1" "$(count_line "$WS/setup.err")" "req-005 (a): stderr holds the fixed line once"
assert_equals "1" "$(grep -c . "$WS/setup.err" || true)" "req-005 (a): stderr holds no other line"
assert_equals "$BEFORE" "$(shasum "$WS/.claude/settings.json" | cut -d' ' -f1)" "req-005 (a): the file bytes are unchanged"
check_clean_output "$WS" "req-005 (a)"

echo ""
echo "=== req-005 (a): a read-only .claude folder with no settings.json ==="

WS="$(new_workspace)"
# Setup fills the folder once, then the file goes and the folder locks.
run_setup "$WS"
rm -f "$WS/.claude/settings.json"
chmod 555 "$WS/.claude"
run_setup "$WS"
CODE=$?
chmod 755 "$WS/.claude"
assert_equals "1" "$CODE" "req-005 (a): setup.sh exits 1"
assert_equals "1" "$(count_line "$WS/setup.err")" "req-005 (a): stderr holds the fixed line once"
check_clean_output "$WS" "req-005 (a) folder"

echo ""
echo "=== req-005 (a): a fault at the allowedTools write alone ==="

WS="$(new_workspace)"
REAL_NODE="$(command -v node)"
mkdir -p "$WS/shim"
cat >"$WS/shim/node" <<SHIM
#!/usr/bin/env bash
case "\$*" in *allowedTools*) chmod 444 "$WS/.claude/settings.json" ;; esac
exec "$REAL_NODE" "\$@"
SHIM
chmod +x "$WS/shim/node"
(cd "$WS" && PATH="$WS/shim:$PATH" GIT_CEILING_DIRECTORIES="$(dirname "$WS")" bash ravintio-zero/setup.sh claude-code \
  >"$WS/setup.out" 2>"$WS/setup.err")
CODE=$?
assert_equals "1" "$CODE" "req-005 (a): setup.sh exits 1"
assert_equals "1" "$(count_line "$WS/setup.err")" "req-005 (a): stderr holds the fixed line once"
assert_contains "gate-write" "$(cat "$WS/.claude/settings.json")" "req-005 (a): the hook install write had succeeded"
check_clean_output "$WS" "req-005 (a) allowedTools"

print_summary
