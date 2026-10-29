#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when a failed chore commit leaks the parked entry into the feature branch.
# Tests for feature 0000041-setup-cleanup-and-park-hardening, req-004:
# if park's local add or chore commit fails, park unstages and deletes the
# entry, rethrows the original error, and returns to the feature branch.
# The tests run park.mjs against a local bare remote with a stub gh, and a
# failing pre-commit hook forces the chore commit to fail.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARK="$ROOT/skills/ravintio-orchestrator/scripts/park.mjs"

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
  "pr create") echo "https://example.com/pr/1" ;;
esac
exit 0
EOF
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

FID="0000777-demo"
BR="feat/$FID"
CHORE="chore/park-$FID"
ENTRY="plan/backlog/0000900-park-demo/entry.md"

# Builds a fresh origin and clone with park.md committed on the feature branch.
# It then installs a pre-commit hook that refuses commits on the chore branch.
# The optional argument runs inside the hook before it refuses.
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
  cat > "$TMP/work/.git/hooks/pre-commit" <<EOF
#!/usr/bin/env bash
[ "\$(git branch --show-current)" = "$CHORE" ] || exit 0
${1:-}
echo "stub: pre-commit refused" >&2
exit 1
EOF
  chmod +x "$TMP/work/.git/hooks/pre-commit"
}
run_park() { (cd "$TMP/work" && node "$PARK" "$@" 2>&1); }
cur_branch() { git -C "$TMP/work" branch --show-current; }
nonzero() { [ "$1" -ne 0 ] && echo nonzero || echo zero; }
present() { [ -e "$TMP/work/$1" ] && echo yes || echo no; }

echo "=== req-004: a failed chore commit reports the git error ==="
setup_repo
PARK_HEAD=$(git -C "$TMP/work" rev-parse HEAD)
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-004: park exits non-zero when the chore commit fails"
assert_contains "stub: pre-commit refused" "$OUT" "req-004: park prints the exact git error"
assert_contains "git commit" "$OUT" "req-004: the error names the failed git commit"

echo "=== req-004: a failed chore commit leaves a clean feature branch ==="
assert_equals "$BR" "$(cur_branch)" "req-004: the working tree returns to the feature branch"
assert_equals no "$(present "$ENTRY")" "req-004: the entry file is not in the working tree"
assert_equals "" "$(git -C "$TMP/work" status --porcelain)" "req-004: no staged or untracked change remains"
assert_equals "$PARK_HEAD" "$(git -C "$TMP/work" rev-parse HEAD)" "req-004: the feature branch head is unchanged"
assert_contains "Park Record" "$(git -C "$TMP/work" show "$BR:plan/current/park.md" 2>&1)" \
  "req-004: park.md is still committed on the feature branch"
assert_equals "" "$(grep 'pr create' "$GH_LOG")" "req-004: no gh pr create after a failed commit"
assert_equals "" "$(grep 'pr merge' "$GH_LOG")" "req-004: no gh pr merge after a failed commit"

echo "=== req-004: finish-pr cleans up after a failed chore commit ==="
setup_repo
OUT=$(run_park finish-pr --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals nonzero "$(nonzero $RC)" "req-004: finish-pr exits non-zero when the chore commit fails"
assert_contains "stub: pre-commit refused" "$OUT" "req-004: finish-pr prints the exact git error"
assert_equals "$BR" "$(cur_branch)" "req-004: finish-pr returns to the feature branch"
assert_equals "" "$(git -C "$TMP/work" status --porcelain)" "req-004: finish-pr leaves no entry and no staged change"

echo "=== req-004: a failed cleanup never replaces the original error ==="
# The hook makes the entry folder read-only, so deleting the entry fails.
setup_repo 'chmod a-w plan/backlog/0000900-park-demo'
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
chmod -R u+w "$TMP/work/plan" 2>/dev/null
assert_equals 1 "$RC" "req-004: park exits 1 when the cleanup also fails"
assert_contains "stub: pre-commit refused" "$OUT" "req-004: the original git error survives a failed cleanup"
assert_equals "" "$(printf '%s\n' "$OUT" | grep -E '^ +at ')" "req-004: a failed cleanup prints no stack trace"
assert_equals "$BR" "$(cur_branch)" "req-004: a failed cleanup still returns to the feature branch"
assert_equals "" "$(git -C "$TMP/work" diff --cached --name-only)" "req-004: a failed cleanup still unstages the entry"

echo "=== req-004: park refuses an --entry that is the target path (0000041 F-001) ==="
# The cleanup deletes the target path, so it must never be the only copy.
setup_repo
mkdir -p "$TMP/work/$(dirname "$ENTRY")"
cp "$TMP/entry.md" "$TMP/work/$ENTRY"
OUT=$(run_park park --entry "$ENTRY" --backlog-id 0000900); RC=$?
assert_equals 1 "$RC" "req-004: park exits 1 when --entry is the target path"
assert_contains "--entry must not be the target path" "$OUT" "req-004: the refusal names the --entry fault"
assert_equals yes "$(present "$ENTRY")" "req-004: the only copy of the entry survives"
assert_equals "$BR" "$(cur_branch)" "req-004: a refused --entry leaves the feature branch checked out"

print_summary
