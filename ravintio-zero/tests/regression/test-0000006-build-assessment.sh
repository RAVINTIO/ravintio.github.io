#!/usr/bin/env bash
# Tests for feature 0000006-build-assessment-phase
# Covers: req-001 through req-008
# Amended for the 0000030 cut-down: build assessment folded into
# skills/ravintio-ship/SKILL.md Step 5, P8 removed, phase agents retired.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS="$ZERO_DIR/skills"
TEMPLATES="$ZERO_DIR/templates"

# -----------------------------------------------------------------------

echo ""
echo "=== req-001: build log working file ==="

assert_file_exists() {
  local path="$1" label="$2"
  if [ -e "$path" ]; then
    assert_equals "0" "0" "$label"
  else
    assert_equals "exists" "missing" "$label: $path"
  fi
}

ORCH=$(cat "$(orch_combined "$SKILLS/ravintio-orchestrator")")
assert_contains "build-log.md"               "$ORCH" "req-001: orchestrator references build-log.md"
assert_contains "build-log.template.md"      "$ORCH" "req-001: orchestrator references build-log template"
assert_contains "append"                     "$ORCH" "req-001: orchestrator has append instruction for resume"

# -----------------------------------------------------------------------

echo ""
echo "=== req-002: build assessment step in the ship skill ==="
echo "(0000030: ravintio-build-assessment-agent retired, build assessment folded into ravintio-ship Step 5)"

# The retired skill carried its own frontmatter name check. The folded-in
# step has no frontmatter of its own, so that check is dropped.
SHIP_FILE="$SKILLS/ravintio-ship/SKILL.md"
assert_file_exists "$SHIP_FILE"                                 "req-002: ship skill file exists"

SHIP=$(cat "$SHIP_FILE")
assert_contains "### Step 5: Build assessment" "$SHIP" "req-002: Step 5 Build assessment present"
assert_contains "model tiers"                "$SHIP" "req-002: covers agent counts and model tiers per phase"
assert_contains "Parallelism used"           "$SHIP" "req-002: covers parallelism"
assert_contains "Self-corrections"           "$SHIP" "req-002: covers self-corrections"
assert_contains "avoidable"                  "$SHIP" "req-002: avoidability judged per self-correction"
assert_contains "ran sequentially"           "$SHIP" "req-002: covers phases that ran sequentially"
assert_contains "improvement suggestion"     "$SHIP" "req-002: one improvement suggestion per phase"
assert_contains "build-report.md"            "$SHIP" "req-002: output path references build-report.md"
assert_contains "build-log.md"               "$SHIP" "req-002: step reads build-log.md as input"
assert_contains "Never infer or fabricate"   "$SHIP" "req-002: no-fabrication rule present"

# -----------------------------------------------------------------------

echo ""
echo "=== req-003: build assessment wired into P4 Ship ==="
echo "(0000030: P8 removed, build assessment now runs inside P4 Ship)"

assert_contains "| P4 | Ship |"              "$ORCH" "req-003: orchestrator phase table lists P4 Ship"
assert_contains "ravintio-ship"             "$ORCH" "req-003: P4 owned by ravintio-ship"
assert_contains "build report"               "$ORCH" "req-003: P4 Ship gate condition mentions build report"

assert_contains "Build report:"              "$SHIP" "req-003: ship final gate output lists the build report line"
assert_contains "build-report.md"            "$SHIP" "req-003: ship final gate confirms build-report.md"

# -----------------------------------------------------------------------

echo ""
echo "=== req-004: model routing rules ==="
echo "(0000022: Model Tier Decision Table relocated to standards/agent-dispatch-standards.md, ADR-001 - orchestrator now points to it)"

DISPATCH_STD=$(cat "$ZERO_DIR/standards/agent-dispatch-standards.md")
assert_contains "agent-dispatch-standards.md" "$ORCH" "req-004: orchestrator points to agent-dispatch-standards.md"
assert_contains "Model Tier"                 "$DISPATCH_STD" "req-004: standards file has Model Tier section"
assert_contains "Primary"                    "$DISPATCH_STD" "req-004: Primary tier defined"
assert_contains "Cheaper"                    "$DISPATCH_STD" "req-004: Cheaper tier defined"
assert_contains "Code generation"            "$DISPATCH_STD" "req-004: code generation classified"
assert_contains "Security review"            "$DISPATCH_STD" "req-004: security review classified"
assert_contains "Codebase discovery"         "$DISPATCH_STD" "req-004: codebase discovery classified"
assert_contains "Formatting"                 "$DISPATCH_STD" "req-004: formatting classified"
assert_contains "Tier-to-model"              "$DISPATCH_STD" "req-004: tier-to-model mapping table present"
assert_contains '| Claude Code | `sonnet` | `haiku` |' "$DISPATCH_STD" "req-004: Haiku listed as cheaper tier for Claude Code"

# -----------------------------------------------------------------------

echo ""
echo "=== req-005: parallelism directives in orchestrator ==="
echo "(0000022: Parallelism Rules relocated to standards/agent-dispatch-standards.md, ADR-001 - orchestrator now points to it)"

assert_contains "Parallelism Rules"          "$DISPATCH_STD" "req-005: Parallelism Rules section present"
assert_contains "Default posture: parallel"  "$DISPATCH_STD" "req-005: default posture is parallel stated"
assert_contains "Dependency test"            "$DISPATCH_STD" "req-005: dependency test present"
assert_contains "MUST parallelise"           "$DISPATCH_STD" "req-005: MUST parallelise table present"
assert_contains "Cannot parallelise"         "$DISPATCH_STD" "req-005: Cannot parallelise table present"

# -----------------------------------------------------------------------

echo ""
echo "=== req-006: parallelism directives in phase skills ==="
echo "(0000030: the six phase agents are retired, parallelism now lives in the surviving phase skills)"

PLAN=$(cat "$SKILLS/ravintio-plan/SKILL.md")
assert_contains "## Parallelism"             "$PLAN" "req-006: plan skill has Parallelism section"
assert_contains "MUST parallelise"           "$PLAN" "req-006: plan skill has MUST parallelise table"

IMPLEMENT=$(cat "$SKILLS/ravintio-implement/SKILL.md")
assert_contains "## Parallel dispatch"       "$IMPLEMENT" "req-006: implement skill has Parallel dispatch section"
assert_contains "MUST"                       "$IMPLEMENT" "req-006: implement skill uses MUST"

# The validate skill states batch order rather than MUST, so assert the
# parallel batching wording instead.
VALIDATE=$(cat "$SKILLS/ravintio-validate-and-accept/SKILL.md")
assert_contains "## Parallelism"             "$VALIDATE" "req-006: validate-and-accept skill has Parallelism section"
assert_contains "(parallel)"                 "$VALIDATE" "req-006: validate-and-accept states parallel batches"

# -----------------------------------------------------------------------

echo ""
echo "=== req-007: build-log.template.md ==="

TEMPLATE="$TEMPLATES/build-log.template.md"
assert_file_exists "$TEMPLATE"                               "req-007: build-log.template.md exists"

TMPL=$(cat "$TEMPLATE")
assert_contains "feature-id"                 "$TMPL" "req-007: template has feature-id field"
assert_contains "primary-model"              "$TMPL" "req-007: template has primary model field"
assert_contains "cheaper-model"              "$TMPL" "req-007: template has cheaper model field"
assert_contains "Model tier"                 "$TMPL" "req-007: template has model tier per-phase field"
assert_contains "Agents spawned"             "$TMPL" "req-007: template has agents spawned field"
assert_contains "MCP calls"                  "$TMPL" "req-007: template has MCP calls field"
assert_contains "Parallel task"              "$TMPL" "req-007: template has parallel task batches field"
assert_contains "Summary"                    "$TMPL" "req-007: template has Summary section"
assert_contains "{{feature-id}}"             "$TMPL" "req-007: template uses placeholder tokens"

# -----------------------------------------------------------------------

print_summary
