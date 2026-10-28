#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-008: pack
# prose.
#
# Prose in the files that req-008 names says "RAVINTIO Zero", "the pack", or
# "the pipeline". It never calls RAVINTIO Zero by the old word. Generic uses
# (test and web stacks, the separate RAVINTIO product) stay. This test builds
# the old word from two parts, so it never matches its own source.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"

WORD="frame""work"
CAP="Frame""work"

# Generic uses that stay. Each pattern names a stack, a test tool, or the
# separate product, never RAVINTIO Zero.
GENERIC=(
  "test[- ]${WORD}"                       # test tools and their library standards
  "testing ${WORD}"                       # the testing tool a project declares
  "meta-${WORD}"                          # React meta tools such as Next.js
  "language or ${WORD} in use"            # formatting-standards.md
  "independent of language or ${WORD}"    # code-quality-standards.md
  "where the ${WORD} expects it"          # code-quality-standards.md naming rule
  "${WORD} internals"                     # testing-standards.md
  "[Ww]eb ${WORD}"                        # the web layer in a user's stack
  "[Ff]rontend ${WORD}"                   # the frontend layer in a user's stack
  "stack\\.(${WORD}|frontend|testing)"    # component-guide.md stack fields
  "^[0-9]+:[[:space:]]*${WORD}:"           # the stack field in YAML templates
  "\\| ${CAP} \\|"                      # stack tables in templates and standards
  "${CAP}-specific terms"               # domain-glossary-guide.md
  "RAVINTIO ${CAP}"                    # the separate product
  "ravintio/planifest-${WORD}"           # the separate product's repo
  "planifest-${WORD}/"                    # the old folder that 0000030 renamed
  "${WORD}-cut-down"                      # the 0000030 feature id
)

FILES=(
  README.md
  docs/about.md
  docs/architecture-overview.md
  docs/dependency-graph.md
  docs/decisions-index.md
  plan/feature-structure.md
  plan/README.md
  .github/workflows/ravintio.yml
  ravintio-zero/pipeline-reference.md
  ravintio-zero/project-operations.md
  ravintio-zero/getting-started.md
  ravintio-zero/component.yml
  ravintio-zero/setup.sh
  ravintio-zero/setup.ps1
  ravintio-zero/hooks/enforcement/ratchet-check.mjs
  ravintio-zero/templates/component-guide.md
  ravintio-zero/templates/standard-boot.md
  ravintio-zero/templates/feature-brief.template.md
  ravintio-zero/templates/domain-glossary-guide.md
  ravintio-zero/templates/component.template.yml
  ravintio-zero/templates/loop-toggles.template.yml
  ravintio-zero/skills/ravintio-migrator/SKILL.md
  ravintio-zero/skills/ravintio-optimise-agent/SKILL.md
  ravintio-zero/skills/ravintio-ship/SKILL.md
  ravintio-zero/skills/ravintio-test-writer/SKILL.md
  ravintio-zero/skills/ravintio-loop-runner/SKILL.md
  ravintio-zero/skills/ravintio-orchestrator/SKILL.md
  ravintio-zero/skills/ravintio-implement/SKILL.md
  ravintio-zero/skills/ravintio-validate-and-accept/SKILL.md
  ravintio-zero/skills/ravintio-refresh-setup/SKILL.md
  ravintio-zero/skills/ravintio-file-backlog/SKILL.md
  ravintio-zero/standards/language-quirks-en-gb.md
  ravintio-zero/standards/code-quality-standards.md
  ravintio-zero/standards/formatting-standards.md
  ravintio-zero/standards/stack-summary.md
  ravintio-zero/standards/pack-update-policy.md
  ravintio-zero/tests/README.md
  ravintio-zero/tests/helpers/assert.sh
)

generic_re="$(IFS='|'; echo "${GENERIC[*]}")"

# Prints file:line for each line in $1 that uses the old word and matches no
# generic pattern.
stray() {
  local f="$1"
  [ -f "$REPO_ROOT/$f" ] || return 0
  grep -niE -- "$WORD" "$REPO_ROOT/$f" \
    | grep -vE -- "$generic_re" \
    | cut -d: -f1 | sed "s|^|$f:|"
}

echo ""
echo "=== req-008 (a): README.md and docs/about.md ==="

assert_equals "" "$(stray README.md)" "req-008 (a): README.md never calls RAVINTIO Zero by the old word"
assert_equals "" "$(stray docs/about.md)" "req-008 (a): docs/about.md never calls RAVINTIO Zero by the old word"
assert_equals "yes" "$(grep -qiE "distinct from .*ravintio/planifest-${WORD}" "$REPO_ROOT/README.md" && echo yes || echo no)" \
  "req-008 (a): README.md says RAVINTIO Zero is distinct from the separate product"

echo ""
echo "=== req-008 (b): prose in the listed files ==="

for f in "${FILES[@]}"; do
  case "$f" in README.md|docs/about.md) continue ;; esac
  assert_equals "" "$(stray "$f")" "req-008 (b): $f never calls RAVINTIO Zero by the old word"
done

assert_equals "yes" "$(grep -qF "the pack's own behaviour" "$ZERO_DIR/component.yml" && echo yes || echo no)" \
  "req-008 (b): component.yml says the pack's own behaviour"

echo ""
echo "=== req-008 (c): generic uses stay ==="

count="$(git -C "$REPO_ROOT" ls-files "ravintio-zero/standards/library-standards/*/test-${WORD}s.md" | wc -l | tr -d ' ')"
assert_equals "21" "$count" "req-008 (c): 21 test-tool library standards remain"
for f in backend-stack-evaluation.md frontend-stack-evaluation.md; do
  n="$(grep -ciE -- "$WORD" "$ZERO_DIR/standards/reference/$f")"
  assert_equals "yes" "$([ "$n" -gt 40 ] && echo yes || echo no)" \
    "req-008 (c): $f keeps its web stack wording ($n lines)"
done
assert_equals "yes" "$(grep -qE "^[[:space:]]*${WORD}:" "$ZERO_DIR/templates/component.template.yml" && echo yes || echo no)" \
  "req-008 (c): component.template.yml keeps the stack web-layer field"

print_summary
