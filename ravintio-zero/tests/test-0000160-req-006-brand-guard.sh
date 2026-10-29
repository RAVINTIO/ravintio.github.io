#!/usr/bin/env bash
# Tests for feature 0000160-ravintio-rebrand, req-006: the brand guard (ADR-004).
#
# No tracked file outside history uses the retired brand word. This test reads
# `git ls-files`, drops the excluded prefixes, and searches the rest for the
# word, case-insensitive. It checks paths and lines.
#
# A path or line passes only if an allowlist entry covers it. A line entry is a
# path regex and a line regex, and both must match. Any other match fails the
# test, and the test prints the file and line number.
#
# A stale allowlist entry that matches no line also fails the test.
#
# A second case adds the word to a scratch copy of README.md and expects the
# check to flag it. A third case feeds a path with the word to the path check.
#
# This source never writes the word as one token where a scan could match it
# outside its own allowlist entry. Its own path is allowlisted, so it may.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

# Paths that start with these prefixes are history or past records.
EXCLUDED_PREFIXES=(
  "plan/_archive/"                    # archived features: history
  "plan/changelog/"                   # release notes: history
  "ravintio-zero/migrations/_done/"  # applied migrations: past records
  "plan/current/"                     # this feature quotes the old words to describe the rename, until ship archives it
)

# Path allowlist. Each entry is a path regex. No tracked path may name the
# brand word today, so the list is empty. Add an entry with a reason.
PATH_ALLOWLIST=()

# Line allowlist. Each entry is "path regex<TAB>line regex", both extended
# regular expressions and case-sensitive. A line passes when its path matches
# the first part and its text matches the second. "." matches anything.
TAB=$'\t'
ALLOWLIST=(
  # --- Sibling repos that keep their names ---
  # The separate product's repo name and URL.
  "^README\\.md\$${TAB}ravintio/planifest-framework"
  # The docs repo name and its file names, in the README documentation table.
  "^README\\.md\$${TAB}planifest-docs"
  # File names inside the docs repo, linked from the stack evaluation standards.
  "^ravintio-zero/standards/reference/(backend|frontend)-stack-evaluation\\.md\$${TAB}p0[0-9]{2}-planifest-"
  # The frontend evaluation title names its file in the docs repo.
  "^ravintio-zero/standards/reference/frontend-stack-evaluation\\.md\$${TAB}^# p016-planifest-"

  # --- Past feature ids ---
  # Feature ids 0000031 and 0000037 contain the old name. They appear in tests, manifests, backlog entries, and docs.
  ".${TAB}0000031-five-phase-planifest-zero|0000037-self-host-on-planifest-zero"

  # --- Past decisions quoted as they were ---
  # The section headings for the two past features.
  "^docs/decisions-index\\.md\$${TAB}^### Feature 0000(031|037): "
  # Past ADR rows for 0000031 and 0000032 that name the old folders and skills.
  "^docs/decisions-index\\.md\$${TAB}^\\| ADR-00[12] \\| (Folder rename and product identity|The setup-config record lives|Refresh-setup reads the record|Telemetry is not a pack concern) "
  # Superseded-ADR rows that name the old override folder and pack.
  "^docs/decisions-index\\.md\$${TAB}^\\| (0000025 ADR-002|0000018, 0000024, 0000026, 0000027, and 0000028 telemetry ADRs) "
  # Past ADR rows for 0000037 that name the old pack, folder, variable, and hook entries.
  "^docs/decisions-index\\.md\$${TAB}^\\| ADR-00[1-3] \\| (The repo self-hosts|The Bash suites run in CI|Setup repairs the hook entries|Setup filters .* hook commands) "
  # The 0000042 ADR-004 row quotes the retired word it banned.
  "^docs/decisions-index\\.md\$${TAB}^\\| ADR-004 \\| Pack wording and identifier map "

  # --- Tests that read pre-rename history ---
  # The 0000034 test builds a fixture that uses the old pack folder name.
  "^ravintio-zero/tests/(regression/)?test-0000034-req-003-atomic-settings-writes\\.sh\$${TAB}OLD_PACK=\"planifest-zero\""
  # The frozen orchestrator skill base, a byte fixture of the pre-rename text.
  "^ravintio-zero/tests/fixtures/0000151-orchestrator-skill-base\\.md\$${TAB}."
  # The 0000151 test rewrites the frozen fixture to the new names with sed.
  "^ravintio-zero/tests/test-0000151-req-011-orchestrator-references-split\\.sh\$${TAB}^sed -e \"s/PLANIFEST/RAVINTIO/g\"|^  -e \"s/Planifest/RAVINTIO/g\""
  # The 0000042 prose test names the sibling repo and the old folder.
  "^ravintio-zero/tests/test-0000042-req-008-pack-prose\\.sh\$${TAB}planifest-\\\$\\{WORD\\}"
  # The 0000042 wording test names the sibling repo and the old folder in its allowlist.
  "^ravintio-zero/tests/(regression/)?test-0000042-req-010-pack-wording-allowlist\\.sh\$${TAB}planifest\\[-\\]framework"
  # It also allowlists this guard's own entry for that pattern.
  "^ravintio-zero/tests/(regression/)?test-0000042-req-010-pack-wording-allowlist\\.sh\$${TAB}test-0000160-req-006-brand-guard"

  # --- 0.x legacy aliases, removed at 1.0.0 ---
  # The initiative runner stops when an old environment variable name is set (0000189).
  "^ravintio-zero/scripts/initiative-run\\.mjs\$${TAB}PLANIFEST_ROADMAP_(MODEL|MAX_TURNS)|legacy PLANIFEST_\\*"
  # The 0000189 old-variable test sets those names to check the stop.
  "^ravintio-zero/tests/test-0000189-req-006-old-variable-stop\\.sh\$${TAB}PLANIFEST_ROADMAP_(MODEL|MAX_TURNS)"
  # The dependency graph documents the fallback.
  "^docs/dependency-graph\\.md\$${TAB}PLANIFEST_ROADMAP_(MODEL|MAX_TURNS)"
  # The component manifest lists the fallback variables.
  "^ravintio-zero/component\\.yml\$${TAB}PLANIFEST_ROADMAP_(MODEL|MAX_TURNS)"
  # The REQ-003 test checks the fallback, scans for the old variable prefix, and checks no old label is emitted.
  "^ravintio-zero/tests/test-0000160-req-003-.*\\.sh\$${TAB}PLANIFEST_|planifest\\."
  # The em dash guard honours the old sentinel.
  "^ravintio-zero/hooks/enforcement/em-dash-guard\\.mjs\$${TAB}planifest-em-dash-allow"
  # The REQ-002 test checks the old sentinel and the setup leftovers.
  "^ravintio-zero/tests/test-0000160-req-002-.*\$${TAB}planifest-(em-dash-allow|zero|overrides)|\\.planifest-(setup-flags|manifest)"

  # --- Tests that name the 0000030 folder, which 0000031 renamed ---
  "^ravintio-zero/tests/test-0000031-req-00[14]-[a-z-]+\\.sh\$${TAB}^OLD_NAME=\"planifest\"\"-framework\"\$"
  "^ravintio-zero/tests/test-0000037-req-00[14]-[a-z-]+\\.sh\$${TAB}^OLD_FOLDER=\"planifest-\"\"framework\"\$"

  # --- Setup detection of leftover folders and old markers ---
  # Setup detects and reports leftover old folders.
  "^ravintio-zero/setup\\.(sh|ps1)\$${TAB}planifest-(zero|overrides)"
  # Setup removes old markers.
  "^ravintio-zero/setup\\.(sh|ps1)\$${TAB}\\.planifest-(setup-flags|manifest)"

  # --- The rename migration, its helpers, and its tests ---
  # The migration names the old paths on purpose.
  "^ravintio-zero/migrations/0004-ravintio-rename\\.md\$${TAB}."
  # The helpers move the old paths to the new ones.
  "^ravintio-zero/migrations/migrate-ravintio-rename\\.(sh|ps1)\$${TAB}."

  # --- This guard ---
  # This test and its regression copy, which must name the word to match it.
  "^ravintio-zero/tests/(regression/)?test-0000160-req-006-brand-guard\\.sh\$${TAB}."
)

# Hit counts per entry, used by the stale-entry check.
declare -a HITS
for _i in "${!ALLOWLIST[@]}"; do HITS[$_i]=0; done
COUNT_HITS=1

# Returns 0 when an entry covers the line. Counts every covering entry while
# COUNT_HITS is 1, so the stale check sees overlapping entries.
allowed() {
  local path="$1" text="$2" i entry path_re line_re found=1
  for i in "${!ALLOWLIST[@]}"; do
    entry="${ALLOWLIST[$i]}"
    path_re="${entry%%"$TAB"*}"
    line_re="${entry#*"$TAB"}"
    if [[ "$path" =~ $path_re ]] && [[ "$text" =~ $line_re ]]; then
      found=0
      [ "$COUNT_HITS" -eq 1 ] && HITS[$i]=$(( ${HITS[$i]} + 1 ))
    fi
  done
  return "$found"
}

# Reads relative paths on stdin, searches each under root $1, and prints
# "path:line" for every matching line that no allowlist entry covers.
check_lines() {
  local root="$1" path num text hit
  while IFS= read -r path; do
    [ -f "$root/$path" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      num="${hit%%:*}"
      text="${hit#*:}"
      allowed "$path" "$text" || echo "$path:$num"
    done <<< "$(grep -inI -- planifest "$root/$path" 2>/dev/null)"
  done
}

# Reads relative paths on stdin and prints each path that names the word and
# matches no path allowlist entry.
check_paths() {
  local path re ok
  while IFS= read -r path; do
    printf '%s\n' "$path" | grep -qi -- planifest || continue
    ok=1
    for re in ${PATH_ALLOWLIST[@]+"${PATH_ALLOWLIST[@]}"}; do
      [[ "$path" =~ $re ]] && ok=0
    done
    [ "$ok" -eq 0 ] || echo "$path"
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
echo "=== req-006 (a): tracked lines use the word only in allowlisted ways ==="

SCOPE="$(in_scope_files)"
STRAY="$(printf '%s\n' "$SCOPE" | check_lines "$REPO_ROOT")"
# The check ran in a subshell, so count the hits again here in this shell.
while IFS= read -r p; do
  [ -f "$REPO_ROOT/$p" ] || continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    allowed "$p" "${hit#*:}" || true
  done <<< "$(grep -inI -- planifest "$REPO_ROOT/$p" 2>/dev/null)"
done <<< "$SCOPE"
COUNT_HITS=0
if [ -n "$STRAY" ]; then
  echo "  Lines outside the allowlist:"
  printf '    %s\n' $STRAY
fi
assert_equals "" "$STRAY" "req-006 (a): no tracked line outside the allowlist uses the word"

echo ""
echo "=== req-006 (b): no tracked path names the word outside the allowlist ==="

STRAY_PATHS="$(printf '%s\n' "$SCOPE" | check_paths)"
if [ -n "$STRAY_PATHS" ]; then
  echo "  Paths outside the allowlist:"
  printf '    %s\n' $STRAY_PATHS
fi
assert_equals "" "$STRAY_PATHS" "req-006 (b): no tracked path outside the allowlist names the word"

echo ""
echo "=== req-006 (c): every line allowlist entry matches at least one line ==="

STALE=""
for i in "${!ALLOWLIST[@]}"; do
  [ "${HITS[$i]}" -eq 0 ] && STALE="${STALE}entry $i: ${ALLOWLIST[$i]%%"$TAB"*} / ${ALLOWLIST[$i]#*"$TAB"}"$'\n'
done
if [ -n "$STALE" ]; then
  echo "  Stale allowlist entries:"
  printf '    %s\n' "$STALE"
fi
assert_equals "" "$STALE" "req-006 (c): no allowlist entry is stale"

echo ""
echo "=== req-006 (d): a planted line in a scratch README.md fails the check ==="

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
cp "$REPO_ROOT/README.md" "$SCRATCH/README.md"
echo "Planifest Zero is the old name" >> "$SCRATCH/README.md"
PLANTED_LINE="$(wc -l < "$SCRATCH/README.md" | tr -d ' ')"
PLANTED="$(echo "README.md" | check_lines "$SCRATCH")"
assert_contains "README.md:$PLANTED_LINE" "$PLANTED" \
  "req-006 (d): the check flags the planted line with its file and line number"

echo ""
echo "=== req-006 (e): a path that names the word fails the path check ==="

PLANTED_PATH="$(echo "docs/Planifest-notes.md" | check_paths)"
assert_equals "docs/Planifest-notes.md" "$PLANTED_PATH" \
  "req-006 (e): the path check flags a path that names the word"

print_summary
