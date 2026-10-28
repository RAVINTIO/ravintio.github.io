#!/usr/bin/env bash
# Tests for feature 0000202-improvement-loops, req-002: the workflow governance
# standard lists the Improve marker and the living docs name the improvement loop.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD="$ZERO_DIR/standards/workflow-governance-standards.md"
MANIFEST="$ZERO_DIR/component.yml"
ARCH="$ZERO_DIR/../docs/architecture-overview.md"
PIPE="$ZERO_DIR/pipeline-reference.md"

MARKERS=$(awk '/^## Marker lines/{f=1;next} /^## /{f=0} f' "$STD")

echo ""
echo "=== req-002 AC-1: the standard lists both marker forms ==="
assert_contains "Improve: REQ-{nnn}: cycle {n}: {finding}: {change}: suite {pass | fail, reverted}" "$MARKERS" "req-002 AC-1: the change form is listed"
assert_contains "Improve: REQ-{nnn}: cycle {n}: no change worth making" "$MARKERS" "req-002 AC-1: the early stop form is listed"

echo ""
echo "=== req-002 AC-2: the standard says the script ignores the marker ==="
assert_contains "does not count" "$(cat "$STD")" "req-002 AC-2: the standard says the script does not count the marker"
assert_contains '`workflow-metrics.mjs` does not count' "$(tr '\n' ' ' < "$STD")" "req-002 AC-2: the note names the script"

echo ""
echo "=== req-002 AC-3: the living docs name the loop ==="
assert_contains "improvement loop" "$(cat "$MANIFEST")" "req-002 AC-3: component.yml names the improvement loop"
assert_contains "improvement loop" "$(cat "$ARCH")" "req-002 AC-3: the architecture overview names the improvement loop"
assert_contains "improvement loop" "$(cat "$PIPE")" "req-002 AC-3: the pipeline reference names the improvement loop"

print_summary
