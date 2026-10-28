#!/usr/bin/env bash
# Feature 0000031 req-002: one route. Change Pipeline, Fast Path, Retrofit gone.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) exactly one workflow file ==="
COUNT=$(ls "$ZERO_DIR/workflows/"*.md 2>/dev/null | wc -l | tr -d ' ')
assert_equals "1" "$COUNT" "one file in workflows/"
assert_equals "yes" "$([ -f "$ZERO_DIR/workflows/feature-pipeline.md" ] && echo yes || echo no)" "feature-pipeline.md present"

echo "=== (b) change-agent skill gone ==="
assert_equals "no" "$([ -d "$ZERO_DIR/skills/ravintio-change-agent" ] && echo yes || echo no)" "change-agent absent"

echo "=== (c) CI has no fast-path exemption ==="
assert_equals "0" "$(grep -c "fast-path" "$REPO/.github/workflows/ravintio.yml" || true)" "no fast-path branch in repo CI"
assert_equals "0" "$(grep -c "fast-path" "$ZERO_DIR/hooks/ravintio.yml" || true)" "no fast-path branch in shipped CI copy"

echo "=== (d) no live route references ==="
HITS=$(grep -rli "change-pipeline\|fast-path" "$ZERO_DIR/skills" "$ZERO_DIR/workflows" "$ZERO_DIR/standards" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "no change-pipeline/fast-path refs in skills, workflows, standards"

print_summary
