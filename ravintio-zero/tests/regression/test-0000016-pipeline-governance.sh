#!/usr/bin/env bash
# Tests for feature 0000016-pipeline-governance-and-loop-engineering
# Covers: req-001, req-003, req-004, req-010, req-011, req-014, req-015, req-018
# (SKILL.md text checks for req-002/005/006/007/008/009/012/013/016/017/019/020/021
#  are in the "skill text" section at the bottom.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES="$ZERO_DIR/templates"
SCRIPTS="$ZERO_DIR/scripts"
HOOKS="$ZERO_DIR/hooks/enforcement"
SKILLS="$ZERO_DIR/skills"
STANDARDS="$ZERO_DIR/standards"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_file_exists() {
  local path="$1" label="$2"
  if [ -e "$path" ]; then
    assert_equals "0" "0" "$label"
  else
    assert_equals "exists" "missing" "$label: $path"
  fi
}

# -----------------------------------------------------------------------
echo ""
echo "=== req-001: backlog entry template ==="
# -----------------------------------------------------------------------

assert_file_exists "$TEMPLATES/backlog-entry.template.md" "req-001: backlog-entry.template.md exists"
BACKLOG_T=$(cat "$TEMPLATES/backlog-entry.template.md" 2>/dev/null || echo "")
assert_contains "Source feature" "$BACKLOG_T" "req-001: source feature field"
assert_contains "Source phase"   "$BACKLOG_T" "req-001: source phase field"
assert_contains "Date filed"     "$BACKLOG_T" "req-001: date filed field"
assert_contains "Problem"        "$BACKLOG_T" "req-001: problem section"

# -----------------------------------------------------------------------
echo ""
echo "=== req-003: product.yml template ==="
# -----------------------------------------------------------------------

assert_file_exists "$TEMPLATES/product.template.yml" "req-003: product.template.yml exists"
PRODUCT_T=$(cat "$TEMPLATES/product.template.yml" 2>/dev/null || echo "")
assert_contains "versionPolicy"          "$PRODUCT_T" "req-003: versionPolicy field"
assert_contains "max-component-version"  "$PRODUCT_T" "req-003: max-component-version documented"
assert_contains "explicit"               "$PRODUCT_T" "req-003: explicit documented"
assert_contains "external"               "$PRODUCT_T" "req-003: external documented"
assert_contains "components"             "$PRODUCT_T" "req-003: components list"
assert_contains "path"                   "$PRODUCT_T" "req-003: components[] entries are path pointers, not cached versions"

# -----------------------------------------------------------------------
echo ""
echo "=== req-004: product-version.mjs derivation ==="
# -----------------------------------------------------------------------

PV="$SCRIPTS/product-version.mjs"
assert_file_exists "$PV" "req-004: product-version.mjs exists"

# components[] holds {id, path} pointers to each component's own component.yml —
# not a cached version — so max-component-version fixtures need real component.yml
# files on disk for the script to read live (revised 2026-08-08).

# fixture: max-component-version
FIX1="$TMP/fix-max"; mkdir -p "$FIX1/comp-a" "$FIX1/comp-b"
printf 'id: "comp-a"\nversion: "1.2.0"\n' > "$FIX1/comp-a/component.yml"
printf 'id: "comp-b"\nversion: "1.10.3"\n' > "$FIX1/comp-b/component.yml"
cat > "$FIX1/product.yml" <<'YAML'
id: "demo-product"
name: "Demo"
version: "0.1.0"
feature: "0000001-demo"
versionPolicy: "max-component-version"
components:
  - id: "comp-a"
    path: "comp-a/component.yml"
  - id: "comp-b"
    path: "comp-b/component.yml"
YAML
OUT=$(node "$PV" --root "$FIX1" 2>&1); RC=$?
assert_equals "1.10.3" "$OUT" "req-004: max-component-version derives highest semver (1.10.3 > 1.2.0)"
assert_exit_zero "$RC" "req-004: max policy exits 0"

# fixture: explicit — doesn't touch components[]/component.yml at all
FIX2="$TMP/fix-explicit"; mkdir -p "$FIX2"
sed 's/max-component-version/explicit/; s/version: "0.1.0"/version: "2.5.1"/' "$FIX1/product.yml" > "$FIX2/product.yml"
OUT=$(node "$PV" --root "$FIX2" 2>&1); RC=$?
assert_equals "2.5.1" "$OUT" "req-004: explicit policy returns manifest version"
assert_exit_zero "$RC" "req-004: explicit policy exits 0"

# fixture: external — prints version but exit 5 signals "ask the anchor/human"
FIX3="$TMP/fix-external"; mkdir -p "$FIX3"
sed 's/max-component-version/external/' "$FIX1/product.yml" > "$FIX3/product.yml"
OUT=$(node "$PV" --root "$FIX3" 2>&1); RC=$?
assert_equals "5" "$RC" "req-004: external policy exits 5 (caller must consult anchor)"

# fixture: invalid version string in the referenced component.yml rejected
FIX4="$TMP/fix-invalid"; mkdir -p "$FIX4/comp-a" "$FIX4/comp-b"
cp "$FIX1/product.yml" "$FIX4/product.yml"
cp "$FIX1/comp-a/component.yml" "$FIX4/comp-a/component.yml"
printf 'id: "comp-b"\nversion: "not-a-version"\n' > "$FIX4/comp-b/component.yml"
OUT=$(node "$PV" --root "$FIX4" 2>&1); RC=$?
assert_equals "2" "$RC" "req-004: invalid component version exits 2"

# fixture: components[] path points at a component.yml that doesn't exist
FIX4B="$TMP/fix-missing-path"; mkdir -p "$FIX4B/comp-a"
cp "$FIX1/product.yml" "$FIX4B/product.yml"
cp "$FIX1/comp-a/component.yml" "$FIX4B/comp-a/component.yml"
# comp-b/component.yml deliberately absent
OUT=$(node "$PV" --root "$FIX4B" 2>&1); RC=$?
assert_equals "2" "$RC" "req-004: components[] path with no component.yml at it exits 2"

# fixture: invalid policy rejected
FIX5="$TMP/fix-badpolicy"; mkdir -p "$FIX5"
sed 's/max-component-version/newest-wins/' "$FIX1/product.yml" > "$FIX5/product.yml"
OUT=$(node "$PV" --root "$FIX5" 2>&1); RC=$?
assert_equals "2" "$RC" "req-004: unknown versionPolicy exits 2"

# fixture: absent product.yml → exit 4 (caller falls back to component.yml)
FIX6="$TMP/fix-absent"; mkdir -p "$FIX6"
OUT=$(node "$PV" --root "$FIX6" 2>&1); RC=$?
assert_equals "4" "$RC" "req-004: absent product.yml exits 4 (single-component fallback)"

# -----------------------------------------------------------------------
echo ""
echo "=== req-010: loop state / revision log templates ==="
# -----------------------------------------------------------------------

assert_file_exists "$TEMPLATES/loop-state.template.md" "req-010: loop-state.template.md exists"
LS_T=$(cat "$TEMPLATES/loop-state.template.md" 2>/dev/null || echo "")
assert_contains "Iteration"                "$LS_T" "req-010: iteration counter field"
assert_contains "Run Log"                  "$LS_T" "req-010: run log section"
assert_contains "Append-only"              "$LS_T" "req-010: append-only rule stated"
assert_contains "Decision"                 "$LS_T" "req-010: decision field (continue/done/escalate)"

# -----------------------------------------------------------------------
echo ""
echo "=== req-011: loop toggles default off ==="
# -----------------------------------------------------------------------
# 0000033 removed telemetry from ravintio-zero. The telemetry event-vocabulary
# half of this section asserted over standards/telemetry-standards.md, which is
# deleted; those four assertions are gone. The toggle half stands unchanged.

assert_file_exists "$TEMPLATES/loop-toggles.template.yml" "req-011: loop-toggles.template.yml exists"
TOG=$(cat "$TEMPLATES/loop-toggles.template.yml" 2>/dev/null || echo "")
ON_COUNT=$(printf '%s' "$TOG" | grep -c '^[a-z_]*: on$' || true)
assert_equals "0" "$ON_COUNT" "req-011: no toggle defaults to on"
assert_contains "report-only" "$TOG" "req-011: report-only level documented"

# -----------------------------------------------------------------------
echo ""
echo "=== req-014: consistency-check.mjs ==="
# -----------------------------------------------------------------------

CC="$SCRIPTS/consistency-check.mjs"
assert_file_exists "$CC" "req-014: consistency-check.mjs exists"

# clean fixture
CLEAN="$TMP/clean/plan/current"; mkdir -p "$CLEAN/requirements" "$CLEAN/adr"
cat > "$CLEAN/design.md" <<'MD'
# Design
## Scope
- In: things
## Engineering Layer
- Components:
  - `demo-comp` (component-pack, existing) — owns stuff
MD
cat > "$CLEAN/requirements/req-001-demo.md" <<'MD'
# Requirement: REQ-001 - Demo
**Source:** US-001
## Acceptance Criteria
- [ ] AC-1: one
  - Given a fixture
  - When the check runs
  - Then it is clean
- [ ] AC-2: two
  - Given a fixture
  - When the check runs
  - Then it is clean
  - And nothing is flagged
## Dependencies
- None. See ADR-001.
MD
cat > "$CLEAN/story-map.md" <<'MD'
# Story Map
## Backbone
| Activity | Step | Story | Requirement |
|----------|------|-------|-------------|
| Demo | Run the demo | US-001 | REQ-001 |
MD
cat > "$CLEAN/adr/ADR-001-demo.md" <<'MD'
# ADR-001 - Demo
MD
cat > "$CLEAN/risk-register.md" <<'MD'
## Risks
| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | something specific | low | low | do the thing | open |
MD
OUT=$(node "$CC" "$CLEAN" 2>&1); RC=$?
assert_exit_zero "$RC" "req-014: clean fixture exits 0"

# seeded-defect fixture: 5 defect classes
BAD="$TMP/bad/plan/current"; mkdir -p "$BAD/requirements" "$BAD/adr"
cat > "$BAD/design.md" <<'MD'
# Design
MD
# defect 1: requirement with no Source story; defect 2: >3 acceptance criteria
cat > "$BAD/requirements/req-001-orphan.md" <<'MD'
# Requirement: REQ-001 - Orphan
## Acceptance Criteria
- [ ] one
- [ ] two
- [ ] three
- [ ] four
## Dependencies
- References ADR-009 which does not exist.
MD
# defect 5: risk without mitigation
cat > "$BAD/risk-register.md" <<'MD'
## Risks
| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | something | low | high | | open |
MD
OUT=$(node "$CC" "$BAD" 2>&1); RC=$?
assert_equals "1" "$RC" "req-014: seeded-defect fixture exits non-zero"
assert_contains "US"          "$OUT" "req-014: catches missing story traceability"
assert_contains "acceptance"  "$OUT" "req-014: catches >3 acceptance criteria"
assert_contains "ADR-009"     "$OUT" "req-014: catches orphaned ADR reference"
assert_contains "mitigation"  "$OUT" "req-014: catches risk without mitigation"
assert_contains "Scope"       "$OUT" "req-014: catches design without scope/component paths"

# -----------------------------------------------------------------------
echo ""
# -----------------------------------------------------------------------
echo ""
echo "=== req-018: ratchet-check hook ==="
# -----------------------------------------------------------------------

RATCHET="$HOOKS/ratchet-check.mjs"
assert_file_exists "$RATCHET" "req-018: ratchet-check.mjs exists"

# project fixture with an active loop
PROJ="$TMP/proj"; mkdir -p "$PROJ/plan/current"
cat > "$PROJ/plan/current/loop-state-design_critic.md" <<'MD'
---
status: "active"
---
# Loop State: design_critic
MD
cat > "$PROJ/plan/current/requirements-doc.md" <<'MD'
# Requirement: REQ-001 - Demo
## Acceptance Criteria
- [ ] criterion alpha holds
  - Given a fixture with an active loop
  - When the check runs
  - Then it holds
- [ ] criterion beta holds
  - Given a second fixture
  - When the check runs
  - Then it holds
MD

run_ratchet() {
  # $1 = file_path, $2 = new content, $3 = cwd
  local payload
  payload=$(node -e '
    const [fp, content] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:fp,content}}));
  ' "$1" "$2")
  ( cd "$3" && printf '%s' "$payload" | node "$RATCHET" >/dev/null 2>&1; echo $? )
}

# weakening: remove criterion beta
WEAK=$'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n  - Given a fixture with an active loop\n  - When the check runs\n  - Then it holds'
RC=$(run_ratchet "$PROJ/plan/current/requirements-doc.md" "$WEAK" "$PROJ")
assert_equals "2" "$RC" "req-018: weakening write (removed criterion) blocked with exit 2"

# strengthening: add criterion gamma
STRONG=$'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n  - Given a fixture with an active loop\n  - When the check runs\n  - Then it holds\n- [ ] criterion beta holds\n  - Given a second fixture\n  - When the check runs\n  - Then it holds\n- [ ] criterion gamma holds\n  - Given a third fixture\n  - When the check runs\n  - Then it holds'
RC=$(run_ratchet "$PROJ/plan/current/requirements-doc.md" "$STRONG" "$PROJ")
assert_equals "0" "$RC" "req-018: strengthening write passes with exit 0"

# approved weakening: marker file names the path, write passes, marker consumed
# (marker format `path | reason | timestamp` per 0000017 ADR-001, superseding
#  0000016 ADR-004's bare-path format — fixture updated when the format changed)
printf '%s\n' "plan/current/requirements-doc.md | criterion beta was genuinely wrong | 2026-07-26T00:00:00Z" > "$PROJ/plan/current/.ratchet-approve"
RC=$(run_ratchet "$PROJ/plan/current/requirements-doc.md" "$WEAK" "$PROJ")
assert_equals "0" "$RC" "req-018: human-approved weakening passes (marker present)"
if [ -s "$PROJ/plan/current/.ratchet-approve" ]; then
  assert_equals "consumed" "still-present" "req-018: marker consumed after use"
else
  assert_equals "0" "0" "req-018: marker consumed after use"
fi

# disarmed: no active loop-state → weakening passes (hook not armed)
PROJ2="$TMP/proj2"; mkdir -p "$PROJ2/plan/current"
cp "$PROJ/plan/current/requirements-doc.md" "$PROJ2/plan/current/"
RC=$(run_ratchet "$PROJ2/plan/current/requirements-doc.md" "$WEAK" "$PROJ2")
assert_equals "0" "$RC" "req-018: hook disarmed when no active loop-state file"

# malformed stdin → exit 0 (never block unexpectedly)
RC=$( (cd "$PROJ" && printf 'not json' | node "$RATCHET" >/dev/null 2>&1; echo $?) )
assert_equals "0" "$RC" "req-018: malformed input exits 0 (never blocks unexpectedly)"

# -----------------------------------------------------------------------
echo ""
echo "=== skill text: new skills exist and conform ==="
# -----------------------------------------------------------------------

for s in ravintio-loop-runner; do
  assert_file_exists "$SKILLS/$s/SKILL.md" "skill $s exists"
  S=$(cat "$SKILLS/$s/SKILL.md" 2>/dev/null || echo "")
  assert_contains "name: $s" "$S" "$s: frontmatter name"
  assert_contains "description:" "$S" "$s: frontmatter description"
done

# The plan skill inherited the mechanical consistency gate from the retired critic.
PLAN_SKILL=$(cat "$SKILLS/ravintio-plan/SKILL.md" 2>/dev/null || echo "")
assert_contains "consistency-check.mjs" "$PLAN_SKILL" "req-013: plan skill runs the consistency script"

RUNNER=$(cat "$SKILLS/ravintio-loop-runner/SKILL.md" 2>/dev/null || echo "")
assert_contains "no-progress" "$RUNNER" "req-009: loop-runner defines no-progress stop rule"
assert_contains "loop-state" "$RUNNER" "req-009: loop-runner references loop-state file"
assert_contains "loop-toggles" "$RUNNER" "req-009/011: loop-runner reads toggles"

VBE=$(cat "$SKILLS/ravintio-validate-and-accept/SKILL.md" 2>/dev/null || echo "")
assert_contains "not-verifiable" "$VBE" "req-020: validate-and-accept keeps the not-verifiable outcome"

# -----------------------------------------------------------------------
echo ""
echo "=== skill text: edited skills carry the new directives ==="
# -----------------------------------------------------------------------

ORCH=$(cat "$(orch_combined "$SKILLS/ravintio-orchestrator")" 2>/dev/null || echo "")
assert_contains "plan/backlog/" "$ORCH" "req-001/002: orchestrator documents backlog convention + pickup"
assert_contains "product.yml" "$ORCH" "req-005: orchestrator reads product.yml at discovery"
assert_contains "every meaningful artifact write" "$ORCH" "req-007: Hard Limit 7 strengthened"
assert_contains "push the feature branch" "$ORCH" "req-008: push cadence documented"

WAVE_ORCH=$(printf '%s' "$ORCH" | grep -ci 'group them into waves' || true)
assert_equals "1" "$WAVE_ORCH" "req-006: orchestrator Decomposition uses Waves"

BRIEF_T=$(cat "$TEMPLATES/feature-brief.template.md" 2>/dev/null || echo "")
assert_contains "| Wave |" "$BRIEF_T" "req-006: brief template Features table uses Wave column"
assert_contains "## Waves" "$BRIEF_T" "req-006: brief template Waves section"

SHIP=$(cat "$SKILLS/ravintio-ship/SKILL.md" 2>/dev/null || echo "")
assert_contains "product.yml" "$SHIP" "req-004: ship skill reads product.yml"
assert_contains "product-version.mjs" "$SHIP" "req-004: ship skill uses derivation script"

VAL=$(cat "$SKILLS/ravintio-validate-and-accept/SKILL.md" 2>/dev/null || echo "")
assert_contains "ravintio-loop-runner" "$VAL" "req-009: validate-and-accept references loop-runner"
assert_contains "verify" "$VAL" "req-020: validate-and-accept verifies by execution"

for s in ravintio-plan ravintio-implement; do
  SKILL_CONTENT=$(cat "$SKILLS/$s/SKILL.md")
  assert_contains "meaningful artifact write" "$SKILL_CONTENT" "req-007: $s carries commit directive"
done

print_summary
