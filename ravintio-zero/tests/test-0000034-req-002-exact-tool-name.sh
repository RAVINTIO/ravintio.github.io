#!/usr/bin/env bash
# Tests for feature 0000034-setup-hardening, req-002: exact tool name.
#
# setup.sh must accept only an exact match to an entry in VALID_TOOLS, the
# same as setup.ps1's -contains check. grep -w matched partial words and
# regular expressions (backlog 0000088).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000034_req002_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

echo ""
echo "=== req-002 (a): the exact tool name still runs ==="

WS=$(make_workspace)
cd "$WS"
OUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero "$?" "req-002 (a): setup.sh claude-code exits 0"
cd /; rm -rf "$WS"

echo ""
echo "=== req-002 (b): partial and pattern names are rejected ==="

for name in claude code '.*' c.aude-code 'claude-code ' ''claude-code-x; do
  WS=$(make_workspace)
  cd "$WS"
  OUT="$(bash ravintio-zero/setup.sh "$name" 2>&1)"
  EXIT=$?
  assert_equals "1" "$EXIT" "req-002 (b): tool name '$name' exits 1"
  assert_contains "Unknown tool" "$OUT" "req-002 (b): tool name '$name' prints Unknown tool"
  assert_equals "no" "$([ -e .claude ] && echo yes || echo no)" \
    "req-002 (b): tool name '$name' writes no .claude folder"
  cd /; rm -rf "$WS"
done

echo ""
echo "=== req-002 (c): the grep -w check is gone ==="

assert_equals "no" "$(grep -q 'grep -qw "\$TOOL"' "$ZERO_DIR/setup.sh" && echo yes || echo no)" \
  "req-002 (c): setup.sh no longer uses grep -qw on the tool name"

print_summary
