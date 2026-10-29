#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-001:
# park refuses a symlink in the entry path, writes and deletes nothing through
# it, pushes nothing, and returns to the feature branch (ADR-008).
# Every symlink target lives inside this test's own mktemp directory.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARK="$ROOT/skills/ravintio-orchestrator/scripts/park.mjs"

TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL="$TMP/gitconfig" GIT_CONFIG_NOSYSTEM=1
cat > "$GIT_CONFIG_GLOBAL" <<'CFG'
[user]
	name = Park Test
	email = park@example.com
[init]
	defaultBranch = main
[advice]
	detachedHead = false
CFG
mkdir -p "$TMP/bin"
export GH_LOG="$TMP/gh.log"
cat > "$TMP/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr list") exit 0 ;;
  "pr create") echo "https://example.com/pr/1" ;;
esac
exit 0
GH
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

FID="0000777-demo"
BR="feat/$FID"
DIR="plan/backlog/0000900-park-demo"
OUTSIDE="$TMP/outside"
MARK="outside-original-bytes"

# Builds origin and a clone. $1 is a command run in the seed repo on main
# before the first push, so it commits the symlink under test. The hook ($2)
# runs on the chore branch before the commit is refused.
setup_repo() {
  rm -rf "$TMP/origin.git" "$TMP/seed" "$TMP/work" "$OUTSIDE" "$TMP/inside"
  : > "$GH_LOG"
  mkdir -p "$OUTSIDE/0000900-park-demo" "$TMP/inside"
  printf '%s' "$MARK" > "$OUTSIDE/0000900-park-demo/entry.md"
  printf '%s' "$MARK" > "$OUTSIDE/target.md"
  git init -q --bare "$TMP/origin.git"
  git init -q "$TMP/seed"
  (cd "$TMP/seed" && echo base > README.md && git add . && git commit -qm "chore: seed" \
    && eval "${1:-:}" && git add -A && git commit -qm "chore: symlink" --allow-empty \
    && git remote add origin "$TMP/origin.git" && git push -q origin main) || return 1
  git --git-dir="$TMP/origin.git" symbolic-ref HEAD refs/heads/main
  git clone -q "$TMP/origin.git" "$TMP/work"
  (cd "$TMP/work" && git checkout -q -b "$BR" && echo code > feature.txt \
    && mkdir -p plan/current && printf -- '---\nphase: "P3"\n---\n# Park Record\n' > plan/current/park.md \
    && git add . && git commit -qm "docs(plan): park $FID") || return 1
  printf -- '---\nstatus: "parked"\n---\n# Backlog Entry: 0000900 - park demo\n\n**Parked branch:** %s\n' \
    "$BR" > "$TMP/entry.md"
  if [ -n "${2:-}" ]; then
    cat > "$TMP/work/.git/hooks/pre-commit" <<HOOK
#!/usr/bin/env bash
[ "\$(git branch --show-current)" = "chore/park-$FID" ] || exit 0
$2
echo "stub: pre-commit refused" >&2
exit 1
HOOK
    chmod +x "$TMP/work/.git/hooks/pre-commit"
  fi
}
run_park() { (cd "$TMP/work" && node "$PARK" "$@" 2>&1); }
cur_branch() { git -C "$TMP/work" branch --show-current; }
chore_on_origin() { git --git-dir="$TMP/origin.git" branch --list 'chore/park-*'; }

# Runs park and asserts every refusal property for one symlink case.
check_refused() {
  local label="$1" outfile="$2"
  local out rc
  out=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); rc=$?
  assert_equals 1 "$rc" "$label: park exits 1"
  assert_contains "symlink" "$out" "$label: the refusal says symlink"
  assert_equals "$MARK" "$(cat "$outfile" 2>/dev/null)" "$label: the outside file keeps its bytes"
  assert_equals "" "$(grep 'pr create' "$GH_LOG")" "$label: no gh pr create"
  assert_equals "" "$(chore_on_origin)" "$label: origin gains no chore branch"
  assert_equals "$BR" "$(cur_branch)" "$label: the working tree is on the feature branch"
}

echo "=== req-001: a symlinked plan/backlog is refused ==="
setup_repo "mkdir -p plan && ln -s '$OUTSIDE' plan/backlog"
check_refused "req-001 backlog link" "$OUTSIDE/0000900-park-demo/entry.md"

echo "=== req-001: a symlinked entry folder is refused ==="
setup_repo "mkdir -p plan/backlog && ln -s '$OUTSIDE/0000900-park-demo' $DIR"
check_refused "req-001 folder link" "$OUTSIDE/0000900-park-demo/entry.md"

echo "=== req-001: a symlinked entry.md is refused ==="
setup_repo "mkdir -p $DIR && ln -s '$OUTSIDE/target.md' $DIR/entry.md"
check_refused "req-001 entry link" "$OUTSIDE/target.md"

echo "=== req-001: a symlink to a folder inside the repo is refused ==="
setup_repo "mkdir -p plan/backlog/real && ln -s real $DIR"
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals 1 "$RC" "req-001 inside link: park exits 1"
assert_contains "symlink" "$OUT" "req-001 inside link: the refusal says symlink"
assert_equals "" "$(grep 'pr create' "$GH_LOG")" "req-001 inside link: no gh pr create"
assert_equals "$BR" "$(cur_branch)" "req-001 inside link: back on the feature branch"

echo "=== req-001: a failed commit with a symlink at the entry path deletes nothing through it ==="
# The hook swaps the entry folder for a symlink, so the cleanup must not delete through it.
setup_repo "" "rm -rf $DIR && ln -s '$OUTSIDE/0000900-park-demo' $DIR"
OUT=$(run_park park --entry "$TMP/entry.md" --backlog-id 0000900); RC=$?
assert_equals 1 "$RC" "req-001 cleanup: park exits 1"
assert_contains "stub: pre-commit refused" "$OUT" "req-001 cleanup: park rethrows the original commit error"
assert_equals "$MARK" "$(cat "$OUTSIDE/0000900-park-demo/entry.md" 2>/dev/null)" "req-001 cleanup: the outside entry keeps its bytes"

print_summary
