#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-006: merge-guard hook.
#
# merge-guard.mjs blocks any gh pr merge unless the flag is --squash and the PR
# base starts with initiative/. It reads the base through gh pr view and fails
# closed. A stub gh on PATH stands in for the real one.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
GUARD="$ZERO_DIR/hooks/enforcement/merge-guard.mjs"

TMP=$(mktemp -d -t ravintio_0000043_req006_XXXXXX)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
# Stub gh: prints $STUB_BASE for "pr view", exits 1 when STUB_FAIL is set.
cat > "$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$@" >> "$STUB_LOG"
if [ -n "${STUB_FAIL:-}" ]; then exit 1; fi
if [ "$1 $2" = "pr view" ]; then printf '{"baseRefName":"%s"}\n' "$STUB_BASE"; fi
STUB
chmod +x "$TMP/bin/gh"
export STUB_LOG="$TMP/gh.log"

# run_guard <stdin> [ENV=VAL ...]: sets OUT and CODE.
run_guard() {
  local input="$1"; shift
  OUT=$(printf '%s' "$input" | env PATH="$TMP/bin:$PATH" "$@" node "$GUARD" 2>&1)
  CODE=$?
}
payload() { node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1"; }
# check <label> <expected exit> <command> <base> [fail]
check() {
  local label="$1" want="$2" cmd="$3" base="$4" fail="${5:-}"
  run_guard "$(payload "$cmd")" STUB_BASE="$base" STUB_FAIL="$fail"
  assert_equals "$want" "$CODE" "req-006: $label exits $want"
  if [ "$want" = 2 ]; then assert_contains "[RAVINTIO]" "$OUT" "req-006: $label prints a [RAVINTIO] message"; fi
}

echo ""
echo "=== req-006 (a): gh pr merge needs --squash and an initiative/* base ==="
if [ ! -f "$GUARD" ]; then assert_equals "exists" "missing" "req-006: merge-guard.mjs exists"; fi
check "squash into initiative/x" 0 "gh pr merge 12 --squash" "initiative/x"
check "squash into initiative/x with branch delete" 0 "gh pr merge 12 --squash --delete-branch" "initiative/x"
check "chained with &&" 0 "git fetch && gh pr merge 12 --squash" "initiative/x"
check "squash into main" 2 "gh pr merge 12 --squash" "main"
check "squash into initiativex (no slash)" 2 "gh pr merge 12 --squash" "initiativex"
check "no flag" 2 "gh pr merge 12" "initiative/x"
check "--merge" 2 "gh pr merge 12 --merge" "initiative/x"
check "--rebase" 2 "gh pr merge 12 --rebase" "initiative/x"
check "--admin with --squash" 2 "gh pr merge 12 --squash --admin" "initiative/x"
check "--auto without --squash" 2 "gh pr merge 12 --auto" "initiative/x"
check "--squash and --merge" 2 "gh pr merge 12 --squash --merge" "initiative/x"
check "chained with ; into main" 2 "echo hi; gh pr merge 12 --squash" "main"
check "gh pr view fails" 2 "gh pr merge 12 --squash" "initiative/x" 1
check "empty base" 2 "gh pr merge 12 --squash" ""
check "current-branch merge into main" 2 "gh pr merge --squash" "main"

: > "$STUB_LOG"
run_guard "$(payload 'gh pr merge 12 --squash; rm -rf x')" STUB_BASE=initiative/x
assert_contains "pr view 12 --json baseRefName" "$(cat "$STUB_LOG")" "req-006: base is read with gh pr view <pr> --json baseRefName"
assert_equals "0" "$(grep -c 'rm' "$STUB_LOG" || true)" "req-006: the command is never executed"

: > "$STUB_LOG"
run_guard "$(payload 'gh pr merge --squash')" STUB_BASE=initiative/x
assert_equals "pr view --json baseRefName" "$(head -1 "$STUB_LOG")" "req-006: no PR argument reads the current branch"

run_guard "$(payload 'gh pr merge 12 --squash')" STUB_BASE=main
assert_contains "main" "$OUT" "req-006: the block message names the base"
assert_contains "human-only" "$OUT" "req-006: the block message names the rule"

echo ""
echo "=== req-006 (b): other input passes ==="
check "non-merge Bash command" 0 "gh pr view 12" "main"
check "git status" 0 "git status" "main"
run_guard '{"tool_name":"Write","tool_input":{"file_path":"x","content":"gh pr merge 1"}}' STUB_BASE=main
assert_equals "0" "$CODE" "req-006: non-Bash payload exits 0"
run_guard 'not json {' STUB_BASE=main
assert_equals "0" "$CODE" "req-006: malformed stdin exits 0"
run_guard '' STUB_BASE=main
assert_equals "0" "$CODE" "req-006: empty stdin exits 0"

echo ""
echo "=== req-006 (d): fail-closed tripwire (security report F-001 to F-004) ==="
# Every bypass form exits 2 even when the stub base is initiative/x.
check "F-001 absolute path" 2 "/usr/bin/gh pr merge 5 --squash" "initiative/x"
check "F-001 backticks" 2 'echo `gh pr merge 5 --squash`' "initiative/x"
check "F-001 quoted gh" 2 '"gh" pr merge 5 --squash' "initiative/x"
check "F-001 leading backslash" 2 '\gh pr merge 5 --squash' "initiative/x"
check "F-001 bash -c" 2 "bash -c 'gh pr merge 5 --squash'" "initiative/x"
check "F-001 eval" 2 'eval "gh pr merge 5 --squash"' "initiative/x"
check "F-001 variable" 2 'g=gh; $g pr merge 5 --squash' "initiative/x"
check "F-001 alias" 2 "gh alias set m 'pr merge'" "initiative/x"
check "F-001 repeated -R" 2 "gh -R a/b -R c/d pr merge 5 --squash" "initiative/x"
check "F-001 --hostname" 2 "gh --hostname x pr merge 5 --squash" "initiative/x"
check "F-001 tab between pr and merge" 2 "$(printf 'echo pr\tmerge')" "initiative/x"
check "F-002 gh api merge path" 2 "gh api -X PUT repos/o/r/pulls/5/merge" "initiative/x"
check "F-002 gh api merge path, no slash prefix" 2 "gh api -X PUT pulls/5/merge" "initiative/x"
check "F-002 gh api graphql merge" 2 "gh api graphql -f query=mergePullRequest" "initiative/x"
PAD=$(printf 'a%.0s' $(seq 1 5000))
check "F-003 merge after 5000 characters" 2 "echo $PAD; gh pr merge 5 --squash" "initiative/x"
check "F-003 long command without merge" 0 "echo $PAD" "main"
check "F-004 command substitution ref" 2 'gh pr merge $(echo 5) --squash' "initiative/x"
check "F-004 --squash=false" 2 "gh pr merge 5 --squash=false" "initiative/x"
check "F-004 --squash=true" 0 "gh pr merge 5 --squash=true" "initiative/x"
check "F-004 two PR selectors" 2 "gh pr merge 5 6 --squash" "initiative/x"
check "plain merge with -R" 0 "gh pr merge 5 --squash -R o/r" "initiative/x"
check "text in a quoted string" 2 'git commit -m "pr merge notes"' "initiative/x"
run_guard "$(payload 'gh api -X PUT x/pulls/5/merge')" STUB_BASE=initiative/x
assert_contains "merge-guard:" "$OUT" "req-006: the unconfirmed message names merge-guard"
assert_contains "initiative/*" "$OUT" "req-006: the unconfirmed message names initiative/*"

echo ""
echo "=== req-006 (c): setup.sh and setup.ps1 register merge-guard ==="
SETUP_PS1="$ZERO_DIR/setup.ps1"
WS=$(mktemp -d -t ravintio_0000043_req006_ws_XXXXXX)
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
SH_ENTRY=$(node -e '
  const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  for (const e of s.hooks.PreToolUse || []) for (const h of e.hooks || [])
    if (/merge-guard\.mjs/.test(h.command)) console.log("PreToolUse " + e.matcher + " merge-guard");
' "$WS/.claude/settings.json")
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
SH_COUNT=$(grep -c merge-guard "$WS/.claude/settings.json" || true)
SH_INSTALLED="no"; [ -f "$WS/.claude/hooks/enforcement/merge-guard.mjs" ] && SH_INSTALLED="yes"
rm -rf "$WS"
PS1_ENTRY=$(awk '
  /\$preToolEntries = @\(/ { on=1; next }
  on && /^[[:space:]]*\)[[:space:]]*$/ { on=0 }
  on && /merge-guard/ { print }' "$SETUP_PS1" | sed -E "s/.*New-HookEntry '([^']*)' '([^']*)'.*/PreToolUse \1 \2/")
assert_equals "PreToolUse Bash merge-guard" "$SH_ENTRY" "req-006 (c): setup.sh registers merge-guard under PreToolUse with matcher Bash"
assert_equals "PreToolUse Bash merge-guard" "$PS1_ENTRY" "req-006 (c): setup.ps1 registers merge-guard under PreToolUse with matcher Bash"
assert_equals "$SH_ENTRY" "$PS1_ENTRY" "req-006 (c): the two entries match"
assert_equals "1" "$SH_COUNT" "req-006 (c): a second setup.sh run leaves one merge-guard entry"
assert_equals "yes" "$SH_INSTALLED" "req-006 (c): setup.sh installs merge-guard.mjs"
assert_equals "1" "$(grep -c 'gate-write|ratchet-check|em-dash-guard|merge-guard' "$SETUP_PS1")" "req-006 (c): setup.ps1 filter pattern covers merge-guard"

echo ""
echo "=== req-006: a block reaches the agent on stderr ==="
# Claude Code shows the agent only stderr when a PreToolUse hook exits 2.
ERR=$(payload "gh pr merge 7 --squash" | env PATH="$TMP/bin:$PATH" STUB_BASE="main" node "$GUARD" 2>&1 >/dev/null)
assert_contains "[RAVINTIO] merge-guard" "$ERR" "req-006: the block reason is on stderr"

print_summary
