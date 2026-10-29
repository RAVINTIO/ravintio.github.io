#!/usr/bin/env bash
# Tests for feature 0000248-ship-merge-and-wall-clocks, req-002: the build log
# check fails a blank or wrong phase time, and ship runs it before Archive.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
CHECK="$ZERO_DIR/scripts/build-log-check.mjs"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
TEMPLATE="$ZERO_DIR/templates/build-log.template.md"

TMP=$(mktemp -d -t ravintio_0000248_req002_XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# block <n> <name> <start> <end> <wall>: one phase block.
block() {
  printf '### P%s: %s\n\n| Field | Value |\n|-------|-------|\n| Start | `%s` |\n| End | `%s` |\n| Wall clock | `%s` |\n| Model tier | primary |\n\n' "$1" "$2" "$3" "$4" "$5"
}
# summary <total>: the Summary table.
summary() {
  printf '## Summary\n\n| Metric | Value |\n|--------|-------|\n| Total phases completed | `5` |\n| Total wall clock | `%s` |\n' "$1"
}
# complete_log <file>: five filled blocks and a total.
complete_log() {
  {
    printf '# Build Log\n\n## Phase Log\n\n'
    block 0 Discovery 2026-10-28T12:00:00Z 2026-10-28T12:03:00Z 3
    block 1 Plan 2026-10-28T12:03:00Z 2026-10-28T12:10:00Z 7
    block 2 Implement 2026-10-28T12:10:00Z 2026-10-28T12:30:00Z 20
    block 3 "Validate and Accept" 2026-10-28T12:30:00Z 2026-10-28T12:40:00Z 10
    block 4 Ship 2026-10-28T12:40:00Z 2026-10-28T12:45:00Z 5
    summary 45
  } > "$1"
}
# run_check <file>: sets OUT and CODE.
run_check() {
  OUT=$(node "$CHECK" "$1" 2>&1)
  CODE=$?
}

echo ""
echo "=== req-002 AC-1: blank and wrong times fail ==="
complete_log "$TMP/ok.md"
run_check "$TMP/ok.md"
assert_equals "0" "$CODE" "req-002 AC-3: a complete log passes"
assert_contains "build-log-check: clean" "$OUT" "req-002 AC-3: a complete log prints clean"

sed 's/^| End | `2026-10-28T12:10:00Z` |/| End | `` |/' "$TMP/ok.md" > "$TMP/blank-end.md"
run_check "$TMP/blank-end.md"
assert_equals "1" "$CODE" "req-002 AC-1: a blank End fails"
assert_contains "P1" "$OUT" "req-002 AC-1: a blank End names the phase"

sed '/^### P2/,/^### P3/ s/^| Wall clock | `20` |/| Wall clock | |/' "$TMP/ok.md" > "$TMP/blank-wall.md"
run_check "$TMP/blank-wall.md"
assert_equals "1" "$CODE" "req-002 AC-1: a blank Wall clock fails"
assert_contains "P2" "$OUT" "req-002 AC-1: a blank Wall clock names the phase"

{
  printf '## Phase Log\n\n'
  block 0 Discovery 2026-10-27T12:09:04Z 2026-10-27T12:11:27Z 0
  block 1 Plan 2026-10-27T12:12:00Z 2026-10-27T12:20:00Z 8
  block 2 Implement 2026-10-27T12:20:00Z 2026-10-27T12:30:00Z 10
  block 3 "Validate and Accept" 2026-10-27T12:30:00Z 2026-10-27T12:40:00Z 10
  block 4 Ship 2026-10-27T12:40:00Z 2026-10-27T12:45:00Z 5
  summary 36
} > "$TMP/zero-wall.md"
run_check "$TMP/zero-wall.md"
assert_equals "1" "$CODE" "req-002 AC-1: P0 from 12:09:04Z to 12:11:27Z with Wall clock 0 fails"
assert_contains "P0" "$OUT" "req-002 AC-1: the wrong wall clock names the phase"

sed 's/^| Wall clock | `3` |/| Wall clock | `4` |/' "$TMP/ok.md" > "$TMP/within-one.md"
run_check "$TMP/within-one.md"
assert_equals "0" "$CODE" "req-002 AC-1: a Wall clock one minute off passes"

sed 's/^| Start | `2026-10-28T12:00:00Z` |/| Start | `yesterday` |/' "$TMP/ok.md" > "$TMP/bad-time.md"
run_check "$TMP/bad-time.md"
assert_equals "1" "$CODE" "req-002 AC-1: an unreadable timestamp fails"

echo ""
echo "=== req-002 AC-2: missing blocks and the total ==="
awk '/^### P2/{skip=1} /^### P3/{skip=0} !skip' "$TMP/ok.md" > "$TMP/no-p2.md"
run_check "$TMP/no-p2.md"
assert_equals "1" "$CODE" "req-002 AC-2: a missing P2 block fails"
assert_contains "P2" "$OUT" "req-002 AC-2: a missing block names the phase"

{ cat "$TMP/no-p2.md"; printf '\n- Skipped: P2 (human request)\n'; } > "$TMP/skipped-p2.md"
run_check "$TMP/skipped-p2.md"
assert_equals "0" "$CODE" "req-002 AC-2: a Skipped: P2 line excuses the missing block"

sed 's/^| Total wall clock | `45` |/| Total wall clock | `not recorded` |/' "$TMP/ok.md" > "$TMP/no-total.md"
run_check "$TMP/no-total.md"
assert_equals "1" "$CODE" "req-002 AC-2: a Total wall clock of not recorded fails"
assert_contains "Total wall clock" "$OUT" "req-002 AC-2: the finding names the total"

sed 's/^| Total wall clock | `45` |/| Total wall clock | |/' "$TMP/ok.md" > "$TMP/blank-total.md"
run_check "$TMP/blank-total.md"
assert_equals "1" "$CODE" "req-002 AC-2: a blank Total wall clock fails"

run_check "$TMP/missing-file.md"
assert_equals "1" "$CODE" "req-002 AC-2: an unreadable file fails"

echo ""
echo "=== req-002 AC-3: ship runs the check before Archive ==="
STEP3=$(awk '/^### Step 3/{f=1;next} /^### /{f=0} f' "$SHIP")
assert_contains "node ravintio-zero/scripts/build-log-check.mjs plan/current/build-log.md" "$STEP3" "req-002 AC-3: Step 3 runs the script"
assert_contains "Skipped: P" "$STEP3" "req-002 AC-3: Step 3 names the skipped-phase line"
assert_contains "before Step 4" "$STEP3" "req-002 AC-3: Step 3 runs the check before Archive"
assert_contains "Stop" "$STEP3" "req-002 AC-3: Step 3 stops on a failure"
assert_contains "Skipped: P" "$(cat "$TEMPLATE")" "req-002 AC-3: the template names the skipped-phase line"

print_summary
