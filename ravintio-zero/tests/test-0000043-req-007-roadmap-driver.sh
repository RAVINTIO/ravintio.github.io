#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-007: initiative driver.
#
# scripts/initiative-run.mjs runs each initiative step in a fresh claude -p session.
# A stub claude on PATH stands in for the model. It edits the fixture's
# initiative.md and build-log.md the way a real step would.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
TPL="$SCRIPT_DIR/../templates/initiative.template.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub claude. STUB_MODE: ok (default), block, stall, fail.
printf '%s\n' "$*" >> "$STUB_LOG"
RM=plan/current-initiative/initiative.md
POSRE='^((\*\*)?[Pp]osition:?(\*\*)? *:? *)'
pos="$(sed -nE "s/${POSRE}//p" "$RM")"
case "${STUB_MODE:-ok}" in
  fail) exit 3 ;;
  stall) exit 0 ;;
  block)
    printf 'Blocked: needs a human decision on step %s\n' "$pos" >> plan/current/build-log.md
    exit 0 ;;
esac
printf 'I-C Run: step %s done\n' "$pos" >> plan/current/build-log.md
if [ "$pos" = 2 ]; then
  mkdir -p plan/_archive
  mv plan/current-initiative "plan/_archive/0000050-demo-${ARCHIVE_FORM:-initiative}-2026-10-23"
else
  sed -i.bak -E "s/${POSRE}.*/\\1$((pos + 1))/" "$RM" && rm -f "$RM.bak"
fi
STUB
chmod +x "$WORK/bin/claude"

# make_fixture <name> <status>: prints the fixture root.
make_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  cat > "$d/plan/current-initiative/initiative.md" <<EOF2
---
title: "Initiative: demo"
summary: "Two steps."
status: $2
---
# Initiative: demo

goal: demo
branch: initiative/0000050-demo
status: $2
position: 1

| Step | Feature id | Backlog entries | Bump | Version | Status |
|------|------------|-----------------|------|---------|--------|
| 1 | 0000051-a | 0000011 | minor | | pending |
| 2 | 0000052-b | 0000012 | minor | | pending |
EOF2
  : > "$d/plan/current/build-log.md"
  printf '%s' "$d"
}

# run_driver <root> <mode>: sets OUT and CODE.
run_driver() {
  OUT="$(cd "$1" && PATH="$WORK/bin:$PATH" STUB_LOG="$1/stub.log" STUB_MODE="$2" \
    node "$DRIVER" --root "$1" 2>&1)"
  CODE=$?
}

echo ""
echo "=== req-007 (a): a two-step initiative runs to delivery ==="
R="$(make_fixture a active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (a): driver exits 0 at delivery"
assert_equals "2" "$(wc -l < "$R/stub.log" | tr -d ' ')" "req-007 (a): two steps ran"
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model sonnet Run initiative step 1" "$(sed -n 1p "$R/stub.log")" "req-007 (a): step 1 arguments"
assert_equals "-p --output-format stream-json --verbose --permission-mode auto --model sonnet Run initiative step 2" "$(sed -n 2p "$R/stub.log")" "req-007 (a): step 2 arguments"
assert_equals "0" "$(grep -cE -- '--continue|--resume' "$R/stub.log")" "req-007 (a): no --continue or --resume"
assert_contains "I-C Run:" "$OUT" "req-007 (a): prints I-C Run: lines"
assert_contains "I-D Advance:" "$OUT" "req-007 (a): prints I-D Advance: lines"
assert_contains "I-E Delivery:" "$OUT" "req-007 (a): prints an I-E Delivery: line"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-007 (a): lock released"

echo ""
echo "=== 0000192 req-002: an archive folder in the old form still counts as delivered ==="
R="$(make_fixture a-old active)"
ARCHIVE_FORM=roadmap run_driver "$R" ok
assert_equals "0" "$CODE" "0000192 req-002 AC-3: driver exits 0 with the old archive form"
assert_contains "I-E Delivery:" "$OUT" "0000192 req-002 AC-3: prints an I-E Delivery: line"
assert_equals "yes" "$([ -d "$R/plan/_archive/0000050-demo-roadmap-2026-10-23" ] && echo yes || echo no)" "0000192 req-002 AC-3: fixture used the old form"
assert_equals "yes" "$([ -d "$WORK/a/plan/_archive/0000050-demo-initiative-2026-10-23" ] && echo yes || echo no)" "0000192 req-002 AC-2: case (a) used the new form"

# make_template_fixture <name> <frontmatter status> <body status>: an initiative filled in from the
# real template, quotes kept. Prints the fixture root.
make_template_fixture() {
  local d="$WORK/$1"
  mkdir -p "$d/plan/current-initiative" "$d/plan/current"
  sed -e "s/^status: \"draft\"/status: $2/" \
      -e 's/^\*\*Status:\*\* .*/**Status:** '"$3"'/' \
      -e 's/^\*\*Position:\*\* .*/**Position:** 1/' \
      -e 's/{{id}}/0000050/g; s/{{slug}}/demo/g; s/{{short-title}}/demo/g' \
      -e 's/^| 1 | {{feature id}} .*/| 1 | 0000051-a | 0000011 | minor | | pending |\
| 2 | 0000052-b | 0000012 | minor | | pending |/' \
      "$TPL" > "$d/plan/current-initiative/initiative.md"
  : > "$d/plan/current/build-log.md"
  printf '%s' "$d"
}

echo ""
echo "=== req-007 (a): an initiative built from the real template ==="
R="$(make_template_fixture t-quoted '"active"' active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (a): quoted frontmatter status runs to delivery"
assert_equals "2" "$(wc -l < "$R/stub.log" | tr -d ' ')" "req-007 (a): template initiative ran two steps"
R="$(make_template_fixture t-single "'active'" active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (a): single-quoted frontmatter status runs"
R="$(make_template_fixture t-body-wins '"draft"' active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (a): the body Status field wins over the frontmatter"
R="$(make_template_fixture t-body-draft '"active"' draft)"
run_driver "$R" ok
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (a): a draft body Status stops the driver"

echo ""
echo "=== req-007 (b): refuses to start ==="
R="$(make_fixture b-draft draft)"
run_driver "$R" ok
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (b): non-zero exit when status is draft"
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-007 (b): no step ran for draft"

R="$(make_fixture b-lock active)"
echo "other-driver" > "$R/plan/.initiative-runner.lock"
run_driver "$R" ok
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (b): non-zero exit when the lock exists"
assert_equals "no" "$([ -e "$R/stub.log" ] && echo yes || echo no)" "req-007 (b): no step ran with a lock"
assert_equals "other-driver" "$(cat "$R/plan/.initiative-runner.lock")" "req-007 (b): pre-existing lock untouched"

echo ""
echo "=== req-007 (c): stop rules ==="
R="$(make_fixture c-block active)"
run_driver "$R" block
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (c): non-zero exit on Blocked:"
assert_contains "Blocked: needs a human decision on step 1" "$OUT" "req-007 (c): stop line repeats the Blocked: message"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-007 (c): lock released after a block"

R="$(make_fixture c-resolved active)"
printf 'Blocked: old\nResolved: old\n' > "$R/plan/current/build-log.md"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (c): a Resolved: line after Blocked: does not stop the driver"

# A build log may write the stop as a list item (live acceptance run, step 1).
R="$(make_fixture c-list-block active)"
printf -- '- Blocked: listed stop\n' > "$R/plan/current/build-log.md"
run_driver "$R" ok
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (c): non-zero exit on a list-item Blocked: line"
assert_contains "Blocked: listed stop" "$OUT" "req-007 (c): stop line repeats a list-item Blocked: message"

R="$(make_fixture c-list-resolved active)"
printf -- '- Blocked: old\n* Resolved: old\n' > "$R/plan/current/build-log.md"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (c): a list-item Resolved: line clears a list-item Blocked: line"

R="$(make_fixture c-stall active)"
run_driver "$R" stall
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (c): non-zero exit on a stalled position"
assert_contains "position" "$OUT" "req-007 (c): stop line names the stalled position"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-007 (c): lock released after a stall"

R="$(make_fixture c-fail active)"
run_driver "$R" fail
[ "$CODE" -ne 0 ] && r=yes || r=no
assert_equals "yes" "$r" "req-007 (c): non-zero exit when claude fails"
assert_equals "no" "$([ -e "$R/plan/.initiative-runner.lock" ] && echo yes || echo no)" "req-007 (c): lock released after a failure"

echo ""
echo "=== req-007 (d): runner lock is excluded from git ==="
R="$(make_fixture d-git active)"
git -C "$R" init -q
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (d): driver exits 0 in a git work tree"
assert_equals "1" "$(grep -cxF 'plan/.initiative-runner.lock' "$R/.git/info/exclude")" "req-007 (d): lock path added to info/exclude"
R="$(make_fixture d-git-rerun active)"
git -C "$R" init -q
run_driver "$R" ok
run_driver "$R" ok
assert_equals "1" "$(grep -cxF 'plan/.initiative-runner.lock' "$R/.git/info/exclude")" "req-007 (d): a second run does not duplicate the entry"
R="$(make_fixture d-nogit active)"
run_driver "$R" ok
assert_equals "0" "$CODE" "req-007 (d): driver exits 0 outside a git work tree"
assert_equals "no" "$([ -e "$R/.git" ] && echo yes || echo no)" "req-007 (d): no git directory created outside a work tree"

print_summary
