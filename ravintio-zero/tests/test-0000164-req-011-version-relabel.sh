#!/usr/bin/env bash
# Tests for feature 0000164-hardening-and-backlog-skill, req-011: version relabel.
#
# 0000160 is relabelled 0.12.0. No live file may name a 2.0.0 removal point or
# promise a 1.x line. History (plan/_archive/, plan/changelog/) and the run's
# own plan/current/ stay as written. Unrelated version strings, such as a
# library version or a frontmatter version, do not match the promise wording.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SELF_REL="ravintio-zero/tests/test-0000164-req-011-version-relabel.sh"

# Built from parts so this file never holds the wording it searches for.
V2="2""\\.0\\.0"
X1="1""\\.x"
PLAIN_V2="2"".0.0"
PLAIN_X1="1"".x"
PROMISE="(at ${V2}|(in|through|for) ${X1}|${X1} (line|legacy))"

# Prints each line of the files named on stdin that holds a version promise.
promises() {
  local f
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    grep -n -E -- "$PROMISE" "$f" 2>/dev/null | sed "s|^|$f:|"
  done
}

live_files() {
  git -C "$ROOT_DIR" ls-files -- . ':!plan/_archive' ':!plan/changelog' ':!plan/current' ":!$SELF_REL" \
    | sed "s|^|$ROOT_DIR/|"
}

echo "=== req-011: no live file promises a 1.x line or a 2.0.0 removal ==="
assert_equals "" "$(live_files | promises)" "no live file names a 2.0.0 removal point or a 1.x line"

echo "=== req-011: the guard detects planted wording ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf '%s\n' "# Legacy, remove at ${PLAIN_V2}" > "$TMP/a.txt"
printf '%s\n' "Accepted in ${PLAIN_X1} only" > "$TMP/b.txt"
printf '%s\n' "sqlalchemy 1.x patterns, version: \"1.0.0\"" > "$TMP/c.txt"
assert_equals "1" "$(printf '%s\n' "$TMP/a.txt" | promises | wc -l | tr -d ' ')" "the guard catches 'remove at 2.0.0'"
assert_equals "1" "$(printf '%s\n' "$TMP/b.txt" | promises | wc -l | tr -d ' ')" "the guard catches 'in 1.x'"
assert_equals "0" "$(printf '%s\n' "$TMP/c.txt" | promises | wc -l | tr -d ' ')" "the guard ignores unrelated version strings"

echo "=== req-011: brand-prose version check ==="
source "$SCRIPT_DIR/helpers/version.sh"
assert_equals "yes" "$(version_at_least_0_12 0.12.0)" "0.12.0 passes"
assert_equals "yes" "$(version_at_least_0_12 0.13.0)" "0.13.0 passes"
assert_equals "yes" "$(version_at_least_0_12 1.0.0)" "1.0.0 passes"
assert_equals "no" "$(version_at_least_0_12 0.11.0)" "0.11.0 fails"
assert_equals "no" "$(version_at_least_0_12 junk)" "a non-version fails"

print_summary
