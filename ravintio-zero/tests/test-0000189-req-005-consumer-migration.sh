#!/usr/bin/env bash
# Feature 0000189 req-005: migration 0005 moves a consumer's drafts, CI pattern,
# and log folder to the initiative names. Covers AC-1 (rename), AC-2 (stop while
# plan/current-roadmap/ exists), and AC-3 (rerun changes nothing), once per
# helper. The PowerShell half skips when pwsh is absent. Old names appear here
# on purpose: the brand guard allowlists this file.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

MIGRATION="$ZERO_DIR/migrations/0005-initiative-rename.md"
SH_HELPER="$ZERO_DIR/migrations/migrate-initiative-rename.sh"
PS_HELPER="$ZERO_DIR/migrations/migrate-initiative-rename.ps1"

WS=$(mktemp -d)
trap 'rm -rf "${WS:?}"' EXIT

# make_repo NAME: scratch consumer repo with a draft, the CI pattern, and logs.
make_repo() {
  local d="$WS/$1"
  mkdir -p "$d/ravintio-zero/migrations" "$d/plan/roadmap/0000001-demo" \
           "$d/plan/.roadmap-logs" "$d/.github/workflows"
  echo "draft" > "$d/plan/roadmap/0000001-demo/roadmap.md"
  echo "log" > "$d/plan/.roadmap-logs/run.log"
  printf 'on:\n  push:\n    branches: ["roadmap/**"]\n' > "$d/.github/workflows/ravintio.yml"
  echo "m" > "$d/ravintio-zero/migrations/0005-initiative-rename.md"
  ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t \
    && git add -A && git commit -q -m init )
  echo "$d"
}

# snapshot DIR: sorted paths with checksums, for before/after comparison.
snapshot() {
  ( cd "$1" && find . -path ./.git -prune -o -type f -exec cksum {} + | LC_ALL=C sort
    find . -path ./.git -prune -o -print | LC_ALL=C sort )
}

run_sh() { ( cd "$1" && GIT_CEILING_DIRECTORIES="$WS" bash "$SH_HELPER" 2>&1 ); }
run_ps() { ( cd "$1" && GIT_CEILING_DIRECTORIES="$WS" pwsh -NoProfile -File "$PS_HELPER" 2>&1 ); }

echo "=== files exist ==="
assert_equals "yes" "$([ -f "$MIGRATION" ] && echo yes || echo no)" "migration file exists"
assert_equals "yes" "$([ -f "$SH_HELPER" ] && echo yes || echo no)" "Bash helper exists"
assert_equals "yes" "$([ -f "$PS_HELPER" ] && echo yes || echo no)" "PowerShell helper exists"
if [ -f "$MIGRATION" ]; then
  M=$(cat "$MIGRATION")
  assert_contains "**Applies when:**" "$M" "migration has an Applies when line"
  assert_contains "plan/roadmap/*/roadmap.md" "$M" "Applies when names the draft file"
  assert_contains "**Safe to skip:** No" "$M" "migration is not safe to skip"
fi

# check_helper LABEL RUNNER: AC-1, AC-2, AC-3 for one helper.
check_helper() {
  local label="$1" runner="$2" R OUT CODE BEFORE

  echo "=== AC-1 ($label): rename drafts, CI pattern, and logs ==="
  R=$(make_repo "ac1-$label")
  OUT=$($runner "$R"); CODE=$?
  assert_equals "0" "$CODE" "$label: clean run exits 0"
  assert_equals "draft" "$(cat "$R/plan/roadmap/0000001-demo/initiative.md" 2>/dev/null)" "$label: draft renamed with content"
  assert_equals "no" "$([ -e "$R/plan/roadmap/0000001-demo/roadmap.md" ] && echo yes || echo no)" "$label: old draft file gone"
  assert_contains "initiative/**" "$(cat "$R/.github/workflows/ravintio.yml")" "$label: CI pattern renamed"
  assert_equals "0" "$(grep -c 'roadmap/\*\*' "$R/.github/workflows/ravintio.yml")" "$label: old CI pattern gone"
  assert_equals "log" "$(cat "$R/plan/.initiative-logs/run.log" 2>/dev/null)" "$label: log folder renamed"
  assert_equals "no" "$([ -e "$R/plan/.roadmap-logs" ] && echo yes || echo no)" "$label: old log folder gone"

  echo "=== AC-3 ($label): rerun changes nothing ==="
  BEFORE=$(snapshot "$R")
  OUT=$($runner "$R"); CODE=$?
  assert_equals "0" "$CODE" "$label: rerun exits 0"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$label: rerun leaves the tree unchanged"

  echo "=== AC-2 ($label): stop while plan/current-roadmap/ exists ==="
  R=$(make_repo "ac2-$label")
  mkdir -p "$R/plan/current-roadmap"
  echo "active" > "$R/plan/current-roadmap/roadmap.md"
  BEFORE=$(snapshot "$R")
  OUT=$($runner "$R"); CODE=$?
  assert_equals "1" "$([ "$CODE" -ne 0 ] && echo 1 || echo 0)" "$label: exits non-zero"
  assert_contains "plan/current-roadmap/" "$OUT" "$label: names plan/current-roadmap/"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$label: changes no file"

  echo "=== conflict ($label): initiative.md already present ==="
  R=$(make_repo "conflict-$label")
  echo "other" > "$R/plan/roadmap/0000001-demo/initiative.md"
  BEFORE=$(snapshot "$R")
  OUT=$($runner "$R"); CODE=$?
  assert_equals "1" "$([ "$CODE" -ne 0 ] && echo 1 || echo 0)" "$label: conflict exits non-zero"
  assert_contains "plan/roadmap/0000001-demo" "$OUT" "$label: names the conflicting folder"
  assert_equals "$BEFORE" "$(snapshot "$R")" "$label: conflict changes no file"

  echo "=== symlink ($label): refuse a linked draft ==="
  R=$(make_repo "link-$label")
  ( cd "$R/plan/roadmap/0000001-demo" && rm roadmap.md && ln -s /etc/hostname roadmap.md )
  OUT=$($runner "$R"); CODE=$?
  assert_equals "1" "$([ "$CODE" -ne 0 ] && echo 1 || echo 0)" "$label: symlink exits non-zero"
  assert_contains "symlink" "$OUT" "$label: names the symlink"
  assert_equals "no" "$([ -e "$R/plan/.initiative-logs" ] && echo yes || echo no)" "$label: moved nothing"
}

check_helper bash run_sh

if command -v pwsh >/dev/null 2>&1; then
  check_helper pwsh run_ps
else
  echo "SKIP: pwsh not installed, PowerShell half not run"
fi

print_summary
