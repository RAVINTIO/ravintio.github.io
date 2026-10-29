#!/usr/bin/env node
/**
 * workflow-metrics.mjs - derive four workflow metrics from a run folder.
 *
 * Usage: node workflow-metrics.mjs [--standard <path>] <run-folder>
 *
 * Reads <run-folder>/build-log.md and every <run-folder>/loop-state-*.md.
 * Counts marker lines only (ADR-002). Reads thresholds from the Thresholds
 * table of the workflow governance standard (ADR-003). Reports and never blocks.
 *
 * Exit codes:
 *   0 - the build log and thresholds were read, with or without a breach
 *   1 - build log unreadable, or a threshold key missing or not a whole number
 *   2 - usage error
 *
 * Node.js built-ins only. Writes no file.
 */

import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const DEFAULT_STANDARD = join(HERE, "..", "standards", "workflow-governance-standards.md");

const METRICS = [
  { key: "rework-per-requirement", label: "Rework loops per requirement (highest)" },
  { key: "blocked-stops", label: "`Blocked:` stops" },
  { key: "design-changes", label: "Mid-pipeline design changes" },
  { key: "gate-corrections", label: "Human corrections at gates" },
];

function fail(msg, code = 1) {
  process.stderr.write(`workflow-metrics: ${msg}\n`);
  process.exit(code);
}

function parseArgs(argv) {
  let standard = DEFAULT_STANDARD;
  let folder = null;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--standard") {
      if (i + 1 >= argv.length) usage();
      standard = argv[++i];
    } else if (argv[i].startsWith("--") || folder !== null) {
      usage();
    } else {
      folder = argv[i];
    }
  }
  if (folder === null) usage();
  return { standard, folder };
}

function usage() {
  fail("usage: workflow-metrics.mjs [--standard <path>] <run-folder>", 2);
}

function readText(path) {
  try {
    return readFileSync(path, "utf-8");
  } catch {
    fail(`cannot read ${path}`);
  }
}

// Strip leading whitespace and one optional list marker.
const LIST_PREFIX = /^\s*(?:(?:[-*]|\d+\.)\s+)?/;
const FENCE = /^\s*(```|~~~)/;

function countMarkers(text, tally) {
  let fence = null;
  for (const raw of text.split(/\r?\n/)) {
    const fm = FENCE.exec(raw);
    if (fm) {
      if (fence === null) fence = fm[1];
      else if (fm[1] === fence) fence = null;
      continue;
    }
    if (fence !== null) continue;
    const line = raw.replace(LIST_PREFIX, "");
    const rework = /^Rework: (REQ-\d+):/.exec(line);
    if (rework) {
      tally.rework.set(rework[1], (tally.rework.get(rework[1]) || 0) + 1);
    } else if (line.startsWith("Blocked:")) {
      tally.blocked++;
    } else if (line.startsWith("Requirement change:")) {
      tally.design++;
    } else if (line.startsWith("Gate revised:")) {
      tally.gate++;
    }
  }
}

function readThresholds(path) {
  const lines = readText(path).split(/\r?\n/);
  const found = new Map();
  let inSection = false;
  let keyCol = -1;
  let valCol = -1;
  for (const line of lines) {
    if (/^##\s/.test(line)) {
      inSection = /^##\s+Thresholds\s*$/.test(line);
      keyCol = valCol = -1;
      continue;
    }
    if (!inSection || !line.trim().startsWith("|")) continue;
    const cells = line.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
    if (keyCol < 0) {
      keyCol = cells.indexOf("Key");
      valCol = cells.indexOf("Threshold");
      continue;
    }
    if (/^[-: ]+$/.test(cells.join(""))) continue;
    found.set(cells[keyCol], cells[valCol]);
  }
  const out = {};
  for (const { key } of METRICS) {
    const v = found.get(key);
    if (v === undefined) fail(`threshold key missing: ${key}`);
    if (!/^\d+$/.test(v)) fail(`threshold for ${key} is not a whole number`);
    out[key] = Number(v);
  }
  return out;
}

const { standard, folder } = parseArgs(process.argv.slice(2));

const tally = { rework: new Map(), blocked: 0, design: 0, gate: 0 };
countMarkers(readText(join(folder, "build-log.md")), tally);

let loopFiles = [];
try {
  loopFiles = readdirSync(folder, { withFileTypes: true })
    .filter((e) => e.isFile() && /^loop-state-.*\.md$/.test(e.name))
    .map((e) => e.name)
    .sort();
} catch {
  loopFiles = [];
}
for (const f of loopFiles) countMarkers(readText(join(folder, f)), tally);

const thresholds = readThresholds(standard);

let topId = null;
let topCount = 0;
for (const [id, n] of tally.rework) {
  if (n > topCount || (n === topCount && id < topId)) {
    topId = id;
    topCount = n;
  }
}

const values = [topCount, tally.blocked, tally.design, tally.gate];
const shown = [topId ? `${topCount} (${topId})` : "0", ...values.slice(1).map(String)];

let breaches = 0;
const rows = METRICS.map((m, i) => {
  const t = thresholds[m.key];
  const breach = values[i] > t;
  if (breach) breaches++;
  return `| ${m.label} | ${shown[i]} | ${t} | ${breach ? "breach" : "ok"} |`;
});

process.stdout.write(
  [
    "## Workflow governance",
    "",
    "| Metric | Value | Threshold | Result |",
    "|--------|-------|-----------|--------|",
    ...rows,
    "",
    `Breaches: ${breaches}. The gate reports and does not block. Counts come from marker lines only.`,
    "",
  ].join("\n"),
);
