#!/usr/bin/env bash
# Tests for feature 0000160-ravintio-rebrand, req-004: brand prose.
#
# (a) setup.ps1 keeps its BOM and its one existing mojibake sequence. When a
#     main ref holds the pre-rename file, the mojibake line differs from it
#     only by the brand token.
# (b) docs/about.md, product.yml, and component.yml record one version. Once
#     ship has archived the run, that version is 0.12.0 or later.
# The brand guard test (req-006) covers the prose itself.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/version.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$ZERO_DIR/.." && pwd)"
PS1="$ZERO_DIR/setup.ps1"
MOJI=$'\xc3\x83\xc2\xa2'

echo "=== (a) setup.ps1 bytes ==="
assert_equals "efbbbf" "$(head -c3 "$PS1" | od -An -tx1 | tr -d ' \n')" "setup.ps1 keeps its UTF-8 BOM"
assert_equals "1" "$(grep -c "$MOJI" "$PS1" || true)" "setup.ps1 keeps one mojibake line"
OLD="$(git -C "$ROOT_DIR" ls-tree --name-only main 2>/dev/null | grep -E '^[a-z]+-zero$' | grep -v '^ravintio-zero$' | head -1)"
if [ -n "$OLD" ]; then
  BEFORE="$(git -C "$ROOT_DIR" show "main:$OLD/setup.ps1" | grep "$MOJI")"
  AFTER="$(grep "$MOJI" "$PS1")"
  # Rewrite the brand token in the old line, then compare whole lines.
  OLD_CAP="$(printf '%s' "${OLD%-zero}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
  assert_equals "${BEFORE//$OLD_CAP/RAVINTIO}" "$AFTER" "the mojibake line differs from main only by the brand"
else
  echo "  SKIP: main holds no pre-rename pack folder"
fi

echo "=== (b) version ==="
V_ABOUT="$(sed -n 's/^version: *"\(.*\)"/\1/p' "$ROOT_DIR/docs/about.md" | head -1)"
V_PRODUCT="$(sed -n 's/^version: *"\(.*\)"/\1/p' "$ROOT_DIR/product.yml" | head -1)"
V_COMPONENT="$(sed -n 's/^version: *"\(.*\)"/\1/p' "$ZERO_DIR/component.yml" | head -1)"
assert_equals "$V_ABOUT" "$V_PRODUCT" "product.yml matches docs/about.md"
assert_equals "$V_ABOUT" "$V_COMPONENT" "component.yml matches docs/about.md"
if [ -f "$ROOT_DIR/plan/current/design.md" ]; then
  echo "  SKIP: a run is in flight, so ship has not set the version yet"
else
  assert_equals "yes" "$(version_at_least_0_12 "$V_ABOUT")" "the version is 0.12.0 or later"
fi

print_summary
