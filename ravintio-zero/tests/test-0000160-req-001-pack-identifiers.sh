#!/usr/bin/env bash
# Tests for feature 0000160-ravintio-rebrand, req-001: pack identifiers.
#
# (a) Every skill's name field matches its folder and starts with ravintio-.
# (b) Every regression manifest entry points at a file that exists.
# (c) The history folders match main, when a main ref is present. A shallow
#     CI checkout has no main ref, so (c) skips there.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"

# Prints "dir name" for each skill whose name field is wrong. Usage: bad_names skills_dir
bad_names() {
  local f dir name
  for f in "$1"/*/SKILL.md; do
    dir="$(basename "$(dirname "$f")")"
    name="$(sed -n 's/^name: *//p' "$f" | head -1)"
    case "$name" in
      ravintio-*) [ "$name" = "$dir" ] || echo "$dir $name" ;;
      *) echo "$dir $name" ;;
    esac
  done
}

echo "=== (a) skill names ==="
assert_equals "16" "$(ls -d "$ZERO_DIR"/skills/ravintio-*/ | wc -l | tr -d ' ')" "the pack ships 16 ravintio- skills"
assert_equals "" "$(bad_names "$ZERO_DIR/skills")" "every name field matches its folder and starts with ravintio-"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills/ravintio-x"
printf -- '---\nname: other-x\n---\n' > "$TMP/skills/ravintio-x/SKILL.md"
assert_contains "ravintio-x other-x" "$(bad_names "$TMP/skills")" "a wrong name field is flagged"

echo "=== (b) regression manifest paths ==="
MISSING=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  [ -f "$ZERO_DIR/$p" ] || MISSING="$MISSING $p"
done <<< "$(sed -n 's/.*"filePath": *"\(tests\/[^"]*\)".*/\1/p' "$ZERO_DIR/tests/regression/regression-manifest.json")"
assert_equals "" "$MISSING" "every regression manifest filePath exists"
assert_equals "yes" "$([ "$(grep -c '"filePath": *"tests/' "$ZERO_DIR/tests/regression/regression-manifest.json")" -gt 0 ] && echo yes || echo no)" "the manifest lists at least one test"

echo "=== (c) history folders match main ==="
if [ -n "$REPO_ROOT" ] && git -C "$REPO_ROOT" rev-parse -q --verify refs/heads/main >/dev/null 2>&1 \
  && git -C "$REPO_ROOT" cat-file -e "main:plan/_archive" 2>/dev/null; then
  # Ship adds this run's own archive and changelog, so only added files may differ.
  assert_equals "" "$(git -C "$REPO_ROOT" diff --name-only --diff-filter=a main -- plan/_archive plan/changelog)" \
    "no file in plan/_archive or plan/changelog differs from main"
  # The pack folder moved, so compare each applied migration with main under
  # either folder name.
  OLD="$(git -C "$REPO_ROOT" ls-tree --name-only main | grep -E '^[a-z]+-zero$' | head -1)"
  DIFFS=""
  for f in "$ZERO_DIR"/migrations/_done/*; do
    b="$(basename "$f")"
    if git -C "$REPO_ROOT" cat-file -e "main:$OLD/migrations/_done/$b" 2>/dev/null; then
      git -C "$REPO_ROOT" show "main:$OLD/migrations/_done/$b" | cmp -s - "$f" || DIFFS="$DIFFS $b"
    fi
  done
  assert_equals "" "$DIFFS" "applied migrations match main byte for byte"
else
  echo "  SKIP: no main ref in this checkout"
fi

print_summary
