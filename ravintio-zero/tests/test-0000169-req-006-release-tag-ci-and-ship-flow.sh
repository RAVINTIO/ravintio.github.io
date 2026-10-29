#!/usr/bin/env bash
# 0000169 req-006: release-tag-ci-and-ship-flow
# CI tags the merge commit on main. Ship creates no tag and the docs agree.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"
REF="$ZERO_DIR/pipeline-reference.md"
OPS="$ZERO_DIR/project-operations.md"
C004="$ROOT/ravintio-overrides/instructions/custom-004-ship-push-and-raise-pr.md"
WF_REPO="$ROOT/.github/workflows/ravintio.yml"
WF_TPL="$ZERO_DIR/hooks/ravintio.yml"

section() { awk -v h="$1" '
    $0 == h { on = 1; lvl = index(h, " "); next }
    on && /^#+ / { if (index($0, " ") <= lvl) exit }
    on { print }' "$2"; }
has() { printf '%s\n' "$2" | grep -qF -- "$1" && echo yes || echo no; }

echo ""
echo "=== 0000169 req-006 release-tag-ci-and-ship-flow ==="

# YAML checks with ruby, skipped with a note if ruby is missing
if command -v ruby >/dev/null 2>&1; then
  for wf in "$WF_REPO" "$WF_TPL"; do
    n="$(basename "$(dirname "$wf")")/$(basename "$wf")"
    out="$(ruby -ryaml -e '
      d = YAML.load_file(ARGV[0])
      on = d["on"] || d[true] || {}
      r = []
      r << "push" unless on.is_a?(Hash) && on["push"] && on["push"]["branches"] == ["main", "master"]
      jobs = d["jobs"]
      rt = jobs["release-tag"]
      if rt.nil? then r << "nojob" else
        r << "ifpush" unless rt["if"] == "github.event_name == \x27push\x27"
        r << "write" unless rt.dig("permissions", "contents") == "write"
        s = rt["steps"]
        r << "depth" unless s.any? { |x| x.dig("with", "fetch-depth") == 0 }
        r << "bot" unless s.to_s.include?("41898282+github-actions[bot]@users.noreply.github.com")
        r << "cmd" unless s.any? { |x| x["run"].to_s.include?("node ravintio-zero/scripts/release-tag.mjs") }
      end
      jobs.each do |k, j|
        next if k == "release-tag"
        r << "guard-#{k}" unless j["if"] == "github.event_name == \x27pull_request\x27"
        r << "write-#{k}" if j.dig("permissions", "contents") == "write"
      end
      r << "toplevel" unless d.dig("permissions", "contents") == "read"
      puts r.join(",")
    ' "$wf" 2>&1)"
    assert_equals "" "$out" "$n parses with push trigger, release-tag job, and guarded jobs"
  done
else
  echo "  NOTE: ruby not found, skipping YAML parse assertions"
fi

S7="$(section '### Step 7: Release tag' "$SHIP")"
S9="$(section '### Step 9: PR' "$SHIP")"
S10="$(section '### Step 10: Final gate' "$SHIP")"
assert_equals "no" "$(has 'git tag' "$S7")" "Step 7 holds no git tag command"
assert_equals "yes" "$(has 'CI' "$S7")" "Step 7 says CI tags"
assert_equals "yes" "$(has 'CI tags' "$S9")" "Step 9 names CI tagging on main"
assert_equals "yes" "$(has 'git tag v{version} -m "{feature-id}" {merge-commit}' "$S9")" "Step 9 prints the local-git-only tag command"
assert_equals "no" "$(has 'git push origin v{version}' "$(printf '%s\n' "$S9" | sed -n '/option \[1\], push/,/^```$/p' | sed -n '1,8p')")" "Step 9 option [1] pushes no tag"
assert_equals "yes" "$(has 'main' "$(printf '%s\n' "$S10" | grep 'Tag:')")" "Step 10 summary names the tag landing on main"
assert_equals "yes" "$(has 'I-D Advance' "$(section '## Initiative steps' "$SHIP")")" "Initiative steps still points at I-D Advance"

SS="$(section '## Ship stages' "$STD")"
assert_equals "no" "$(has 'tag at Step 7' "$SS")" "roadmap-standards no longer says Step 7 tags"
assert_equals "yes" "$(has 'git tag v{version} -m "{feature-id}" "$sha"' "$(section '### I-D Advance' "$STD")")" "I-D Advance still tags the squash commit"
assert_equals "yes" "$(has 'release-tag' "$(cat "$REF")")" "pipeline-reference names the release-tag job"
assert_equals "yes" "$(has 'release-tag' "$(cat "$OPS")")" "project-operations names the release-tag job"
assert_equals "no" "$(has 'and the release tag' "$(cat "$C004")")" "custom-004 drops the release tag push"
assert_equals "yes" "$(has 'CI tags' "$(cat "$C004")")" "custom-004 says CI tags the merge commit"

print_summary
