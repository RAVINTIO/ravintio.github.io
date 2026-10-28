#!/usr/bin/env bash
# Tests for feature 0000007-agent-optimisation
# Covers: req-001 through req-008

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS="$ZERO_DIR/skills"
TEMPLATES="$ZERO_DIR/templates"
STANDARDS="$ZERO_DIR/standards"

assert_not_contains() {
  local needle="$1"
  local haystack="$2"
  local message="${3:-not-contains assertion}"

  if printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "  FAIL: $message"
    echo "        needle '$needle' was found but should be absent"
    ((FAIL++)) || true
  else
    echo "  PASS: $message"
    ((PASS++)) || true
  fi
}

assert_file_exists() {
  local path="$1" label="${2:-file exists}"
  if [ -e "$path" ]; then
    echo "  PASS: $label"
    ((PASS++)) || true
  else
    echo "  FAIL: $label: $path"
    ((FAIL++)) || true
  fi
}

# -----------------------------------------------------------------------

echo ""
echo "=== req-001: build target field in feature-brief template ==="

BRIEF=$(cat "$TEMPLATES/feature-brief.template.md")
assert_contains "Build target"       "$BRIEF" "req-001: Build target row exists in Stack table"
assert_contains "local"              "$BRIEF" "req-001: 'local' is an allowed value"
assert_contains "docker"             "$BRIEF" "req-001: 'docker' is an allowed value"
assert_contains "ci-only"            "$BRIEF" "req-001: 'ci-only' is an allowed value"

# -----------------------------------------------------------------------

echo ""
echo "=== req-002: build target agent guidance ==="

CODEGEN=$(cat "$SKILLS/ravintio-implement/SKILL.md")
assert_contains "Build target: docker"        "$CODEGEN" "req-002: implement skill has Build target: docker section"
assert_contains "check host-installed runtimes" "$CODEGEN" "req-002: implement instructs never check host runtimes"
assert_contains "docker build"                "$CODEGEN" "req-002: implement skill references docker build"
# 0000171 ADR-004: skills no longer bundle pack files, so no bundle field remains.
assert_not_contains "bundle_standards"        "$CODEGEN" "req-002: implement skill holds no bundle_standards (0000171 ADR-004)"

VALIDATE=$(cat "$SKILLS/ravintio-validate-and-accept/SKILL.md")
assert_contains "Build target: docker"        "$VALIDATE" "req-002: validate-agent has Build target: docker section"
assert_contains "host toolchain"              "$VALIDATE" "req-002: validate-agent instructs never run host toolchain"
assert_contains "docker build"                "$VALIDATE" "req-002: validate-agent references docker build"
assert_not_contains "bundle_standards"        "$VALIDATE" "req-002: validate-agent holds no bundle_standards (0000171 ADR-004)"

assert_file_exists "$STANDARDS/build-target-standards.md" "req-002: build-target-standards.md exists"
BUILD_STD=$(cat "$STANDARDS/build-target-standards.md")
assert_contains "local"     "$BUILD_STD" "req-002: build-target-standards defines 'local' tier"
assert_contains "docker"    "$BUILD_STD" "req-002: build-target-standards defines 'docker' tier"
assert_contains "ci-only"   "$BUILD_STD" "req-002: build-target-standards defines 'ci-only' tier"

# -----------------------------------------------------------------------

echo ""
echo "=== req-003: ravintio-optimise-agent skill ==="

OPTIMISE_FILE="$SKILLS/ravintio-optimise-agent/SKILL.md"
assert_file_exists "$OPTIMISE_FILE" "req-003: optimise-agent SKILL.md exists"

OPTIMISE=$(cat "$OPTIMISE_FILE")
FRONTMATTER_NAME=$(grep "^name:" "$OPTIMISE_FILE" | head -1 | awk '{print $2}')
assert_equals "ravintio-optimise-agent" "$FRONTMATTER_NAME" "req-003: frontmatter name matches directory"

assert_not_contains "bundle_standards"        "$OPTIMISE" "req-003: frontmatter holds no bundle_standards (0000171 ADR-004)"
assert_contains "description:"                "$OPTIMISE" "req-003: frontmatter has description"
assert_contains "ravintio-zero/skills/" "$OPTIMISE" "req-003: skill targets ravintio-zero/skills/"
assert_contains "Do NOT review"              "$OPTIMISE" "req-003: skill explicitly excludes out-of-scope directories"

assert_contains "Implicit model knowledge"    "$OPTIMISE" "req-003: category 1 — implicit model knowledge"
assert_contains "Hook-enforced duplication"   "$OPTIMISE" "req-003: category 2 — hook-enforced duplication"
assert_contains "Cross-file boilerplate"      "$OPTIMISE" "req-003: category 3 — cross-file boilerplate"
assert_contains "Stale reference"             "$OPTIMISE" "req-003: category 4 — stale references"

assert_contains "one suggestion at a time"    "$OPTIMISE" "req-003: presents one suggestion at a time"
assert_contains "confirm"                     "$OPTIMISE" "req-003: waits for confirm/reject"
assert_contains "Confirmed so far"            "$OPTIMISE" "req-003: accumulates confirmed list"
assert_contains "Review complete"             "$OPTIMISE" "req-003: produces end-of-review summary"
assert_contains "Never write"                 "$OPTIMISE" "req-003: hard limit — never modifies files"

# -----------------------------------------------------------------------

echo ""
echo "=== req-004: skill boilerplate removal ==="

# 0000171 ADR-004: phase skills hold no bundle fields in frontmatter.
# (0000033: the telemetry-standards.md pointer assertion is gone — see below.)
for skill in ravintio-plan ravintio-implement \
             ravintio-validate-and-accept ravintio-ship; do
  SKILL_CONTENT=$(cat "$SKILLS/$skill/SKILL.md")
  assert_not_contains "bundle_standards" "$SKILL_CONTENT" "req-004: $skill holds no bundle_standards in frontmatter"
  assert_not_contains "telemetry-standards.md" "$SKILL_CONTENT" "req-004: $skill does not name telemetry-standards.md"
done

# Sub-agent skills (footer-only removal) — verify skill files still exist and are valid
for skill in ravintio-test-writer ravintio-implementer ravintio-refactor; do
  assert_file_exists "$SKILLS/$skill/SKILL.md" "req-004: $skill SKILL.md exists after footer removal"
done

# Hard Limits section should be absent from downstream phase skills (the orchestrator holds them)
for skill in ravintio-plan ravintio-implement \
             ravintio-validate-and-accept; do
  SKILL_CONTENT=$(cat "$SKILLS/$skill/SKILL.md")
  assert_not_contains "## Hard Limits" "$SKILL_CONTENT" "req-004: $skill has no Hard Limits section"
done

# -----------------------------------------------------------------------

echo ""
echo "=== req-005: telemetry standards extraction (retired by 0000033) ==="

# 0000033 removed telemetry from ravintio-zero: standards/telemetry-standards.md
# is deleted, so every assertion about its contents is gone. What remains is the
# strengthened inverse: the file must not come back.
if [ -e "$STANDARDS/telemetry-standards.md" ]; then
  echo "  FAIL: req-005: telemetry-standards.md is retired and must not exist"
  ((FAIL++)) || true
else
  echo "  PASS: req-005: telemetry-standards.md is retired and absent"
  ((PASS++)) || true
fi

# -----------------------------------------------------------------------

echo ""
echo "=== req-006: stale reference cleanup ==="

for skill in ravintio-plan ravintio-implement \
             ravintio-validate-and-accept ravintio-orchestrator; do
  SKILL_CONTENT=$(cat "$SKILLS/$skill/SKILL.md")
  assert_not_contains "design-requirements.md" "$SKILL_CONTENT" "req-006: $skill has no reference to design-requirements.md"
done

for skill in ravintio-validate-and-accept ravintio-orchestrator ravintio-ship; do
  SKILL_CONTENT=$(cat "$SKILLS/$skill/SKILL.md")
  assert_not_contains "pipeline-run.md" "$SKILL_CONTENT" "req-006: $skill has no reference to pipeline-run.md"
done

for skill in ravintio-orchestrator ravintio-ship; do
  SKILL_CONTENT=$(cat "$SKILLS/$skill/SKILL.md")
  assert_not_contains "external-skills.json" "$SKILL_CONTENT" "req-006: $skill has no reference to external-skills.json"
  assert_not_contains "skill-sync.sh" "$SKILL_CONTENT" "req-006: $skill has no reference to skill-sync.sh"
done

VALIDATE=$(cat "$SKILLS/ravintio-validate-and-accept/SKILL.md")
assert_contains "build-log.md" "$VALIDATE" "req-006: validate-agent references build-log.md (correct path)"

# -----------------------------------------------------------------------

echo ""
echo "=== req-007: template extractions and setup manifest ==="

DESIGN_TMPL="$TEMPLATES/design.template.md"
assert_file_exists "$DESIGN_TMPL" "req-007: design.template.md exists"

DESIGN_T=$(cat "$DESIGN_TMPL")
assert_contains "feature-id"    "$DESIGN_T" "req-007: design.template.md has feature-id field"
assert_contains "Build target"  "$DESIGN_T" "req-007: design.template.md has Build target in Stack row"
assert_contains "Components"    "$DESIGN_T" "req-007: design.template.md has Components field"

ORCH=$(cat "$(orch_combined "$SKILLS/ravintio-orchestrator")")
assert_contains "design.template.md" "$ORCH" "req-007: orchestrator JIT Loading table references design.template.md"
assert_not_contains "## Design - {feature-id}" "$ORCH" "req-007: orchestrator has no inline design template block"

DOCS=$(cat "$SKILLS/ravintio-implement/SKILL.md")
assert_contains "iteration-log.template.md" "$DOCS" "req-007: implement references iteration-log.template.md"
assert_not_contains "# Iteration Log" "$DOCS" "req-007: implement has no inline iteration log template block"

SETUP_SH=$(cat "$ZERO_DIR/setup.sh")
assert_contains ".ravintio-manifest" "$SETUP_SH" "req-007: setup.sh writes .ravintio-manifest"
assert_contains "Re-run detected"     "$SETUP_SH" "req-007: setup.sh handles re-run manifest cleanup"

SETUP_PS1=$(cat "$ZERO_DIR/setup.ps1")
assert_contains ".ravintio-manifest" "$SETUP_PS1" "req-007: setup.ps1 writes .ravintio-manifest"
assert_contains "Re-run detected"     "$SETUP_PS1" "req-007: setup.ps1 handles re-run manifest cleanup"

# -----------------------------------------------------------------------

echo ""
echo "=== req-008: language standards ==="

LANG_FILE="$STANDARDS/language-quirks-en-gb.md"
assert_file_exists "$LANG_FILE" "req-008: language-quirks-en-gb.md exists"

LANG=$(cat "$LANG_FILE")
assert_contains 'locale: "en-GB"'     "$LANG" "req-008: frontmatter has locale: en-GB"
assert_contains "artifact"            "$LANG" "req-008: artifact listed as American exception"
assert_contains "initialize"          "$LANG" "req-008: initialize listed as American exception"
assert_contains "serialize"           "$LANG" "req-008: serialize listed as American exception"
assert_contains "licence"             "$LANG" "req-008: licence/license noun/verb distinction documented"
assert_contains "ID"                  "$LANG" "req-008: capitalisation rules present"
assert_contains "data"                "$LANG" "req-008: data countability rule present"

# Global artefact → artifact check (prose only — code spans excluded by design)
# Check no prose 'artefact' in skill files
ARTEFACT_IN_SKILLS=$(grep -rl "artefact" "$SKILLS" 2>/dev/null | grep -v ".bak" || true)
if [ -z "$ARTEFACT_IN_SKILLS" ]; then
  echo "  PASS: req-008: no prose 'artefact' in skills/"
  ((PASS++)) || true
else
  echo "  FAIL: req-008: 'artefact' found in skills/: $ARTEFACT_IN_SKILLS"
  ((FAIL++)) || true
fi

# Check no prose 'artefact' in standards files (excluding language-quirks itself where it appears in code spans)
ARTEFACT_IN_STANDARDS=$(grep -l "artefact" "$STANDARDS"/*.md 2>/dev/null | grep -v "language-quirks" || true)
if [ -z "$ARTEFACT_IN_STANDARDS" ]; then
  echo "  PASS: req-008: no prose 'artefact' in standards/ (excluding language-quirks)"
  ((PASS++)) || true
else
  # Check if the remaining occurrences are only in formatting-standards — that one documents the rule
  ARTEFACT_NON_DOC=$(echo "$ARTEFACT_IN_STANDARDS" | grep -v "formatting-standards" || true)
  if [ -z "$ARTEFACT_NON_DOC" ]; then
    echo "  PASS: req-008: remaining 'artefact' in standards/ only in documentation tables"
    ((PASS++)) || true
  else
    echo "  FAIL: req-008: prose 'artefact' found outside documentation context: $ARTEFACT_NON_DOC"
    ((FAIL++)) || true
  fi
fi

# -----------------------------------------------------------------------

print_summary
