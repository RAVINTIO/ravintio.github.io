#!/usr/bin/env bash
# Tests for feature 0000189-name-the-roadmap-initiative, req-002: renamed names.
#
# AC-1: the driver reads plan/current-initiative/initiative.md, logs to plan/.initiative-logs/,
#       and passes work.kind=initiative and ravintio.initiative labels.
# AC-2: merge-guard allows a squash into initiative/* and blocks roadmap/*.
# AC-3: both CI files list initiative/** and neither lists roadmap/**.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
DRIVER="$ZERO_DIR/scripts/initiative-run.mjs"
GUARD="$ZERO_DIR/hooks/enforcement/merge-guard.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$OTEL_RESOURCE_ATTRIBUTES" > "$STUB_LOG"
echo "step output"
mkdir -p plan/_archive
mv plan/current-initiative "plan/_archive/0000050-demo-roadmap-2026-10-24"
STUB
chmod +x "$WORK/bin/claude"
cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
if [ "$1 $2" = "pr view" ]; then printf '{"baseRefName":"%s"}\n' "$STUB_BASE"; fi
STUB
chmod +x "$WORK/bin/gh"

echo ""
echo "=== req-002 AC-1: driver uses new paths and labels ==="
R="$WORK/drv"
mkdir -p "$R/plan/current-initiative" "$R/plan/current"
cat > "$R/plan/current-initiative/initiative.md" <<'EOT'
---
title: "Initiative: demo"
status: active
---
branch: initiative/0000050-demo
status: active
position: 1
EOT
: > "$R/plan/current/build-log.md"
OUT="$(cd "$R" && env PATH="$WORK/bin:$PATH" STUB_LOG="$R/stub.log" node "$DRIVER" --root "$R" 2>&1)"
CODE=$?
assert_equals "0" "$CODE" "req-002 AC-1: driver exits 0"
assert_contains "work.kind=initiative" "$(cat "$R/stub.log" 2>/dev/null)" "req-002 AC-1: work.kind=initiative label"
assert_contains "ravintio.initiative=0000050-demo" "$(cat "$R/stub.log" 2>/dev/null)" "req-002 AC-1: ravintio.initiative label"
assert_equals "yes" "$([ -f "$R/plan/.initiative-logs/step-1.log" ] && echo yes || echo no)" "req-002 AC-1: log in plan/.initiative-logs/"
assert_equals "no" "$([ -e "$R/plan/.roadmap-logs" ] && echo yes || echo no)" "req-002 AC-1: no plan/.roadmap-logs/"

echo ""
echo "=== req-002 AC-2: merge-guard base ==="
payload() { node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1"; }
guard() {
  OUT=$(payload "gh pr merge 12 --squash" | env PATH="$WORK/bin:$PATH" STUB_BASE="$1" node "$GUARD" 2>&1)
  CODE=$?
}
guard "initiative/0000001-demo"
assert_equals "0" "$CODE" "req-002 AC-2: squash into initiative/* allowed"
guard "roadmap/0000001-demo"
assert_equals "2" "$CODE" "req-002 AC-2: squash into roadmap/* blocked"
assert_contains "initiative/*" "$OUT" "req-002 AC-2: message names initiative/*"

echo ""
echo "=== req-002 AC-3: CI branches ==="
for f in "$ZERO_DIR/../.github/workflows/ravintio.yml" "$ZERO_DIR/hooks/ravintio.yml"; do
  t="$(cat "$f")"
  l="$(basename "$(dirname "$f")")/ravintio.yml"
  assert_contains "initiative/**" "$t" "req-002 AC-3: $l lists initiative/**"
  assert_equals "no" "$([[ "$t" == *"roadmap/**"* ]] && echo yes || echo no)" "req-002 AC-3: no roadmap/** in $l"
done

print_summary
