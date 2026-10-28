#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when the orchestrator loses the park command, parked pickup, or park.mjs stops keeping work safe.
# Tests for feature 0000040-setup-json-checks-and-park, req-004 and req-005:
# park shelves a feature on its branch and files a parked backlog entry
# through a chore PR (ADR-005). Backlog pickup resumes or discards it.
# The behaviour tests run park.mjs against a local bare remote with a stub gh.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
ORCH="$(orch_combined "$ROOT/skills/ravintio-orchestrator")"
PARK="$ROOT/skills/ravintio-orchestrator/scripts/park.mjs"
PARK_TPL="$ROOT/templates/park.template.md"
ENTRY_TPL="$ROOT/templates/backlog-entry.template.md"
S=$(cat "$ORCH")
PARK_SEC=$(printf '%s\n' "$S" | sed -n '/^## Park Command/,/^# Orchestrator reference:/p')
RESUME_SEC=$(printf '%s\n' "$S" | sed -n '/^## Resume Detection/,/^## Pack Index/p')$'\n'$(cat "$ROOT/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md")
STEP10=$(printf '%s\n' "$S" | sed -n '/^10\. \*\*Backlog pickup\*\*/,/^11\. /p')

echo "=== req-004: the skill has a Park Command section after Pause Command ==="
PAUSE_LINE=$(grep -n '^## Pause Command' "$ORCH" | cut -d: -f1)
PARK_LINE=$(grep -n '^## Park Command' "$ORCH" | cut -d: -f1)
if [ -n "$PARK_LINE" ] && [ -n "$PAUSE_LINE" ] && [ "$PARK_LINE" -gt "$PAUSE_LINE" ]; then
  assert_equals "after" "after" "req-004: Park Command follows Pause Command"
else
  assert_equals "after" "missing or before" "req-004: Park Command follows Pause Command"
fi
assert_contains '"park"' "$PARK_SEC" "req-004: the section runs when the human says park"

echo "=== req-004: the five park steps appear in order ==="
STEPS=$(printf '%s\n' "$PARK_SEC" | grep -E '^[1-5]\. ' | cut -c1-2 | tr -d '\n')
assert_equals "1.2.3.4.5." "$STEPS" "req-004: Park Command lists five numbered steps"
step() { printf '%s\n' "$PARK_SEC" | grep -E "^$1\. "; }
assert_contains 'park.template.md' "$(step 1)" "req-004: step 1 reads the park template"
assert_contains 'plan/current/park.md' "$(step 1)" "req-004: step 1 writes plan/current/park.md"
assert_contains 'push the feature branch' "$(step 2)" "req-004: step 2 commits park.md and pushes the feature branch"
assert_contains 'chore/park-{feature-id}' "$(step 3)" "req-004: step 3 cuts the chore branch"
assert_contains '`parked`' "$(step 3)" "req-004: step 3 adds a parked entry"
assert_contains 'gh pr create' "$(step 4)" "req-004: step 4 raises the chore PR"
assert_contains 'Check out `main`' "$(step 5)" "req-004: step 5 checks out main"
assert_contains 'scripts/park.mjs' "$PARK_SEC" "req-004: the section calls park.mjs"

echo "=== req-004: the park rules ==="
assert_contains 'If `plan/current/design.md` does not exist, the phase reached is P0' "$PARK_SEC" \
  "req-004: the P0 rule for a park before design.md"
assert_contains 'exact error' "$PARK_SEC" "req-004: park reports the exact error"
assert_contains 'stays on the feature branch' "$PARK_SEC" "req-004: a failure stops on the feature branch"
assert_contains 'never merges a pull request' "$PARK_SEC" "req-004: park never merges"
assert_contains 'never commits to `main`' "$PARK_SEC" "req-004: park never commits to main"
assert_contains 'never force-pushes' "$PARK_SEC" "req-004: park never force-pushes"
assert_contains 'one park per working tree' "$PARK_SEC" "req-004: one park per working tree"

echo "=== req-004: the park template and the index ==="
if [ -f "$PARK_TPL" ]; then T=$(cat "$PARK_TPL"); else T=""; fi
for field in 'phase:' 'last_artifact:' 'head_commit:' 'reason:'; do
  assert_contains "$field" "$T" "req-004: park.template.md holds $field"
done
assert_equals "" "$(grep -n '—' "$PARK_TPL" 2>/dev/null)" "req-004: park.template.md has no em dash"
# 0000244 replaced the per-template Pack Index rows with one {artifact}.template.md rule.
assert_contains '`ravintio-zero/templates/{artifact}.template.md`' "$S" "req-004: the Pack Index holds the template rule"
assert_contains '`park`' "$(grep -F 'The artifacts are' "$ORCH")" "req-004: the Pack Index rule names the park template"

echo "=== req-004: the backlog entry template allows parked ==="
E=$(cat "$ENTRY_TPL")
assert_contains 'parked' "$(grep '^status:' "$ENTRY_TPL")" "req-004: the entry status allows parked"
assert_contains '**Parked branch:**' "$E" "req-004: the entry template has a Parked branch field"
for field in '**Source feature:**' '**Source phase:**' '**Deferral source:**' '**Date filed:**'; do
  assert_contains "$field" "$E" "req-004: the entry template keeps $field"
done

echo "=== req-005: backlog pickup handles parked entries ==="
assert_contains '`parked`' "$STEP10" "req-005: backlog pickup names the parked status"
assert_contains 'resume or discard' "$STEP10" "req-005: a parked entry offers resume or discard"
for phrase in 'Check out the branch the entry names' 'Merge `origin/main`' \
  'Restore state from `plan/current/park.md`' 'Delete the parked entry folder and `park.md` in one commit'; do
  assert_contains "$phrase" "$STEP10" "req-005: resume step: $phrase"
done
assert_contains 'only after the human confirms' "$STEP10" "req-005: discard runs only after the human confirms"
assert_contains 'build-log note' "$STEP10" "req-005: discard leaves a build-log note"

echo "=== req-005: resume detection finishes an interrupted park ==="
assert_contains 'plan/current/park.md' "$RESUME_SEC" "req-005: resume detection checks for park.md"
assert_contains 'gh pr list --head chore/park-{feature-id} --state all' "$RESUME_SEC" \
  "req-005: resume detection looks for the chore PR"
assert_contains 'finish-pr' "$RESUME_SEC" "req-005: resume detection runs finish-pr"

# ---------------------------------------------------------------------------
# Behaviour: park.mjs against a local bare remote and a stub gh
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL="$TMP/gitconfig" GIT_CONFIG_NOSYSTEM=1
cat > "$GIT_CONFIG_GLOBAL" <<'EOF'
[user]
	name = Park Test
	email = park@example.com
[init]
	defaultBranch = main
[advice]
	detachedHead = false
EOF
mkdir -p "$TMP/bin"
export GH_LOG="$TMP/gh.log"
cat > "$TMP/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr list") exit 0 ;;
  "pr create")
    if [ "${GH_STUB_FAIL_CREATE:-0}" = "1" ]; then echo "stub: pr create refused" >&2; exit 1; fi
    echo "https://example.com/pr/1" ;;
esac
exit 0
EOF
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

FID="0000777-demo"
BR="feat/$FID"
CHORE="chore/park-$FID"
ENTRY_DIR="plan/backlog/0000900-park-demo"

# Builds a fresh origin and clone: main with one commit, and the feature
# branch holding a committed plan/current/park.md. Leaves the clone on $BR.
setup_repo() {
  rm -rf "$TMP/origin.git" "$TMP/seed" "$TMP/work"
  : > "$GH_LOG"
  git init -q --bare "$TMP/origin.git"
  git init -q "$TMP/seed"
  (cd "$TMP/seed" && echo base > README.md && git add . && git commit -qm "chore: seed" \
    && git remote add origin "$TMP/origin.git" && git push -q origin main) || return 1
  git --git-dir="$TMP/origin.git" symbolic-ref HEAD refs/heads/main
  git clone -q "$TMP/origin.git" "$TMP/work"
  (cd "$TMP/work" && git checkout -q -b "$BR" && echo code > feature.txt \
    && mkdir -p plan/current && printf -- '---\nphase: "P3"\n---\n# Park Record\n' > plan/current/park.md \
    && git add . && git commit -qm "docs(plan): park $FID") || return 1
  printf -- '---\nstatus: "parked"\n---\n# Backlog Entry: 0000900 - park demo\n\n**Parked branch:** %s\n' \
    "$BR" > "$TMP/entry.md"
}
run_park() { (cd "$TMP/work" && node "$PARK" "$@" 2>&1); }
cur_branch() { git -C "$TMP/work" branch --show-current; }
origin_ref() { git --git-dir="$TMP/origin.git" rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }

echo "=== req-004: park refuses an uncommitted park.md ==="
setup_repo
echo "more" >> "$TMP/work/plan/current/park.md"
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals "nonzero" "$([ $RC -ne 0 ] && echo nonzero || echo zero)" "req-004: park exits non-zero when park.md is not committed"
assert_equals "" "$(origin_ref "$BR")" "req-004: nothing pushed when park.md is not committed"

echo "=== req-004: a successful park ==="
setup_repo
MAIN_BEFORE=$(origin_ref main)
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_exit_zero "$RC" "req-004: park exits zero"
[ $RC -ne 0 ] && echo "$OUT"
assert_equals "$(git -C "$TMP/work" rev-parse "$BR")" "$(origin_ref "$BR")" \
  "req-004: the feature branch is pushed with park.md"
assert_contains 'Park Record' "$(git --git-dir="$TMP/origin.git" show "$BR:plan/current/park.md" 2>&1)" \
  "req-004: park.md is on origin's feature branch"
assert_equals "refs/heads/$BR" "$(git -C "$TMP/work" config "branch.$BR.merge")" \
  "req-004: park sets the feature branch upstream"
CHORE_ENTRY=$(git --git-dir="$TMP/origin.git" show "$CHORE:$ENTRY_DIR/entry.md" 2>&1)
assert_contains "**Parked branch:** $BR" "$CHORE_ENTRY" "req-004: the chore branch holds a parked entry naming the branch"
assert_contains 'status: "parked"' "$CHORE_ENTRY" "req-004: the entry has status parked"
assert_equals "" "$(git --git-dir="$TMP/origin.git" ls-tree -r --name-only "$CHORE" -- plan/current feature.txt)" \
  "req-004: the chore branch carries no feature work"
assert_equals "main" "$(cur_branch)" "req-004: the working tree ends on main"
assert_equals "$MAIN_BEFORE" "$(origin_ref main)" "req-004: origin main is unchanged"
assert_equals "$MAIN_BEFORE" "$(git -C "$TMP/work" rev-parse main)" "req-004: local main is unchanged"
assert_contains "pr create" "$(cat "$GH_LOG")" "req-004: park runs gh pr create"
assert_contains "--head $CHORE" "$(grep 'pr create' "$GH_LOG")" "req-004: the PR comes from the chore branch"
assert_equals "" "$(grep 'pr merge' "$GH_LOG")" "req-004: park never runs gh pr merge"

echo "=== req-004: a failed push stops on the feature branch ==="
setup_repo
MAIN_BEFORE=$(origin_ref main)
git -C "$TMP/work" remote set-url origin "$TMP/missing.git"
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals "nonzero" "$([ $RC -ne 0 ] && echo nonzero || echo zero)" "req-004: park exits non-zero when the push fails"
assert_contains "missing.git" "$OUT" "req-004: park prints the exact git error"
assert_equals "$BR" "$(cur_branch)" "req-004: the working tree stays on the feature branch"
assert_equals "$MAIN_BEFORE" "$(origin_ref main)" "req-004: origin main is unchanged after the failure"
assert_equals "$MAIN_BEFORE" "$(git -C "$TMP/work" rev-parse main)" "req-004: local main is unchanged after the failure"
assert_equals "" "$(cat "$GH_LOG")" "req-004: no gh call after a failed push"

echo "=== req-004: a failed gh pr create returns to the feature branch ==="
setup_repo
OUT=$(GH_STUB_FAIL_CREATE=1 run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals "nonzero" "$([ $RC -ne 0 ] && echo nonzero || echo zero)" "req-004: park exits non-zero when gh pr create fails"
assert_contains "stub: pr create refused" "$OUT" "req-004: park prints the exact gh error"
assert_equals "$BR" "$(cur_branch)" "req-004: the working tree returns to the feature branch"
assert_equals "" "$(grep 'pr merge' "$GH_LOG")" "req-004: no gh pr merge after a failure"

echo "=== req-005: finish-pr completes an interrupted park ==="
OUT=$(run_park finish-pr --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_exit_zero "$RC" "req-005: finish-pr exits zero"
[ $RC -ne 0 ] && echo "$OUT"
assert_contains "pr list --head $CHORE --state all" "$(cat "$GH_LOG")" "req-005: finish-pr checks for an existing chore PR"
assert_equals "2" "$(grep -c 'pr create' "$GH_LOG")" "req-005: finish-pr raises the chore PR"
assert_equals "main" "$(cur_branch)" "req-005: finish-pr ends on main"

echo "=== req-005: resume checks out the branch with origin/main merged ==="
(cd "$TMP/seed" && git pull -q origin main && echo later > later.txt && git add . \
  && git commit -qm "chore: later work" && git push -q origin main)
OUT=$(run_park resume "$BR"); RC=$?
assert_exit_zero "$RC" "req-005: resume exits zero"
[ $RC -ne 0 ] && echo "$OUT"
assert_equals "$BR" "$(cur_branch)" "req-005: resume leaves the working tree on the feature branch"
if git -C "$TMP/work" merge-base --is-ancestor "$(origin_ref main)" HEAD; then M=merged; else M=missing; fi
assert_equals merged "$M" "req-005: origin/main is merged into the feature branch"
assert_equals yes "$([ -f "$TMP/work/plan/current/park.md" ] && echo yes || echo no)" \
  "req-005: resume leaves park.md for the skill to restore"

echo "=== req-005: discard needs confirmation, then removes the branch ==="
git -C "$TMP/work" checkout -q main
OUT=$(run_park discard "$BR"); RC=$?
assert_equals "nonzero" "$([ $RC -ne 0 ] && echo nonzero || echo zero)" "req-005: discard without --confirmed exits non-zero"
assert_equals yes "$(git -C "$TMP/work" rev-parse -q --verify "refs/heads/$BR" >/dev/null && echo yes || echo no)" \
  "req-005: a declined discard keeps the local branch"
assert_equals yes "$([ -n "$(origin_ref "$BR")" ] && echo yes || echo no)" "req-005: a declined discard keeps the origin branch"
OUT=$(run_park discard "$BR" --confirmed); RC=$?
assert_exit_zero "$RC" "req-005: a confirmed discard exits zero"
[ $RC -ne 0 ] && echo "$OUT"
assert_equals no "$(git -C "$TMP/work" rev-parse -q --verify "refs/heads/$BR" >/dev/null && echo yes || echo no)" \
  "req-005: a confirmed discard removes the local branch"
assert_equals "" "$(origin_ref "$BR")" "req-005: a confirmed discard removes the origin branch"
assert_equals "" "$(grep 'pr merge' "$GH_LOG")" "req-005: pickup never runs gh pr merge"

# ---------------------------------------------------------------------------
# Argument validation (security findings F-001 to F-005)
# ---------------------------------------------------------------------------
nonzero() { [ "$1" -ne 0 ] && echo nonzero || echo zero; }
local_ref() { git -C "$TMP/work" rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }

echo "=== req-005: resume refuses an option as the branch ==="
setup_repo
echo "uncommitted" >> "$TMP/work/feature.txt"
OUT=$(run_park resume -f); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: resume -f exits non-zero"
assert_contains 'uncommitted' "$(cat "$TMP/work/feature.txt")" "req-005: resume -f keeps the uncommitted edit"

echo "=== req-005: resume refuses main ==="
setup_repo
git -C "$TMP/work" checkout -q main
(cd "$TMP/work" && echo local > local.txt && git add . && git commit -qm "chore: local main")
(cd "$TMP/seed" && echo remote > remote.txt && git add . && git commit -qm "chore: remote main" && git push -q origin main)
MAIN_BEFORE=$(local_ref main)
OUT=$(run_park resume main); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: resume main exits non-zero"
assert_equals "$MAIN_BEFORE" "$(local_ref main)" "req-005: resume main makes no commit on main"

echo "=== req-005: discard refuses a full ref name and main ==="
setup_repo
git -C "$TMP/work" push -q origin "$BR:refs/heads/extra"
git -C "$TMP/work" checkout -q main
OUT=$(run_park discard refs/heads/extra --confirmed); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: discard refs/heads/extra exits non-zero"
assert_equals yes "$([ -n "$(origin_ref extra)" ] && echo yes || echo no)" "req-005: discard refs/heads/extra keeps the origin branch"
MAIN_BEFORE=$(origin_ref main)
OUT=$(run_park discard main --confirmed); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: discard main exits non-zero"
OUT=$(run_park discard refs/heads/main --confirmed); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: discard refs/heads/main exits non-zero"
assert_equals "$MAIN_BEFORE" "$(origin_ref main)" "req-005: discard keeps origin main"

echo "=== req-005: a branch named +x is refused ==="
git -C "$TMP/work" branch +x
OUT=$(run_park discard +x --confirmed); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: discard +x exits non-zero"
assert_equals yes "$([ -n "$(local_ref +x)" ] && echo yes || echo no)" "req-005: discard +x keeps the local branch"
OUT=$(run_park resume +x); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-005: resume +x exits non-zero"
assert_equals main "$(cur_branch)" "req-005: resume +x leaves the working tree on main"

echo "=== req-004: park refuses a bad slug or backlog id ==="
setup_repo
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900 --slug ../escaped); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-004: park --slug ../escaped exits non-zero"
assert_equals "" "$(origin_ref "$BR")" "req-004: a bad slug pushes nothing"
assert_equals "" "$(origin_ref "$CHORE")" "req-004: a bad slug cuts no chore branch on origin"
assert_equals no "$([ -e "$TMP/work/plan/backlog" ] && echo yes || echo no)" "req-004: a bad slug writes nothing"
assert_equals "$BR" "$(cur_branch)" "req-004: a bad slug leaves the working tree on the feature branch"
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id ../../escaped); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-004: park with a bad --backlog-id exits non-zero"
assert_equals "" "$(origin_ref "$BR")" "req-004: a bad backlog id pushes nothing"
assert_equals no "$([ -e "$TMP/work/escaped-park-demo" ] && echo yes || echo no)" "req-004: a bad backlog id writes nothing"
assert_equals "" "$(cat "$GH_LOG")" "req-004: a bad slug or backlog id makes no gh call"

print_summary
