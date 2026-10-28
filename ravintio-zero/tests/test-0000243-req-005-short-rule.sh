#!/usr/bin/env bash
# Test: 0000243 req-005 short Resume Detection rule
# AC-1: the Resume Detection section of SKILL.md is 400 bytes or fewer.
# AC-2: the Pack Index names the resume reference.
# AC-3: the reference holds every line of the old section.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
REF="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md"
BASE="$SCRIPT_DIR/fixtures/0000243-resume-detection-base.md"

section_bytes() { # file: bytes from the Resume Detection heading to the next rule line
  awk '/^## Resume Detection$/ {on=1} on && /^---$/ {exit} on' "$1" | wc -c | tr -d ' '
}

echo "=== AC-1: the section is 400 bytes or fewer ==="
BYTES="$(section_bytes "$SKILL")"
assert_equals "yes" "$([ "$BYTES" -gt 0 ] && [ "$BYTES" -le 400 ] && echo yes || echo no)" "Resume Detection is 1 to 400 bytes ($BYTES)"
assert_equals "1" "$(grep -cxF '## Resume Detection' "$SKILL")" "SKILL.md keeps one Resume Detection heading"

echo "=== AC-1 mutation: the old section fails the size check ==="
OLD_BYTES="$(section_bytes "$BASE")"
assert_equals "no" "$([ "$OLD_BYTES" -le 400 ] && echo yes || echo no)" "the old section is over 400 bytes ($OLD_BYTES)"

echo "=== AC-2: the Pack Index names the reference ==="
INDEX="$(sed -n '/^## Pack Index/,/^---$/p' "$SKILL")"
assert_contains "references/orchestrator-resume-detection.md" "$INDEX" "Pack Index has a row for the resume reference"
assert_contains "references/orchestrator-resume-detection.md" "$(awk '/^## Resume Detection$/ {on=1} on && /^---$/ {exit} on' "$SKILL")" "the rule names the reference"
assert_contains "resume-detect.mjs" "$(awk '/^## Resume Detection$/ {on=1} on && /^---$/ {exit} on' "$SKILL")" "the rule names the script"

echo "=== AC-3: the reference holds every line of the old section ==="
missing_lines() {
  grep -v '^[[:space:]]*$' "$1" | grep -v '^#' | while IFS= read -r line; do
    grep -Fxq -- "$line" "$2" || printf '%s\n' "$line"
  done
}
assert_equals "" "$(missing_lines "$BASE" "$REF")" "every old line is in the reference"

echo "=== AC-3 mutation: removing one old line is reported ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
grep -vF 'Never patch a partial file.' "$REF" > "$TMP/ref.md"
assert_contains "Never patch a partial file." "$(missing_lines "$BASE" "$TMP/ref.md")" "the check reports the removed line"

print_summary
