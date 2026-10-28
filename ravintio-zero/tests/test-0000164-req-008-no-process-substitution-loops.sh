#!/usr/bin/env bash
# Tests for feature 0000164-hardening-and-backlog-skill, req-008: guard.
#
# On macOS Bash 3.2, a while-read loop fed by process substitution can silently
# stop yielding lines. No file under tests/ may use that loop form. Feed the
# loop with a herestring of the command output instead, and skip empty lines.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
SELF="$SCRIPT_DIR/$(basename "$0")"

# Built from parts so this file never contains the pattern it searches for.
PATTERN="done"" < ""<("

# Prints each file under the directory $1 that contains the pattern, except this file.
offenders() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$f" = "$SELF" ] && continue
    grep -qF -- "$PATTERN" "$f" 2>/dev/null && echo "${f#"$1"/}"
  done <<< "$(find "$1" \( -type f -o -type l \) | LC_ALL=C sort)"
}

echo "=== req-008: no process-substitution loops under tests/ ==="
assert_equals "" "$(offenders "$SCRIPT_DIR")" "no file under tests/ contains the process-substitution loop"

echo "=== req-008: the guard detects a planted file ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf 'while read -r l; do :; %s echo x)\n' "$PATTERN" > "$TMP/bad.sh"
printf 'while read -r l; do :; done <<< "$(echo x)"\n' > "$TMP/good.sh"
assert_equals "bad.sh" "$(offenders "$TMP")" "the guard flags only the file with the pattern"

# Prints "file:line" for each herestring-fed loop whose first body line is not
# an empty-line skip. The scan walks back from each closing line to its own
# "while", counting nested loops, then reads the line after it.
unguarded() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    awk -v name="${f#"$1"/}" '
      { line[NR] = $0 }
      /^[ \t]*done <<< "\$\(/ {
        depth = 0
        for (i = NR - 1; i > 0; i--) {
          if (line[i] ~ /^[ \t]*done([ \t]|$)/) depth++
          else if (line[i] ~ /^[ \t]*(while|for|until)[ \t].*; do[ \t]*$/) {
            if (depth == 0) break
            depth--
          }
        }
        if (line[i + 1] !~ /^[ \t]*\[ -n "\$[A-Za-z_]+" \] \|\| continue/) print name ":" NR
      }' "$f"
  done <<< "$(find "$1" -name '*.sh' | LC_ALL=C sort)"
}

echo "=== req-008: REQ-003 every herestring loop skips empty input ==="
assert_equals "" "$(unguarded "$SCRIPT_DIR")" "REQ-003 each herestring loop starts with an empty-line skip"

echo "=== req-008: REQ-003 the check detects an unguarded loop ==="
mkdir -p "$TMP/g"
printf 'while IFS= read -r l; do\n  echo "$l"\ndone <<< "$(echo x)"\n' > "$TMP/g/bad.sh"
printf 'while IFS= read -r l; do\n  [ -n "$l" ] || continue\ndone <<< "$(echo x)"\n' > "$TMP/g/good.sh"
assert_equals "bad.sh:3" "$(unguarded "$TMP/g")" "REQ-003 the check flags only the unguarded loop"

print_summary
