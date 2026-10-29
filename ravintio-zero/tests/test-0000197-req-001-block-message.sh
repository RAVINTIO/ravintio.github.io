#!/usr/bin/env bash
# Tests for feature 0000197-merge-guard-block-message, req-001: the merge-guard
# block message names the real reason and advises the Write tool.
#
# The block set stays as it was. These tests check message text and exit codes.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

GUARD="$SCRIPT_DIR/../hooks/enforcement/merge-guard.mjs"

TMP=$(mktemp -d -t ravintio_0000197_req001_XXXXXX)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
if [ "$1 $2" = "pr view" ]; then printf '{"baseRefName":"%s"}\n' "$STUB_BASE"; fi
STUB
chmod +x "$TMP/bin/gh"

payload() { node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1"; }
run_guard() {
  OUT=$(printf '%s' "$(payload "$1")" | env PATH="$TMP/bin:$PATH" STUB_BASE="initiative/x" node "$GUARD" 2>&1)
  CODE=$?
}

HEREDOC=$'cat > notes.md <<\'EOF\'\n- the agent runs gh pr merge --squash when CI is green\nEOF'

echo ""
echo "=== req-001 AC-1: heredoc that names the merge command ==="
run_guard "$HEREDOC"
assert_equals "2" "$CODE" "req-001 AC-1: the heredoc command exits 2"
assert_contains "names a merge in text" "$OUT" "req-001 AC-1: the message says the command names a merge in text"
assert_contains "Write tool" "$OUT" "req-001 AC-1: the message names the Write tool"

echo ""
echo "=== req-001 AC-2: the same command over 4096 characters ==="
PAD=$(printf 'a%.0s' $(seq 1 4100))
run_guard "$HEREDOC"$'\n'"# $PAD"
assert_equals "2" "$CODE" "req-001 AC-2: the long command exits 2"
assert_contains "over 4096 characters" "$OUT" "req-001 AC-2: the message names the length"
assert_contains "Write tool" "$OUT" "req-001 AC-2: the message names the Write tool"

echo ""
echo "=== req-001 AC-3: the block set is unchanged ==="
run_guard "gh pr merge 12 --squash"
assert_equals "0" "$CODE" "req-001 AC-3: a plain squash merge into initiative/* still passes"
run_guard "git status"
assert_equals "0" "$CODE" "req-001 AC-3: a command with no merge words still passes"
run_guard 'git commit -m "pr merge notes"'
assert_equals "2" "$CODE" "req-001 AC-3: merge words in a quoted string still block"
assert_contains "Write tool" "$OUT" "req-001 AC-3: the quoting reason also advises the Write tool"
run_guard "gh pr merge 12 --squash; gh pr merge 13 --squash"
assert_equals "2" "$CODE" "req-001 AC-3: two merge calls still block"

print_summary
