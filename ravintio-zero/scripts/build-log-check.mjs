#!/usr/bin/env node
/**
 * build-log-check.mjs — deterministic check of a finished build log
 * (feature 0000248, ADR-001). Ship runs it in Step 3, before Archive.
 *
 * Usage: node build-log-check.mjs [buildLogPath]   (default: plan/current/build-log.md)
 *
 * Checks:
 *   1. Phases P0 to P4 each have a "### P<n>:" block, unless a line
 *      "Skipped: P<n>" marks the phase as skipped.
 *   2. Each block has a readable Start and End, and a whole-number Wall clock.
 *   3. Wall clock is within one minute of End minus Start.
 *   4. The Summary "Total wall clock" row is filled and not "not recorded".
 *
 * Every finding names the phase. Exit codes: 0 = clean, 1 = findings.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";

const file = process.argv[2] ?? join(process.cwd(), "plan", "current", "build-log.md");
const findings = [];

let text;
try {
  text = readFileSync(file, "utf-8");
} catch {
  console.error("build-log-check: cannot read the build log");
  process.exit(1);
}

const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?Z$/;

/** Value of a "| Field | `value` |" row, with backticks removed. Null if absent. */
function field(body, name) {
  const m = new RegExp(`^\\|\\s*${name}\\s*\\|(.*)\\|\\s*$`, "im").exec(body);
  return m ? m[1].replace(/`/g, "").trim() : null;
}

/** A value that holds nothing: empty, or a template placeholder. */
const blank = (v) => v === null || v === "" || v.includes("{{");

const heads = [...text.matchAll(/^### P([0-4]):.*$/gm)];
const blocks = new Map();
heads.forEach((h, i) => {
  const rest = text.slice(h.index + h[0].length);
  const end = rest.search(/^(###? |---\s*$)/m);
  blocks.set(Number(h[1]), end === -1 ? rest : rest.slice(0, end));
});
const skipped = new Set(
  [...text.matchAll(/^\s*(?:[-*]\s*)?Skipped:\s*P([0-4])\b/gm)].map((m) => Number(m[1])),
);

for (let n = 0; n <= 4; n++) {
  const body = blocks.get(n);
  if (body === undefined) {
    if (!skipped.has(n)) findings.push(`P${n}: no phase block and no "Skipped: P${n}" line`);
    continue;
  }
  const start = field(body, "Start");
  const end = field(body, "End");
  const wall = field(body, "Wall clock");
  let readable = true;
  if (blank(start)) { findings.push(`P${n}: Start is blank`); readable = false; }
  else if (!ISO.test(start)) { findings.push(`P${n}: Start is not an ISO-8601 UTC time`); readable = false; }
  if (blank(end)) { findings.push(`P${n}: End is blank`); readable = false; }
  else if (!ISO.test(end)) { findings.push(`P${n}: End is not an ISO-8601 UTC time`); readable = false; }
  if (blank(wall)) { findings.push(`P${n}: Wall clock is blank`); continue; }
  if (!/^\d+$/.test(wall)) { findings.push(`P${n}: Wall clock is not a whole number of minutes`); continue; }
  if (readable) {
    const span = (Date.parse(end) - Date.parse(start)) / 60000;
    if (span < 0) findings.push(`P${n}: End is before Start`);
    else if (Math.abs(Number(wall) - span) > 1) {
      findings.push(`P${n}: Wall clock ${wall} differs by more than one minute from the ${span.toFixed(1)} minutes between Start and End`);
    }
  }
}

const total = field(text, "Total wall clock");
if (blank(total) || /^not recorded$/i.test(total)) {
  findings.push(`Total wall clock: blank or "not recorded"`);
}

if (findings.length === 0) {
  console.log("build-log-check: clean");
  process.exit(0);
}
console.log(`build-log-check: ${findings.length} finding(s)`);
for (const f of findings) console.log(`  ✖ ${f}`);
process.exit(1);
