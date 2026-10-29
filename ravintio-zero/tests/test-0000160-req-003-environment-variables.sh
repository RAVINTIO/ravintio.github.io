#!/usr/bin/env bash
# Tests for feature 0000160-ravintio-rebrand, req-003: environment variables.
#
# (a) No PLANIFEST_ string remains in tracked files outside the history folders, the migration,
#     and the two initiative fallback names.
# (b) initiative-run.mjs reads RAVINTIO_INITIATIVE_* and stops if a PLANIFEST_ROADMAP_* name is set (0000189 REQ-006).
# (c) The emitted OTEL labels are ravintio.initiative and ravintio.step.
# A stub claude on PATH logs its arguments and OTEL_RESOURCE_ATTRIBUTES.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

assert_not_contains() {
  local has=no
  [[ "$2" == *"$1"* ]] && has=yes
  assert_equals "no" "$has" "$3"
}

echo ""
echo "=== req-003 (a): no PLANIFEST_ string remains ==="
LEFT="$(cd "$REPO" && git ls-files -z \
  | grep -zv -e '^plan/_archive/' -e '^plan/changelog/' -e '^ravintio-zero/migrations/_done/' \
      -e '^plan/current/' -e '^ravintio-zero/migrations/0004-ravintio-rename.md$' \
      -e '^ravintio-zero/migrations/migrate-ravintio-rename\.' \
      -e '^ravintio-zero/tests/test-.*ravintio-rename' \
      -e '^docs/decisions-index\.md$' \
      -e '^ravintio-zero/tests/test-0000160-req-006-brand-guard.sh$' \
      -e '^ravintio-zero/tests/test-0000160-req-003-environment-variables.sh$' \
  | xargs -0 grep -I -n 'PLANIFEST_' 2>/dev/null \
  | grep -Ev 'PLANIFEST_ROADMAP_(MODEL|MAX_TURNS)' )"
assert_equals "" "$LEFT" "req-003 (a): no PLANIFEST_ string outside the allowed places"

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"
printf 'OTEL=%s\n' "$OTEL_RESOURCE_ATTRIBUTES" >> "$STUB_LOG"
mkdir -p plan/_archive
mv plan/current-initiative "plan/_archive/0000050-demo-roadmap-2026-10-24"
STUB
chmod +x "$WORK/bin/claude"

make_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  cat > "$d/plan/current-initiative/initiative.md" <<EOF2
---
title: "Initiative: demo"
status: active
---
goal: demo
branch: initiative/0000050-demo
status: active
position: 1
EOF2
  : > "$d/plan/current/build-log.md"
  printf '%s' "$d"
}

# run_driver <root> [VAR=value ...]: sets OUT and CODE.
run_driver() {
  local r="$1"; shift
  OUT="$(cd "$r" && env -u RAVINTIO_INITIATIVE_MODEL -u RAVINTIO_INITIATIVE_MAX_TURNS \
    -u PLANIFEST_ROADMAP_MODEL -u PLANIFEST_ROADMAP_MAX_TURNS \
    PATH="$WORK/bin:$PATH" STUB_LOG="$r/stub.log" "$@" node "$DRIVER" --root "$r" 2>&1)"
  CODE=$?
}

echo ""
echo "=== req-003 (b): precedence ==="
R="$(make_fixture new-only)"
run_driver "$R" RAVINTIO_INITIATIVE_MODEL=haiku RAVINTIO_INITIATIVE_MAX_TURNS=40
assert_contains "--model haiku --max-turns 40 " "$(cat "$R/stub.log")" "req-003 (b): only RAVINTIO_* set"
R="$(make_fixture old-only)"
run_driver "$R" PLANIFEST_ROADMAP_MODEL=opus PLANIFEST_ROADMAP_MAX_TURNS=25
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-003 (b): only PLANIFEST_* set, no step runs"
assert_contains "PLANIFEST_ROADMAP_MODEL is no longer read. Set RAVINTIO_INITIATIVE_MODEL instead." "$OUT" "req-003 (b): only PLANIFEST_* set, the driver stops"
R="$(make_fixture both)"
run_driver "$R" RAVINTIO_INITIATIVE_MODEL=haiku RAVINTIO_INITIATIVE_MAX_TURNS=40 \
  PLANIFEST_ROADMAP_MODEL=opus PLANIFEST_ROADMAP_MAX_TURNS=25
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-003 (b): both set, the old name still stops the driver"
R="$(make_fixture mixed)"
run_driver "$R" RAVINTIO_INITIATIVE_MODEL=haiku PLANIFEST_ROADMAP_MAX_TURNS=25
assert_contains "PLANIFEST_ROADMAP_MAX_TURNS is no longer read. Set RAVINTIO_INITIATIVE_MAX_TURNS instead." "$OUT" "req-003 (b): an old turn cap stops the driver on its own"
R="$(make_fixture old-bad)"
run_driver "$R" PLANIFEST_ROADMAP_MAX_TURNS=abc
assert_equals "1" "$CODE" "req-003 (b): an invalid old value is still rejected"

echo ""
echo "=== req-003 (c): OTEL labels ==="
LOG="$(cat "$WORK/new-only/stub.log")"
assert_contains "ravintio.initiative=0000050-demo" "$LOG" "req-003 (c): ravintio.initiative emitted"
assert_contains "ravintio.step=1" "$LOG" "req-003 (c): ravintio.step emitted"
assert_not_contains "planifest." "$LOG" "req-003 (c): no planifest. label"

print_summary 2>/dev/null || true
