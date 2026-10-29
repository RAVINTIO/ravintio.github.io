#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-013: initiative telemetry labels.
#
# scripts/initiative-run.mjs appends labels to OTEL_RESOURCE_ATTRIBUTES in the child environment.
# A stub claude prints the value it sees and a sorted copy of its environment.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
LABELS="$SCRIPT_DIR/../scripts/initiative-labels.mjs"
STANDARDS="$SCRIPT_DIR/../standards/roadmap-standards.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub claude: logs the label variable and the rest of its environment, then advances.
printenv OTEL_RESOURCE_ATTRIBUTES >> "$STUB_LOG"
env | grep -v '^OTEL_RESOURCE_ATTRIBUTES=' | grep -v '^_=' | grep -v '^SHLVL=' | grep -v '^PWD=' | LC_ALL=C sort > "$STUB_LOG.env"
RM=plan/current-initiative/initiative.md
POSRE='^((\*\*)?[Pp]osition:?(\*\*)? *:? *)'
pos="$(sed -nE "s/${POSRE}//p" "$RM")"
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

echo ""
echo "=== req-013 (a): label values ==="
R="$(make_fixture a-unset)"
(cd "$R" && env -u OTEL_RESOURCE_ATTRIBUTES PATH="$WORK/bin:$PATH" STUB_LOG="$R/stub.log" node "$DRIVER" --root "$R" >/dev/null 2>&1)
assert_equals "work.kind=initiative,ravintio.initiative=0000050-demo,ravintio.step=1" "$(sed -n 1p "$R/stub.log")" "req-013 (a): unset variable gets the three labels"
assert_equals "work.kind=initiative,ravintio.initiative=0000050-demo,ravintio.step=2" "$(sed -n 2p "$R/stub.log")" "req-013 (a): step 2 labels the position"

R="$(make_fixture a-set)"
(cd "$R" && OTEL_RESOURCE_ATTRIBUTES='service.name=x,team=a' PATH="$WORK/bin:$PATH" STUB_LOG="$R/stub.log" node "$DRIVER" --root "$R" >/dev/null 2>&1)
assert_equals "service.name=x,team=a,work.kind=initiative,ravintio.initiative=0000050-demo,ravintio.step=1" "$(sed -n 1p "$R/stub.log")" "req-013 (a): old value kept and labels appended"

echo ""
echo "=== req-013 (b): encoder and edge cases ==="
ENC="$(node --input-type=module -e "import { encodeLabelValue as e } from '$LABELS'; process.stdout.write(e('a,b=c d%e'))")"
assert_equals "a%2Cb%3Dc%20d%25e" "$ENC" "req-013 (b): encoder escapes comma, equals, space, percent"
JOIN="$(node --input-type=module -e "import { withInitiativeLabels as w } from '$LABELS'; process.stdout.write(w('k=v,', '0000050', 'demo', '1'))")"
assert_equals "k=v,work.kind=initiative,ravintio.initiative=0000050-demo,ravintio.step=1" "$JOIN" "req-013 (b): a trailing comma adds no second comma"
JOIN="$(node --input-type=module -e "import { withInitiativeLabels as w } from '$LABELS'; process.stdout.write(w('k=a%2Cb', '0000050', 'demo', '1'))")"
assert_contains "k=a%2Cb,work.kind" "$JOIN" "req-013 (b): old value is not re-encoded"

echo ""
echo "=== req-013 (c): isolation ==="
R="$(make_fixture c-iso)"
(cd "$R" && env | grep -v '^_=' | grep -v '^SHLVL=' | grep -v '^PWD=' | grep -v '^OTEL_RESOURCE_ATTRIBUTES=' | LC_ALL=C sort > "$R/parent.env"
 OTEL_RESOURCE_ATTRIBUTES='service.name=x' PATH="$WORK/bin:$PATH" STUB_LOG="$R/stub.log" node "$DRIVER" --root "$R" >/dev/null 2>&1)
# The driver and the stub add PATH and STUB_LOG, which the parent snapshot lacks. Compare the rest.
grep -v -e '^PATH=' -e '^STUB_LOG=' -e '^CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=' -e '^RAVINTIO_INITIATIVE_STEP=' -e '^OLDPWD=' -e '^__CF_' "$R/parent.env" > "$R/p.env"
grep -v -e '^PATH=' -e '^STUB_LOG=' -e '^CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=' -e '^RAVINTIO_INITIATIVE_STEP=' -e '^OLDPWD=' -e '^__CF_' "$R/stub.log.env" > "$R/c.env"
assert_equals "0" "$(diff "$R/p.env" "$R/c.env" | grep -c '^[<>]')" "req-013 (c): no other child variable differs"
# The driver passes the labels through spawn's env option and never assigns
# to its own process.env, so its environment stays as it was.
assert_equals "0" "$(grep -cE 'process\.env(\.[A-Z_]+|\[[^]]+\])? *=[^=]' "$DRIVER" || true)" "req-013 (c): the driver never assigns to its own environment"

echo ""
echo "=== req-013 (c): documentation ==="
HEAD_TXT="$(sed -n '1,70p' "$DRIVER")"
for f in "$HEAD_TXT" "$(cat "$STANDARDS")"; do
  assert_contains "work.kind=initiative" "$f" "req-013: names work.kind"
  assert_contains "ravintio.initiative=" "$f" "req-013: names ravintio.initiative"
  assert_contains "ravintio.step=" "$f" "req-013: names ravintio.step"
done

print_summary
