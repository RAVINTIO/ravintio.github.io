#!/usr/bin/env bash
# Tests for feature 0000189-name-the-roadmap-initiative, req-006: old variable stop.
#
# An old model or turn cap variable stops the driver before it spawns a step.
# A stub claude on PATH logs its arguments.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"
mkdir -p plan/_archive
mv plan/current-initiative "plan/_archive/0000050-demo-roadmap-2026-10-24"
STUB
chmod +x "$WORK/bin/claude"

make_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  cat > "$d/plan/current-initiative/initiative.md" <<'EOT'
---
title: "Initiative: demo"
status: active
---
branch: initiative/0000050-demo
status: active
position: 1
EOT
  : > "$d/plan/current/build-log.md"
  printf '%s' "$d"
}

run_driver() {
  local r="$1"; shift
  OUT="$(cd "$r" && env PATH="$WORK/bin:$PATH" STUB_LOG="$r/stub.log" "$@" node "$DRIVER" --root "$r" 2>&1)"
  CODE=$?
}

stopped() {
  local old="$1" new="$2" val="$3" r
  r="$(make_fixture "s-$old")"
  run_driver "$r" "$old=$val"
  assert_equals "1" "$CODE" "req-006: $old exits 1"
  assert_contains "I-C Run: Blocked: $old is no longer read. Set $new instead." "$OUT" "req-006: $old stop line names $new"
  assert_equals "no" "$([ -e "$r/stub.log" ] && echo yes || echo no)" "req-006: $old spawns no step"
}

echo ""
echo "=== req-006 AC-1: old model variable ==="
stopped RAVINTIO_ROADMAP_MODEL RAVINTIO_INITIATIVE_MODEL sonnet
stopped PLANIFEST_ROADMAP_MODEL RAVINTIO_INITIATIVE_MODEL sonnet

echo ""
echo "=== req-006 AC-2: old turn cap variable ==="
stopped RAVINTIO_ROADMAP_MAX_TURNS RAVINTIO_INITIATIVE_MAX_TURNS 40
stopped PLANIFEST_ROADMAP_MAX_TURNS RAVINTIO_INITIATIVE_MAX_TURNS 40

echo ""
echo "=== req-006 AC-3: new variables work ==="
R="$(make_fixture new)"
run_driver "$R" RAVINTIO_INITIATIVE_MODEL=sonnet RAVINTIO_INITIATIVE_MAX_TURNS=40
assert_equals "0" "$CODE" "req-006 AC-3: exits 0"
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model sonnet --max-turns 40 Run initiative step 1" "$(cat "$R/stub.log")" "req-006 AC-3: model and cap passed to claude -p"

R="$(make_fixture empty-old)"
run_driver "$R" RAVINTIO_ROADMAP_MODEL= RAVINTIO_ROADMAP_MAX_TURNS=
assert_equals "0" "$CODE" "req-006: empty old variables do not stop the driver"

print_summary
