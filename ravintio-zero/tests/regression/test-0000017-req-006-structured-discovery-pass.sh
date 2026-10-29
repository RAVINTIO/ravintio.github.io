#!/usr/bin/env bash
# Tests for feature 0000017 req-006: structured P0 discovery pass for all
# adoption modes, writing to plan/current/discovery.md (ADR-004).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORCHESTRATOR="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
DISCOVERY_TPL="$ZERO_DIR/templates/discovery.template.md"
DESIGN_TPL="$ZERO_DIR/templates/design.template.md"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
grep_has()    { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

# ── AC-1: discovery pass defined for every adoption mode ─────────────────────

echo ""
echo "=== req-006: discovery pass defined for all 4 adoption modes ==="

assert_equals "yes" "$(grep_has "### Adoption Modes" "$ORCHESTRATOR")" \
  "req-006: orchestrator has the adoption-modes discovery section"

# the adoption-modes section covers all four modes and the discovery.md lifecycle
MODE_SECTION=$(sed -n '/### Adoption Modes/,/#### Retrofit Scan/p' "$ORCHESTRATOR")
for mode in Greenfield "Standard Iterative" Retrofit "External Anchor"; do
  assert_contains "$mode" "$MODE_SECTION" \
    "req-006: $mode mode present in the adoption table"
done
assert_contains "discovery.md" "$MODE_SECTION" \
  "req-006: adoption section states the discovery.md lifecycle"
assert_contains "fresh every run" "$MODE_SECTION" \
  "req-006: discovery.md is fresh every run"

# the old Greenfield "No discovery pass needed" line is gone
assert_equals "no" "$(grep_has "No discovery pass needed" "$ORCHESTRATOR")" \
  "req-006: Greenfield no-discovery exemption removed"

# ── AC-1: discovery runs before coaching (Phase 0 Start Actions step) ────────

echo ""
echo "=== req-006: Phase 0 Start Actions wiring ==="

assert_equals "yes" "$(grep_has "Write \`discovery.md\`" "$ORCHESTRATOR")" \
  "req-006: Start Actions has a Write discovery.md step"
assert_equals "yes" "$(grep_has "before the first coaching question" "$ORCHESTRATOR")" \
  "req-006: discovery.md written before the first coaching question"

# ── AC-2: shared header content specified ────────────────────────────────────

echo ""
echo "=== req-006: shared header ==="

HEADER_LINE=$(grep "shared header" "$ORCHESTRATOR")
assert_contains "adoption-mode result" "$HEADER_LINE" \
  "req-006: header includes adoption-mode signal"
assert_contains "git pre-flight" "$HEADER_LINE" \
  "req-006: header includes git pre-flight"
assert_contains "skills-inbox scan" "$HEADER_LINE" \
  "req-006: header includes skills-inbox scan"

# ── AC-3: fresh-each-run / archived-at-P7 lifecycle ──────────────────────────

echo ""
echo "=== req-006: lifecycle ==="

assert_equals "yes" "$(grep_has "fresh every run" "$ORCHESTRATOR")" \
  "req-006: fresh-each-run lifecycle documented"
LIFECYCLE_LINE=$(grep "fresh every run" "$ORCHESTRATOR")
assert_contains "archived" "$LIFECYCLE_LINE" \
  "req-006: archived-at-P7 documented"

# ── AC-4: partial-failure inline note, never a hard block ────────────────────

echo ""
echo "=== req-006: partial failure ==="

assert_equals "yes" "$(grep_has "could not be read" "$ORCHESTRATOR")" \
  "req-006: partial failure states section could not be determined"
assert_equals "yes" "$(grep_has "never a hard block" "$ORCHESTRATOR")" \
  "req-006: partial failure never hard-blocks coaching"

# ── AC-5: resume trusts existing file; missing/incomplete regenerated ────────

echo ""
echo "=== req-006: cross-session ==="

assert_equals "yes" "$(grep_has "trust it as-is" "$ORCHESTRATOR")" \
  "req-006: resume trusts existing discovery.md"
assert_equals "yes" "$(grep_has "regenerate it fresh" "$ORCHESTRATOR")" \
  "req-006: missing/incomplete discovery.md regenerated, not patched"
RESUME_SECTION=$(sed -n '/## Resume Detection/,/^---$/p' "$ORCHESTRATOR")$'\n'$(cat "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md")
assert_contains "discovery.md" "$RESUME_SECTION" \
  "req-006: Resume Detection covers discovery.md"

# ── templates: discovery.template.md exists, design.template.md points at it ─

echo ""
echo "=== req-006: templates ==="

assert_equals "yes" "$(file_exists "$DISCOVERY_TPL")" \
  "req-006: discovery.template.md exists"
for section in "Greenfield" "Standard Iterative" "Retrofit" "External Anchor" "Header (all modes)"; do
  assert_equals "yes" "$(grep_has "$section" "$DISCOVERY_TPL")" \
    "req-006: discovery template has $section section"
done
assert_equals "yes" "$(grep_has "discovery.md" "$DESIGN_TPL")" \
  "req-006: design.template.md references discovery.md"
assert_equals "yes" "$(grep_has "discovery.template.md" "$ORCHESTRATOR")" \
  "req-006: orchestrator JIT index references discovery.template.md"

print_summary
