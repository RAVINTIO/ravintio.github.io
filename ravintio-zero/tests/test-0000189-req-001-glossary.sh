#!/usr/bin/env bash
# 0000189 req-001: glossary
# project-operations.md holds one glossary section that defines roadmap and
# roadmap initiative and lists the five states. roadmap-standards.md links to it.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

OPS="$ZERO_DIR/project-operations.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"
HEADING="## Roadmap and initiative glossary"
ANCHOR="roadmap-and-initiative-glossary"

echo ""
echo "=== 0000189 req-001 glossary ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

sec="$(awk -v h="$HEADING" '$0==h{f=1;next} /^## /{f=0} f' "$OPS")"
has() { printf '%s\n' "$sec" | grep -qF -- "$1"; }

ok=1
if [ -n "$sec" ] && has '**Roadmap:**' && has '**Roadmap initiative:**' \
  && has 'long-term plan for the product' && has 'plan/roadmap/' \
  && has 'a string of feature builds' && has 'merges to `main` in one PR'; then ok=0; fi
check "req-001 AC-1: glossary defines Roadmap and Roadmap initiative" "$ok"

ok=1
if [ -n "$sec" ] && has '**Initiative states:**'; then
  ok=0
  for pair in 'proposed:Drafting' 'charted:I-A Chart' 'active:I-B Activate' 'delivered:I-E Delivery' 'blocked:exception stop'; do
    st="${pair%%:*}"; sg="${pair#*:}"
    printf '%s\n' "$sec" | grep -F -- "$st" | grep -qF -- "$sg" || ok=1
  done
fi
check "req-001 AC-2: glossary lists the five states with the stage that sets each" "$ok"

ok=1
if [ "$(grep -c -F -- "$HEADING" "$OPS")" = "1" ] \
  && grep -qF -- "](../project-operations.md#$ANCHOR)" "$STD"; then ok=0; fi
check "req-001 AC-3: roadmap-standards.md links to the glossary anchor and the anchor exists" "$ok"

print_summary
