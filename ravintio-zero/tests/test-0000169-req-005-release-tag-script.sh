#!/usr/bin/env bash
# Feature 0000169 req-005: release-tag.mjs tags HEAD and pushes the tag to origin.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$ZERO_DIR/scripts/release-tag.mjs"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_equals "yes" "$([ -f "$SCRIPT" ] && echo yes || echo no)" "release-tag.mjs exists"
[ -f "$SCRIPT" ] || { print_summary; exit 1; }

# Build a repo with a local bare origin. Prints the repo path.
make_repo() {
  local name="$1" dir="$TMP_ROOT/$1"
  mkdir -p "$dir/work/docs"
  git init -q --bare "$dir/origin.git"
  git -C "$dir/work" init -q
  git -C "$dir/work" config user.email "test@example.com"
  git -C "$dir/work" config user.name "Test"
  git -C "$dir/work" config commit.gpgsign false
  git -C "$dir/work" config tag.gpgsign false
  git -C "$dir/work" remote add origin "$dir/origin.git"
  echo "$dir/work"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "init"
}

# run_tag <repo>: runs the script, sets OUT and CODE.
run_tag() {
  OUT=$(cd "$1" && node "$SCRIPT" --root "$1" 2>&1)
  CODE=$?
}

echo "=== create and push ==="
R=$(make_repo create)
printf 'version: "1.2.3"\nfeature: 0000169-release-hygiene\n' > "$R/product.yml"
commit_all "$R"
run_tag "$R"
assert_equals "0" "$CODE" "first run exits 0"
assert_equals "tag" "$(git -C "$R" cat-file -t refs/tags/v1.2.3)" "local tag is annotated"
assert_equals "$(git -C "$R" rev-parse HEAD)" "$(git -C "$R" rev-parse 'v1.2.3^{commit}')" "tag points at HEAD"
assert_contains "0000169-release-hygiene" "$(git -C "$R" tag -l -n1 v1.2.3)" "tag message is the feature"
assert_contains "refs/tags/v1.2.3" "$(git ls-remote --tags "$TMP_ROOT/create/origin.git")" "origin holds the tag"

echo "=== skip when tag exists locally ==="
BEFORE=$(git -C "$R" rev-parse refs/tags/v1.2.3)
run_tag "$R"
assert_equals "0" "$CODE" "second run exits 0"
assert_contains "release-tag: v1.2.3 exists, skipped" "$OUT" "second run prints skip line"
assert_equals "$BEFORE" "$(git -C "$R" rev-parse refs/tags/v1.2.3)" "local tag unchanged"

echo "=== skip when only origin holds the tag ==="
git -C "$R" tag -d v1.2.3 >/dev/null
run_tag "$R"
assert_equals "0" "$CODE" "origin-only run exits 0"
assert_contains "release-tag: v1.2.3 exists, skipped" "$OUT" "origin-only run prints skip line"
assert_equals "" "$(git -C "$R" tag -l v1.2.3)" "no local tag recreated"

echo "=== missing version ==="
R=$(make_repo missing)
printf 'feature: x\n' > "$R/product.yml"
commit_all "$R"
run_tag "$R"
assert_equals "1" "$CODE" "missing version exits 1"
assert_contains "release-tag:" "$OUT" "missing version prints a clear line"

echo "=== invalid version ==="
R=$(make_repo invalid)
printf 'version: 1.2.3-beta\n' > "$R/product.yml"
commit_all "$R"
run_tag "$R"
assert_equals "1" "$CODE" "invalid version exits 1"
assert_contains "release-tag:" "$OUT" "invalid version prints a clear line"
assert_equals "" "$(git -C "$R" tag -l)" "invalid version creates no tag"

echo "=== failed push ==="
R=$(make_repo pushfail)
printf 'version: 2.0.0\nfeature: f\n' > "$R/product.yml"
commit_all "$R"
printf '#!/bin/sh\nexit 1\n' > "$TMP_ROOT/pushfail/origin.git/hooks/pre-receive"
chmod +x "$TMP_ROOT/pushfail/origin.git/hooks/pre-receive"
run_tag "$R"
assert_equals "1" "$CODE" "failed push exits 1"
assert_contains "release-tag:" "$OUT" "failed push prints a clear line"

echo "=== about.md fallback ==="
R=$(make_repo about)
printf -- '---\ntitle: About\nversion: "0.9.1"\nfeature: 0000099-about\n---\n# About\n' > "$R/docs/about.md"
commit_all "$R"
run_tag "$R"
assert_equals "0" "$CODE" "about.md fallback exits 0"
assert_contains "refs/tags/v0.9.1" "$(git ls-remote --tags "$TMP_ROOT/about/origin.git")" "origin holds the about.md version tag"
assert_contains "0000099-about" "$(git -C "$R" tag -l -n1 v0.9.1)" "about.md feature is the tag message"

echo "=== message falls back to the tag name ==="
R=$(make_repo nofeature)
printf 'version: 3.1\n' > "$R/product.yml"
commit_all "$R"
run_tag "$R"
assert_equals "0" "$CODE" "two-part version exits 0"
assert_contains "v3.1" "$(git -C "$R" tag -l -n1 v3.1)" "message falls back to v{version}"

print_summary
