#!/usr/bin/env bash
# 0000170 req-004: story-map-consistency-rule
# consistency-check.mjs flags gaps between plan/current/story-map.md and the requirement files.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

CHECK="$ZERO_DIR/scripts/consistency-check.mjs"
TMP="$(mktemp -d -t ravintio_0000170_req004_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Build a fixture with one valid requirement (REQ-001, US-001) and no story map.
make_fixture() {
  local d="$TMP/$1/plan/current"
  mkdir -p "$d/requirements"
  printf '# Design\n## Scope\n- In: things\n' > "$d/design.md"
  printf '# Requirement: REQ-001 - Demo\n**Source:** US-001\n## Acceptance Criteria\n- [ ] AC-1: One\n  - Given a\n  - When b\n  - Then c\n' > "$d/requirements/req-001-demo.md"
  echo "$d"
}

echo ""
echo "=== 0000170 req-004 story-map-consistency-rule ==="

D=$(make_fixture nomap)
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-004 AC-1: missing story map exits 1"
assert_contains "story-map.md: missing" "$OUT" "req-004 AC-1: stdout names story-map.md as missing"

D=$(make_fixture gaps)
printf '# Requirement: REQ-002 - Other\n**Source:** US-007\n## Acceptance Criteria\n- [ ] AC-1: One\n  - Given a\n  - When b\n  - Then c\n' > "$D/requirements/req-002-other.md"
cat > "$D/story-map.md" <<'MD'
## Backbone
| Activity | Step | Story | Requirement |
|----------|------|-------|-------------|
| A | empty cell step | US-001 | |
| A | dangling step | US-002 | REQ-009 |
| A | good step | US-003 | REQ-001 |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-004 AC-2: row and story gaps exit 1"
assert_contains "empty cell step" "$OUT" "req-004 AC-2: empty Requirement cell flagged"
assert_contains "REQ-009" "$OUT" "req-004 AC-2: REQ with no file flagged"
assert_contains "US-007" "$OUT" "req-004 AC-2: Source story absent from map flagged"
N=$(printf '%s\n' "$OUT" | grep -c '✖')
assert_equals "3" "$N" "req-004 AC-2: one finding for each of the three defects"

D=$(make_fixture clean)
cat > "$D/story-map.md" <<'MD'
## Backbone
| Activity | Step | Story | Requirement |
|----------|------|-------|-------------|
| A | covered | US-001 | REQ-001 |
| A | skipped | none | gap: out of scope |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "0" "$RC" "req-004 AC-3: clean map exits 0"
case "$OUT" in *story-map*) echo "  FAIL: req-004 AC-3: clean fixture has story-map finding"; FAIL=$((FAIL+1));; *) echo "  PASS: req-004 AC-3: clean fixture has no story-map finding"; PASS=$((PASS+1));; esac

E="$TMP/empty/plan/current"; mkdir -p "$E/requirements"
printf '# Design\n## Scope\n- In: things\n' > "$E/design.md"
OUT=$(node "$CHECK" "$E" 2>&1); RC=$?
assert_equals "0" "$RC" "req-004 AC-3: no requirement files exits 0"
case "$OUT" in *story-map*) echo "  FAIL: req-004 AC-3: empty fixture has story-map finding"; FAIL=$((FAIL+1));; *) echo "  PASS: req-004 AC-3: empty fixture has no story-map finding"; PASS=$((PASS+1));; esac

print_summary
