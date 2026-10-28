#!/usr/bin/env bash
# Tests for feature 0000200-reply-conventions, req-003: the check-reply-prefix
# Stop hook warns on a missing prefix, logs the miss, and never blocks.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

HOOK="$SCRIPT_DIR/../hooks/enforcement/check-reply-prefix.mjs"

TMP=$(mktemp -d -t ravintio_0000200_req003_XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# new_project: make a fresh project dir with the sentinel and print its path.
new_project() {
  local d
  d=$(mktemp -d "$TMP/proj_XXXXXX")
  mkdir -p "$d/plan"
  : > "$d/plan/.orchestrator-active"
  echo "$d"
}

# write_transcript FILE MODE TEXT...: build a JSONL transcript.
# MODE "string" stores content as a string. MODE "array" stores text blocks.
# Each TEXT becomes one assistant message. A user message comes first.
write_transcript() {
  local file="$1" mode="$2"
  shift 2
  node -e '
    const [file, mode, ...texts] = process.argv.slice(1);
    const fs = require("node:fs");
    const lines = [JSON.stringify({ type: "user", message: { role: "user", content: "hi" } })];
    for (const t of texts) {
      const content = mode === "string" ? t : [{ type: "tool_use", name: "x" }, { type: "text", text: t }];
      lines.push(JSON.stringify({ type: "assistant", message: { role: "assistant", content } }));
    }
    fs.writeFileSync(file, lines.join("\n") + "\n");
  ' "$file" "$mode" "$@"
}

# run_hook CWD TRANSCRIPT: run the hook with a Stop payload.
run_hook() {
  local payload
  payload=$(node -e 'console.log(JSON.stringify({ hook_event_name: "Stop", cwd: process.argv[1], transcript_path: process.argv[2] }))' "$1" "$2")
  OUT=$(printf '%s' "$payload" | node "$HOOK" 2>/dev/null)
  CODE=$?
}

LOG_REL="plan/.prefix-misses.log"
log_lines() { if [ -f "$1/$LOG_REL" ]; then wc -l < "$1/$LOG_REL" | tr -d ' '; else echo 0; fi; }

echo ""
echo "=== req-003 AC-1: a miss warns and logs ==="
P=$(new_project)
LONG="Plain reply with no prefix. $(printf 'x%.0s' $(seq 1 120))"
write_transcript "$TMP/t1.jsonl" string "P2 Implement: earlier" "$LONG"
run_hook "$P" "$TMP/t1.jsonl"
assert_equals "0" "$CODE" "req-003 AC-1: the hook exits 0"
assert_contains '"systemMessage"' "$OUT" "req-003 AC-1: the output carries a systemMessage"
assert_contains "prefix" "$OUT" "req-003 AC-1: the message names the missing prefix"
validate_json "$OUT" >/dev/null 2>&1
assert_equals "1" "$(log_lines "$P")" "req-003 AC-1: one log line is appended"
LINE=$(head -n 1 "$P/$LOG_REL" 2>/dev/null)
assert_contains "Plain reply with no prefix." "$LINE" "req-003 AC-1: the log line holds the start of the reply"
if [[ "$LINE" == *"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"* ]]; then
  assert_equals "trimmed" "not trimmed" "req-003 AC-1: the log line trims the reply to about 80 characters"
else
  assert_equals "trimmed" "trimmed" "req-003 AC-1: the log line trims the reply to about 80 characters"
fi
assert_contains "20" "$LINE" "req-003 AC-1: the log line carries a timestamp"
write_transcript "$TMP/t1b.jsonl" array "Second plain reply"
run_hook "$P" "$TMP/t1b.jsonl"
assert_equals "2" "$(log_lines "$P")" "req-003 AC-1: a second miss appends a second line"
assert_contains '"systemMessage"' "$OUT" "req-003 AC-1: a text-block array reply also warns"

echo ""
echo "=== req-003 AC-1: only the first non-empty line is checked ==="
P=$(new_project)
write_transcript "$TMP/t2.jsonl" string $'\n\nP4 Ship: pushed the branch\nmore text'
run_hook "$P" "$TMP/t2.jsonl"
assert_equals "" "$OUT" "req-003: leading blank lines are skipped and the prefix passes"
write_transcript "$TMP/t2b.jsonl" string $'Plain first line\nP4 Ship: later line'
run_hook "$P" "$TMP/t2b.jsonl"
assert_contains '"systemMessage"' "$OUT" "req-003: a prefix on a later line does not count"

echo ""
echo "=== req-003 AC-2: valid prefixes pass silently ==="
P=$(new_project)
write_transcript "$TMP/t3.jsonl" string "P2 Implement: Starting: write the hook"
run_hook "$P" "$TMP/t3.jsonl"
assert_equals "0" "$CODE" "req-003 AC-2: the hook exits 0"
assert_equals "" "$OUT" "req-003 AC-2: the hook prints nothing"
assert_equals "0" "$(log_lines "$P")" "req-003 AC-2: the hook writes no log line"

for PFX in "P0 Discovery:" "P1 Plan:" "P2 Implement:" "P3 Validate:" "P4 Ship:" \
           "I-A Chart:" "I-B Activate:" "I-C Run:" "I-D Advance:" "I-E Delivery:" "Supervise:"; do
  for MODE in string array; do
    write_transcript "$TMP/tp.jsonl" "$MODE" "$PFX body text"
    run_hook "$P" "$TMP/tp.jsonl"
    assert_equals "" "$OUT" "req-003 AC-2: '$PFX' passes ($MODE content)"
  done
done
assert_equals "0" "$(log_lines "$P")" "req-003 AC-2: no valid prefix wrote a log line"

write_transcript "$TMP/tv.jsonl" string "P3 Validate and Accept: done"
run_hook "$P" "$TMP/tv.jsonl"
assert_contains '"systemMessage"' "$OUT" "req-003 AC-2: 'P3 Validate and Accept:' is not valid"
assert_equals "1" "$(log_lines "$P")" "req-003 AC-2: 'P3 Validate and Accept:' is logged"

echo ""
echo "=== req-003 AC-3: the hook never blocks ==="
P=$(new_project)
rm -f "$P/plan/.orchestrator-active"
write_transcript "$TMP/t4.jsonl" string "Plain reply"
run_hook "$P" "$TMP/t4.jsonl"
assert_equals "0" "$CODE" "req-003 AC-3: no sentinel exits 0"
assert_equals "" "$OUT" "req-003 AC-3: no sentinel prints nothing"
assert_equals "0" "$(log_lines "$P")" "req-003 AC-3: no sentinel logs nothing"

P=$(new_project)
OUT=$(printf '%s' '{not json' | node "$HOOK" 2>/dev/null); CODE=$?
assert_equals "0" "$CODE" "req-003 AC-3: malformed JSON exits 0"
assert_equals "" "$OUT" "req-003 AC-3: malformed JSON prints nothing"
OUT=$(printf '' | node "$HOOK" 2>/dev/null); CODE=$?
assert_equals "0" "$CODE" "req-003 AC-3: empty stdin exits 0"

run_hook "$P" "$TMP/does-not-exist.jsonl"
assert_equals "0" "$CODE" "req-003 AC-3: a missing transcript exits 0"
assert_equals "" "$OUT" "req-003 AC-3: a missing transcript prints nothing"
assert_equals "0" "$(log_lines "$P")" "req-003 AC-3: a missing transcript logs nothing"

node -e 'require("node:fs").writeFileSync(process.argv[1], JSON.stringify({type:"user",message:{role:"user",content:"hi"}})+"\n"+JSON.stringify({type:"assistant",message:{role:"assistant",content:[{type:"tool_use",name:"x"}]}})+"\n")' "$TMP/t5.jsonl"
run_hook "$P" "$TMP/t5.jsonl"
assert_equals "0" "$CODE" "req-003 AC-3: no assistant text exits 0"
assert_equals "" "$OUT" "req-003 AC-3: no assistant text prints nothing"
assert_equals "0" "$(log_lines "$P")" "req-003 AC-3: no assistant text logs nothing"

echo ""
echo "=== req-003: the miss log stays out of git ==="
P=$(new_project)
mkdir -p "$P/.git/info"
write_transcript "$TMP/t9.jsonl" string "Plain reply with no prefix"
run_hook "$P" "$TMP/t9.jsonl"
run_hook "$P" "$TMP/t9.jsonl"
assert_equals "1" "$(grep -cxF 'plan/.prefix-misses.log' "$P/.git/info/exclude")" \
  "req-003: two misses add the log to .git/info/exclude once"

print_summary
