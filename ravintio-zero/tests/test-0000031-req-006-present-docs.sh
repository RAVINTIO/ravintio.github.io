#!/usr/bin/env bash
# Feature 0000031 req-006: living docs describe the present only.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) no narrative history in living docs ==="
# Exempt: decisions-index.md (change record), about.md feature field.
HITS=$(grep -rl "Removed at 0000030\|introduced in feature\|Left as-is by decision" \
  "$REPO/docs" "$REPO/README.md" "$ZERO_DIR"/*.md "$ZERO_DIR/standards" 2>/dev/null \
  | grep -v "decisions-index.md" | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "living docs free of narrative history"

echo "=== (b) folded backlog fixes ==="
assert_equals "0" "$(grep -ci "cursor" "$ZERO_DIR/tests/README.md" || true)" "tests README has no Cursor"
assert_equals "0" "$(grep -c "plan/{feature-id}/" "$REPO/plan/feature-structure.md" 2>/dev/null || true)" "feature-structure has no per-feature folder layout"
assert_equals "no" "$([ -f "$REPO/plan/library-standards-plan.md" ] && echo yes || echo no)" "spent plan doc deleted"
for pat in ".cursor/" ".gemini/" ".windsurf/" ".clinerules/" "GEMINI.md"; do
  assert_equals "0" "$(grep -cF "$pat" "$ZERO_DIR/.gitignore" || true)" "pack .gitignore free of $pat"
  assert_equals "0" "$(grep -cF "$pat" "$REPO/.gitignore" || true)" "root .gitignore free of $pat"
done

echo "=== (c) never-run stale setup tests deleted ==="
assert_equals "no" "$([ -f "$ZERO_DIR/tests/test_setup.sh" ] && echo yes || echo no)" "test_setup.sh deleted"
assert_equals "no" "$([ -f "$ZERO_DIR/tests/test_setup.ps1" ] && echo yes || echo no)" "test_setup.ps1 deleted"

print_summary
