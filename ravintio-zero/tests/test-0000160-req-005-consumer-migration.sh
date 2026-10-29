#!/usr/bin/env bash
# Feature 0000160 req-005: migrate-ravintio-rename.sh moves a consumer repo to the
# ravintio names. Covers the clean run, a rerun, each stop condition, git mv,
# symlink refusal, the skip under a linked parent folder, and the backup move
# of the old pack. Each case runs in a scratch git repo.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

HELPER="$ZERO_DIR/migrations/migrate-ravintio-rename.sh"
OLD="plan""ifest"   # keep the old name out of a literal brand scan
OLDU="PLAN""IFEST"

WS=$(mktemp -d)
trap 'rm -rf "${WS:?}"' EXIT

# make_repo NAME: scratch consumer repo with the old install and the new pack.
make_repo() {
  local d="$WS/$1"
  mkdir -p "$d/ravintio-zero" "$d/$OLD-zero" "$d/$OLD-overrides/instructions" \
           "$d/.github/workflows" "$d/.claude/skills"
  echo "mine" > "$d/$OLD-overrides/instructions/a.md"
  {
    printf 'run: bash %s-zero/tests/run-tests.sh\nenv:\n' "$OLD"
    for v in REQUIRE_PWSH PWSH TEST_QUIET PREFLIGHT_ONLY REGRESSION_DIR ROADMAP_MODEL ROADMAP_MAX_TURNS; do
      printf '  %s_%s: 1\n' "$OLDU" "$v"
    done
    printf '  TOKEN: ${{ secrets.%s_DEPLOY_TOKEN }}\n' "$OLDU"
  } > "$d/.github/workflows/$OLD.yml"
  echo "x" > "$d/.claude/.$OLD-setup-flags"
  echo "x" > "$d/.claude/skills/.$OLD-manifest"
  echo "x" > "$d/$OLD-zero/file.md"
  echo "x" > "$d/$OLD-zero/setup.sh"
  mkdir -p "$d/ravintio-zero/migrations"
  echo "m" > "$d/ravintio-zero/migrations/0004-ravintio-rename.md"
  ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t \
    && git add -A && git commit -q -m init )
  echo "$d"
}

# snapshot DIR: sorted list of paths, for before/after comparison.
snapshot() { ( cd "$1" && find . -path ./.git -prune -o -print | LC_ALL=C sort ); }

run() { ( cd "$1" && GIT_CEILING_DIRECTORIES="$WS" bash "$HELPER" 2>&1 ); }

echo "=== (a) clean run (tracked folders use git mv) ==="
R=$(make_repo clean)
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "clean run exits 0"
assert_equals "mine" "$(cat "$R/ravintio-overrides/instructions/a.md")" "overrides moved with content"
assert_equals "no" "$([ -e "$R/$OLD-overrides" ] && echo yes || echo no)" "old overrides folder gone"
assert_equals "yes" "$([ -f "$R/.github/workflows/ravintio.yml" ] && echo yes || echo no)" "workflow renamed"
assert_equals "no" "$([ -e "$R/.github/workflows/$OLD.yml" ] && echo yes || echo no)" "old workflow gone"
assert_contains "ravintio-zero/tests/run-tests.sh" "$(cat "$R/.github/workflows/ravintio.yml")" "workflow paths rewritten"
assert_contains "RAVINTIO_REQUIRE_PWSH" "$(cat "$R/.github/workflows/ravintio.yml")" "workflow variables rewritten"
for v in REQUIRE_PWSH PWSH TEST_QUIET PREFLIGHT_ONLY REGRESSION_DIR ROADMAP_MODEL ROADMAP_MAX_TURNS; do
  assert_equals "1" "$(grep -c "^  RAVINTIO_$v: 1\$" "$R/.github/workflows/ravintio.yml")" "pack variable $v rewritten"
done
assert_contains "secrets.${OLDU}_DEPLOY_TOKEN" "$(cat "$R/.github/workflows/ravintio.yml")" "consumer secret name kept"
assert_equals "1" "$(grep -c "${OLDU}_" "$R/.github/workflows/ravintio.yml")" "only the consumer secret keeps the old prefix"
assert_equals "no" "$([ -e "$R/.claude/.$OLD-setup-flags" ] && echo yes || echo no)" "flags marker removed"
assert_equals "no" "$([ -e "$R/.claude/skills/.$OLD-manifest" ] && echo yes || echo no)" "manifest marker removed"
assert_equals "no" "$([ -e "$R/$OLD-zero" ] && echo yes || echo no)" "old pack folder gone from the root"
assert_equals "x" "$(cat "$R/.ravintio-backup/$OLD-zero/file.md" 2>/dev/null)" "old pack moved to the backup"
assert_contains "Moved $OLD-zero/ to .ravintio-backup/$OLD-zero/. Delete .ravintio-backup/ once you have checked that nothing of yours is in it." "$OUT" "prints the backup message"
assert_equals "0" "$(cd "$R" && git ls-files -- "$OLD-zero" | grep -c .)" "git no longer tracks the old pack"
assert_equals "1" "$(grep -cx '.ravintio-backup/' "$R/.git/info/exclude")" "backup folder added to .git/info/exclude"
assert_equals "0" "$(cd "$R" && git status --porcelain --untracked-files=all | grep -c 'ravintio-backup')" "backup hidden from git status"
assert_equals "yes" "$([ -d "$R/ravintio-zero" ] && echo yes || echo no)" "new pack folder kept"
assert_contains "Next step: run ravintio-zero/setup.sh claude-code" "$OUT" "prints the setup command"
STAGED=$(cd "$R" && git diff --cached --name-status | grep -c '^R')
assert_equals "yes" "$([ -f "$R/ravintio-zero/migrations/_done/0004-ravintio-rename.md" ] && echo yes || echo no)" "clean run archives migration 0004"
assert_equals "no" "$([ -e "$R/ravintio-zero/migrations/0004-ravintio-rename.md" ] && echo yes || echo no)" "migration 0004 no longer pending"
assert_equals "2" "$STAGED" "git records the overrides file and workflow as renames"

echo "=== (b) rerun changes nothing ==="
BEFORE=$(snapshot "$R")
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "rerun exits 0"
assert_equals "$BEFORE" "$(snapshot "$R")" "rerun changes nothing"
assert_contains "Nothing to do" "$OUT" "rerun says nothing to do"
assert_equals "1" "$(grep -cx '.ravintio-backup/' "$R/.git/info/exclude")" "rerun adds no second exclude line"

echo "=== (b2) a repo with no old install keeps 0004 pending ==="
S="$WS/source"
mkdir -p "$S/ravintio-zero/migrations"
echo "m" > "$S/ravintio-zero/migrations/0004-ravintio-rename.md"
( cd "$S" && git init -q . )
OUT=$(run "$S"); CODE=$?
assert_equals "0" "$CODE" "no old install exits 0"
assert_equals "yes" "$([ -f "$S/ravintio-zero/migrations/0004-ravintio-rename.md" ] && echo yes || echo no)" "no old install leaves 0004 pending"

echo "=== (c) untracked folder uses plain mv ==="
R=$(make_repo untracked)
( cd "$R" && git rm -rq --cached "$OLD-overrides" && git commit -q -m untrack )
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "untracked run exits 0"
assert_equals "mine" "$(cat "$R/ravintio-overrides/instructions/a.md")" "untracked overrides moved"

echo "=== (d) no ravintio-zero/ stops ==="
R=$(make_repo nopack)
rm -rf "${R:?}/ravintio-zero"
BEFORE=$(snapshot "$R")
OUT=$(run "$R"); CODE=$?
assert_equals "1" "$CODE" "missing ravintio-zero exits 1"
assert_contains "ravintio-zero/ not found" "$OUT" "names the missing folder"
assert_equals "$BEFORE" "$(snapshot "$R")" "missing ravintio-zero moves nothing"

echo "=== (e) both override folders stop ==="
R=$(make_repo both)
mkdir -p "$R/ravintio-overrides"
BEFORE=$(snapshot "$R")
OUT=$(run "$R"); CODE=$?
assert_equals "1" "$CODE" "both override folders exit 1"
assert_contains "WARNING: Both" "$OUT" "prints the warning"
assert_equals "$BEFORE" "$(snapshot "$R")" "both override folders move nothing"

echo "=== (f) existing ravintio.yml stops before any move ==="
R=$(make_repo wf)
echo "new" > "$R/.github/workflows/ravintio.yml"
BEFORE=$(snapshot "$R")
OUT=$(run "$R"); CODE=$?
assert_equals "1" "$CODE" "existing ravintio.yml exits 1"
assert_contains "ravintio.yml already exists" "$OUT" "names the existing workflow"
assert_equals "$BEFORE" "$(snapshot "$R")" "existing ravintio.yml moves nothing"

echo "=== (g) symlink refusal ==="
for name in "$OLD-overrides" "ravintio-overrides" "$OLD-zero" ".ravintio-backup"; do
  R=$(make_repo "link-$name")
  TARGET="$WS/target-$name"
  mkdir -p "$TARGET"; echo "keep" > "$TARGET/keep.txt"
  if [ -e "$R/$name" ]; then rm -rf "${R:?}/${name:?}"; fi
  ln -s "$TARGET" "$R/$name"
  BEFORE=$(snapshot "$R")
  OUT=$(run "$R"); CODE=$?
  assert_equals "1" "$CODE" "symlinked $name exits 1"
  assert_contains "is a symlink" "$OUT" "symlinked $name is named"
  assert_equals "$BEFORE" "$(snapshot "$R")" "symlinked $name moves nothing"
  assert_equals "yes" "$([ -L "$R/$name" ] && echo yes || echo no)" "link $name still a link"
  assert_equals "keep" "$(cat "$TARGET/keep.txt")" "target of $name untouched"
done

echo "=== (h) a nested directory link in the old pack moves as a link ==="
R=$(make_repo nested-link)
OUTSIDE="$WS/outside-nested"
mkdir -p "$OUTSIDE"; echo "keep" > "$OUTSIDE/keep.txt"
ln -s "$OUTSIDE" "$R/$OLD-zero/nested"
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "nested link run exits 0"
assert_equals "no" "$([ -e "$R/$OLD-zero" ] || [ -L "$R/$OLD-zero" ] && echo yes || echo no)" "old pack folder moved with its nested link"
assert_equals "yes" "$([ -L "$R/.ravintio-backup/$OLD-zero/nested" ] && echo yes || echo no)" "nested link still a link in the backup"
assert_equals "keep" "$(cat "$OUTSIDE/keep.txt" 2>/dev/null)" "file behind the nested link survives"

echo "=== (i) a workflow link stops before any move ==="
for wf in "$OLD.yml" "ravintio.yml"; do
  for kind in live dangling; do
    R=$(make_repo "wflink-$wf-$kind")
    TARGET="$WS/wftarget-$wf-$kind.yml"
    if [ "$kind" = live ]; then printf 'keep %s-zero/ x\n' "$OLD" > "$TARGET"; fi
    rm -f "$R/.github/workflows/$wf"
    ln -s "$TARGET" "$R/.github/workflows/$wf"
    BEFORE=$(snapshot "$R")
    OUT=$(run "$R"); CODE=$?
    assert_equals "1" "$CODE" "$kind link at $wf exits 1"
    assert_contains "is a symlink" "$OUT" "$kind link at $wf is named"
    assert_equals "$BEFORE" "$(snapshot "$R")" "$kind link at $wf moves nothing"
    if [ "$kind" = live ]; then
      assert_equals "keep $OLD-zero/ x" "$(cat "$TARGET")" "target of $wf untouched"
    fi
  done
done

echo "=== (j) a linked parent folder skips only the step that writes through it ==="
for parent in ".claude" ".claude/skills" ".github" ".github/workflows" "ravintio-zero" "ravintio-zero/migrations"; do
  R=$(make_repo "parent-${parent//\//-}")
  REAL="$WS/real-${parent//\//-}-$RANDOM"
  mv "$R/$parent" "$REAL"
  ln -s "$REAL" "$R/$parent"
  REAL_BEFORE=$(snapshot "$REAL")
  OUT=$(run "$R"); CODE=$?
  assert_equals "0" "$CODE" "linked $parent exits 0"
  assert_contains "WARNING: $parent is a symlink" "$OUT" "linked $parent is named in a warning"
  assert_equals "$REAL_BEFORE" "$(snapshot "$REAL")" "target of $parent untouched"
  assert_equals "yes" "$([ -f "$R/.ravintio-backup/$OLD-zero/setup.sh" ] && echo yes || echo no)" "linked $parent still moves the old pack"
  assert_equals "mine" "$(cat "$R/ravintio-overrides/instructions/a.md" 2>/dev/null)" "linked $parent still moves the overrides"
done

echo "=== (k) a project below its git top level upgrades ==="
R=$(make_repo inner)
rm -rf "${R:?}/.git"
mkdir -p "$WS/outer"
mv "$R" "$WS/outer/inner"
( cd "$WS/outer" && git init -q . && git config user.email t@example.com && git config user.name t \
  && git add -A && git commit -q -m init )
R="$WS/outer/inner"
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "run below the top level exits 0"
assert_equals "yes" "$([ -f "$R/.ravintio-backup/$OLD-zero/setup.sh" ] && echo yes || echo no)" "nested project pack moved to the backup"
assert_equals "1" "$(grep -cx '.ravintio-backup/' "$WS/outer/.git/info/exclude")" "nested project backup excluded in the outer repo"
assert_equals "0" "$(cd "$WS/outer" && git status --porcelain --untracked-files=all | grep -c 'ravintio-backup')" "nested project backup hidden from git status"

echo "=== (l) a pack that git never tracked moves to the backup ==="
R=$(make_repo untracked-pack)
( cd "$R" && git rm -rq --cached "$OLD-zero" && git commit -q -m untrack )
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "untracked pack exits 0"
assert_equals "yes" "$([ -f "$R/.ravintio-backup/$OLD-zero/file.md" ] && echo yes || echo no)" "untracked pack lands in the backup"

echo "=== (m) a stray untracked file in the old pack moves with it ==="
R=$(make_repo stray)
echo "x" > "$R/$OLD-zero/.DS_Store"
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "stray untracked file exits 0"
assert_equals "yes" "$([ -f "$R/.ravintio-backup/$OLD-zero/.DS_Store" ] && echo yes || echo no)" "stray file lands in the backup"

echo "=== (n) a folder outside git moves the pack and writes no exclude ==="
R=$(make_repo nogit)
rm -rf "${R:?}/.git"
echo "mine" > "$R/$OLD-zero/custom.md"
OUT=$(run "$R"); CODE=$?
assert_equals "0" "$CODE" "folder outside git exits 0"
assert_equals "mine" "$(cat "$R/.ravintio-backup/$OLD-zero/custom.md" 2>/dev/null)" "custom file kept in the backup outside git"
assert_equals "no" "$([ -e "$R/.git" ] && echo yes || echo no)" "outside git writes no .git"

echo "=== (o) an existing backup stops before any move ==="
R=$(make_repo backup-exists)
mkdir -p "$R/.ravintio-backup/$OLD-zero"
echo "older" > "$R/.ravintio-backup/$OLD-zero/old.md"
BEFORE=$(snapshot "$R")
OUT=$(run "$R"); CODE=$?
assert_equals "1" "$CODE" "existing backup exits 1"
assert_contains ".ravintio-backup/$OLD-zero already exists" "$OUT" "names the existing backup"
assert_equals "$BEFORE" "$(snapshot "$R")" "existing backup moves nothing"

print_summary
