#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-010: the
# framework allowlist test (ADR-004).
#
# No tracked file outside history names or describes RAVINTIO Zero as a
# framework. This test reads `git ls-files`, drops the excluded prefixes, and
# searches the rest for "framework", case-insensitive. A matching line passes
# only if it matches an allowlist entry below. Any other line fails the test,
# and the test prints the file and line number.
#
# A second case adds "RAVINTIO Zero is a framework" to a scratch copy of
# README.md and expects the check to flag it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

# Paths that start with these prefixes are history or past records.
EXCLUDED_PREFIXES=(
  "plan/_archive/"                    # archived features: history
  "plan/changelog/"                   # release notes: history
  "ravintio-zero/migrations/_done/"  # applied migrations: past records
  "plan/current/"                     # this feature quotes the old words to describe the rename, until ship archives it
)

# Allowlist. Each entry is "path regex<TAB>line regex", both extended regular
# expressions and case-sensitive. A line passes when its path matches the
# first part and its text matches the second. "." matches anything.
TAB=$'\t'
ALLOWLIST=(
  # The 21 test-frameworks.md standards: test tools, not RAVINTIO Zero.
  "^ravintio-zero/standards/library-standards/.*/test-frameworks\\.md\$${TAB}."
  # Links and paths to those standards.
  ".${TAB}test-frameworks\\.md"
  # The two stack evaluation standards: web, API, and UI frameworks.
  "^ravintio-zero/standards/reference/(backend|frontend)-stack-evaluation\\.md\$${TAB}."
  # The web framework tables in the prefer-avoid.md standards: headings and table rows.
  "^ravintio-zero/standards/library-standards/.*/prefer-avoid\\.md\$${TAB}^(## Web Framework|\\|)"
  # The frontend ranking table in the stack summary names UI frameworks.
  "^ravintio-zero/standards/stack-summary\\.md\$${TAB}^\\| Rank \\| Framework \\|"
  # React meta-frameworks such as Next.js.
  ".${TAB}[Mm]eta-framework"
  # A project's test framework.
  ".${TAB}[Tt]est framework"
  # A project's testing framework.
  ".${TAB}[Tt]esting framework"
  # The language or framework a project uses, in the formatting standards.
  ".${TAB}language or framework in use"
  # Code quality rules that name a project's language or web framework.
  "^ravintio-zero/standards/code-quality-standards\\.md\$${TAB}(independent of language or framework|where the framework expects it)"
  # Testing rule about a project's framework internals.
  "^ravintio-zero/standards/testing-standards\\.md\$${TAB}framework internals"
  # Glossary guide: terms that belong to a web framework, not the domain.
  "^ravintio-zero/templates/domain-glossary-guide\\.md\$${TAB}Framework-specific terms"
  # The stack table in the feature brief names a web framework.
  "^ravintio-zero/templates/feature-brief\\.template\\.md\$${TAB}^\\| Framework \\| \\{\\{"
  # The stack.framework, stack.frontend, and stack.testing rows in the component guide.
  "^ravintio-zero/templates/component-guide\\.md\$${TAB}stack\\.(framework|frontend|testing)"
  # The stack framework: field in component manifests names a web framework.
  "^(ravintio-zero/templates/component\\.template\\.yml|ravintio-zero/component\\.yml)\$${TAB}^[[:space:]]*framework:"
  # The separate product RAVINTIO Framework.
  ".${TAB}RAVINTIO Framework"
  # The separate product's repo.
  ".${TAB}ravintio/planifest[-]framework"
  # The old folder of the RAVINTIO Framework copy, which 0000030 renamed and 0000037 removed.
  ".${TAB}planifest[-]framework/|\"planifest-\"\"framework\"|\"planifest\"\"-framework\""
  # History ids of promoted tests in the regression manifest.
  "^ravintio-zero/tests/regression/regression-manifest\\.json\$${TAB}\"sourceFeature\": \"[0-9]{7}-framework-"
  # The 0000030 feature id framework-cut-down in the decisions index.
  "^docs/decisions-index\\.md\$${TAB}framework-cut-down"
  # The 0000160 brand guard allowlist names the old folder pattern.
  "^ravintio-zero/tests/test-0000160-req-006-brand-guard\\.sh\$${TAB}planifest.{1,8}framework"
  # This test and its regression copy, which must name the word to match it.
  "^ravintio-zero/tests/(regression/)?test-0000042-req-010-pack-wording-allowlist\\.sh\$${TAB}."
)

allowed() {
  local path="$1" text="$2" entry path_re line_re
  for entry in "${ALLOWLIST[@]}"; do
    path_re="${entry%%"$TAB"*}"
    line_re="${entry#*"$TAB"}"
    if [[ "$path" =~ $path_re ]] && [[ "$text" =~ $line_re ]]; then
      return 0
    fi
  done
  return 1
}

# Reads relative paths on stdin, searches each under root $1, and prints
# "path:line" for every matching line that no allowlist entry covers.
check_lines() {
  local root="$1" path num text
  while IFS= read -r path; do
    [ -f "$root/$path" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      num="${hit%%:*}"
      text="${hit#*:}"
      allowed "$path" "$text" || echo "$path:$num"
    done <<< "$(grep -inI -- framework "$root/$path" 2>/dev/null)"
  done
}

in_scope_files() {
  local path prefix keep
  git -C "$REPO_ROOT" ls-files | while IFS= read -r path; do
    keep=1
    for prefix in "${EXCLUDED_PREFIXES[@]}"; do
      case "$path" in "$prefix"*) keep=0; break ;; esac
    done
    [ "$keep" -eq 1 ] && echo "$path"
  done
}

echo ""
echo "=== req-010 (a): tracked files use the word only in allowlisted ways ==="

STRAY="$(in_scope_files | check_lines "$REPO_ROOT")"
if [ -n "$STRAY" ]; then
  echo "  Lines outside the allowlist:"
  printf '    %s\n' $STRAY
fi
assert_equals "" "$STRAY" "req-010 (a): no tracked line outside the allowlist uses the word"

echo ""
echo "=== req-010 (b): a planted line in a scratch README.md fails the check ==="

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
cp "$REPO_ROOT/README.md" "$SCRATCH/README.md"
echo "RAVINTIO Zero is a framework" >> "$SCRATCH/README.md"
PLANTED_LINE="$(wc -l < "$SCRATCH/README.md" | tr -d ' ')"
PLANTED="$(echo "README.md" | check_lines "$SCRATCH")"
assert_contains "README.md:$PLANTED_LINE" "$PLANTED" \
  "req-010 (b): the check flags the planted line with its file and line number"

print_summary
