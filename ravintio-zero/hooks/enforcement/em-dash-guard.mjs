#!/usr/bin/env node
/**
 * PreToolUse hook: em dash write-time guard (REQ-006, ADR-003, feature 0000028).
 *
 * Rejects the em dash character (U+2014) in content being written to RAVINTIO
 * prose artifacts. Sibling to gate-write.mjs and ratchet-check.mjs in this
 * directory, not a modification of either — a defect here never disables them.
 *
 * Receives: JSON on stdin conforming to the RAVINTIO common envelope (ADR-002)
 * or the raw Claude Code PreToolUse hook input. Reads tool_input.content
 * (Write) or tool_input.new_string (Edit) only — never the existing file on
 * disk, and never the wider repo. Only the write being made right now is
 * scanned, matching the commit-msg precedent of inspecting only what is being
 * committed right now.
 *
 * Scope: plan/current/, docs/, ravintio-zero/skills/,
 * ravintio-zero/templates/, ravintio-zero/standards/. Everything
 * else, including plan/_archive/, plan/changelog/, source code, and this
 * hook's own source and test fixtures under ravintio-zero/hooks/ and
 * ravintio-zero/tests/, passes without inspection: those paths simply
 * fall outside the five prefixes above, so the guard's own fixtures can
 * contain the character it is designed to catch without needing a bypass.
 *
 * Bypass: a single-line sentinel comment, <!-- ravintio-em-dash-allow -->,
 * present anywhere in the content being written, allows that write through
 * regardless of em dash matches. Reusable, not single-use, and writable by
 * either a human or an agent — unlike plan/current/.ratchet-approve, which is
 * human-only and single-use. An em dash carries no weakening semantics (it is
 * a style rule about one character, not a commitment being relaxed), so there
 * is nothing here that needs a human-only, single-use marker. See ADR-003 and
 * ravintio-zero/standards/formatting-standards.md for the full
 * rationale.
 *
 * Exit codes: 0 = pass, 2 = block (matching gate-write.mjs and ratchet-check.mjs).
 * Silent on unexpected errors — always exit 0 on non-enforcement failures (ADR-005).
 */

import { normalize, resolve } from "node:path";

import { readStdin } from "./read-stdin.mjs";

const EM_DASH = "—";
const SENTINEL = "<!-- ravintio-em-dash-allow -->";
// Legacy alias, remove at 1.0.0 (0000160 ADR-002).
const LEGACY_SENTINEL = "<!-- planifest-em-dash-allow -->";

// Mirrors REQ-006's scope list and gate-write.mjs's ALWAYS_PERMITTED_PREFIXES shape.
const SCOPED_PREFIXES = [
  "plan/current/",
  "docs/",
  "ravintio-zero/skills/",
  "ravintio-zero/templates/",
  "ravintio-zero/standards/",
];

function norm(p) {
  return normalize(p).replace(/\\/g, "/").toLowerCase();
}

function isScoped(relPath) {
  const n = norm(relPath);
  return SCOPED_PREFIXES.some((prefix) => n.startsWith(prefix));
}

function findEmDashLines(content) {
  const lines = content.split("\n");
  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes(EM_DASH)) hits.push(i + 1);
  }
  return hits;
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);

  // Support both common envelope (ADR-002) and raw Claude Code hook input.
  const cwd = input?.cwd ?? process.cwd();
  const toolInput = input?.tool_input ?? input;
  const rawTarget = toolInput?.path ?? toolInput?.file_path ?? "";

  // No target path = pass (not a file-writing tool call).
  if (!rawTarget) process.exit(0);

  // Write carries tool_input.content; Edit carries tool_input.new_string.
  // Neither present = nothing to scan (e.g. a read-adjacent tool call).
  const content = typeof toolInput?.content === "string"
    ? toolInput.content
    : typeof toolInput?.new_string === "string"
      ? toolInput.new_string
      : null;
  if (content === null) process.exit(0);

  // Resolve to a path relative to cwd for prefix matching, mirroring
  // gate-write.mjs's normalisation so Windows/mixed-separator paths match.
  const absTarget = resolve(cwd, rawTarget);
  const normCwd = norm(cwd);
  const normAbs = norm(absTarget);
  const cwdPrefix = normCwd.endsWith("/") ? normCwd : normCwd + "/";
  const relTarget = normAbs.startsWith(cwdPrefix)
    ? normAbs.slice(cwdPrefix.length)
    : norm(rawTarget);

  // Out of scope — pass without inspecting content at all.
  if (!isScoped(relTarget)) process.exit(0);

  // Sentinel bypass (ADR-003): reusable, agent- or human-writable.
  if (content.includes(SENTINEL) || content.includes(LEGACY_SENTINEL)) process.exit(0);

  const hits = findEmDashLines(content);
  if (hits.length === 0) process.exit(0);

  const MAX_LISTED = 20;
  const listed = hits.slice(0, MAX_LISTED).join(", ");
  const more = hits.length > MAX_LISTED ? ` (+${hits.length - MAX_LISTED} more)` : "";

  const message =
    `[RAVINTIO] Em dash (U+2014) found in '${relTarget}' at line(s): ${listed}${more}. ` +
    "Replace with a comma, colon, semicolon, full stop, or parentheses depending " +
    "on the sentence. If the character is genuinely required (a literal quotation, " +
    `for example), add ${SENTINEL} anywhere in the content to bypass. ` +
    "See ravintio-zero/standards/hook-enforcement.md.\n";
  // Claude Code shows the agent only stderr on exit 2. Stdout keeps the tests' view.
  process.stderr.write(message);
  process.stdout.write(message);
  process.exit(2);
} catch {
  // Never block the session on unexpected errors (ADR-005).
  process.exit(0);
}
