#!/usr/bin/env bash
# Test: 0000151 req-011 orchestrator-references-split
# Rarely used orchestrator sections live in references/orchestrator-*.md. The
# test proves the size target, that no rule line was lost, that the Pack Index
# lists every reference file, and that setup installs the files.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$ZERO_DIR/.." && pwd)"

SKILL_DIR="$ZERO_DIR/skills/ravintio-orchestrator"
SKILL="$SKILL_DIR/SKILL.md"
REFS="$SKILL_DIR/references"
# 0000244 moved the initiative stage prefix block here.
ROADMAP_STD="$ZERO_DIR/standards/roadmap-standards.md"
# SKILL.md at the base commit 8b1e929 (36,275 bytes after the 0000189 rename), kept as a fixture so the
# check does not depend on git history.
BASE="$SCRIPT_DIR/fixtures/0000151-orchestrator-skill-base.md"

TMP="$(mktemp -d -t ravintio_0000151_req011_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# The fixture predates the 0000160 rename. Compare its lines after the same
# brand rewrite that 0000160 applied to SKILL.md.
BASE_RENAMED="$TMP/base-renamed.md"
sed -e "s/PLANIFEST/RAVINTIO/g" -e "s/Planifest\([A-Z]\)/Ravintio\1/g" \
  -e "s/Planifest/RAVINTIO/g" -e "s/planifest/ravintio/g" "$BASE" > "$BASE_RENAMED.tmp"
# 0000171 ADR-004 dropped the bundle fields and gave pack files full paths.
# Apply the same rewrite to the base lines.
sed -e "/^bundle_templates:/d" -e "/^bundle_standards:/d" \
  -e 's|(see `roadmap-standards.md`)|(see `ravintio-zero/standards/roadmap-standards.md`)|' \
  "$BASE_RENAMED.tmp" > "$BASE_RENAMED.tmp2"
# 0000199 replaced the folder-scan id rule in backlog pickup with the counter file.
sed -e 's|Backlog ids come from their own monotonic sequence: the next id is the highest ever allocated plus one, including spent ids\. Check `plan/_archive/` and `plan/changelog/` for the high-water mark\.|Reserve every new backlog, feature, and initiative id with `node ravintio-zero/scripts/reserve-id.mjs [qty]`. It takes ids from the counter file `plan/backlog/.next-id`, so spent ids never return.|' \
  "$BASE_RENAMED.tmp2" > "$BASE_RENAMED.tmp3"
# 0000205 split initiative resume out of the orchestrator. Drop the old step 3 lines that the
# initiative skill now owns, and add the new step 3 lines.
sed -e '/^   - If an initiative is `active` and `plan\/current\/` holds artifacts, resume that step/d' \
  -e '/^   - If an initiative is `active`, `plan\/current\/` is empty, and `position` is past/d' \
  -e '/^   - If an initiative is `active` and `plan\/current\/` is empty, start the step/d' \
  -e 's|^3\. \*\*Check the initiative, then scan `plan/current/`\.\*\* Check `plan/current-initiative/` first\.$|3. **Check the initiative, then scan `plan/current/`.** Check `plan/current-initiative/` first. The orchestrator never resumes an initiative.\n   - A step session has `RAVINTIO_INITIATIVE_STEP=1` or the prompt `Run initiative step {n}`. With `plan/current/` artifacts, resume that step through the rest of this list.\n   - A step session with `plan/current/` empty starts the step at `position` and opens with `I-C Run: Starting: {step}`.\n   - If an initiative is `active` and this is not a step session, load `ravintio-initiative` and stop. It owns I-A, I-B, and I-E.|' \
  "$BASE_RENAMED.tmp3" > "$BASE_RENAMED.tmp4"
# 0000244 replaced the Pack Index template rows with one rule that names {artifact}.template.md.
sed -e '/^| Discovery findings | `ravintio-zero\/templates\//d' -e '/^| A feature brief request |/d' \
  -e '/^| The build log | `ravintio-zero\/templates\//d' -e '/^| `plan\/current\/design.md` | `ravintio-zero\/templates\//d' \
  -e '/^| A backlog entry | `ravintio-zero\/templates\//d' -e '/^| An initiative draft or plan | `ravintio-zero\/templates\//d' \
  -e '/^| A pause record |/d' -e '/^| A park record |/d' \
  -e "/^Never assume you know a template's format\\./d" \
  "$BASE_RENAMED.tmp4" > "$BASE_RENAMED"

# Print every non-blank, non-heading line of $1 that no later file holds as a
# whole line. Usage: missing_lines base file...
missing_lines() {
  local base="$1"; shift
  local all="$TMP/all.$$"
  cat "$@" > "$all"
  grep -v '^[[:space:]]*$' "$base" | grep -v '^#' | grep -vx -- '---' | while IFS= read -r line; do
    grep -Fxq -- "$line" "$all" || printf '%s\n' "$line"
  done
}

echo "=== (a) size target ==="
# Byte size of a boot file without its override block: every line from the
# ravintio-overrides:instructions start marker to the end marker is dropped.
# Setup appends that block, so counting it makes each override a pack change.
pack_claude_bytes() {
  awk '/<!-- ravintio-overrides:instructions:start -->/ {skip=1; held=""}
       !skip { if ($0 == "") held = held "\n"; else { printf "%s%s\n", held, $0; held = "" } }
       /<!-- ravintio-overrides:instructions:end -->/ {skip=0}' "$1" | wc -c | tr -d ' '
}
SKILL_BYTES=$(wc -c < "$SKILL" | tr -d ' ')
# 0000245 caps the boot file on its own. The boot template is the pack content, so the measure ignores a stale install.
BOOT_FILE="$ZERO_DIR/templates/standard-boot.md"
CLAUDE_BYTES=$(pack_claude_bytes "$BOOT_FILE")
assert_equals "36275" "$(wc -c < "$BASE" | tr -d ' ')" "fixture holds the 36,275 byte baseline"
# 0000244 moved the task-bound sections to references/, so the SKILL.md cap fell from 27,800 to 9,000 bytes.
SKILL_CAP=9000
assert_equals "yes" "$([ "$SKILL_BYTES" -le "$SKILL_CAP" ] && echo yes || echo no)" "SKILL.md is $SKILL_CAP bytes or fewer ($SKILL_BYTES)"
# Cap raised from 35,484 to 35,600 for the initiative rename (0000189).
# Caps raised to 27,700 and 37,800 for the reporting rule and the Supervise prefix (0000200).
# Cap raised to 27,800 for the initiative resume split (0000205).
# 0000245 split the combined cap. The boot template has its own cap, as backlog entry 0000222 asked. The pack-only
# boot template measured 3,414 bytes on 2026-10-28, and the cap leaves margin. The generated CLAUDE.md has a separate
# 6,000 byte cap in test-0000245-req-003-004.
CLAUDE_CAP=3600
assert_equals "yes" "$([ "$CLAUDE_BYTES" -le "$CLAUDE_CAP" ] && echo yes || echo no)" "pack-only boot template is $CLAUDE_CAP bytes or fewer ($CLAUDE_BYTES)"

echo "=== (a) overrides never change the size cap result ==="
printf 'plain boot text\n' > "$TMP/nomarkers.md"
assert_equals "$(wc -c < "$TMP/nomarkers.md" | tr -d ' ')" "$(pack_claude_bytes "$TMP/nomarkers.md")" "a file with no markers is counted whole"
cp "$BOOT_FILE" "$TMP/with-override.md"
{
  echo ""
  echo "<!-- ravintio-overrides:instructions:start -->"
  head -c 5000 /dev/zero | tr '\0' 'x'
  echo ""
  echo "<!-- ravintio-overrides:instructions:end -->"
} >> "$TMP/with-override.md"
assert_equals "$(pack_claude_bytes "$BOOT_FILE")" "$(pack_claude_bytes "$TMP/with-override.md")" "an appended 5,000 byte override block leaves the measure unchanged"

echo "=== (a) mutation: pack growth fails each cap ==="
MARGIN=$((CLAUDE_CAP - CLAUDE_BYTES))
GROWN=$((CLAUDE_BYTES + MARGIN + 1))
assert_equals "no" "$([ "$GROWN" -le "$CLAUDE_CAP" ] && echo yes || echo no)" "$((MARGIN + 1)) extra boot template bytes break the cap ($GROWN)"
SMARGIN=$((SKILL_CAP - SKILL_BYTES))
SGROWN=$((SKILL_BYTES + SMARGIN + 1))
assert_equals "no" "$([ "$SGROWN" -le "$SKILL_CAP" ] && echo yes || echo no)" "$((SMARGIN + 1)) extra SKILL.md bytes break the cap ($SGROWN)"

echo "=== (a) no rule line was lost ==="
REF_FILES=$(ls "$REFS"/orchestrator-*.md 2>/dev/null)
assert_equals "yes" "$([ -n "$REF_FILES" ] && echo yes || echo no)" "reference files exist"
# shellcheck disable=SC2086
MISSING="$(missing_lines "$BASE_RENAMED" "$SKILL" $REF_FILES "$ROADMAP_STD")"
assert_equals "" "$MISSING" "every base line is in SKILL.md or a reference file"

echo "=== (a) mutation: removing one moved line makes the check fail ==="
MUT_LINE='**Confirmation is human-only, per item.**'
MUT_FILE="$REFS/orchestrator-scope-lock.md"
assert_equals "1" "$(grep -cF -- "$MUT_LINE" "$MUT_FILE")" "the mutation target is in the reference file once"
assert_equals "0" "$(grep -cF -- "$MUT_LINE" "$SKILL")" "the mutation target is not in SKILL.md"
mkdir -p "$TMP/mut"
for f in $REF_FILES; do cp "$f" "$TMP/mut/"; done
grep -vF -- "$MUT_LINE" "$MUT_FILE" > "$TMP/mut/orchestrator-scope-lock.md"
# shellcheck disable=SC2046
MUT_MISSING="$(missing_lines "$BASE_RENAMED" "$SKILL" $(ls "$TMP"/mut/orchestrator-*.md) "$ROADMAP_STD")"
assert_contains "Confirmation is human-only" "$MUT_MISSING" "the check reports the removed line"

echo "=== (b) inline sections keep their original text ==="
section_lines() { # file heading: lines of the section, without the heading
  awk -v h="$2" '$0==h {on=1; next} on && /^## / {exit} on {print}' "$1"
}
for h in '## Hard Limits' '## Resume Detection' '## Exception Stops' '## Phase Invocation (P1 to P4)'; do
  section_lines "$BASE_RENAMED" "$h" > "$TMP/sec.base"
  assert_equals "yes" "$([ -s "$TMP/sec.base" ] && echo yes || echo no)" "base has $h"
  # 0000243 moved the Resume Detection checks into a reference file.
  HOLDERS=("$SKILL")
  [ "$h" = '## Resume Detection' ] && HOLDERS+=("$REFS/orchestrator-resume-detection.md")
  # 0000244 moved Exception Stops and Phase Invocation into reference files.
  [ "$h" = '## Exception Stops' ] && HOLDERS=("$REFS/orchestrator-exception-stops.md")
  [ "$h" = '## Phase Invocation (P1 to P4)' ] && HOLDERS=("$REFS/orchestrator-phase-invocation.md")
  assert_equals "" "$(missing_lines "$TMP/sec.base" "${HOLDERS[@]}")" "$h: every base line is still in ${HOLDERS[*]##*/}"
done
# 0000244 moved the P0 subsections into reference files: Discovery Start Actions, Discovery Gate Checklist, and Design Confirmation.
for pair in 'How You Coach|orchestrator-p0-coaching.md' 'Discovery Start Actions|orchestrator-p0-start-actions.md' 'Discovery Gate Checklist|orchestrator-p0-gate.md' 'Design Confirmation (the discovery gate)|orchestrator-p0-gate.md'; do
  h="### ${pair%%|*}"; f="$REFS/${pair##*|}"
  awk -v h="$h" '$0==h {on=1; next} on && /^###? / {exit} on {print}' "$BASE_RENAMED" > "$TMP/sec.base"
  assert_equals "" "$(missing_lines "$TMP/sec.base" "$f")" "$h: every base line is in ${f##*/}"
  assert_equals "1" "$(grep -cxF -- "$h" "$f")" "$h is a heading in ${f##*/}"
  assert_equals "0" "$(grep -cxF -- "$h" "$SKILL")" "$h is no longer a heading in SKILL.md"
done
for h in '## Hard Limits' '## Resume Detection' '## Phases and Response Prefixes' '## Pack Index (JIT Loading)' '## Subagent Dispatch'; do
  assert_equals "1" "$(grep -cxF -- "$h" "$SKILL")" "SKILL.md keeps the heading $h"
done
for h in '## Exception Stops' '## Phase Invocation (P1 to P4)'; do
  assert_equals "0" "$(grep -cxF -- "$h" "$SKILL")" "$h is no longer a heading in SKILL.md"
  assert_equals "1" "$(cat "$REFS"/orchestrator-*.md | grep -cxF -- "$h")" "$h is a heading in exactly one reference file"
done

echo "=== (b) Pack Index lists every reference file ==="
INDEX="$(sed -n '/^## Pack Index/,/^---$/p' "$SKILL")"
COUNT=0
for f in "$REFS"/*; do
  n="$(basename "$f")"
  [ "$n" = ".gitkeep" ] && continue
  COUNT=$((COUNT + 1))
  assert_contains "references/$n" "$INDEX" "Pack Index has a row for $n"
  assert_equals "yes" "$([[ "$n" == orchestrator-*.md ]] && echo yes || echo no)" "$n has the orchestrator- prefix"
done
assert_equals "yes" "$([ "$COUNT" -ge 6 ] && echo yes || echo no)" "at least the required sections moved ($COUNT files)"
assert_contains "Before you act on" "$INDEX" "Pack Index states the read-before-acting rule"
for h in 'Adoption Modes' 'Retrofit Scan' 'Pause Command' 'Park Command' 'Phase Skip Protocol' 'Standalone and Subagent Skills' 'Capability Skills' 'Mid-Pipeline Requirement Changes'; do
  assert_equals "yes" "$(grep -qE "^#+ $h" $REF_FILES && echo yes || echo no)" "$h now lives in a reference file"
  assert_equals "0" "$(grep -cE "^#+ $h" "$SKILL")" "$h is no longer a heading in SKILL.md"
done

echo "=== (b) 0000244: template rule and initiative prefixes ==="
assert_contains 'ravintio-zero/templates/{artifact}.template.md' "$INDEX" "Pack Index holds the template rule"
assert_equals "0" "$(printf '%s\n' "$INDEX" | grep -c '^| .*\.template\.md` |$')" "Pack Index has no per-template row"
assert_contains 'roadmap-standards.md' "$(grep -F 'Initiative stages use the prefixes I-A to I-E' "$SKILL")" "SKILL.md points at the roadmap standards for the I-A to I-E prefixes"
for p in 'I-A Chart:' 'I-B Activate:' 'I-C Run:' 'I-D Advance:' 'I-E Delivery:'; do
  assert_equals "yes" "$(grep -qF "| \`$p\` |" "$ROADMAP_STD" && echo yes || echo no)" "roadmap-standards.md lists $p"
done

echo "=== (c) setup installs the reference files ==="
WS="$(mktemp -d -t ravintio_0000151_req011_ws_XXXXXX)"
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && GIT_CEILING_DIRECTORIES="$(dirname "$WS")" bash ravintio-zero/setup.sh claude-code >"$WS/setup.out" 2>"$WS/setup.err")
assert_exit_zero "$?" "setup.sh exits 0"
INST="$WS/.claude/skills/ravintio-orchestrator/references"
for f in $REF_FILES; do
  n="$(basename "$f")"
  assert_equals "yes" "$([ -f "$INST/$n" ] && cmp -s "$f" "$INST/$n" && echo yes || echo no)" "installed copy of $n matches the source"
done
rm -rf "$WS"

print_summary
