#!/usr/bin/env bash
# Content-pinning tests for the doc/workflow-only requirements of feature
# 0000027 that survive the five-phase cut-down: req-003 (subagent
# backlog filing), req-005 (pack update policy), req-007 (skill-scope
# test), req-008 (minimal plan-phase artifact set). Asserts the required
# content exists in its current homes rather than executing prose.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "=== req-003: subagent out-of-scope discoveries file to plan/backlog/ ==="

DISPATCH_STANDARDS="$ZERO_DIR/standards/agent-dispatch-standards.md"
content=$(cat "$DISPATCH_STANDARDS")
assert_contains "plan/backlog/{id}-{slug}/entry.md" "$content" \
  "req-003: dispatch template instructs filing to plan/backlog/"
assert_contains "pre-computes the next available backlog ID" "$content" \
  "req-003: dispatching agent pre-computes the backlog ID"
assert_contains "Subagent self-lookup" "$content" \
  "req-003: subagent self-lookup explicitly rejected"

for skill in ravintio-orchestrator ravintio-plan ravintio-implement ravintio-validate-and-accept; do
  skill_content=$(cat "$ZERO_DIR/skills/$skill/SKILL.md")
  assert_contains "backlog" "$skill_content" "req-003: $skill references backlog guidance"
done

echo ""
echo "=== req-005: explicit discovery flow for a ravintio-zero/ dependency update ==="

ORCHESTRATOR_SKILL="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
orch_content=$(cat "$ORCHESTRATOR_SKILL")
assert_contains "Pack dependency update" "$orch_content" \
  "req-005: orchestrator has a distinct resume-detection step for pack updates"
assert_contains "pack-update-policy.md" "$orch_content" \
  "req-005: orchestrator points to the Pack Update Policy doc"

assert_equals "yes" "$([ -f "$ZERO_DIR/standards/pack-update-policy.md" ] && echo yes || echo no)" \
  "req-005: standards/pack-update-policy.md exists"

if [ -f "$ZERO_DIR/standards/pack-update-policy.md" ]; then
  policy_content=$(cat "$ZERO_DIR/standards/pack-update-policy.md")
  assert_contains "provenance" "$policy_content" \
    "req-005: Pack Update Policy requires provenance confirmation"
fi
assert_contains "provenance" "$orch_content" \
  "req-005: orchestrator requires provenance confirmation before accepting the update"

echo ""
echo "=== req-007: skill-scope test guards the process that adds a skill ==="

assert_contains "skill-scope test" "$orch_content" \
  "req-007: orchestrator names the skill-scope test"
assert_contains "governance or traceability the host tool cannot provide" "$orch_content" \
  "req-007: the skill-scope test states its criterion"

echo ""
echo "=== req-008: minimal plan-phase artifact set agrees between workflow and plan skill ==="

PIPELINE_WORKFLOW="$ZERO_DIR/workflows/feature-pipeline.md"
pipeline_content=$(cat "$PIPELINE_WORKFLOW")
assert_contains "one artifact set: the execution plan, functional" "$pipeline_content" \
  "req-008: feature-pipeline.md's always-produced list starts with execution plan + requirements"

plan_content=$(cat "$ZERO_DIR/skills/ravintio-plan/SKILL.md")
assert_contains "produced only when its trigger holds" "$plan_content" \
  "req-008: ravintio-plan gates conditional artifacts on a trigger"
assert_contains "The feature builds or modifies an API" "$plan_content" \
  "req-008: ravintio-plan states OpenAPI's trigger condition"
assert_contains "The feature introduces or modifies a deployed runtime service" "$plan_content" \
  "req-008: ravintio-plan states the operational model's trigger condition"

README_CONTENT=$(cat "$SCRIPT_DIR/../../README.md")
assert_contains "five plan-phase artifacts by default" "$README_CONTENT" \
  "req-008: README states the default artifact count"

print_summary
