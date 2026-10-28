#!/usr/bin/env bash
# Tests for feature 0000009: rail tightening
# Covers REQ-001 through REQ-012 (design.md numbering).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SETUP_SH="$ZERO_DIR/setup.sh"
SETUP_PS1="$ZERO_DIR/setup.ps1"
ORCHESTRATOR="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
ORCH_RESUME_REF="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md"
SHIP_AGENT="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
GATE_WRITE="$ZERO_DIR/hooks/enforcement/gate-write.mjs"
AUTO_TRIGGER="$ZERO_DIR/hooks/enforcement/auto-trigger-orchestrator.mjs"
PRESENCE_CHECK="$ZERO_DIR/hooks/enforcement/check-orchestrator-presence.mjs"
DESIGN_TPL="$ZERO_DIR/templates/design.template.md"
PAUSE_TPL="$ZERO_DIR/templates/pause.template.md"
STANDARD_BOOT="$ZERO_DIR/templates/standard-boot.md"
GETTING_STARTED="$ZERO_DIR/getting-started.md"
PIPELINE_REFERENCE="$ZERO_DIR/pipeline-reference.md"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
grep_has()    { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }
grep_str()    { grep "$1" "$2" 2>/dev/null || true; }

# ── REQ-001: .skips path ─────────────────────────────────────────────────────

echo ""
echo "=== REQ-001: .skips path corrected to plan/current/.skips ==="

assert_contains "plan/current/.skips" \
  "$(grep_str "\.skips" "$ORCHESTRATOR")$(grep_str "\.skips" "$ORCH_RESUME_REF")" \
  "REQ-001: orchestrator references plan/current/.skips"

# ── REQ-002: auto-trigger-orchestrator hook ───────────────────────────────────

echo ""
echo "=== REQ-002: auto-trigger-orchestrator hook ==="

assert_equals "yes" "$(file_exists "$AUTO_TRIGGER")" \
  "REQ-002: auto-trigger-orchestrator.mjs exists"

assert_equals "yes" "$(grep_has "ravintio-zero" "$AUTO_TRIGGER")" \
  "REQ-002: hook checks for ravintio-zero presence"

assert_equals "yes" "$(grep_has "orchestrator-active" "$AUTO_TRIGGER")" \
  "REQ-002: hook checks sentinel absence"

assert_equals "yes" "$(grep_has "auto-trigger-orchestrator" "$SETUP_SH")" \
  "REQ-002: setup.sh wires auto-trigger-orchestrator"

assert_equals "yes" "$(grep_has "RAVINTIO_TRIGGER" "$SETUP_SH")" \
  "REQ-002: setup.sh passes trigger cmd to UserPromptSubmit wiring"

assert_equals "yes" "$(grep_has "auto-trigger-orchestrator" "$ZERO_DIR/standards/hook-enforcement.md")" \
  "REQ-002: hook-enforcement.md documents auto-trigger hook"

assert_equals "yes" "$(grep_has "ravintio-orchestrator skill" "$STANDARD_BOOT")" \
  "REQ-002: standard-boot.md has fallback instruction"

# ── REQ-003: Skill Map in design template ─────────────────────────────────────

echo ""
echo "=== REQ-003: Skill Map in design.template.md ==="

assert_equals "yes" "$(grep_has "## Skill Map" "$DESIGN_TPL")" \
  "REQ-003b: design.template.md has Skill Map section"

assert_equals "yes" "$(grep_has "Skill Map" "$ORCHESTRATOR")" \
  "REQ-003b: orchestrator produces Skill Map in P0"

assert_equals "yes" "$(grep_has "subagent decomposition" "$ORCHESTRATOR")" \
  "REQ-003a: orchestrator directs subagent decomposition"

# ── REQ-004: open-source skill library ───────────────────────────────────────

echo ""
echo "=== REQ-005: pause/resume via pause.md ==="

assert_equals "yes" "$(file_exists "$PAUSE_TPL")" \
  "REQ-005: pause.template.md exists"

assert_equals "yes" "$(grep_has "active_task" "$PAUSE_TPL")" \
  "REQ-005: pause template has active_task field"

assert_equals "yes" "$(grep_has "Pause Command" "$ORCHESTRATOR")" \
  "REQ-005: orchestrator has Pause Command section"

assert_equals "yes" "$(grep_has "pause\.md" "$GATE_WRITE")" \
  "REQ-005: gate-write permits pause.md"

assert_equals "yes" "$(grep_has "isAlwaysPermittedBasename" "$GATE_WRITE")" \
  "REQ-005: gate-write bypasses sentinel for always-permitted basenames"

# ── REQ-006/REQ-007: setup.sh override instructions parity ───────────────────

echo ""
echo "=== REQ-006/REQ-007: setup.sh override instructions parity with setup.ps1 ==="

assert_equals "yes" "$(grep_has "^append_override_instructions" "$SETUP_SH")" \
  "REQ-006: setup.sh defines append_override_instructions function"

assert_equals "yes" "$(grep_has "ravintio-overrides/instructions" "$SETUP_SH")" \
  "REQ-007: setup.sh references ravintio-overrides/instructions"

assert_equals "yes" "$(grep_has 'append_override_instructions "\$TOOL_BOOT_FILE"' "$SETUP_SH")" \
  "REQ-007: setup.sh calls append_override_instructions in setup_tool"

assert_equals "yes" "$(grep_has "Append-OverrideInstructions" "$SETUP_PS1")" \
  "REQ-006: setup.ps1 has Append-OverrideInstructions (pre-existing)"

# ── REQ-008: setup.sh copy_capability_skills parity ──────────────────────────

echo ""
echo "=== REQ-008: setup.sh Copy-CapabilitySkills parity ==="

assert_equals "yes" "$(grep_has "^copy_capability_skills" "$SETUP_SH")" \
  "REQ-008: setup.sh defines copy_capability_skills function"

assert_equals "yes" "$(grep_has "ravintio-overrides/capability-skills" "$SETUP_SH")" \
  "REQ-008: setup.sh references ravintio-overrides/capability-skills"

assert_equals "yes" "$(grep_has 'copy_capability_skills "\$skills_dir"' "$SETUP_SH")" \
  "REQ-008: setup.sh calls copy_capability_skills in setup_tool"

assert_equals "yes" "$(grep_has "Copy-CapabilitySkills" "$SETUP_PS1")" \
  "REQ-008: setup.ps1 has Copy-CapabilitySkills (pre-existing)"

# ── REQ-009: setup.ps1 Tier 1 adapter support ────────────────────────────────

echo ""
echo "=== REQ-012: gate-write.mjs Windows path normalisation ==="

assert_equals "yes" "$(grep_has "function norm\|const norm" "$GATE_WRITE")" \
  "REQ-012: gate-write.mjs defines norm() helper"

assert_equals "yes" "$(grep_has "cwdPrefix" "$GATE_WRITE")" \
  "REQ-012: gate-write.mjs uses cwdPrefix for comparison"

assert_equals "no" "$(grep_has "cwdWithSep" "$GATE_WRITE")" \
  "REQ-012: gate-write.mjs does not use old cwdWithSep"

assert_equals "yes" "$(file_exists "$ZERO_DIR/tests/test-gate-write-windows.mjs")" \
  "REQ-012: Node.js regression test exists"

# ── REQ-008 (mid-pipeline): orchestrator-presence-check hook ─────────────────

echo ""
echo "=== REQ-008 (mid-pipeline): check-orchestrator-presence hook ==="

assert_equals "yes" "$(file_exists "$PRESENCE_CHECK")" \
  "REQ-008p: check-orchestrator-presence.mjs exists"

assert_equals "yes" "$(grep_has "orchestrator-active" "$PRESENCE_CHECK")" \
  "REQ-008p: hook checks .orchestrator-active sentinel"

assert_equals "yes" "$(grep_has "RAVINTIO PIPELINE ACTIVE" "$PRESENCE_CHECK")" \
  "REQ-008p: advisory mode banner present"

assert_equals "yes" "$(grep_has "orchestrator-strict" "$PRESENCE_CHECK")" \
  "REQ-008p: hook reads .orchestrator-strict for strict mode"

assert_equals "yes" "$(grep_has "orchestrator-ack" "$PRESENCE_CHECK")" \
  "REQ-008p: hook reads/compares .orchestrator-ack"

assert_equals "yes" "$(grep_has "session_id" "$PRESENCE_CHECK")" \
  "REQ-008p: hook uses session_id for ack"

assert_equals "yes" "$(grep_has "RAVINTIO STRICT MODE\|STRICT MODE" "$PRESENCE_CHECK")" \
  "REQ-008p: strict mode hard-block banner present"

assert_equals "yes" "$(grep_has "check-orchestrator-presence" "$SETUP_SH")" \
  "REQ-008p: setup.sh wires check-orchestrator-presence"

assert_equals "yes" "$(grep_has "RAVINTIO_PRESENCE" "$SETUP_SH")" \
  "REQ-008p: setup.sh passes presence cmd to UserPromptSubmit wiring"

assert_equals "yes" "$(grep_has "strict-orchestrator" "$SETUP_SH")" \
  "REQ-008p: setup.sh has --strict-orchestrator flag"

assert_equals "yes" "$(grep_has "orchestrator-strict" "$SETUP_SH")" \
  "REQ-008p: setup.sh writes plan/.orchestrator-strict sentinel"

assert_equals "yes" "$(grep_has "check-orchestrator-presence\|presenceEntry" "$SETUP_PS1")" \
  "REQ-008p: setup.ps1 wires check-orchestrator-presence"

assert_equals "yes" "$(grep_has "strict-orchestrator\|StrictOrchestrator" "$SETUP_PS1")" \
  "REQ-008p: setup.ps1 has --strict-orchestrator flag"

assert_equals "yes" "$(grep_has "orchestrator-strict" "$SETUP_PS1")" \
  "REQ-008p: setup.ps1 writes plan/.orchestrator-strict sentinel"

assert_equals "yes" "$(grep_has "orchestrator-ack" "$ORCHESTRATOR")" \
  "REQ-008p: orchestrator SKILL.md writes .orchestrator-ack on P0 start"

assert_equals "yes" "$(grep_has "orchestrator-ack" "$SHIP_AGENT")" \
  "REQ-008p: ship skill deletes .orchestrator-ack at close-out"

# getting-started.md is the entry-point file (deliberately terse, per the
# 0000012 three-file docs architecture, ADR-001); presence-check/strict-mode
# is deep-reference material and lives in pipeline-reference.md instead.
assert_equals "yes" "$(grep_has "check-orchestrator-presence\|orchestrator-presence" "$PIPELINE_REFERENCE")" \
  "REQ-008p: pipeline-reference.md documents presence check hook"

assert_equals "yes" "$(grep_has "strict-orchestrator" "$PIPELINE_REFERENCE")" \
  "REQ-008p: pipeline-reference.md documents --strict-orchestrator flag"

print_summary
