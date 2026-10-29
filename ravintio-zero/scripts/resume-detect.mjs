#!/usr/bin/env node
/**
 * resume-detect.mjs: read-only resume signal detection.
 *
 * Usage: node resume-detect.mjs [projectDir]
 *
 * Prints one fixed line per finding, in check order. It never prints file
 * text. Ids appear only after they pass a strict pattern. Writes nothing and
 * always exits 0.
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const root = process.argv[2] || process.cwd();
const p = (...parts) => join(root, ...parts);
const out = [];

function read(path) {
  try {
    return readFileSync(path, "utf-8");
  } catch {
    return null;
  }
}

function list(dir) {
  try {
    return readdirSync(dir);
  } catch {
    return [];
  }
}

try {
  // 1. Pending migrations.
  for (const name of list(p("ravintio-zero", "migrations")).sort()) {
    if (name === "_done" || !name.endsWith(".md")) continue;
    const m = /^(\d{4})-[a-z0-9-]+\.md$/.exec(name);
    out.push(`pending migration: ${m ? m[1] : "unreadable"}`);
  }

  // 2. Pack version.
  const comp = read(p("ravintio-zero", "component.yml"));
  const about = read(p("docs", "about.md"));
  if (comp !== null && about !== null) {
    const ver = (t) => {
      const m = /^version:\s*["']?([^"'\s]*)["']?\s*$/m.exec(t);
      return m && /^\d+\.\d+\.\d+$/.test(m[1]) ? m[1] : null;
    };
    const a = ver(comp);
    const b = ver(about);
    if (a === null || b === null) out.push("pack version unreadable");
    else if (a !== b) out.push("pack version differs from docs/about.md");
  }

  const currentEntries = () => list(p("plan", "current")).filter((n) => n !== ".gitkeep");
  const artifacts = currentEntries().length > 0;
  const sentinel = existsSync(p("plan", ".orchestrator-active"));

  // 3. Session and initiative.
  if (process.env.RAVINTIO_INITIATIVE_STEP === "1") out.push("step session");
  const init = read(p("plan", "current-initiative", "initiative.md"));
  if (
    init !== null &&
    (/^\s*status:\s*["']?active["']?\s*$/im.test(init) ||
      /^\s*\*\*Status:\*\*\s*active\s*$/im.test(init))
  ) {
    out.push("initiative active");
    out.push(existsSync(p("plan", ".initiative-runner.lock")) ? "driver lock held" : "driver lock free");
    const pos = /^\*\*Position:\*\*[ \t]*(\S*)[ \t]*$/m.exec(init);
    out.push(`initiative position: ${pos && /^\d{1,4}$/.test(pos[1]) ? pos[1] : "unreadable"}`);
  }
  if (artifacts) out.push("plan/current has artifacts");

  // 4. Interrupted ship.
  if (sentinel && !artifacts) out.push("interrupted ship: sentinel present, plan/current empty");

  // 5 to 8. Presence files.
  if ([p(".feature-id"), p("plan", ".feature-id"), p("plan", "current", ".feature-id")].some(existsSync)) {
    out.push("feature id file present");
  }
  if (existsSync(p("plan", "current", ".skips"))) out.push("skips file present");
  if (existsSync(p("plan", "current", "pause.md"))) out.push("pause record present");
  if (existsSync(p("plan", "current", "park.md"))) out.push("park record present");

  // Build log lines, with a leading "- " bullet removed.
  const logText = read(p("plan", "current", "build-log.md"));
  const log = logText === null ? [] : logText.split(/\r?\n/).map((l) => l.replace(/^- /, ""));

  // 9. Run mode, open stop, gate.
  if (sentinel || artifacts) {
    const rm = read(p("plan", ".run-mode"));
    let mode = "missing";
    if (rm !== null) {
      const v = rm.trim();
      mode = v === "gated" || v === "autonomous" ? v : "invalid";
    }
    out.push(`run mode: ${mode}`);
    const last = (prefix) => log.reduce((acc, l, i) => (l.startsWith(prefix) ? i : acc), -1);
    const b = last("Blocked:");
    if (b >= 0 && b > last("Resolved:")) out.push("open stop: Blocked with no Resolved");
    if (mode === "gated") {
      const complete = log.filter((l) => /^P[0-4] [A-Za-z]+: Complete:/.test(l)).length;
      const accepted = log.filter((l) => l.startsWith("Gate accepted:")).length;
      if (complete > accepted) out.push("gate not accepted");
    }
  }

  // 10. Units in progress.
  const unitOk = /^(?:(?:REQ|U)-\d{3}(?: (?:test-writer|implementer|refactor|validate|ship))?|P[0-4] cycle \d{1,2})$/;
  log.forEach((l, i) => {
    const m = /^In progress: (.*?) \(([^()]*)\)\s*$/.exec(l);
    if (!m) return;
    const unit = m[1];
    const done = log.slice(i + 1).some((d) => d.startsWith(`Done: ${unit}`));
    if (!done) out.push(`unit in progress: ${unitOk.test(unit) ? unit : "unreadable"}`);
  });

  // 11. Discovery.
  if (artifacts) {
    out.push(existsSync(p("plan", "current", "discovery.md")) ? "discovery.md present" : "discovery.md missing");
  }

  // 12. Last phase.
  let phase = null;
  for (const l of log) {
    const m = /^### P([0-4]):/.exec(l);
    if (m) phase = m[1];
  }
  if (phase !== null) out.push(`last phase: P${phase}`);
} catch {
  // Report what was found so far.
}

process.stdout.write((out.length ? out : ["no resume signals"]).join("\n") + "\n");
process.exit(0);
