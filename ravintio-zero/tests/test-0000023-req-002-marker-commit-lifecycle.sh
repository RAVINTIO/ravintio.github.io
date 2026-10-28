#!/usr/bin/env bash
# Tests for feature 0000023-pipeline-fixes, req-002:
# marker commit lifecycle.
#
# Covers: session markers (plan/.orchestrator-active, plan/.orchestrator-ack,
# plan/.run-mode) must be committed at the point they are written (discovery),
# and the ship phase must clear them, stage the deletions, and confirm with
# git ls-files that none remain tracked. Since 0000042 req-001,
# plan/.run-mode holds `gated` or `autonomous`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ORCHESTRATOR="$(orch_combined "$SCRIPT_DIR/../skills/ravintio-orchestrator")"
SHIP="$SCRIPT_DIR/../skills/ravintio-ship/SKILL.md"

for f in "$ORCHESTRATOR" "$SHIP"; do
  if [ ! -f "$f" ]; then
    echo "  FAIL: $f not found"
    ((FAIL++)) || true
    print_summary
  fi
done

ORCH_CONTENT=$(cat "$ORCHESTRATOR" "$(dirname "$ORCHESTRATOR")/references/orchestrator-resume-detection.md")
SHIP_CONTENT=$(cat "$SHIP")

echo ""
echo "=== req-002: creation-side commit instructions (orchestrator discovery) ==="

assert_contains "Write the sentinel" "$ORCH_CONTENT" \
  "req-002: the write-the-sentinel start action is present"
assert_contains "Include in the discovery commit." "$ORCH_CONTENT" \
  "req-002: .orchestrator-active is committed at the point it is written"

assert_contains "Strict-mode ack" "$ORCH_CONTENT" \
  "req-002: the strict-mode ack start action is present"
assert_contains "include it in the discovery commit" "$ORCH_CONTENT" \
  "req-002: .orchestrator-ack is committed at the point it is written"

assert_contains 'write `plan/.run-mode`' "$ORCH_CONTENT" \
  "req-002: the run-mode marker is written at design confirmation"
assert_contains "Include it in the discovery commit." "$ORCH_CONTENT" \
  "req-002: .run-mode is committed at the point it is written"
assert_contains '`gated` or `autonomous`' "$ORCH_CONTENT" \
  "req-002: the run-mode marker holds gated or autonomous"

echo ""
echo "=== req-002: deletion-side clearing (ship phase) ==="

SENTINEL_STEP=$(printf '%s\n' "$SHIP_CONTENT" | sed -n '/^### Step 8: Clear sentinels/,/^### Step 9/p')

assert_contains 'Delete `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode`' \
  "$SENTINEL_STEP" "req-002: ship clears all three markers"
assert_contains "Stage the deletions and commit." "$SENTINEL_STEP" \
  "req-002: ship stages and commits the marker deletions"

echo ""
echo "=== req-002: tracked-marker backstop check ==="

assert_contains 'git ls-files' "$SENTINEL_STEP" \
  "req-002: ship confirms with git ls-files that no marker remains tracked"

echo ""
echo "=== req-002: interrupted-ship recovery ==="

assert_contains "Interrupted-ship cleanup" "$ORCH_CONTENT" \
  "req-002: the orchestrator detects a ship interrupted between archive and sentinel cleanup"

print_summary
