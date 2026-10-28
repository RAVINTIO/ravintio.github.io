#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-007: product
# name RAVINTIO Zero.
#
# product.yml and ravintio-zero/component.yml set name "RAVINTIO Zero" and
# keep id "ravintio-zero". README.md names "RAVINTIO Framework" only as the
# separate sibling product (0000160 ADR-001).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ROOT="$SCRIPT_DIR/../.."
PRODUCT="$ROOT/product.yml"
COMPONENT="$ROOT/ravintio-zero/component.yml"
README="$ROOT/README.md"

# First top-level scalar: key at column 0, quotes stripped.
field() {
  grep -m1 -E "^$1:" "$2" | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]+#.*$//; s/^\"//; s/\"$//"
}
has() { grep -qF -- "$1" "$2" && echo yes || echo no; }

echo ""
echo "=== req-007 (a): name fields ==="

assert_equals "RAVINTIO Zero" "$(field name "$PRODUCT")" \
  "req-007 (a): product.yml name is RAVINTIO Zero"
assert_equals "RAVINTIO Zero" "$(field name "$COMPONENT")" \
  "req-007 (a): component.yml name is RAVINTIO Zero"

echo ""
echo "=== req-007 (a): ids unchanged ==="

assert_equals "ravintio-zero" "$(field id "$PRODUCT")" \
  "req-007 (a): product.yml id is ravintio-zero"
assert_equals "ravintio-zero" "$(field id "$COMPONENT")" \
  "req-007 (a): component.yml id is ravintio-zero"

echo ""
echo "=== req-007 (b): no RAVINTIO Framework name ==="

assert_equals "" "$(grep 'RAVINTIO Framework' "$README" | grep -v 'distinct from RAVINTIO Framework' || true)" \
  "req-007 (b): README.md names RAVINTIO Framework only as the sibling product"
assert_equals "no" "$(has 'RAVINTIO Framework' "$PRODUCT")" \
  "req-007 (b): product.yml holds no RAVINTIO Framework string"
assert_equals "no" "$(has 'RAVINTIO Framework' "$COMPONENT")" \
  "req-007 (b): component.yml holds no RAVINTIO Framework string"

print_summary
