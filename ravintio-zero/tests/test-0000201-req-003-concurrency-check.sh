#!/usr/bin/env bash
# 0000201 req-003: concurrency-check
# consistency-check.mjs check 8 validates the Concurrency plan table in execution-plan.md.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

CHECK="$ZERO_DIR/scripts/consistency-check.mjs"
TMP="$(mktemp -d -t ravintio_0000201_req003_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

HEADER='| Unit | Depends on | Writes | Batch | Sequential reason |
|------|------------|--------|-------|-------------------|'

# Build a fixture with a design and no execution plan. Prints the plan/current path.
make_fixture() {
  local d="$TMP/$1/plan/current"
  mkdir -p "$d"
  printf '# Design\n## Scope\n- In: things\n' > "$d/design.md"
  echo "$d"
}

# Write an execution plan with a Concurrency plan section. Rows come from stdin.
write_plan() {
  { printf '# Execution plan\n\n## Concurrency plan\n\n%s\n' "$HEADER"; cat; printf '\n## Assumptions\n- none\n'; } > "$1/execution-plan.md"
}

count_findings() { printf '%s\n' "$1" | grep -c '✖'; }

echo ""
echo "=== 0000201 req-003 concurrency-check ==="

# AC-1: a valid plan passes
D=$(make_fixture valid)
write_plan "$D" <<'MD'
| U1-a | none | `src/a.txt`, `src/b.txt` | 1 | |
| U2-b | - | `src/c.txt` | 1 | none |
| U3-c | U1-a, `U2-b` | `src/d.txt` | 2 | Reads the final wording of U1 and U2. |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "0" "$RC" "req-003 AC-1: valid plan exits 0"
assert_contains "consistency-check: clean" "$OUT" "req-003 AC-1: valid plan prints clean"

# Skip: no execution-plan.md
D=$(make_fixture noplan)
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "0" "$RC" "req-003 skip: missing execution-plan.md exits 0"
case "$OUT" in *execution-plan*) echo "  FAIL: req-003 skip: finding for a missing execution plan"; FAIL=$((FAIL+1));; *) echo "  PASS: req-003 skip: no execution-plan finding"; PASS=$((PASS+1));; esac

# AC-2: plan without the section
D=$(make_fixture nosection)
printf '# Execution plan\n\n## Assumptions\n- none\n' > "$D/execution-plan.md"
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-2: missing section exits 1"
assert_contains "execution-plan.md: no '## Concurrency plan' section" "$OUT" "req-003 AC-2: finding names the missing section"

# AC-2 extension: section with no table, and a table with no unit row
D=$(make_fixture notable)
printf '# Execution plan\n\n## Concurrency plan\n\nSome prose only.\n' > "$D/execution-plan.md"
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-2: section without a table exits 1"
assert_contains "execution-plan.md" "$OUT" "req-003 AC-2: no-table finding names the file"

D=$(make_fixture norows)
write_plan "$D" < /dev/null
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-2: table without unit rows exits 1"
assert_contains "no unit row" "$OUT" "req-003 AC-2: finding says there is no unit row"

# AC-3: unjustified sequential unit (alone in its batch, empty reason)
for reason in "" "none" "-"; do
  D=$(make_fixture "seq$reason")
  write_plan "$D" <<MD
| U1-a | none | \`src/a.txt\` | 1 | $reason |
| U2-b | none | \`src/b.txt\` | 1 | |
| U3-lone | U1-a | \`src/c.txt\` | 2 | $reason |
MD
  OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
  assert_equals "1" "$RC" "req-003 AC-3: unjustified sequential unit exits 1 (reason '$reason')"
  assert_contains "U3-lone" "$OUT" "req-003 AC-3: finding names the lone unit (reason '$reason')"
  assert_equals "1" "$(count_findings "$OUT")" "req-003 AC-3: one finding for the lone unit (reason '$reason')"
done

# AC-3: shared write path in one batch
D=$(make_fixture shared)
write_plan "$D" <<'MD'
| U1-a | none | `src/a.txt`, `src/shared.txt` | 1 | |
| U2-b | none | `src/shared.txt` | 1 | |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-3: shared Writes path exits 1"
assert_contains "U1-a" "$OUT" "req-003 AC-3: shared path finding names the first unit"
assert_contains "U2-b" "$OUT" "req-003 AC-3: shared path finding names the second unit"
assert_contains "src/shared.txt" "$OUT" "req-003 AC-3: shared path finding names the path"

# AC-3: Depends on an unknown unit
D=$(make_fixture unknown)
write_plan "$D" <<'MD'
| U1-a | U9-ghost | `src/a.txt` | 1 | |
| U2-b | none | `src/b.txt` | 1 | |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-3: unknown dependency exits 1"
assert_contains "U9-ghost" "$OUT" "req-003 AC-3: finding names the unknown dependency"
assert_contains "U1-a" "$OUT" "req-003 AC-3: finding names the unit"

# AC-3: Depends on a unit in the same batch, and in a later batch
D=$(make_fixture order)
write_plan "$D" <<'MD'
| U1-a | U2-b | `src/a.txt` | 1 | |
| U2-b | none | `src/b.txt` | 1 | |
| U3-c | U4-d | `src/c.txt` | 2 | |
| U4-d | none | `src/d.txt` | 3 | Waits for U3-c output. |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-3: same or later batch dependency exits 1"
assert_contains "U1-a" "$OUT" "req-003 AC-3: same-batch dependency finding names U1-a"
assert_contains "U3-c" "$OUT" "req-003 AC-3: later-batch dependency finding names U3-c"

# AC-3: non-integer Batch
D=$(make_fixture batch)
write_plan "$D" <<'MD'
| U1-a | none | `src/a.txt` | one | |
| U2-b | none | `src/b.txt` | 0 | |
| U3-c | none | `src/c.txt` | 1.5 | |
MD
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-3: bad Batch exits 1"
assert_contains "U1-a" "$OUT" "req-003 AC-3: text Batch finding names U1-a"
assert_contains "U2-b" "$OUT" "req-003 AC-3: zero Batch finding names U2-b"
assert_contains "U3-c" "$OUT" "req-003 AC-3: decimal Batch finding names U3-c"

# Cap: a long unit name prints through the 200-character cap
LONG=$(printf 'U%.0s' $(seq 1 260))
D=$(make_fixture long)
write_plan "$D" <<MD
| $LONG | ghost | \`src/a.txt\` | 1 | |
MD
OUT=$(node "$CHECK" "$D" 2>&1)
assert_contains "[truncated]" "$OUT" "req-003 cap: long unit name is truncated"

print_summary
