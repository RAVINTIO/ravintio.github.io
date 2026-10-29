#!/usr/bin/env bash
# 0000189 req-007: old-name-guard
# Searches tracked files for the names that 0000189 retired and fails on any
# hit outside the allowlist. A planted name in a temporary repo must fail too.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo ""
echo "=== 0000189 req-007 old-name-guard ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

# One alternative per old name in the design Names table. The branch pattern
# skips plan/roadmap/, which keeps its name. The prefix match needs a non-word
# character on each side, so risk ids such as R-001 never match. 0000192 adds
# the runner lock and the archive folder pattern.
OLD_NAMES='roadmap-runner\.lock|\{slug\}-roadmap-\{date\}|current-roadmap|roadmap-run\.mjs|roadmap-labels\.mjs|roadmap-entry\.template|\.roadmap-logs|RAVINTIO_ROADMAP_|work\.kind=roadmap|ravintio\.roadmap|(^|[^A-Za-z0-9/._-])roadmap/(\*|\{|[0-9])|(^|[^A-Za-z0-9_-])R-[A-E]([^A-Za-z0-9_]|$)'

# Folders that hold history.
ALLOW_DIRS='plan/_archive/
plan/changelog/'

# Files that must name an old name to do their job.
ALLOW_FILES='ravintio-zero/scripts/initiative-run.mjs
ravintio-zero/component.yml
ravintio-zero/migrations/0005-initiative-rename.md
ravintio-zero/migrations/migrate-initiative-rename.sh
ravintio-zero/migrations/migrate-initiative-rename.ps1
ravintio-zero/tests/test-0000189-req-002-renamed-names.sh
ravintio-zero/tests/test-0000189-req-003-initiative-prefixes.sh
ravintio-zero/tests/test-0000189-req-005-consumer-migration.sh
ravintio-zero/tests/test-0000189-req-006-old-variable-stop.sh
ravintio-zero/tests/test-0000189-req-007-old-name-guard.sh
ravintio-zero/tests/test-0000189-req-008-open-backlog-entries.sh'

allowed() {
  local f="$1" d
  if printf '%s\n' "$ALLOW_FILES" | grep -qxF -- "$f"; then return 0; fi
  while IFS= read -r d; do
    case "$f" in "$d"*) return 0 ;; esac
  done <<EOF
$ALLOW_DIRS
EOF
  return 1
}

# Prints each hit outside the allowlist as path:line and returns 1 if any.
guard() {
  local root="$1" hits=0 line f
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    f="${line%%:*}"
    if ! allowed "$f"; then
      printf '    %s\n' "$(printf '%s' "$line" | cut -d: -f1-2)"
      hits=1
    fi
  done <<EOF
$(git -C "$root" grep -n -I -E -- "$OLD_NAMES" 2>/dev/null)
EOF
  return $hits
}

ok=1
if guard "$REPO_DIR"; then ok=0; fi
check "req-007 AC-1: 0 old names outside the allowlist" "$ok"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/ravintio-zero/skills/demo"
printf 'line one\nRead plan/current-roadmap/ first.\n' > "$TMP/ravintio-zero/skills/demo/SKILL.md"
git -C "$TMP" init -q
git -C "$TMP" add ravintio-zero/skills/demo/SKILL.md
out="$(guard "$TMP")"; rc=$?
ok=1
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF 'ravintio-zero/skills/demo/SKILL.md:2'; then ok=0; fi
check "req-007 AC-2: a planted old name fails and names its file and line" "$ok"

for planted in 'Lock: plan/.roadmap-runner.lock' 'Archive to plan/_archive/{id}-{slug}-roadmap-{date}/.'; do
  printf 'line one\n%s\n' "$planted" > "$TMP/ravintio-zero/skills/demo/SKILL.md"
  git -C "$TMP" add ravintio-zero/skills/demo/SKILL.md
  out="$(guard "$TMP")"; rc=$?
  ok=1
  if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qF 'ravintio-zero/skills/demo/SKILL.md:2'; then ok=0; fi
  check "0000192 req-003 AC-2: planted '$planted' fails and names its file and line" "$ok"
done

printf 'line one\nSee plan/_archive/0000168-backlog-clearance-roadmap-2026-10-25/.\n' > "$TMP/ravintio-zero/skills/demo/SKILL.md"
git -C "$TMP" add ravintio-zero/skills/demo/SKILL.md
ok=1
if guard "$TMP" >/dev/null; then ok=0; fi
check "0000192 req-003: a real archive folder name does not match" "$ok"

print_summary
