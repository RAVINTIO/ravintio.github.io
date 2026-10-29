#!/usr/bin/env bash
# Tests for feature 0000171-faster-setup-ps1-tests, req-004, in setup.sh.
# Setup installs only each skill's own folder, byte for byte, with no bundled
# pack templates, standards, or schemas (ADR-004). A rerun removes bundled
# files an older install left and keeps the skill's own files.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
WORKSPACES=()

new_workspace() {
  local ws
  ws=$(mktemp -d -t ravintio_0000171_req004_test_XXXXXX)
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

# Prints every difference between each skill source folder and its installed
# copy, or nothing when every installed skill matches its source.
tree_diff() {
  local ws="$1" src name
  for src in "$ws/ravintio-zero/skills"/*/; do
    src="${src%/}"
    [ -f "$src/SKILL.md" ] || continue
    name="$(basename "$src")"
    diff -r "$src" "$ws/.claude/skills/$name" 2>&1
  done
}

echo ""
echo "=== req-004 AC-1: a fresh install holds only each skill's own files ==="
WS="$(new_workspace)"
run_setup "$WS"
assert_exit_zero "$?" "AC-1: setup.sh exits 0"
assert_equals "" "$(tree_diff "$WS")" "AC-1: each installed skill matches its source folder byte for byte"
assert_equals "0" "$(grep -cE '^ +(templates|standards): ' "$WS/setup.out")" "AC-1: setup prints no templates or standards bundle line"
SKILL_COUNT=$(find "$WS/ravintio-zero/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
LINE_COUNT=$(grep -cE '^  \+ [^/ ]+/SKILL\.md$' "$WS/setup.out")
assert_equals "$SKILL_COUNT" "$LINE_COUNT" "AC-1: setup prints one SKILL.md line per skill"
assert_equals "0" "$(grep -cE 'bundle_(templates|standards)' "$ZERO_DIR/setup.sh")" "AC-1: setup.sh does not parse bundle frontmatter"

echo ""
echo "=== req-004 AC-2: a rerun removes bundled files from an older install ==="
SK="$WS/.claude/skills"
mkdir -p "$SK/ravintio-plan/assets/templates" "$SK/ravintio-plan/assets/schemas" \
  "$SK/ravintio-plan/references" \
  "$SK/ravintio-orchestrator/assets/templates" "$SK/ravintio-orchestrator/references"
echo "old" >"$SK/ravintio-plan/assets/templates/requirement.template.md"
echo "old" >"$SK/ravintio-plan/assets/schemas/shared.schema.json"
echo "old" >"$SK/ravintio-plan/references/formatting-standards.md"
echo "old" >"$SK/ravintio-orchestrator/assets/templates/park.template.md"
echo "old" >"$SK/ravintio-orchestrator/references/code-quality-standards.md"
# Without the manifest, the rerun cannot wipe the skill folders first, so
# only the prune step can remove the bundled files.
rm -f "$SK/.ravintio-manifest"
run_setup "$WS"
assert_exit_zero "$?" "AC-2: the rerun exits 0"
assert_equals "no" "$([ -e "$SK/ravintio-plan/assets" ] && echo yes || echo no)" "AC-2: the bundled assets folder is gone"
assert_equals "no" "$([ -e "$SK/ravintio-plan/references" ] && echo yes || echo no)" "AC-2: the bundled references folder is gone"
assert_equals "no" "$([ -e "$SK/ravintio-orchestrator/assets/templates" ] && echo yes || echo no)" "AC-2: the orchestrator's bundled templates are gone"
assert_equals "no" "$([ -e "$SK/ravintio-orchestrator/references/code-quality-standards.md" ] && echo yes || echo no)" "AC-2: the orchestrator's bundled standard is gone"
assert_equals "yes" "$([ -f "$SK/ravintio-orchestrator/assets/.gitkeep" ] && echo yes || echo no)" "AC-2: the orchestrator's own assets file remains"
assert_equals "yes" "$([ -f "$SK/ravintio-orchestrator/references/orchestrator-scope-lock.md" ] && echo yes || echo no)" "AC-2: the orchestrator's own reference file remains"
assert_equals "" "$(tree_diff "$WS")" "AC-2: each installed skill matches its source folder after the rerun"

echo ""
echo "=== req-004 AC-2: a rerun with the manifest gives the same tree ==="
WS="$(new_workspace)"
run_setup "$WS"
SK="$WS/.claude/skills"
mkdir -p "$SK/ravintio-ship/assets/templates"
echo "old" >"$SK/ravintio-ship/assets/templates/changelog.template.md"
run_setup "$WS"
assert_exit_zero "$?" "AC-2: the rerun with the manifest exits 0"
assert_equals "" "$(tree_diff "$WS")" "AC-2: each installed skill matches its source folder"

echo ""
echo "=== req-004 security: the prune deletes only pack copies inside the install ==="
WS="$(new_workspace)"
run_setup "$WS"
SK="$WS/.claude/skills"
rm -f "$SK/.ravintio-manifest"
# S-010: a user file in references/ that no pack file names stays.
mkdir -p "$SK/ravintio-plan/references"
echo "mine" >"$SK/ravintio-plan/references/my-notes.md"
# S-008: a planted name holding a newline cannot aim the prune at a file in
# the folder setup runs from.
echo "keep" >"$WS/victim.txt"
mkdir -p "$SK/ravintio-plan/assets/templates"
touch "$SK/ravintio-plan/assets/templates/x
victim.txt"
# S-009: a linked skill folder is never pruned, so pack-named files at its
# target stay.
OUT="$(mktemp -d -t ravintio_0000171_req004_out_XXXXXX)"
WORKSPACES+=("$OUT")
mkdir -p "$OUT/assets/templates" "$OUT/references"
echo "theirs" >"$OUT/assets/templates/requirement.template.md"
echo "theirs" >"$OUT/references/formatting-standards.md"
rm -rf "$SK/ravintio-refactor"
ln -s "$OUT" "$SK/ravintio-refactor"
run_setup "$WS"
assert_exit_zero "$?" "security: the rerun exits 0"
assert_equals "yes" "$([ -f "$SK/ravintio-plan/references/my-notes.md" ] && echo yes || echo no)" "S-010: a user file in references stays"
assert_equals "yes" "$([ -f "$WS/victim.txt" ] && echo yes || echo no)" "S-008: a newline name cannot delete a file outside the skill"
assert_equals "yes" "$([ -f "$OUT/assets/templates/requirement.template.md" ] && echo yes || echo no)" "S-009: a linked skill folder keeps its template"
assert_equals "yes" "$([ -f "$OUT/references/formatting-standards.md" ] && echo yes || echo no)" "S-009: a linked skill folder keeps its standard"

print_summary
