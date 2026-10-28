#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-009: pack
# identifiers.
#
# Identifiers and file names that named RAVINTIO Zero after the old word now
# follow the ADR-004 map. Code uses "zero" (ZERO_DIR, zeroDir, ZeroDir). File
# names, headings, and anchors use "pack". This test builds each old name
# from two parts, so it never matches its own source.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"
SELF="ravintio-zero/tests/$(basename "$0")"

W="work"        # second half of the old word, so this file never matches itself
UP="FRAME""WORK"; LO="frame"; CAP="Frame"

# Tracked files that the rule covers: everything outside history and the
# current plan, which quotes the old names to describe the rename.
in_scope_files() {
  git -C "$REPO_ROOT" ls-files \
    | grep -v -e '^plan/_archive/' -e '^plan/changelog/' -e '^plan/current/' \
              -e '^ravintio-zero/migrations/_done/' \
    | grep -vxF "$SELF"
}

# Prints file:line for each in-scope line that matches the extended regex $1.
hits() {
  local re="$1"
  (cd "$REPO_ROOT" && in_scope_files | while IFS= read -r f; do
    [ -f "$f" ] && grep -nE -- "$re" "$f" /dev/null 2>/dev/null
  done) | cut -d: -f1-2
}

no_hits() {
  local re="$1" label="$2" found
  found="$(hits "$re")"
  assert_equals "" "$found" "req-009 (a): no in-scope line names $label"
}

echo ""
echo "=== req-009 (a): old variable and function names are gone ==="

no_hits "\\b${UP}(_DIR|_SRC)?\\b" "the old shell variables"
no_hits "\\b${LO}${W}Dir\\b" "the old JS directory name"
no_hits "\\b${CAP}${W}Dir\\b" "the old PowerShell directory name"
no_hits "\\b${LO}${W}Path\\b" "the old hook path name"
no_hits "extract${CAP}${W}Table" "the old table parser"

echo ""
echo "=== req-009 (a): old file names, anchors, headings, and labels are gone ==="

no_hits "${LO}${W}-update-policy" "the old policy file"
no_hits "updating-the-${LO}${W}" "the old update anchor"
no_hits "Updating the ${CAP}${W}" "the old update heading"
no_hits "^## The ${LO}${W}\$" "the old README heading"
no_hits "test-0000005-${LO}${W}-governance" "the old 0000005 test file"
no_hits "${LO}${W}-quality-improvements" "the old 0000010 test file"
no_hits "remove-old-${LO}${W}" "the old 0000037 req-004 test file"
no_hits "${LO}${W}-pipeline-fixes" "the old 0000023 comment label"
no_hits "^# Tests for feature 0000005-${LO}${W}-governance" "the old 0000005 header label"

echo ""
echo "=== req-009 (a): renamed files exist and old files do not ==="

for f in \
  standards/pack-update-policy.md \
  tests/test-0000005-pack-governance.sh \
  tests/regression/test-0000005-pack-governance.sh \
  tests/test-0000010-pack-quality-improvements.sh \
  tests/test-0000037-req-004-remove-old-folder.sh; do
  assert_equals "yes" "$([ -f "$ZERO_DIR/$f" ] && echo yes || echo no)" \
    "req-009 (a): $f exists"
done
for f in \
  "standards/${LO}${W}-update-policy.md" \
  "tests/test-0000005-${LO}${W}-governance.sh" \
  "tests/regression/test-0000005-${LO}${W}-governance.sh" \
  "tests/test-0000010-${LO}${W}-quality-improvements.sh" \
  "tests/test-0000037-req-004-remove-old-${LO}${W}.sh"; do
  assert_equals "no" "$([ -e "$ZERO_DIR/$f" ] && echo yes || echo no)" \
    "req-009 (a): old $f is gone"
done

echo ""
echo "=== req-009 (a): new names are in use ==="

has() { grep -qF -- "$1" "$2" && echo yes || echo no; }

assert_equals "yes" "$(has 'standards/pack-update-policy.md' <(cat "$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md" "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md"))" \
  "req-009 (a): orchestrator links pack-update-policy.md"
assert_equals "yes" "$(has '## Updating the pack' "$ZERO_DIR/pipeline-reference.md")" \
  "req-009 (a): pipeline-reference.md has the Updating the pack heading"
assert_equals "yes" "$(has '## Updating the pack' "$ZERO_DIR/project-operations.md")" \
  "req-009 (a): project-operations.md has the Updating the pack heading"
assert_equals "yes" "$(has 'pipeline-reference.md#updating-the-pack' "$ZERO_DIR/project-operations.md")" \
  "req-009 (a): project-operations.md links #updating-the-pack"
assert_equals "yes" "$(has 'project-operations.md#updating-the-pack' "$ZERO_DIR/getting-started.md")" \
  "req-009 (a): getting-started.md links #updating-the-pack"
assert_equals "yes" "$(has 'zeroDir' "$ZERO_DIR/hooks/enforcement/auto-trigger-orchestrator.mjs")" \
  "req-009 (a): auto-trigger-orchestrator.mjs uses zeroDir"
assert_equals "yes" "$(has 'extractPackTable' "$ZERO_DIR/scripts/self-description-check.mjs")" \
  "req-009 (a): self-description-check.mjs uses extractPackTable"
assert_equals "yes" "$(has '$global:ZeroDir' "$ZERO_DIR/tests/helpers/setup-workspace.ps1")" \
  "req-009 (a): setup-workspace.ps1 sets \$global:ZeroDir"

echo ""
echo "=== req-009 (a): the regression manifest lists the renamed test ==="

MANIFEST="$ZERO_DIR/tests/regression/regression-manifest.json"
assert_equals "yes" "$(has '"name": "test-0000005-pack-governance.sh"' "$MANIFEST")" \
  "req-009 (a): manifest name uses the new 0000005 file name"
assert_equals "yes" "$(has '"filePath": "tests/regression/test-0000005-pack-governance.sh"' "$MANIFEST")" \
  "req-009 (a): manifest filePath uses the new 0000005 file name"
assert_equals "yes" "$(has "\"sourceFeature\": \"0000005-${LO}${W}-governance\"" "$MANIFEST")" \
  "req-009 (a): manifest keeps the 0000005 sourceFeature history id"

# Every filePath in the manifest resolves to a file.
missing=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  [ -f "$ZERO_DIR/$p" ] || missing="$missing $p"
done <<< "$(grep -oE '"filePath": "tests/[^"]+"' "$MANIFEST" | sed -E 's/.*: "([^"]+)"/\1/')"
assert_equals "" "$missing" "req-009 (a): every manifest filePath resolves"

echo ""
echo "=== req-009 (b): README heading and the self-description check agree ==="

assert_equals "yes" "$(grep -qx '## The pack' "$REPO_ROOT/README.md" && echo yes || echo no)" \
  "req-009 (b): README.md has the ## The pack heading"
assert_equals "yes" "$(has '## The pack' "$ZERO_DIR/scripts/self-description-check.mjs")" \
  "req-009 (b): self-description-check.mjs looks for ## The pack"
output="$(node "$ZERO_DIR/scripts/self-description-check.mjs" "$REPO_ROOT" 2>&1)"
assert_exit_zero "$?" "req-009 (b): self-description-check.mjs passes against the repository"
assert_contains "match the repository" "$output" "req-009 (b): self-description check reports a clean match"

print_summary
