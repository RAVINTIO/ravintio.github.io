#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-006: initiative step model and turn cap.
#
# scripts/initiative-run.mjs passes --model and an optional --max-turns to each claude -p call.
# A stub claude on PATH logs its arguments.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
STANDARDS="$SCRIPT_DIR/../standards/roadmap-standards.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub claude. STUB_MODE: ok (default), fail.
printf '%s\n' "$*" >> "$STUB_LOG"
RM=plan/current-initiative/initiative.md
[ "${STUB_MODE:-ok}" = fail ] && exit 3
mkdir -p plan/_archive
mv plan/current-initiative "plan/_archive/0000050-demo-roadmap-2026-10-24"
STUB
chmod +x "$WORK/bin/claude"

assert_not_contains() {
  local has=no
  [[ "$2" == *"$1"* ]] && has=yes
  assert_equals "no" "$has" "$3"
}

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

# run_driver <root> <mode> [VAR=value ...]: sets OUT and CODE.
run_driver() {
  local r="$1" m="$2"; shift 2
  OUT="$(cd "$r" && env PATH="$WORK/bin:$PATH" STUB_LOG="$r/stub.log" STUB_MODE="$m" "$@" \
    node "$DRIVER" --root "$r" 2>&1)"
  CODE=$?
}

echo ""
echo "=== req-006 (a): arguments ==="
R="$(make_fixture a-default)"
run_driver "$R" ok
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model sonnet Run initiative step 1" "$(cat "$R/stub.log")" "req-006 (a): default model and no cap"
R="$(make_fixture a-empty)"
run_driver "$R" ok RAVINTIO_INITIATIVE_MODEL= RAVINTIO_INITIATIVE_MAX_TURNS=
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model sonnet Run initiative step 1" "$(cat "$R/stub.log")" "req-006 (a): empty variables use the defaults"
R="$(make_fixture a-set)"
run_driver "$R" ok RAVINTIO_INITIATIVE_MODEL=haiku RAVINTIO_INITIATIVE_MAX_TURNS=40
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model haiku --max-turns 40 Run initiative step 1" "$(cat "$R/stub.log")" "req-006 (a): model and cap passed before the prompt"

echo ""
echo "=== req-006 (a): input validation ==="
i=0
for bad in 0 -3 1.5 abc "10 --foo" 12345; do
  i=$((i + 1))
  R="$(make_fixture bad-turns-$i)"
  run_driver "$R" ok RAVINTIO_INITIATIVE_MAX_TURNS="$bad"
  assert_equals "1" "$CODE" "req-006 (a): cap '$bad' exits 1"
  assert_contains "I-C Run: Blocked:" "$OUT" "req-006 (a): cap '$bad' prints a Blocked line"
  assert_contains "RAVINTIO_INITIATIVE_MAX_TURNS" "$OUT" "req-006 (a): cap '$bad' names the variable"
  assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-006 (a): cap '$bad' runs no step"
  assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-006 (a): cap '$bad' takes no lock"
done
for bad in "a b" "-x" 'a;b' 'a$b'; do
  i=$((i + 1))
  R="$(make_fixture bad-model-$i)"
  run_driver "$R" ok RAVINTIO_INITIATIVE_MODEL="$bad"
  assert_equals "1" "$CODE" "req-006 (a): model '$bad' exits 1"
  assert_contains "I-C Run: Blocked:" "$OUT" "req-006 (a): model '$bad' prints a Blocked line"
  assert_contains "RAVINTIO_INITIATIVE_MODEL" "$OUT" "req-006 (a): model '$bad' names the variable"
  assert_not_contains "$bad" "$OUT" "req-006 (a): model '$bad' value not printed"
  assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-006 (a): model '$bad' runs no step"
  assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-006 (a): model '$bad' takes no lock"
done

echo ""
echo "=== req-006 (b): a failing step with a cap set ==="
R="$(make_fixture b-cap)"
run_driver "$R" fail RAVINTIO_INITIATIVE_MAX_TURNS=40
assert_equals "1" "$CODE" "req-006 (b): exits 1"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: Blocked:')" "req-006 (b): one Blocked line"
assert_contains "RAVINTIO_INITIATIVE_MAX_TURNS=40" "$OUT" "req-006 (b): the line names the cap"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-006 (b): lock released"
R="$(make_fixture b-nocap)"
run_driver "$R" fail
assert_not_contains "RAVINTIO_INITIATIVE_MAX_TURNS" "$OUT" "req-006 (b): no cap named when none is set"

echo ""
echo "=== req-006 (c): documentation ==="
HEAD_TXT="$(sed -n '1,60p' "$DRIVER")"
for f in "$HEAD_TXT" "$(cat "$STANDARDS")"; do
  assert_contains "RAVINTIO_INITIATIVE_MODEL" "$f" "req-006 (c): names the model variable"
  assert_contains "RAVINTIO_INITIATIVE_MAX_TURNS" "$f" "req-006 (c): names the cap variable"
  assert_contains "sonnet" "$f" "req-006 (c): names the sonnet default"
done

print_summary
