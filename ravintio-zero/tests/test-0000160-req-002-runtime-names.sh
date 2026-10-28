#!/usr/bin/env bash
# Tests for feature 0000160-ravintio-rebrand, req-002: hooks and setup detect
# and write ravintio names. Covers the hooks, em-dash-guard's legacy sentinel
# alias (ADR-002), setup.sh markers, old-marker cleanup, core.hooksPath, and
# the stop on a leftover old pack folder (ADR-003).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ZERO_DIR/hooks/enforcement"


TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

new_workspace() {
  local ws
  ws=$(mktemp -d "$TMP/ws_XXXXXX")
  cp -r "$ZERO_DIR" "$ws/ravintio-zero"
  git init "$ws" >/dev/null 2>&1
  printf '%s\n' "$ws"
}

run_setup() {
  (cd "$1" && GIT_CEILING_DIRECTORIES="$(dirname "$1")" bash ravintio-zero/setup.sh claude-code \
    >"$1/setup.out" 2>"$1/setup.err")
}

echo ""
echo "=== req-002: hooks detect ravintio names ==="

P="$TMP/hookproj"
mkdir -p "$P/ravintio-zero" "$P/plan/current" "$P/src"
out="$(cd "$P" && printf '{"cwd":"%s"}' "$P" | node "$HOOKS/auto-trigger-orchestrator.mjs" 2>/dev/null)"
assert_contains "ravintio-zero/ detected" "$out" "auto-trigger-orchestrator detects ravintio-zero/"

P2="$TMP/oldproj"
mkdir -p "$P2/planifest-zero"
out="$(cd "$P2" && printf '{"cwd":"%s"}' "$P2" | node "$HOOKS/auto-trigger-orchestrator.mjs" 2>/dev/null)"
assert_equals "" "$out" "auto-trigger-orchestrator ignores the old pack folder"

# gate-write: no design.md, so src/ is blocked and .ravintio-session passes.
gw() {
  (cd "$P" && printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$P" "$1" \
    | node "$HOOKS/gate-write.mjs" >/dev/null 2>&1; echo $?)
}
assert_equals "2" "$(gw src/app.js)" "gate-write blocks src/ without a design"
assert_equals "0" "$(gw .ravintio-session)" "gate-write allowlists .ravintio-session"

P3="$TMP/sdproj"
mkdir -p "$P3/ravintio-zero/skills"
printf '# T\n\n## The pack\n\n| Folder | Contents |\n|--------|----------|\n| [skills/](ravintio-zero/skills/) | Skills |\n' >"$P3/README.md"
out="$(node "$ZERO_DIR/scripts/self-description-check.mjs" "$P3" 2>&1)"
assert_contains "match the repository" "$out" "self-description-check reads ravintio-zero/ paths"

echo ""
echo "=== req-002: em-dash-guard accepts both sentinels ==="

guard_rc() {
  local content="$1" payload
  payload=$(node -e '
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:"docs/a.md",content:process.argv[1]}}));
  ' "$content")
  (cd "$P" && printf '%s' "$payload" | node "$HOOKS/em-dash-guard.mjs" >/dev/null 2>&1; echo $?)
}
DASH="$(printf '\xe2\x80\x94')"
assert_equals "2" "$(guard_rc "a $DASH b")" "em dash without a sentinel is blocked"
assert_equals "0" "$(guard_rc "a $DASH b <!-- ravintio-em-dash-allow -->")" "new sentinel allows the write"
assert_equals "0" "$(guard_rc "a $DASH b <!-- planifest-em-dash-allow -->")" "legacy sentinel allows the write in 0.x"

echo ""
echo "=== req-002: setup.sh writes ravintio markers and clears old ones ==="

WS="$(new_workspace)"
mkdir -p "$WS/.claude/skills"
echo '{}' >"$WS/.claude/.planifest-setup-flags"
echo '[]' >"$WS/.claude/skills/.planifest-manifest"
run_setup "$WS"
assert_exit_zero "$?" "setup exits 0"
[ -f "$WS/.claude/.ravintio-setup-flags" ] && r=present || r=absent
assert_equals present "$r" ".claude/.ravintio-setup-flags is written"
[ -f "$WS/.claude/skills/.ravintio-manifest" ] && r=present || r=absent
assert_equals present "$r" ".claude/skills/.ravintio-manifest is written"
[ -e "$WS/.claude/.planifest-setup-flags" ] && r=present || r=absent
assert_equals absent "$r" "old setup-flags marker is removed"
[ -e "$WS/.claude/skills/.planifest-manifest" ] && r=present || r=absent
assert_equals absent "$r" "old manifest marker is removed"
assert_equals "ravintio-zero/hooks" "$(git -C "$WS" config core.hooksPath)" "core.hooksPath is ravintio-zero/hooks"

echo ""
echo "=== req-002: setup never follows a symlinked old marker ==="

WS="$(new_workspace)"
mkdir -p "$WS/.claude"
echo keep >"$TMP/target.txt"
ln -s "$TMP/target.txt" "$WS/.claude/.planifest-setup-flags"
run_setup "$WS"
assert_exit_zero "$?" "setup exits 0 with a symlinked old marker"
assert_equals keep "$(cat "$TMP/target.txt")" "symlink target is untouched"
[ -L "$WS/.claude/.planifest-setup-flags" ] && r=kept || r=gone
assert_equals kept "$r" "symlinked old marker is skipped"

echo ""
echo "=== req-002: setup stops on a leftover old folder ==="

for folder in "planifest-zero" "planifest-overrides"; do
  WS="$(new_workspace)"
  mkdir -p "$WS/$folder"
  run_setup "$WS"
  rc=$?
  assert_equals 1 "$rc" "setup exits 1 when $folder exists"
  msg="$(cat "$WS/setup.out" "$WS/setup.err")"
  assert_contains "$folder" "$msg" "message names $folder"
  assert_contains "migrate-ravintio-rename.sh" "$msg" "message names the migration script ($folder)"
  [ -e "$WS/.claude/.ravintio-setup-flags" ] && r=present || r=absent
  assert_equals absent "$r" "nothing is installed ($folder)"
done

echo ""
echo "=== req-002: setup stops on a dangling leftover link ==="

for folder in "planifest-zero" "planifest-overrides"; do
  WS="$(new_workspace)"
  ln -s "$TMP/no-such-folder" "$WS/$folder"
  run_setup "$WS"
  rc=$?
  assert_equals 1 "$rc" "setup exits 1 when $folder is a dangling link"
  [ -e "$WS/.claude/.ravintio-setup-flags" ] && r=present || r=absent
  assert_equals absent "$r" "nothing is installed (dangling $folder)"
done

echo ""
echo "=== req-002: setup skips old markers under a linked folder ==="

WS="$(new_workspace)"
mkdir -p "$TMP/real-skills"
echo keep >"$TMP/real-skills/.planifest-manifest"
mkdir -p "$WS/.claude"
ln -s "$TMP/real-skills" "$WS/.claude/skills"
run_setup "$WS"
assert_equals keep "$(cat "$TMP/real-skills/.planifest-manifest" 2>/dev/null)" "old marker under a linked .claude/skills is kept"
assert_contains "skipped" "$(cat "$WS/setup.err")" "setup warns about the linked folder"

print_summary
