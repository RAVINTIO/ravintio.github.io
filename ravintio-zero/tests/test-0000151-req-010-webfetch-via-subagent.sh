#!/usr/bin/env bash
# Test: 0000151 req-010 webfetch-via-subagent
# The dispatch standard routes a WebFetch of a full reference page through a
# sonnet or haiku subagent that returns only the extract.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$ZERO_DIR/.." && pwd)"
STD="$ZERO_DIR/standards/agent-dispatch-standards.md"

echo "=== (a) WebFetch rule ==="
SECTION=$(sed -n '/^## WebFetch of a reference page/,/^---/p' "$STD")
assert_equals "yes" "$([ -n "$SECTION" ] && echo yes || echo no)" "WebFetch section exists"
assert_contains 'WebFetch' "$SECTION" "section names WebFetch"
assert_contains 'subagent' "$SECTION" "section names a subagent"
assert_contains 'sonnet' "$SECTION" "section names sonnet"
assert_contains 'haiku' "$SECTION" "section names haiku"
assert_contains 'extract' "$SECTION" "section names the returned extract"
assert_contains 'passes `model`' "$SECTION" "section states the dispatch passes model"

echo "=== (b) installed copies ==="
DIFFS=0
for f in "$ROOT_DIR"/.claude/skills/*/references/agent-dispatch-standards.md; do
  [ -e "$f" ] || continue
  cmp -s "$f" "$STD" || DIFFS=$((DIFFS + 1))
done
assert_equals "0" "$DIFFS" "installed copies match the source"

print_summary
