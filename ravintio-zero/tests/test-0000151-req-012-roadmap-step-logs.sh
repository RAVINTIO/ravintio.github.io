#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-012: initiative step logs.
#
# scripts/initiative-run.mjs writes each step's stdout and stderr to
# plan/.initiative-logs/step-{position}.log and names that log in every stop after a step starts.

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
# Stub claude. STUB_MODE: ok (default), block, stall, fail, short.
printf '%s\n' "$*" >> "$STUB_LOG"
RM=plan/current-initiative/initiative.md
POSRE='^((\*\*)?[Pp]osition:?(\*\*)? *:? *)'
pos="$(sed -nE "s/${POSRE}//p" "$RM")"
if [ "${STUB_MODE:-ok}" = short ]; then echo "short out"; exit 0; fi
echo "stub stdout line step $pos"
echo "stub stderr line step $pos" >&2
echo "second stdout line step $pos"
case "${STUB_MODE:-ok}" in
  fail) exit 3 ;;
  stall) exit 0 ;;
  block)
    printf 'Blocked: needs a human decision on step %s\n' "$pos" >> plan/current/build-log.md
    exit 0 ;;
esac
if [ "$pos" = 2 ]; then
  mkdir -p plan/_archive
  mv plan/current-initiative "plan/_archive/0000050-demo-roadmap-2026-10-24"
else
  sed -i.bak -E "s/${POSRE}.*/\\1$((pos + 1))/" "$RM" && rm -f "$RM.bak"
fi
STUB
chmod +x "$WORK/bin/claude"

make_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  cat > "$d/plan/current-initiative/initiative.md" <<EOF2
---
title: "Initiative: demo"
status: $2
---
goal: demo
branch: initiative/0000050-demo
status: $2
position: 1
EOF2
  : > "$d/plan/current/build-log.md"
  printf '%s' "$d"
}

# run_driver <root> <mode>: sets OUT, ERR, and CODE. OUT is stdout only.
run_driver() {
  OUT="$(cd "$1" && PATH="$WORK/bin:$PATH" STUB_LOG="$1/stub.log" STUB_MODE="$2" \
    node "$DRIVER" --root "$1" 2>"$1/driver.err")"
  CODE=$?
  ERR="$(cat "$1/driver.err")"
}

echo ""
echo "=== req-012 (a): log files ==="
R="$(make_fixture a-ok active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-012 (a): two-step run exits 0"
for n in 1 2; do
  L="$R/plan/.initiative-logs/step-$n.log"
  assert_equals "yes" "$([ -f "$L" ] && echo yes || echo no)" "req-012 (a): step-$n.log exists"
  assert_contains "stub stdout line step $n" "$(cat "$L" 2>/dev/null)" "req-012 (a): step-$n.log holds stdout"
  assert_contains "stub stderr line step $n" "$(cat "$L" 2>/dev/null)" "req-012 (a): step-$n.log holds stderr"
done
assert_equals "3" "$(wc -l < "$R/plan/.initiative-logs/step-1.log" | tr -d ' ')" "req-012 (a): step-1.log holds all three lines"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'Log:')" "req-012 (a): a clean run prints no Log: suffix"

for mode in fail block stall; do
  R="$(make_fixture a-$mode active)"
  run_driver "$R" "$mode"
  assert_equals "1" "$CODE" "req-012 (a): $mode exits 1"
  assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c 'I-C Run: Blocked:')" "req-012 (a): $mode prints one Blocked line"
  assert_equals "yes" "$(printf '%s\n' "$OUT" | grep 'I-C Run: Blocked:' | grep -q 'Log: plan/.initiative-logs/step-1.log$' && echo yes || echo no)" "req-012 (a): $mode line ends with the log path"
  assert_equals "yes" "$([ -f "$R/plan/.initiative-logs/step-1.log" ] && echo yes || echo no)" "req-012 (a): $mode log exists"
done

R="$(make_fixture a-rerun active)"
run_driver "$R" block
run_driver "$R" short
rm -f "$R/plan/.initiative-runner.lock"
assert_equals "short out" "$(cat "$R/plan/.initiative-logs/step-1.log")" "req-012 (a): a rerun truncates the log"

R="$(make_fixture a-draft draft)"
run_driver "$R" ok
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'Log:')" "req-012 (a): an inactive initiative names no log"
R="$(make_fixture a-lock active)"
echo other > "$R/plan/.initiative-runner.lock"
run_driver "$R" ok
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'Log:')" "req-012 (a): an existing lock names no log"

echo ""
echo "=== req-012 (b): output and git ==="
R="$(make_fixture b-out active)"
run_driver "$R" ok
assert_contains "stub stderr line step 1" "$ERR" "req-012 (b): child stderr reaches driver stderr"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c 'stub stdout')" "req-012 (b): child stdout stays off driver stdout"

R="$(make_fixture b-git active)"
git -C "$R" init -q
run_driver "$R" ok
run_driver "$R" ok
assert_equals "1" "$(grep -cxF 'plan/.initiative-logs/' "$R/.git/info/exclude")" "req-012 (b): log folder excluded exactly once"
assert_equals "1" "$(grep -cxF 'plan/.initiative-runner.lock' "$R/.git/info/exclude")" "req-012 (b): lock still excluded once"
assert_equals "0" "$(git -C "$R" status --porcelain | grep -c 'initiative-logs')" "req-012 (b): git status lists no log"

R="$(make_fixture b-file active)"
echo not-a-dir > "$R/plan/.initiative-logs"
run_driver "$R" ok
assert_equals "1" "$CODE" "req-012 (b): an unusable log folder exits 1"
assert_contains "I-C Run: Blocked: could not open the step log" "$OUT" "req-012 (b): log-open stop line"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-012 (b): lock released"
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-012 (b): no step ran"

echo ""
echo "=== req-012 (d): symlinks and modes (S-001, S-003) ==="
mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

R="$(make_fixture d-file active)"
mkdir -p "$R/plan/.initiative-logs"
printf 'victim bytes\n' > "$WORK/victim-file"
ln -s "$WORK/victim-file" "$R/plan/.initiative-logs/step-1.log"
run_driver "$R" ok
assert_equals "1" "$CODE" "req-012 (d): a symlinked step log exits 1"
assert_contains "I-C Run: Blocked: refused a symlinked step log path" "$OUT" "req-012 (d): symlinked log stop line"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c "$WORK")" "req-012 (d): stop line omits the target path"
assert_equals "victim bytes" "$(cat "$WORK/victim-file")" "req-012 (d): the victim file keeps its bytes"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-012 (d): lock released after a symlinked log"
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-012 (d): no step ran after a symlinked log"

R="$(make_fixture d-dir active)"
mkdir -p "$WORK/victim-dir"
printf 'victim bytes\n' > "$WORK/victim-dir/step-1.log"
ln -s "$WORK/victim-dir" "$R/plan/.initiative-logs"
run_driver "$R" ok
assert_equals "1" "$CODE" "req-012 (d): a symlinked log folder exits 1"
assert_contains "I-C Run: Blocked: refused a symlinked step log path" "$OUT" "req-012 (d): symlinked folder stop line"
assert_equals "0" "$(printf '%s\n' "$OUT" | grep -c "$WORK")" "req-012 (d): folder stop line omits the target path"
assert_equals "victim bytes" "$(cat "$WORK/victim-dir/step-1.log")" "req-012 (d): the victim folder file keeps its bytes"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-012 (d): lock released after a symlinked folder"
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-012 (d): no step ran after a symlinked folder"

R="$(make_fixture d-mode active)"
run_driver "$R" ok
assert_equals "700" "$(mode_of "$R/plan/.initiative-logs")" "req-012 (d): log folder mode is 700"
assert_equals "600" "$(mode_of "$R/plan/.initiative-logs/step-1.log")" "req-012 (d): log mode is 600"

echo ""
echo "=== req-012 (c): documentation ==="
HEAD_TXT="$(sed -n '1,60p' "$DRIVER")"
for f in "$HEAD_TXT" "$(cat "$STANDARDS")"; do
  assert_contains "plan/.initiative-logs/" "$f" "req-012 (c): names the log folder"
  assert_contains "truncate" "$f" "req-012 (c): names the truncate rule"
  assert_contains "symlink" "$f" "req-012 (c): names the symlink refusal"
  assert_contains "private" "$f" "req-012 (c): says logs are private"
done

print_summary
