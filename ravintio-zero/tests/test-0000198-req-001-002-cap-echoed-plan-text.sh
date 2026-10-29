#!/usr/bin/env bash
# 0000198 req-001 and req-002: cap-echoed-plan-text
# ratchet-check.mjs and consistency-check.mjs print at most 200 characters of an echoed line.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

RATCHET="$ZERO_DIR/hooks/enforcement/ratchet-check.mjs"
CHECK="$ZERO_DIR/scripts/consistency-check.mjs"
TMP="$(mktemp -d -t ravintio_0000198_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

MARK=' …[truncated]'
# 200 characters, and a line whose 200th code point is an astral character.
L200=$(node -e 'process.stdout.write("a".repeat(200))')
LONG=$(node -e 'process.stdout.write("a".repeat(1000))')
ASTRAL=$(node -e 'process.stdout.write("b".repeat(199) + "\u{1F600}" + "c".repeat(100))')
ASTRAL_CAP=$(node -e 'process.stdout.write("b".repeat(199) + "\u{1F600}")')

# Runs the ratchet for an edit that removes the guarded line $2. Prints the removed line, then the exit code.
ratchet_removed() {
  local proj="$TMP/$1" line="$2"
  mkdir -p "$proj/plan/current"
  printf -- '---\nstatus: "active"\n---\n' > "$proj/plan/current/loop-state-x.md"
  printf '## Acceptance Criteria\n- [ ] keep\n- [ ] %s\n' "$line" > "$proj/plan/current/req.md"
  local payload err rc
  payload=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:process.argv[1],content:"## Acceptance Criteria\n- [ ] keep\n"}}))' "$proj/plan/current/req.md")
  err=$(cd "$proj" && printf '%s' "$payload" | node "$RATCHET" 2>&1 1>/dev/null); rc=$?
  RATCHET_RC="$rc"
  RATCHET_LINE=$(printf '%s\n' "$err" | sed -n 's/^  removed: "\(.*\)"$/\1/p')
}

# Runs the consistency check on a story map with one row. $2 is the label, $3 the Requirement cell.
check_finding() {
  local d="$TMP/$1/plan/current"
  mkdir -p "$d/requirements"
  printf '# Design\n## Scope\n- In: things\n' > "$d/design.md"
  printf '# Requirement: REQ-001 - Demo\n**Source:** US-001\n## Acceptance Criteria\n- [ ] AC-1: One\n  - Given a\n  - When b\n  - Then c\n' > "$d/requirements/req-001-demo.md"
  printf '| Activity | Step | Story | Requirement |\n|---|---|---|---|\n| A | %s | US-001 | %s |\n' "$2" "$3" > "$d/story-map.md"
  CHECK_OUT=$(node "$CHECK" "$d" 2>&1); CHECK_RC=$?
  CHECK_LABEL=$(printf '%s\n' "$CHECK_OUT" | sed -nE 's/^.*row "(.*)" (has|names) .*$/\1/p')
}

echo ""
echo "=== 0000198 req-001 cap the ratchet block message ==="

ratchet_removed long "$LONG"
assert_equals "2" "$RATCHET_RC" "req-001 AC-1: a 1000-character removed line still exits 2"
assert_equals "${L200}${MARK}" "$RATCHET_LINE" "req-001 AC-1: the removed line is 200 characters plus the cut marker"

ratchet_removed exact "$L200"
assert_equals "2" "$RATCHET_RC" "req-001 AC-2: a 200-character removed line still exits 2"
assert_equals "$L200" "$RATCHET_LINE" "req-001 AC-2: a 200-character line prints whole with no marker"

ratchet_removed short "short criterion"
assert_equals "short criterion" "$RATCHET_LINE" "req-001 AC-2: a short line prints unchanged"

ratchet_removed astral "$ASTRAL"
assert_equals "${ASTRAL_CAP}${MARK}" "$RATCHET_LINE" "req-001: the cut counts code points and keeps the astral character whole"

echo ""
echo "=== 0000198 req-002 cap the consistency finding ==="

check_finding emptycell "$LONG" ""
assert_equals "1" "$CHECK_RC" "req-002 AC-1: a long label with an empty Requirement cell exits 1"
assert_equals "${L200}${MARK}" "$CHECK_LABEL" "req-002 AC-1: the finding holds 200 characters plus the cut marker"
assert_contains "has an empty Requirement cell" "$CHECK_OUT" "req-002 AC-1: the finding keeps its reason"

check_finding dangling "$LONG" "REQ-009"
assert_equals "${L200}${MARK}" "$CHECK_LABEL" "req-002 AC-1: the dangling reference finding caps the label too"
assert_contains "names REQ-009" "$CHECK_OUT" "req-002 AC-1: the dangling finding keeps its reason"

check_finding exact "$L200" ""
assert_equals "$L200" "$CHECK_LABEL" "req-002 AC-2: a 200-character label prints whole with no marker"

check_finding short "short step" "REQ-009"
assert_equals "short step" "$CHECK_LABEL" "req-002 AC-2: a short label prints unchanged"
assert_equals "1" "$CHECK_RC" "req-002 AC-2: the dangling reference exits 1"

check_finding astral "$ASTRAL" ""
assert_equals "${ASTRAL_CAP}${MARK}" "$CHECK_LABEL" "req-002: the cut counts code points and keeps the astral character whole"

echo ""
echo "=== 0000198 parity: both programs cut the same line the same way ==="

ratchet_removed parity "$LONG"
check_finding parity "$LONG" ""
assert_equals "$RATCHET_LINE" "$CHECK_LABEL" "parity: the ratchet and the check print the same capped text"

print_summary
